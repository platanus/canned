# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'canned/version'

Gem::Specification.new do |gem|
  gem.name          = "canned"
  gem.version       = Canned::VERSION
  gem.authors       = ["Ignacio Baixas"]
  gem.email         = ["iobaixas@platan.us"]
  gem.description   = %q{Profile based authorization for ruby on rails}
  # gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = "http://www.platan.us"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "rails", "~> 3.2.2"
  gem.add_development_dependency "rspec"
end
