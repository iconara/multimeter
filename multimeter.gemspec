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
  s.description = 'Multimeter provides a thin wrapper around Yammer\'s Metrics library under the hood.'

  s.rubyforge_project = 'multimeter'

  s.add_dependency 'metrics-core-jars', '~> 3.0.2'

  s.files         = Dir['lib/**/*.rb']
  s.require_paths = %w[lib]
end
