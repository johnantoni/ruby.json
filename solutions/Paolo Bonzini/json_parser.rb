class JSONParser
  def try(re)
    m = @s.match(re)
    return false if m.nil?

    @s = m.post_match if m.length
    yield m.to_s if block_given?
    true
  end

  def parse_keyword (a)
    return true if a == "true"
    return false if a == "false"
    nil
  end

  def parse_string (a)
    a[1..-2].gsub(/(\\[bfrnt"\\]|\\u(....)|[^\\]*)/) {
      |a|
      a[0] != ?\\ ? a :
      a[1] == ?b ? "\b" :
      a[1] == ?f ? "\f" :
      a[1] == ?r ? "\r" :
      a[1] == ?n ? "\n" :
      a[1] == ?t ? "\t" :
      a[1] == ?u ? a[3..-1].hex.chr :
      a[1].chr
   }
  end

  def parse_array ()
    array = []
    array << parse_atom unless try(/\A\s*(?=\])/)
    array << parse_atom while try(/\A\s*,/)
    array if try(/\A\s*\]/)
  end

  RE_COLON = /\A\s*:\s*/
  RE_IS_STRING = /\A\s*(?=")/
  def parse_hash ()
    hash = Hash.new
    hash[parse_atom(RE_IS_STRING)] = parse_atom(RE_COLON) unless try(/\A\s*(?=\})/)
    hash[parse_atom(RE_IS_STRING)] = parse_atom(RE_COLON) while try(/\A\s*,/)
    hash if try(/\A\s*\}/)
  end

  RE_TFN = /\A(?:true|false|null)\b/
  RE_NUM = /\A-?[0-9]+(?>\.[0-9]*)?(?>[eE][+-]?[0-9]+)?/
  RE_STR = /\A"(?:(?>[^\\"]*)(?>\\u[0-9A-Fa-f]{4}|\\["\\bfrnt]|(?=")))*"/
  RE_ARRAY = /\A\[/
  RE_HASH = /\A\{/

  def parse_atom (before = /\A\s*/)
    raise RuntimeError if !try(before)
    try(RE_TFN) { |a| return parse_keyword(a) }
    try(RE_NUM) { |a| return a.to_f }
    try(RE_STR) { |a| return parse_string(a) }
    try(RE_ARRAY) { return parse_array() }
    try(RE_HASH) { return parse_hash() }
    raise RuntimeError
  end

  def parse (s)
    @s = s
    # raise RuntimeError if !@s.match(/\A\s*[\[{]/)
    a = parse_atom
    raise RuntimeError if @s.match(/\S/)
    a
  end
end