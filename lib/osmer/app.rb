require 'osmer/thor_base'
require 'osmer/data/app'
require 'osmer/schema/app'

require 'thor/group'

class Osmer::App < Osmer::ThorBase

  register Osmer::Data::App, 'data', 'data <command>', 'OSM data management'
  register Osmer::Schema::App, 'schema', 'schema <command>', 'OSM schema management'

end
