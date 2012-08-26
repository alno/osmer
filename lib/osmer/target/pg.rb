require 'osmer'

require 'pg'

class Osmer::Target::Pg

  attr_accessor :options

  def initialize(options)
    @options = options
  end

  def [](key)
    @options[key]
  end

  def in_transaction
    conn = Connection.new connection_options

    begin
      conn.exec "BEGIN TRANSACTION"

      yield conn

      conn.exec "COMMIT"
    ensure
      conn.close
    end
  end

  GEOTYPES = { 'point' => 'POINT', 'line' => 'LINESTRING', 'polygon' => 'POLYGON', 'multiline' => 'MULTILINESTRING', 'multipolygon' => 'MULTIPOLYGON' }

  def geometry_type(type)
    GEOTYPES[type.to_s.gsub(/s\z/,'')] or raise StandardError.new("Unknown geometry type #{type.inspect}")
  end

  private

  def connection_options
    { :host => options[:host], :user => options[:username], :password => options[:password], :dbname => options[:database] }
  end

  class Connection < Struct.new(:options)

    def initialize(*args)
      super
      @conn = PG.connect options
    end

    def exec(q, *args)
      puts "  #{q}"
      @conn.exec q, *args
    end

    def close
      @conn.close
    end

  end

end
