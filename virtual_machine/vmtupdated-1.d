import std.stdio, std.string, std.conv, std.array, std.algorithm;

enum Type { ARITHMETIC, MEMORY, LABEL, GOTO, FUNCTION, CALL, RETURN }
string[string] operations_dict;
Type[string] type_dict;
string[][string] vars_dict;
string[] arithmetic, memory, comp_ops, unary_ops, binary_ops;
string start, end, binary_template, unary_template,
		comp_template, push_tail_template, push_const_template,
		push_var_template, push_staticpointer_template,
		pop_template, pop_staticpointer_template, filename,
		label_template, goto_template, if_goto_template;
int op_count, line_count, return_address_count;

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

	type_dict = ["add":Type.ARITHMETIC, "sub":Type.ARITHMETIC, "and":Type.ARITHMETIC, 
				 "or":Type.ARITHMETIC, "not":Type.ARITHMETIC, "neg":Type.ARITHMETIC,
				   "lt":Type.ARITHMETIC, "gt":Type.ARITHMETIC, "eq":Type.ARITHMETIC, 
				   "leq":Type.ARITHMETIC, "geq":Type.ARITHMETIC, "label":Type.LABEL,
				   "goto":Type.GOTO, "if-goto":Type.GOTO, "push":Type.MEMORY, 
				   "pop":Type.MEMORY, "function":Type.FUNCTION, "call":Type.CALL,
				   "return":Type.RETURN];

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
	goto_template = "@%s_%s\n0;JMP\n";
	if_goto_template = "@SP\n"
	"AM=M-1\n"
	"D=M\n"
	"@%s_%s\n"
	"D;JNE\n";


}

void init() {
	op_count = 0;
	line_count = 0;
	return_address_count = 0;
	build_strings();
	build_dictionaries();
}

string compile_operation(string op) {
	if (op.length == 0 || op[0..2] == "//")
		return "";
	string operation = op.split()[0];
	string header = "// '" ~ op ~  "' (line " ~ to!string(line_count) ~ ")\n";
	++line_count;
	if (type_dict[operation] == Type.ARITHMETIC)
		return header ~ compile_arithmetic(op);
	else if (type_dict[operation] == Type.MEMORY)
		return header ~ compile_memory(op);
	else if (type_dict[operation] == Type.GOTO)
		return header ~ compile_goto(op);
	else if (type_dict[operation] == Type.LABEL)
		return header ~ compile_label(op);
	else if (type_dict[operation] == Type.FUNCTION)
		return header ~ compile_function(op);
	else if (type_dict[operation] == Type.CALL)
		return header ~ compile_call(op);
	else if (type_dict[operation] == Type.RETURN)
		return header ~ compile_return();
	else
		throw new Exception("Unrecognized instruction");
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
	writeln("Compiling label: ", op);
	string label = op.split()[1];
	return format(label_template, label, filename);
}

string compile_goto(string op) {
	string inst = op.split()[0];
	string dest = op.split()[1];
	if (inst == "goto")
		return format(goto_template, dest, filename);
	else
		return format(if_goto_template, dest, filename);
}

string compile_function(string op) {
	string function_name = op.split()[1];
	int num_local_vars = to!int(op.split()[2]);
	string output = format(label_template, function_name, filename);
	for (int i=0; i<num_local_vars; ++i)
		output ~= format(push_const_template, 0);
	return output;
}

string compile_call(string op) {
	string function_name = op.split()[1];
	int num_args = to!int(op.split()[2]);
	//make return address label
	string return_address = format("RET_ADDR_%s", return_address_count++);
	//push return address
	string output = format(push_const_template, return_address);
	//push ARG, LCL, THIS, THAT
	output ~= "@ARG\nD=M\n" ~ push_tail_template ~
			  "@LCL\nD=M\n" ~ push_tail_template ~
			  "@THIS\nD=M\n" ~ push_tail_template ~
			  "@THAT\nD=M\n" ~ push_tail_template;
	//ARG = SP - num_args - 5
	output ~= format("@SP\nD=M\n@%s\nD=D-A\n@5\nD=D-A\n@ARG\nM=D\n", num_args);
	//LCL = SP
	output ~= "@SP\nD=M\n@LCL\nM=D\n";
	// goto function
	output ~= format(goto_template, function_name, filename);
	// put in a label for after the function
	output ~= format(label_template, return_address, filename);
	return output;
}

string compile_return() {
	string output = "@LCL\nD=M\n@FRAME\nM=D\n"; // FRAME = LCL
	output ~= "@SP\nAM=M-1\nD=M\n@ARG\nA=M\nM=D\n"; // *(ARG) = pop()
	output ~= "@ARG\nD=M+1\n@SP\nM=D\n"; // SP = ARG + 1
	foreach (ptr; ["THAT", "THIS", "ARG", "LCL", "RET"]) //set environment pointers
		output ~= format ("@FRAME\nAM=M-1\nD=M\n@%s\nM=D\n", ptr);
	output ~= "@RET\nA=M\n0;JMP\n"; //goto ret
	return output;
}

void main(string args[]) {
	init();
	if (args.length < 2) {
		writefln("usage: %s <filename>", args[0]);
		return;
	}

	auto output = appender!string("// Assembly file generated by my awesome VM compiler\n");
	string outputfname;
	for (int i=1; i<args.length; ++i) {
		string inputfname = args[i];
		filename = args[i].split(".")[0];
		outputfname = filename ~ ".asm";

		auto inputf = File(inputfname, "r");
		output.put(format("// Input filename: %s\n", inputfname));
		foreach (line; inputf.byLine) {
			string input_line = to!string(line).split("//")[0].strip;
			output.put(compile_operation(input_line));
		}
		inputf.close();
	}

	auto outputf = File(outputfname, "w");
	outputf.write(output.data);

	outputf.write("(END)\n@END\n0;JMP");
	outputf.close();
	writeln("Compilation successful. Output written to " ~ outputfname);
}