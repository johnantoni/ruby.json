require 'rubygems'
gem 'grammar'
require 'grammar'
gem 'cursor'
require 'cursor/io'
require 'duck'

class JSONParser < Grammar

    # bug fix - wasn't raising an exception when EOF wasn't found
    EOF = Inline.new { |cursor,buffer,lookahead,_|
        "(!#{cursor}.skip1after ||
          !#{lookahead} && raise(Error.new(#{cursor},'any element')))"
    }
    
    E = Element

    def initialize

        ws = (E[?\s]|E[?\t]|E[?\n]|E[?\r]).list0.discard
    
        digit = E[(?0..?9).duck!(:==,:===)]
        digits = digit.list1
        e = (E[?e]|E[?E]) + (E[?+]|E[?-]|NULL)
        exp = e + digits
        frac = E[?.] + digits
        int = E[?-] + (E[?0] | digits) | E[?0] | digits
        number = (int.group(String) +
                  (frac + (exp|NULL) | exp | NULL).group(String)).
                 filter(Array) { |n| n[1].empty? ? [n[0].to_i] : [n.to_s.to_f] }

        hex = digit | E[(?a..?f).duck!(:==,:===)] | E[(?A..?F).duck!(:==,:===)]
        char = E[?\\].discard + (
                E[?\"].filter { "\"" } |
                E[?\\].filter { "\\" } |
                E[?\/].filter { "\/" } |
                E[?b].filter { "\b" } |
                E[?f].filter { "\f" } |
                E[?n].filter { "\n" } |
                E[?r].filter { "\r" } |
                E[?t].filter { "\t" } |
                E[?u].discard + (hex+hex+hex+hex).filter { |s| "" << s.to_i(16) }
            ) |
            ANY
        string = E[?\"].discard + char.list0(E[?\"].discard).group(String)
        
        alpha = E[?_] | E[(?a..?z).duck!(:==,:===)] | E[(?A..?Z).duck!(:==,:===)]
        boolean = alpha.list1.filter(String) { |s|
            case s
            when "true" : [true]
            when "false" : [false]
            when "null" : [nil]
            else raise(Error.new(nil, "true|false|null", s))
            end
        }
        
        value = Grammar.new { |value|
            elements = (value + ws).list1(nil, E[?,].discard + ws)
            array = E[?[].discard + ws + (elements + ws|NULL).group(Array) +
                    E[?]].discard
            
            pair = string + ws + E[?:].discard + ws + value
            members = (pair + ws).list1(nil, E[?,].discard + ws)
            object = E[?{].discard + ws + (members|NULL).filter(Array) { |a|
                [Hash[*a]]
            } + E[?}].discard 

            string | number | object | array | boolean
        }

        super(ws + value + ws + EOF)

    end

    def parse(str)
        self.scan(Cursor::IO.new(StringIO.new(str)), output=[])
        raise if output.length!=1
        output[0]
    rescue Grammar::Error => e
        raise(e.to_s)
    end

end

