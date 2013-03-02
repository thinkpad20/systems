import std.stdio, std.string, std.conv, std.algorithm;

string removeComments(string filename) {
	string[] lines;
	string noComments;
	auto file = File(filename, "r");
	foreach (line; file.byLine)
		lines ~= to!string(line);
	foreach (line; lines) {
		string strippedLine = line.split("//")[0];
		noComments ~= strippedLine;
	}
	return noComments;
}

void main(string args[]) {
	string[] tests = ["       sdfkjs oioi hi iii      ", "heyhowzits   ", "   yoyuo"];
	foreach (i, ln; tests) {
		tests[i] = ln.strip();
	}
	foreach (ln; tests)
		writeln("'", ln, "'");

	string noComs = removeComments(args[1]);
	writeln(noComs);
}