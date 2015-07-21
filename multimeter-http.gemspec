$: << File.expand_path('../lib', __FILE__)

require 'rake'
require 'multimeter/version'

Gem::Specification.new do |s|
  s.name        = 'multimeter-http'
  s.version     = Multimeter::VERSION
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg', 'Joel Segerlind']
  s.email       = ['theo@iconara.net', 'joel.segerlind@gmail.com']
  s.homepage    = 'http://github.com/iconara/multimeter'
  s.summary     = 'Multimeter addition for serving metrics over HTTP'
  s.description = 'Multimeter addition for serving metrics over HTTP, using Dropwizard\'s (a.k.a. Coda Hale\'s) Metrics libraries under the hood.'
  s.license     = 'Apache-2.0'

  s.add_dependency 'multimeter', "= #{Multimeter::VERSION}"
  s.add_dependency 'metrics-servlets-jars', '~> 3.1'
  s.add_dependency 'rjack-jetty', '~> 9.2.12'

  s.files         = Dir['lib/multimeter/http.rb']
  s.require_paths = %w[lib]
end
