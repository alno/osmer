require 'osmer/thor_base'

class Osmer::Data::App < Osmer::ThorBase
  namespace :data

  desc "import SCHEMA [FILE]", "Import data to given schema from file"
  def import(schema, file = nil)
    osmer.find_schema(schema).import_data! db, file
  end

  desc "update SCHEMA [FILE]", "Update data in schema from given change file"
  def update(schema, file = nil)
    osmer.find_schema(schema).update_data! db, file
  end

  desc "count [SCHEMA]", "Count data in given schema (or in all schemas)"
  def count(schema = nil)
    res = if schema
      osmer.find_schema(schema).count_data! db
    else
      osmer.count_data! db
    end

    puts res.inspect
  end

end
