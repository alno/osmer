require 'osmer'

class Osmer::Schema::Base

  include Osmer::Configurable

  attr_reader :ns, :name
  attr_accessor :projection

  def initialize(ns, name, options = {})
    @ns = ns
    @name = name
    @projection = 4326

    options.each do |k,v| # Assign all schema options
      send "#{k}=", v
    end
  end

  # Create schema in given database
  def create!(db)
    raise StandardError.new("Not implemented")
  end

  # Drop schema in given database
  def drop!(db)
    raise StandardError.new("Not implemented")
  end

  def recreate!(db)
    drop! db
    create! db
  end

  # Add collection listener
  # name - stored procedure name
  #
  def attach_listener!(conn, collection, name, fields)
    raise StandardError.new("Not implemented")
  end

  def detach_listener!(conn, collection, name, fields)
    raise StandardError.new("Not implemented")
  end

  def table_prefix
    [@ns.prefix, name].compact.join('_')
  end

  private

  class Dsl < Struct.new(:schema)
  end

end
