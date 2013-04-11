require 'rinda/tuplespace'
require 'drb'
require 'rinda_eval'
require 'benchmark'

DRb.start_service
$ts = Rinda::TupleSpace.new

def is_prime(me)
  limit = Math.sqrt(me)
  (2..limit).each do |i|
    un1, un2, ok = $ts.read([:primes, i, nil])
    return false if ok && (me % i == 0)
  end
  return true
end

NUM_WORKERS = 5
GRAIN = 500

def print_primes(limit)
  (0...NUM_WORKERS).each do
    Rinda::eval($ts) { [:worker, worker()] }
  end
  num_primes = 0
  new_primes = []
  first_num = 2
  $ts.write([:next_task, first_num])
  eot = 0
  num = first_num
  while num < limit
    a_prime = $ts.take([:result, num, nil])[2]
    new_primes << a_prime
    (0...
    num += GRAIN
  end
end

print_primes(100)
