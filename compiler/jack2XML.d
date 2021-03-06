import std.stdio, std.string, std.algorithm, jackTokenizer;

int next, indentation;
Token[] tokens;
string[] outputLines;

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

void writeXML(Token t) {
	writeIndented(t.getXML());
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
		writeXML(tokens[next++]);
	}
	else if (tokens[next].type == "stringConstant") {
		writeXML(tokens[next++]);
	}
	else if (isKeywordConstant(tokens[next])) {
		writeXML(tokens[next++]);
	}
	else if (isUnaryOp(tokens[next])) {
		writeXML(tokens[next++]);
		compileTerm();
	}
	else if (isTerminal(tokens[next], "(")) {
		writeXML(tokens[next++]);
		compileExpression();
		writeXML(demand(")"));
	}
	else if (isTerminal(tokens[next], "identifier")) {
		/* Here we have three possibilities: array reference, a subroutine name, else a variable */
		if (isTerminal(tokens[next+1], "[")) { /* check if there's a [ */
			writeXML(tokens[next++]); /* Write the variable */
			writeXML(demand("[")); /* grab the [ (the demand is unnecessary, but...) */
			compileExpression(); /* write the internal expression */
			writeXML(demand("]")); /* and demand a ] */
		}
		else if (isTerminal(tokens[next+1], "(") || isTerminal(tokens[next+1], ".")) { /* check for a subroutine call */
			compileSubroutineCall();
		}
		else { /* if it's neither one of those, it must be a variable */
			writeXML(tokens[next++]);
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
	compileTerm();
	while (isOp(tokens[next])) {
		writeXML(tokens[next++]);
		compileTerm();
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
	while (next < tokens.length && isType(tokens[next])) {
		writeXML(tokens[next++]);
		writeXML(demand("identifier"));
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
	writeXML(demand("identifier"));
	/* the identifier might have array brackets following. */
	if (isTerminal(tokens[next], "[")) {
		writeXML(demand("["));
		compileExpression();
		writeXML(demand("]"));
	}
	writeXML(demand("="));
	compileExpression();
	writeXML(demand(";"));
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
	writeIndented("<class>\r\n");
	++indentation;
	writeXML(demand("class"));
	writeXML(demand("identifier"));
	writeXML(demand("{"));
	while (isClassVarDec(tokens[next]))
		compileClassVarDec();
	while (isSubroutineDec(tokens[next]))
		compileSubroutineDec();
	writeXML(demand("}"));
	--indentation;
	writeIndented("</class>\r\n");
}

void compileClassVarDec() {
	writeIndented("<classVarDec>\r\n");
	++indentation;
	writeXML(demandOneOf(["field", "static"]));
	writeXML(demandOneOf(["int", "char", "boolean", "identifier"])); /* type */
	writeXML(demand("identifier"));
	while (isTerminal(tokens[next], ",")) {
		writeXML(demand(","));
		writeXML(demand("identifier"));
	}
	writeXML(demand(";"));
	--indentation;
	writeIndented("</classVarDec>\r\n");
}

void compileSubroutineDec() {
	writeIndented("<subroutineDec>\r\n");
	++indentation;
	writeXML(demandOneOf(["constructor", "function", "method"]));
	writeXML(demandOneOf(["void", "int", "char", "boolean", "identifier"])); /* 'void' or type */
	writeXML(demand("identifier")); /* subroutineName */
	writeXML(demand("("));
	compileParameterList();
	writeXML(demand(")"));
	compileSubroutineBody();
	--indentation;
	writeIndented("</subroutineDec>\r\n");
}

void compileSubroutineBody() {
	writeIndented("<subroutineBody>\r\n");
	++indentation;
	writeXML(demand("{"));
	while (isTerminal(tokens[next], "var")) {
		compileVarDec();
	}
	compileStatements();
	writeXML(demand("}"));
	--indentation;
	writeIndented("</subroutineBody>\r\n");
}

void compileVarDec() {
	writeIndented("<varDec>\r\n");
	++indentation;
	writeXML(demand("var"));
	writeXML(demandOneOf(["int", "char", "boolean", "identifier"])); /* type */
	writeXML(demand("identifier")); /* varName */
	while (isTerminal(tokens[next], ",")) {
		writeXML(demand(","));
		writeXML(demand("identifier"));
	}
	writeXML(demand(";"));
	--indentation;
	writeIndented("</varDec>\r\n");
}
/* </HIGHEST-LEVEL STRUCTURES> */

void main(string[] args) {
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
}