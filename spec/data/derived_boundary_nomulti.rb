
schema :src, :type => :osm2pgsql, :projection => 4326

schema :dst, :source => :src do

  lines :boundaries do
    map :boundary
  end

end
