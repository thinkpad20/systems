import std.stdio, std.algorithm;

bool isPrefixMatch(string[] tokens, string[][] replacements) {
	foreach (rep; replacements) {
		if (rep.length >= tokens.length) {
			bool match = true;
			for (int i=0; i<tokens.length; ++i) {
				if (tokens[i] != rep[i])
					match = false;
			}
			if (match)
				return true;
		}
	}
	return false;
}

void main() {
	string[][] reps = [["a", "b", "c"],
					   ["d", "g"],
					   ["k", "i", "p"]];
	string[] tokens = ["k", "i", "p"];
	writeln(isPrefixMatch(tokens, reps));
}

//int i=2;
//	bool isLongEnough (string[] slist) {return slist.length > i;}
//	auto pliss = filter!(isLongEnough)(reps);