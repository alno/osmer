require 'osmer'

class Osmer::Conds::Base

  attr_reader :table

  def initialize(table)
    @table = table
  end

  def conditions
    []
  end

end
