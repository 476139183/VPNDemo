import Foundation
import KeychainAccess
import UIKit

final class DeviceFingerprintService {
    static let shared = DeviceFingerprintService()
    
    private let keychain = Keychain(service: "com.vpndemo.app")
    private let userDefaults = UserDefaults.standard
    
    private let deviceIdKey = "device_fingerprint_id"
    private let registerCountKey = "device_register_count"
    private let registerDateKey = "device_register_date"
    private let totalRegisterCountKey = "device_total_register_count"
    
    private let dailyMaxRegisters = 2
    private let lifetimeMaxRegisters = 10
    
    var deviceId: String {
        if let existingId = keychain[deviceIdKey] {
            return existingId
        }
        let newId = UUID().uuidString
        keychain[deviceIdKey] = newId
        return newId
    }
    
    var registerCount: Int {
        get { userDefaults.integer(forKey: registerCountKey) }
        set { userDefaults.set(newValue, forKey: registerCountKey) }
    }
    
    var totalRegisterCount: Int {
        get { userDefaults.integer(forKey: totalRegisterCountKey) }
        set { userDefaults.set(newValue, forKey: totalRegisterCountKey) }
    }
    
    var lastRegisterDate: Date? {
        get { userDefaults.object(forKey: registerDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: registerDateKey) }
    }
    
    var canRegister: Bool {
        guard totalRegisterCount < lifetimeMaxRegisters else { return false }
        
        if let lastDate = lastRegisterDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastDate) {
                return registerCount < dailyMaxRegisters
            } else {
                registerCount = 0
                return true
            }
        }
        return true
    }
    
    var remainingRegisters: Int {
        if totalRegisterCount >= lifetimeMaxRegisters { return 0 }
        
        if let lastDate = lastRegisterDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastDate) {
                return min(dailyMaxRegisters - registerCount, lifetimeMaxRegisters - totalRegisterCount)
            }
        }
        return min(dailyMaxRegisters, lifetimeMaxRegisters - totalRegisterCount)
    }
    
    func recordRegistration() {
        registerCount += 1
        totalRegisterCount += 1
        lastRegisterDate = Date()
    }
    
    func resetCount() {
        registerCount = 0
        totalRegisterCount = 0
        lastRegisterDate = nil
    }
    
    private init() {}
}
