require 'osmer/mapper/base'

class Osmer::Mapper::Tags < Osmer::Mapper::Base

  def fields
    { :tags => "HSTORE" }
  end

  def assigns
    { :tags => "src_tags" }
  end

end
