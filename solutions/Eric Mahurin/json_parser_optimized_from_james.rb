require "strscan"

class JSONParser

 def parse(input)
   @input = StringScanner.new(input)
   @input.scan(/\s*/)
   parse_value(out=[])
   @input.eos? or error("Unexpected data")
   out[0]
 end

 private

 def parse_value(out)
   if @input.scan(/\{\s*/)
     object = {}
     kv = []
     until @input.scan(/\}\s*/)
       object.empty? or @input.scan(/,\s*/) or error("Expected ,")
       kv.clear
       @input.scan(/"/) or error("Expected string")
       parse_string(kv)
       @input.scan(/:\s*/) or error("Expecting object separator")
       parse_value(kv)
       object[kv[0]] = kv[1]
     end
     out << object
   elsif @input.scan(/\[\s*/)
     array = []
     until @input.scan(/\]\s*/)
       array.empty? or @input.scan(/,\s*/) or error("Expected ,")
       parse_value(array)
     end
     out << array
   elsif @input.scan(/"/)
     parse_string(out)
   elsif @input.scan(/-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\s*/)
     out << eval(@input.matched)
   elsif @input.scan(/true\s*/)
     out << true
   elsif @input.scan(/false\s*/)
     out << false
   elsif @input.scan(/null\s*/)
     out << nil
   else
     error("Illegal JSON value")
   end
 end

 def parse_string(out)
   string = ""
   while true
     if @input.scan(/[^\\"]+/)
       string.concat(@input.matched)
     elsif @input.scan(%r{\\["\\/]})
       string << @input.matched[-1]
     elsif @input.scan(/\\[bfnrt]/)
       string << eval(%Q{"#{@input.matched}"})
     elsif @input.scan(/\\u[0-9a-fA-F]{4}/)
       string << @input.matched[2..-1].to_i(16)
     else
       break
     end
   end
   @input.scan(/"\s*/) or error("Unclosed string")
   out << string
 end

 def error(message)
   if @input.eos?
     raise "Unexpected end of input."
   else
     raise "#{message}:  #{@input.peek(@input.string.length)}"
   end
 end
end