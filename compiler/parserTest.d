import std.stdio, std.algorithm, std.string;

struct GrammarRule {
	string source;
	string[] goesTo;
	this(string source, string[] goesTo) {
		this.source = source;
		this.goesTo = goesTo;
	}
	string toString() {
		return format("(%s -> %s)", source, goesTo);
	}
}

struct Grammar {
	GrammarRule[] grammar;
	void insertRule(string source, string[] goesTo) {
		grammar ~= GrammarRule(source, goesTo);
	}
	string[][] getReplacements(string source, int depth = 1) {
		string[][] replacements = [[source]];
		foreach (gr; grammar)
			if (gr.source == source)
				replacements ~= gr.goesTo;
		return replacements;
	}

	string[][] showPossibilities(string[] tokens, int depth = 1) {
		string[][] results;
		foreach(token; tokens) {
			if (results.length == 0) {
				results = getReplacements(token, depth);
			}
			else {
				string[][] newResults;
				foreach(replacement; getReplacements(token, depth)) {
					for (int k=0; k<results.length; ++k) {
						string[] newResult = results[k];
						newResult ~= replacement;
						newResults ~= newResult;
					}
				}
				results = newResults;
			}
		}
		return results;
	} 
}

Grammar grammar;

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


void init() {
	grammar.insertRule("class", ["class", "className", "{", "classVarDec", "subroutineDec", "}"]);
	//a classVarDec consists of 0 or more classVarDecs. Similarly for subroutineDec.
	grammar.insertRule("classVarDec", ["classVarDec", "classVarDec"]);
	grammar.insertRule("classVarDec", [""]);
	grammar.insertRule("classVarDec", ["static", "type", "varName", "optVarArgs", ";"]);

	grammar.insertRule("classVarDec", "static", "type", "varName", ";");
	grammar.insertRule("subroutineDec", ["subroutineDec", "subroutineDec"]);
	grammar.insertRule("subroutineDec", [""]);

	grammar.insertRule("letStatement", ["let", "varName", "=", "expression", ";"]);
	grammar.insertRule("varName", ["identifier"]);
	grammar.insertRule("varName", ["varName", "[", "expression", "]"]);
	indent = 0;
}

void main(string[] args) {
	init();
	auto tokens = ["a", "exp"];
	string[][] results = grammar.showPossibilities(tokens);
	//foreach(res; results)
	//	writeln(res);
	string[][] results2;
	writeln(grammar.getReplacementsR("exp", 2));
}