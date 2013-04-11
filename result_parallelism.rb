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

def print_primes(limit)
  (2..limit).each do |each|
    Rinda.rinda_eval($ts) { |ts| [:primes, each, is_prime(each)] }
  end
  puts "finished evaling"
  (2..limit).each do |each|
    i, j, is_prime = $ts.read([:primes, each, nil])
    puts "#{each} is prime" if is_prime
  end
end

print_primes(500)
