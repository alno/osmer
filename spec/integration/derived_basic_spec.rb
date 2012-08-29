require 'spec_helper'

describe "Osmer" do

  steps "on basic area" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_basic.rb') }

    it "should recreate tables" do
      osmer.recreate_all! DB
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
        @road_ids = conn.exec("SELECT id FROM dst_roads").values.flatten
        @road_ids.should_not be_empty

        @building_ids = conn.exec("SELECT id FROM dst_buildings").values.flatten
        @building_ids.should_not be_empty
      end
    end

    it "should have no wrong data in database after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM dst_roads WHERE (tags->'highway') IS NULL").values.flatten.first.to_i.should == 0
        conn.exec("SELECT COUNT(1) FROM dst_buildings WHERE (tags->'building') IS NULL").values.flatten.first.to_i.should == 0
      end
    end

    it "after recreating derived tables" do
      osmer.find_schema(:dst).recreate! DB
    end

    it "should contain same features" do
      DB.in_transaction do |conn|
        conn.exec("SELECT id FROM dst_roads").values.flatten.should =~ @road_ids
        conn.exec("SELECT id FROM dst_buildings").values.flatten.should =~ @building_ids
      end
    end

  end

  steps "with conds" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_conds.rb') }

    it "should recreate tables" do
      osmer.recreate_all! DB
    end

    it "should have right tables database after schema creation" do
      DB.in_transaction do |conn|
        src_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'src_%'").values.flatten
        src_tables.should =~ ['src_point', 'src_line', 'src_polygon', 'src_roads', 'src_nodes', 'src_ways', 'src_rels']

        dst_tables = conn.exec("select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE 'dst_%'").values.flatten
        dst_tables.should =~ ['dst_roads']
      end
    end

    it "should import data" do
      osmer.find_schema(:src).import_data! DB, File.join(DATAPATH, 'area_1.osm.pbf')
    end

    it "should have right data in database after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT id FROM dst_roads").values.flatten.should == ["239720002", "283922662"]
      end
    end

  end

  steps "with boundaries as lines on area with incomplete boundaries" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_boundary_nomulti.rb') }

    it "should recreate tables" do
      osmer.recreate_all! DB
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

    it "should have incomplete boundary imported" do
      DB.in_transaction do |conn|
        conn.exec("SELECT Sum(ST_Length(geometry)) FROM dst_boundaries WHERE id = 12540503").values.first.first.to_f.should be_between(0.05, 0.21)
      end
    end
  end

  steps "with boundaries as multilines on area with incomplete boundaries" do

    let(:osmer) { Osmer.new.configure File.join(DATAPATH, 'derived_boundary_multi.rb') }

    it "should recreate tables" do
      osmer.recreate_all! DB
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

    it "should have no errors in log after import" do
      DB.in_transaction do |conn|
        conn.exec("SELECT COUNT(1) FROM osmer_error_records").values.flatten.first.to_i.should == 0
      end
    end

    it "should have complete boundary imported" do
      DB.in_transaction do |conn|
        conn.exec("SELECT Sum(ST_Length(geometry)) FROM dst_boundaries WHERE id = 12540503").values.first.first.to_f.should be_between(0.26, 0.27)
      end
    end
  end

end
