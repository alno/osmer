require 'osmer/mapper/base'

class Osmer::Mapper::Address < Osmer::Mapper::Base

  def assigns
    { :street => "src_tags->'addr:street'",
      :housenumber => "src_tags->'addr:housenumber'",
      :city => "src_tags->'addr:city'",
      :postcode => "src_tags->'addr:postcode'" }
  end

  def fields
    { :street => "TEXT",
      :housenumber => 'TEXT',
      :city => "TEXT",
      :postcode => "TEXT" }
  end

end
