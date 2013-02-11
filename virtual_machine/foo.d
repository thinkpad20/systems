import std.c.stdio; 
import std.format; 

void main() 
{ 
	auto writer = appender!string(); 
	formattedWrite(writer, "%s is the ultimate %s.", 42, "answer"); 
	assert(writer.data == "42 is the ultimate answer."); // Clear the writer 
	writer = appender!string(); 
	formattedWrite(writer, "Date: %2$s %1$s", "October", 5); 
	assert(writer.data == "Date: 5 October"); 
}