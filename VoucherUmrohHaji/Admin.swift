import SwiftUI

struct AdminVouchersView: View {
    @EnvironmentObject var store: Store
    @State private var editing: Voucher?
    @State private var adding = false
    var body: some View {
        List {
            Section {
                Button("Tambah Voucher", systemImage: "plus.circle.fill") { adding = true }
            }
            Section("Semua Voucher") {
                ForEach(store.state.vouchers) { voucher in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(voucher.title).font(.headline)
                            Spacer()
                            Text(voucher.isActive ? "Aktif" : "Nonaktif").font(.caption).foregroundStyle(voucher.isActive ? .green : .secondary)
                        }
                        LabeledContent("Harga", value: voucher.price.rupiah)
                        LabeledContent("Saldo", value: voucher.value.rupiah)
                        HStack {
                            Button("Edit") { editing = voucher }.buttonStyle(.bordered)
                            Button(voucher.isActive ? "Nonaktifkan" : "Aktifkan") {
                                do { try store.upsertVoucher(id: voucher.id, title: voucher.title, price: voucher.price, value: voucher.value, active: !voucher.isActive) } catch { store.errorMessage = error.localizedDescription }
                            }.buttonStyle(.bordered)
                            Button("Hapus", role: .destructive) { do { try store.removeVoucher(voucher.id) } catch { store.errorMessage = error.localizedDescription } }.buttonStyle(.bordered)
                        }
                    }.padding(.vertical, 6)
                }
            }
        }
        .sheet(isPresented: $adding) { VoucherEditor(voucher: nil) }
        .sheet(item: $editing) { voucher in VoucherEditor(voucher: voucher) }
    }
}
struct VoucherEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    let voucher: Voucher?
    @State private var title: String
    @State private var price: String
    @State private var value: String
    @State private var active: Bool
    init(voucher: Voucher?) {
        self.voucher = voucher
        _title = State(initialValue: voucher?.title ?? "")
        _price = State(initialValue: voucher.map { String($0.price) } ?? "")
        _value = State(initialValue: voucher.map { String($0.value) } ?? "")
        _active = State(initialValue: voucher?.isActive ?? true)
    }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nama paket", text: $title)
                TextField("Harga bayar", text: $price).keyboardType(.numberPad)
                TextField("Nilai saldo diterima", text: $value).keyboardType(.numberPad)
                Toggle("Aktif", isOn: $active)
                Button("Simpan Voucher") {
                    do { try store.upsertVoucher(id: voucher?.id, title: title, price: Int(price) ?? 0, value: Int(value) ?? 0, active: active); dismiss() }
                    catch { store.errorMessage = error.localizedDescription }
                }.buttonStyle(.borderedProminent)
            }
            .navigationTitle(voucher == nil ? "Voucher Baru" : "Edit Voucher")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Tutup") { dismiss() } } }
        }
    }
}
struct MLMSettingsView: View {
    @EnvironmentObject var store: Store
    @State private var percentages: [String] = []
    @State private var step = ""
    @State private var factor = ""
    var body: some View {
        Form {
            Section("Persentase Cashback per Level") {
                ForEach(percentages.indices, id: \.self) { index in
                    HStack {
                        Text("Level \(index + 1)")
                        Spacer()
                        TextField("%", text: $percentages[index]).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        Text("%")
                    }
                }
                HStack {
                    Button("Tambah Level") { if percentages.count < 20 { percentages.append("0") } }
                    Spacer()
                    Button("Hapus Level Terakhir", role: .destructive) { if percentages.count > 1 { percentages.removeLast() } }
                }.font(.subheadline)
            }
            Section("Bonus Multiplier") {
                TextField("Kelipatan jumlah downline", text: $step).keyboardType(.numberPad)
                TextField("Tambahan faktor per kelipatan", text: $factor).keyboardType(.decimalPad)
                Text("Contoh: 2 downline dengan faktor 0.5 menghasilkan pengali 1.5×.").font(.caption).foregroundStyle(.secondary)
            }
            Button("Simpan Konfigurasi") {
                let vals = percentages.compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
                do { try store.configure(levels: vals, step: Int(step) ?? 0, factor: Double(factor.replacingOccurrences(of: ",", with: ".")) ?? -1) }
                catch { store.errorMessage = error.localizedDescription }
            }.buttonStyle(.borderedProminent)
        }
        .onAppear { percentages = store.state.rules.map { String($0.percentage) }; step = String(store.state.downlineStep); factor = String(store.state.multiplier) }
    }
}
struct AdminWithdrawView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        List {
            Section("Menunggu Approval • \(store.pendingCount)") {
                let pending = store.state.withdrawals.filter { $0.status == "pending" }
                if pending.isEmpty { Text("Tidak ada withdraw pending").foregroundStyle(.secondary) }
                ForEach(pending) { wd in withdrawRow(wd, actions: true) }
            }
            Section("Riwayat Approval") {
                ForEach(store.state.withdrawals.filter { $0.status != "pending" }) { wd in withdrawRow(wd, actions: false) }
            }
            Section { Text("Pastikan dana telah ditransfer secara terpisah sebelum menyetujui. Tombol Approve tidak menjalankan transfer bank.").font(.caption).foregroundStyle(.secondary) }
        }
    }
    private func withdrawRow(_ wd: Withdrawal, actions: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.state.members.first(where: { $0.id == wd.userID })?.name ?? "Pengguna").bold()
            Text(wd.amount.rupiah).font(.title3.bold())
            Text("\(wd.bank) • \(wd.account) • \(wd.holder)").font(.subheadline)
            Text("\(wd.id) • \(wd.createdAt.shortID) • \(wd.status.capitalized)").font(.caption).foregroundStyle(.secondary)
            if actions {
                HStack {
                    Button("Tolak", role: .destructive) { do { try store.actOnWithdrawal(id: wd.id, approve: false) } catch { store.errorMessage = error.localizedDescription } }.buttonStyle(.bordered)
                    Button("Setujui (sudah transfer)") { do { try store.actOnWithdrawal(id: wd.id, approve: true) } catch { store.errorMessage = error.localizedDescription } }.buttonStyle(.borderedProminent)
                }
            }
        }.padding(.vertical, 6)
    }
}
struct AdminMembersView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        List {
            Section("Ringkasan") {
                LabeledContent("Total pengguna", value: "\(store.state.members.count)")
                LabeledContent("Buyer", value: "\(store.state.members.filter { $0.role == "buyer" }.count)")
                LabeledContent("Total Order", value: "\(store.state.orders.count)")
            }
            Section("Pengguna dan Jaringan") {
                ForEach(store.state.members) { user in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(user.name).bold(); Spacer(); Text(user.role.capitalized).font(.caption) }
                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                        LabeledContent("Saldo", value: user.balance.rupiah)
                        LabeledContent("Kode", value: user.referralCode)
                        LabeledContent("Downline", value: "\(user.downlines)")
                        if let parentID = user.parentID, let parent = store.state.members.first(where: { $0.id == parentID }) {
                            Text("Upline: \(parent.name)").font(.caption)
                        }
                    }.padding(.vertical, 5)
                }
            }
        }
    }
}
