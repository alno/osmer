require 'rspec/core/rake_task'
require 'yard/rake/yardoc_task'

desc 'Default: run specs'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new('spec:coverage') do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['app/**/*.rb', 'lib/**/*.rb', '-', 'doc/FAQ.md', 'doc/Changes.md']
end
