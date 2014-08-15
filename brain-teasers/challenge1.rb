#!/usr/bin/env ruby

# reads from ARGV[0] to figure out solution to problem:
# line 1: number of tests
# lines n: [number of values] [integer values...] [target]
# ignoring order of operations, use +-/* on integer values in list in order to arrive at target
# print NO SOLUTION if no combination of operators will arrive at target, or the solution equation
# target between -32000 and +32000 inclusive, cannot divide a partial solution with a remainder

lines = ARGF.read.lines

num_tests = lines[0].strip.to_i
sets = lines[1..-1].map do |l|
  fields = l.strip.split(/\s+/).map(&:to_i)
  {
    :num_vals => fields[0],
    :vals => fields[1..-2],
    :target => fields.last
  }
end

def find_solution(k, target)
  _find_solution(k.first,k[1..-1],target,[])
end

def _find_solution(memo, k, target, path)
  # if no more values in k, memo best be == to target. otherwise no expression possible
  if k.empty?
    return path if memo == target
    return nil
  end
  # lets see if we can find a valid path
  v2 = k.first
  [:+,:-,:*,:/].each do |op|
    # if mod is non-zero, its an illegal move, so skip this branch
    unless op == :/ and memo % v2 != 0
      # apply operator
      partial = memo.send(op, v2)
      # test is valid thus far
      if _is_valid_partial_res?(partial)
        # recurse depth first to find a solution
        sol = _find_solution(partial,k[1..-1],target, path + [op])
        # if nothing found down this fork, keep going
        return sol unless sol.nil?
      end
    end
  end
  # nothing found
  return nil
end

def _is_valid_partial_res?(partial)
  partial <= 32000 and partial >= -32000
end

sets.each_with_index do |test,i|
  solution = find_solution(test[:vals], test[:target])
  if solution.nil?
    puts "NO EXPRESSION"
  else
    puts test[:vals].zip(solution).concat(['=',test[:target]]).join ""
  end
end
