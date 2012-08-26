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

end
