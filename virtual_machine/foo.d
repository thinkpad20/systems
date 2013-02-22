import std.stdio, std.conv;

//string build_instruction(string assembly) {
//}

void main() 
{
	string foo = "0000000";
	char[] foo2 = foo.dup;
	foo2[2..4] = "ha";
	writeln("foo: ", foo2);
}