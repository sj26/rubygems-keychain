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
    fputs("  has-api-key [host] # test if an api key exists, exits 0 for yes, 1 for no\n", stderr)
    fputs("  get-api-key [host] # return an api key, prints key to stdout\n", stderr)
    fputs("  list-api-keys [host] # lists all api key hosts to stdout\n", stderr)
    fputs("  add-api-key [host] # sets a new api key from stdin\n", stderr)
    fputs("  rm-api-key [host] # removes an existing api key\n", stderr)
    fputs("", stderr)
    fputs("  import-key # import a signing key from stdin\n", stderr)
    fputs("  generate-key # generate a new signing key\n", stderr)
    fputs("  has-key # test if a signing key exists, exits 0 for yes, 1 for no\n", stderr)
    fputs("  get-cert # gets a currently valid signing certificate, (re)generating if neccessary\n", stderr)
    fputs("  sign # signs stdin using signing key to stdout\n", stderr)
    exit(-1)
}

let apiKeyService = "com.github.sj26.rubygems-keychain.api-key"
let keyTag = "com.github.sj26.rubygems-keychain.key"

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
        kSecAttrService as String: apiKeyService,
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
        kSecAttrService as String: apiKeyService,
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
        kSecAttrService as String: apiKeyService,
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
} else if command == "add-api-key" {
    let account: String
    if args.count == 0 {
        account = "rubygems"
    } else if args.count == 1 {
        account = args.removeFirst()
    } else {
        fputs("Usage: \(arg0) add-api-key [host]\n", stderr)
        fputs("Expects password on stdin\n", stderr)
        exit(-1)
    }

    let password: String? = readLine(strippingNewline: true)

    if password == nil {
        fputs("Usage: \(arg0) add-api-key [host]\n", stderr)
        fputs("Expects password on stdin\n", stderr)
        exit(-1)
    }

    let data: Data = password!.data(using: String.Encoding.utf8)!

    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrService as String: apiKeyService,
        kSecAttrAccount as String: account,
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
        kSecAttrService as String: apiKeyService,
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
} else if command == "has-key" {
    if args.count != 0 {
        fputs("Usage: \(arg0) has-key\n", stderr)
        exit(-1)
    }

    let query = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: keyTag,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
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
} else if command == "import-key" {
    if args.count != 0 {
        fputs("Usage: \(arg0) import-key\n", stderr)
        exit(-1)
    }

    let data: Data = FileHandle.standardInput.readDataToEndOfFile()
    var items: CFArray? = nil

    var keyFormat = SecExternalFormat.formatOpenSSL
    var keyType = SecExternalItemType.itemTypePrivateKey
    var params = SecItemImportExportKeyParameters()
    params.flags = SecKeyImportExportFlags.importOnlyOne
    var status = SecItemImport(
        data as CFData,
        nil,
        &keyFormat,
        &keyType,
        SecItemImportExportFlags.pemArmour,
        &params,
        nil,
        &items)

    if status != errSecSuccess {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }

    // If successful then we have a single key in an array
    let key: SecKey = (items! as! [Any]).first! as! SecKey

    // Now we store it
    let query = [
        kSecClass as String: kSecClassKey as String,
        kSecAttrApplicationTag as String: keyTag,
        kSecAttrLabel as String: "Rubygems signing key",
        kSecValueRef as String: key,
        //kSecAttrSynchronizable as String: true,
        //kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked as String,
        ] as [String : Any]

    status = SecItemAdd(query as CFDictionary, nil)

    if status != errSecSuccess {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }

    exit(0)
// } else if command == "export-key" {
//     if args.count != 0 {
//         fputs("Usage: \(arg0) export-key\n", stderr)
//         exit(-1)
//     }
// 
//     let query = [
//         kSecClass as String: kSecClassKey,
//         kSecAttrApplicationTag as String: keyTag,
//         kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//         kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
//         kSecReturnRef as String: true,
//         kSecMatchLimit as String: kSecMatchLimitOne,
//         ] as [String : Any]
// 
//     var dataTypeRef: AnyObject?
//     var status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
// 
//     if status != errSecSuccess {
//         fputs("Error: \(errorMessage(for: status))\n", stderr)
//         exit(-1)
//     }
// 
//     let key = dataTypeRef! as! SecKey
//     let unmanagedEmptyString = Unmanaged<CFString>.passRetained("" as CFString)
//     let unmanagedPasphrase = Unmanaged<AnyObject>.passRetained("" as AnyObject)
//     var params = SecItemImportExportKeyParameters(
//         version: UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION),
//         flags: .noAccessControl,
//         passphrase: unmanagedPasphrase,
//         alertTitle: unmanagedEmptyString,
//         alertPrompt: unmanagedEmptyString,
//         accessRef: nil,
//         keyUsage: nil,
//         keyAttributes: nil)
//     var data: CFData? = nil
// 
//     status = SecItemExport(key, .formatPKCS12, .pemArmour, &params, &data)
// 
//     if status != errSecSuccess {
//         fputs("Error: \(errorMessage(for: status))\n", stderr)
//         exit(-1)
//     }
// 
//     FileHandle.standardOutput.write(data! as Data)
// 
//     exit(0)
} else if command == "get-cert" {
} else if command == "sign" {
    if args.count != 0 {
        fputs("Usage: \(arg0) sign\n", stderr)
        exit(-1)
    }

    let query = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: keyTag,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        kSecReturnRef as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
        ] as [String : Any]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status != errSecSuccess {
        fputs("Error: \(errorMessage(for: status))\n", stderr)
        exit(-1)
    }

    let key = dataTypeRef! as! SecKey
    let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA1
    let data: Data = FileHandle.standardInput.readDataToEndOfFile()

    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(key, algorithm, data as CFData, &error) as Data? else {
        fputs("Error: \(error!.takeRetainedValue() as Error)\n", stderr)
        exit(-1)
    }

    FileHandle.standardOutput.write(signature)
    exit(0)
} else {
    fputs("Usage: \(arg0) COMMAND [args...]\n", stderr)
    exit(-1)
}
