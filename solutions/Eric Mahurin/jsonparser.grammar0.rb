require 'grammar0'
require 'stringio'

class JSONParser < Grammar0

    def initialize

        ws = (E(?\s)|E(?\t)|E(?\n)|E(?\r)).repeat0.filter
    
        digit = E(?0..?9)
        digits = digit.repeat1
        e = (E(?e)|E(?E)) + (E(?+)|E(?-)|NULL)
        exp = e + digits
        frac = E(?.) + digits
        int = E(?-) + (E(?0) | digits) | E(?0) | digits
        number = (int.group("") + (frac + (exp|NULL) | exp | NULL).group("")).
                 group([]) { |n| n[1].empty? ? n[0].to_i : n.to_s.to_f }

        hex = digit | E(?a..?f) | E(?A..?F)
        char = E(?\\).filter + (
                E(?\").group { ?\" } |
                E(?\\).group { ?\\ } |
                E(?\/).group { ?\/ } |
                E(?b).group { ?\b } |
                E(?f).group { ?\f } |
                E(?n).group { ?\n } |
                E(?r).group { ?\r } |
                E(?t).group { ?\t } |
                E(?u).filter + (hex+hex+hex+hex).group("") { |s| s.to_i(16) }
            ) |
            ANY
        string = E(?\").filter + char.repeat0(E(?\").filter).group("")
        
        alpha = E(?_) | E(?a..?z) | E(?A..?Z)
        boolean = alpha.repeat1.group("") { |s|
            case s
            when "true" : true
            when "false" : false
            when "null" : nil
            else error("true|false|null", nil, s)
            end
        }
        
        value = Recurse { |value|
            elements = Right { |elements|
                value + ws + (E(?,).filter + ws + elements | NULL)
            }
            array = E(?[).filter + ws + (elements + ws|NULL).group([]) + E(?]).filter
            
            pair = (string + ws + E(?:).filter + ws + value).process([]) { |h,kv|
                h[kv[0]] = kv[1]
            }
            members = Right { |members|
                pair + ws + (E(?,).filter + ws + members | NULL)
            }
            object = E(?{).filter + ws + (members|NULL).group({}) + E(?}).filter 

            string | number | object | array | boolean
        }

        super(ws + value + ws + EOF)

    end

    def parse(str)
        self.scan(StringIO.new(str), output=[])
        raise if output.length!=1
        output[0]
    end

end


