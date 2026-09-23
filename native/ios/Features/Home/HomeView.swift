import RallyUpCore
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: RallyStore
    let onSelectTab: (RallyTab) -> Void
    let onStartManualMatch: () -> Void

    @State private var selectedMatch: MatchRecord?
    @State private var showingNotifications = false

    private var nextMatch: MatchRecord? { store.upcomingMatches.first }
    private var recentMatch: MatchRecord? { store.history.first }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let timeOfDay = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"
        let firstName = store.currentUser.displayName.split(separator: " ").first.map(String.init) ?? "there"
        return "Good \(timeOfDay), \(firstName)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .tracking(-0.6)
                    Text("More tennis. Brighter days.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                if let nextMatch {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SectionHeading(title: "Next match")
                            Spacer()
                            Text("Good players. Better days.")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.3)
                                .foregroundStyle(.secondary)
                        }
                        nextMatchContent(nextMatch)
                    }
                } else {
                    nextMatchEmpty
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Quick actions")
                    HStack(spacing: 10) {
                        QuickAction(title: "Find player", symbol: "person.2") { onSelectTab(.play) }
                        QuickAction(title: "Start match", symbol: "tennisball", action: onStartManualMatch)
                        QuickAction(title: "Find court", symbol: "sportscourt") { onSelectTab(.courts) }
                    }
                }

                recordCard

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Suggested players", actionTitle: "See all") { onSelectTab(.play) }
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(store.players.prefix(3)) { player in
                                Button { onSelectTab(.play) } label: {
                                    suggestedPlayer(player)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(.trailing, 4)
                }

                if let recentMatch {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Recent match", actionTitle: "History") { onSelectTab(.matches) }
                        Button { selectedMatch = recentMatch } label: { recentMatchCard(recentMatch) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, RallyTheme.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(RallyTheme.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(item: $selectedMatch) { match in
            MatchDetailSheet(matchID: match.id)
                .environmentObject(store)
        }
        .alert("Notifications", isPresented: $showingNotifications) {
            Button("Done", role: .cancel) { }
        } message: {
            Text(store.invitations.isEmpty ? "You're all caught up." : "You have \(store.invitations.count) match invite\(store.invitations.count == 1 ? "" : "s") waiting for you.")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Image("RallyUpWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 184, height: 48, alignment: .leading)
                .accessibilityLabel("RallyUp")
            Spacer()
            Button { showingNotifications = true } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 46, height: 46)
                    .background(RallyTheme.card, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if !store.invitations.isEmpty {
                            Circle().fill(RallyTheme.tennis).frame(width: 9, height: 9).padding(4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
    }

    private func nextMatchContent(_ match: MatchRecord) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                PlayerTeamView(players: store.teamProfiles(in: match, on: .you), avatarSize: 64)
                Text("VS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
                PlayerTeamView(players: store.teamProfiles(in: match, on: .opponent), avatarSize: 64)
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 5) {
                    Text("GOOD PLAYERS")
                    Text("BETTER DAYS")
                    Rectangle().fill(RallyTheme.tennis).frame(width: 42, height: 3).padding(.top, 4)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 12) {
                    Label(match.scheduledAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()), systemImage: "calendar")
                    Spacer(minLength: 4)
                    Label(match.scheduledAt.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                }
                Label(match.court.name, systemImage: "mappin.and.ellipse")
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            Label("\(match.matchType.title) · \(match.format.title)", systemImage: "tennisball")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { selectedMatch = match } label: {
                Label("View match", systemImage: "arrow.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(RallyTheme.tennis, in: Capsule())
                    .foregroundStyle(RallyTheme.ink)
            }
            .buttonStyle(.plain)
        }
        .rallyCard()
    }

    private var nextMatchEmpty: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Next match")
            ContentUnavailableView("No match scheduled", systemImage: "calendar.badge.plus", description: Text("Invite a player to get your next rally on the calendar."))
                .frame(minHeight: 150)
                .rallyCard()
        }
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Your record", actionTitle: "Details") { onSelectTab(.profile) }
            HStack(spacing: 0) {
                RecordMetric(value: "\(store.wins)", title: "Wins")
                Divider().frame(height: 42)
                RecordMetric(value: "\(store.losses)", title: "Losses")
                Divider().frame(height: 42)
                RecordMetric(value: "\(store.winRate)%", title: "Win rate")
                Divider().frame(height: 42)
                VStack(spacing: 1) {
                    Image(systemName: "trophy")
                        .font(.caption.weight(.semibold))
                    Text("\(store.currentWinStreak) Wins")
                        .font(.subheadline.weight(.bold))
                    Text("Streak")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
            .padding(.vertical, 8)
        }
        .rallyCard()
    }

    private func suggestedPlayer(_ player: PlayerProfile) -> some View {
        HStack(spacing: 12) {
            PlayerAvatarView(player: player, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(player.displayName).font(.subheadline).foregroundStyle(.primary)
                Text("\(player.skillLevel.title) · \(distance(for: player)) away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let compatibility = player.compatibilityPercent {
                    Text("\(compatibility)% match")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RallyTheme.darkGreen)
                }
            }
            .lineLimit(1)
        }
        .padding(12)
        .frame(width: 250, alignment: .leading)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
    }

    private func recentMatchCard(_ match: MatchRecord) -> some View {
        HStack(spacing: 13) {
            PlayerAvatarView(player: opponent(in: match), size: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(match.teamName(on: .opponent))").font(.subheadline)
                Text("\(match.matchType.title) · \(match.court.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(match.scheduledAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(match.score.winner == .you ? "Won" : "Lost")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RallyTheme.tennis.opacity(0.25), in: Capsule())
                Text(match.score.completedSets.map { "\($0.you)–\($0.opponent)" }.joined(separator: ", "))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
    }

    private func opponent(in match: MatchRecord) -> PlayerProfile {
        let participant = match.participants.first(where: { $0.side == .opponent })
        return store.players.first(where: { $0.id == participant?.playerID }) ?? PlayerProfile(
            id: participant?.playerID ?? UUID(),
            displayName: participant?.displayName ?? "Opponent",
            initials: String((participant?.displayName ?? "OP").prefix(2)).uppercased(),
            skillLevel: .intermediate
        )
    }

    private func distance(for player: PlayerProfile) -> String {
        guard let distance = player.approximateDistanceKm else { return "nearby" }
        return String(format: "%.1f km", distance)
    }
}

private struct QuickAction: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.headline.weight(.medium))
                Text(title).font(.caption.weight(.medium)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.horizontal, 6)
            .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
