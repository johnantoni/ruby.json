require 'treetop'

File.open("json.treetop", "w") {|f| f.write GRAMMAR }

Treetop.load "json"
parser = JsonParser.new

pp parser.parse(STDIN.read).value  if $0 == __FILE__


BEGIN {

GRAMMAR = %q{
grammar Json
  rule json
    space json_value space { def value; json_value.value; end } 
  end

  rule json_value
    string / numeric / keyword / object / array
  end


  rule string
    '"' chars:char* '"' {
      def value
        chars.elements.map {|e| e.value }.join
      end
    }
  end

  rule char
    !'"' ('\\\\' ( ( [nbfrt"] / '\\\\' / '/' ) / 'u' hex hex hex hex ) / !'\\\\' .) {
      def value
        if text_value[0..0] == '\\\\'
          case c = text_value[1..1]
          when /[nbfrt]/
            {'n' => "\n", 'b' => "\b", 'f' => "\f", 'r' => "\r", 't' => "\t"}[c]
          when 'u'
            [text_value[2,4].to_i(16)].pack("L").gsub(/\0*$/,'')
          else
            c
          end
        else
          text_value
        end
      end
    }
  end

  rule hex
    [0-9a-fA-F]
  end


  rule numeric
    exp / float / integer
  end

  rule exp
    (float / integer) ('e' / 'E') ('+' / '-')? integer  { def value; text_value.to_f; end }
  end

  rule float
    integer '.' [0-9]+  { def value; text_value.to_f; end }
  end

  rule integer
    '-'? ('0' / [1-9] [0-9]*)  { def value; text_value.to_i; end }
  end


  rule keyword
    ('true' / 'false' / 'null') {
      def value
        { 'true' => true, 'false' => false, 'null' => nil }[text_value]
      end
    }
  end


  rule object
    '{' space pairs:pair* space '}' {
      def value
        pairs.elements.map {|p| p.value }.inject({}) {|h,p| h.merge p }
      end
    }
  end

  rule pair
    space string space ':' space json_value space (',' &pair / !pair) {
      def value
        { string.value => json_value.value }
      end
    }
  end

  
  rule array
    '[' space array_values:array_value* space ']' {
      def value
        array_values.elements.map {|e| e.value }
      end
    }
  end

  rule array_value
    space json_value space (',' &array_value / !array_value) {
      def value
        json_value.value
      end
    }
  end


  rule space
    [ \t\r\n]*
  end

end
}

}