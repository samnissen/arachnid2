require "arachnid2/version"
require "arachnid2/cached_arachnid_responses"
require "arachnid2/exoskeleton"
require "arachnid2/typhoeus"
require "arachnid2/watir"

require 'tempfile'
require "typhoeus"
require "bloomfilter-rb"
require "adomain"
require "addressable/uri"
require "nokogiri"
require "base64"
require "webdrivers"
require "webdriver-user-agent"
require "watir"


class Arachnid2
  # META:
  #   About the origins of this crawling approach
  # The Crawler is heavily borrowed from by Arachnid.
  # Original: https://github.com/dchuk/Arachnid
  # Other iterations I've borrowed liberally from:
  #   - https://github.com/matstc/Arachnid
  #   - https://github.com/intrigueio/Arachnid
  #   - https://github.com/jhulme/Arachnid
  # And this was originally written as a part of Tellurion's bot
  # https://github.com/samnissen/tellurion_bot

  MAX_CRAWL_TIME = 10000
  BASE_CRAWL_TIME = 15
  MAX_URLS = 10000
  BASE_URLS = 50
  DEFAULT_LANGUAGE = "en-IE, en-UK;q=0.9, en-NL;q=0.8, en-MT;q=0.7, en-LU;q=0.6, en;q=0.5, *;0.4"
  DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1 Safari/605.1.15"

  DEFAULT_NON_HTML_EXTENSIONS = {
    3 => ['.gz'],
    4 => ['.jpg', '.png', '.m4a', '.mp3', '.mp4', '.pdf', '.zip',
          '.wmv', '.gif', '.doc', '.xls', '.pps', '.ppt', '.tar',
          '.iso', '.dmg', '.bin', '.ics', '.exe', '.wav', '.mid'],
    5 => ['.xlsx', '.docx', '.pptx', '.tiff', '.zipx'],
    8 => ['.torrent']
  }
  MEMORY_USE_FILE = "/sys/fs/cgroup/memory/memory.usage_in_bytes"
  MEMORY_LIMIT_FILE = "/sys/fs/cgroup/memory/memory.limit_in_bytes"
  DEFAULT_MAXIMUM_LOAD_RATE = 79.9

  DEFAULT_TIMEOUT = 10_000
  MINIMUM_TIMEOUT = 1
  MAXIMUM_TIMEOUT = 999_999

  #
  # Creates the object to execute the crawl
  #
  # @example
  #   url = "https://daringfireball.net"
  #   spider = Arachnid2.new(url)
  #
  # @param [String] url
  #
  # @return [Arachnid2] self
  #
  def initialize(url)
    @url = url
  end

  #
  # Visits a URL, gathering links and visiting them,
  # until running out of time, memory or attempts.
  #
  # @example
  #   url = "https://daringfireball.net"
  #   spider = Arachnid2.new(url)
  #
  #   opts = {
  #     :followlocation => true,
  #     :timeout => 25000,
  #     :time_box => 30,
  #     :headers => {
  #       'Accept-Language' => "en-UK",
  #       'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
  #     },
  #     :memory_limit => 89.99,
  #     :proxy => {
  #       :ip => "1.2.3.4",
  #       :port => "1234",
  #       :username => "sam",
  #       :password => "coolcoolcool",
  #     }
  #     :non_html_extensions => {
  #       3 => [".abc", ".xyz"],
  #       4 => [".abcd"],
  #       6 => [".abcdef"],
  #       11 => [".abcdefghijk"]
  #     }
  #   }
  #   responses = []
  #   spider.crawl(opts) { |response|
  #     responses << response
  #   }
  #
  # @param [Hash] opts
  #
  # @return nil
  #
  def crawl(opts = {}, with_watir = false)
    crawl_watir and return if with_watir

    Arachnid2::Typhoeus.new(@url).crawl(opts, &Proc.new)
  end

  def crawl_watir(opts)
    Arachnid2::Watir.new(@url).crawl(opts, &Proc.new)
  end
  # https://mudge.name/2011/01/26/passing-blocks-in-ruby-without-block.html

end
