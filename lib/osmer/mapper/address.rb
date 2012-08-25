require 'osmer/mapper/base'

class Osmer::Mapper::Address < Osmer::Mapper::Base

  def assigns
    { :street => "src_tags->'addr:street'",
      :housenumber => "src_tags->'addr:housenumber'",
      :city => "src_tags->'addr:city'",
      :postcode => "src_tags->'addr:postcode'" }
  end

  def fields
    { :street => "VARCHAR(255)",
      :housenumber => 'VARCHAR(255)',
      :city => "VARCHAR(255)",
      :postcode => "VARCHAR(100)" }
  end

end
