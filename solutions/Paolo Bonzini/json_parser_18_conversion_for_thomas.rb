class JSONParser

   RXE = /
       \[|\]|
       \{|\}|
       (:)|
       (,\s*[}\]])|
       ,|
       ("(?>[^"\\]+|\\(?:u[0-9a-fA-F]{4}|[bfnrt"\/\\]))*")|
       -?(?=\d)(?>0|[1-9]\d*)(?>\.\d+)?(?>[Ee][+-]?\d+)?(?=\D|$)|
       true|
       false|
       (null)|
       (?>[[:space:][:cntrl:]]+)|
       ((?>.+))
       /xmu

   def parse(json)
       ruby = json.gsub(RXE) do |t|
           if !$5.nil?||!$2.nil?       then invalid($5.nil? ? $2 : $5)
           elsif !$4.nil?              then 'nil'
           elsif !$1.nil?              then '=>'
           elsif !$3.nil?              then $3.gsub(/#/, '\\\\#')
           else
               t
           end
       end
       begin
           return eval(ruby)
       rescue Exception => e
           invalid(json)
       end
   end

   def invalid(string)
       raise RuntimeError, 'Invalid JSON: %s' % string
   end

end
