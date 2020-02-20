class Arachnid2
  class Watir
    DEFAULT_AGENT = :desktop
    DEFAULT_ORIENTATION = :landscape

    include Arachnid2::Exoskeleton

    def initialize(url)
      @url = url
      @domain = Adomain[@url]
    end

    def crawl(opts)
      preflight(opts)
      watir_preflight
      @already_retried = false

      until @global_queue.empty?
        q = @global_queue.shift
        links = nil

        break if @global_visited.size >= crawl_options[:max_urls]
        break if Time.now > crawl_options[:time_limit]
        break if memory_danger?

        @global_visited.insert(q)

        begin
          begin
            browser.goto q
          rescue Selenium::WebDriver::Error::UnknownError => e
            # Firefox and Selenium, in their infinite wisdom
            # raise an error when a page cannot be loaded.
            # At the time of writing this, the page at
            # thewirecutter.com/cars/accessories-auto
            # causes such an issue (too many redirects).
            # This error handling moves us on from those pages.
            raise e unless e.message =~ /.*Reached error page.*/i
            next
          end
          links = process(browser.url, browser.body.html) if browser.body.exists?
          next unless links

          yield browser

          vacuum(links, browser.url)
        rescue Selenium::WebDriver::Error::NoSuchWindowError, Net::ReadTimeout => e
        rescue => e
          raise e if raise_before_retry?(e.class)
          reset_for_retry
        end

      end # until @global_queue.empty?
    ensure
      @browser.close if @browser rescue nil
      @headless.destroy if @headless rescue nil
    end

    private
      def raise_before_retry?(klass)
        @already_retried || \
          "#{klass}".include?("Selenium") || \
          "#{klass}".include?("Watir")
      end

      def reset_for_retry
        @browser.close if @browser rescue nil
        @headless.destroy if @headless rescue nil
        @driver.quit if @headless rescue nil
        @driver = nil
        @browser = nil
        @already_retried = true
      end

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
        unless @driver
          language    = @options.dig(:headers, "Accept-Language") || DEFAULT_LANGUAGE
          user_agent  = @options.dig(:headers, "User-Agent")      || DEFAULT_USER_AGENT
          agent       = @options.dig(:agent)                      || DEFAULT_AGENT
          orientation = @options.dig(:orientation)                || DEFAULT_ORIENTATION

          @driver = Webdriver::UserAgent.driver(
            browser: browser_type,
            agent: agent,
            orientation: orientation,
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
