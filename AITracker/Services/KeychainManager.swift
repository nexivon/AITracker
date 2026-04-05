import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    // A domain/service name for Keychain items
    private let service = "com.AITracker.app"
    
    func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecAttrService as String : service,
            kSecValueData as String   : data
        ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecAttrService as String : service,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ] as [String : Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    func delete(key: String) {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecAttrService as String : service
        ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - String Helpers
    
    func saveString(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        _ = save(key: key, data: data)
    }
    
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
