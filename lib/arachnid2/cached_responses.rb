require 'net/http'
require 'json'
module CachedResponses
  CACHE_SERVICE_URL = ENV['ARACHNID_CACHED_SERVICE_ADDRESS'].freeze

  def load_data(_url, _options)
    return if check_config

    uri = URI("#{CACHE_SERVICE_URL}/typhoeus_responses?url=#{@url}&options=#{@options}")
    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'json'
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      response = http.request(req)
      return nil if response.code != '200'

      body = ::JSON.parse(response.body)
      responses_list = Base64.decode64(body['encrypted_response'])
      return Marshal.load responses_list # here we get an Array of `Typhoeus::Response`s
    end
  rescue StandardError
    nil
  end

  def put_cached_data(url, options, data)
    return if check_config

    uri = URI("#{CACHE_SERVICE_URL}/typhoeus_responses")

    header = { 'Content-Type': 'application/json' }
    req = Net::HTTP::Post.new(uri, header)
    processed_data = Base64.encode64(Marshal.dump(data))
    req.body = { url: url, options: options, encrypted_response: processed_data }.to_json
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end

  def check_config
    CACHE_SERVICE_URL.nil?
  end
end
