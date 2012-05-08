$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'multimeter'
  s.version     = '1.0.0'
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg']
  s.email       = ['theo@iconara.net']
  s.homepage    = 'http://github.com/iconara/multimeter'
  s.summary     = ''
  s.description = ''

  s.rubyforge_project = 'multimeter'
  
  s.add_dependency 'metrics-core-jars'
  
  s.files         = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
