class String
 # Splits into sub-strings separated by ',' characters. Does not split
 # contents within {}, [], or "". \" does not end a string, \\" does.
 # Checks if closing characters match previous opening ones.
 def split_stateful
   memb = [] # list of members identified
   delims = [] # stack of delimiters
   split('').each { |c|
     memb << "" if memb.empty?
     case delims.last
     when '"' # quote mode
       c == '\\' and delims.push c
       c == '"' and delims.pop
     when '\\' # escape mode
       delims.pop
     else
       case c
       when '{', '[', '"' then delims.push c
       when ',' then ( memb << ""; c="" ) if delims.empty? # next element
       when '}' then delims.pop == '{' or raise RuntimeError, "Non-matching }."
       when ']' then delims.pop == '[' or raise RuntimeError, "Non-matching ]."
       end
     end
     memb[-1] += c
   }
   delims.empty? or raise RuntimeError, "No closing delimiter for #{delims.join(', ')}."
   memb
 end
end

class JSONParser

 NUM_FORMAT = /^(-)?(0|[1-9][0-9]*)(\.[0-9]+)?(E[+-]?([0-9]+))?$/i

 # parse_value
 def parse(code)
   code.strip!
   case code[0,1]
   when '"' then parse_string(code)
   when /[-0-9]/ then parse_number(code)
   when '{' then parse_object(code)
   when '[' then parse_array(code)
   else parse_keyword(code)
   end
 end

 def parse_string(code)
   code =~ /^"(.*)"$/ or raise RuntimeError, "String has no closing quotation mark."
   $_ = $1
   $_ =~ /([^\\]|(\\\\)+)"/ and raise RuntimeError, "Non-escaped \" not allowed in string #{$_}."
   gsub(/\\(.)/) { |m|
     case $1
     when 'b', 'f', 'n', 'r', 't'
       eval('"\\%s"' % $1)
     when 'u'
       m # no change, handled later
     when '"', '/', '\\'
       $1 # strip \ character
     else
       raise RuntimeError, "No such escape sequence \\#{$1}."
     end
   }
   gsub(/\\u([A-F0-9]{4})/i) { "%c" % $1.hex }
 end

 def parse_number(code)
   code =~ NUM_FORMAT or raise RuntimeError, "Invalid number #{code}."
   eval code
 end

 def parse_array(code)
   code =~ /^\[(.*)\]$/ or raise RuntimeError, "No closing bracket for array #{code}."
   $1.split_stateful.collect { |m| parse(m) }
 end

 def parse_object(code)
   code =~ /^\{(.*)\}$/ or raise RuntimeError, "No closing bracket for object #{code}."
   object = {}
   $1.split_stateful.each do |m|
     key, value = m.split(":", 2)
     object[parse_string(key.strip)] = parse(value)
   end
   object
 end

 def parse_keyword(code)
   case code
   when 'true', 'false' then eval(code)
   when 'null' then nil
   else
     raise RuntimeError, "Syntax error: #{code}."
   end
 end
end