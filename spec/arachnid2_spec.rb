require 'spec_helper.rb'

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
