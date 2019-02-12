class Arachnid2
  class Typhoeus
    include CachedArachnidResponses
    include Arachnid2::Exoskeleton

    def initialize(url)
      @url = url
      @domain = Adomain[@url]
      @cached_data = []
    end
    #
    # Visits a URL, gathering links and visiting them,
    # until running out of time, memory or attempts.
    #
    # @example
    #   url = "https://daringfireball.net"
    #   spider = Arachnid2.new(url)
    #
    #   opts = {
    #     :followlocation => true,
    #     :timeout => 25000,
    #     :time_box => 30,
    #     :headers => {
    #       'Accept-Language' => "en-UK",
    #       'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
    #     },
    #     :memory_limit => 89.99,
    #     :proxy => {
    #       :ip => "1.2.3.4",
    #       :port => "1234",
    #       :username => "sam",
    #       :password => "coolcoolcool",
    #     }
    #     :non_html_extensions => {
    #       3 => [".abc", ".xyz"],
    #       4 => [".abcd"],
    #       6 => [".abcdef"],
    #       11 => [".abcdefghijk"]
    #     }
    #   }
    #   responses = []
    #   spider.crawl(opts) { |response|
    #     responses << response
    #   }
    #
    # @param [Hash] opts
    #
    # @return nil
    #
    def crawl(opts = {})
      preflight(opts)
      typhoeus_preflight

      until @global_queue.empty?
        @max_concurrency.times do
          q = @global_queue.shift

          break if @global_visited.size >= @crawl_options[:max_urls]
          break if Time.now > @crawl_options[:time_limit]
          break if memory_danger?

          @global_visited.insert(q)

          request = ::Typhoeus::Request.new(q, request_options)

          data = load_data(@url, opts)
          unless data.nil?
            data.each do |response|
              yield response
            end
            return
          end
          request.on_complete do |response|
            @cached_data.push(response)
            links = process(response.effective_url, response.body)
            next unless links

            yield response

            vacuum(links, response.effective_url)
          end

          @hydra.queue(request)
        end # @max_concurrency.times do

        @hydra.run

      end # until @global_queue.empty?
      put_cached_data(@url, opts, @cached_data) unless @cached_data.empty?
    ensure
      @cookie_file.close! if @cookie_file
    end # def crawl(opts = {})

    private
      def typhoeus_preflight
        @max_concurrency = max_concurrency
        @hydra = ::Typhoeus::Hydra.new(:max_concurrency => @max_concurrency)
        typhoeus_proxy_options
      end

      def max_concurrency
        @max_concurrency ||= nil

        if !@max_concurrency
          @max_concurrency = "#{@options[:max_concurrency]}".to_i
          @max_concurrency = 1 unless (@max_concurrency > 0)
        end

        @max_concurrency
      end

      def followlocation
        if @followlocation.is_a?(NilClass)
          @followlocation = @options[:followlocation]
          @followlocation = true unless @followlocation.is_a?(FalseClass)
        end
        @followlocation
      end

      def request_options
        @cookie_file ||= Tempfile.new('cookies')

        @request_options = {
          timeout: timeout,
          followlocation: followlocation,
          cookiefile: @cookie_file.path,
          cookiejar: @cookie_file.path,
          headers: @options[:headers]
        }.merge(@crawl_options[:proxy])

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
