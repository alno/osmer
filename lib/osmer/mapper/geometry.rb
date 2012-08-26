require 'osmer/mapper/base'

class Osmer::Mapper::Geometry < Osmer::Mapper::Base

  def assigns
    if table.type.to_s.start_with? 'multi'
      { :geometry => "ST_Transform(ST_Multi(src_geometry), #{table.projection})" }
    else
      { :geometry => "ST_Transform(src_geometry, #{table.projection})" }
    end
  end

  def fields
    {}
  end

  def indexes
    { :geometry => 'GIST(geometry)' }
  end

  def after_create(db, conn, table_name)
    conn.exec "SELECT AddGeometryColumn('#{table_name}', 'geometry', #{table.projection}, '#{db.geometry_type table.type}', 2)"
    conn.exec "ALTER TABLE #{table_name} ALTER COLUMN geometry SET NOT NULL"
  end

end
