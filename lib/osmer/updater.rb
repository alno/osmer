require 'osmer'

class Osmer::Updater
  include Osmer::Configurable

  attr_accessor :interval, :dump, :diff

  def initialize(interval = nil)
    @interval = interval
  end

  def load_diffs(db, schema)
    db.in_transaction do |conn|
      init_meta_table conn, schema
      cur = get_current_version conn, schema

      puts "Requesting diff versions"
      versions = get_diff_versions

      while version = versions.detect{|d| d[0] == cur }
        puts "Downloading diff #{version.join('-')}"
        file = download_file diff, version

        puts "Applying diff #{file}"
        yield file

        set_current_version conn, schema, version[1]
        cur = version[1]
      end
    end
  end

  def load_dump(db, schema)
    db.in_transaction do |conn|
      init_meta_table conn, schema

      puts "Requesting last dump version"
      version = get_dump_version

      puts "Downloading dump #{version.join('-')}"
      file = download_file dump, version

      puts "Loading dump #{file}"
      yield file

      set_current_version conn, schema, version[0]
    end
  end

  def reset(db, schema)
    db.in_transaction do |conn|
      init_meta_table conn, schema
      reset_current_version conn, schema
    end
  end

  private

  def init_meta_table(conn, schema)
    conn.exec "CREATE TABLE IF NOT EXISTS #{schema.ns.meta.schema_versions_table}(schema VARCHAR(255) NOT NULL PRIMARY KEY, version INT8 NOT NULL)"
  end

  def get_current_version(conn, schema)
    conn.exec("SELECT version FROM #{schema.ns.meta.schema_versions_table} WHERE schema = $1", [schema.name]).values.first.first
  end

  def reset_current_version(conn, schema)
    conn.exec "DELETE FROM #{schema.ns.meta.schema_versions_table} WHERE schema = $1", [schema.name]
  end

  def set_current_version(conn, schema, version)
    if conn.exec("UPDATE #{schema.ns.meta.schema_versions_table} SET version = $2 WHERE schema = $1", [schema.name, version]).cmdtuples == 0
      conn.exec "INSERT INTO #{schema.ns.meta.schema_versions_table}(schema, version) VALUES ($1, $2)", [schema.name, version]
    end
  end

  def get_diff_versions
    get_available_versions(diff).uniq
  end

  def get_dump_version
    get_available_versions(dump).max
  end

  def get_available_versions(url)
    require 'open-uri'

    dir_content = open(url.gsub(/\/[^\/]+\z/, '/')).read
    file_regexp = Regexp.compile Regexp.quote(url.gsub(/.*\//, '')).gsub(/\\\{\w+\\\}/,'(\d+)')

    dir_content.scan(file_regexp).uniq
  end

  def download_file(template, subst)
    require 'fileutils'

    FileUtils.mkdir_p "/tmp/osmer"

    url = template.split(/\{\w+\}/).zip(subst).flatten.compact.join
    file = "/tmp/osmer/#{url.gsub(/.*\//, '')}"

    unless File.exists? file
      system "wget -O '#{file}' '#{url}'" or StandardError.new("Error downloading file '#{file}' from '#{url}'")
    end

    file
  end

  class Dsl < Struct.new(:updater)

    [:interval, :dump, :diff].each do |method|
      define_method method do |value|
        updater.send "#{method}=", value
      end
    end

  end

end
