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

  def create!(db)
    db.in_transaction do |conn|
      tables.each do |table|
        create_table! db, conn, table
      end
    end
  end

  def drop!(db)
    db.in_transaction do |conn|
      tables.each do |table|
        drop_table! db, conn, table
      end
    end
  end

  private

  def create_table!(db, conn, table)
    table_name = "#{table_prefix}_#{table.name}"
    table_fields = { :id => 'INT8', :tags => 'HSTORE' }
    table_assigns = { :tags => 'src_tags' }
    table_conditions = []

    if table.type.to_s.start_with? 'multi'
      table_assigns[:geometry] = 'ST_Multi(src_geometry)'
    else
      table_assigns[:geometry] = 'src_geometry'
    end

    table.mappers.each do |k,v|
      table_fields.merge! v.fields
      table_assigns.merge! v.assigns
      table_conditions |= v.conditions
    end

    table_assigns_keys = table_assigns.keys.to_a
    table_assigns_values = table_assigns_keys.map{|k| table_assigns[k] }
    table_condition = table_conditions.map{|c| "(#{c})"}.join(' AND ')

    conn.exec "CREATE TABLE #{table_name}(#{table_fields.map{|k,v| "#{k} #{v}"}.join(', ')})"
    conn.exec "SELECT AddGeometryColumn('#{table_name}', 'geometry', #{projection}, '#{db.geometry_type table.type}', 2)"

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{table_name}_insert(src_id BIGINT, src_tags HSTORE, src_geometry GEOMETRY) RETURNS BOOLEAN AS $$
      BEGIN
        IF #{table_condition} THEN
          INSERT INTO #{table_name} (id, #{table_assigns_keys.join(', ')}) VALUES (src_id, #{table_assigns_values.join(', ')});
          RETURN FOUND;
        ELSE
          RETURN FALSE;
        END IF;
      END; $$ LANGUAGE plpgsql;}

    conn.exec %Q{CREATE OR REPLACE FUNCTION #{table_name}_update(src_id BIGINT, src_tags HSTORE, src_geometry GEOMETRY) RETURNS BOOLEAN AS $$
      BEGIN
        IF #{table_condition} THEN
          UPDATE #{table_name} SET #{table_assigns.map{|k,v| "#{k} = #{v}"}.join(', ')} WHERE id = src_id;

          IF NOT FOUND THEN
            INSERT INTO #{table_name} (id, #{table_assigns_keys.join(', ')}) VALUES (src_id, #{table_assigns_values.join(', ')});
          END IF;

          RETURN FOUND;
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

    table.source_schema.attach_listener! conn, table.source_table, table_name, [:tags, :geometry]
  end

  def drop_table!(db, conn, table)
    conn.exec "DROP TABLE IF EXISTS #{table_prefix}_#{table.name}"
  end

  class Dsl < Osmer::Schema::Base::Dsl

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
      schema.tables << Table.new(schema, name, type, options).configure(&block)
    end

  end

  class Table

    include Osmer::Configurable

    attr_reader :schema, :name, :type, :source_schema, :source_table, :mappers

    def initialize(schema, name, type, options)
      require 'osmer/mapper/type'

      @schema, @name, @type = schema, name, type

      @source_table = type.to_s.gsub(/\Amulti/,'')
      @source_schema = schema.ns.find_schema(options[:source] || schema.source || :source) or raise StandardError.new("Source schema not found")

      @mappers = {
        :type => Osmer::Mapper::Type.new(:type)
      }
    end

    class Dsl < Struct.new(:table)

      include Osmer::Utils

      def map(*args)
        table.mappers[:type].add_args(*args)
      end

      def with(*args)
        args.each do |arg|
          if arg.is_a? Hash
            arg.each(&method(:add_mapper))
          else
            add_mapper arg, arg
          end
        end
      end

      private

      def add_mapper(key, type)
        require "osmer/mapper/#{type}"

        table.mappers[key.to_s] = Osmer::Mapper.const_get(camelize type).new key
      end

    end

  end

end
