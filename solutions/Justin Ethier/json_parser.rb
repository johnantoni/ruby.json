class JSONParser
 # Parse a given JSON expression
 def parse(expr)
   # Tokenize the input
   tokens = lex(expr)

   # Load the expression into ruby
   # Takes advantage of the fact ruby syntax is so close to that of JSON.
   # However, it would be nice to have a safe_eval to prevent against potential injection attacks
   begin
     eval(ruby_convert(tokens))
   rescue SyntaxError, NameError
     raise RuntimeError
   end
 end

 # Converts tokens into a single ruby expression
 def ruby_convert(tokens)
   expr = ""
   for token in tokens
     token = "=>" if token == ":" # Ruby hash syntax
     token = "nil" if token == "null"
     expr += token
   end
   expr
 end

 # Parses the input expression into a series of tokens
 # Performs some limited forms of conversion where necessary
 def lex(expr)
   tokens = []
   i = -1
   while i < expr.size - 1
     tok ||= ""
     i += 1

     case expr[i].chr
       when '[', ']', '{', '}', ':', ','
         tokens << tok if tok.size > 0
         tokens << expr[i].chr
         tok = ""
       # String processing
       when '"'
         raise "Unexpected quote" if tok.size > 0
         len = 1
         escaped = false
         while (len + i) < expr.size
           break if expr[len + i].chr == '"' and not escaped
           if escaped
             case expr[len + i].chr
               when '"', '/', '\\', 'b', 'f', 'n', 'r', 't', 'u'
               else
                 raise "Unable to escape #{expr[len + i].chr}"
               end
           end
           escaped = expr[len + i].chr == "\\"
           len += 1
         end
         raise "No matching endquote for string" if (len + i) > expr.size
         tokens << convert_unicode(expr.slice(i, len+1))
         i += len
       # Number processing
       when '-', /[0-9]/
         len = 0
         while (len + i) < expr.size and /[0-9eE+-.]/.match(expr[len + i].chr)!= nil
           len += 1
         end
         num = expr.slice(i, len)

         # Verify syntax of the number using the JSON state machine
         raise "Invalid number #{num}" if /[-]?([1-9]|(0\.))[0-9]*[eE]?[+-]?[0-9]*/.match(num) == nil

         tokens << num
         i += len - 1
       # Skip whitespace
       when ' ', '\t'
       else
         tok << expr[i].chr
     end
   end
   tokens << tok if tok.size > 0
   tokens
 end

 # Convert unicode characters from hex (currently only handles ASCII set)
 def convert_unicode(str)
   while true
     u_idx = str.index(/\\u[0-9a-fA-F]{4}/)
     break if u_idx == nil

     u_str = str.slice(u_idx, 6)
     str.sub!(u_str, u_str[2..5].hex.chr)
   end
   str
 end
end
