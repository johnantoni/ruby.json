require 'benchmark'

class RandomJSON
   def initialize(value=0)
       @number = -1
       @string = -1
       @boolean = -1
       @constant = -1
       @value = value-1
   end
   def number
       case (@number=(@number+1)%3)
       when 0 : 0
       when 1 : 1234
       when 2 : 3.75e+1
       end
   end
   def string
       case (@string=(@string+1)%3)
       when 0 : ""
       when 1 : "JSON"
       when 2 : "\"\\\/\b\f\r\t"
       end
   end
   def boolean
       case (@boolean=(@boolean+1)%3)
       when 0 : false
       when 1 : true
       when 2 : nil
       end
   end
   def constant
       case (@constant=(@constant+1)%3)
       when 0 : number
       when 1 : string
       when 2 : boolean
       end
   end
   def array(depth)
       a = []
       depth.times {
           a << value(depth-1)
       }
       a
   end
   def object(depth)
       o = {}
       depth.times {
           o[string] = value(depth-1)
       }
       o
   end
   def value(depth, v=nil)
       case (v||(@value=(@value+1)%3))
       when 0 : array(depth)
       when 1 : object(depth)
       else constant
       end
   end
end

parser = JSONParser.new
generator = RandomJSON.new((ARGV[1]||0).to_i)
bandwidth = 0
bandwidth0 = 0
t0 = 0
l = nil
t = nil
max_depth = 10
(max_depth+1).times { |depth|
   tree = generator.value(depth, depth%2)
   s = tree.inspect
   s.gsub!(/=>/, ':')
   s.gsub!(/nil/, 'null')
   tree2 = nil
   l = s.length
   t = nil
   4.times {
       Benchmark.bm { |b|
           GC.start
           t1 = b.report("#{depth} #{l} ") { tree2 = parser.parse(s) }
           GC.start
           raise("#{tree2.inspect}!=#{tree.inspect}") if tree2!=tree
           GC.start
           if (!t or t1.real<t.real)
               t = t1
           end
       }
   }
   bandwidth = l/t.real
   puts "#{bandwidth.to_i} chars/second"
   break if (t.real>=(ARGV[0]||1).to_f or depth>=max_depth)
   if (t.real>t0)
       bandwidth0 = bandwidth
       t0 = t.real
   end
}
bandwidth = bandwidth0 if (bandwidth0>bandwidth)

puts "\n#{bandwidth.to_i} chars/second"
