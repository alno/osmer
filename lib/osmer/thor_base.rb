require 'osmer'
require 'thor'

class Osmer::ThorBase < Thor

  class_option :config, :default => 'Osmfile', :desc => 'Config file location'

  class_option :dbhost, :default => 'localhost', :desc => 'Database host'
  class_option :dbport, :default => '5432', :desc => 'Database port'
  class_option :dbuser, :desc => 'Database user'
  class_option :dbpass, :desc => 'Database password'
  class_option :dbname, :desc => 'Database name'

  private

  def db
    require 'osmer/target/pg'

    @db ||= Osmer::Target::Pg.new :username => options[:dbuser], :password => options[:dbpass], :host => options[:dbhost], :port => options[:dbport], :database => options[:dbname]
  end

  def osmer
    @osmer ||= Osmer.new.configure options[:config]
  end

end
