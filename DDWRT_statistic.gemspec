# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'DDWRT_statistic/version'

Gem::Specification.new do |gem|
  gem.name          = "DDWRT_statistic"
  gem.version       = DDWRTStatistic::VERSION
  gem.authors       = ["maksym.shtyria"]
  gem.email         = ["maksym.shtyria@yandex.ru"]
  gem.description   = %q{This gem collects statistics from routers DDWRT for telnet and writes to the database}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
