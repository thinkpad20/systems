import std.stdio, std.string, std.algorithm, jackTokenizer;

int next, indentation;
Token[] tokens;
string[] outputLines;

void init() {
	tokens = [Token("let", TokenCat.KW), 
				Token("x", TokenCat.IDENT), 
				Token("=", TokenCat.SYM), 
				Token("3", TokenCat.INTCONST),
				Token("+", TokenCat.SYM),
				Token("y", TokenCat.IDENT),
				Token(";", TokenCat.SYM),];
}

void report(string location = "") {
	if (next < tokens.length)
		writefln("%s next = %s,  tokens[next] = %s", location, next, tokens[next]);
	else
		writefln("%s next = %s,  end of file", location, next);
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
	write(indent(str));
}

void writeXML(Token t) {
	writeIndented(t.getXML());
}
/* </FORMATTING FUNCTIONS */

/* <CHECKING FUNCTIONS> */
bool term(Token t, string type) {
	return t.type == type;
}

bool isType(Token t) {
	return term(t, "int") || term(t, "char") || term(t, "boolean") || term(t, "identifier");
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
	return term(t, "field") || term(t, "static");
}

bool isSubroutineDec(Token t) {
	return term(t, "constructor") || term(t, "function") || term(t, "method");
}

/* </CHECKING FUNCTIONS> */

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

void compileSubroutineCall() {
	report("SRC0");
	//writeIndented("<subroutineCall>\n");
	//++indentation;
	/* We have two possibilities here; either a regular function or a class method. */
	if (term(tokens[next+1], ".")) {
		report("SRC1");
		writeXML(demand("identifier"));
		writeXML(demand("."));
	}
	/* Both possibilities will need these 4 elements. 
	A class method needs the above two as well. */
	report("SRC2");
	writeXML(demand("identifier"));
	writeXML(demand("("));
	compileExpressionList();
	writeXML(demand(")"));
	//--indentation;
	//writeIndented("</subroutineCall>\n");
}

void compileTerm() {
	writeIndented("<term>\n");
	++indentation;
	report("TERM0");
	if (tokens[next].type == "integerConstant") {
		report("TERM1");
		writeXML(tokens[next++]);
	}
	else if (tokens[next].type == "stringConstant") {
		report("TERM2");
		writeXML(tokens[next++]);
	}
	else if (isKeywordConstant(tokens[next])) {
		report("TERM3");
		writeXML(tokens[next++]);
	}
	else if (isUnaryOp(tokens[next])) {
		report("TERM4");
		writeXML(tokens[next++]);
		compileTerm();
	}
	else if (term(tokens[next], "(")) {
		report("TERM5");
		writeXML(tokens[next++]);
		compileExpression();
		writeXML(demand(")"));
	}
	else if (term(tokens[next], "identifier")) {
		report("TERM6");
		writeln("lookahead: tokens[next+1] = ", tokens[next+1]);
		/* Here we have three possibilities: a variable, array reference, or subroutine name */
		/* First check for array reference */
		if (term(tokens[next+1], "[")) { /* check if there's a [ */
			report("TERM7");
			writeXML(tokens[next++]); /* Write the variable */
			writeXML(demand("[")); /* grab the [ (the demand is unnecessary, but...) */
			compileExpression(); /* write the internal expression */
			writeXML(demand("]")); /* and demand a ] */
		}
		/* Next check for a subroutine call */
		else if (term(tokens[next+1], "(") || term(tokens[next+1], ".")) {
			report("TERM8");
			compileSubroutineCall();
		}
		/* if it's neither one of those, it must be a variable */
		else {
			report("TERM9");
			writeXML(tokens[next++]);
		}
	}
	else if (term(tokens[next], "identifier") && term(tokens[next], "(")) {
		report("TERM10");
		compileSubroutineCall();
	}
	else {
		throw new Exception("Error: term expression had unparsable contents");
	}

	--indentation;
	writeIndented("</term>\n");
}

void compileExpression() {
	report("EXP0");
	writeIndented("<expression>\n");
	++indentation;
	compileTerm();
	while (isOp(tokens[next])) {
		report("EXP1");
		writeXML(tokens[next++]);
		compileTerm();
	}
	--indentation;
	writeIndented("</expression>\n");
}

void compileExpressionList() {
	writeIndented("<expressionList>\n");
	++indentation;
	while (isTerm(tokens[next])) {
		compileExpression();
		if (term(tokens[next], ","))
			writeXML(tokens[next++]);
		else
			break;
	}
	--indentation;
	writeIndented("</expressionList>\n");
}

/* <EXPRESSION COMPILERS> */
void compileParameters() {
	while (next < tokens.length && isType(tokens[next])) {
		writeXML(tokens[next++]);
		writeXML(demand("identifier"));
		if (next < tokens.length && term(tokens[next], ","))
			writeXML(tokens[next++]);
		else
			break;
	}
}

void compileParameterList() {
	writeIndented("<parameterList>\n");
	++indentation;
	compileParameters();
	--indentation;
	writeIndented("</parameterList>\n");
}

/* </EXPRESSION COMPILERS> */

/* <STATEMENT COMPILERS> */

void compileStatements() {
	report("BEGINSTATEMENTS");
	writeIndented("<statements>\n");
	++indentation;
	while (true) {
		if (term(tokens[next],"let"))
			compileLetStatement();
		else if (term(tokens[next], "if"))
			compileIfStatement();
		else if (term(tokens[next], "while"))
			compileWhileStatement();
		else if (term(tokens[next], "do"))
			compileDoStatement();
		else if (term(tokens[next], "return"))
			compileReturnStatement();
		else
			throw new Exception("Error: statement expected but no valid keyword found.");
		report("STATEMENTS1");
		if (next == tokens.length || !isStatement(tokens[next]))
			break;
	}
	--indentation;
	writeIndented("</statements>\n");
	report("ENDSTATEMENTS");
}

void compileReturnStatement() {
	report("BEGINRETURN");
	writeIndented("<returnStatement>\n");
	++indentation;
	writeXML(demand("return"));
	if (!term(tokens[next], ";"))
		compileExpression();
	writeXML(demand(";"));
	--indentation;
	writeIndented("</returnStatement>\n");
	report("ENDRETURN");
}

void compileDoStatement() {
	report("BEGINDO");
	writeIndented("<doStatement>\n");
	++indentation;
	writeXML(demand("do"));
	compileSubroutineCall();
	writeXML(demand(";"));
	--indentation;
	writeIndented("</doStatement>\n");
	report("ENDDO");
}

void compileWhileStatement() {
	report("BEGINWHILE");
	writeIndented("<whileStatement>\n");
	++indentation;
	writeXML(demand("while"));
	writeXML(demand("("));
	compileExpression();
	writeXML(demand(")"));
	writeXML(demand("{"));
	compileStatements();
	writeXML(demand("}"));
	--indentation;
	writeIndented("</whileStatement>\n");
	report("ENDWHILE");
}

void compileLetStatement() {
	report("BEGINLET");
	writeIndented("<letStatement>\n");
	++indentation;
	report("LET1");
	writeXML(demand("let"));
	report("LET2");
	writeXML(demand("identifier"));
	/* the identifier might have array brackets following. */
	if (term(tokens[next], "[")) {
		report("LET3");
		writeXML(demand("["));
		compileExpression();
		report("LET4");
		writeXML(demand("]"));
	}
	writeXML(demand("="));
	compileExpression();
	report("LET5");
	writeXML(demand(";"));
	--indentation;
	writeIndented("</letStatement>\n");
	report("ENDLET");
}

void compileIfStatement() {
	report("BEGINIF");
	writeIndented("<ifStatement>\n");
	++indentation;
	writeXML(demand("if"));
	writeXML(demand("("));
	compileExpression();
	writeXML(demand(")"));
	writeXML(demand("{"));
	compileStatements();
	writeXML(demand("}"));
	if (term(tokens[next], "else")) {
		writeXML(demand("else"));
		writeXML(demand("{"));
		compileStatements();
		writeXML(demand("}"));
	}
	--indentation;
	writeIndented("</ifStatement>\n");
	report("ENDIF");
}

/* </STATEMENT COMPILERS> */

/* <HIGHEST-LEVEL STRUCTURES> */

void compileClass() {
	writeIndented("<class>\n");
	++indentation;
	writeXML(demand("class"));
	writeXML(demand("identifier"));
	writeXML(demand("{"));
	if (isClassVarDec(tokens[next]))
		compileClassVarDec();
	if (isSubroutineDec(tokens[next]))
		compileSubroutineDec();
	writeXML(demand("}"));
	--indentation;
	writeIndented("</class>\n");
}

void compileClassVarDec() {
	writeIndented("<classVarDec>\n");
	++indentation;
	while (isClassVarDec(tokens[next])) {
		writeXML(demandOneOf(["field", "static"]));
		writeXML(demandOneOf(["int", "char", "boolean", "identifier"])); /* type */
		writeXML(demand("identifier"));
		while (term(tokens[next], ",")) {
			writeXML(demand(","));
			writeXML(demand("identifier"));
		}
		writeXML(demand(";"));
	}
	--indentation;
	writeIndented("</classVarDec>\n");
}

void compileSubroutineDec() {
	writeIndented("<subroutineDec>\n");
	++indentation;
	while (next < tokens.length && isSubroutineDec(tokens[next])) {
		writeXML(demandOneOf(["constructor", "function", "method"]));
		writeXML(demandOneOf(["void", "int", "char", "boolean", "identifier"])); /* 'void' or type */
		writeXML(demand("identifier")); /* subroutineName */
		writeXML(demand("("));
		compileParameterList();
		writeXML(demand(")"));
		compileSubroutineBody();
	}
	--indentation;
	writeIndented("</subroutineDec>\n");
}

void compileSubroutineBody() {
	writeIndented("<subroutineBody>\n");
	++indentation;
	writeXML(demand("{"));
	while (term(tokens[next], "var")) {
		compileVarDec();
	}
	compileStatements();
	writeXML(demand("}"));
	--indentation;
	writeIndented("</subroutineBody>\n");
}

void compileVarDec() {
	writeIndented("<varDec>\n");
	++indentation;
	writeXML(demand("var"));
	writeXML(demandOneOf(["int", "char", "boolean", "identifier"])); /* type */
	writeXML(demand("identifier")); /* varName */
	while (term(tokens[next], ",")) {
		writeXML(demand(","));
		writeXML(demand("identifier"));
	}
	writeXML(demand(";"));
	--indentation;
	writeIndented("</varDec>\n");
}

/* </HIGHEST-LEVEL STRUCTURES> */


void main(string[] args) {
	jackTokenizer jt;
	jt.init();
	jt.prepareLexWrite(args[1], args[2]);
	tokens = jt.getTokens();
	foreach (i, token; tokens)
		writeln(i, " ", token);
	//init();
	next = 0;
	compileClass();
	auto outputFile = File(args[3], "w");
	foreach(str; outputLines) {
		outputFile.write(str);
		write(str);
	}
}