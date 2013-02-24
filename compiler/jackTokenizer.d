module jackTokenizer;
import std.stdio, std.string, std.conv, std.algorithm;

enum TokenCat {
	KW, SYM, INTCONST, STRCONST, IDENT, WS, 
	NONE, PARTIALSTRING, COMMENT, PARTIALCOMMENT
}

struct Token {
	string symbol;
	TokenCat category;
	string type;
	int val;
	string str;
	static string[TokenCat] descriptions;
	this(string sym, TokenCat cat) { // Token struct initializer
		descriptions = [TokenCat.KW:"keyword", 
				TokenCat.IDENT:"identifier", TokenCat.SYM:"symbol", 
				TokenCat.INTCONST:"integerConstant", TokenCat.STRCONST:"stringConstant"];
		symbol = sym;
		category = cat;
		if (cat == TokenCat.INTCONST) {
			val = to!int(sym);
			type = "integerConstant";
		} else if (cat == TokenCat.STRCONST) {
			str = sym[1..$-1];
			type = "stringConstant";
		} else if (cat == TokenCat.IDENT) {
			type = "identifier";
		} else {
			type = symbol;
		}

	}

	string getXML() {
		if (category == TokenCat.STRCONST)
			return format("<%s> %s </%s>\n", descriptions[category], str, descriptions[category]);
		if (category == TokenCat.INTCONST)
			return format("<%s> %s </%s>\n", descriptions[category], val, descriptions[category]);
		if (symbol == "<")
			return format("<%s> &lt; </%s>\n", descriptions[category], descriptions[category]);
		if (symbol == ">")
			return format("<%s> &gt; </%s>\n", descriptions[category], descriptions[category]);
		if (symbol == "&")
			return format("<%s> &amp; </%s>\n", descriptions[category], descriptions[category]);
		return format("<%s> %s </%s>\n", descriptions[category], symbol, descriptions[category]);
	}

	string toString() {
		return symbol ~ " (" ~ type ~ "," ~ descriptions[category] ~ ")";
	}
}

struct jackTokenizer {
	int[string] keywords, symbols;
	int[char] identFirstChar, identOtherChars, numbers;
	int lineNumber, indentAmount;
	string preparedCode;
	Token[] tokens;

	bool matchIdent(string str) {
		if (!str) return false;
		if (!(str[0] in identFirstChar)) { return false; }
		for (int i=1; i<str.length; ++i)
			if (!(str[i] in identOtherChars)) { return false; }
		return true;
	}

	bool matchNum(string str) {
		if (!str) return false;
		for (int i=0; i<str.length; ++i)
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

	void lex() {
		lex(preparedCode);
	}

	void lex(string line) {
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

	void prepare(string filename) {
		string[] lines;
		string noComments;
		auto file = File(filename, "r");
		foreach (line; file.byLine)
			lines ~= to!string(line);
		foreach (line; lines) {
			string strippedLine = line.split("//")[0];
			noComments ~= strippedLine ~ "\n";
		}
		preparedCode = noComments;
	}

	void writeTokens(string filename) {
		auto file = File(filename, "w");
		file.writeln("<tokens>");
		foreach (token; tokens)
			file.write(token.getXML());
		file.writeln("</tokens>");
		file.close();
	}

	void lexAndWrite(string inputFilename, string outputFilename) {
		prepare(inputFilename);
		lex();
		writeTokens(outputFilename);
	}

	Token[] getTokens() {
		return tokens;
	}
}

//void main(string args[]) {
//	if (args.length < 3) {
//		writefln("usage: %s <jack input file)> <xml output file>", args[0]);
//		return;
//	}
//	jackTokenizer t;
//	t.init();
//	t.lexAndWrite(args[1], args[2]);
//}