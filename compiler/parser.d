import std.stdio, std.string, std.conv, std.algorithm;

enum TokenCat {
	KW, SYM, INTCONST, STRCONST, IDENT, WS, NONE, PARTIALSTRING, COMMENT, PARTIALCOMMENT
}

enum TokenType { _class_, constructor_, _function_, _method_,
			 _field_, _static_, _var_, _int_, _char_, _boolean_,
			 _void_, _true_, _false_, _null_, _this_, _let_,
			 _do_, _if_, _else_, _while_, _return_
}

struct Token {
	string symbol;
	TokenCat category;
	TokenType type;
	int val;
	string str;
	string[TokenCat] descriptions;
	//constructor for keyword or identifier tokens
	this(string sym, TokenCat cat) {
		descriptions = [TokenCat.KW:"keyword", TokenCat.IDENT:"identifier",
						 TokenCat.SYM:"symbol", TokenCat.INTCONST:"integerConstant",
						 TokenCat.STRCONST:"stringConstant"];
		this.symbol = sym;
		this.category = cat;
		if (cat == TokenCat.INTCONST)
			this.val = to!int(sym);
		if (cat == TokenCat.STRCONST)
			this.str = sym[1..$-1];

	}

	string getXML() {
		if (category == TokenCat.STRCONST)
			return format("<%s> %s </%s>", descriptions[category], str, descriptions[category]);
		if (category == TokenCat.INTCONST)
			return format("<%s> %s </%s>", descriptions[category], val, descriptions[category]);
		if (symbol == "<")
			return format("<%s> &lt; </%s>", descriptions[category], descriptions[category]);
		if (symbol == ">")
			return format("<%s> &gt; </%s>", descriptions[category], descriptions[category]);
		if (symbol == "&")
			return format("<%s> &amp; </%s>", descriptions[category], descriptions[category]);
		return format("<%s> %s </%s>", descriptions[category], symbol, descriptions[category]);
	}

	string toString() {
		return symbol ~ " (" ~ descriptions[category] ~ ")";
	}
}

int[string] keywords, symbols;
int[char] identFirstChar, identOtherChars, numbers;
int lineNumber, indentAmount;

bool matchIdent(string str) {
	if (!str) return false;
	if (!(str[0] in identFirstChar)) { return false; }
	for (int i=1; i<str.length; ++i)
		if (!(str[i] in identOtherChars)) { return false; }
	return true;
}

bool matchNum(string str) {
	if (!str || str == "-") return false;
	if (!((str[0] in numbers) || str[0] == '-')) return false;
	for (int i=1; i<str.length; ++i)
		if (!(str[i] in numbers)) { return false; }
	return true;
}

bool matchWhiteSpace(string str) {
	foreach(ch; str)
		if (ch != ' ' && ch != '\n' && ch != '\r' && ch != '\t')
			return false;
	return true;
}


TokenCat bestMatch(string token) {
	if (token in keywords)
		return TokenCat.KW;
	else if (token in symbols)
		return TokenCat.SYM;
	else if (matchNum(token))
		return TokenCat.INTCONST;
	else if (token[0] == '"' && token[$-1] == '"')
		return TokenCat.STRCONST;
	else if (token[0] == '"' && !canFind(token[1..$-1], '"'))
		return TokenCat.PARTIALSTRING; // this will never be a terminal type
	else if (matchIdent(token))
		return TokenCat.IDENT;
	else if (token.length >= 4 && token[0..2] == "/*" && token[$-2..$] == "*/")
		return TokenCat.COMMENT;
	else if (token.length >= 2 && token[0..2] == "/*" && token.split("*/")[0] == token)
		return TokenCat.PARTIALCOMMENT;
	else if (matchWhiteSpace(token))
		return TokenCat.WS;
	else
		return TokenCat.NONE;
}

Token[] lexLine(string line) {
	Token[] tokens;
	int cursor; // keeps track of our position in the line
	writeln("Input:\n", line);
	string current = "", prev = "";
	TokenCat bestCat = TokenCat.NONE;
	for (cursor = 0; cursor < line.length; ++cursor) {
		char c = line[cursor];
		current ~= c; // append next character onto our working token
		if (bestMatch(current) == TokenCat.NONE) { // then we've encountered an illegal expression
			if (bestCat == TokenCat.NONE) { //bestCat stored the type of the previous expression
				throw new Exception(format("Error: illegal input on line %s", lineNumber)); // if none, this means
				// the previous statement was illegal, so there was some illegal input.
			}
			if (bestCat != TokenCat.WS && bestCat != TokenCat.COMMENT) // if it's not comment or ws, we record it
				tokens ~= Token(prev, bestCat);
			current = to!string(c);
			prev = "";
		}
		bestCat = bestMatch(current);
		prev = current;
	}
	//we now have to do it on the very last character.
	bestCat = bestMatch(current);
	if (bestCat != TokenCat.WS && bestCat != TokenCat.NONE)
		if (bestCat == TokenCat.PARTIALSTRING)
			throw new Exception("Error: unbounded string constant.");
		else if (bestCat == TokenCat.PARTIALCOMMENT)
			throw new Exception("Error: unbounded comment.");
		else
			tokens ~= Token(prev, bestCat);

	return tokens;
}

void init() {
	/* For lexing */
	string[] keywordList = ["class", "constructor", "function", "method", 
			 "field", "static", "var", "int", "char", "boolean",
			 "void", "true", "false", "null", "this", "let",
			 "do", "if", "else", "while", "return"];
	foreach (kw; keywordList) { keywords[kw] = 0; }

	string[] symbolList = ["{", "}", "(", ")", "[", "]", ".", ",", ";",
							"+", "-", "*", "/", "&", "|", "<", ">", "=", "~"];
	foreach (sym; symbolList) { symbols[sym] = 0; }

	string lowerCase = "abcdefghijklmnopqrstuvwxyz_";
	string upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	string digits = "0123456789";
	foreach (ch; lowerCase ~ upperCase)
		identFirstChar[ch] = 0;
	foreach (ch; lowerCase ~ upperCase ~ digits)
		identOtherChars[ch] = 0;
	foreach (ch; digits)
		numbers[ch] = 0;
}

string indent(string str) {
	string res = "";
	for (int i=0; i<indentAmount; ++i)
		res ~= "  ";
	return res ~ str;
}

string prepare(string filename) {
	string[] lines;
	string noComments;
	auto file = File(filename, "r");
	foreach (line; file.byLine)
		lines ~= to!string(line);
	foreach (line; lines) {
		string strippedLine = line.split("//")[0];
		noComments ~= strippedLine ~ "\n";
	}
	return noComments;
}

void writeTokens(Token[] tokens, string filename) {
	auto file = File(filename, "w");
	file.writeln("<tokens>");
	foreach (token; tokens)
		file.writeln(token.getXML());
	file.writeln("</tokens>");
	file.close();
}

void main(string args[]) {
	init();
	if (args.length == 1) {
		writefln("usage: %s <jack file(s)>", args[0]);
		return;
	}
	string preparedString = prepare(args[1]);
	Token[] tokens = lexLine(preparedString);
	//string test = "while (int i < 5*j) {string s = \"hello;\"}";
	//Token[] tokens = lexLine(test);
	writeTokens(tokens, args[2]);
}