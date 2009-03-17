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

generator = RandomJSON.new((ARGV[1]||0).to_i)

parser = JSONParser.new
Benchmark.bm { |b|
   l = nil; t = nil
   13.times { |depth|
       tree = generator.value(depth, depth%2)
       s = tree.inspect
       #puts s
       s.gsub!(/=>/, ':')
       s.gsub!(/nil/, 'null')
       tree2 = nil
       #puts s
       l = s.length
       t = b.report("#{depth} #{l}") { tree2 = parser.parse(s).value }
       raise if tree2!=tree
       break if (t.real>=(ARGV[0]||1).to_f)
   }
   puts "#{(l/t.real).to_i} chars/second"
}