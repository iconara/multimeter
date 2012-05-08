$: << File.expand_path('../lib', __FILE__)

require 'rake'


Gem::Specification.new do |s|
  s.name        = 'multimeter'
  s.version     = '1.0.0'
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg']
  s.email       = ['theo@iconara.net']
  s.homepage    = 'http://github.com/iconara/multimeter'
  s.summary     = 'JRuby application metric instrumentation using Yammer\'s Metrics'
  s.description = 'Multimeter provides a JRuby DSL for instrumenting your application. It uses Yammer\'s Metrics library under the hood.'

  s.rubyforge_project = 'multimeter'
  
  s.add_dependency 'metrics-core-jars'
  
  s.files         = FileList['lib/**/*.rb'].to_a
  s.require_paths = %w[lib]
end
