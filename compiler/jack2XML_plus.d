import std.stdio, std.string, std.conv, std.algorithm, jackTokenizer, symbolTable;

int next, indentation;
Token[] tokens;
string[] outputLines;
string[] outputVM;
SymbolTableStack sts;
string className;

bool printPush = false;
bool printPop = false;
bool printAdd = false;
bool printStack = false;

string[string] opToVm, kwConstToVM, unOpToVM;

void init() {
	opToVm = ["+":"add", "-":"sub", "*":"call Math.multiply 2", 
			  "/":"call Math.divide 2", "&":"and", "|":"or", 
			  "<":"lt", ">":"gt", "=":"eq"];
	kwConstToVM = ["true":"constant 1\r\nneg", "false":"constant 0", "null":"constant 0", "this":"pointer 0"];
	unOpToVM = ["~":"not", "-":"neg"];
}

void report(string location = "") {
	if (next < tokens.length)
		writefln("%s next = %s,  tokens[next] = %s", location, next, tokens[next]);
	else
		writefln("%s next = %s,  end of file", location, next);
}

Token demand(string type) {
	Token ret = tokens[next++];
	if (type != ret.type)
		throw new Exception(format("Error: expected type %s", type));
	return ret;
}

Token demandOneOf(string[] types) {
	Token ret = tokens[next++];
	if (!canFind(types, ret.type))
		throw new Exception(format("Error: expected one of types %s", types));
	return ret;	
}

void buildStringConstant(string str) {
	outputVM ~= "push constant " ~ to!string(str.length);
	outputVM ~= "call String.new 1";
	foreach (c; str) {
		string ord = to!string(to!int(c));
		outputVM ~= format("push constant " ~ ord);
		outputVM ~= "call String.appendChar 2";
	}
}

/* <FORMATTING FUNCTIONS> */
string indent(string str) {
	string res;
	for (int i=0; i<indentation; ++i)
		res ~= "  ";
	return res ~ str;
}

void writeIndented(string str) {
	outputLines ~= indent(str);
	//write(indent(str));
}

Token writeXML(Token t) {
	writeIndented(t.getXML());
	return t;
}
/* </FORMATTING FUNCTIONS */

/* <CHECKING FUNCTIONS> */
bool isTerminal(Token t, string type) {
	return t.type == type;
}

bool isType(Token t) {
	return isTerminal(t, "int") || isTerminal(t, "char") || isTerminal(t, "boolean") || isTerminal(t, "identifier");
}

bool isKeywordConstant(Token t) {
	return t.type == "true" || t.type == "false" || t.type == "null" || t.type == "this";
}

bool isTerm(Token t) {
	return t.type == "integerConstant" || t.type == "stringConstant" || isKeywordConstant(t)
					|| t.type == "identifier" || t.type == "(" || isUnaryOp(t);
}

bool isUnaryOp(Token t) {
	return t.type == "~" || t.type == "-";
}

bool isOp(Token t) {
	string[] ops = ["+", "-", "*", "/", "&", "|", "<", ">", "="];
	return canFind(ops, t.type);
}

bool isStatement(Token t) {
	string[] statements = ["let", "if", "while", "do", "return"];
	return canFind(statements, t.type);
}

bool isClassVarDec(Token t) {
	return isTerminal(t, "field") || isTerminal(t, "static");
}

bool isSubroutineDec(Token t) {
	return isTerminal(t, "constructor") || isTerminal(t, "function") || isTerminal(t, "method");
}

/* </CHECKING FUNCTIONS> */

/* <EXPRESSION COMPILERS> */

void compileSubroutineCall() {
	/* We have two possibilities here; either a regular function or a class method. */
	if (isTerminal(tokens[next+1], ".")) {
		writeXML(demand("identifier"));
		writeXML(demand("."));
	}
	/* Both possibilities will need these 4 elements. 
	A class method needs the above two as well. */
	writeXML(demand("identifier"));
	writeXML(demand("("));
	compileExpressionList();
	writeXML(demand(")"));
}

void compileTerm() {
	writeIndented("<term>\r\n");
	++indentation;
	if (tokens[next].type == "integerConstant") {
		string num = writeXML(tokens[next++]).symbol; // get the numeric value of the constant
		outputVM ~= "push constant " ~ num;
	}
	else if (tokens[next].type == "stringConstant") {
		string str = writeXML(tokens[next++]).str; // get the internal string
		buildStringConstant(str);
	}
	else if (isKeywordConstant(tokens[next])) {
		string kwConst = writeXML(tokens[next++]).symbol;
		outputVM ~= "push " ~ kwConstToVM[kwConst];
	}
	else if (isUnaryOp(tokens[next])) {
		string unOp = writeXML(tokens[next++]).symbol;
		compileTerm();
		outputVM ~= unOpToVM[unOp];
	}
	else if (isTerminal(tokens[next], "(")) {
		writeXML(tokens[next++]);
		compileExpression();
		writeXML(demand(")"));
	}
	else if (isTerminal(tokens[next], "identifier")) {
		// Here we have three possibilities: array reference, a subroutine name, else a variable
		if (isTerminal(tokens[next+1], "[")) { // check if there's a [
			writeXML(tokens[next++]); // Write the variable
			writeXML(demand("[")); // grab the [ (the demand is unnecessary, but...)
			compileExpression(); // write the internal expression
			writeXML(demand("]")); // and demand a ]
		}
		else if (isTerminal(tokens[next+1], "(") || isTerminal(tokens[next+1], ".")) { // check for a subroutine call
			compileSubroutineCall();
		}
		else { // if it's neither one of those, it must be a variable
			string vm;
			SymbolTableEntry entry = sts.lookup(writeXML(tokens[next++]).symbol);
			if (entry) {
				vm = entry.vm;
				outputVM ~= "push " ~ vm;
			}
		}
	}
	else if (isTerminal(tokens[next], "identifier") && isTerminal(tokens[next], "("))
		compileSubroutineCall();
	else
		throw new Exception("Error: term expression had unparsable contents");
	--indentation;
	writeIndented("</term>\r\n");
}

void compileExpression() {
	writeIndented("<expression>\r\n");
	++indentation;
	string op;
	compileTerm();
	while (isOp(tokens[next])) {
		op = writeXML(tokens[next++]).symbol;
		compileTerm();
		outputVM ~= opToVm[op];
	}
	--indentation;
	writeIndented("</expression>\r\n");
}

void compileExpressionList() {
	writeIndented("<expressionList>\r\n");
	++indentation;
	while (isTerm(tokens[next])) {
		compileExpression();
		if (isTerminal(tokens[next], ","))
			writeXML(tokens[next++]);
		else
			break;
	}
	--indentation;
	writeIndented("</expressionList>\r\n");
}

void compileParameters() {
	// push the symbol table for this function; thi will be popped
	// at the END of the corresponding compileSubroutineBody
	sts.push(printPush);
	int numParams = 0;
	while (next < tokens.length && isType(tokens[next])) {
		string paramType = writeXML(tokens[next++]).symbol; // parameter type (int, char, etc)
		string paramName = writeXML(demand("identifier")).symbol; // parameter name
		sts.addSymbol(paramName, format("argument %d", numParams++), paramType);
		if (next < tokens.length && isTerminal(tokens[next], ","))
			writeXML(tokens[next++]);
		else
			break;
	}
}

void compileParameterList() {
	writeIndented("<parameterList>\r\n");
	++indentation;
	compileParameters();
	--indentation;
	writeIndented("</parameterList>\r\n");
}
/* </EXPRESSION COMPILERS> */

/* <STATEMENT COMPILERS> */
void compileStatements() {
	writeIndented("<statements>\r\n");
	++indentation;
	while (true) {
		if (isTerminal(tokens[next],"let"))
			compileLetStatement();
		else if (isTerminal(tokens[next], "if"))
			compileIfStatement();
		else if (isTerminal(tokens[next], "while"))
			compileWhileStatement();
		else if (isTerminal(tokens[next], "do"))
			compileDoStatement();
		else if (isTerminal(tokens[next], "return"))
			compileReturnStatement();
		else
			throw new Exception("Error: statement expected but no valid keyword found.");
		if (next == tokens.length || !isStatement(tokens[next]))
			break;
	}
	--indentation;
	writeIndented("</statements>\r\n");
}

void compileReturnStatement() {
	writeIndented("<returnStatement>\r\n");
	++indentation;
	writeXML(demand("return"));
	if (!isTerminal(tokens[next], ";"))
		compileExpression();
	writeXML(demand(";"));
	--indentation;
	writeIndented("</returnStatement>\r\n");
}

void compileDoStatement() {
	writeIndented("<doStatement>\r\n");
	++indentation;
	writeXML(demand("do"));
	compileSubroutineCall();
	writeXML(demand(";"));
	--indentation;
	writeIndented("</doStatement>\r\n");
}

void compileWhileStatement() {
	writeIndented("<whileStatement>\r\n");
	++indentation;
	writeXML(demand("while"));
	writeXML(demand("("));
	compileExpression();
	writeXML(demand(")"));
	writeXML(demand("{"));
	compileStatements();
	writeXML(demand("}"));
	--indentation;
	writeIndented("</whileStatement>\r\n");
}

void compileLetStatement() {
	writeIndented("<letStatement>\r\n");
	++indentation;
	writeXML(demand("let"));
	// write the XML for the variable and look it up in the symbol table
	SymbolTableEntry dest = sts.lookup(writeXML(demand("identifier")).symbol);
	// error check
	string destVM;
	if (dest)
		destVM = dest.vm;
	else
		throw new Exception ("Error: symbols not found");
	// the identifier might have array brackets following.
	if (isTerminal(tokens[next], "[")) {
		writeXML(demand("["));
		compileExpression();
		writeXML(demand("]"));
	}
	writeXML(demand("="));
	compileExpression();
	writeXML(demand(";"));
	outputVM ~= "pop " ~ destVM;
	--indentation;
	writeIndented("</letStatement>\r\n");
}

void compileIfStatement() {
	writeIndented("<ifStatement>\r\n");
	++indentation;
	writeXML(demand("if"));
	writeXML(demand("("));
	compileExpression();
	writeXML(demand(")"));
	writeXML(demand("{"));
	compileStatements();
	writeXML(demand("}"));
	if (isTerminal(tokens[next], "else")) {
		writeXML(demand("else"));
		writeXML(demand("{"));
		compileStatements();
		writeXML(demand("}"));
	}
	--indentation;
	writeIndented("</ifStatement>\r\n");
}
/* </STATEMENT COMPILERS> */

/* <HIGHEST-LEVEL STRUCTURES> */
void compileClass() {
	// new symbol table on the stack
	sts.push(printPush);
	writeIndented("<class>\r\n");
	++indentation;
	writeXML(demand("class"));
	className = writeXML(demand("identifier")).symbol; //set the class name
	writeXML(demand("{"));
	int fieldNum = 0, staticNum = 0;
	while (isClassVarDec(tokens[next]))
		compileClassVarDec(fieldNum, staticNum);

	// do a first pass over the subroutine names, don't recurse, just get the names.
	int save = next;
	while (isSubroutineDec(tokens[next]))
		compileSubroutineDec(true);
	// do a second pass; this time recurse but don't get the names
	next = save;
	while (isSubroutineDec(tokens[next]))
		compileSubroutineDec();
	if (printStack) {
		writeln("Table seen from class:");
		writeln(sts);
	}
	// pop the symbol table off the stack
	sts.pop(printPop);
	writeXML(demand("}"));
	--indentation;
	writeIndented("</class>\r\n");
}

void compileClassVarDec(ref int fieldNum, ref int staticNum) {
	writeIndented("<classVarDec>\r\n");
	++indentation;
	string classVarType = writeXML(demandOneOf(["field", "static"])).type;
	string type = writeXML(demandOneOf(["int", "char", "boolean", "identifier"])).symbol; // type
	string varName = writeXML(demand("identifier")).symbol;
	//create the entry in the symbol table
	if (classVarType == "field") {
		sts.addSymbol(varName, format("this %d", fieldNum++), type, printAdd);
	} else {
		sts.addSymbol(varName, format("%s.%d", className, staticNum++), type, printAdd);
	}
	while (isTerminal(tokens[next], ",")) {
		writeXML(demand(","));
		varName = writeXML(demand("identifier")).symbol;
		if (classVarType == "field") {
			sts.addSymbol(varName, format("this %d", fieldNum++), type, printAdd);
		} else {
			sts.addSymbol(varName, format("%s.%d", className, staticNum++), type, printAdd);
		}
	}
	writeXML(demand(";"));
	--indentation;
	writeIndented("</classVarDec>\r\n");
}

void compileSubroutineDec(bool namesOnly = false) {
	writeIndented("<subroutineDec>\r\n");
	++indentation;
	string funcType = writeXML(demandOneOf(["constructor", "function", "method"])).type;
	writeXML(demandOneOf(["void", "int", "char", "boolean", "identifier"])); // 'void' or type
	string funcName = writeXML(demand("identifier")).symbol; // subroutineName
	// If this is a "method", we need to count the implied parameter, so start at 1
	int numParams = (funcType == "method")? 1 : 0;
	writeXML(demand("("));
	if (namesOnly) { // then we just want the name and the number of parameters
		Token t;
		while (t = tokens[next++], t.type != ")")
			if (t.type == "identifier")
				++numParams;
		--next;
	} else {
		compileParameterList();
	}
	writeXML(demand(")"));
	if (namesOnly)
		sts.addSymbol(funcName, format("%s.%s %d", className, funcName, numParams), funcType, printAdd);
	else
		compileSubroutineBody();
	--indentation;
	writeIndented("</subroutineDec>\r\n");
}

void compileSubroutineBody() {
	writeIndented("<subroutineBody>\r\n");
	++indentation;
	writeXML(demand("{"));
	int numVars = 0;
	while (isTerminal(tokens[next], "var")) {
		compileVarDec(numVars);
	}
	compileStatements();
	writeXML(demand("}"));
	if (printStack) {
		writeln("Table seen from subroutineBody:");
		writeln(sts);
	}
	sts.pop(printPop);
	--indentation;
	writeIndented("</subroutineBody>\r\n");
}

void compileVarDec(ref int numVars) {
	writeIndented("<varDec>\r\n");
	++indentation;
	writeXML(demand("var"));
	string varType = writeXML(demandOneOf(["int", "char", "boolean", "identifier"])).symbol; // type
	string varName = writeXML(demand("identifier")).symbol; // varName
	sts.addSymbol(varName, format("local %d", numVars++), varType, printAdd);
	while (isTerminal(tokens[next], ",")) {
		writeXML(demand(","));
		varName = writeXML(demand("identifier")).symbol;
		sts.addSymbol(varName, format("local %d", numVars++), varType, printAdd);
	}
	writeXML(demand(";"));
	--indentation;
	writeIndented("</varDec>\r\n");
}
/* </HIGHEST-LEVEL STRUCTURES> */

void main(string[] args) {
	init();
	jackTokenizer jt;
	jt.init();
	for (int i=1; i<args.length; ++i) {
		string filenameRoot = args[i].split(".")[$-2];
		jt.prepareLexWrite(args[i], filenameRoot ~ "T.xml");
		tokens = jt.getTokens();
		outputLines = [];
		next = 0;
		compileClass();
		auto outputFile = File(filenameRoot ~ ".xml", "w");
		foreach(str; outputLines)
			outputFile.write(str);
		outputFile.close();
	}
	foreach(line; outputVM)
		writeln(line);
}