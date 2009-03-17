require 'strscan'

class JSONParser

   def initialize
       @rxe = /
           \[|\]|
           \{|\}|
           (:)|
           (,[ \t\r\n]*[}\]])|
           ,|
           ("(?>[^"\\]+|\\(?:u[0-9a-fA-F]{4}|[bfnrt"\/\\]))*"(?![ \t\r\n]"))|
           -?(?=\d)(?>0|[1-9]\d*)(?>\.\d+)?(?>[Ee][+-]?\d+)?(?!\d)|
           true|
           false|
           (null)|
           (?>[ \t\r\n]+)|
           ((?>.+))
           /xmu
   end

   def parse(json)
       scanner = StringScanner.new(json)
       out = []
       until (scanner.skip(/[[:space:][:cntrl:]]*/); scanner.eos?)
           scan = scanner.scan(@rxe)
           if scanner[5] or scanner[2]
               invalid(scanner[2] || scanner[5])
           elsif scanner[1]
               out << '=>'
           elsif scanner[3]
               out << scanner[3].gsub(/#/, '\\\\#')
           elsif scanner[4]
               out << 'nil'
           else
               out << scan
           end
       end
       begin
           return eval(out.join(' '))
       rescue Exception => e
           invalid(json)
       end
   end

   def invalid(string)
       raise RuntimeError, 'Invalid JSON: %s' % string
   end

end
