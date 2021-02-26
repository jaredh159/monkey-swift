monkey:
	swiftc -o ./.bin/monkey token/Token.swift lexer/Lexer.swift utils/color.swift repl/repl.swift main.swift

tl:
	swiftc -o ./.bin/LexerTest token/Token.swift lexer/Lexer.swift lexer/LexerTest.swift utils/color.swift test/test.swift main.swift && ./.bin/LexerTest
