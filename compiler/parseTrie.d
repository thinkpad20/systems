module tokenTrie;

enum TokenType {
	KEYWORD, SYMBOL, INTEGERCONSTANT, STRINGCONSTANT, IDENTIFIER, ERROR;
}

class TokenTrie {
	char key = '\0';
	TokenType type = TokenType.ERROR;
	TokenTrie[char] subTries;
	this() {}
	this(char c) {
		this.key = c;
	}
	void addToken(string keys, TokenType t) {
		if (keys == "") {
			type = t;
			return;
		}
		if (!(keys[0] in subTries))
			subTries[keys[0]] = new TokenTrie(keys[0]);
		subTries[keys[0]].addToken(keys[1..$], t);
	}

	TokenTrie nextTrie(char key) {
		if (key in subTries)
			return subTries[key];
		return null;
	}

	TokenType getType() {
		return type;
	}

	bool lookup(string keys, TokenType *record) {
		if (keys == "") {
			record = type;
			return true;
		}

		if (keys[0] in subTries)
			return subTries[keys[0]].getTokenType(keys[1..$], record);

		return false;
	}
}