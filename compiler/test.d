import std.stdio, tokenTrie, std.regex;


bool match_str(string str) {
	return str[0] == '"' && str[$-1] == '"';
}

void main(string[] args) {
	string test = "  ";
	auto ident_match = match(test, regex(r"[a-zA-Z_][a-zA-Z0-9_]*"));
	auto ws_match = match(test, regex(r"[ \n\r\t]+"));
	if (ws_match.hit == test)
		writeln("yes");
	else
		writeln("no");
}