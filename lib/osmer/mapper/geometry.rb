require 'osmer/mapper/base'

class Osmer::Mapper::Geometry < Osmer::Mapper::Base

  attr_accessor :simplify

  def assigns
    { :geometry => expr }
  end

  def fields
    {}
  end

  def conditions
    conds = []
    conds << "ST_NPoints(#{expr}) > 0" if simplify
    conds
  end

  def indexes
    { :geometry => 'GIST(geometry)' }
  end

  def after_create(db, conn, table_name)
    conn.exec "SELECT AddGeometryColumn('#{table_name}', 'geometry', #{table.projection}, '#{db.geometry_type table.type}', 2)"
    conn.exec "ALTER TABLE #{table_name} ALTER COLUMN geometry SET NOT NULL"
  end

  def expr
    res = "src_geometry"
    res = "ST_Multi(#{res})" if table.type.to_s.start_with? 'multi'
    res = "ST_Transform(#{res}, #{table.projection})"
    res = "ST_Simplify(#{res}, #{simplify.to_f})" if simplify
    res
  end

end
