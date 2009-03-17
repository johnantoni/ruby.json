# minimally featured Grammar class (completely on-the-fly, no code gen)

class Grammar0

    # proxy for another grammar or a block acting as a grammar
    def initialize(grammar=nil,&block) # :yield: input, output, lookahead, fail
        @grammar = grammar||block
    end
    # parse input to output
    def scan(input,output,lookahead=[input.getc],fail=true)
        @grammar[input,output,lookahead,fail]
    end
    alias_method(:[], :scan)
    # alternation of +self+ or +other+ 
    def |(other)
        Grammar0 { |input,output,lookahead,fail|
            self[input,output,lookahead,false] ||
            other[input,output,lookahead,fail]
        }
    end
    # sequence of +self+ followed by +other+
    def +(other)
        Grammar0 { |input,output,lookahead,fail|
            self[input,output,lookahead,fail] &&
            other[input,output,lookahead,true]
        }
    end
    # process output from +self+ and into the output.
    # Block should process output from grammar (+buf+) to the +output+.
    def process(buf0=VOID,&code) # :yield: output, buf, result, fail
        Grammar0 { |input,output,lookahead,fail|
            self[input,buf=buf0.clone,lookahead,fail] && (code[output,buf];true)
        }
    end
    # filter output from +self+.  Block returns a sequence for output concat.
    def filter(buf0=VOID,&code) # :yield: buf
        process(buf0) { |out,buf|
            code ? out.concat(code[buf]) : true
        }
    end
    # group output from +self+.  Block returns an object for output append.
    def group(buf0=VOID,&code) # :yield: buf
        process(buf0) { |out,buf|
            out << (code ? code[buf] : buf)
        }
    end
    # repeat +self+ 0+ times optionally terminated by +term+
    def repeat0(term=nil)
        term ? Right { |g| term | self + g } : Right { |g| self + g | NULL }
    end
    # repeat +self+ 1+ times optionally terminated by +term+
    def repeat1(term=nil)
        term ? Right { |g| self + (term | g) } : self + repeat0
    end
    # Match a single element from the input
    class E < Grammar0
        def initialize(pattern)
            super() { |input,output,lookahead,fail|
                if pattern===lookahead[0]
                    output << lookahead[0]
                    lookahead[0] = input.getc
                    true
                elsif fail
                    error(pattern.inspect, lookahead)
                end
            }
        end
    end
    # Handle recursion with a block that gives the outer grammar from the inner
    class Recurse < Grammar0
        def initialize(&block) # :yield: self
            super(block[self])
        end
    end
    # Handle right recursion (should really do some tail-call optimization)
    Right = Recurse
    
    # Hack to emulate callable classes (like python)
    (constants << to_s).each { |klass|
        eval("
            def #{klass}(*args,&block);#{klass}.new(*args,&block);end
            def self.#{klass}(*args,&block);#{klass}.new(*args,&block);end
        ")
    }
    
    def self.error(expected, lookahead, got=lookahead[0])
        raise("expected #{expected}, got #{got}")
    end
    def error(*args); self.class.error(*args); end
    
    # Match nothing
    NULL = Grammar0 { true }
    # Match the end of our input (end-of-file)
    EOF = Grammar0 { |_,_,lookahead,fail|
        !lookahead[0] || fail && error("EOF", lookahead)
    }
    # Match any single element
    ANY = Grammar0 { |input,output,lookahead,fail|
        if lookahead[0]
            output << lookahead[0]
            lookahead[0] = input.getc
            true
        elsif fail
            error("ANY", nil, "EOF")
        end
    }

    # An empty container that discards anything you put in it.  Not a grammar.
    VOID = Object.new
    class << VOID
        def concat(seq); self; end
        def <<(seq); self; end
    end

end


