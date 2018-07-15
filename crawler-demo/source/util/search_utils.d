module util.search_utils;
import arsd.dom;
import std.regex;
import std.exception: enforce;
import std.format: format;
import std.stdio: writefln;

ElementRange childRange (Element elem) {
    return ElementRange(elem, 0, elem.children.length);
}

bool regexMatch (string regex, Args...)(Element elem, ref Args args) {
    auto match = matchFirst(elem.innerText, ctRegex!regex);
    if (!match) return false;
    size_t i = 0;
    foreach (ref arg; args) {
        arg = match[++i];
    }
    return true;
}

struct ElementRange {
    private Element head;
    private size_t start, stop, current;

    this (Element elem, size_t start, size_t stop) {
        this.head = elem;
        this.current = this.start = start;
        this.stop = stop;
    }
    private this (Element elem, size_t start, size_t stop, size_t current) {
        this.head = elem;
        this.start = start;
        this.stop = stop;
        this.current = current;
    }

    private bool bounded () { return current >= start && current < stop; }
    @property Element front () { assert(bounded); return head[current]; }
    bool empty () { return !bounded; }
    void popFront () { assert(bounded); ++current; }
    Element moveFront () { assert(bounded); return head[current++]; }
    ElementRange save () { return ElementRange(head, start, stop, current); }
    Element back () { assert(bounded); return head[stop - 1]; }
    void popBack () { assert(bounded); --stop; }
    size_t length () { return stop - start; }
    Element opIndex (size_t i) { assert(start + i < length); return head[start + i]; }

    ref ElementRange requireSeq (bool delegate (Element elem) predicate) {
        auto start = save();
        //writefln("Range empty? %s", empty);
        while (!empty && !predicate(front)) {
            //writefln("Did not match '%s'", front);
            popFront;
        }
        enforce(!empty, format("Failed to find sequence, starting at %s", save.front.innerHTML));
        //writefln("Matched! %s", front);
        return this;
    }

    unittest {
        import std.range.primitives;
        static assert(isForwardRange!ElementRange);
        static assert(isBidirectionalRange!ElementRange);
        static assert(isRandomAccessRange!ElementRange);
    }
}
