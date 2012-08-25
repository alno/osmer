require 'osmer'
require 'thor'

class Osmer::ThorBase < Thor

  class_option :config, :aliases => '-c', :default => 'Osmfile', :desc => 'Config file location'

  class_option :dbhost, :aliases => '-h', :default => 'localhost', :desc => 'Database host'
  class_option :dbport, :aliases => '-p', :default => '5432', :desc => 'Database port'
  class_option :dbuser, :aliases => '-U', :desc => 'Database user'
  class_option :dbpass, :aliases => '-P', :desc => 'Database password'
  class_option :dbname, :aliases => '-d', :desc => 'Database name'

  private

  def app_options
    @app_options = parent_options.merge(options)
  end

  def db
    require 'osmer/target/pg'

    @db ||= Osmer::Target::Pg.new :username => app_options[:dbuser], :password => app_options[:dbpass], :host => app_options[:dbhost], :port => app_options[:dbport], :database => app_options[:dbname]
  end

  def osmer
    @osmer ||= Osmer.new.configure app_options[:config]
  end

end
