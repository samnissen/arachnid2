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
        time_box: 10,
        max_urls: 1,
        language: "en-UK",
        user_agent: "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
        proxy: {
          ip: "1.2.3.4",
          port: "1234",
          username: "sam",
          password: "coolcoolcool",
        }
      }

      spider.crawl(opts){}

      crawl_options = spider.instance_variable_get(:@crawl_options)
      request_options = spider.instance_variable_get(:@request_options)

      expect(crawl_options[:time_limit]).to be_a(Time)
      expect(crawl_options[:max_urls]).to be_an(Integer)
      expect(crawl_options[:proxy]).to eq("1.2.3.4:1234")
      expect(crawl_options[:proxyuserpwd]).to eq("sam:coolcoolcool")
      expect(request_options).not_to be_nil
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
end
