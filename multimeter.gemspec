$: << File.expand_path('../lib', __FILE__)

require 'rake'
require 'multimeter/version'


Gem::Specification.new do |s|
  s.name        = 'multimeter'
  s.version     = Multimeter::VERSION
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg']
  s.email       = ['theo@iconara.net']
  s.homepage    = 'http://github.com/iconara/multimeter'
  s.summary     = 'JRuby application metric instrumentation using Yammer\'s Metrics'
  s.description = 'Multimeter provides a JRuby DSL for instrumenting your application. It uses Yammer\'s Metrics library under the hood.'

  s.rubyforge_project = 'multimeter'

  s.add_dependency 'metrics-core-jars', '~> 3.0.2'

  s.files         = FileList['lib/**/*.rb'].to_a
  s.require_paths = %w[lib]
end
