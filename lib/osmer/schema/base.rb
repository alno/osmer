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

  def recreate!(db, colls = nil)
    drop! db, colls
    create! db, colls
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

    def method_missing(method, *args)
      if schema.respond_to?("#{method}=") && !args.empty?
        if args.size > 1
          schema.send "#{method}=", args
        else
          schema.send "#{method}=", args.first
        end
      else
        super
      end
    end

  end

end
