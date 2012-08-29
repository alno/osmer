require 'osmer/schema/base'

class Osmer::Schema::Osm2pgsql < Osmer::Schema::Base

  attr_accessor :osm2pgsql_binary, :bbox, :updater

  def initialize(*args)
    @osm2pgsql_binary = 'osm2pgsql'
    super
  end

  # Create schema in given database
  def create!(db, colls = nil)
    db.in_transaction do |conn|
      raise StandardError.new("Schema #{name} already created!") unless schema_tables(conn).empty?
    end

    osm2pgsql_exec db, "'#{empty_file}'", "creating osm2pgsql schema"
  end

  # Drop schema in given database
  def drop!(db, colls = nil)
    db.in_transaction do |conn|
      schema_tables(conn).each do |table|
        conn.exec "DROP TABLE IF EXISTS #{table}"
      end
    end
  end

  def import_data!(db, file = nil)
    raise StandardError.new("No file or updater specified") unless file or updater

    db.in_transaction do |conn|
      schema_tables(conn).each do |table|
        conn.exec "DELETE FROM #{table}"
      end
    end

    if file
      osm2pgsql_exec db, "-a '#{file}'", "importing data with osm2pgsql from #{file}"
    else
      updater.load_dump db, self do |f|
        osm2pgsql_exec db, "-a '#{f}'", "importing data with osm2pgsql from #{f}"
      end
    end
  end

  def update_data!(db, file = nil)
    raise StandardError.new("No file or updater specified") unless file or updater

    if file
      osm2pgsql_exec db, "-a '#{file}'", "importing data with osm2pgsql from #{file}"
    else
      updater.load_diffs db, self do |f|
        osm2pgsql_exec db, "-a '#{f}'", "importing data with osm2pgsql from #{f}"
      end
    end
  end

  def attach_listener!(conn, collection, name, fields)
    table  = collection_table collection
    args = fields.map{|f| collection_field(collection, f) }.join(', ')

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{name}_insert_proxy() RETURNS trigger AS $$
      BEGIN
        PERFORM #{name}_insert(#{unique_id_expr(collection, 'NEW.osm_id')}, #{args});
        RETURN NULL;
      END; $$ LANGUAGE plpgsql}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{name}_update_proxy() RETURNS trigger AS $$
      BEGIN
        PERFORM #{name}_update(#{unique_id_expr(collection, 'NEW.osm_id')}, #{args});
        RETURN NULL;
      END; $$ LANGUAGE plpgsql}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{name}_delete_proxy() RETURNS trigger AS $$
      BEGIN
        PERFORM #{name}_delete(#{unique_id_expr(collection, 'OLD.osm_id')});
        RETURN NULL;
      END; $$ LANGUAGE plpgsql}

    # Create new triggers
    conn.exec "CREATE TRIGGER #{name}_insert_trigger AFTER INSERT ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{name}_insert_proxy()"
    conn.exec "CREATE TRIGGER #{name}_update_trigger AFTER UPDATE ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{name}_update_proxy()"
    conn.exec "CREATE TRIGGER #{name}_delete_trigger AFTER DELETE ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{name}_delete_proxy()"

    # Prepopulate dependency
    conn.exec "SELECT #{name}_insert(NEW.osm_id, #{args}) FROM #{table} NEW"
  end

  def detach_listener!(conn, collection, name, fields)
    table  = collection_table collection

    return unless schema_tables(conn).include? table

    # Drop triggers
    conn.exec "DROP TRIGGER IF EXISTS #{name}_insert_trigger ON #{table}"
    conn.exec "DROP TRIGGER IF EXISTS #{name}_update_trigger ON #{table}"
    conn.exec "DROP TRIGGER IF EXISTS #{name}_delete_trigger ON #{table}"
  end

  private

  def osm2pgsql_exec(db, tail, desc)
    cmd = "'#{osm2pgsql_binary}' -j -m -G --slim -U #{db[:username]} -d #{db[:database]} -H #{db[:host]} -p '#{table_prefix}'"
    cmd << " --bbox #{bbox.join(',')}" if bbox # Restrict import if bbox specified

    case projection.to_i
    when 4326 then cmd << ' --latlong'
    when 900913 then cmd << ' --merc'
    else raise StandardError.new("Unsupported projection #{projection}")
    end

    ENV['PGPASS'] = db[:password]

    puts "#{cmd} #{tail}"
    system "#{cmd} #{tail}" or raise StandardError.new("Error #{desc}")
  end

  def schema_tables(conn)
    res = conn.exec "select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE '#{table_prefix}_%'"
    tables = res.values.flatten
    res.clear
    tables
  end

  # Map id to unique by encoding last digit in result
  # nodes: {id}1
  # ways: {id}2
  # relations: {id}3
  def unique_id_expr(collection, id_expr)
    case collection.to_s
    when 'polygons', 'lines' then "CASE WHEN #{id_expr} > 0 THEN 10*#{id_expr} + 2 ELSE 3 - 10*#{id_expr} END"
    when 'points' then "10*#{id_expr} + 1"
    else raise StandardError.new("Unsupported collection '#{collection}'")
    end
  end

  def collection_table(collection)
    case collection.to_s
    when 'polygons' then "#{table_prefix}_polygon"
    when 'lines' then "#{table_prefix}_line"
    when 'points' then "#{table_prefix}_point"
    else raise StandardError.new("Unsupported collection '#{collection}'")
    end
  end

  def collection_field(collection, field)
    case field.to_s
    when 'geometry' then 'NEW.way'
    when 'tags' then 'NEW.tags'
    else raise StandardError.new("Unsupported field '#{field}' in collection '#{collection}'")
    end
  end

  def empty_file
    File.expand_path("../../../../data/empty.osm", __FILE__)
  end

  class Dsl < Osmer::Schema::Base::Dsl

    def updates(interval = nil, &block)
      require 'osmer/updater'

      schema.updater = Osmer::Updater.new(interval).configure(&block)
    end

  end

end
