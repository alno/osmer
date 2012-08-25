require 'osmer/thor_base'

class Osmer::Schema::App < Osmer::ThorBase
  namespace :schema

  desc "create [SCHEMA]", "Create given osm schema in database (create all if none specified)"
  def create(schema = nil)
    if schema
      osmer.find_schema(schema).create! db
    else
      osmer.create_all! db
    end
  end

  desc "recreate [SCHEMA]", "Recreate given osm schema in database (recreate all if none specified)"
  def recreate(schema = nil)
    if schema
      osmer.find_schema(schema).recreate! db
    else
      osmer.recreate_all! db
    end
  end

  desc "drop [SCHEMA]", "Drop given osm schema in database (drop all if none specified)"
  def drop(schema = nil)
    if schema
      osmer.find_schema(schema).drop! db
    else
      osmer.drop_all! db
    end
  end

end
