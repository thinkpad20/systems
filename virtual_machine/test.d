import std.stdio, std.string, std.conv;

void filter_line(ref string s) {
    string toRemove = "\t\n\r ";
    foreach (c; toRemove)
        s = removechars(s, to!string(c));
}

void main() {
	string poop = "(howz       // its)";
	writeln(poop.split("^"));
}