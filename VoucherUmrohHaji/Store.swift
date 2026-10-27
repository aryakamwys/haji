import Foundation
import SwiftUI

@MainActor final class Store: ObservableObject {
    @Published private(set) var state: Snapshot
    @Published var errorMessage: String?
    private let key = "voucher.umroh.haji.demo.v1"
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) { state = decoded }
        else { state = Self.seed() }
    }
    var current: Member { state.members.first(where: { $0.id == state.currentID }) ?? state.members[0] }
    var isAdmin: Bool { current.role == "admin" }
    var activeVouchers: [Voucher] { state.vouchers.filter(\.isActive) }
    var userLedger: [Ledger] { state.ledgers.filter { $0.userID == current.id }.sorted { $0.createdAt > $1.createdAt } }
    var userOwned: [VoucherOwned] { state.owned.filter { $0.userID == current.id }.sorted { $0.createdAt > $1.createdAt } }
    var userWithdrawals: [Withdrawal] { state.withdrawals.filter { isAdmin || $0.userID == current.id }.sorted { $0.createdAt > $1.createdAt } }
    var userOrders: [Order] { state.orders.filter { $0.userID == current.id }.sorted { $0.createdAt > $1.createdAt } }
    var directDownlines: [Member] { state.members.filter { $0.parentID == current.id } }
    var pendingCount: Int { state.withdrawals.filter { $0.status == "pending" }.count }
    private func save() { if let data = try? JSONEncoder().encode(state) { UserDefaults.standard.set(data, forKey: key) }; objectWillChange.send() }
    func switchTo(_ id: String) { guard state.members.contains(where: { $0.id == id }) else { return }; state.currentID = id; save() }
    func resetDemo() { state = Self.seed(); save() }
    private func index(_ id: String) throws -> Int { guard let i = state.members.firstIndex(where: { $0.id == id }) else { throw AppIssue.invalid("Pengguna tidak ditemukan") }; return i }
    func register(name: String, email: String, referral: String) throws {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard n.count >= 3, e.contains("@"), e.contains(".") else { throw AppIssue.invalid("Isi nama dan alamat email yang valid") }
        guard !state.members.contains(where: { $0.email.lowercased() == e }) else { throw AppIssue.invalid("Email sudah digunakan") }
        let ref = referral.trimmingCharacters(in: .whitespacesAndNewlines)
        let upline = ref.isEmpty ? nil : state.members.first { $0.referralCode.caseInsensitiveCompare(ref) == .orderedSame && $0.role == "buyer" }
        if !ref.isEmpty && upline == nil { throw AppIssue.invalid("Kode referral tidak ditemukan") }
        let id = UUID().uuidString
        var code: String
        repeat { code = "VCH-" + String(UUID().uuidString.prefix(8)).uppercased() } while state.members.contains(where: { $0.referralCode == code })
        state.members.append(Member(id: id, name: n, email: e, role: "buyer", referralCode: code, parentID: upline?.id, balance: 0, downlines: 0))
        if let parent = upline { incrementAncestors(parent.id) }
        state.currentID = id; save()
    }
    private func incrementAncestors(_ start: String) {
        var cursor: String? = start
        var visited: Set<String> = []
        while let id = cursor, !visited.contains(id), let idx = state.members.firstIndex(where: { $0.id == id }) {
            visited.insert(id); state.members[idx].downlines += 1; cursor = state.members[idx].parentID
        }
    }
    func bindReferral(_ code: String) throws {
        let id = current.id
        guard !isAdmin, current.parentID == nil else { throw AppIssue.invalid("Akun sudah memiliki upline") }
        guard let parent = state.members.first(where: { $0.referralCode.caseInsensitiveCompare(code.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame && $0.role == "buyer" }) else { throw AppIssue.invalid("Kode referral tidak ditemukan") }
        guard parent.id != id else { throw AppIssue.invalid("Tidak dapat menggunakan kode sendiri") }
        var cursor: String? = parent.id; var visited: Set<String> = []
        while let value = cursor, !visited.contains(value) {
            if value == id { throw AppIssue.invalid("Referral akan membuat jaringan melingkar") }
            visited.insert(value); cursor = state.members.first(where: { $0.id == value })?.parentID
        }
        state.members[try index(id)].parentID = parent.id
        incrementAncestors(parent.id); save()
    }
    func createOrder(voucher: Voucher, referral: String = "") throws -> Order {
        guard !isAdmin, let live = state.vouchers.first(where: { $0.id == voucher.id && $0.isActive }) else { throw AppIssue.invalid("Voucher tidak tersedia") }
        if current.parentID == nil && !referral.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { try bindReferral(referral) }
        let order = Order(id: "ORD-" + UUID().uuidString.prefix(10), userID: current.id, voucherID: live.id, amount: live.price, value: live.value, status: "pending", createdAt: .now)
        state.orders.insert(order, at: 0); save(); return order
    }
    // DEMO ONLY: real transactions must be credited by verified, idempotent backend webhook.
    func simulateSettlement(_ orderID: String) throws {
        guard let index = state.orders.firstIndex(where: { $0.id == orderID }) else { throw AppIssue.invalid("Order tidak ditemukan") }
        guard state.orders[index].status == "pending" else { throw AppIssue.invalid("Order sudah diproses") }
        let order = state.orders[index]
        state.orders[index].status = "settlement"
        let buyerIndex = try self.index(order.userID)
        state.members[buyerIndex].balance += order.value
        let voucherTitle = state.vouchers.first(where: { $0.id == order.voucherID })?.title ?? "Voucher"
        state.owned.insert(VoucherOwned(id: UUID().uuidString, userID: order.userID, title: voucherTitle, value: order.value, orderID: orderID, createdAt: .now), at: 0)
        addLedger(user: order.userID, type: "topup", title: "Top-Up \(voucherTitle)", amount: order.value, order: orderID)
        var cursor = state.members[buyerIndex].parentID
        var visited: Set<String> = [order.userID]
        for rule in state.rules.sorted(by: { $0.level < $1.level }) {
            guard let id = cursor, !visited.contains(id), let parentIndex = state.members.firstIndex(where: { $0.id == id }) else { break }
            visited.insert(id)
            let steps = state.downlineStep > 0 ? state.members[parentIndex].downlines / state.downlineStep : 0
            let factor = 1.0 + Double(steps) * state.multiplier
            let payout = Int((Double(order.amount) * rule.percentage / 100 * factor).rounded())
            if payout > 0 {
                state.members[parentIndex].balance += payout
                addLedger(user: id, type: "mlm_cashback", title: "Cashback Level \(rule.level) ×\(String(format: "%.2f", factor)) dari \(state.members[buyerIndex].name)", amount: payout, order: orderID)
            }
            cursor = state.members[parentIndex].parentID
        }
        save()
    }
    func cancelOrder(_ orderID: String) throws {
        guard let i = state.orders.firstIndex(where: { $0.id == orderID && $0.status == "pending" }) else { throw AppIssue.invalid("Order tidak dapat dibatalkan") }
        state.orders[i].status = "cancel"; save()
    }
    private func addLedger(user: String, type: String, title: String, amount: Int, order: String) {
        state.ledgers.insert(Ledger(id: UUID().uuidString, userID: user, type: type, title: title, amount: amount, orderID: order, createdAt: .now), at: 0)
    }
    func requestWithdrawal(amount: Int, bank: String, account: String, holder: String) throws {
        let bank = bank.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = account.trimmingCharacters(in: .whitespacesAndNewlines)
        let holder = holder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isAdmin, amount > 0, amount <= current.balance else { throw AppIssue.invalid("Nominal tidak valid atau saldo tidak mencukupi") }
        guard !bank.isEmpty, account.count >= 5, !holder.isEmpty else { throw AppIssue.invalid("Lengkapi nama bank, rekening, dan pemilik rekening") }
        let id = "WD-" + UUID().uuidString.prefix(10)
        state.members[try index(current.id)].balance -= amount
        state.withdrawals.insert(Withdrawal(id: id, userID: current.id, amount: amount, bank: bank, account: account, holder: holder, status: "pending", createdAt: .now), at: 0)
        addLedger(user: current.id, type: "withdraw", title: "Hold withdraw ke \(bank)", amount: -amount, order: id)
        save()
    }
    func actOnWithdrawal(id: String, approve: Bool) throws {
        guard isAdmin else { throw AppIssue.invalid("Hanya admin yang berwenang") }
        guard let i = state.withdrawals.firstIndex(where: { $0.id == id && $0.status == "pending" }) else { throw AppIssue.invalid("Penarikan sudah diproses") }
        state.withdrawals[i].status = approve ? "approved" : "rejected"
        if !approve {
            let wd = state.withdrawals[i]
            state.members[try index(wd.userID)].balance += wd.amount
            addLedger(user: wd.userID, type: "refund", title: "Pengembalian withdraw \(id)", amount: wd.amount, order: id)
        }
        save()
    }
    func upsertVoucher(id: String? = nil, title: String, price: Int, value: Int, active: Bool = true) throws {
        guard isAdmin else { throw AppIssue.invalid("Akses ditolak") }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, price > 0, value > 0 else { throw AppIssue.invalid("Judul dan nominal voucher harus valid") }
        let voucher = Voucher(id: id ?? UUID().uuidString, title: title, price: price, value: value, isActive: active)
        if let i = state.vouchers.firstIndex(where: { $0.id == voucher.id }) { state.vouchers[i] = voucher } else { state.vouchers.append(voucher) }
        save()
    }
    func removeVoucher(_ id: String) throws {
        guard isAdmin else { throw AppIssue.invalid("Akses ditolak") }
        // Preserve historical voucher linkage in settled orders.
        guard !state.orders.contains(where: { $0.voucherID == id }) else { throw AppIssue.invalid("Voucher pernah ditransaksikan. Nonaktifkan, jangan hapus.") }
        state.vouchers.removeAll { $0.id == id }; save()
    }
    func configure(levels: [Double], step: Int, factor: Double) throws {
        guard isAdmin else { throw AppIssue.invalid("Akses ditolak") }
        guard !levels.isEmpty, levels.count <= 20, levels.allSatisfy({ $0 >= 0 && $0 <= 100 && $0.isFinite }), step > 0, factor >= 0, factor <= 100, factor.isFinite else { throw AppIssue.invalid("Konfigurasi komisi tidak valid") }
        state.rules = levels.enumerated().map { MLMRule(level: $0.offset + 1, percentage: $0.element) }
        state.downlineStep = step; state.multiplier = factor; save()
    }
    static func seed() -> Snapshot {
        let members = [
            Member(id: "admin", name: "Administrator", email: "admin@app.demo", role: "admin", referralCode: "ADMIN-HQ", parentID: nil, balance: 0, downlines: 0),
            Member(id: "budi", name: "Budi Santoso", email: "budi@app.demo", role: "buyer", referralCode: "VCH-BUDI01", parentID: nil, balance: 350000, downlines: 2),
            Member(id: "andi", name: "Andi Pratama", email: "andi@app.demo", role: "buyer", referralCode: "VCH-ANDI88", parentID: "budi", balance: 150000, downlines: 1),
            Member(id: "citra", name: "Citra Kirana", email: "citra@app.demo", role: "buyer", referralCode: "VCH-CITRA99", parentID: "andi", balance: 75000, downlines: 0)
        ]
        let vouchers = [Voucher(id: "v1", title: "Voucher Reguler 100K", price: 100000, value: 100000, isActive: true), Voucher(id: "v2", title: "Voucher Gold 500K", price: 500000, value: 525000, isActive: true), Voucher(id: "v3", title: "Voucher VIP 1 Juta", price: 1000000, value: 1100000, isActive: true)]
        return Snapshot(members: members, vouchers: vouchers, owned: [], ledgers: [], withdrawals: [], orders: [], rules: [MLMRule(level: 1, percentage: 5), MLMRule(level: 2, percentage: 3), MLMRule(level: 3, percentage: 1.5)], downlineStep: 2, multiplier: 0.5, currentID: "citra")
    }
}
