// Exercise the production login decoder with real engine Packet and String.
// Removing username normalization, changing inner characters, or trimming the
// password must break these cases before credentials reach lookup/AutoReg.
#include "server/login/packets/AccountVersionMessage.h"
#include <cstring>
#include <iostream>

struct LoginFields {
	String username;
	String password;
	String version;
};

static LoginFields decode(const String& username, const String& password) {
	Packet packet;
	packet.insertAscii(username);
	packet.insertAscii(password);
	packet.insertAscii("20050408-18:00");
	packet.reset();
	LoginFields result;
	AccountVersionMessage::parse(&packet, result.username, result.password, result.version);
	return result;
}

static bool sameBytes(const String& value, const String& expected) {
	return value.length() == expected.length() &&
		std::memcmp(value.toCharArray(), expected.toCharArray(), expected.length()) == 0;
}

int main() {
	struct UsernameCase { const char* label; const char* wire; const char* identity; };
	const UsernameCase cases[] = {
		{"ordinary username", "trav", "trav"},
		{"leading spaces use existing lookup key", "   trav", "trav"},
		{"trailing spaces use existing lookup key", "trav   ", "trav"},
		{"both edges use one lookup and AutoReg key", " trav ", "trav"},
		{"mixed edge whitespace", "\t\r\n\f trav \f\n\r\t", "trav"},
		{"new account identity", "  fresh-account  ", "fresh-account"},
		{"whitespace-only follows empty-name rejection", " \t\n\r\f ", ""},
		{"empty name remains empty", "", ""},
		{"case and internal spaces remain exact", " TrAv User ", "TrAv User"},
		{"internal tab remains exact", " tr\tav ", "tr\tav"},
		{"SQL metacharacters remain unescaped until account manager", "  tr'av\\name  ", "tr'av\\name"},
	};
	int failures = 0;
	for (const auto& test : cases) {
		auto result = decode(test.wire, " test password \t");
		if (!sameBytes(result.username, test.identity)) {
			std::cerr << "FAIL: " << test.label << '\n';
			++failures;
		}
		if (!sameBytes(result.password, " test password \t") || result.version != "20050408-18:00") {
			std::cerr << "FAIL: decoder changed password bytes or client version\n";
			++failures;
		}
	}
	const char passwordBytes[] = {' ', '\t', 'p', '\0', '\'', '\\', '\r', '\n', '\f', ' '};
	const String password(passwordBytes, sizeof(passwordBytes));
	if (!sameBytes(decode(" trav ", password).password, password)) {
		std::cerr << "FAIL: length-delimited password bytes changed\n";
		++failures;
	}
	if (failures != 0)
		return 1;
	std::cout << "Login decoder: 11 username cases and exact password bytes PASS\n";
}
