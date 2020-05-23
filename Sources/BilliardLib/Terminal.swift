public func DarkGray(_ str: String) -> String {
	return "\u{001B}[30;1m\(str)\u{001B}[0m"
}

public func Red(_ str: String) -> String {
	return "\u{001B}[31m\(str)\u{001B}[0m"
}

public func Green(_ str: String) -> String {
	return "\u{001B}[32m\(str)\u{001B}[0m"
}

public func Magenta(_ str: String) -> String {
	return "\u{001B}[35m\(str)\u{001B}[0m"
}

public func Cyan(_ str: String) -> String {
	return "\u{001B}[36m\(str)\u{001B}[0m"
}

public func Yellow(_ str: String) -> String {
	return "\u{001B}[33m\(str)\u{001B}[0m"
}

public func BrightYellow(_ str: String) -> String {
	return "\u{001B}[33;1m\(str)\u{001B}[0m"
}

public func White(_ str: String) -> String {
	return "\u{001B}[37;1m\(str)\u{001B}[0m"
}

public func ClearCurrentLine() -> String {
	"\u{001B}[2K"
}
