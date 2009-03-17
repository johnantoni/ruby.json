require 'benchmark'
# require 'json/pure'
require 'json'

N = 2000
S = [10, 20, 30, 40]

# This is a slightly enhanced version of Ara's object generator.
# Objects are generated via RandomObject.generate(nil, DEPTH)
# -- the first argument defines which object types are eligible
# and can be ignored in this context.
require 'tml/random-object'

puts 'Preparing objects ...'
sizes   = Hash.new
objects = S.inject({}) do |h, s|
   size = 0
   a = h[s] = []
   n = N * 1000
   while size < n
       o = RandomObject.generate(nil, s)
       j = o.to_json
       a << [o, j]
       size += j.size
   end
   sizes[s] = size.to_f
   h
end

throughput = Hash.new {|h, k| h[k] = Hash.new(0)}

ARGV.each do |arg|
   p arg
   require arg

   parser = JSONParser.new

   throughput = []
   Benchmark.bm do |b|
       S.each do |s|
           t = b.report(s.to_s) do |sn|
               objects[s].each do |o, j|
                   if o != parser.parse(j)
                       raise RuntimeError
                   end
               end
           end
           throughput << "%s %d chars/sec (%d/%0.2f)" % [s, sizes[s] / t.real, sizes[s], t.real]
       end
   end
   puts
   puts throughput.join("\n")
   puts
   puts

end

objects.each do |s, z|
   puts "%s: n=%d avg.size=%0.2f tot.size=%d" %
   [s, z.size, sizes[s].to_f / z.size, sizes[s]]

end
puts
