require 'osmer/mapper/base'

class Osmer::Mapper::Length < Osmer::Mapper::Base

  def assigns
    { :length => "ST_Length(#{table.mappers[:geometry].assigns[:geometry]})" }
  end

  def fields
    { :length => "REAL" }
  end

end
