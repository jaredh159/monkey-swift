tl:
	swiftc -o ./.bin/LexerTest token/Token.swift lexer/Lexer.swift lexer/LexerTest.swift utils/color.swift test/test.swift main.swift && ./.bin/LexerTest
