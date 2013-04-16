require 'rinda/tuplespace'
require 'drb'
require 'rinda_eval'
require 'benchmark'


DRb.start_service
$ts = Rinda::TupleSpace.new

NUM_WORKERS = 10
GRAIN = 50

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



def print_primes(limit)
  NUM_WORKERS.times do
    $ts.rinda_eval { [:worker, worker(limit) ] }
  end
  # fill initial primes
  $ts.write([:primes, 2, true])
  $ts.write([:primes, 3, true])
  $ts.write([:primes, 4, false])
  $ts.write([:primes, 5, true])
  $ts.write([:primes, 6, false])
  $ts.write([:primes, 7, true])  
  $ts.write([:primes, 8, false])
  $ts.write([:primes, 9, false])
  $ts.write([:primes, 10, false])
  start = 10
  raise "Bollocks" unless GRAIN < (start ** 2 - start)
  next_number = start + 1
  $ts.write([:next_task, next_number])
  loop do
    _, block_start, block = $ts.take([:result, next_number, nil])
    #puts "writing block: #{block.inspect}"
    block.each do |number, is_prime|
      $ts.write([:primes, number, is_prime])
    end
    break if block.last.first == limit
    next_number += GRAIN
  end

  NUM_WORKERS.times do
    $ts.take([:worker, nil])
  end
  (2..limit).each do |number|
    _, _, is_prime = $ts.read([:primes, number, nil])
    puts "#{number} is prime" if is_prime
  end
end

# def print_primes(limit)
#   (2..limit).each do |number|
#     _, _, is_prime = $ts.read([:primes, number, nil])
#     puts number if is_prime
#   end
# end

puts Benchmark.measure { print_primes(500) }
#print_primes(500)

