import std.stdio, std.string, std.conv, std.math, std.regex;

string binary;
string[string] comp_dict, jump_dict;
Regex!char num_regex = regex(r"[0-9]+"),
		   ident_regex = regex(r"[a-zA-Z$_.][a-zA-Z0-9?_.:]+"),
		   a_instruction = regex(r"@([0-9]+|[a-zA-Z_$.][a-zA-Z0-9$_.]+)"),
		   assign = regex(r"[AMD][AMD]?[AMD]?=(([AMD](\+|-|&|\|)[AMD1])|([-!]?[AMD10]))"),
		   jump = regex(r"[AMD0];J(GT|EQ|GE|LT|NE|LE|MP)"),
		   address = regex(r"\([a-zA-Z$_.:][a-zA-Z0-9$_.:]+\)");

class SymbolTable {
	int next_open=0;
	int[string] addressMap;
	this() {
		addressMap = ["SP":0, "LCL":1, "ARG":2, "THIS":3, 
					  "THAT":4, "SCREEN":16384, "KBD":24576];
		for (int i=0; i<16; ++i)
			add_symbol(format("R%s", i));
	}

	bool add_symbol(string sym) {
		if (addressMap.get(sym, -1) == -1) {
			addressMap[sym] = next_open;
			++next_open;
			return true;
		} else
			return false;
	}

	bool add_at(string sym, int address) {
		if (addressMap.get(sym, -1) == -1) {
			addressMap[sym] = address;
			return true;
		} else
			return false;
	}

	int get(string sym) {
		add_symbol(sym);
		return addressMap[sym];
	}

}

SymbolTable s_table;

void init() {
	binary = "%s%s%s%s\n"; //header, comp, dest, jump
	s_table = new SymbolTable;
}

string convert_to_binary(int num, int max_bits = 15) {
	string inst = "0";
	for (int i=max_bits-1; i>=0; --i) {
		if (pow(2, i) & num)
			inst ~= "1";
		else
			inst ~= "0";
	}
	return inst;
}

string build_a_instruction(string s) {
	int val;
	if (match(s[1..$], num_regex)) {
		val = to!int(s[1..$]);
	} else {
		val = s_table.get(s[1..$]);
	}
	return convert_to_binary(val);
}

//string build_instruction(string s) {
//	if (s.indexOf("@") > 0)
//		return build_a_instruction(s);
//	else if (s.indexOf("=") > 0)
//		return build_assignment_instruction(s);
//	else if (s.indexOf(";") > 0)
//		return build_jump_instruction(s);
//	else
//		return "";
//}

void main() 
{
	init();
	string s = "123";
	writeln(build_a_instruction("@poop"));
	writeln(build_a_instruction("@plop"));
	writeln(build_a_instruction("@pope"));
	writeln(build_a_instruction("@poop"));
	writeln(build_a_instruction("@plop"));
	writeln(build_a_instruction("@pope"));
}