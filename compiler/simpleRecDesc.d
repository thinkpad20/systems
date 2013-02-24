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

/* <FORMATTING FUNCTIONS> */
string indent(string str) {
	string res;
	for (int i=0; i<indentation; ++i)
		res ~= "  ";
	return res ~ str;
}

void writeIndented(string str) {
	outputLines ~= indent(str);
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

bool isUnaryOp(Token t) {
	return t.type == "~" || t.type == "-";
}

bool isOp(Token t) {
	string[] ops = ["+", "-", "*", "/", "&", "|", "<", ">", "="];
	return canFind(ops, t.type);
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

void compileExpressionList() {
	while (true) {
		compileExpression();
		if (term(tokens[next], ","))
			writeXML(tokens[next++]);
		else
			break;
	}
}

void compileSubroutineCall() {
	writeIndented("<subroutineCall>\n");
	++indentation;
	/* We have two possibilities here; either a regular function or a class method. */
	if (term(tokens[next+1], ".")) {
		writeXML(demand("identifier"));
		writeXML(demand("."));
	}
	/* Both possibilities will need these 4 elements. 
	A class method needs the above two as well. */
	writeXML(demand("identifier"));
	writeXML(demand("("));
	compileExpressionList();
	writeXML(demand(")"));
	--indentation;
	writeIndented("</subroutineCall>\n");
}

void compileTerm() {
	writeIndented("<term>\n");
	++indentation;
	writeln("next = ", next, " tokens[next].type = ", tokens[next].type);
	if (tokens[next].type == "integerConstant")
		writeXML(tokens[next++]);
	else if (tokens[next].type == "stringConstant")
		writeXML(tokens[next++]);
	else if (isKeywordConstant(tokens[next]))
		writeXML(tokens[next++]);
	else if (isUnaryOp(tokens[next])) {
		writeXML(tokens[next++]);
		compileTerm();
	}
	else if (term(tokens[next], "(")) {
		writeXML(tokens[next++]);
		compileExpression();
		writeXML(demand(")"));
	}
	else if (term(tokens[next], "identifier")) {
		/* Here we have three possibilities: a variable, array reference, or subroutine name */
		/* First check for array reference */
		if (term(tokens[next+1], "[")) { /* check if there's a [ */
			writeXML(tokens[next++]); /* Write the variable */
			writeXML(demand("[")); /* grab the [ (the demand is unnecessary, but...) */
			compileExpression(); /* write the internal expression */
			writeXML(demand("]")); /* and demand a ] */
		}
		/* Next check for a subroutine call */
		else if (term(tokens[next+1], "(")) {
			compileSubroutineCall();
		}
		/* if it's neither one of those, it must be a variable */
		else {
			writeXML(tokens[next++]);
		}
	}
	else if (term(tokens[next], "identifier") && term(tokens[next], "(")) {
		compileSubroutineCall();
	}
	else {
		throw new Exception("Error: term expression had unparsable contents");
	}

	--indentation;
	writeIndented("</term>\n");
}

void compileExpression() {
	writeIndented("<expression>\n");
	++indentation;
	compileTerm();
	while (isOp(tokens[next])) {
		writeXML(tokens[next++]);
		compileTerm();
	}
	--indentation;
	writeIndented("</expression>\n");
}

void compileLetStatement() {
	writeIndented("<letStatement>\n");
	++indentation;
	writeXML(demand("let"));
	writeXML(demand("identifier"));
	/* the identifier might have array brackets following. */
	if (term(tokens[next], "[")) {
		writeXML(demand("["));
		compileExpression();
		writeXML(demand("]"));
	}
	writeXML(demand("="));
	compileExpression();
	writeXML(demand(";"));
	--indentation;
	writeIndented("</letStatement>\n");
}

/* <TESTED COMPILATION FUNCTIONS> */
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

/* </TESTED COMPILATION FUNCTIONS> */

void main(string[] args) {
	jackTokenizer jt;
	jt.init();
	jt.lex("let x[y + 2*z] = Class.function(5, 6);");
	tokens = jt.getTokens();
	//init();
	next = 0;
	compileLetStatement();
	foreach(str; outputLines)
		write(str);
}