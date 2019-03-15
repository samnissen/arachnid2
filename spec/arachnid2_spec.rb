RSpec.describe Arachnid2 do
  it "has a version number" do
    expect(Arachnid2::VERSION).not_to be nil
  end

  describe "#initialize" do
    it "sets the URL" do
      url = "http://test.com"
      spider = Arachnid2.new url
      expect(spider.instance_variable_get(:@url)).to eq(url)
    end
  end
end

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
        headless: false
      }

      spider.crawl(opts) { |browser|
        @header_language = browser.execute_script("return navigator.language") unless @header_language
        @header_user_agent = browser.execute_script("return navigator.userAgent") unless @header_user_agent
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
      expect{ spider.crawl(opts = {}, with_watir = true) {} }.not_to raise_error
    end
  end
end

RSpec.describe Arachnid2::Typhoeus do
  describe "#crawl" do
    it "accepts the options" do
      url = "https://daringfireball.net"
      spider = Arachnid2::Typhoeus.new(url)
      opts = {
        followlocation: true,
        timeout: 12000,
        time_box: 10,
        max_urls: 1,
        headers: {
          'Accept-Language' => "en-UK",
          'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
        },
        max_concurrency: 5,
        memory_limit: 39.99,
        proxy: {
          ip: "1.2.3.4",
          port: "1234",
          username: "sam",
          password: "coolcoolcool",
        },
        non_html_extensions: {
          2 => [".oh"],
          3 => [".omg"],
          5 => [".ohhai"],
        }
      }

      spider.crawl(opts){}

      crawl_options = spider.instance_variable_get(:@crawl_options)
      request_options = spider.instance_variable_get(:@request_options)
      maximum_load_rate = spider.send(:maximum_load_rate)
      max_concurrency = spider.send(:max_concurrency)
      hydra = spider.instance_variable_get(:@hydra)
      followlocation = spider.send(:followlocation)
      non_html_extensions = spider.send(:non_html_extensions)
      timeout = spider.instance_variable_get(:@timeout)

      expect(crawl_options[:time_limit]).to be_a(Time)
      expect(crawl_options[:max_urls]).to be_an(Integer)
      expect(crawl_options[:proxy][:proxy]).to eq("1.2.3.4:1234")
      expect(crawl_options[:proxy][:proxyuserpwd]).to eq("sam:coolcoolcool")
      expect(request_options).not_to be_nil
      expect(request_options[:headers]).to eq(opts[:headers])
      expect(maximum_load_rate).to eq(39.99)
      expect(max_concurrency).to eq(5)
      expect(hydra).to be_a(Typhoeus::Hydra)
      expect(followlocation).to eq(true)
      expect(timeout).to eq(12000)
      expect(non_html_extensions.values.flatten).to eq([".oh", ".omg", ".ohhai"])
    end

    it "visits the URL" do
      url = "https://daringfireball.net"
      spider = Arachnid2::Typhoeus.new(url)
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
  end
end

RSpec.describe Arachnid2::Exoskeleton do
  describe "#memory_danger?" do
    let(:dummy) { (Class.new { include Arachnid2::Exoskeleton }).new }
    before(:each) do
      dummy.instance_variable_set(:@url, "http://dummy.com")
      dummy.instance_variable_set(:@domain, "dummy.com")

      allow(dummy).to receive(:in_docker?).and_return(true)
      dummy.instance_variable_set(:@maximum_load_rate, 50.00)
    end

    it "stops execution when memory limit is reached" do
      use_file    = OpenStruct.new({read: 99.9999})
      limit_file  = OpenStruct.new({read: 100.0000})

      allow(File).to receive(:open).with(Arachnid2::MEMORY_USE_FILE, 'rb').and_return(use_file)
      allow(File).to receive(:open).with(Arachnid2::MEMORY_LIMIT_FILE, 'rb').and_return(limit_file)

      expect(dummy.memory_danger?).to be_truthy
    end

    it "does not stop execution when memory limit is not yet reached" do
      use_file    = OpenStruct.new({read: 1.0})
      limit_file  = OpenStruct.new({read: 100.0000})

      allow(File).to receive(:open).with(Arachnid2::MEMORY_USE_FILE, 'rb').and_return(use_file)
      allow(File).to receive(:open).with(Arachnid2::MEMORY_LIMIT_FILE, 'rb').and_return(limit_file)

      expect(dummy.memory_danger?).to be_falsey
    end
  end
end
