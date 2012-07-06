$: << 'lib'

require 'multimeter/version'


task :release do
  version_string = "v#{Multimeter::VERSION}"
  unless %x(git tag -l).include?(version_string)
    system %(git tag -a #{version_string} -m #{version_string})
  end
  system %(git push && git push --tags)
  system %(gem build multimeter.gemspec && gem inabox multimeter-*.gem && mv multimeter-*.gem pkg)
end