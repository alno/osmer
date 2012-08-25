require 'osmer/mapper/base'

class Osmer::Mapper::Type < Osmer::Mapper::Base

  attr_reader :mappings

  def initialize(*args)
    super

    @mappings = []
    @multi = false
  end

  def assigns
    if @multi
      { :type => expression, :types => expression_multi }
    else
      { :type => expression }
    end
  end

  def fields
    if @multi
      { :type => 'VARCHAR(100) NOT NULL', :types => 'VARCHAR(100)[]' }
    else
      { :type => 'VARCHAR(100) NOT NULL' }
    end
  end

   def indexes
    if @multi
      { :type => "BTREE(type)", :types => "GIN(types)" }
    else
      { :type => "BTREE(type)" }
    end
  end

  def conditions
    [ @mappings.map{|m| map_cond(m)}.join(' OR ') ]
  end

  def expression
    "CASE #{@mappings.map{|m| "WHEN #{map_cond(m)} THEN trim(regexp_replace(src_tags->'#{m[0]}', ',.*', ''))"}.join(' ')} END"
  end

  def expression_multi
    "(#{@mappings.map{|m| "string_to_array(coalesce(CASE WHEN #{map_cond(m)} THEN replace(src_tags->'#{m[0]}',' ','') END,''),',')"}.join(' || ')})"
  end

  def map_cond(m)
    m[1] ? "(src_tags->'#{m[0]}') IN ('#{m[1].join("','")}')" : "(src_tags->'#{m[0]}') IS NOT NULL"
  end

  def add_args(*args)
    args.each do |arg|
      if arg.is_a? Hash
        arg.each(&method(:add_arg))
      else
        add_arg arg, nil
      end
    end
  end

  def add_arg(key, value)
    key = to_key(key)

    if key == 'multi'
      @multi = value
    else
      @mappings << [key, to_keylist(value)]
    end
  end

  private

  def to_key(key)
    raise StandardError.new("Invalid key #{key.inspect}") unless key.is_a? String or key.is_a? Symbol
    key.to_s
  end

  def to_keylist(list)
    if list.nil?
      list
    elsif list.is_a? Array
      list.map(&method(:to_key))
    else
      [to_key(list)]
    end
  end

end
