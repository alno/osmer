
schema :src, :type => :osm2pgsql, :projection => 4326

schema :dst, :projection => 900913, :source => :src do

  lines :roads do # Table of roads
    map :highway # It contains features with highway tag

    where :oneway => :yes
  end

end
