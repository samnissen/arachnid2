# Arachnid2

## About

Arachnid2 is a simple, fast web-crawler written in Ruby.
It uses [typhoeus](https://github.com/typhoeus/typhoeus)
to get HTTP requests,
[bloomfilter-rb](https://github.com/igrigorik/bloomfilter-rb)
to store the URLs it will get and has gotten,
and [nokogiri](https://github.com/sparklemotion/nokogiri)
to find the URLs on each webpage.

Arachnid2 is a successor to [Arachnid](https://github.com/dchuk/Arachnid),
and was abstracted out of the [Tellurion Bot](https://github.com/samnissen/tellurion_bot).

## Usage

The basic use of Arachnid2 is surfacing the responses from a domains'
URLs by visiting a URL, collecting any links to the same domain
on that page, and visiting those to do the same.

Hence, the simplest output would be to collect all of the responses
while spidering from some URL.

```ruby
require "arachnid2"

url = "http://www.maximumfun.org"
spider = Arachnid2.new(url)
responses = []

spider.crawl { |response|
  responses << response
}
```

Obviously this could become unwieldy,
so you can execute logic within the spidering to collect a narrow subset
of the responses, transform or dissect the response,
or both (or whatever you want).

```ruby
require "arachnid2"
require "nokogiri"

url = "https://daringfireball.net"
spider = Arachnid2.new(url)
responses = []

spider.crawl { |response|
  responses << Nokogiri::HTML(response.body) if response.effective_url =~ /.*amazon.*/
  print '*'
}
```

`Arachnid2#crawl` will return always `nil`.

### Options

```ruby
require "arachnid2"

url = "http://sixcolours.com"
spider = Arachnid2.new(url)
opts = {
  time_box: 60,
  max_urls: 50,
  language: "en-UK",
  user_agent: "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0"
}
responses = []

spider.crawl(opts) { |response|
  responses << response
}
```

#### `time_box`

The crawler will time-bound your spidering. If no valid integer is provided,
it will crawl for 15 seconds before exiting. 600 seconds (10 minutes)
is the current maximum, and any value above it will be reduced to 600.

#### `max_urls`

The crawler will crawl a limited number of URLs before stopping.
If no valid integer is provided, it will crawl for 50 URLs before exiting.
10000 seconds is the current maximum,
and any value above it will be reduced to 10000.

#### `language`

The language is a string mapped to the HTTP header Accept-Language. The
default is
`en-IE, en-UK;q=0.9, en-NL;q=0.8, en-MT;q=0.7, en-LU;q=0.6, en;q=0.5, \*;0.4`

#### `user_agent`

This user agent is a string mapped to the HTTP header User-Agent. The
default is
`Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1 Safari/605.1.15`

### Memory use in Docker

In case you are operating the crawler within a container, Arachnid2
will attempt to prevent the container from running out of memory,
and crawls will end when the container has <= 20% of its available memory
free.

### Non-HTML links

The crawler attempts to stop itself from returning data from
links that are not indicative of HTML, as detailed in
`Arachnid2::NON_HTML_EXTENSIONS`.

## Development

TODO: this

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/samnissen/arachnid2.
This project is intended to be a safe,
welcoming space for collaboration,
and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Arachnid2 project’s codebases,
issue trackers, chat rooms and mailing lists is expected
to follow the
[code of conduct](https://github.com/samnissen/arachnid2/blob/master/CODE_OF_CONDUCT.md).
