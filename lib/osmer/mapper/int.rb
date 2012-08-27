require 'osmer/mapper/base'

class Osmer::Mapper::Int < Osmer::Mapper::Base

  def fields
    { name => "INTEGER" }
  end

  def assigns
    { name => "CASE WHEN (src_tags->'#{name}') ~ E'^[-+]?[\\\\d\\\\s]+$' THEN replace(src_tags->'#{name}',' ','')::INTEGER ELSE NULL END" }
  end

end
