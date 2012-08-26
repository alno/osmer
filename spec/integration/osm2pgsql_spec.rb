require 'spec_helper'

describe "Osmer" do

  steps "with osm2pgsql source" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'osm2pgsql.rb') }

    it "should clear schemas" do
      osmer.drop_all! DB
    end

    it "should recreate tables" do
      osmer.create_all! DB
    end

    it "should have right tables database after schema creation" do
      DB.in_transaction do |conn|
        tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'osmer_source_%'").values.flatten
        tables.should =~ ['osmer_source_point', 'osmer_source_line', 'osmer_source_polygon', 'osmer_source_roads', 'osmer_source_nodes', 'osmer_source_ways', 'osmer_source_rels']
      end
    end

    it "should import data" do
      osmer.find_schema('source').import_data! DB, File.join(DATAPATH, 'area_1.osm.pbf')
    end

    it "should have right data in database after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM osmer_source_point").values.flatten.first.to_i.should > 0
        conn.exec("SELECT COUNT(1) FROM osmer_source_line").values.flatten.first.to_i.should > 0
        conn.exec("SELECT COUNT(1) FROM osmer_source_polygon").values.flatten.first.to_i.should > 0
      end
    end

  end

end
