require 'osmer/mapper/base'

class Osmer::Mapper::Area < Osmer::Mapper::Base

  def assigns
    { :area => "ST_Area(#{table.mappers[:geometry].assigns[:geometry]})" }
  end

  def fields
    { :area => "REAL" }
  end

end
