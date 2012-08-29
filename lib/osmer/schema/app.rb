require 'osmer/thor_base'

class Osmer::Schema::App < Osmer::ThorBase
  namespace :schema

  desc "create [SCHEMA] [TABLES]", "Create given osm schema in database (create all if none specified)"
  def create(schema = nil, tables = nil)
    if tables
      osmer.find_schema(schema).create! db, tables.split(',')
    elsif schema
      osmer.find_schema(schema).create! db
    else
      osmer.create_all! db
    end
  end

  desc "recreate [SCHEMA] [TABLES]", "Recreate given osm schema in database (recreate all if none specified)"
  def recreate(schema = nil, tables = nil)
    if tables
      osmer.find_schema(schema).recreate! db, tables.split(',')
    elsif schema
      osmer.find_schema(schema).recreate! db
    else
      osmer.recreate_all! db
    end
  end

  desc "drop [SCHEMA] [TABLES]", "Drop given osm schema in database (drop all if none specified)"
  def drop(schema = nil, tables = nil)
    if tables
      osmer.find_schema(schema).drop! db, tables.split(',')
    elsif schema
      osmer.find_schema(schema).drop! db
    else
      osmer.drop_all! db
    end
  end

end
