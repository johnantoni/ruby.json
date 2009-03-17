# A solution to RubyQuiz #155.
#
# Takes a JSON string and parses it into an equivalent Ruby value.
#
# See http://www.rubyquiz.com/quiz155.html for details.
#
# The latest version of this solution can also be found at
# http://learnruby.com/examples/ruby-quiz-155.shtml .

require 'rubygems'
require 'treetop'

Treetop.load 'json'

class JSONParser
 def initialize
   @parser = JSONHelperParser.new
 end

 def parse(input)
   result = @parser.parse(input)
   raise "could not parse" if result.nil?
   result.resolve
 end
end
