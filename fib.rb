require 'rinda/tuplespace'
require 'drb'
require 'rinda_eval'
require 'benchmark'

DRb.start_service
$ts = Rinda::TupleSpace.new

def fib(n)
  n < 2 ? n : fib(n -2) + fib(n - 1)
end

def task(n)
  puts "fib(#{n}) = #{fib(n)}"
end

def rinda_eval_version(fib_numbers)
  fib_numbers.each { |x|
    Rinda::rinda_eval($ts) do |ts| 
      [:result, x, fib(x)]
    end
  }.each { |x|
    i, j, result = $ts.take([:result, x, nil])
    puts "fib(#{x}) = #{result}"
  }
end

def multithread_version(fib_numbers)
  fib_numbers.map {|x| Thread.new { task(x) } }.map {|y| y.join }
end

def singlethread_version(fib_numbers)
  fib_numbers.each {|x| task(x) }
end

fib(34)
puts Benchmark.measure {
  fib_numbers = [34, 34, 34]
  #singlethread_version(fib_numbers)
  #multithread_version(fib_numbers)
  rinda_eval_version(fib_numbers)
}
