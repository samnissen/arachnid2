class Arachnid2
  class Typhoeus
    include CachedResponses
    include Arachnid2::Exoskeleton

    def initialize(url)
      @url = url
      @domain = Adomain[@url]
      @cached_data = []
    end

    def crawl(opts = {})
      preflight(opts)
      typhoeus_preflight

      until @global_queue.empty?
        max_concurrency.times do
          q = @global_queue.shift

          break if time_to_stop?
          @global_visited.insert(q)

          found_in_cache = use_cache(q, opts, &Proc.new)
          return if found_in_cache

          request = ::Typhoeus::Request.new(q, request_options)
          requestable = after_request(request, &Proc.new)
          @hydra.queue(request) if requestable
        end # max_concurrency.times do

        @hydra.run
      end # until @global_queue.empty?
    ensure
      @cookie_file.close! if @cookie_file
    end # def crawl(opts = {})

    private
      def after_request(request)
        request.on_complete do |response|
          cacheable = use_response(response, &Proc.new)
          return unless cacheable

          put_cached_data(response.effective_url, @options, response)
        end

        true
      end

      def use_response(response)
        links = process(response.effective_url, response.body)
        return unless links

        yield response

        vacuum(links, response.effective_url)
        true
      end

      def use_cache(url, options)
        data = load_data(url, options)
        use_response(data, &Proc.new) if data

        data
      end

      def time_to_stop?
        @global_visited.size >= crawl_options[:max_urls] || \
                 Time.now > crawl_options[:time_limit] || \
                 memory_danger?
      end

      def typhoeus_preflight
        @hydra = ::Typhoeus::Hydra.new(:max_concurrency => max_concurrency)
        typhoeus_proxy_options
      end

      def max_concurrency
        return @max_concurrency if @max_concurrency

        @max_concurrency = "#{@options[:max_concurrency]}".to_i
        @max_concurrency = 1 unless (@max_concurrency > 0)
        @max_concurrency
      end

      def followlocation
        return @followlocation unless @followlocation.nil?

        @followlocation = @options[:followlocation]
        @followlocation = true unless @followlocation.is_a?(FalseClass)
      end

      def request_options
        @cookie_file ||= Tempfile.new('cookies')

        @request_options = {
          timeout: timeout,
          followlocation: followlocation,
          cookiefile: @cookie_file.path,
          cookiejar: @cookie_file.path,
          headers: @options[:headers]
        }.merge(crawl_options[:proxy])

        @request_options[:headers] ||= {}
        @request_options[:headers]['Accept-Language'] ||= DEFAULT_LANGUAGE
        @request_options[:headers]['User-Agent']      ||= DEFAULT_USER_AGENT

        @request_options
      end

      def typhoeus_proxy_options
        crawl_options[:proxy] = {}

        crawl_options[:proxy][:proxy] = "#{@options[:proxy][:ip]}:#{@options[:proxy][:port]}" if @options.dig(:proxy, :ip)
        crawl_options[:proxy][:proxyuserpwd] = "#{@options[:proxy][:username]}:#{@options[:proxy][:password]}" if @options.dig(:proxy, :username)
      end

  end
end
