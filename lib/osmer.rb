class Osmer

  module Data; end
  module Mapper; end
  module Schema; end
  module Target; end

  module Utils

    # Based on https://github.com/intridea/omniauth/blob/v1.0.2/lib/omniauth.rb#L129-139
    def camelize(str)
      str.to_s.gsub(/\/(.?)/){ "::" + $1.upcase }.gsub(/(^|_)(.)/){ $2.upcase }
    end

    def underscore(str)
      str.to_s.gsub(/::(.?)/){ "/" + $1.downcase }.gsub(/(.)([A-Z])/){ "#{$1}_#{$2.downcase}" }.downcase
    end

  end

  module Configurable

    def configure(file = nil, &block)
      if file
        dsl.instance_eval{ eval File.read(file) }
      elsif block
        dsl.instance_eval(&block)
      end

      self
    end

    private

    def dsl
      self.class.const_get('Dsl').new(self)
    end

  end

  include Utils
  include Configurable

  attr_reader :schemas
  attr_accessor :prefix

  def initialize
    @schemas = []
  end

  def add_schema(name, options)
    type = options.delete(:type) || 'custom'

    require "osmer/schema/#{type}"

    schema = Osmer::Schema.const_get(camelize type).new self, name, options
    schemas << schema
    schema
  end

  def find_schema(name)
    schemas.find{|s| s.name.to_s == name.to_s }
  end

  def create_all!(db)
    @schemas.each{|s| s.create! db }
  end

  def drop_all!(db)
    @schemas.reverse.each{|s| s.drop! db }
  end

  def recreate_all!(db)
    drop_all! db
    create_all! db
  end

  def meta
    @meta ||= begin
      require 'osmer/meta'
      Osmer::Meta.new self
    end
  end

  class Dsl < Struct.new(:osmer)

    def schema(name, options, &block)
      schema = osmer.add_schema name, options
      schema.configure &block if block
      schema
    end

    def prefix(value)
      osmer.prefix = value
    end

  end

end
