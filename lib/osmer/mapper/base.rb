require 'osmer'

class Osmer::Mapper::Base

  attr_reader :name

  def initialize(name, options = {})
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
