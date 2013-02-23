import std.stdio, std.string, std.conv;

enum TokenType {
	KW, SYM, INTCONST, STRCONST, IDENT, WS, NONE
}

struct Token {
	string symbol;
	TokenType type;
	this(string sym, TokenType t) {
		this.symbol = sym;
		this.type = t;
	}
	string toString() {
		return format("%s : %s", symbol, type);
	}
}

Token[] tokens;
int[string] keywords, symbols;
int[char] identFirstChar, identOtherChars, numbers;
int lineNumber, indentAmount;
string[TokenType] tokenXMLTemplates;

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

TokenType bestMatch(string token) {
	if (token in keywords)
		return TokenType.KW;
	else if (token in symbols)
		return TokenType.SYM;
	else if (matchNum(token))
		return TokenType.INTCONST;
	else if (token[0] == '"' && token[$-1] == '"')
		return TokenType.STRCONST;
	else if (matchIdent(token))
		return TokenType.IDENT;
	else if (matchWhiteSpace(token))
		return TokenType.WS;
	else
		return TokenType.NONE;
}

int lexLine(string line) {
	int cursor; // keeps track of our position in the line
	writeln("Input: ", line);
	string current = "", prev = "";
	TokenType bestType = TokenType.NONE;
	for (cursor = 0; cursor < line.length; ++cursor) {
		char c = line[cursor];
		current ~= c; // append next character onto our working token
		if (bestMatch(current) == TokenType.NONE) { // then we've encountered an illegal expression
			if (bestType == TokenType.NONE) { //bestType stored the type of the previous expression
				writeln("Error: unknown token type on line %s", lineNumber); // if none, this means
				return lineNumber;	 // the previous statement was illegal, so there was some illegal input.
			}
			if (bestType != TokenType.WS) // if it's not whitespace, we record it
				tokens ~= Token(prev, bestType);
			current = to!string(c);
			prev = "";
		}
		bestType = bestMatch(current);
		prev = current;
	}
	//have to do it on the very last character.
	bestType = bestMatch(current);
	if (bestType != TokenType.WS && bestType != TokenType.NONE)
		tokens ~= Token(prev, bestType);

	return -1; // -1 indicates success
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

	/* For parsing */
	tokenXMLTemplates = [TokenType.KW:"<keyword> %s </keyword>",
						 TokenType.IDENT:"<identifier> %s </identifier>",
						 TokenType.SYM:"<symbol> %s </symbol>",
						 TokenType.INTCONST:"<integerConstant> %s </integerConstant>",
						 TokenType.STRCONST:"<stringConstant> %s </stringConstant>"];

}


string ind(string str) {
	string res = "";
	for (int i=0; i<indentAmount; ++i)
		res ~= "  ";
	return res ~ str;
}

string compileTerminal(Token token) {
	return ind(format(tokenXMLTemplates[token.type], token.symbol));
}

string compileLetStatement(Token[] tokens) {
	string res = ind("<letStatement>");
	++indent;
	res ~= compileTerminal(tokens[0]);
	/* At this point we need to figure out if the next symbol is an
	   regular variable or an array. */
	if (tokens[2] == "=")
		res ~= compileTerminal(tokens[1])

	--indent;
	res ~= ind("</letStatement>");
}




void main() {
	init();
	string test = "while (i < 5*j) {i = i+1;}";
	parseLine(test);
	foreach(Token m; tokens) {
		writeln(m);
	}
}