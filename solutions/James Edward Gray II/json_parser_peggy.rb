#!/usr/bin/env ruby -wKU

require "lib/parser"
require "lib/builder"

class JSONParser < Peggy::Builder
 KEYWORDS = {"true" => true, "false" => false, "null" => nil}
 ESCAPES  = Hash[*%W[b \b f \f n \n r \r t \t]]

 def self.parse(json_string)
   parser = self.new

   parser.source_text = json_string
   parser.parse?(:value) or raise "Failed to parse:  #{json_string.inspect}"

   parser.to_ruby
 end

 def initialize
   super

   self.ignore_productions = [:space]
   space { lit /\s+/ }

   value {
     seq {
       opt { space }
       one {
         object
         array
         string
         number
         keyword
       }
       opt { space }
     }
   }

   object {
     seq {
       lit /\{\s*/
       one {
         seq {
           opt { many { seq { string; lit /\s*:/; value; lit /,\s*/ } } }
                        seq { string; lit /\s*:/; value             }
           lit "}"
         }
         lit "}"
       }
     }
   }

   array {
     seq {
       lit "["
       one {
         seq {
           opt { many { seq { value; lit "," } } }; value; lit "]"
         }
         lit "]"
       }
     }
   }

   string {
     seq {
       lit '"'
       one {
         lit '"'
         seq {
           many {
             one {
               seq { string_content; opt { escape         } }
               seq { escape;         opt { string_content } }
             }
           }
           lit '"'
         }
       }
     }
   }
   string_content { lit(/[^\\"]+/) }
   escape {
     one {
       escape_literal
       escape_sequence
       escape_unicode
     }
   }

   escape_literal  { lit(%r{\\["\\/]})      }
   escape_sequence { lit(/\\[bfnrt]/)       }
   escape_unicode  { lit(/\\u[0-9a-f]{4}/i) }

   number  { lit(/-?(?:0|[1-9]\d*)(?:\.\d+(?:[eE][+-]?\d+)?)?\b/) }
   keyword { lit(/\b(?:true|false|null)\b/)                       }
 end

 def to_ruby(from = parse_results.keys.min)
   kind = parse_results[from][:found_order].first
   to   = parse_results[from][kind]
   send("to_ruby_#{kind}", from, to)
 end

 private

 def to_ruby_object(from, to)
   p parse_results
   object   = Hash.new
   skip_to  = nil
   last_key = nil
   parse_results.keys.select { |k| k > from and k < to }.sort.each do |key|
     content = parse_results[key]
     next if skip_to and key < skip_to
     next unless content[:found_order]                      and
                 ( ( content[:found_order].size == 2        and
                     content[:found_order][1]   == :value ) or
                   content[:found_order]        == [:string] )
     if content[:found_order] == [:string]
       last_key = to_ruby_string(key, content[:string])
     else
       case content[:found_order].first
       when :object
         object[last_key] = to_ruby_object(key, content[:object])
         skip_to = content[:object]
       when :array
         object[last_key] = to_ruby_array(key, content[:array])
         skip_to = content[:array]
       else
         object[last_key] = to_ruby(key)
       end
     end
   end
   object
 end

 def to_ruby_array(from, to)
   array   = Array.new
   skip_to = nil
   parse_results.keys.select { |k| k > from and k < to }.sort.each do |key|
     content = parse_results[key]
     next if skip_to and key < skip_to
     next unless content[:found_order]                and
                 content[:found_order].size == 2      and
                 content[:found_order][1]   == :value
     case content[:found_order].first
     when :object
       array << to_ruby_object(key, content[:object])
       skip_to = content[:object]
     when :array
       array << to_ruby_array(key, content[:array])
       skip_to = content[:array]
     else
       array << to_ruby(key)
     end
   end
   array
 end

 def to_ruby_string(from, to)
   string = String.new
   parse_results.keys.select { |k| k > from and k < to }.sort.each do |key|
     content = parse_results[key]
     next unless content[:found_order]
     case content[:found_order].first
     when :string_content
       string << source_text[key...content[:string_content]]
     when :escape_literal
       string << source_text[content[:escape_literal] - 1, 1]
     when :escape_sequence
       string << ESCAPES[source_text[content[:escape_sequence] - 1, 1]]
     when :escape_unicode
       string << [Integer("0x#{source_text[key + 2, 4]}")].pack("U")
     end
   end
   string
 end

 def to_ruby_number(from, to)
   num = source_text[from...to]
   num.include?(".") ? Float(num) : Integer(num)
 end

 def to_ruby_keyword(from, to)
   KEYWORDS[source_text[from...to]]
 end
end
