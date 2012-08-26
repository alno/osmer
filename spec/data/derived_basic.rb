
schema :src, :type => :osm2pgsql, :projection => 4326

schema :dst, :projection => 900913, :source => :src do

  lines :roads do # Table of roads
    map :highway # It contains features with highway tag

    with :ref => :string # And maps ref tag to additional table column
  end

  multipolygons :buildings do
    map :building

    with :address
  end

end
