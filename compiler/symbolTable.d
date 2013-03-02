module symbolTable;
import std.stdio, std.string, std.algorithm, std.conv, std.container, jackTokenizer;

class SymbolTableEntry {
	string symbol;
	string vm;
	string type;
	this(string symbol, string vm, string type) {
		this.symbol = symbol; 
		this.vm = vm; 
		this.type = type;
	}
	string toStr() {
		return symbol ~ ": " ~ vm ~ " (" ~ type ~ ")";
	}
}

// given a symbol, returns the appropriate vm code and type
class SymbolTable {
	SymbolTableEntry[string] table;

	void set(string symbol, string vm, string type) {
		SymbolTableEntry ste = new SymbolTableEntry(symbol, vm, type);
		table[symbol] = ste;
	}

	void set(string symbol, SymbolTableEntry ste) {
		table[symbol] = ste;
	}

	SymbolTableEntry get(string symbol) {
		if (!(symbol in table))
			return null;
		return table[symbol];
	}
	bool contains(string symbol) {
		if (symbol in table) return true;
		return false;
	}
	string toStr() {
		string ret = "";
		foreach(symbol; table.keys) {
			ret ~= table[symbol].toStr();
			ret ~= "\n";
		}
		return ret;
	}
}

struct SymbolTableStack {
	SymbolTableStackNode first;

	void push(bool toPrint = false) {
		if (toPrint) writeln("*******************\nPushing a new SymbolTable\n*******************");
		SymbolTable st = new SymbolTable();
		push(st);
	}
	void push(SymbolTable st) {
		auto newFirst = new SymbolTableStackNode(st);
		newFirst.next = first;
		first = newFirst;
	}
	SymbolTable pop(bool toPrint = false) {
		if (toPrint) writeln("*******************\nPopping a new SymbolTable\n*******************");
		SymbolTable toReturn = first.table;
		first = first.next;
		return toReturn;
	}
	string toString() {
		string res = "********Printing symbol table********\n";
		auto current = first;
		while (current !is null) {
			res ~= current.toStr() ~ "\n";
			current = current.next;
		}
		return res ~ "******finished printing*****\n";
	}
	SymbolTableStackNode top() {
		return first;
	}
	SymbolTableEntry lookup(string symbol) {
		auto current = first;
		while (current !is null) {
			if (current.table.contains(symbol))
				return current.table.get(symbol);
			current = current.next;
		}
		return null;
	}
	void addSymbol(string symbol, string vm, string type, bool toPrint = false) {
		if (toPrint) writefln("adding %s, %s, %s to table", symbol, vm, type);
		top().table.set(symbol, vm, type);
	}
	void addSymbol(string symbol, SymbolTableEntry ste) {
		top().table.set(symbol, ste);
	}
	void addSymbolAbove(string symbol, string vm, string type, bool toPrint = false) {
		if (toPrint) writefln("adding %s, %s, %s to table one step up", symbol, vm, type);
		top().next.table.set(symbol, vm, type);
	}
}

class SymbolTableStackNode {
	SymbolTable table;
	SymbolTableStackNode next = null;
	this(SymbolTable table) {
		this.table = table;
	}
	string toStr() {
		return table.toStr();
	}
}

//for testing

//void main() {
//	SymbolTableEntry ste1 = new SymbolTableEntry("i", "local 0", "int"),
//	                 ste2 = new SymbolTableEntry("j", "local 1", "int"),
//	                 ste3 = new SymbolTableEntry("x", "local 0", "obj"),
//	                 ste4 = new SymbolTableEntry("y", "local 1", "boolean");
//	SymbolTableEntry ste5 = new SymbolTableEntry("i", "local 1", "int"),
//	                 ste6 = new SymbolTableEntry("j", "local 0", "int"),
//	                 ste7 = new SymbolTableEntry("x", "local 1", "obj"),
//	                 ste8 = new SymbolTableEntry("y", "local 0", "boolean");
//	SymbolTableStack sts;
//	sts.push();
//	sts.addSymbol("i", ste1); 
//	sts.addSymbol("j", ste2);
//	sts.push();
//	writeln(sts);
//	SymbolTableEntry xRes, iRes;
//	xRes = sts.lookup("x");
//	if (xRes) writeln("result for x: ", xRes.toStr()); else writeln("x not found");
//	iRes = sts.lookup("i");
//	if (iRes) writeln("result for i: ", iRes.toStr()); else writeln("i not found");
//	sts.addSymbol("x", ste3); 
//	sts.addSymbol("y", ste4);
//	writeln(sts);
//	xRes = sts.lookup("x");
//	if (xRes) writeln("result for x: ", xRes.toStr()); else writeln("x not found");
//	iRes = sts.lookup("i");
//	if (iRes) writeln("result for i: ", iRes.toStr()); else writeln("i not found");
//}

//int i=2;
//	bool isLongEnough (string[] slist) {return slist.length > i;}
//	auto pliss = filter!(isLongEnough)(reps);