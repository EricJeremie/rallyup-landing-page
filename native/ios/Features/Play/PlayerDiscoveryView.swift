import RallyUpCore
import SwiftUI

struct PlayerDiscoveryView: View {
    @EnvironmentObject private var store: RallyStore
    @EnvironmentObject private var accountSession: AccountSessionStore
    @State private var searchText = ""
    @State private var selectedLevel: SkillLevel?
    @State private var selectedPlayer: PlayerProfile?

    private var filteredPlayers: [PlayerProfile] {
        store.players.filter { player in
            let matchesSearch = searchText.isEmpty || player.displayName.localizedCaseInsensitiveContains(searchText)
            let matchesLevel = selectedLevel == nil || player.skillLevel == selectedLevel
            return matchesSearch && matchesLevel
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Compatible players nearby")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        Button("All levels") { selectedLevel = nil }
                        ForEach(SkillLevel.allCases) { level in
                            Button(level.title) { selectedLevel = level }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.subheadline)
                            .frame(width: 44, height: 44)
                            .background(RallyTheme.card, in: Circle())
                    }
                    .accessibilityLabel("Filter players by skill level")
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        FilterChip(title: "All levels", selected: selectedLevel == nil) { selectedLevel = nil }
                        ForEach(SkillLevel.allCases) { level in
                            FilterChip(title: level.title, selected: selectedLevel == level) {
                                selectedLevel = selectedLevel == level ? nil : level
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)

                SectionHeading(title: "Players", actionTitle: "\(filteredPlayers.count) nearby") { }

                if filteredPlayers.isEmpty {
                    EmptyStateView(title: "No players found", message: "Try another name or clear the skill filter.", symbol: "person.2")
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredPlayers) { player in
                            PlayerDiscoveryCard(player: player) { selectedPlayer = player }
                        }
                    }
                }
            }
            .padding(.horizontal, RallyTheme.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
        .navigationTitle("Find players")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search players")
        .sheet(item: $selectedPlayer) { player in
            PlayerProfileSheet(player: player)
                .environmentObject(store)
        }
        .task(id: accountSession.currentAccount?.id) {
            let remotePlayers = await accountSession.refreshDiscoverablePlayers()
            store.setDiscoverablePlayers(remotePlayers)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "chevron.down").font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .frame(minHeight: 42)
            .background(selected ? RallyTheme.tennis : RallyTheme.card, in: Capsule())
            .foregroundStyle(selected ? RallyTheme.ink : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct PlayerDiscoveryCard: View {
    let player: PlayerProfile
    let openProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: openProfile) {
                HStack(alignment: .top, spacing: 14) {
                    PlayerAvatarView(player: player, size: 76)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(player.displayName).font(.headline.weight(.semibold)).foregroundStyle(.primary)
                        Label(player.skillLevel.title, systemImage: "chart.bar")
                        Label(distance, systemImage: "mappin.and.ellipse")
                        Label("\(player.wins)–\(player.losses)", systemImage: "trophy")
                        Label(player.availabilitySummary, systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let percent = player.compatibilityPercent {
                        CompatibilityBadge(percentage: percent)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens player profile")

            HStack(spacing: 10) {
                Button(action: openProfile) {
                    Text("View profile")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RallyTheme.secondaryAction, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                Button {
                    openProfile()
                } label: {
                    Label("Invite", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RallyTheme.darkGreen, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
    }

    private var distance: String {
        guard let distance = player.approximateDistanceKm else { return "Distance hidden" }
        return String(format: "%.1f km away", distance)
    }
}

private struct PlayerProfileSheet: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingInvite = false

    let player: PlayerProfile

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    PlayerAvatarView(player: player, size: 112)
                    VStack(spacing: 5) {
                        Text(player.displayName).font(.title3.weight(.bold))
                        Text("\(player.skillLevel.title) · \(player.availabilitySummary)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    if let percent = player.compatibilityPercent {
                        CompatibilityBadge(percentage: percent)
                    }
                    HStack {
                        RecordMetric(value: "\(player.wins)", title: "Wins")
                        Divider().frame(height: 46)
                        RecordMetric(value: "\(player.losses)", title: "Losses")
                        Divider().frame(height: 46)
                        RecordMetric(value: distance, title: "Away")
                    }
                    .padding(.vertical, 14)
                    .rallyCard()
                    if let strengths = player.strengths, !strengths.isEmpty {
                        PlayerStrengthsView(strengths: strengths)
                    }
                    if !player.racketSetup.isEmpty {
                        RacketSetupGallery(rackets: player.racketSetup, title: "Racket setup")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "About")
                        Text("Looking for a friendly, competitive rally. Usually free for a weekend match.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .rallyCard()
                }
                .padding(RallyTheme.pagePadding)
            }
            .background(RallyTheme.canvas.ignoresSafeArea())
            .navigationTitle("Player profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showingInvite = true
                } label: {
                    Label("Invite to play", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(RallyTheme.tennis)
                .foregroundStyle(RallyTheme.ink)
                .padding(.horizontal, RallyTheme.pagePadding)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .sheet(isPresented: $showingInvite) {
                InviteComposerSheet(player: player)
                    .environmentObject(store)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var distance: String {
        guard let value = player.approximateDistanceKm else { return "—" }
        return String(format: "%.1f km", value)
    }
}

private struct InviteComposerSheet: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var selectedCourtID = DemoData.courts[0].id
    @State private var matchType: MatchType = .singles
    @State private var format: MatchFormat = .bestOfThree
    @State private var teammateID: UUID?
    @State private var opponentPartnerID: UUID?
    @State private var note = ""

    let player: PlayerProfile

    private var selectedCourt: TennisCourt {
        store.courts.first(where: { $0.id == selectedCourtID }) ?? store.courts[0]
    }

    private var teammateOptions: [PlayerProfile] {
        store.players.filter { $0.id != player.id }
    }

    private var opponentPartnerOptions: [PlayerProfile] {
        store.players.filter { $0.id != player.id && $0.id != teammateID }
    }

    private var selectedTeammate: PlayerProfile? {
        store.players.first(where: { $0.id == teammateID })
    }

    private var selectedOpponentPartner: PlayerProfile? {
        store.players.first(where: { $0.id == opponentPartnerID })
    }

    private var canSend: Bool {
        guard matchType == .doubles else { return true }
        guard let teammateID, let opponentPartnerID else { return false }
        return teammateID != player.id && opponentPartnerID != player.id && teammateID != opponentPartnerID
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Match details") {
                    DatePicker("Date and time", selection: $date, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    Picker("Court", selection: $selectedCourtID) {
                        ForEach(store.courts) { court in Text(court.name).tag(court.id) }
                    }
                }
                Section("Players") {
                    Picker("Match type", selection: $matchType) {
                        ForEach(MatchType.allCases) { type in Text(type.title).tag(type) }
                    }
                    if matchType == .doubles {
                        Picker("Your teammate", selection: $teammateID) {
                            ForEach(teammateOptions) { option in Text(option.displayName).tag(Optional(option.id)) }
                        }
                        Picker("Opponent’s teammate", selection: $opponentPartnerID) {
                            ForEach(opponentPartnerOptions) { option in Text(option.displayName).tag(Optional(option.id)) }
                        }
                        Text("You’ll invite \(player.displayName) and their partner.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Opponent", value: player.displayName)
                    }
                }
                Section("Scoring format") {
                    Picker("Format", selection: $format) {
                        ForEach(MatchFormat.allCases) { item in Text(item.title).tag(item) }
                    }
                    Text(format.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Note to \(player.displayName)") {
                    TextField("Add a message (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Label("Only your approximate distance is shown to nearby players.", systemImage: "location.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Invite to play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        store.makeInvite(
                            for: player,
                            date: date,
                            court: selectedCourt,
                            matchType: matchType,
                            format: format,
                            note: note.isEmpty ? nil : note,
                            teammate: matchType == .doubles ? selectedTeammate : nil,
                            opponentPartner: matchType == .doubles ? selectedOpponentPartner : nil
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSend)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { ensureDoublesLineup() }
        .onChange(of: matchType) { _, _ in ensureDoublesLineup() }
        .onChange(of: teammateID) { _, _ in ensureDoublesLineup() }
        .onChange(of: opponentPartnerID) { _, _ in ensureDoublesLineup() }
    }

    private func ensureDoublesLineup() {
        guard matchType == .doubles else { return }
        if teammateID == nil || teammateID == player.id {
            teammateID = teammateOptions.first?.id
        }
        if opponentPartnerID == nil || opponentPartnerID == player.id || opponentPartnerID == teammateID {
            opponentPartnerID = opponentPartnerOptions.first?.id
        }
    }
}
