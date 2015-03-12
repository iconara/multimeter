require 'bundler/setup'
require 'bundler/gem_helper'
require 'rake/javaextensiontask'
require 'rspec/core/rake_task'

Rake::JavaExtensionTask.new('multimeter_metrics') do |ext|
  ext.ext_dir = 'ext/java'
  jruby_home = RbConfig::CONFIG['prefix']
  jars = ["#{jruby_home}/lib/jruby.jar"]
  jars.concat($LOAD_PATH.flat_map { |path| Dir["#{path}/**/*.jar"] })
  ext.classpath = jars.map { |x| File.expand_path(x) }.join(':')
  ext.source_version = '1.7'
  ext.target_version = '1.7'
end

namespace :bundler do
  Bundler::GemHelper.install_tasks
end

task :release => [:spec, :compile, 'bundler:release']

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = File.read('.rspec').split("\n")
end

task :spec => :compile

task :default => :spec
