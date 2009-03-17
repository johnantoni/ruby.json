class JSONParser
   def initialize
       @parser = JsonParser.new
   end

   def parse(text)
       rv = @parser.parse(text)
       if rv
           return rv.value
       else
           raise RuntimeError
       end
   end
end
