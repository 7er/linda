require 'rinda/tuplespace'
require 'drb'
require 'rinda_eval'
require 'benchmark'


DRb.start_service
$ts = Rinda::TupleSpace.new

NUM_WORKERS = 9
GRAIN = 88

def is_prime(candidate)
  limit = Math.sqrt(candidate)
  (2..limit).each do |i|
    un1, un2, ok = $ts.read([:primes, i, nil])
    return false if ok && (candidate % i == 0)
  end
  true
end

def worker(limit)
  loop do
    _, start = $ts.take([:next_task, nil])
    if start == :die
      $ts.write([:next_task, :die])
      return
    end
    stop = [start + GRAIN, limit + 1].min
    #puts "write next_task #{stop}"
    if stop == limit + 1
      $ts.write([:next_task, :die])
    else
      $ts.write([:next_task, stop])
    end
    block = (start...stop).map do |candidate|
      [candidate, is_prime(candidate)]
    end
    $ts.write([:result, start, block])
  end
end


class Primes
  def initialize(limit)
    @limit = limit
    @count = 0
  end

  def fill_initial_primes
    $ts.write([:primes, 2, true])
    $ts.write([:primes, 3, true])
    $ts.write([:primes, 4, false])
    $ts.write([:primes, 5, true])
    $ts.write([:primes, 6, false])
    $ts.write([:primes, 7, true])  
    $ts.write([:primes, 8, false])
    $ts.write([:primes, 9, false])
    $ts.write([:primes, 10, false])
    11
  end

  def generate
    next_number = fill_initial_primes
    raise "Bollocks" unless GRAIN < ((next_number - 1) ** 2 - next_number)
    $ts.write([:next_task, next_number])
    NUM_WORKERS.times do
      $ts.rinda_eval { [:worker, worker(@limit) ] }
    end
    @count = 4
    while next_number <= @limit
      _, _, block = $ts.take([:result, next_number, nil])
      block.each do |number, is_prime|
        $ts.write([:primes, number, is_prime])
        @count += 1 if is_prime
      end
      next_number += GRAIN
    end
    NUM_WORKERS.times do
      $ts.take([:worker, nil])
    end
  end
  
  def count
    @count
  end

  def print
    (2..@limit).each do |number|
      _, _, is_prime = $ts.read([:primes, number, nil])
      puts "#{number} is prime" if is_prime
    end
  end
end

primes = Primes.new(1000)
count = 0
puts Benchmark.measure {
  primes.generate
  count = primes.count
}
raise "Wrong was #{count}" if count != 168
primes.print

