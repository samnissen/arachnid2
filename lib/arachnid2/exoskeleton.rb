class Arachnid2
  module Exoskeleton
    def browser_type
      unless @browser_type
        @browser_type   = "#{@options[:browser_type]}".to_sym if @options[:browser_type]
        @browser_type ||= :firefox
      end

      @browser_type
    end

    def process(url, html)
      return false unless Adomain["#{url}"].include? @domain

      extract_hrefs(html)
    end

    def extract_hrefs(body)
      elements = Nokogiri::HTML.parse(body).css('a')
      return elements.map {|link| link.attribute('href').to_s}.uniq.sort.delete_if {|href| href.empty? }
    end

    def vacuum(links, url)
      links.each do |link|
        next if link.match(/^\(|^javascript:|^mailto:|^#|^\s*$|^about:/)

        begin
          absolute_link = make_absolute(link, url)

          next if skip_link?(absolute_link)

          @global_queue << absolute_link
        rescue Addressable::URI::InvalidURIError
        end
      end
    end

    def skip_link?(absolute_link)
      !internal_link?(absolute_link) || \
      @global_visited.include?(absolute_link) || \
      extension_ignored?(absolute_link) || \
      @global_queue.include?(absolute_link)
    end

    def preflight(opts)
      @options = opts
      @global_visited = BloomFilter::Native.new(:size => 1000000, :hashes => 5, :seed => 1, :bucket => 8, :raise => true)
      @global_queue = [@url]
    end

    def proxy
      @options[:proxy]
    end

    def non_html_extensions
      return @non_html_extensions if @non_html_extensions

      @non_html_extensions   = @options[:non_html_extensions]
      @non_html_extensions ||= DEFAULT_NON_HTML_EXTENSIONS
    end

    def bound_time
      boundary = "#{@options[:time_box]}".to_i
      boundary = BASE_CRAWL_TIME if boundary <= 0
      boundary = MAX_CRAWL_TIME  if boundary >  MAX_CRAWL_TIME

      return Time.now + boundary
    end

    def bound_urls
      amount = "#{@options[:max_urls]}".to_i
      amount = BASE_URLS if amount <= 0
      amount = MAX_URLS  if amount >  MAX_URLS

      amount
    end

    def timeout
      unless @timeout
        @timeout = @options[:timeout]
        @timeout = DEFAULT_TIMEOUT unless @timeout.is_a?(Integer)
        @timeout = DEFAULT_TIMEOUT if @timeout > MAXIMUM_TIMEOUT
        @timeout = DEFAULT_TIMEOUT if @timeout < MINIMUM_TIMEOUT
      end
      @timeout
    end

    def crawl_options
      @crawl_options ||= { max_urls: max_urls, time_limit: time_limit }
    end

    alias_method :max_urls, :bound_urls

    alias_method :time_limit, :bound_time

    def make_absolute(href, root)
      Addressable::URI.parse(root).join(Addressable::URI.parse(href)).to_s
    end

    def internal_link?(absolute_url)
      "#{Adomain[absolute_url]}".include? @domain
    end

    def extension_ignored?(url)
      return false if url.empty?

      !non_html_extensions.values.flatten.find { |e| url.downcase.end_with? e.downcase }.nil?
    end

    def memory_danger?
      return false unless in_docker?

      use      = "#{File.open(MEMORY_USE_FILE, "rb").read}".to_f
      @limit ||= "#{File.open(MEMORY_LIMIT_FILE, "rb").read}".to_f

      return false unless ( (use > 0.0) && (@limit > 0.0) )

      return ( ( (use / @limit) * 100.0 ) >= maximum_load_rate )
    end

    def in_docker?
      File.file?(MEMORY_USE_FILE)
    end

    def maximum_load_rate
      return @maximum_load_rate if @maximum_load_rate

      @maximum_load_rate = "#{@options[:memory_limit]}".to_f
      @maximum_load_rate = DEFAULT_MAXIMUM_LOAD_RATE unless ((@maximum_load_rate > 0.0) && (@maximum_load_rate < 100.0))
      @maximum_load_rate
    end
  end
end
