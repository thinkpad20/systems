import std.stdio, std.algorithm, std.string;

bool thing(int a) {
	return a>1;
}

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

	string[][] getReplacementsR(string source, int depth) {
		string[][] results = [[source]];
		for (int i=0; i<depth; ++i) {
			string[][] newResults;
			foreach (result; results) {
				foreach (token; result) {
					newResults ~= getReplacements(token);
				}
			}
			results = newResults;
		}
		return results ~ [source];
		//writefln("source: %s depth: %s results: %s", source, depth, results);
		//if (depth == 0)
		//	return results ~ [source] ~ getReplacements(); //"itself" is the last possible element we'll add.
		//foreach (gr; grammar)
		//	if (gr.source == source) {
		//		writeln("Grammar rule ", gr, " matches.");
		//		foreach (token; gr.goesTo) {
		//			writeln("recursing on ", token);
		//			return results ~ getReplacementsR(token, depth-1, results);
		//		}
		//	}
		////if there's no deeper to recurse, the item can return itself.
		//return [[source]];
	}

	string[][] showPossibilities(string[] tokens, int depth = 1) {
		string[][] results;
		foreach(token; tokens) {
			//writeln("processing token ", token);
			//writeln("replacements: ", getReplacements(token, depth));
			if (results.length == 0) {
				//writeln("1");
				results = getReplacements(token, depth);
			}
			else {
				//writeln("2");
				string[][] newResults;
				foreach(replacement; getReplacements(token, depth)) {
					//writeln("treating replacement ", replacement);
					for (int k=0; k<results.length; ++k) {
						string[] newResult = results[k];
						//writeln("tagging replacement ", replacement, " onto result ", results[k]);
						newResult ~= replacement;
						//writeln("result is now ", newResult);
						newResults ~= newResult;
					}
				}
				results = newResults;
			}
		}
		//writeln("results are now ", results);
		return results;
	} 
}

Grammar grammar;

void init() {
	grammar.insertRule("exp", ["exp", "+", "exp"]);
	grammar.insertRule("exp", ["exp", "-", "exp"]);
	grammar.insertRule("exp", ["(","exp", ")"]);
	grammar.insertRule("exp", ["num"]);
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