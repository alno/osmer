require 'osmer/mapper/base'

class Osmer::Mapper::Length < Osmer::Mapper::Base

  def assigns
    { :area => "ST_Length(#{table.mappers[:geometry].assigns[:geometry]})" }
  end

  def fields
    { :area => "REAL" }
  end

end
