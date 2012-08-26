require 'spec_helper'

describe "Osmer" do

  steps "on basic area" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_basic.rb') }

    it "should clear schemas" do
      osmer.drop_all! DB
    end

    it "should recreate tables" do
      osmer.create_all! DB
    end

    it "should have right tables database after schema creation" do
      DB.in_transaction do |conn|
        src_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'src_%'").values.flatten
        src_tables.should =~ ['src_point', 'src_line', 'src_polygon', 'src_roads', 'src_nodes', 'src_ways', 'src_rels']

        dst_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'dst_%'").values.flatten
        dst_tables.should =~ ['dst_buildings', 'dst_roads']
      end
    end

    it "should import data" do
      osmer.find_schema(:src).import_data! DB, File.join(DATAPATH, 'area_1.osm.pbf')
    end

    it "should have right data in database after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM dst_roads").values.flatten.first.to_i.should > 0
        conn.exec("SELECT COUNT(1) FROM dst_buildings").values.flatten.first.to_i.should > 0
      end
    end

    it "should have no wrong data in database after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM dst_roads WHERE (tags->'highway') IS NULL").values.flatten.first.to_i.should == 0
        conn.exec("SELECT COUNT(1) FROM dst_buildings WHERE (tags->'building') IS NULL").values.flatten.first.to_i.should == 0
      end
    end

  end

  steps "with boundaries as lines on area with incomplete boundaries" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_boundary_nomulti.rb') }

    it "should clear schemas" do
      osmer.drop_all! DB
    end

    it "should recreate tables" do
      osmer.create_all! DB
    end

    it "should have right tables database after schema creation" do
      DB.in_transaction do |conn|
        src_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'src_%'").values.flatten
        src_tables.should =~ ['src_point', 'src_line', 'src_polygon', 'src_roads', 'src_nodes', 'src_ways', 'src_rels']

        dst_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'dst_%'").values.flatten
        dst_tables.should =~ ['dst_boundaries']
      end
    end

    it "should import data" do
      osmer.find_schema(:src).import_data! DB, File.join(DATAPATH, 'area_incomplete_boundary.osm.pbf')
    end

    it "should have right data in database after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM dst_boundaries").values.flatten.first.to_i.should > 0
      end
    end

    it "should have errors in log after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM osmer_error_records").values.flatten.first.to_i.should > 0
      end
    end
  end

end
