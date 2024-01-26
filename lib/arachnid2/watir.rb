class Arachnid2
  class Watir
    DEFAULT_AGENT = :desktop
    DEFAULT_ORIENTATION = :landscape

    include Arachnid2::Exoskeleton

    def initialize(url)
      @url = url
      @domain = Adomain[@url]
    end

    def crawl(opts, &block)
      preflight(opts)
      watir_preflight
      @already_retried = false

      until @global_queue.empty?
        q = @global_queue.shift
        links = nil

        break if time_to_stop?

        @global_visited.insert(q)

        make_request(q, &block)
      end # until @global_queue.empty?
    ensure
      @browser.close if @browser rescue nil
      @headless.destroy if @headless rescue nil
    end

    private
      def make_request(q, &block)
        begin
          links = browse_links(q, &block)
          return unless links

          vacuum(links, browser.url)
        rescue Selenium::WebDriver::Error::NoSuchWindowError, Net::ReadTimeout => e
          msg = "WARNING [arachnid2] Arachnid2::Watir#make_request " \
                "is ignoring an error: " \
                "#{e.class} - #{e.message}"
          puts msg
        rescue => e
          raise e if raise_before_retry?(e.class)
          msg = "WARNING [arachnid2] Arachnid2::Watir#make_request " \
                "is retrying once after an error: " \
                "#{e.class} - #{e.message}"
          puts msg
          e.backtrace[0..4].each{|l| puts "\t#{l}"}; puts "..."
          reset_for_retry
        end
      end

      def browse_links(url, &block)
        return unless navigate(url)

        block.call browser

        process(browser.url, browser.body.html) if browser.body.exists?
      end

      def navigate(url)
        begin
          browser.goto url
        rescue Selenium::WebDriver::Error::UnknownError => e
          # Firefox and Selenium, in their infinite wisdom
          # raise an error when a page cannot be loaded.
          # At the time of writing this, the page at
          # thewirecutter.com/cars/accessories-auto
          # causes such an issue (too many redirects).
          # This error handling moves us on from those pages.
          raise e unless e.message =~ /.*Reached error page.*/i
          return
        end

        true
      end

      def time_to_stop?
        @global_visited.size >= crawl_options[:max_urls] || \
                 Time.now > crawl_options[:time_limit] || \
                 memory_danger?
      end

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
