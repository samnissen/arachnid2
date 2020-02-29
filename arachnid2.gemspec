
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "arachnid2/version"

Gem::Specification.new do |spec|
  spec.name          = "arachnid2"
  spec.version       = Arachnid2::VERSION
  spec.authors       = ["Sam Nissen"]
  spec.email         = ["scnissen@gmail.com"]

  spec.summary       = %q{A simple, fast web crawler}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/samnissen/arachnid2"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "webdriver-user-agent", ">= 7.6"
  spec.add_dependency "watir"
  spec.add_dependency "webdrivers"
  spec.add_dependency "typhoeus"
  spec.add_dependency "bloomfilter-rb"
  spec.add_dependency "adomain"
  spec.add_dependency "addressable"
  spec.add_dependency "nokogiri", ">= 1.10.4"
end
