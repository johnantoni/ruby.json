class JSONParser
 def parse(text)
   parser = JsonParser.new
   p = parser.parse(text)
   raise parser.failure_reason unless p
   p.obj
 end
end
