#!/usr/bin/env ruby

# Solution to Ruby Quiz #155 (see http://www.rubyquiz.com/quiz155.html)
# by Paweł Radecki (pawel.j.radecki@gmail.com).

$KCODE='UTF-8'
require 'jcode'

class JSONParser

 def parse(input)
   case input
   # TODO: in every case we need to check if pattern matches the input thoroughly and nothing is left;
   # ex. "[3, 5] Pablos" still not handled well, it passes through instead of giving exception

   when '' : raise RuntimeError

   # TODO: There needs to be some smart way of choosing whether we found an object or an array;
   # now object has priority and it may be found instead of an array

   #object
   when /\{(".+"):(.+)\s*(,\s*(".+"):(.+))+\}/ then
     h = Hash.new
     $&[1...-1].split(/(.*:.*)?\s*,\s*(.*:.*)?/).each do |e|
       a = e.split(/:\s*(\{.*\}\s*)?/);
       h[parse(a.first)] = parse(a.last) unless (a.first.nil? && a.last.nil?)
     end
     h
   when /\{\s*(".+")\s*:\s*(.+)\s*\}/ then { parse($1) => parse($2) }
   when /\{\s*\}/ : Hash.new

   #array
   when /\[.+\]/ then $&[1...-1].split(/(\[.*\])?\s*,\s*(\[.*\])?/).collect{|e| parse(e)}
   when /\[\s*\]/ then []

   #constants
   when /true/ then
     if ($`.strip.empty? && $'.strip.empty?) then true else raise RuntimeError end
   when /false/ then
     if ($`.strip.empty? && $'.strip.empty?) then false else raise RuntimeError end
   when /null/ then nil
     if ($`.strip.empty? && $'.strip.empty?) then nil else raise RuntimeError end

   #string
   when /"([A-Za-z]|(\s)|(\\")|(\\\\)|(\\\/)|(\\b)|(\\f)|(\\n)|(\\r)| (\\t)|(\\u[0-9a-fA-F]{4,4}))+"/ : $&[1...-1].gsub(/\\"/, '"').gsub(/\\n/, "\n").gsub(/\\u([0-9a-fA-F]{4,4})/u){["#$1".hex ].pack('U*')}
   when /""/ then ""

   #number
   when /-?(0|([1-9][0-9]*))(\.[0-9]+)?([e|E][+|-]?[0-9]+)?/ then
     if ($`.strip.empty? && $'.strip.empty?) then eval($&) else raise RuntimeError end
   else
     raise RuntimeError
   end
 end
end

#puts JSONParser.new.parse(ARGV.first)
