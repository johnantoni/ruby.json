require "test/unit"

class TestJSONParser < Test::Unit::TestCase
  def setup
    @parser = JSONParser.new
  end
  
  def test_keyword_parsing
    assert_equal(true,  @parser.parse("true"))
    assert_equal(false, @parser.parse("false"))
    assert_equal(nil,   @parser.parse("null"))
  end
  
  def test_number_parsing
    assert_equal(42,     @parser.parse("42"))
    assert_equal(-13,    @parser.parse("-13"))
    assert_equal(3.1415, @parser.parse("3.1415"))
    assert_equal(-0.01,  @parser.parse("-0.01"))
  
    assert_equal(0.2e1,  @parser.parse("0.2e1"))
    assert_equal(0.2e+1, @parser.parse("0.2e+1"))
    assert_equal(0.2e-1, @parser.parse("0.2e-1"))
    assert_equal(0.2E1,  @parser.parse("0.2e1"))
  end
  
  def test_string_parsing
    assert_equal(String.new, @parser.parse(%Q{""}))
    assert_equal("JSON",     @parser.parse(%Q{"JSON"}))
  
    assert_equal(%Q{nested "quotes"}, @parser.parse('"nested \"quotes\""'))
    assert_equal("\n",                @parser.parse(%Q{"\\n"}))
    assert_equal("a",                 @parser.parse(%Q{"\\u#{"%04X" % ?a}"}))
  end
  
  def test_array_parsing
    assert_equal(Array.new,     @parser.parse(%Q{[]}))
    assert_equal( ["JSON", 3.1415, true],
                  @parser.parse(%Q{["JSON", 3.1415, true]}) )
    assert_equal([1, [2, [3]]], @parser.parse(%Q{[1, [2, [3]]]}))
  end
  
  def test_object_parsing
    assert_equal(Hash.new, @parser.parse(%Q{{}}))
    assert_equal( {"JSON" => 3.1415, "data" => true},
                  @parser.parse(%Q{{"JSON": 3.1415, "data": true}}) )
    assert_equal( {"Array" => [1, 2, 3], "Object" => {"nested" => "objects"}},
                  @parser.parse(<<-END_OBJECT) )
    {"Array": [1, 2, 3], "Object": {"nested": "objects"}}
    END_OBJECT
  end
  
  def test_parse_errors
    assert_raise(RuntimeError) { @parser.parse("{") }
    assert_raise(RuntimeError) { @parser.parse(%q{{"key": true false}}) }
  
    assert_raise(RuntimeError) { @parser.parse("[") }
    assert_raise(RuntimeError) { @parser.parse("[1,,2]") }
  
    assert_raise(RuntimeError) { @parser.parse(%Q{"}) }
    assert_raise(RuntimeError) { @parser.parse(%Q{"\\i"}) }
  
    assert_raise(RuntimeError) { @parser.parse("$1,000") }
    assert_raise(RuntimeError) { @parser.parse("1_000") }
    assert_raise(RuntimeError) { @parser.parse("1K") }
  
    assert_raise(RuntimeError) { @parser.parse("unknown") }
  end
end