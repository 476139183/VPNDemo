import Foundation

struct User: Codable {
    let id: String
    let username: String
    let email: String?
    var avatarURL: String?
    var subscription: Subscription?
    var isLoggedIn: Bool
    
    var phone: String?
    var isTrial: Bool
    var dataQuota: Int64
    var usedData: Int64
    var trialExpiryDate: Date

    struct Subscription: Codable {
        let plan: String
        let expirationDate: Date
        let dataLimit: Int64
        let dataUsed: Int64

        var dataLimitGB: Double {
            return Double(dataLimit) / 1_000_000_000
        }

        var dataUsedGB: Double {
            return Double(dataUsed) / 1_000_000_000
        }

        var remainingGB: Double {
            return dataLimitGB - dataUsedGB
        }

        var isExpired: Bool {
            return expirationDate < Date()
        }
    }

    static let guest = User(
        id: "guest",
        username: "游客",
        email: nil,
        avatarURL: nil,
        subscription: nil,
        isLoggedIn: false,
        phone: nil,
        isTrial: false,
        dataQuota: 0,
        usedData: 0,
        trialExpiryDate: Date()
    )
}
