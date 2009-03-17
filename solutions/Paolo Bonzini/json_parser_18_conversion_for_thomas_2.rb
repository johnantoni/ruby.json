class JSONParser

  RXE = /
      [\[\]\{\}[:space:][:cntrl:]truefals]+|
      (:)|
      (?:,(?>\s*)(?![}\]]))|
      ("(?>[^"\\]+|\\(?:u[0-9a-fA-F]{4}|[bfnrt"\/\\]))*")|
      -?(?=\d)(?>0|[1-9]\d*)(?>\.\d+)?(?>[Ee][+-]?\d+)?(?=\D|$)|
      (null)|
      (.+)
  /xmu

  def parse(json)
      ruby = json.gsub(RXE) do |t|
          if !$4.nil?         then invalid($4)
          elsif !$3.nil?      then 'nil'
          elsif !$1.nil?      then '=>'
          elsif !$2.nil?      then $2.gsub(/#/, '\\\\#')
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
