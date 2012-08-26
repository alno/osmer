require 'osmer/mapper/base'

class Osmer::Mapper::Area < Osmer::Mapper::Base

  def assigns
    { :area => "ST_Area(ST_Transform(src_geometry,#{table.projection}))" }
  end

  def fields
    { :area => "REAL" }
  end

end
