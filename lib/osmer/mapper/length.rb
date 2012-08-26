require 'osmer/mapper/base'

class Osmer::Mapper::Length < Osmer::Mapper::Base

  def assigns
    { :area => "ST_Length(ST_Transform(src_geometry,#{table.projection}))" }
  end

  def fields
    { :area => "REAL" }
  end

end
