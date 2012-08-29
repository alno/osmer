require 'osmer/schema/base'

class Osmer::Schema::Custom < Osmer::Schema::Base

  attr_reader :tables
  attr_accessor :source

  def initialize(*args)
    @tables = []
    super
  end

  def dsl
    Dsl.new(self)
  end

  def create!(db, colls = nil)
    db.in_transaction do |conn|
      tables.each do |table|
        create_table! db, conn, table if colls.nil? || colls.include?(table.name.to_s)
      end
    end
  end

  def drop!(db, colls = nil)
    db.in_transaction do |conn|
      tables.reverse.each do |table|
        drop_table! db, conn, table if colls.nil? || colls.include?(table.name.to_s)
      end
    end
  end

  private

  def create_table!(db, conn, table)
    ns.meta.init_error_records_table conn

    table_name = "#{table_prefix}_#{table.name}"
    table_fields = {}
    table_assigns = {}
    table_conditions = []
    table_indexes = {}

    table.mappers.each do |k,v|
      table_fields.merge! v.fields
      table_assigns.merge! v.assigns
      table_indexes.merge! v.indexes
      table_conditions |= v.conditions
    end

    table.conds.each do |c|
      table_conditions |= c.conditions
    end

    table_assigns_keys = table_assigns.keys.to_a
    table_assigns_values = table_assigns_keys.map{|k| table_assigns[k] }
    table_condition = table_conditions.map{|c| "(#{c})"}.join(' AND ')

    conn.exec "CREATE TABLE #{table_name}(id INT8 PRIMARY KEY, #{table_fields.map{|k,v| "#{k} #{v}"}.join(', ')})"

    table.mappers.each{|k,m| m.after_create db, conn, table_name }

    table_indexes.each do |key,desc|
      conn.exec "CREATE INDEX #{table_name}_#{key}_index ON #{table_name} USING #{desc}"
    end

    declare_sql = table_fields.map{|k,v| "dst_#{k} #{v.gsub('NOT NULL','')};" }.join(' ') + ' dst_geometry GEOMETRY;'
    assign_sql = table_assigns.map{|k,v| "dst_#{k} := #{v};"}.join(' ')

    insert_sql = if table.multi_geometry?
      %Q{
        UPDATE #{table_name} SET geometry = ST_Union(geometry, dst_geometry), #{(table_assigns_keys - [:geometry]).map{|k| "#{k} = dst_#{k}"}.join(', ')} WHERE id = src_id;

        IF NOT FOUND THEN
          INSERT INTO #{table_name} (id, #{table_assigns_keys.join(', ')}) VALUES (src_id, #{table_assigns_keys.map{|k| "dst_#{k}"}.join(', ')});
        END IF;

        RETURN TRUE;
      }
    else
      %Q{
        UPDATE #{table_name} SET #{table_assigns_keys.map{|k| "#{k} = dst_#{k}"}.join(', ')} WHERE id = src_id;

        IF NOT FOUND THEN
          INSERT INTO #{table_name} (id, #{table_assigns_keys.join(', ')}) VALUES (src_id, #{table_assigns_keys.map{|k| "dst_#{k}"}.join(', ')});
          RETURN TRUE;
        ELSE
          INSERT INTO #{ns.meta.error_records_table}(ts,tbl,id,msg) VALUES (current_timestamp, '#{table_name}', src_id, 'Record already exists, updated');
          RAISE WARNING 'Record #{table_name}(%) already exists, updated', src_id;
          RETURN FALSE;
        END IF;
      }
    end

    update_sql = %Q{
      UPDATE #{table_name} SET #{table_assigns_keys.map{|k| "#{k} = dst_#{k}"}.join(', ')} WHERE id = src_id;

      IF NOT FOUND THEN
        INSERT INTO #{table_name} (id, #{table_assigns_keys.join(', ')}) VALUES (src_id, #{table_assigns_keys.map{|k| "dst_#{k}"}.join(', ')});
      END IF;

      RETURN FOUND;
    }

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{table_name}_insert(src_id BIGINT, src_tags HSTORE, src_geometry GEOMETRY) RETURNS BOOLEAN AS $$
      DECLARE
        #{declare_sql}
      BEGIN
        IF #{table_condition} THEN
          #{assign_sql}
          #{insert_sql}
        ELSE
          RETURN FALSE;
        END IF;
      END; $$ LANGUAGE plpgsql;}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{table_name}_update(src_id BIGINT, src_tags HSTORE, src_geometry GEOMETRY) RETURNS BOOLEAN AS $$
      DECLARE
        #{declare_sql}
      BEGIN
        IF #{table_condition} THEN
          #{assign_sql}
          #{update_sql}
        ELSE
          DELETE FROM #{table_name} WHERE id = src_id;
          RETURN FOUND;
        END IF;
      END; $$ LANGUAGE plpgsql;}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{table_name}_delete(src_id BIGINT) RETURNS BOOLEAN AS $$
      BEGIN
        DELETE FROM #{table_name} WHERE id = src_id;
        RETURN FOUND;
      END; $$ LANGUAGE plpgsql;}

    table.source_schema.attach_listener! conn, table.source_table, table_name, listener_fields

    conn.exec "ANALYZE #{table_name}"
  end

  def drop_table!(db, conn, table)
    table_name = "#{table_prefix}_#{table.name}"

    table.source_schema.detach_listener! conn, table.source_table, table_name, listener_fields

    conn.exec "DROP TABLE IF EXISTS #{table_name}"
  end

  def listener_fields
    [:tags, :geometry]
  end

  class Dsl < Osmer::Schema::Base::Dsl

    def initialize(*args)
      super
      @defaults = []
    end

    def multipolygons(name, options = {}, &block)
      table name, :multipolygons, options, &block
    end

    def multilines(name, options = {}, &block)
      table name, :multilines, options, &block
    end

    def polygons(name, options = {}, &block)
      table name, :polygons, options, &block
    end

    def lines(name, options = {}, &block)
      table name, :lines, options, &block
    end

    def points(name, options = {}, &block)
      table name, :points, options, &block
    end

    def table(name, type, options, &block)
      defs = @defaults
      schema.tables << Table.new(schema, name, type, options).configure{ defs.each{|d| send(*d)} }.configure(&block)
    end

    [:with, :without, :simplify, :z_order].each do |method|
      define_method method do |*args|
        @defaults << [method, *args]
      end
    end

  end

  class Table

    include Osmer::Configurable

    attr_reader :schema, :name, :type, :source_schema, :source_table, :mappers, :conds

    def initialize(schema, name, type, options)
      require 'osmer/mapper/tags'
      require 'osmer/mapper/type'
      require 'osmer/mapper/name'
      require 'osmer/mapper/geometry'
      require 'osmer/conds/field'

      @schema, @name, @type = schema, name, type

      @source_table = type.to_s.gsub(/\Amulti/,'')
      @source_schema = schema.ns.find_schema(options[:source] || schema.source || :source) or raise StandardError.new("Source schema not found")

      @conds = []
      @mappers = {
        :type => Osmer::Mapper::Type.new(self, :type),
        :name => Osmer::Mapper::Name.new(self, :name),
        :tags => Osmer::Mapper::Tags.new(self, :tags),
        :geometry => Osmer::Mapper::Geometry.new(self, :geometry)
      }
    end

    def multi_geometry?
      type.to_s.start_with? 'multi'
    end

    def projection
      schema.projection
    end

    class Dsl < Struct.new(:table)

      include Osmer::Utils

      def map(*args)
        table.mappers[:type].add_args(*args)
      end

      def with(*args, &block)
        args.each do |arg|
          if arg.is_a? Hash
            arg.each{|k,v| add_mapper k, v }
          else
            add_mapper arg
          end
        end

        MapperDsl.new(table).instance_eval(&block) if block
      end

      def without(*args)
        args.each do |arg|
          table.mappers.delete arg.to_sym
        end
      end

      def where(conds = {})
        conds.each do |k,v|
          table.conds << Osmer::Conds::Field.new(table, k, v)
        end
      end

      def simplify(tolerance)
        table.mappers[:geometry].simplify = tolerance
      end

      def buffer(distance)
        table.mappers[:geometry].buffer = distance
      end

      def z_order(*args)
        mapper = add_mapper :z_order

        args.each do |arg|
          if arg.is_a? Hash
            arg.each{ |k,v|
              mapper[k] = v
            }
          else
            mapper << arg
          end
        end
      end

      private

      def add_mapper(key, type = nil)
        type ||= key

        require "osmer/mapper/#{type}"

        table.mappers[key.to_sym] ||= Osmer::Mapper.const_get(camelize type).new table, key
      end

    end

    class MapperDsl < Struct.new(:table)

      include Osmer::Utils

      def method_missing(type, key, *args, &block)
        require "osmer/mapper/#{type}"
        table.mappers[key.to_sym] ||= Osmer::Mapper.const_get(camelize type).new(table, key, *args, &block)
      end

    end

  end

end
