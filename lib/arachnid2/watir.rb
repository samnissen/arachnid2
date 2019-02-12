class Arachnid2
  class Watir
    include Arachnid2::Exoskeleton

    def initialize(url)
      @url = url
      @domain = Adomain[@url]
    end
    
    def crawl(opts)
      preflight(opts)
      watir_preflight

      until @global_queue.empty?
        @already_retried = false
        q = @global_queue.shift

        break if @global_visited.size >= @crawl_options[:max_urls]
        break if Time.now > @crawl_options[:time_limit]
        break if memory_danger?

        @global_visited.insert(q)

        begin
          browser.goto q
          links = process(browser.url, browser.body.html)
          next unless links

          yield browser

          vacuum(links, browser.url)
        rescue => e
          raise e if @already_retried
          raise e unless "#{e.class}".include?("Selenium") || "#{e.class}".include?("Watir")
          @browser = nil
          @already_retried = true
          retry
        end

      end # until @global_queue.empty?
    ensure
      @browser.close if @browser rescue nil
      @headless.destroy if @headless rescue nil
    end

    private
      def browser
        unless @browser
          behead if @make_headless

          @browser = create_browser

          set_timeout
        end

        return @browser
      end

      def create_browser
        return ::Watir::Browser.new(driver, proxy: @proxy) if @proxy

        ::Watir::Browser.new driver
      end

      def set_timeout
        @browser.driver.manage.timeouts.page_load = timeout
      end

      def behead
        @headless = Headless.new
        @headless.start
      end

      def driver
        if !@driver
          language   = @options.dig(:headers, "Accept-Language")  || DEFAULT_LANGUAGE
          user_agent = @options.dig(:headers, "User-Agent")       || DEFAULT_USER_AGENT

          @driver = Webdriver::UserAgent.driver(
            browser: @browser_type,
            accept_language_string: language,
            user_agent_string: user_agent
          )
        end

        @driver
      end

      def watir_preflight
        watir_proxy_options
        @make_headless = @options[:headless]
      end

      def watir_proxy_options
        crawl_options[:proxy] = {}

        crawl_options[:proxy][:http] = @options[:proxy][:http] if @options.dig(:proxy, :http)
        crawl_options[:proxy][:ssl] = @options[:proxy][:ssl] if @options.dig(:proxy, :ssl)
      end
    end

end
