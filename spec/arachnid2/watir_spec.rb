require 'spec_helper.rb'

RSpec.describe Arachnid2::Watir do
  describe "#crawl" do
    it "accepts the options" do
      url = "https://daringfireball.net"
      spider = Arachnid2::Watir.new(url)
      opts = {
        browser_type: :chrome,
        timeout: 12000,
        time_box: 10,
        max_urls: 1,
        headers: {
          'Accept-Language' => "en-UK",
          'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
        },
        memory_limit: 39.99,
        proxy: {
          http: "troy.show:8080",
          ssl: "abed.show:8080"
        },
        non_html_extensions: {
          2 => [".oh"],
          3 => [".omg"],
          5 => [".ohhai"],
        },
        headers: {
          'Accept-Language' => "es-ES",
          'User-Agent' => "Sam's Custom Browser"
        },
        headless: false,
        agent: :iphone,
        orientation: :portrait
      }

      spider.crawl(opts) { |browser|
        @header_language = browser.execute_script("return navigator.language") unless @header_language
        @header_user_agent = browser.execute_script("return navigator.userAgent") unless @header_user_agent
        @portrait = browser.execute_script("return (window.innerHeight > window.innerWidth)") unless @portrait
        @window_width = browser.execute_script("return window.innerWidth") unless @window_width
      }

      crawl_options = spider.crawl_options
      maximum_load_rate = spider.maximum_load_rate
      non_html_extensions = spider.non_html_extensions
      timeout = spider.timeout
      make_headless = spider.instance_variable_get(:@make_headless)

      expect(crawl_options[:time_limit]).to be_a(Time)
      expect(crawl_options[:max_urls]).to be_an(Integer)
      expect(crawl_options[:proxy][:http]).to eq("troy.show:8080")
      expect(crawl_options[:proxy][:ssl]).to eq("abed.show:8080")
      expect(@header_language).to include(opts[:headers]['Accept-Language'])
      expect(@header_user_agent).to eq(opts[:headers]['User-Agent'])
      expect(@portrait).to be_truthy
      expect(@window_width).to be < 525
      expect(maximum_load_rate).to eq(39.99)
      expect(timeout).to eq(12000)
      expect(non_html_extensions.values.flatten).to eq([".oh", ".omg", ".ohhai"])
    end

    it "visits the URL" do
      url = "https://daringfireball.net"
      spider = Arachnid2::Watir.new(url)
      opts = {
        time_box: 10,
        max_urls: 2
      }
      responses = []

      spider.crawl(opts){|r| responses << r}
      global_visited = spider.instance_variable_get(:@global_visited)
      global_queue = spider.instance_variable_get(:@global_queue)

      expect(global_visited.size).to be > 0
      expect(responses.size).to be > 0
    end

    it "uses Watir when requested" do
      spider = Arachnid2.new("http://test.com")
      allow_any_instance_of(Arachnid2::Watir).to receive(:crawl).with(anything).and_return(true)
      expect{ spider.crawl(opts = {max_urls: 1, time_box: 1}, with_watir = true) {} }.not_to raise_error
    end

    it "only uses one crawling technology type" do
      spider = Arachnid2.new("http://daringfireball.net")
      # allow_any_instance_of(Arachnid2::Watir).to receive(:crawl).with(anything).and_return(true)
      expect_any_instance_of(Arachnid2::Typhoeus).not_to receive(:crawl)
      spider.crawl(opts = {max_urls: 2, time_box: 5}, with_watir = true) {}
    end

    it "crawls past any Net::ReadTimeout issues" do
      spider = Arachnid2.new("https://www.themcelroy.family")
      opts = {max_urls: 3, time_box: 10}
      with_watir = true

      allow_any_instance_of(::Watir::Browser).to receive(:goto).with(anything).and_raise(Net::ReadTimeout)

      expect{
        spider.crawl(opts, with_watir) {}
      }.not_to raise_error
    end

    it "crawls past any Selenium::WebDriver::Error::NoSuchWindowError issues" do
      spider = Arachnid2.new("https://www.themcelroy.family")
      opts = {max_urls: 3, time_box: 10}
      with_watir = true

      allow_any_instance_of(::Watir::Browser).to receive(:goto).with(anything).and_raise(Selenium::WebDriver::Error::NoSuchWindowError)

      expect{
        spider.crawl(opts, with_watir) {}
      }.not_to raise_error
    end

    it "does not fail when the browser cannot locate the <body>" do
      spider = Arachnid2.new("https://www.themcelroy.family")
      opts = {max_urls: 3, time_box: 10}
      with_watir = true

      allow_any_instance_of(::Watir::Body).to receive(:html).and_raise(Watir::Exception::UnknownObjectException)
      allow_any_instance_of(::Watir::Body).to receive(:exists?).and_return(false)

      expect{
        spider.crawl(opts, with_watir) {}
      }.not_to raise_error
    end

    it "rescues one error when the browser connection is lost" do
      spider = Arachnid2::Watir.new("https://stratechery.com")
      opts = {max_urls: 3, time_box: 60}

      Object.const_set("MyCustomTestError", Class.new(StandardError))

      allow_any_instance_of(Arachnid2::Watir).to receive(:preflight).with(opts).and_return(true)
      allow_any_instance_of(Arachnid2::Watir).to receive(:watir_preflight).and_return(true)

      queue = [
        "https://stratechery.com",
        "http://stratechery.com/about/",
        "https://stratechery.com/concepts/"
      ]
      spider.instance_variable_set(:@options, opts)
      spider.instance_variable_set(:@global_queue, queue)
      bf = BloomFilter::Native.new(:size => 1000000, :hashes => 5, :seed => 1, :bucket => 8, :raise => true)
      spider.instance_variable_set(:@global_visited, bf)
      spider.instance_variable_set(:@make_headless, !OS.mac?)

      browser = spider.send(:create_browser)
      spider.instance_variable_set(:@browser, browser)

      allow(browser).to receive(:url).and_raise(MyCustomTestError)

      expect{
        spider.crawl(opts) {}
      }.not_to raise_error
    end

    it "stops after more than one error" do
      spider = Arachnid2::Watir.new("https://stratechery.com")
      opts = {max_urls: 3, time_box: 60}

      Object.const_set("MyCustomTestError", Class.new(StandardError)) unless Object.const_defined?("MyCustomTestError")

      allow_any_instance_of(::Watir::Browser).to receive(:url).and_raise(MyCustomTestError)
      allow_any_instance_of(Arachnid2::Watir).to receive(:preflight).with(opts).and_return(true)
      allow_any_instance_of(Arachnid2::Watir).to receive(:watir_preflight).and_return(true)

      queue = [
        "https://stratechery.com",
        "http://stratechery.com/about/",
        "https://stratechery.com/concepts/"
      ]
      spider.instance_variable_set(:@options, opts)
      spider.instance_variable_set(:@global_queue, queue)
      bf = BloomFilter::Native.new(:size => 1000000, :hashes => 5, :seed => 1, :bucket => 8, :raise => true)
      spider.instance_variable_set(:@global_visited, bf)
      spider.instance_variable_set(:@make_headless, !OS.mac?)

      expect{
        spider.crawl(opts) {}
      }.to raise_error(MyCustomTestError)
    end

    context "data is available in the cache" do
      let!(:url) { "https://daringfireball.net/" }
      let!(:spider) { Arachnid2::Watir.new(url) }
      let!(:opts) { { time_box: 30, max_urls: 2 } }
      let!(:found_url) { "https://daringfireball.net/archive/" }
      let!(:payload) {
        OpenStruct.new({
          url: "https://daringfireball.net/",
          body: OpenStruct.new({
            html: "<html><a href=\"#{found_url}\" /></html>",
            :"exists?" => true
          })
        })
      } # note that the url and effective_url domains must match

      before(:each) do
        allow(spider).to receive(:load_data).with(url, opts).and_return(payload)
        allow(spider).to receive(:load_data).with(found_url, opts).and_return(nil)
      end

      it "loads data from the cache" do
        responses = []
        expect(spider).to receive(:load_data).exactly(:twice)

        spider.crawl(opts){|r| responses << r}
        expect(responses).to include(payload)
      end
    end
  end
end
