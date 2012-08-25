require 'osmer/thor_base'

class Osmer::Data::App < Osmer::ThorBase
  namespace :data

  desc "import SCHEMA FILE", "Import data to given schema from file"
  def import(schema, file)
    osmer.find_schema(schema).import! db, file
  end

end
