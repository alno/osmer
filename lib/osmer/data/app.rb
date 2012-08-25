require 'osmer/thor_base'

class Osmer::Data::App < Osmer::ThorBase
  namespace :data

  desc "import SCHEMA FILE", "Import data to given schema from file"
  def import(schema, file)
    osmer.find_schema(schema).import_data! db, file
  end

  desc "update SCHEMA FILE", "Update data in schema from given change file"
  def update(schema, file)
    osmer.find_schema(schema).update_data! db, file
  end

end
