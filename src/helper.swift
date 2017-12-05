import Foundation
import Security

func errorMessage(for status: OSStatus) -> String {
    if let message = SecCopyErrorMessageString(status, nil) {
        return message as String
    } else {
        return "Unknown error: \(status)"
    }
}

var args = CommandLine.arguments as [String]
var arg0 = (args.removeFirst() as NSString).lastPathComponent as String
if args.isEmpty {
    fputs("Usage: \(arg0) COMMAND [args...]\n", stderr)
    fputs("\n", stderr)
    fputs("Commands:\n", stderr)
    fputs("  has-api-key [host] # test if an api key exists, exits 0 for yes, 2 for no\n", stderr)
    fputs("  get-api-key [host] # return an api key, prints key to stdout\n", stderr)
    fputs("  list-api-keys [host] # lists all api key hosts to stdout\n", stderr)
    fputs("  set-api-key [host] # sets an api key, expects key on stdin\n", stderr)
    fputs("  rm-api-key [host] # removes an existing api key\n", stderr)
    exit(-1)
}

var command = args.removeFirst()
if command == "has-api-key" {
    let account: String
    if args.count == 0 {
        account = "rubygems"
    } else if args.count == 1 {
        account = args.removeFirst()
    } else {
        fputs("Usage: \(arg0) has-api-key [host]\n", stderr)
        exit(-1)
    }

    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: "com.github.sj26.rubygems-keychain.api-key",
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        kSecReturnAttributes as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
        ] as [String : Any]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess {
        exit(0)
    } else if status == errSecItemNotFound {
        exit(1)
    } else {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }
} else if command == "get-api-key" {
    let account: String
    if args.count == 0 {
        account = "rubygems"
    } else if args.count == 1 {
        account = args.removeFirst()
    } else {
        fputs("Usage: \(arg0) get-api-key [host]\n", stderr)
        exit(-1)
    }

    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: "com.github.sj26.rubygems-keychain.api-key",
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
        ] as [String : Any]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess {
        let data = dataTypeRef! as! Data

        print(String(data: data, encoding: String.Encoding.utf8)!)
        exit(0)
    } else {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }
} else if command == "list-api-keys" {
    if !args.isEmpty {
        fputs("Usage: \(arg0) list-api-keys\n", stderr)
        exit(-1)
    }

    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: "com.github.sj26.rubygems-keychain.api-key",
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        kSecReturnAttributes as String: true,
        kSecMatchLimit as String: kSecMatchLimitAll as String,
        ] as [String : Any]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess {
        let data = dataTypeRef! as! [Dictionary<String, Any>]
        for item in data {
            print(item[kSecAttrAccount as String] as! String)
        }
        exit(0)
    } else if status == errSecItemNotFound {
        // Successful, but empty
        exit(0)
    } else {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }
} else if command == "set-api-key" {
    let account: String
    let label: String
    if args.count == 0 {
        account = "rubygems"
        label = "Rubygems api key"
    } else if args.count == 1 {
        account = args.removeFirst()
        label = "Rubygems api key (\(account))"
    } else {
        fputs("Usage: \(arg0) set-api-key [host]\nExpects password on stdin\n", stderr)
        exit(-1)
    }

    let password: String? = readLine(strippingNewline: true)

    if password == nil {
        fputs("Usage: \(arg0) set-api-key [host]\n", stderr)
        fputs("Expects password on stdin\n", stderr)
        exit(-1)
    }

    let data: Data = password!.data(using: String.Encoding.utf8)!

    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: "com.github.sj26.rubygems-keychain.api-key",
        kSecAttrAccount as String: account,
        kSecAttrLabel as String: label,
        kSecValueData as String: data,
        kSecAttrSynchronizable as String: true,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked as String,
        ] as [String : Any]

    let status = SecItemAdd(query as CFDictionary, nil)

    if status == errSecSuccess {
        exit(0)
    } else {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }
} else if command == "rm-api-key" {
    let account: String
    if args.count == 0 {
        account = "rubygems"
    } else if args.count == 1 {
        account = args.removeFirst()
    } else {
        fputs("Usage: \(arg0) rm-api-key [host]\n", stderr)
        exit(-1)
    }

    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: "com.github.sj26.rubygems-keychain.api-key",
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ] as [String : Any]

    let status = SecItemDelete(query as CFDictionary)

    if status == errSecSuccess {
        exit(0)
    } else {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }
} else {
    fputs("Usage: \(arg0) COMMAND [args...]\n", stderr)
    exit(-1)
}
