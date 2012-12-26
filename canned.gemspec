# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "canned/version"

Gem::Specification.new do |s|
  s.name          = "canned"
  s.version       = Canned::VERSION
  s.authors       = ["Ignacio Baixas"]
  s.email         = ["ignacio@platan.us"]
  s.description   = %q{Profile based authorization for ruby on rails}
  s.summary       = %q{Profile based authorization for ruby on rails, provides a simple DSL for specifying controller access restrictions, also considers resource loading and attribute accesibility}
  s.homepage      = "http://www.platan.us"

  s.rubyforge_project = "canned"

  s.files         = Dir["{lib,spec}/**/*", "[A-Z]*"] - ["Gemfile.lock"]
  s.require_paths = ["lib"]

  s.add_development_dependency "rails", "~> 3.2.2"
  s.add_development_dependency "rspec"
end
