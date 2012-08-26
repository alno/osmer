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

RSpec.configure do |config|

  config.before do
    DB.in_transaction do |conn|
      tables = conn.exec("select table_name from information_schema.tables where table_schema NOT IN('pg_catalog','information_schema') AND table_name NOT IN('spatial_ref_sys', 'geometry_columns')").values.flatten
      tables.each do |table|
        conn.exec "DROP TABLE #{table}"
      end
    end
  end

end
