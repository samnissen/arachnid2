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

    it "parses the domain" do
      url = "http://test.com"
      spider = Arachnid2.new url
      expect(spider.instance_variable_get(:@domain)).to eq("test.com")
    end
  end

  describe "#crawl" do
    it "accepts the options" do
      url = "https://daringfireball.net"
      spider = Arachnid2.new(url)
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
      maximum_load_rate = spider.instance_variable_get(:@maximum_load_rate)
      max_concurrency = spider.instance_variable_get(:@max_concurrency)
      hydra = spider.instance_variable_get(:@hydra)
      followlocation = spider.instance_variable_get(:@followlocation)
      non_html_extensions = spider.instance_variable_get(:@non_html_extensions)
      timeout = spider.instance_variable_get(:@timeout)

      expect(crawl_options[:time_limit]).to be_a(Time)
      expect(crawl_options[:max_urls]).to be_an(Integer)
      expect(crawl_options[:proxy]).to eq("1.2.3.4:1234")
      expect(crawl_options[:proxyuserpwd]).to eq("sam:coolcoolcool")
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
      spider = Arachnid2.new(url)
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

  describe "#memory_danger?" do
    before(:each) do
      @url = "https://daringfireball.net"
      @spider = Arachnid2.new(@url)
      allow(@spider).to receive(:in_docker?).and_return(true)
      @spider.instance_variable_set(:@maximum_load_rate, 50.00)
    end

    it "stops execution when memory limit is reached" do
      use_file    = OpenStruct.new({read: 99.9999})
      limit_file  = OpenStruct.new({read: 100.0000})

      allow(File).to receive(:open).with(Arachnid2::MEMORY_USE_FILE, 'rb').and_return(use_file)
      allow(File).to receive(:open).with(Arachnid2::MEMORY_LIMIT_FILE, 'rb').and_return(limit_file)

      expect(@spider.send(:memory_danger?)).to be_truthy
    end

    it "does not stop execution when memory limit is not yet reached" do
      use_file    = OpenStruct.new({read: 1.0})
      limit_file  = OpenStruct.new({read: 100.0000})

      allow(File).to receive(:open).with(Arachnid2::MEMORY_USE_FILE, 'rb').and_return(use_file)
      allow(File).to receive(:open).with(Arachnid2::MEMORY_LIMIT_FILE, 'rb').and_return(limit_file)

      expect(@spider.send(:memory_danger?)).to be_falsey
    end
  end
end
