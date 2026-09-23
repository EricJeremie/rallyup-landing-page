import RallyUpCore
import SwiftUI
import UIKit

struct RallyLogoHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image("RallyUpWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 178, height: 44, alignment: .leading)
                .accessibilityLabel("RallyUp")
            Text("PLAY  ·  PEOPLE  ·  PROGRESS")
                .font(.caption2.weight(.semibold))
                .tracking(2.1)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct PlayerAvatarView: View {
    let player: PlayerProfile
    var size: CGFloat = 58

    private var fill: Color {
        switch player.initials {
        case "ER", "SL": RallyTheme.tennis
        case "JC": Color(red: 0.85, green: 0.89, blue: 0.77)
        case "MS": Color(red: 0.87, green: 0.89, blue: 0.84)
        default: RallyTheme.darkGreen
        }
    }

    private var textColor: Color {
        switch player.initials {
        case "ER", "SL", "JC", "MS": RallyTheme.ink
        default: .white
        }
    }

    var body: some View {
        avatarContent
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.primary.opacity(0.06), lineWidth: 1))
            .accessibilityLabel("\(player.displayName) avatar")
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let avatarURL = player.avatarURL,
           let url = URL(string: avatarURL), url.isFileURL,
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let avatarURL = player.avatarURL,
                  let url = URL(string: avatarURL), url.scheme == "https" || url.scheme == "http" {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    initialsContent
                }
            }
        } else {
            initialsContent
        }
    }

    private var initialsContent: some View {
        Text(player.initials)
            .font(.system(size: size * 0.27, weight: .semibold, design: .rounded))
            .foregroundStyle(textColor)
    }
}

struct PlayerTeamView: View {
    let players: [PlayerProfile]
    var avatarSize: CGFloat = 58
    var labelFont: Font = .caption

    private var displayedAvatarSize: CGFloat {
        players.count > 1 ? avatarSize * 0.72 : avatarSize
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: players.count > 1 ? -displayedAvatarSize * 0.22 : 0) {
                ForEach(players) { player in
                    PlayerAvatarView(player: player, size: displayedAvatarSize)
                }
            }
            Text(players.map(\.displayName).joined(separator: " & "))
                .font(labelFont.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct PlayerStrengthsView: View {
    let strengths: [PlayerStrength]
    var title = "Game strengths"

    var body: some View {
        if !strengths.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: title)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ForEach(strengths) { strength in
                        Text(strength.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RallyTheme.darkGreen)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(RallyTheme.tennis.opacity(0.16), in: Capsule())
                    }
                }
            }
            .rallyCard()
        }
    }
}

struct RacketSetupGallery: View {
    let rackets: [PlayerRacket]
    var title = "Racket setup"

    var body: some View {
        if !rackets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: title)
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(rackets.prefix(3)) { racket in
                            RacketSetupCard(racket: racket)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .rallyCard()
        }
    }
}

private struct RacketSetupCard: View {
    let racket: PlayerRacket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let photoURL = racket.photoURL,
                   let url = URL(string: photoURL), url.isFileURL,
                   let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let photoURL = racket.photoURL,
                          let url = URL(string: photoURL), url.scheme == "https" || url.scheme == "http" {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else if phase.error != nil {
                            placeholder
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: 148, height: 122)
            .background(RallyTheme.tennis.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(RallyTheme.separator, lineWidth: 1)
            }

            Text(racket.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .frame(width: 148, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(racket.photoURL == nil ? "\(racket.name), no photo" : "\(racket.name), racket photo")
    }

    private var placeholder: some View {
        Image(systemName: "tennis.racket")
            .font(.title2)
            .foregroundStyle(RallyTheme.darkGreen.opacity(0.65))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SectionHeading: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .tint(RallyTheme.darkGreen)
            }
        }
    }
}

struct RecordMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.title3.weight(.bold).monospacedDigit())
            Text(title).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

struct CompatibilityBadge: View {
    let percentage: Int

    var body: some View {
        Text("\(percentage)% match")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RallyTheme.tennis.opacity(0.24), in: Capsule())
            .foregroundStyle(RallyTheme.darkGreen)
    }
}

struct MatchRow: View {
    let match: MatchRecord
    let action: () -> Void

    private var opponent: String {
        let name = match.teamName(on: .opponent)
        return name.isEmpty ? "Opponent" : name
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(spacing: 3) {
                    Text(match.scheduledAt.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline.monospacedDigit())
                }
                .frame(width: 58)
                .padding(.vertical, 4)
                .overlay(alignment: .trailing) { Rectangle().fill(RallyTheme.separator).frame(width: 1) }

                VStack(alignment: .leading, spacing: 7) {
                    Text(opponent).font(.subheadline).foregroundStyle(.primary)
                    Label(match.court.name, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(match.matchType.title) · \(match.format.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens match details")
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
            .padding(.vertical, 24)
    }
}
