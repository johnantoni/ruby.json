#!/usr/bin/env ruby -wKU

require "rubygems"
require "ghost_wheel"

JSONParser = GhostWheel.build_parser( %q{
 keyword = 'true' { true } | 'false' { false } | 'null' { nil }

 number = /-?(?:0|[1-9]\d*)(?:\.\d+(?:[eE][+-]?\d+)?)?/
          { ast.include?(".") ? Float(ast) : Integer(ast) }

 string_content = /\\\\["\\\\\/]/ { ast[-1, 1] }
                | /\\\\[bfnrt]/
                  { Hash[*%W[b \n f \f n \n r \r t \t]][ast[-1, 1]] }
                | /\\\\u[0-9a-fA-F]{4}/
                  { [Integer("0x#{ast[2..-1]}")].pack("U") }
                | /[^\\\\"]+/
 string         = '"' string_content* '"' { ast.flatten[1..-2].join }

 array_content = value_with_array_sep+ value
                 { ast[0].inject([]) { |a, v| a.push(*v) } + ast[-1..-1] }
               | value? { ast.is_a?(EmptyParseResult) ? [] : [ast] }
 array         = /\[\s*/ array_content /\s*\]/ { ast[1] }

 object_pair         = string /\s*:\s*/ value { {ast[0] => ast[-1]} }
 object_pair_and_sep = object_pair /\s*;\s*/ { ast[0] }
 object_content      = object_pair_and_sep+ object_pair { ast.flatten }
                     | object_pair?
                       { ast.is_a?(EmptyParseResult) ? [] : [ast] }
 object              = /\\\{\s*/ object_content /\\\}\s*/
                       { ast[1].inject({}) { |h, p| h.merge(p) } }

 value_space          = /\s*/
 value_content        = keyword | number | string | array | object
 value                = value_space value_content value_space { ast[1] }
 value_with_array_sep = value /\s*,\s*/ { ast[0] }

 json := value EOF { ast[0] }
} )
