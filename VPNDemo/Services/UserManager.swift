import Foundation
import KeychainAccess

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case networkError
    case deviceLimitExceeded
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "用户名或密码错误"
        case .userNotFound: return "用户不存在"
        case .userAlreadyExists: return "用户已存在"
        case .networkError: return "网络错误"
        case .deviceLimitExceeded: return "设备注册次数已达上限，请明天再来"
        case .unknown: return "未知错误"
        }
    }
}

final class UserManager {
    static let shared = UserManager()
    
    private let keychain = Keychain(service: "com.vpndemo.app")
    private let userDefaults = UserDefaults.standard
    
    private let currentUserKey = "currentUser"
    private let isLoggedInKey = "isLoggedIn"
    
    var isLoggedIn: Bool {
        return userDefaults.bool(forKey: isLoggedInKey)
    }
    
    var currentUser: User? {
        get {
            guard let data = userDefaults.data(forKey: currentUserKey) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let user = newValue {
                let data = try? JSONEncoder().encode(user)
                userDefaults.set(data, forKey: currentUserKey)
            } else {
                userDefaults.removeObject(forKey: currentUserKey)
            }
        }
    }
    
    private init() {}
    
    func login(phone: String?, email: String?, password: String, completion: @escaping (Result<User, AuthError>) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            let identifier = phone ?? email ?? ""
            let storedPassword = self.keychain[identifier]
            
            if storedPassword == password {
                let user = User(
                    id: UUID().uuidString,
                    username: identifier,
                    email: email,
                    avatarURL: nil,
                    subscription: nil,
                    isLoggedIn: true,
                    phone: phone,
                    isTrial: true,
                    dataQuota: 500 * 1024 * 1024,
                    usedData: 0,
                    trialExpiryDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
                )
                self.currentUser = user
                self.userDefaults.set(true, forKey: self.isLoggedInKey)
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            } else if self.keychain[identifier] != nil {
                DispatchQueue.main.async {
                    completion(.failure(.invalidCredentials))
                }
            } else {
                let newUser = User(
                    id: UUID().uuidString,
                    username: identifier,
                    email: email,
                    avatarURL: nil,
                    subscription: nil,
                    isLoggedIn: true,
                    phone: phone,
                    isTrial: true,
                    dataQuota: 500 * 1024 * 1024,
                    usedData: 0,
                    trialExpiryDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
                )
                try? self.keychain.set(password, key: identifier)
                self.currentUser = newUser
                self.userDefaults.set(true, forKey: self.isLoggedInKey)
                DispatchQueue.main.async {
                    completion(.success(newUser))
                }
            }
        }
    }
    
    func register(phone: String?, email: String?, password: String, inviteCode: String?, completion: @escaping (Result<User, AuthError>) -> Void) {
        guard DeviceFingerprintService.shared.canRegister else {
            DispatchQueue.main.async {
                completion(.failure(.deviceLimitExceeded))
            }
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            let identifier = phone ?? email ?? ""
            
            if self.keychain[identifier] != nil {
                DispatchQueue.main.async {
                    completion(.failure(.userAlreadyExists))
                }
                return
            }
            
            var quota: Int64 = 500 * 1024 * 1024
            if let code = inviteCode, !code.isEmpty {
                quota += 200 * 1024 * 1024
            }
            
            let user = User(
                id: UUID().uuidString,
                username: identifier,
                email: email,
                avatarURL: nil,
                subscription: nil,
                isLoggedIn: true,
                phone: phone,
                isTrial: true,
                dataQuota: quota,
                usedData: 0,
                trialExpiryDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
            )
            
            try? self.keychain.set(password, key: identifier)
            self.currentUser = user
            self.userDefaults.set(true, forKey: self.isLoggedInKey)
            DeviceFingerprintService.shared.recordRegistration()
            
            DispatchQueue.main.async {
                completion(.success(user))
            }
        }
    }
    
    func startTrial(completion: @escaping (Result<User, AuthError>) -> Void) {
        // 「先体验一下」：无账号时直接创建游客体验用户，不再报「用户不存在」
        if var user = currentUser {
            user.isTrial = true
            user.isLoggedIn = true
            user.dataQuota = max(user.dataQuota, 500 * 1024 * 1024)
            user.trialExpiryDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
            currentUser = user
            userDefaults.set(true, forKey: isLoggedInKey)
            DispatchQueue.main.async {
                completion(.success(user))
            }
            return
        }

        let trialUser = User(
            id: "trial-\(UUID().uuidString.prefix(8))",
            username: "体验用户",
            email: nil,
            avatarURL: nil,
            subscription: nil,
            isLoggedIn: true,
            phone: nil,
            isTrial: true,
            dataQuota: 500 * 1024 * 1024,
            usedData: 0,
            trialExpiryDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        currentUser = trialUser
        userDefaults.set(true, forKey: isLoggedInKey)
        DispatchQueue.main.async {
            completion(.success(trialUser))
        }
    }
    
    func logout() {
        currentUser = nil
        userDefaults.set(false, forKey: isLoggedInKey)
    }
    
    func getRemainingData() -> Int64 {
        guard let user = currentUser else { return 0 }
        return max(0, user.dataQuota - user.usedData)
    }
    
    func isTrialExpired() -> Bool {
        guard let user = currentUser else { return true }
        return Date() > user.trialExpiryDate
    }
}
