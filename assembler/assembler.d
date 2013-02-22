import std.stdio, std.string;
import std.conv, std.array : appender;
import std.algorithm, std.math;

int line_count = 0, original_line_count = 0, next_address = 16;
int[string] symbol_table;
string[string] c_ops_dict, j_ops_dict;

enum LineType { COMMENT, INSTRUCTION, ADDRESS }

void init() {
    symbol_table = ["SP":0, "LCL":1, "ARG":2, "THIS":3, "THAT":4, 
                    "TEMP":5, "SCREEN":16384, "KBD":24576];
    for (int i=13; i<16; ++i)
        symbol_table[format("R%s",i)] = i;
    c_ops_dict = ["0":"101010", "1":"111111", "-1":"111010",
                  "D":"001100", "A":"110000", "M":"110000", "!D":"001101",
                  "!A":"110001", "!M":"110001", "-D":"001111", "-A":"110011",
                  "-M":"110011", "D+1":"011111", "A+1":"110111", "M+1":"110111",
                  "D-1":"001110", "A-1":"110010", "M-1":"110010", "D+A":"000010",
                  "D+M": "000010", "A+D": "000010", "M+D": "000010", "D-A":"010011",
                  "D-M":"010011", "A-D":"000111", "M-D":"000111", "D&A":"000000",
                  "D&M":"000000", "A&D":"000000", "M&D":"000000", "D|A":"010101",
                  "A|D":"010101", "D|M":"010101", "M|D":"010101"];
    j_ops_dict = ["JGT":"001", "JEQ":"010", "JGE":"011", "JLT":"100", "JNE":"101", 
                  "JLE":"110", "JMP":"111", "":"000"];
}

LineType filter_line(ref string s) {
    s = s.strip();
    if (canFind(s, "//")) s = s.split("//")[0];
    if (s == "") return LineType.COMMENT;
    if (s[0..2] == "//") return LineType.COMMENT;
    string toRemove = "\t\n\r ";
    foreach (c; toRemove)
        s = removechars(s, to!string(c));
    if (s[0] == '(' && s[$-1] == ')')
        return LineType.ADDRESS;
    else
        return LineType.INSTRUCTION;
}

string compile(string line) {
    if (line[0] == '@')
        return compile_a_instruction(line);
    else if (canFind(line, "="))
        return compile_c_instruction(line);
    else if (canFind(line, ";"))
        return compile_jump(line);
    else
        throw new Exception("Undefined instruction");
}

void compile_address(string line) {
    string symbol = line[1..$-1];
    if (!(symbol in symbol_table))
        symbol_table[symbol] = line_count;
    else
        throw new Exception("Attempting to add the same address twice.");
}

string to_binary(int n) {
    char[] inst = "0000000000000000\r\n".dup;
    for (int i=14; i>=0; --i) {
        if (pow(2, i) & n)
            inst[15-i] = '1';
    }
    return to!string(inst);
}

bool is_integer(string s) {
    foreach (c; s)
        if (std.string.indexOf("0123456789", c)<0)
            return false;
    return true;
}

string compile_a_instruction(string line) {
    string symbol = line[1..$];
    if (is_integer(symbol))
        return to_binary(to!int(symbol));
    else if (symbol in symbol_table)
        return to_binary(symbol_table[symbol]);
    else {
        symbol_table[symbol] = next_address;
        ++next_address;
        return to_binary(next_address-1);
    }
}

string compile_c_instruction(string line) {
    string dest = line.split("=")[0];
    string comp = line.split("=")[1];
    char[] dest_binary = "000".dup;
    string a_or_m = canFind(comp, 'M')? "1" : "0";
    if (canFind(dest, "A")) dest_binary[0] = '1';
    if (canFind(dest, "D")) dest_binary[1] = '1';
    if (canFind(dest, "M")) dest_binary[2] = '1';
    return format("111%s%s%s000\r\n", a_or_m, c_ops_dict[comp], dest_binary);
}
string compile_jump(string line) {
    try {
        string comp = line.split(";")[0];
        string jmp = line.split(";")[1];
        return format("1110%s000%s\r\n", c_ops_dict[comp], j_ops_dict[jmp]);
    } catch (core.exception.RangeError e) {
        writeln("Exception occurred tring to compile ", line);
        return "BADLINE: " ~ line;
    }
}

void main(string[] args) {
    if (args.length < 2) {
        writefln("usage: %s <assembly file>", args[0]);
        return;
    }
    init();
    auto inputf = File(args[1], "r");
    auto output_lines = appender!string();
    for (int i=0; i<2; ++i) { // this loop will go twice. The first 
                              // time through it will only find the addresses.
                              // the second time it will compile instructions.
        line_count = original_line_count = 0;
        foreach (ln; inputf.byLine) {
            string input_line = to!string(ln);
            LineType lt = filter_line(input_line);
            if (lt == LineType.INSTRUCTION) {
                if (i==1)
                    output_lines.put(compile(input_line));
                ++line_count;
            } else if (lt == LineType.ADDRESS)
                if (i==0) compile_address(input_line);
            ++original_line_count;
        }
        inputf.rewind();
    }
    inputf.close();
    
    string output_filename = args[1].split(".")[0] ~ ".hack";
    auto outputf = File(output_filename, "w");
    outputf.write(output_lines.data);

    outputf.close();
    writefln("Successfully compiled. Input was %s lines; output %s lines.", 
        original_line_count, line_count);
}