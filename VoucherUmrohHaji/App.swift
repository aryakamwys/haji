import SwiftUI

@main struct VoucherUmrohHajiApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
                .tint(Color(red: 0.07, green: 0.48, blue: 0.42))
        }
    }
}
struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var showingAccounts = false
    @State private var showingRegister = false
    var body: some View {
        NavigationStack {
            Group { if store.isAdmin { AdminTabs() } else { BuyerTabs() } }
                .navigationTitle(store.isAdmin ? "Panel Admin" : "Voucher Umroh & Haji")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Text("Mode demo • \(store.current.name)")
                            ForEach(store.state.members) { member in
                                Button("\(member.role == "admin" ? "🛡️" : "👤") \(member.name)") { store.switchTo(member.id) }
                            }
                            Divider()
                            Button("Daftarkan buyer baru", systemImage: "person.crop.circle.badge.plus") { showingRegister = true }
                            Button("Reset semua data demo", systemImage: "arrow.counterclockwise", role: .destructive) { store.resetDemo() }
                        } label: { Image(systemName: "person.crop.circle") }
                    }
                }
                .sheet(isPresented: $showingRegister) { RegisterSheet() }
                .alert("Informasi", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                    Button("OK") { store.errorMessage = nil }
                } message: { Text(store.errorMessage ?? "") }
        }
    }
}
struct BuyerTabs: View {
    var body: some View {
        TabView {
            ShopView().tabItem { Label("Top-Up", systemImage: "bag") }
            WalletView().tabItem { Label("Dompet", systemImage: "wallet.bifold") }
            ReferralView().tabItem { Label("Referal", systemImage: "person.3.sequence") }
            WithdrawView().tabItem { Label("Withdraw", systemImage: "arrow.up.right.circle") }
        }
    }
}
struct AdminTabs: View {
    var body: some View {
        TabView {
            AdminVouchersView().tabItem { Label("Voucher", systemImage: "giftcard") }
            MLMSettingsView().tabItem { Label("Komisi", systemImage: "point.3.connected.trianglepath.dotted") }
            AdminWithdrawView().tabItem { Label("Approval", systemImage: "checkmark.shield") }
            AdminMembersView().tabItem { Label("Anggota", systemImage: "person.3") }
        }
    }
}
struct BalanceCard: View {
    var title: String
    var amount: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: "wallet.bifold.fill").font(.subheadline).opacity(0.85)
            Text(amount.rupiah).font(.system(size: 31, weight: .bold, design: .rounded)).minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(LinearGradient(colors: [Color(red: 0.04, green: 0.45, blue: 0.39), Color(red: 0.03, green: 0.29, blue: 0.32)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
    }
}
struct ShopView: View {
    @EnvironmentObject var store: Store
    @State private var selected: Voucher?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BalanceCard(title: "Saldo aktif", amount: store.current.balance)
                Label("MODE DEMO — bukan uang nyata", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                Text("Paket Voucher").font(.title2.bold())
                Text("Pilih voucher untuk membuat order dan menguji settlement simulasi.").font(.subheadline).foregroundStyle(.secondary)
                if store.activeVouchers.isEmpty { ContentUnavailableView("Belum ada voucher aktif", systemImage: "giftcard") }
                ForEach(store.activeVouchers) { voucher in
                    VStack(alignment: .leading, spacing: 11) {
                        Label(voucher.title, systemImage: "giftcard.fill").font(.headline)
                        HStack { Text("Harga bayar"); Spacer(); Text(voucher.price.rupiah).bold() }
                        HStack { Text("Saldo diterima"); Spacer(); Text(voucher.value.rupiah).foregroundStyle(.green).bold() }
                        Button("Beli Voucher") { selected = voucher }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity, alignment: .trailing)
                    }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                Text("Saldo dan cashback dikreditkan setelah Anda menekan Simulasikan Pembayaran Berhasil. Mode produksi membutuhkan konfirmasi pembayaran resmi dari server Midtrans.").font(.caption).foregroundStyle(.secondary)
            }.padding()
        }
        .sheet(item: $selected) { voucher in CheckoutSheet(voucher: voucher) }
    }
}
struct CheckoutSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    var voucher: Voucher
    @State private var referral = ""
    @State private var order: Order?
    var body: some View {
        NavigationStack {
            Form {
                Section("Detail Checkout") {
                    LabeledContent("Voucher", value: voucher.title)
                    LabeledContent("Tagihan", value: voucher.price.rupiah)
                    LabeledContent("Saldo diterima", value: voucher.value.rupiah)
                }
                if store.current.parentID == nil && order == nil {
                    Section("Kode referral (opsional)") { TextField("Kode referral upline", text: $referral).textInputAutocapitalization(.characters) }
                }
                if let order {
                    Section("Order Simulasi") {
                        LabeledContent("Nomor", value: order.id)
                        LabeledContent("Status", value: "Pending")
                        Button("Simulasikan Pembayaran Berhasil", systemImage: "checkmark.seal.fill") {
                            do { try store.simulateSettlement(order.id); dismiss() } catch { store.errorMessage = error.localizedDescription }
                        }.tint(.green)
                        Button("Batalkan Order", role: .destructive) {
                            do { try store.cancelOrder(order.id); dismiss() } catch { store.errorMessage = error.localizedDescription }
                        }
                    }
                } else {
                    Section {
                        Button("Buat Order Demo", systemImage: "creditcard") {
                            do { order = try store.createOrder(voucher: voucher, referral: referral) } catch { store.errorMessage = error.localizedDescription }
                        }
                    }
                }
                Section { Text("Tidak melakukan pembayaran sungguhan. Untuk Midtrans production, Snap token harus diterbitkan backend dan settlement diverifikasi oleh webhook server.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Checkout").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Tutup") { dismiss() } } }
        }
    }
}
struct WalletView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        List {
            Section { BalanceCard(title: "Dompet Saya", amount: store.current.balance) }
            Section("Inventory Voucher (\(store.userOwned.count))") {
                if store.userOwned.isEmpty { Text("Belum ada voucher").foregroundStyle(.secondary) }
                ForEach(store.userOwned) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text(item.title).bold(); Spacer(); Text("+\(item.value.rupiah)").foregroundStyle(.green) }
                        Text("\(item.orderID) • \(item.createdAt.shortID)").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                }
            }
            Section("Mutasi Saldo") {
                if store.userLedger.isEmpty { Text("Belum ada mutasi").foregroundStyle(.secondary) }
                ForEach(store.userLedger) { item in
                    HStack(alignment: .top) {
                        Image(systemName: item.amount >= 0 ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill").foregroundStyle(item.amount >= 0 ? .green : .red)
                        VStack(alignment: .leading, spacing: 4) { Text(item.title).font(.subheadline.bold()); Text(item.createdAt.shortID).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Text("\(item.amount > 0 ? "+" : "")\(item.amount.rupiah)").font(.subheadline.bold()).foregroundStyle(item.amount >= 0 ? .green : .red)
                    }
                }
            }
            Section("Pesanan") {
                ForEach(store.userOrders) { order in
                    HStack { Text(order.id).font(.caption); Spacer(); Text(order.status.capitalized).font(.caption.bold()) }
                }
            }
        }
    }
}
struct ReferralView: View {
    @EnvironmentObject var store: Store
    @State private var input = ""
    var body: some View {
        List {
            Section("Kode Referral Saya") {
                Text(store.current.referralCode).font(.title2.monospaced().bold()).textSelection(.enabled)
                ShareLink(item: "Gunakan kode referral saya: \(store.current.referralCode)") { Label("Bagikan Kode", systemImage: "square.and.arrow.up") }
            }
            Section("Jaringan") {
                LabeledContent("Total Downline", value: "\(store.current.downlines) anggota")
                LabeledContent("Downline Langsung", value: "\(store.directDownlines.count)")
                let steps = store.state.downlineStep > 0 ? store.current.downlines / store.state.downlineStep : 0
                LabeledContent("Pengali Cashback", value: String(format: "%.2fx", 1 + Double(steps) * store.state.multiplier))
                ForEach(store.directDownlines) { member in Label(member.name, systemImage: "person.circle") }
            }
            if store.current.parentID == nil {
                Section("Hubungkan Upline") {
                    TextField("Kode referral", text: $input).textInputAutocapitalization(.characters)
                    Button("Hubungkan Referral") { do { try store.bindReferral(input); input = "" } catch { store.errorMessage = error.localizedDescription } }
                }
            } else {
                Section { Label("Akun terhubung dengan upline", systemImage: "checkmark.seal.fill").foregroundStyle(.green) }
            }
            Section("Persentase MLM") {
                ForEach(store.state.rules) { rule in LabeledContent("Level \(rule.level)", value: String(format: "%.2f%%", rule.percentage)) }
                Text("Cashback = Harga Bayar × Persentase Level × (1 + ⌊Total Downline / Step⌋ × Faktor)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
struct WithdrawView: View {
    @EnvironmentObject var store: Store
    @State private var amount = ""
    @State private var bank = ""
    @State private var account = ""
    @State private var holder = ""
    var body: some View {
        Form {
            Section { BalanceCard(title: "Saldo Tersedia", amount: store.current.balance) }
            Section("Ajukan Withdraw") {
                TextField("Nominal (Rp)", text: $amount).keyboardType(.numberPad)
                TextField("Nama bank / e-wallet", text: $bank)
                TextField("Nomor rekening", text: $account).keyboardType(.numbersAndPunctuation)
                TextField("Nama pemilik rekening", text: $holder)
                Button("Ajukan Penarikan", systemImage: "arrow.up.right") {
                    do { try store.requestWithdrawal(amount: Int(amount) ?? 0, bank: bank, account: account, holder: holder); amount = ""; bank = ""; account = ""; holder = "" }
                    catch { store.errorMessage = error.localizedDescription }
                }.buttonStyle(.borderedProminent)
            }
            Section("Status Penarikan") {
                if store.userWithdrawals.isEmpty { Text("Belum ada permintaan penarikan").foregroundStyle(.secondary) }
                ForEach(store.userWithdrawals) { wd in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Text(wd.amount.rupiah).bold(); Spacer(); Text(wd.status.capitalized).foregroundStyle(wd.status == "approved" ? .green : wd.status == "rejected" ? .red : .orange) }
                        Text("\(wd.bank) • \(wd.account) • \(wd.createdAt.shortID)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section { Text("Permintaan menahan saldo hingga admin menyetujui atau menolak. Approval demo tidak memindahkan dana bank sungguhan.").font(.caption).foregroundStyle(.secondary) }
        }
    }
}
struct RegisterSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var referral = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Buyer Baru • Mode Demo") {
                    TextField("Nama lengkap", text: $name)
                    TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    TextField("Kode referral (opsional)", text: $referral)
                }
                Button("Daftar & Masuk") { do { try store.register(name: name, email: email, referral: referral); dismiss() } catch { store.errorMessage = error.localizedDescription } }.buttonStyle(.borderedProminent)
                Text("Pendaftaran demo tanpa password, OTP, atau verifikasi identitas. Akun produksi harus diautentikasi di backend.").font(.caption).foregroundStyle(.secondary)
            }.navigationTitle("Daftar Buyer").toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Tutup") { dismiss() } } }
        }
    }
}
