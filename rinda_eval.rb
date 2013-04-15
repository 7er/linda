require 'rinda/tuplespace'
require 'drb'

module Rinda
  # this only works with java
  def self.rinda_eval(ts, &tuple_producing_block)
    ts = DRbObject.new(ts) unless DRbObject === ts
    Thread.new do
      ts = TupleSpaceProxy.new(ts)
      tuple = tuple_producing_block.call(ts)
      ts.write(tuple) rescue nil
    end
  end

  class TupleSpace
    def rinda_eval(&tuple_producing_block)
      Thread.new do
        write(tuple_producing_block.call(self)) rescue nil
      end
    end
  end
end
