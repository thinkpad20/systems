import std.stdio, std.string, std.algorithm, std.conv, std.container;

struct SymbolTableEntry {
	string symbol;
	string vm;
	string type;
	this(string symbol, string vm, string type) {
		this.symbol = symbol; 
		this.vm = vm; 
		this.type = type;
	}
	string toString() {
		return symbol ~ ": " ~ vm ~ " (" ~ type ~ ")";
	}
}

// given a symbol, returns the appropriate vm code and type
struct SymbolTable {
	SymbolTableEntry[string] table;
	void set(string symbol, SymbolTableEntry ste) {
		table[symbol] = ste;
	}
	SymbolTableEntry get(string symbol) {
		if (!(symbol in table))
			throw new Exception(format("Get called on symbol (%s) that doesn't exist", symbol));
		return table[symbol];
	}
	bool contains(string symbol) {
		if (symbol in table) return true;
		return false;
	}
	string toString() {
		string ret = "";
		foreach(symbol; table.keys) {
			ret ~= to!string(table[symbol]);
			ret ~= "\n";
		}
		return ret;
	}
}

struct SymbolTableStack {
	SymbolTableStackNode first;

	void push(SymbolTable st) {
		auto newFirst = new SymbolTableStackNode(st);
		newFirst.next = first;
		writeln("old first : ", first);
		first = newFirst;
		writeln("new first : ", first);
		writeln("new next : ", first.next);
	}
	SymbolTable pop() {
		SymbolTable toReturn = first.table;
		first = first.next;
		return toReturn;
	}
	string toString() {
		string res = "";
		auto current = first;
		while (current !is null) {
			res ~= to!string(current.table) ~ "\n";
			current = current.next;
		}
		return res;
	}
	SymbolTable peek() {
		return first.table;
	}
	SymbolTableEntry lookup(string symbol) {
		auto current = first;
		while (current !is null) {
			if (current.table.contains(symbol))
				return current.table.get(symbol);
			current = current.next;
		}
		throw new Exception(format("Unrecognized symbol: %s", symbol));
	}
}

class SymbolTableStackNode {
	SymbolTable table;
	SymbolTableStackNode next = null;
	this(SymbolTable table) {
		this.table = table;
	}
}

void main() {
	SymbolTableEntry ste1 = SymbolTableEntry("i", "local 0", "int"),
	                 ste2 = SymbolTableEntry("j", "local 1", "int"),
	                 ste3 = SymbolTableEntry("x", "local 0", "obj"),
	                 ste4 = SymbolTableEntry("y", "local 1", "boolean");
	SymbolTableEntry ste5 = SymbolTableEntry("i", "local 1", "int"),
	                 ste6 = SymbolTableEntry("j", "local 0", "int"),
	                 ste7 = SymbolTableEntry("x", "local 1", "obj"),
	                 ste8 = SymbolTableEntry("y", "local 0", "boolean");
	SymbolTable t1, t2;
	t1.set("i", ste1); t1.set("j", ste2);
	t1.set("x", ste7); t1.set("y", ste8);
	t2.set("x", ste3); t2.set("y", ste4);
	t2.set("i", ste5); t2.set("j", ste6);
	SymbolTableStack sts;
	sts.push(t1);
	sts.push(t2);
	writeln(sts);
	writeln(sts.lookup("k"));
}

//int i=2;
//	bool isLongEnough (string[] slist) {return slist.length > i;}
//	auto pliss = filter!(isLongEnough)(reps);