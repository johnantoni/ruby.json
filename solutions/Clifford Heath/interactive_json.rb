require 'treetop'
require 'json'		# Note that we can require the Treetop file directly.
require 'readline'

parser = JsonParser.new
while line = Readline::readline("? ", [])
 begin
   tree = parser.parse(line)
   if tree
     p tree.obj
   else
     puts parser.failure_reason
   end
 rescue => e
   puts e
   p e.backtrace
   p tree if tree
 end
end
puts
