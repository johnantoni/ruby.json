require 'rubygems'
require 'json'

def random_json
 case rand
   when 0 ... 1/3.0
     top = Hash.new
     add = lambda{|obj| top[obj] = obj}
   when 1/3.0 ... 2/3.0
     top = Array.new
     add = lambda{|obj| top.push obj}
   when 2/3.0 .. 1
     top = String.new
     add = lambda{|obj| top += obj}
 end
 10.times{ add[rand.to_s] }
 top.to_json
end

puts random_json

