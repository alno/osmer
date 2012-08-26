require 'osmer/mapper/base'

class Osmer::Mapper::ZOrder < Osmer::Mapper::Base

  attr_reader :mapping

  def initialize(*args)
    super
    @mapping = {}
  end

  def <<(k)
    @mapping[k] = next_value
  end

  def []=(k, v)
    @mapping[k] = v.to_i
  end

  def next_value
    (@mapping.values.max || 0) + 1
  end

  def assigns
    if @mapping.empty?
      { :z_order => next_value }
    else
      { :z_order => "CASE #{table.mappers[:type].assigns[:type]} #{@mapping.map{|k,v| "WHEN '#{k}' THEN #{v}" }.join(' ')} ELSE #{next_value} END" }
    end
  end

  def fields
    { :z_order => "INTEGER" }
  end

end
