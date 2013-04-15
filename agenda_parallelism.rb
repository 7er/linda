require 'rinda/tuplespace'
require 'drb'
require 'rinda_eval'
require 'benchmark'

DRb.start_service
$ts = Rinda::TupleSpace.new

NUM_WORKERS = 5
GRAIN = 4

def init_primes
  raise "Fuck" if GRAIN != 4
  $ts.write([:primes, 0, 2, 4])
  $ts.write([:primes, 1, 3, 9])
  3
end

def is_prime(candidate)
  index = 0
  while true
    _, _, prime, p2 = $ts.read([:primes, index, nil, nil])
    if candidate % prime == 0
      return false
    end
    if candidate > p2
      break
    end
    index += 1
  end
  true
end


def worker(max_prime)
  eot = false
  while true
    _, start = $ts.take([:next_task, nil])
    puts "next task #{start}"
    if start == -1
      $ts.write([:next_task, -1])
      return
    end
    limit = [start + GRAIN, max_prime].min
    $ts.write([:next_task, limit == max_prime ? -1 : limit])
    my_primes = []
    (start...limit).each do |candidate|
      my_primes << candidate if is_prime(candidate)
    end
    $ts.write([:result, start, my_primes])
  end
end

def print_primes(limit)
  (0...NUM_WORKERS).each do
    $ts.rinda_eval { [:worker, worker(limit)] }
  end
  first_num = init_primes
  $ts.write([:next_task, first_num])
  eot = false
  num_primes = 0
  num = first_num
  while num < limit
    _, _, new_primes = $ts.take([:result, num, nil])
    new_primes.each do |each, i|
      np2 = each ** 2
      $ts.write([:primes, num_primes, each, np2])
      num_primes += 1
    end
    num += GRAIN
  end
  (0...num_primes).each do |i|
    _, _, prime, _ = $ts.read([:primes, i, nil, nil])
    puts prime
  end
end

print_primes(10)
