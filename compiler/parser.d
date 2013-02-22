import std.stdio, std.string, std.conv, std.regex;

enum TokenType {
	KW, SYM, INTCONST, STRCONST, IDENT, WS, NONE
}

struct TokenMatch {
	string symbol;
	TokenType token;
	this(string sym, TokenType t) {
		this.symbol = sym;
		this.token = t;
	}
	string toString() {
		return format("%s : %s", symbol, token);
	}
}

TokenMatch[] tokens;
int[string] keywords, symbols;

TokenType bestMatch(string token) {
	auto num_match = match(token, regex(r"-?[0-9]+"));
	auto ident_match = match(token, regex(r"[a-zA-Z_][a-zA-Z0-9_]*"));
	auto ws_match = match(token, regex(r"[ \n\r\t]+"));
	if (token in keywords)
		return TokenType.KW;
	else if (token in symbols)
		return TokenType.SYM;
	else if (num_match && num_match.hit == token)
		return TokenType.INTCONST;
	else if (token[0] == '"' && token[$-1] == '"')
		return TokenType.STRCONST;
	else if (ident_match && ident_match.hit == token)
		return TokenType.IDENT;
	else if (ws_match && ws_match.hit == token)
		return TokenType.WS;
	else
		return TokenType.NONE;
}

void parseLine(string line) {
	int cursor;
	writeln("Input: ", line);
	string current = "", prev = "";
	TokenType bestType = TokenType.NONE;
	for (cursor = 0; cursor < line.length; ++cursor) {
		char c = line[cursor];
		//writefln("current: '%s' c: %s, bestType: %s", current, c, bestType);
		current ~= c;
		if (bestMatch(current) == TokenType.NONE) {
			if (bestType != TokenType.WS)
				tokens ~= TokenMatch(prev, bestType);
			current = to!string(c);
			prev = "";
		}
		bestType = bestMatch(current);
		prev = current;
	}
	//have to do it on the very last character.
	bestType = bestMatch(current);
	if (bestType != TokenType.WS && bestType != TokenType.NONE)
		tokens ~= TokenMatch(prev, bestType);
}

void init() {
	string[] keywordList = ["class", "constructor", "function", "method", 
			 "field", "static", "var", "int", "char", "boolean",
			 "void", "true", "false", "null", "this", "let",
			 "do", "if", "else", "while", "return"];
	foreach (kw; keywordList) { keywords[kw] = 0; }

	string[] symbolList = ["{", "}", "(", ")", "[", "]", ".", ",", ";",
							"+", "-", "*", "/", "&", "|", "<", ">", "=", "~"];
	foreach (sym; symbolList) { symbols[sym] = 0; }
}

void main() {
	init();
	string test = "while (i < 5*j) {i = i+1;}";
	parseLine(test);
	foreach(TokenMatch m; tokens) {
		writeln(m);
	}
}