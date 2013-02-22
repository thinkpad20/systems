import std.stdio, std.string, std.conv;

bool is_integer(string s) {
    string digits = "0123456789";
    foreach (c; s)
        if (indexOf(digits, c)<0)
            return false;
    return true;
}

void main() {
	writeln(is_integer("1a23"));
}