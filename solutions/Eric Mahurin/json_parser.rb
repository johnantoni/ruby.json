require 'stringio'

class JSONParser

    def parse(s)
        @next = (@io=StringIO.new(s)).getc
        ws
        value(out=[])
        ws
        raise("EOF expected") if @next 
        raise(out.inspect) unless out.length==1 
        out[0]
    end
    
    def error(expected, found)
        raise("expected #{expected}, found #{found ? ("'"<<found<<?\') : 'EOF'}")
    end

    def value(out)
        if ?\[.equal?(@next)
            # array
            @next=@io.getc
            ws
            a = []
            unless ?\].equal?(@next)
                value(a)
                ws
                until ?\].equal?(@next)
                    ?\,.equal?(@next) ? (@next=@io.getc) : error("','", @next)
                    ws
                    value(a)
                    ws
                end
            end
            @next = @io.getc
            out << a
        elsif ?\{.equal?(@next)
            # object
            @next=@io.getc
            ws
            h = {}
            unless ?\}.equal?(@next)
                ?\".equal?(@next) ? string(kv=[]) : error("a string", @next)
                ws
                ?\:.equal?(@next) ? (@next=@io.getc) : error("':'", @next)
                ws
                value(kv)
                ws
                h[kv[0]] = kv[1]
                until ?\}.equal?(@next)
                    ?,.equal?(@next) ? (@next=@io.getc) : error("','", @next)
                    ws
                    ?\".equal?(@next) ? string(kv.clear) : error("a string", @next)
                    ws
                    ?\:.equal?(@next) ? (@next=@io.getc) : error("':'", @next)
                    ws
                    value(kv)
                    ws
                    h[kv[0]] = kv[1]
                end
            end
            @next = @io.getc
            out << h
        elsif (?a..?z)===(@next)
            # boolean
            (s="")<<@next
            @next = @io.getc
            while (?a..?z)===(@next)
                s<<@next;@next=@io.getc
            end
            out << case s
                when "true" then true
                when "false" then false
                when "null" then nil
                else error("'true' or 'false' or 'null'", s)
            end
        elsif ?\".equal?(@next)
            string(out)
        else
            # number
            n = ""
            (n<<@next;@next=@io.getc) if ?-.equal?(@next) 
            ?0.equal?(@next) ? (n<<@next;@next=@io.getc) : digits(n)
            (?..equal?(@next) ?
                (n<<@next;@next=@io.getc;digits(n);exp(n);true) :
                exp(n)) ?
            (out << n.to_f) :
            (out << n.to_i)
        end
    end

    # Flattening/inlining any of the methods below will improve performance further
    
    def ws
        @next = @io.getc while (case @next;when ?\s,?\t,?\n,?\r;true;end)
    end
    
    def digits(out)
        (?0..?9)===@next ? (out<<@next;@next=@io.getc) : error("a digit", @next)
        while (?0..?9)===@next; (out<<@next;@next=@io.getc); end
        true
    end
    
    def exp(out)
        (case @next;when ?e,?E;true;end) ? (out<<@next;@next=@io.getc) :
            return
        (out<<@next;@next=@io.getc) if (case @next;when ?-,?+;true;end) 
        digits(out)
    end
    
    def string(out)
        # we've already verified the starting "
        @next=@io.getc
        s = ""
        until ?\".equal?(@next)
            if ?\\.equal?(@next)
                @next = @io.getc
                case @next
                when ?\",?\\,?\/ then (s<<@next;@next=@io.getc)
                when ?b then (s<<?\b;@next=@io.getc)
                when ?f then (s<<?\f;@next=@io.getc)
                when ?n then (s<<?\n;@next=@io.getc)
                when ?r then (s<<?\r;@next=@io.getc)
                when ?t then (s<<?\t;@next=@io.getc)
                when ?u
                    @next = @io.getc
                    u = ""
                    4.times {
                        case @next
                        when ?0..?9, ?a..?f, ?A..?F
                            u<<@next;@next=@io.getc
                        else
                            error("a hex character", @next)
                        end
                    }
                    s << u.to_i(16)
                else
                    error("a valid escape", @next)
                end
            else
                error("a character", @next) unless @next 
                s<<@next;@next=@io.getc
            end
        end
        @next = @io.getc
        out << s
    end
    
end

