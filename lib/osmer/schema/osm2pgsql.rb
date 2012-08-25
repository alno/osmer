require 'osmer/schema/base'

class Osmer::Schema::Osm2pgsql < Osmer::Schema::Base

  attr_accessor :binary

  def initialize(*args)
    @binary = 'osm2pgsql'
    super
  end

  # Create schema in given database
  def create!(db)
    db.in_transaction do |conn|
      raise StandardError.new("Schema #{name} already created!") unless schema_tables(conn).empty?
    end

    osm2pgsql_exec db, "'#{empty_file}'", "creating osm2pgsql schema"
  end

  # Drop schema in given database
  def drop!(db)
    db.in_transaction do |conn|
      schema_tables(conn).each do |table|
        conn.exec "DROP TABLE IF EXISTS #{table}"
      end
    end
  end

  def import!(db, file)
    db.in_transaction do |conn|
      schema_tables(conn).each do |table|
        conn.exec "DELETE FROM #{table}"
      end
    end

    osm2pgsql_exec db, "-a '#{file}'", "importing data with osm2pgsql"
  end

  def patch!(db, file)
    osm2pgsql_exec db, "-a '#{file}'", "importing data with osm2pgsql"
  end

  def attach_listener!(conn, collection, name, fields)
    table  = collection_table collection
    args = fields.map{|f| collection_field(collection, f) }.join(', ')

    # Drop triggers
    conn.exec "DROP TRIGGER IF EXISTS #{name}_insert_trigger ON #{table}"
    conn.exec "DROP TRIGGER IF EXISTS #{name}_update_trigger ON #{table}"
    conn.exec "DROP TRIGGER IF EXISTS #{name}_delete_trigger ON #{table}"

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{name}_insert_proxy() RETURNS trigger AS $$
      BEGIN
        PERFORM #{name}_insert(NEW.osm_id, #{args});
        RETURN NULL;
      END; $$ LANGUAGE plpgsql}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{name}_update_proxy() RETURNS trigger AS $$
      BEGIN
        PERFORM #{name}_update(NEW.osm_id, #{args});
        RETURN NULL;
      END; $$ LANGUAGE plpgsql}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{name}_delete_proxy() RETURNS trigger AS $$
      BEGIN
        PERFORM #{name}_delete(OLD.osm_id);
        RETURN NULL;
      END; $$ LANGUAGE plpgsql}

    # Create new triggers
    conn.exec "CREATE TRIGGER #{name}_insert_trigger AFTER INSERT ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{name}_insert_proxy()"
    conn.exec "CREATE TRIGGER #{name}_update_trigger AFTER UPDATE ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{name}_update_proxy()"
    conn.exec "CREATE TRIGGER #{name}_delete_trigger AFTER DELETE ON #{table} FOR EACH ROW EXECUTE PROCEDURE #{name}_delete_proxy()"

    # Prepopulate dependency
    conn.exec "SELECT #{name}_insert(NEW.osm_id, #{args}) FROM #{table} NEW"
  end

  private

  def osm2pgsql_exec(db, tail, desc)
    system "'#{binary}' -E #{projection} -j -m -G --slim -U #{db[:username]} -d #{db[:database]} -H #{db[:host]} -p '#{table_prefix}' #{tail}" or raise StandardError.new("Error #{desc}")
  end

  def schema_tables(conn)
    res = conn.exec "select table_name from information_schema.tables where table_schema = 'public' AND table_name LIKE '#{table_prefix}_%'"
    tables = res.values.flatten
    res.clear
    tables
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

end
