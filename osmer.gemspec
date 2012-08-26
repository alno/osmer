require File.expand_path("../lib/osmer/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "osmer"
  s.version = Osmer::VERSION::STRING
  s.platform = Gem::Platform::RUBY
  s.authors = ["Alexey Noskov"]
  s.email = ["alexey.noskov@gmail.com"]
  s.homepage = "http://github.com/alno/osmer"
  s.summary = "Gem for managing OpenStreetMap data in PostgreSQL database"
  s.description = "Gem for managing OpenStreetMap data in PostgreSQL database"

  s.required_rubygems_version = ">= 1.3.6"

  # Gem dependencies
  s.add_dependency "pg", ">= 0.11.0"
  s.add_dependency "thor", ">= 0.14.6"

  # Development dependencies
  s.add_development_dependency "rspec", "~> 2.9.0"
  s.add_development_dependency "rspec-steps", ">= 0.0.8"
  s.add_development_dependency "rake"
  s.add_development_dependency "yard"

  # Gem files
  s.files = Dir["lib/**/*.rb", "bin/*", "data/*", "MIT-LICENSE", "README.rdoc"]
  s.extra_rdoc_files = ["README.rdoc", "MIT-LICENSE"]
  s.require_path = 'lib'
  s.executables  = ['osmer']

  # Info
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Osmer", "--main", "README.rdoc"]

end
