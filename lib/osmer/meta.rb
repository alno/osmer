require 'osmer'

class Osmer::Meta

  attr_reader :ns

  def initialize(ns)
    @ns = ns
  end

  def prefix
    ns.prefix || 'osmer'
  end

  def schema_versions_table
    "#{prefix}_schema_versions"
  end

  def error_records_table
    "#{prefix}_error_records"
  end

  def init_error_records_table(conn)
    conn.exec "CREATE TABLE IF NOT EXISTS #{error_records_table}(ts TIMESTAMP, tbl TEXT, id BIGINT, msg TEXT)"
  end

end
