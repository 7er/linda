require 'rinda/tuplespace'
require 'drb'
require 'rinda_eval'
require 'benchmark'


DRb.start_service
$ts = Rinda::TupleSpace.new

def is_prime(candidate)
  limit = Math.sqrt(candidate)
  (2..limit).each do |i|
    un1, un2, ok = $ts.read([:primes, i, nil])
    return false if ok && (candidate % i == 0)
  end
  true
end

class Primes
  def initialize(limit)
    @limit = limit
  end
  
  def generate
    (2..@limit).each do |each|
      $ts.rinda_eval { [:primes, each, is_prime(each)] }
    end
  end

  def count
    result = 0
    (2..@limit).each do |each|
      _, _, is_prime = $ts.read([:primes, each, nil])
      result += 1 if is_prime
    end
    result
  end

  def print
    primes = (2..@limit).select do |each|
      _, _, is_prime = $ts.read([:primes, each, nil])
      is_prime
    end
    primes.each {|prime| puts "#{prime} is prime" }
  end
end

primes = Primes.new(500)
count = 0
puts Benchmark.measure {
  primes.generate
  count = primes.count
}
raise "Wrong was #{count}" if count != 95
primes.print
