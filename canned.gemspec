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
  gem.summary       = %q{Profile based authorization for ruby on rails, provides a simple DSL for specifying controller access restrictions, also considers resource loading and attribute accesibility}
  gem.homepage      = "http://www.platan.us"

  gem.files         = Dir["{lib,spec}/**/*", "[A-Z]*", "init.rb"] - ["Gemfile.lock"]
  gem.require_path  = "lib"

  gem.add_dependency "rails", "~> 3.2.2"
  gem.add_development_dependency "rspec"
end
