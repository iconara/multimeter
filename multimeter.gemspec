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
  s.summary     = 'JRuby application metric instrumentation using Dropwizard\'s Metrics'
  s.description = 'Multimeter provides a thin wrapper around Dropwizard\'s (a.k.a. Coda Hale\'s) Metrics library under the hood.'
  s.license     = 'Apache-2.0'

  s.rubyforge_project = 'multimeter'

  s.add_dependency 'metrics-core-jars', '~> 3.1', '< 4.0.0'
  s.add_dependency 'metrics-json-jars', '~> 3.1'

  s.files         = %w[lib/multimeter.rb lib/multimeter_metrics.jar lib/multimeter/json.rb lib/multimeter/rack.rb]
  s.require_paths = %w[lib]
end
