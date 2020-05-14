require 'spec_helper.rb'

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

    context "data is available in the cache" do
      let!(:url) { "https://daringfireball.net" }
      let!(:spider) { Arachnid2::Typhoeus.new(url) }
      let!(:opts) { { time_box: 10, max_urls: 1 } }
      let!(:payload) {
        OpenStruct.new({effective_url: "http://daringfireball.net", body: "<html></html>"})
      } # note that the url and effective_url domains must match

      before(:each) do
        allow(spider).to receive(:load_data).with(url, opts).and_return(payload)
      end

      it "loads data from the cache" do
        responses = []
        expect(spider).to receive(:load_data).with(url, opts).and_return(payload)

        spider.crawl(opts){|r| responses << r}
        expect(responses).to include(payload)
      end
    end
  end
end
