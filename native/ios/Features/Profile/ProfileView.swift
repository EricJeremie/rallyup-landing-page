import RallyUpCore
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: RallyStore
    @EnvironmentObject private var accountSession: AccountSessionStore
    @State private var showingResetConfirmation = false
    @State private var showingEditProfile = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                profileHeader
                if let strengths = store.currentUser.strengths, !strengths.isEmpty {
                    PlayerStrengthsView(strengths: strengths)
                }
                if !store.currentUser.racketSetup.isEmpty {
                    RacketSetupGallery(rackets: store.currentUser.racketSetup, title: "Racket setup")
                }
                recordCard
                formCard
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Recent results")
                    if store.history.isEmpty {
                        EmptyStateView(title: "No recorded matches", message: "Your confirmed match results will build your profile over time.", symbol: "chart.bar")
                    } else {
                        ForEach(store.history.prefix(3)) { match in
                            ProfileResultRow(match: match)
                        }
                    }
                }
                accountCard
            }
            .padding(.horizontal, RallyTheme.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset demo data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset local demo data", role: .destructive) { store.resetDemoData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This restores the sample matches and invite on this device. No account or server data is affected.")
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet()
                .environmentObject(store)
        }
        .alert("Couldn’t delete account", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "Try again in a moment.")
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            PlayerAvatarView(player: store.currentUser, size: 76)
            VStack(alignment: .leading, spacing: 5) {
                Text(store.currentUser.displayName)
                    .font(.title3.weight(.bold))
                Text("\(store.currentUser.skillLevel.title) player · \(store.currentUser.homeArea ?? "Home area not shared")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(store.currentUser.availabilitySummary, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
                Button {
                    showingEditProfile = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.subheadline)
                        .frame(width: 42, height: 42)
                        .background(RallyTheme.card, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit profile")
        }
        .padding(.vertical, 4)
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(title: "Your record")
            HStack(spacing: 0) {
                RecordMetric(value: "\(store.wins)", title: "Wins")
                Divider().frame(height: 46)
                RecordMetric(value: "\(store.losses)", title: "Losses")
                Divider().frame(height: 46)
                RecordMetric(value: "\(store.winRate)%", title: "Win rate")
                Divider().frame(height: 46)
                RecordMetric(value: "\(store.currentWinStreak)", title: "Win streak")
            }
        }
        .rallyCard()
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Season so far")
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(monthlyCounts.enumerated()), id: \.offset) { index, bucket in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(index == monthlyCounts.count - 1 ? RallyTheme.tennis : RallyTheme.darkGreen.opacity(0.8))
                            .frame(height: max(10, CGFloat(bucket.count) / CGFloat(max(maxMonthlyCount, 1)) * 82))
                        Text(bucket.label).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130, alignment: .bottom)
            Text("A simple local preview. Trends will be calculated from confirmed matches when the account is connected.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .rallyCard()
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Account")
            Label(
                accountSession.currentAccount?.email ?? "Demo profile · data saved on this device",
                systemImage: accountSession.currentAccount == nil ? "iphone" : "person.crop.circle.badge.checkmark"
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                accountSession.signOut()
            } label: {
                Label(accountSession.currentAccount == nil ? "Exit demo session" : "Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            Button(role: .destructive) { showingResetConfirmation = true } label: {
                Label("Reset demo data", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            if accountSession.currentAccount != nil {
                Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                    Label(isDeletingAccount ? "Deleting account…" : "Delete account", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .disabled(isDeletingAccount)
                .confirmationDialog(
                    "Delete your RallyUp account?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete account", role: .destructive) { deleteAccount() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This permanently removes your account, profile, matches, and photos.")
                }
            }
        }
        .rallyCard()
    }

    private var monthlyCounts: [(label: String, count: Int)] {
        let calendar = Calendar.current
        return (0..<6).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let count = store.history.filter { calendar.isDate($0.scheduledAt, equalTo: month, toGranularity: .month) }.count
            return (month.formatted(.dateTime.month(.abbreviated)), count)
        }
    }

    private var maxMonthlyCount: Int { monthlyCounts.map { $0.count }.max() ?? 0 }

    private func deleteAccount() {
        isDeletingAccount = true
        deleteError = nil
        Task {
            defer { isDeletingAccount = false }
            do {
                try await accountSession.deleteAccount()
            } catch {
                deleteError = error.localizedDescription
            }
        }
    }
}

private struct EditProfileSheet: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var skillLevel: SkillLevel
    @State private var availability: String
    @State private var homeArea: String

    init() {
        _displayName = State(initialValue: DemoData.currentUser.displayName)
        _skillLevel = State(initialValue: DemoData.currentUser.skillLevel)
        _availability = State(initialValue: DemoData.currentUser.availabilitySummary)
        _homeArea = State(initialValue: DemoData.currentUser.homeArea ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                    Picker("Skill level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases) { level in Text(level.title).tag(level) }
                    }
                    TextField("City or area (optional)", text: $homeArea)
                        .textContentType(.addressCity)
                        .textInputAutocapitalization(.words)
                    TextField("Availability", text: $availability)
                        .textInputAutocapitalization(.sentences)
                }
                Section {
                    Text("This local profile is saved on this device. Account sync will be connected in a later milestone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                displayName = store.currentUser.displayName
                skillLevel = store.currentUser.skillLevel
                availability = store.currentUser.availabilitySummary
                homeArea = store.currentUser.homeArea ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateProfile(
                            displayName: displayName,
                            skillLevel: skillLevel,
                            availabilitySummary: availability,
                            homeArea: homeArea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : homeArea
                        )
                        dismiss()
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ProfileResultRow: View {
    let match: MatchRecord

    private var opponent: String {
        match.participants.first(where: { $0.side == .opponent })?.displayName ?? "Opponent"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: match.score.winner == .you ? "checkmark" : "xmark")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(match.score.winner == .you ? RallyTheme.darkGreen : .secondary)
                .frame(width: 40, height: 40)
                .background(match.score.winner == .you ? RallyTheme.tennis.opacity(0.35) : RallyTheme.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("vs \(opponent)").font(.subheadline.weight(.semibold))
                Text("\(match.scheduledAt.formatted(.dateTime.month(.abbreviated).day())) · \(match.court.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(match.score.completedSets.map { "\($0.you)–\($0.opponent)" }.joined(separator: ", "))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(13)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
    }
}
