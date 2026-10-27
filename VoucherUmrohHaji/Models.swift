import Foundation

struct Member: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
    var role: String
    var referralCode: String
    var parentID: String?
    var balance: Int
    var downlines: Int
}
struct Voucher: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var price: Int
    var value: Int
    var isActive: Bool
}
struct VoucherOwned: Identifiable, Codable {
    var id: String
    var userID: String
    var title: String
    var value: Int
    var orderID: String
    var createdAt: Date
}
struct Ledger: Identifiable, Codable {
    var id: String
    var userID: String
    var type: String
    var title: String
    var amount: Int
    var orderID: String
    var createdAt: Date
}
struct Withdrawal: Identifiable, Codable {
    var id: String
    var userID: String
    var amount: Int
    var bank: String
    var account: String
    var holder: String
    var status: String
    var createdAt: Date
}
struct Order: Identifiable, Codable {
    var id: String
    var userID: String
    var voucherID: String
    var amount: Int
    var value: Int
    var status: String
    var createdAt: Date
}
struct MLMRule: Identifiable, Codable {
    var level: Int
    var percentage: Double
    var id: Int { level }
}
struct Snapshot: Codable {
    var members: [Member]
    var vouchers: [Voucher]
    var owned: [VoucherOwned]
    var ledgers: [Ledger]
    var withdrawals: [Withdrawal]
    var orders: [Order]
    var rules: [MLMRule]
    var downlineStep: Int
    var multiplier: Double
    var currentID: String
}
extension Int {
    var rupiah: String { Self.currency.string(from: NSNumber(value: self)) ?? "Rp \(self)" }
    private static let currency: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .currency; f.locale = Locale(identifier: "id_ID"); f.maximumFractionDigits = 0; return f
    }()
}
extension Date {
    var shortID: String { formatted(date: .abbreviated, time: .shortened) }
}
enum AppIssue: LocalizedError {
    case invalid(String)
    var errorDescription: String? { switch self { case .invalid(let text): return text } }
}
