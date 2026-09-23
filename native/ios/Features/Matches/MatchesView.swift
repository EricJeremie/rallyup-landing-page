import RallyUpCore
import SwiftUI

struct MatchesView: View {
    @EnvironmentObject private var store: RallyStore
    @Binding var manualMatchRequested: Bool
    @State private var selectedList = MatchList.upcoming
    @State private var selectedMatch: MatchRecord?
    @State private var showManualMatch = false
    @State private var pendingImmediateMatchID: UUID?
    @State private var liveScoreMatchID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Match list", selection: $selectedList) {
                    ForEach(MatchList.allCases) { list in
                        Text(list.title).tag(list)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Match list")

                switch selectedList {
                case .upcoming:
                    upcomingContent
                case .invites:
                    invitationContent
                case .history:
                    historyContent
                }
            }
            .padding(.horizontal, RallyTheme.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: presentRequestedManualMatch)
        .onChange(of: manualMatchRequested) { _, _ in presentRequestedManualMatch() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showManualMatch = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Start a match manually")
            }
        }
        .navigationDestination(item: $liveScoreMatchID) { matchID in
            LiveScoreView(matchID: matchID)
                .environmentObject(store)
        }
        .sheet(item: $selectedMatch) { match in
            MatchDetailSheet(matchID: match.id)
                .environmentObject(store)
        }
        .sheet(isPresented: $showManualMatch, onDismiss: {
            if let pendingImmediateMatchID {
                self.pendingImmediateMatchID = nil
                liveScoreMatchID = pendingImmediateMatchID
            }
        }) {
            NavigationStack {
                ManualMatchView { matchID in
                    pendingImmediateMatchID = matchID
                }
                .environmentObject(store)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var upcomingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.upcomingMatches.isEmpty {
                EmptyStateView(title: "No upcoming matches", message: "Start a match manually or find a player to set up your next rally.", symbol: "calendar.badge.plus")
                Button { showManualMatch = true } label: {
                    Label("Start a match manually", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(RallyTheme.tennis)
                .foregroundStyle(RallyTheme.ink)
            } else {
                ForEach(store.upcomingMatches) { match in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(match.scheduledAt.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        MatchRow(match: match) { selectedMatch = match }
                    }
                }
            }
            if !store.invitations.isEmpty {
                SectionHeading(title: "Invites", actionTitle: "View all") { selectedList = .invites }
                ForEach(store.invitations.prefix(1)) { invitation in
                    InvitePreview(match: invitation) { selectedList = .invites }
                }
            }
        }
    }

    private func presentRequestedManualMatch() {
        guard manualMatchRequested else { return }
        manualMatchRequested = false
        showManualMatch = true
    }

    private var invitationContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.invitations.isEmpty && store.sentInvites.isEmpty {
                EmptyStateView(title: "No pending invites", message: "New invitations will appear here.", symbol: "envelope.open")
            } else {
                if !store.invitations.isEmpty {
                    SectionHeading(title: "Received")
                    ForEach(store.invitations) { match in
                        InvitationCard(match: match) { selectedMatch = match }
                    }
                }
                if !store.sentInvites.isEmpty {
                    SectionHeading(title: "Sent")
                    ForEach(store.sentInvites) { match in
                        SentInviteCard(match: match) { selectedMatch = match }
                    }
                }
            }
        }
    }

    private var historyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.history.isEmpty {
                EmptyStateView(title: "No match history yet", message: "Completed match results will show here.", symbol: "clock.arrow.circlepath")
            } else {
                ForEach(store.history) { match in
                    MatchRow(match: match) { selectedMatch = match }
                }
            }
        }
    }
}

private enum MatchList: String, CaseIterable, Identifiable {
    case upcoming
    case invites
    case history

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct ManualMatchView: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss

    let onStartImmediately: (UUID) -> Void

    @State private var startsImmediately = true
    @State private var scheduledAt = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now.addingTimeInterval(86_400)
    @State private var courtName = ""
    @State private var courtAddress = ""
    @State private var surface = "Hard"
    @State private var setting = "Outdoor"
    @State private var matchType: MatchType = .singles
    @State private var format: MatchFormat = .bestOfThree
    @State private var teammateName = ""
    @State private var opponentName = ""
    @State private var opponentPartnerName = ""
    @State private var note = ""
    @State private var errorMessage: String?

    private let surfaces = ["Hard", "Clay", "Grass", "Carpet", "Other"]

    private var requiredNames: [String] {
        matchType == .singles
            ? [opponentName]
            : [teammateName, opponentName, opponentPartnerName]
    }

    private var canCreate: Bool {
        !courtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && requiredNames.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && note.count <= 500
            && (startsImmediately || scheduledAt > .now)
    }

    var body: some View {
        Form {
            Section {
                Picker("Match timing", selection: $startsImmediately) {
                    Text("Start now").tag(true)
                    Text("Schedule").tag(false)
                }
                .pickerStyle(.segmented)

                if startsImmediately {
                    Label("Scoring opens as soon as you start.", systemImage: "play.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    DatePicker("Date and time", selection: $scheduledAt, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                }
            } header: {
                Text("When")
            }

            Section {
                TextField("Court name", text: $courtName)
                    .textContentType(.organizationName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                TextField("Address or area (optional)", text: $courtAddress)
                    .textContentType(.fullStreetAddress)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                Picker("Surface", selection: $surface) {
                    ForEach(surfaces, id: \.self) { Text($0).tag($0) }
                }
                Picker("Setting", selection: $setting) {
                    Text("Outdoor").tag("Outdoor")
                    Text("Indoor").tag("Indoor")
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Court")
            } footer: {
                Text("Enter the venue details for this match. No location access is needed.")
            }

            Section {
                Picker("Format", selection: $matchType) {
                    ForEach(MatchType.allCases) { type in Text(type.title).tag(type) }
                }
                .pickerStyle(.segmented)

                LabeledContent("You", value: store.currentUser.displayName)
                if matchType == .doubles {
                    TextField("Your teammate", text: $teammateName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                TextField("Opponent name", text: $opponentName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                if matchType == .doubles {
                    TextField("Opponent’s teammate", text: $opponentPartnerName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Players")
            } footer: {
                Text("Add names directly. This creates a local match and does not send invitations.")
            }

            Section {
                Picker("Scoring", selection: $format) {
                    ForEach(MatchFormat.allCases) { item in Text(item.title).tag(item) }
                }
                Text(format.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Match rules")
            }

            Section {
                TextField("Add a note (optional)", text: $note, axis: .vertical)
                    .lineLimit(2...4)
                    .onChange(of: note) { _, value in
                        if value.count > 500 { note = String(value.prefix(500)) }
                    }
                Text("\(note.count)/500")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .listRowSeparator(.hidden)
            } header: {
                Text("Notes")
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Manual match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(startsImmediately ? "Start" : "Schedule", action: createMatch)
                    .fontWeight(.semibold)
                    .disabled(!canCreate)
            }
        }
    }

    private func createMatch() {
        guard canCreate else { return }
        errorMessage = nil
        if store.isCloudBacked {
            Task {
                do {
                    let matchID = try await store.createRemoteManualMatch(
                        scheduledAt: scheduledAt,
                        courtName: courtName,
                        matchType: matchType,
                        format: format,
                        teammateName: matchType == .doubles ? teammateName : nil,
                        opponentName: opponentName,
                        opponentPartnerName: matchType == .doubles ? opponentPartnerName : nil,
                        note: note,
                        startsImmediately: startsImmediately
                    )
                    if startsImmediately { onStartImmediately(matchID) }
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            return
        }
        guard let matchID = store.createManualMatch(
                  scheduledAt: scheduledAt,
                  courtName: courtName,
                  courtAddress: courtAddress,
                  surface: surface,
                  setting: setting,
                  matchType: matchType,
                  format: format,
                  teammateName: matchType == .doubles ? teammateName : nil,
                  opponentName: opponentName,
                  opponentPartnerName: matchType == .doubles ? opponentPartnerName : nil,
                  note: note,
              startsImmediately: startsImmediately
              ) else { return }

        if startsImmediately { onStartImmediately(matchID) }
        dismiss()
    }
}

private struct InvitePreview: View {
    let match: MatchRecord
    let action: () -> Void

    private var opponent: String {
        let name = match.teamName(on: .opponent)
        return name.isEmpty ? "A player" : name
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(RallyTheme.tennis).frame(width: 46, height: 46)
                    .overlay(Image(systemName: "tennisball.fill").foregroundStyle(RallyTheme.darkGreen))
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(opponent) invited you to play")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(match.scheduledAt.formatted(.dateTime.weekday(.wide).hour().minute())) · \(match.court.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("View")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RallyTheme.darkGreen)
            }
            .padding(14)
            .background(RallyTheme.tennis.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RallyTheme.tennis.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct InvitationCard: View {
    @EnvironmentObject private var store: RallyStore
    let match: MatchRecord
    let showDetails: () -> Void

    private var opponent: String {
        let name = match.teamName(on: .opponent)
        return name.isEmpty ? "A player" : name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                PlayerAvatarView(player: PlayerProfile(
                    id: match.participants.first(where: { $0.side == .opponent })?.playerID ?? UUID(),
                    displayName: opponent,
                    initials: String(opponent.prefix(2)).uppercased(),
                    skillLevel: .intermediate
                ), size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(opponent).font(.subheadline)
                    Text(match.scheduledAt.formatted(.dateTime.weekday(.wide).month(.wide).day().hour().minute()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(match.court.name) · \(match.format.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { showDetails() } label: {
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .accessibilityLabel("View invite details")
            }

            if let note = match.note, !note.isEmpty {
                Text("“\(note)”")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button(role: .destructive) { store.respondToInvite(match.id, accept: false) } label: {
                    Text("Decline")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RallyTheme.secondaryAction, in: Capsule())
                        .contentShape(Capsule())
                }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                Button { store.respondToInvite(match.id, accept: true) } label: {
                    Text("Accept")
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
        .padding(16)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
    }
}

private struct SentInviteCard: View {
    @EnvironmentObject private var store: RallyStore
    let match: MatchRecord
    let showDetails: () -> Void

    private var opponent: String {
        let name = match.teamName(on: .opponent)
        return name.isEmpty ? "A player" : name
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(RallyTheme.tennis.opacity(0.35)).frame(width: 48, height: 48)
                .overlay(Image(systemName: "paperplane.fill").foregroundStyle(RallyTheme.darkGreen))
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite sent to \(opponent)").font(.subheadline.weight(.semibold))
                Text("\(match.scheduledAt.formatted(.dateTime.weekday(.wide).hour().minute())) · \(match.court.name)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text("Waiting for a reply")
                    .font(.caption.weight(.medium)).foregroundStyle(RallyTheme.darkGreen)
            }
            Spacer(minLength: 4)
            Menu {
                Button("View details", action: showDetails)
                Button("Cancel invite", role: .destructive) { store.cancelSentInvite(match.id) }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Invite actions")
        }
        .padding(14)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
    }
}

struct MatchDetailSheet: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss
    @State private var showLiveScore = false
    @State private var showMatchSetup = false

    let matchID: UUID

    private var match: MatchRecord? { store.matches.first(where: { $0.id == matchID }) }

    var body: some View {
        NavigationStack {
            Group {
                if let match {
                    detailContent(match)
                } else {
                    EmptyStateView(title: "Match unavailable", message: "This match may have been removed.", symbol: "calendar.badge.exclamationmark")
                }
            }
            .navigationTitle("Match details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showLiveScore) {
                LiveScoreView(matchID: matchID)
                    .environmentObject(store)
            }
            .navigationDestination(isPresented: $showMatchSetup) {
                if let match {
                    MatchSetupView(match: match)
                        .environmentObject(store)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func detailContent(_ match: MatchRecord) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 18) {
                    PlayerTeamView(players: store.teamProfiles(in: match, on: .you), avatarSize: 64, labelFont: .subheadline)
                    VStack(spacing: 5) {
                        Text("VS").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Text(match.format.title).font(.caption).foregroundStyle(.secondary)
                    }
                    PlayerTeamView(players: store.teamProfiles(in: match, on: .opponent), avatarSize: 64, labelFont: .subheadline)
                }

                VStack(spacing: 0) {
                    MatchDetailRow(symbol: "calendar", title: "Date", value: match.scheduledAt.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    MatchDetailRow(symbol: "clock", title: "Time", value: match.scheduledAt.formatted(.dateTime.hour().minute()))
                    MatchDetailRow(symbol: "mappin.and.ellipse", title: "Court", value: match.court.name)
                    if match.court.address != "Address not provided" {
                        MatchDetailRow(symbol: "location", title: "Location", value: match.court.address)
                    }
                    MatchDetailRow(symbol: "square.grid.2x2", title: "Surface", value: "\(match.court.surface) · \(match.court.setting)")
                    MatchDetailRow(symbol: "person.2", title: "Match type", value: match.matchType.title)
                    MatchDetailRow(symbol: "tennisball", title: "Format", value: match.format.title)
                }
                .rallyCard()

                if let note = match.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "Match note")
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .rallyCard()
                }

                statusActions(match)
            }
            .padding(RallyTheme.pagePadding)
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private func statusActions(_ match: MatchRecord) -> some View {
        switch match.status {
        case .scheduled:
            VStack(spacing: 10) {
                Button { showMatchSetup = true } label: {
                    Label("Edit match details", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .tint(RallyTheme.darkGreen)

                Button {
                    store.startMatch(match.id)
                    showLiveScore = true
                } label: {
                    Label("Start match", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(RallyTheme.tennis)
                .foregroundStyle(RallyTheme.ink)
            }
        case .inProgress:
            Button { showLiveScore = true } label: {
                Label("Resume scoring", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .tint(RallyTheme.tennis)
            .foregroundStyle(RallyTheme.ink)
        case .invited:
            HStack(spacing: 10) {
                Button(role: .destructive) { store.respondToInvite(match.id, accept: false) } label: {
                    Text("Decline")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RallyTheme.secondaryAction, in: Capsule())
                        .contentShape(Capsule())
                }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                Button { store.respondToInvite(match.id, accept: true) } label: {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RallyTheme.darkGreen, in: Capsule())
                        .contentShape(Capsule())
                }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
            }
        case .inviteSent:
            VStack(spacing: 10) {
                Label("Invite sent · waiting for a reply", systemImage: "paperplane")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RallyTheme.darkGreen)
                Button("Cancel invite", role: .destructive) { store.cancelSentInvite(match.id) }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        case .awaitingConfirmation:
            VStack(spacing: 10) {
                Label("Result saved · awaiting confirmation", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RallyTheme.darkGreen)
                Button("Confirm result") { store.confirmResult(match.id) }
                    .buttonStyle(.borderedProminent)
                    .tint(RallyTheme.tennis)
                    .foregroundStyle(RallyTheme.ink)
                    .frame(maxWidth: .infinity)
            }
        case .completed:
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(title: "Final score")
                HStack(spacing: 10) {
                    ForEach(Array(match.score.completedSets.enumerated()), id: \.offset) { _, set in
                        Text("\(set.you)–\(set.opponent)")
                            .font(.headline.weight(.bold).monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        case .cancelled, .disputed:
            Text(match.status == .cancelled ? "This match was cancelled." : "This result is being reviewed.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .rallyCard()
        }
    }

}

private struct MatchDetailRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .foregroundStyle(RallyTheme.darkGreen)
                .frame(width: 22)
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 11)
    }
}

private struct MatchSetupView: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss

    let match: MatchRecord

    @State private var scheduledAt: Date
    @State private var selectedCourtID: UUID
    @State private var matchType: MatchType
    @State private var format: MatchFormat
    @State private var teammateID: UUID?
    @State private var opponentID: UUID?
    @State private var opponentPartnerID: UUID?
    @State private var note: String

    init(match: MatchRecord) {
        self.match = match
        _scheduledAt = State(initialValue: match.scheduledAt)
        _selectedCourtID = State(initialValue: match.court.id)
        _matchType = State(initialValue: match.matchType)
        _format = State(initialValue: match.format)
        _teammateID = State(initialValue: match.participants(on: .you).dropFirst().first?.playerID)
        _opponentID = State(initialValue: match.participants(on: .opponent).first?.playerID)
        _opponentPartnerID = State(initialValue: match.participants(on: .opponent).dropFirst().first?.playerID)
        _note = State(initialValue: match.note ?? "")
    }

    private var selectedCourt: TennisCourt {
        store.courts.first(where: { $0.id == selectedCourtID }) ?? store.courts[0]
    }

    private var selectedTeammate: PlayerProfile? {
        store.players.first(where: { $0.id == teammateID })
    }

    private var selectedOpponent: PlayerProfile? {
        store.players.first(where: { $0.id == opponentID })
    }

    private var selectedOpponentPartner: PlayerProfile? {
        store.players.first(where: { $0.id == opponentPartnerID })
    }

    private var teammateOptions: [PlayerProfile] {
        store.players.filter { $0.id != opponentID && $0.id != opponentPartnerID }
    }

    private var opponentOptions: [PlayerProfile] {
        store.players.filter { $0.id != teammateID && $0.id != opponentPartnerID }
    }

    private var opponentPartnerOptions: [PlayerProfile] {
        store.players.filter { $0.id != teammateID && $0.id != opponentID }
    }

    private var canSave: Bool {
        guard selectedOpponent != nil,
              scheduledAt > .now,
              note.count <= 500 else { return false }
        guard matchType == .doubles else { return true }
        guard let teammateID, let opponentID, let opponentPartnerID else { return false }
        return Set([teammateID, opponentID, opponentPartnerID, store.currentUser.id]).count == 4
    }

    var body: some View {
        Form {
            Section("Match details") {
                DatePicker("Date and time", selection: $scheduledAt, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
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
                        ForEach(teammateOptions) { player in Text(player.displayName).tag(Optional(player.id)) }
                    }
                }
                Picker(matchType == .doubles ? "Opponent" : "Opponent", selection: $opponentID) {
                    ForEach(opponentOptions) { player in Text(player.displayName).tag(Optional(player.id)) }
                }
                if matchType == .doubles {
                    Picker("Opponent’s teammate", selection: $opponentPartnerID) {
                        ForEach(opponentPartnerOptions) { player in Text(player.displayName).tag(Optional(player.id)) }
                    }
                }
                Text(matchType == .doubles ? "Choose two distinct players for each team." : "Singles is one player on each side.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Scoring format") {
                Picker("Format", selection: $format) {
                    ForEach(MatchFormat.allCases) { item in Text(item.title).tag(item) }
                }
                Text(format.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Match note") {
                TextField("Optional note", text: $note, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Edit match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .onAppear { ensureDoublesLineup() }
        .onChange(of: matchType) { _, _ in ensureDoublesLineup() }
        .onChange(of: teammateID) { _, _ in ensureDoublesLineup() }
        .onChange(of: opponentID) { _, _ in ensureDoublesLineup() }
        .onChange(of: opponentPartnerID) { _, _ in ensureDoublesLineup() }
    }

    private func ensureDoublesLineup() {
        guard matchType == .doubles else { return }
        if opponentID == nil || opponentID == store.currentUser.id {
            opponentID = store.players.first(where: { $0.id != teammateID && $0.id != opponentPartnerID })?.id
        }
        if teammateID == nil || teammateID == opponentID || teammateID == opponentPartnerID {
            teammateID = store.players.first(where: { $0.id != opponentID && $0.id != opponentPartnerID })?.id
        }
        if opponentPartnerID == nil || opponentPartnerID == opponentID || opponentPartnerID == teammateID {
            opponentPartnerID = store.players.first(where: { $0.id != opponentID && $0.id != teammateID })?.id
        }
    }

    private func save() {
        guard let selectedOpponent else { return }
        let didSave = store.updateScheduledMatch(
            match.id,
            scheduledAt: scheduledAt,
            court: selectedCourt,
            matchType: matchType,
            format: format,
            teammate: matchType == .doubles ? selectedTeammate : nil,
            opponent: selectedOpponent,
            opponentPartner: matchType == .doubles ? selectedOpponentPartner : nil,
            note: note
        )
        if didSave { dismiss() }
    }
}

struct LiveScoreView: View {
    @EnvironmentObject private var store: RallyStore
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var pointFontSize = 48.0
    let matchID: UUID

    private var match: MatchRecord? { store.matches.first(where: { $0.id == matchID }) }

    var body: some View {
        Group {
            if let match {
                scoreContent(match)
            } else {
                EmptyStateView(title: "Match unavailable", message: "Return to Matches and try again.", symbol: "tennisball")
            }
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
        .navigationTitle("RallyUp Match")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if match?.status == .inProgress {
                    Text("LIVE")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(RallyTheme.darkGreen)
                }
            }
        }
    }

    @ViewBuilder
    private func scoreContent(_ match: MatchRecord) -> some View {
        let opponentName = match.teamName(on: .opponent)
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    PlayerTeamView(players: store.teamProfiles(in: match, on: .you), avatarSize: 76, labelFont: .subheadline)
                    Text("VS").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    PlayerTeamView(players: store.teamProfiles(in: match, on: .opponent), avatarSize: 76, labelFont: .subheadline)
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("SET \(match.score.completedSets.count + 1)")
                            .font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(.secondary)
                        Spacer()
                        Text(match.format.title).font(.caption).foregroundStyle(.secondary)
                    }
                    scoreTable(match.score, matchType: match.matchType)
                }
                .rallyCard()

                VStack(spacing: 16) {
                    Text(match.score.isTiebreak ? "TIEBREAK" : "CURRENT GAME")
                        .font(.caption.weight(.bold)).tracking(1.4).foregroundStyle(.secondary)
                    HStack(alignment: .center) {
                        pointColumn(name: match.matchType == .doubles ? "Your team" : "You", points: match.score.pointLabel(for: .you))
                        Rectangle().fill(RallyTheme.separator).frame(width: 1, height: 72)
                        pointColumn(name: match.matchType == .doubles ? "Opponent team" : (opponentName.split(separator: " ").first.map(String.init) ?? "Opponent"), points: match.score.pointLabel(for: .opponent))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                if match.score.isComplete {
                    VStack(spacing: 10) {
                        Label("Match complete", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(RallyTheme.darkGreen)
                        Button("Save result") { store.finishMatch(match.id) }
                            .buttonStyle(.borderedProminent)
                            .tint(RallyTheme.tennis)
                            .foregroundStyle(RallyTheme.ink)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 10) {
                        Button { store.awardPoint(match.id, to: .you) } label: {
                            Label(match.matchType == .doubles ? "Your team won the point" : "You won the point", systemImage: "plus")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 70)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(RallyTheme.tennis)
                        .foregroundStyle(RallyTheme.ink)

                        Button { store.awardPoint(match.id, to: .opponent) } label: {
                            Label(match.matchType == .doubles ? "Opponent team won the point" : "\(opponentName.split(separator: " ").first.map(String.init) ?? "Opponent") won the point", systemImage: "plus")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 64)
                        }
                        .buttonStyle(.bordered)
                        .tint(RallyTheme.darkGreen)

                        HStack {
                            Button { store.undoPoint(match.id) } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                                .disabled(store.scoreHistory[match.id]?.isEmpty != false)
                            Spacer()
                            Text("Tap the player who won the point")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 3)
                    }
                }
            }
            .padding(RallyTheme.pagePadding)
            .padding(.bottom, 24)
        }
        .alert("Result ready", isPresented: Binding(
            get: { match.status == .awaitingConfirmation },
            set: { _ in }
        )) {
            Button("Confirm for demo") {
                store.confirmResult(match.id)
                dismiss()
            }
            Button("Keep pending", role: .cancel) { }
        } message: {
            Text("The local demo stores your result. A connected opponent confirmation flow will be added with the backend.")
        }
    }

    private func scoreTable(_ score: TennisScore, matchType: MatchType) -> some View {
        VStack(spacing: 9) {
            HStack {
                Text("Player").foregroundStyle(.secondary)
                Spacer()
                ForEach(Array(score.completedSets.enumerated()), id: \.offset) { index, _ in
                    Text("S\(index + 1)").frame(width: 38).foregroundStyle(.secondary)
                }
                Text("G").frame(width: 38).foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
            ForEach(PlayerSide.allCases) { side in
                HStack {
                    Text(scoreTeamLabel(side, matchType: matchType)).font(.subheadline.weight(.semibold))
                    Spacer()
                    ForEach(Array(score.completedSets.enumerated()), id: \.offset) { _, set in
                        Text("\(set.games(for: side))")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 38)
                    }
                    Text("\(score.games(for: side))")
                        .font(.headline.weight(.bold).monospacedDigit())
                        .frame(width: 38)
                }
            }
        }
    }

    private func pointColumn(name: String, points: String) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Text(points)
                .font(.system(size: pointFontSize, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .accessibilityLabel("\(name), \(points)")
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy(duration: 0.2), value: points)
    }

    private func scoreTeamLabel(_ side: PlayerSide, matchType: MatchType) -> String {
        guard matchType == .doubles else { return side == .you ? "You" : "Opponent" }
        return side == .you ? "Your team" : "Opponent team"
    }
}
