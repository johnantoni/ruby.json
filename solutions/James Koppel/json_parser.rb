class StringIO
 def strip!
   ch = read(1)
   ch = read(1) while /\s/ =~ ch
   ungetc ch[0]
   self
 end

 def sees?(str1)
   str2 = read(str1.length)
   str2.reverse.scan(/./) {|ch| ungetc ch[0]}
   str2 == str1
 end

 alias oldread read
 def read(expr,*buffer)
   return oldread(expr,*buffer) unless expr.is_a? Regexp
   str = ""
   str << getc until eof? or (expr =~ str) == 0
   if eof? and (expr =~ str) != 0
     str.reverse.scan(/./){|ch| ungetc ch[0]}
     return nil
   end
   maxmtch = str
   until eof?
     str << getc until eof? or expr.match(str)[0] != str
     str << getc until eof? or expr.match(str)[0] == str
     maxmtch = expr.match(str)[0]
   end
   str[maxmtch.length..-1].reverse.scan(/./){|ch|ungetc ch[0]}
   str = maxmtch
   if expr.match(str)[0]==str
     str
   else
     ungetc str[-1]
     str[0...-1]
   end
 end
end

class JSONParser

 def parse(str)
   parse_next(StringIO.new(str))
 end

 private

 def parse_next(strio)
   strio.strip!
   if el=number(strio)
     return el
   elsif el=string(strio)
     return el
   end
   {"true"=>true,"false"=>false,"null"=>nil}.each_pair do |k,v|
     if strio.sees? k
       strio.read k.length
       return v
     end
   end

   if strio.sees?("{")
     obj = Hash.new
     strio.getc

     until strio.strip!.sees?("}")
       key = string(strio) or raise
       strio.strip!
       raise unless strio.read(1) == ':'
       val = parse_next(strio)
       obj[key] = val
       strio.strip!
       raise unless strio.sees?('}') or strio.read(1) == ','
     end
     strio.getc
     obj
   elsif strio.read(1) == '['
     arr = Array.new
     until strio.strip!.sees?("]")
       arr << parse_next(strio)
       raise unless strio.sees?("]") or strio.read(1) == ','
     end
     strio.getc
     arr
   else
     raise
   end        
 end

 def string(strio)
   str=strio.read(/\"([^\"\\]|\\\"|\\\\|\\\/|\\b|\\f|\\n|\\r|\\t|\\u[a-fA-F0-9]{4})*\"/).
         to_s.gsub(/\\u([a-fA-F0-9]{4})/){$1.to_i(16).chr}[1...-1] \
                     or return nil
   str.gsub!(/\\[\"\\\/bfnrt]/){|s|eval("\"#{s}\"")}
   str
 end

 def number(strio)
   eval (strio.read(/-?(0|[1-9]\d*)(\.\d*)?([eE][+-]?\d+)?/).to_s)
 end
end
