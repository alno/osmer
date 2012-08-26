require 'rspec'
require 'rspec-steps'

require 'osmer'
require 'osmer/target/pg'

DATAPATH = File.expand_path '../data', __FILE__
CONFPATH = if File.exists? File.expand_path('../config.yml', __FILE__)
  File.expand_path('../config.yml', __FILE__)
else
  File.expand_path('../config.example.yml', __FILE__)
end

CONF = YAML.load(File.read CONFPATH)
DB = Osmer::Target::Pg.new :username => CONF['dbuser'], :password => CONF['dbpass'], :host => CONF['dbhost'], :port => CONF['dbport'], :database => CONF['dbname']

RSpec.configure do
end
