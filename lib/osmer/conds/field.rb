require 'osmer/conds/base'

class Osmer::Conds::Field < Osmer::Conds::Base

  def initialize(table, field, restr)
    super table
    @field, @restr = field, restr
  end

  def conditions
    case @restr
    when Range then [ "src_tags->'#{@field}' BETWEEN #{q @restr.begin} AND #{q @restr.end}" ]
    when Array then [ "src_tags->'#{@field}' IN (#{@restr.map{|v| q v}.join(',')})" ]
    else [ "src_tags->'#{@field}' = #{q @restr}" ]
    end
  end

  private

  def q(v)
    "'#{v.to_s.gsub('\\','\\\\').gsub("'","''")}'"
  end

end
