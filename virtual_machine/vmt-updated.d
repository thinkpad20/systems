import std.stdio, std.string, std.conv, std.array, std.algorithm;

string[string] operations_dict;
int[string] type_dict;
string[][string] vars_dict;
string[] arithmetic, memory, comp_ops, unary_ops, binary_ops;
string start, end, binary_template, unary_template,
		comp_template, push_tail_template, push_const_template,
		push_var_template, push_staticpointer_template,
		pop_template, pop_staticpointer_template, filename,
		label_template, goto_template, if_goto_template;
int op_count, line_count;
const TYPE_ARITHMETIC = 0, TYPE_MEMORY = 1, 
	 TYPE_LABEL = 2, TYPE_GOTO = 3;

void build_dictionaries() {
	vars_dict = ["this":["THIS","M"],
				 "that":["THAT","M"],
				 "argument":["ARG","M"],
				 "local":["LCL","M"],
				 "static":["f.%d","M"],
				 "temp":["TEMP","A"]];

	operations_dict = ["add":"+", "sub":"-",
				   "and":"&", "or":"|",
				   "not":"!", "neg":"-",
				   "lt":"JLT", "gt":"JGT",
				   "eq":"JEQ", "leq":"JLE",
				   "geq":"JGE"];

	type_dict = ["add":TYPE_ARITHMETIC, "sub":TYPE_ARITHMETIC,
				   "and":TYPE_ARITHMETIC, "or":TYPE_ARITHMETIC,
				   "not":TYPE_ARITHMETIC, "neg":TYPE_ARITHMETIC,
				   "lt":TYPE_ARITHMETIC, "gt":TYPE_ARITHMETIC,
				   "eq":TYPE_ARITHMETIC, "leq":TYPE_ARITHMETIC,
				   "geq":TYPE_ARITHMETIC, "label":TYPE_LABEL,
				   "goto":TYPE_GOTO, "if-goto":TYPE_GOTO,
				   "push":TYPE_MEMORY, "pop":TYPE_MEMORY];

	binary_ops = ["add", "sub", "and", "or"];
	unary_ops = ["not", "neg"];
	comp_ops = ["lt", "gt", "eq", "leq", "geq"];
}

void build_strings() {
	start = "@SP\nAM=M-1\n";
	end = "@SP\nM=M+1\n";

	binary_template = start ~ "D=M\n"
	"@SP\n"
	"AM=M-1\n"
	"M=M%sD\n" ~ end;

	unary_template = start ~ "M=%sM\n" ~ end;

	comp_template = start ~ "D=M\n"
	"@SP\n"
	"AM=M-1\n"
	"D=M-D\n"
	"@COMP.%s.TRUE\n"
	"D;%s\n"
	"@COMP.%s.FALSE\n"
	"0;JMP\n"
	"(COMP.%s.TRUE)\n"
	"@SP\n"
	"A=M\n"
	"M=-1\n"
	"@SP\n"
	"M=M+1\n"
	"@COMP.%s.END\n"
	"0;JMP\n"
	"(COMP.%s.FALSE)\n"
	"@SP\n"
	"A=M\n"
	"M=0\n" ~ end ~ "(COMP.%s.END)\n";

	push_tail_template = "@SP\n"
	"A=M\n"
	"M=D\n"
	"@SP\n"
	"M=M+1\n";

	push_const_template = "@%s\nD=A\n" ~ push_tail_template;

	push_var_template = "@%s\n"
	"D=A\n"
	"@%s\n"
	"A=%s+D\n"
	"D=M\n" ~ push_tail_template;

	push_staticpointer_template = "@%s\nD=M\n" ~ push_tail_template;

	pop_template = "@%s\n"
	"D=A\n"
	"@%s\n"
	"D=%s+D\n"
	"@R13\n"
	"M=D\n"
	"@SP\n"
	"AM=M-1\n"
	"D=M\n"
	"@R13\n"
	"A=M\n"
	"M=D\n";

	pop_staticpointer_template = "@SP\n"
	"AM=M-1\n"
	"D=M\n"
	"@%s\n"
	"M=D\n";

	label_template = "(%s_%s)\n";
	goto_template = "@%s\n0;JMP\n";
	if_goto_template = "@SP\n"
	"AM=M-1\n"
	"D=M\n"
	"@%s_%s\n"
	"D;JNE\n";
}

void init() {
	op_count = 0;
	line_count = 0;
	build_strings();
	build_dictionaries();
}

string compile_operation(string op) {
	if (op.length == 0 || op[0..2] == "//")
		return "";
	string operation = op.split()[0];
	string header = "// '" ~ op ~  "' (line " ~ to!string(line_count) ~ ")\n";
	++line_count;

	if (type_dict[operation] == TYPE_ARITHMETIC)
		return header ~ compile_arithmetic(op);
	else
		return header ~ compile_memory(op);
}

string compile_arithmetic(string op) {
	if (canFind(comp_ops, op)) {
		string out_string = format(comp_template, op_count, operations_dict[op], op_count, 
			op_count, op_count, op_count, op_count);
		op_count += 1;
		return out_string;
	} else if (canFind(unary_ops, op))
		return format(unary_template, operations_dict[op]);
	else
		return format(binary_template, operations_dict[op]);
}

string compile_memory(string op) {
	string inst = op.split()[0];
	string argtype = op.split()[1];
	int val = to!int(op.split()[2]);
	if (inst == "push") {
		if (argtype == "constant") {
			return format(push_const_template, val);
		} else if (argtype == "static")
			return format(push_staticpointer_template, ("f." ~ to!string(val)));
		else if (argtype == "pointer")
			if (val == 0)
				return format(push_staticpointer_template, "THIS");
			else
				return format(push_staticpointer_template, "THAT");
		else
			return format(push_var_template, val, vars_dict[argtype][0], vars_dict[argtype][1]);
	} else {
		if (argtype != "constant") {
			if (argtype == "static")
				return format(pop_staticpointer_template, ("f." ~ to!string(val)));
			else if (argtype == "pointer") {
				if (val == 0)
					return format(pop_staticpointer_template, "THIS");
				else
					return format(pop_staticpointer_template, "THAT");
			}
			else
				return format(pop_template, val, vars_dict[argtype][0], vars_dict[argtype][1]);
		} else {
			return "";
		}
	}
}

string compile_label(string op) {
	return format(label_template, op[1..$-1], filename);
}

string compile_goto(string op) {
	string inst = op.split()[0];
	string dest = op.split()[1];
	if (inst == "goto")
		return format(goto_template, dest);
	else
		return format(if_goto_template, dest, filename);
}

void main(string args[]) {
	init();
	if (args.length < 2) {
		writefln("usage: %s <filename>", args[0]);
		return;
	}
	string inputfname = args[1];
	filename = args[1].split(".")[0];
	string outputfname = filename ~ ".asm";

	auto inputf = File(inputfname, "r");
	auto output = appender!string("// Assembly file generated by my awesome VM compiler\n");
	output.put(format("// Input filename: %s\n", inputfname));
	foreach (line; inputf.byLine) {
		output.put(compile_operation(to!string(line).strip));
	}
	inputf.close();

	auto outputf = File(outputfname, "w");
	outputf.write(output.data);

	outputf.write("(END)\n@END\n0;JMP");
	outputf.close();
	writeln("Compilation successful. Output written to " ~ outputfname);
}