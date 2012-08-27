require 'osmer/mapper/base'

class Osmer::Mapper::Bool < Osmer::Mapper::Base

  def fields
    { name => "BOOLEAN" }
  end

  def assigns
    { name => "(src_tags->'#{name}') IN ('true','yes','y','1')" }
  end

end
