require 'spec_helper'

describe "Osmer" do

  steps "with osm2pgsql source" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_basic.rb') }

    it "should clear schemas" do
      osmer.drop_all! DB
    end

    it "should recreate tables" do
      osmer.create_all! DB

      DB.in_transaction do |conn|
        src_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'src_%'").values.flatten
        src_tables.should =~ ['src_point', 'src_line', 'src_polygon', 'src_roads', 'src_nodes', 'src_ways', 'src_rels']

        dst_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'dst_%'").values.flatten
        dst_tables.should =~ ['dst_buildings', 'dst_roads']
      end
    end

    it "should import data" do
      osmer.find_schema(:src).import_data! DB, File.join(DATAPATH, 'set1.osm.pbf')

      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM dst_roads").values.flatten.first.to_i.should > 0
        conn.exec("SELECT COUNT(1) FROM dst_buildings").values.flatten.first.to_i.should > 0
      end
    end

    it "should not import wrong data" do
      osmer.find_schema(:src).import_data! DB, File.join(DATAPATH, 'set1.osm.pbf')

      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM dst_roads WHERE (tags->'highway') IS NULL").values.flatten.first.to_i.should == 0
        conn.exec("SELECT COUNT(1) FROM dst_buildings WHERE (tags->'building') IS NULL").values.flatten.first.to_i.should == 0
      end
    end

  end

end
