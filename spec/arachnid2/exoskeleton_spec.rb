require 'spec_helper.rb'

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
