import std.stdio, jackTokenizer;

int next = 0;
Token[] tokens;

bool term(string type) {
	return tokens[next++].type == type;
}

/* Attempt at a recursive descent parser for Jack. This is super complicated! :\ */

bool isVarDec() {
	return term("var") && isType() && isVarNames() && term(";");
}

bool isVarDecs1() {
	return isVarDec();
}

bool isVarDecs2() {
	return isVarDec() && isVarDecs();
}

bool isVarDecs() {
	int save = next;
	return (next = save, isVarDecs1(),
			|| next = save, isVarDecs2());
}

bool isSubroutineBody1() {
	return term("{") && isVarDecs() && isStatements() && term("}");
}

bool isSubroutineBody2() {
	return term("{") && isStatements() && term("}");
}

bool isSubroutineBody() {
	int save = next;
	return (next = save, isSubroutineBody1()
			|| next = save, isSubroutineBody2());
}

bool isParameterList1() {
	return 
}

bool isParameterList() {
	int save = next;
	return (next = save, isParameterList1()
			|| next = save, isParameterList2());
}

bool isSubroutineName() {
	return term("identifier");
}

bool isSubroutineDec1() {
	return term("constructor") && term("void") && isSubroutineName() 
			&& term("(") && isParameterList() && term(")") && isSubroutineBody();
}

bool isSubroutineDec2() {
	return term("function") && term("void") && isSubroutineName() 
			&& term("(") && isParameterList() && term(")") && isSubroutineBody();
}

bool isSubroutineDec3() {
	return term("method") && term("void") && isSubroutineName() 
			&& term("(") && isParameterList() && term(")") && isSubroutineBody();
}

bool isSubroutineDec4() {
	return term("constructor") && isType() && isSubroutineName() 
			&& term("(") && isParameterList() && term(")") && isSubroutineBody();
}

bool isSubroutineDec5() {
	return term("function") && isType() && isSubroutineName() 
			&& term("(") && isParameterList() && term(")") && isSubroutineBody();
}

bool isSubroutineDec6() {
	return term("method") && isType() && isSubroutineName() 
			&& term("(") && isParameterList() && term(")") && isSubroutineBody();
}

bool isSubroutineDec() {
	int save = next;
	return (next = save, isSubroutineDec1()
			|| next = save, isSubroutineDec2()
			|| next = save, isSubroutineDec3()
			|| next = save, isSubroutineDec4()
			|| next = save, isSubroutineDec5()
			|| next = save, isSubroutineDec6();
}

bool isVarName() {
	return term("identifier");
}

bool isVarNames1() {
	return term("identifier");
}

bool isVarNames2() {
	return term("identifier" && isVarNames());
}

bool isVarNames() {
	int save = next;
	return (next = save, isVarNames1()
			|| next = save, isVarNames2());
}

bool isType() {
	int save = next;
	return (next = save, term("int") 
			|| next = save, term("char")
			|| next = save, term("boolean")
			|| next = save, isClassName());
}

bool isClassVarDec1() {
	return term("static") && isType() && isVarnames() && term(";");
}

bool isClassVarDec2() {
	return term("field") && isType() && isVarnames() && term(";");
}

bool isClassVarDec() {
	int save = next;
	return (next = save, isClassVarDec1()
			|| next = save, isClassVarDec2());
}

bool isClassName() {
	int save = next;
	return term("identifier");
}

bool isClass1() {
	return term("class") && isClassName() && term("{") && isClassVarDec() && isSubroutineDec() && term("}");
}

bool isClass2() {
	return term("class") && isClassName() && term("{") && isClassVarDec() && term("}");
}

bool isClass3() {
	return term("class") && isClassName() && term("{") && isSubroutineDec() && term("}");
}

bool isClass4() {
	return term("class") && isClassName() && term("{") && term("}");
}

bool isClass() {
	int save = next;
	return (next = save, isClass1()
			|| next = save, isClass2()
			|| next = save, isClass3()
			|| next = save, isClass4());
}