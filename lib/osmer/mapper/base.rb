require 'osmer'

class Osmer::Mapper::Base

  attr_reader :table, :name

  def initialize(table, name, options = {})
    @table = table
    @name = name
  end

  def fields
    { name => "TEXT" }
  end

  def assigns
    { name => "src_tags->'#{name}'" }
  end

  def conditions
    []
  end

  def indexes
    {}
  end

  # Hook which will be called after table creation
  def after_create(db, conn, table_name)
  end

end
