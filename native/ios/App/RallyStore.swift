import Foundation
import CommonCrypto
import RallyUpCore
import Security
import SwiftUI
import Supabase
import UIKit

enum RallyUpBackend {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://gkxtyvdffyccjgblgpnd.supabase.co")!,
        supabaseKey: "sb_publishable_wR736-ly-oY9Xk_1E1tRPg_kt3eI0cB"
    )
}

struct LocalAccount: Codable, Equatable, Identifiable {
    let id: UUID
    let displayName: String
    let email: String
    let skillLevel: SkillLevel
    let homeArea: String?
    let availabilitySummary: String
    let avatarURL: String?
    let strengths: [PlayerStrength]
    let rackets: [PlayerRacket]

    var racketPhotoURLs: [String] { rackets.compactMap(\.photoURL) }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case skillLevel
        case homeArea
        case availabilitySummary
        case avatarURL
        case strengths
        case rackets
        case racketPhotoURLs
    }

    init(
        id: UUID,
        displayName: String,
        email: String,
        skillLevel: SkillLevel = .intermediate,
        homeArea: String? = nil,
        availabilitySummary: String = "Availability not set",
        avatarURL: String? = nil,
        strengths: [PlayerStrength] = [],
        rackets: [PlayerRacket] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.skillLevel = skillLevel
        self.homeArea = homeArea
        self.availabilitySummary = availabilitySummary
        self.avatarURL = avatarURL
        self.strengths = Array(strengths.prefix(PlayerStrength.allCases.count))
        self.rackets = Array(rackets.prefix(RacketLimits.maximumRackets))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        skillLevel = try container.decodeIfPresent(SkillLevel.self, forKey: .skillLevel) ?? .intermediate
        homeArea = try container.decodeIfPresent(String.self, forKey: .homeArea)
        availabilitySummary = try container.decodeIfPresent(String.self, forKey: .availabilitySummary) ?? "Availability not set"
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        strengths = Array(try container.decodeIfPresent([PlayerStrength].self, forKey: .strengths)?.prefix(PlayerStrength.allCases.count) ?? [])
        if let savedRackets = try container.decodeIfPresent([PlayerRacket].self, forKey: .rackets) {
            rackets = Array(savedRackets.prefix(RacketLimits.maximumRackets))
        } else {
            rackets = Array((try container.decodeIfPresent([String].self, forKey: .racketPhotoURLs) ?? [])
                .prefix(RacketLimits.maximumRackets)
                .enumerated()
                .map { PlayerRacket(name: "Racket \($0.offset + 1)", photoURL: $0.element) })
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(email, forKey: .email)
        try container.encode(skillLevel, forKey: .skillLevel)
        try container.encodeIfPresent(homeArea, forKey: .homeArea)
        try container.encode(availabilitySummary, forKey: .availabilitySummary)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encode(strengths, forKey: .strengths)
        try container.encode(rackets, forKey: .rackets)
    }
}

struct SignupRacketInput: Identifiable {
    let id: UUID
    var name: String
    var photoData: Data?

    init(id: UUID = UUID(), name: String = "", photoData: Data? = nil) {
        self.id = id
        self.name = name
        self.photoData = photoData
    }
}

struct PendingRacket: Codable, Identifiable {
    let id: UUID
    let name: String
    let localPhotoURL: String?
}

struct SupabaseRacketRecord: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let position: Int
    let name: String
    let photo_path: String?
}

enum RacketLimits {
    static let maximumRackets = 3
}

enum RacketPhotoStore {
    static func saveAvatar(_ photo: Data?, for accountID: UUID) throws -> String? {
        guard let photo else { return nil }
        guard let jpeg = makeJPEG(from: photo) else { throw AccountAuthError.invalidProfilePhoto }

        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root
            .appendingPathComponent("RallyUp", isDirectory: true)
            .appendingPathComponent("ProfilePhotos", isDirectory: true)
            .appendingPathComponent(accountID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("profile.jpg")
        try jpeg.write(to: url, options: .atomic)
        return url.absoluteString
    }

    static func save(_ rackets: [SignupRacketInput], for accountID: UUID) throws -> [PendingRacket] {
        guard rackets.count <= RacketLimits.maximumRackets else { throw AccountAuthError.tooManyRackets }

        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root
            .appendingPathComponent("RallyUp", isDirectory: true)
            .appendingPathComponent("RacketPhotos", isDirectory: true)
            .appendingPathComponent(accountID.uuidString, isDirectory: true)
        guard rackets.contains(where: { $0.photoData != nil }) else {
            return rackets.map { PendingRacket(id: $0.id, name: $0.name, localPhotoURL: nil) }
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var savedURLs: [URL] = []
        do {
            var pending: [PendingRacket] = []
            for racket in rackets {
                guard let photo = racket.photoData else {
                    pending.append(PendingRacket(id: racket.id, name: racket.name, localPhotoURL: nil))
                    continue
                }
                guard let jpeg = makeJPEG(from: photo) else { throw AccountAuthError.invalidRacketPhoto }
                let url = directory.appendingPathComponent("racket-\(racket.id.uuidString).jpg")
                try jpeg.write(to: url, options: .atomic)
                savedURLs.append(url)
                pending.append(PendingRacket(id: racket.id, name: racket.name, localPhotoURL: url.absoluteString))
            }
            return pending
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    static func remove(_ photoURLs: [String]) {
        for value in photoURLs {
            guard let url = URL(string: value), url.isFileURL else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func makeJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }
        let scale = min(1, 1600 / longestSide)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format)
            .jpegData(withCompressionQuality: 0.84) { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
    }
}

enum AccountAuthError: LocalizedError {
    case invalidName
    case invalidEmail
    case weakPassword
    case accountAlreadyExists
    case invalidCredentials
    case keychainFailure
    case tooManyRackets
    case invalidRacketName
    case invalidRacketPhoto
    case invalidProfilePhoto
    case profileUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidName: "Enter your name to create an account."
        case .invalidEmail: "Enter a valid email address."
        case .weakPassword: "Use a password with at least 8 characters."
        case .accountAlreadyExists: "An account with this email already exists on this device."
        case .invalidCredentials: "Email or password is incorrect."
        case .keychainFailure: "Your account couldn’t be saved securely on this device. Try again."
        case .tooManyRackets: "You can add up to 3 rackets."
        case .invalidRacketName: "Give each racket a name or remove the empty racket."
        case .invalidRacketPhoto: "One of those photos couldn’t be read. Please choose another image."
        case .invalidProfilePhoto: "That profile photo couldn’t be read. Please choose another image."
        case .profileUnavailable: "Your account is signed in, but the player profile is still syncing. Try again in a moment."
        }
    }
}

private struct LocalAccountCredential: Codable {
    let account: LocalAccount
    let passwordSalt: Data
    let passwordDigest: Data
}

private struct LegacyLocalAccountCredential: Codable {
    let account: LocalAccount
    let password: String
}

private struct PendingSignupDraft: Codable {
    let userID: UUID
    let displayName: String
    let email: String
    let skillLevel: SkillLevel
    let homeArea: String?
    let availabilitySummary: String
    let localAvatarPhotoURL: String?
    let strengths: [PlayerStrength]
    let rackets: [PendingRacket]

    private enum CodingKeys: String, CodingKey {
        case userID
        case displayName
        case email
        case skillLevel
        case homeArea
        case availabilitySummary
        case localAvatarPhotoURL
        case strengths
        case rackets
        case localRacketPhotoURLs
    }

    var localPhotoURLs: [String] { [localAvatarPhotoURL].compactMap { $0 } + rackets.compactMap(\.localPhotoURL) }

    init(
        userID: UUID,
        displayName: String,
        email: String,
        skillLevel: SkillLevel,
        homeArea: String?,
        availabilitySummary: String,
        localAvatarPhotoURL: String? = nil,
        strengths: [PlayerStrength] = [],
        rackets: [PendingRacket]
    ) {
        self.userID = userID
        self.displayName = displayName
        self.email = email
        self.skillLevel = skillLevel
        self.homeArea = homeArea
        self.availabilitySummary = availabilitySummary
        self.localAvatarPhotoURL = localAvatarPhotoURL
        self.strengths = Array(strengths.prefix(PlayerStrength.allCases.count))
        self.rackets = Array(rackets.prefix(RacketLimits.maximumRackets))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(UUID.self, forKey: .userID)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        skillLevel = try container.decode(SkillLevel.self, forKey: .skillLevel)
        homeArea = try container.decodeIfPresent(String.self, forKey: .homeArea)
        availabilitySummary = try container.decode(String.self, forKey: .availabilitySummary)
        localAvatarPhotoURL = try container.decodeIfPresent(String.self, forKey: .localAvatarPhotoURL)
        strengths = Array(try container.decodeIfPresent([PlayerStrength].self, forKey: .strengths)?.prefix(PlayerStrength.allCases.count) ?? [])
        if let savedRackets = try container.decodeIfPresent([PendingRacket].self, forKey: .rackets) {
            rackets = Array(savedRackets.prefix(RacketLimits.maximumRackets))
        } else {
            rackets = Array((try container.decodeIfPresent([String].self, forKey: .localRacketPhotoURLs) ?? [])
                .prefix(RacketLimits.maximumRackets)
                .enumerated()
                .map { PendingRacket(id: UUID(), name: "Racket \($0.offset + 1)", localPhotoURL: $0.element) })
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(email, forKey: .email)
        try container.encode(skillLevel, forKey: .skillLevel)
        try container.encodeIfPresent(homeArea, forKey: .homeArea)
        try container.encode(availabilitySummary, forKey: .availabilitySummary)
        try container.encodeIfPresent(localAvatarPhotoURL, forKey: .localAvatarPhotoURL)
        try container.encode(strengths, forKey: .strengths)
        try container.encode(rackets, forKey: .rackets)
    }
}

struct SupabaseProfileRecord: Codable {
    let user_id: UUID
    let display_name: String
    let skill_level: String
    let home_area: String?
    let availability_summary: String
    let avatar_path: String?
    let player_strengths: [String]
    let profile_rackets: [SupabaseRacketRecord]?
}

private struct SupabaseProfileUpdate: Encodable {
    let display_name: String
    let skill_level: String
    let home_area: String?
    let availability_summary: String
    let avatar_path: String?
    let player_strengths: [String]
}

private struct SupabaseProfileBasicsUpdate: Encodable {
    let display_name: String
    let skill_level: String
    let home_area: String?
    let availability_summary: String
}

private struct SupabasePushTokenRecord: Encodable {
    let user_id: UUID
    let device_token: String
    let platform: String
    let last_seen_at: String
}

private struct SupabasePushTokenOwner: Decodable {
    let user_id: UUID
}

private struct SupabasePushTokenRefresh: Encodable {
    let last_seen_at: String
}

private struct MatchPushRequest: Encodable {
    let match_id: UUID
    let event: String
}

private struct SupabaseCourtRecord: Codable {
    let id: UUID
    let name: String
    let address: String
    let surface: String
    let setting: String
    let latitude: Double
    let longitude: Double
}

private struct SupabaseMatchParticipantRecord: Codable {
    let match_id: UUID
    let player_id: UUID
    let side: String
    let team_slot: Int
    let invite_response: String
}

private struct SupabaseMatchRecord: Codable {
    let id: UUID
    let created_by: UUID
    let court_id: UUID
    let scheduled_at: Date
    let match_type: String
    let match_format: String
    let status: String
    let note: String?
    let courts: SupabaseCourtRecord?
    let match_participants: [SupabaseMatchParticipantRecord]
}

private struct SupabaseParticipantProfileName: Codable {
    let user_id: UUID
    let display_name: String
}

private struct SupabaseLiveScoreRecord: Codable {
    let match_id: UUID
    let score_state: TennisScore
    let revision: Int64
}

enum MatchSyncError: LocalizedError {
    case playerNotFound(String)
    case courtNotFound(String)

    var errorDescription: String? {
        switch self {
        case .playerNotFound(let name): "Couldn’t find \(name) as a RallyUp player. Choose a registered player for cloud matches."
        case .courtNotFound(let name): "Couldn’t find \(name) in the RallyUp court catalog."
        }
    }
}

enum PlayerReportReason: String, CaseIterable, Identifiable {
    case harassment
    case unsafeBehavior = "unsafe_behavior"
    case spam
    case fakeProfile = "fake_profile"
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .harassment: "Harassment"
        case .unsafeBehavior: "Unsafe behavior"
        case .spam: "Spam"
        case .fakeProfile: "Fake profile"
        case .other: "Other"
        }
    }
}

@MainActor
final class AccountSessionStore: ObservableObject {
    @Published private(set) var currentAccount: LocalAccount?
    @Published private(set) var isDemoMode = false
    @Published private(set) var isCloudBacked = false
    @Published private(set) var isPasswordRecovery = false

    var isSignedIn: Bool { currentAccount != nil || isDemoMode }

    func userFacingAuthError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("rate limit") || message.contains("too many") || message.contains("email rate") {
            return "Too many emails were requested. Wait a few minutes before trying again."
        }
        if message.contains("email not confirmed") || message.contains("not confirmed") {
            return "Confirm your email first, then try signing in again."
        }
        return error.localizedDescription
    }

    private let defaults: UserDefaults
    private let activeEmailKey = "rallyup.local-auth.active-email.v1"
    private let keychainService = "com.rallyup.app.local-preview-auth"
    private let passwordDerivationRounds: UInt32 = 310_000

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let email = defaults.string(forKey: activeEmailKey),
           let credential = credential(for: email) {
            currentAccount = credential.account
        } else {
            defaults.removeObject(forKey: activeEmailKey)
        }
        Task { await restoreSupabaseSession() }
    }

    func signUp(
        displayName: String,
        email: String,
        password: String,
        skillLevel: SkillLevel,
        homeArea: String?,
        availabilitySummary: String,
        avatarPhotoData: Data? = nil,
        strengths: [PlayerStrength] = [],
        rackets: [SignupRacketInput] = []
    ) async throws -> Bool {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, cleanName.count <= 60 else { throw AccountAuthError.invalidName }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailParts = normalizedEmail.split(separator: "@", omittingEmptySubsequences: false)
        guard emailParts.count == 2,
              !emailParts[0].isEmpty,
              emailParts[1].contains("."),
              !normalizedEmail.contains(where: \.isWhitespace) else {
            throw AccountAuthError.invalidEmail
        }
        guard password.count >= 8 else { throw AccountAuthError.weakPassword }
        let selectedStrengths = PlayerStrength.allCases.filter { strengths.contains($0) }
        guard rackets.count <= RacketLimits.maximumRackets else { throw AccountAuthError.tooManyRackets }
        let cleanedRackets = try rackets.map { racket -> SignupRacketInput in
            let name = racket.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 80 else { throw AccountAuthError.invalidRacketName }
            return SignupRacketInput(id: racket.id, name: name, photoData: racket.photoData)
        }

        var metadata: [String: AnyJSON] = [
            "display_name": .string(cleanName),
            "skill_level": .string(skillLevel.rawValue),
            "availability_summary": .string(availabilitySummary),
        ]
        if let homeArea {
            metadata["home_area"] = .string(homeArea)
        }

        let response = try await RallyUpBackend.client.auth.signUp(
            email: normalizedEmail,
            password: password,
            data: metadata
        )
        let localAvatarPhotoURL = try RacketPhotoStore.saveAvatar(avatarPhotoData, for: response.user.id)
        let pendingRackets = try RacketPhotoStore.save(cleanedRackets, for: response.user.id)
        let draft = PendingSignupDraft(
            userID: response.user.id,
            displayName: cleanName,
            email: normalizedEmail,
            skillLevel: skillLevel,
            homeArea: homeArea,
            availabilitySummary: availabilitySummary,
            localAvatarPhotoURL: localAvatarPhotoURL,
            strengths: selectedStrengths,
            rackets: pendingRackets
        )
        try savePendingSignup(draft)
        defaults.removeObject(forKey: activeEmailKey)

        guard response.session != nil else {
            currentAccount = nil
            isDemoMode = false
            isCloudBacked = true
            return false
        }

        let account = try await publishProfile(from: draft)
        clearPendingSignup(for: normalizedEmail)
        RacketPhotoStore.remove(draft.localPhotoURLs)
        currentAccount = account
        isDemoMode = false
        isCloudBacked = true
        return true
    }

    func signIn(email: String, password: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let session: Session
        do {
            session = try await RallyUpBackend.client.auth.signIn(email: normalizedEmail, password: password)
        } catch {
#if DEBUG
            if let localAccount = tryLocalSignIn(email: normalizedEmail, password: password) {
                currentAccount = localAccount
                isDemoMode = false
                isCloudBacked = false
                defaults.set(normalizedEmail, forKey: activeEmailKey)
                return
            }
#endif
            throw error
        }

        let user = session.user
        let account: LocalAccount
        if let draft = pendingSignup(for: normalizedEmail) {
            account = try await publishProfile(from: draft)
            clearPendingSignup(for: normalizedEmail)
            RacketPhotoStore.remove(draft.localPhotoURLs)
        } else if let profile = try? await fetchProfile(userID: user.id, email: normalizedEmail) {
            account = profile
        } else {
            let name = metadataString("display_name", from: user)
                ?? normalizedEmail.split(separator: "@").first.map(String.init)
                ?? "Player"
            let draft = PendingSignupDraft(
                userID: user.id,
                displayName: String(name.prefix(60)),
                email: normalizedEmail,
                skillLevel: SkillLevel(rawValue: metadataString("skill_level", from: user) ?? "intermediate") ?? .intermediate,
                homeArea: metadataString("home_area", from: user),
                availabilitySummary: metadataString("availability_summary", from: user) ?? "Availability not set",
                rackets: []
            )
            do {
                account = try await publishProfile(from: draft)
            } catch {
                // Auth has already succeeded. Keep the user moving if profile hydration
                // is temporarily unavailable; the account metadata is enough to render
                // the signed-in shell and a later sync can fill the profile record.
                account = localAccountFromAuthUser(user, email: normalizedEmail)
            }
        }

        defaults.removeObject(forKey: activeEmailKey)
        currentAccount = account
        isDemoMode = false
        isCloudBacked = true
    }

    func requestPasswordReset(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailParts = normalizedEmail.split(separator: "@", omittingEmptySubsequences: false)
        guard emailParts.count == 2, !emailParts[0].isEmpty, emailParts[1].contains(".") else {
            throw AccountAuthError.invalidEmail
        }
        try await RallyUpBackend.client.auth.resetPasswordForEmail(
            normalizedEmail,
            redirectTo: URL(string: "rallyup://auth/reset")
        )
    }

    func handleAuthURL(_ url: URL) {
        guard url.scheme == "rallyup" else { return }
        Task {
            do {
                _ = try await RallyUpBackend.client.auth.session(from: url)
                isPasswordRecovery = url.host == "auth" && url.path == "/reset"
                if !isPasswordRecovery { await restoreSupabaseSession() }
            } catch {
                // Auth callbacks can be delivered more than once by the system.
            }
        }
    }

    func updatePassword(_ password: String) async throws {
        guard password.count >= 8 else { throw AccountAuthError.weakPassword }
        _ = try await RallyUpBackend.client.auth.update(user: UserAttributes(password: password))
        isPasswordRecovery = false
        await restoreSupabaseSession()
    }

    func deleteAccount() async throws {
        guard isCloudBacked else {
            signOut()
            return
        }
        try await RallyUpBackend.client.functions.invoke("delete-account")
        try? await RallyUpBackend.client.auth.signOut()
        currentAccount = nil
        isDemoMode = false
        isCloudBacked = false
        defaults.removeObject(forKey: activeEmailKey)
    }

    func continueWithDemo() {
        Task { try? await RallyUpBackend.client.auth.signOut() }
        currentAccount = nil
        isDemoMode = true
        isCloudBacked = false
        defaults.removeObject(forKey: activeEmailKey)
    }

    func signOut() {
        Task { try? await RallyUpBackend.client.auth.signOut() }
        currentAccount = nil
        isDemoMode = false
        isCloudBacked = false
        defaults.removeObject(forKey: activeEmailKey)
    }

    func registerPushToken(_ token: String) {
        guard isCloudBacked, let userID = currentAccount?.id, !token.isEmpty else { return }
        Task {
            let now = ISO8601DateFormatter().string(from: .now)
            let existing: [SupabasePushTokenOwner] = (try? await RallyUpBackend.client
                .from("device_push_tokens")
                .select("user_id")
                .eq("device_token", value: token)
                .limit(1)
                .execute()
                .value) ?? []

            if existing.first?.user_id == userID {
                let refresh = SupabasePushTokenRefresh(last_seen_at: now)
                try? await RallyUpBackend.client
                    .from("device_push_tokens")
                    .update(refresh)
                    .eq("device_token", value: token)
                    .eq("user_id", value: userID.uuidString)
                    .execute()
            } else if existing.isEmpty {
                let record = SupabasePushTokenRecord(
                    user_id: userID,
                    device_token: token,
                    platform: "ios",
                    last_seen_at: now
                )
                try? await RallyUpBackend.client.from("device_push_tokens").insert(record).execute()
            }
        }
    }

    func updateProfile(
        displayName: String,
        skillLevel: SkillLevel,
        availabilitySummary: String,
        homeArea: String?
    ) async throws {
        guard let account = currentAccount else { return }
        let update = SupabaseProfileBasicsUpdate(
            display_name: String(displayName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60)),
            skill_level: skillLevel.rawValue,
            home_area: homeArea,
            availability_summary: String(availabilitySummary.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        )
        try await RallyUpBackend.client
            .from("profiles")
            .update(update)
            .eq("user_id", value: account.id.uuidString)
            .execute()
        currentAccount = try await fetchProfile(userID: account.id, email: account.email)
    }

    func blockPlayer(_ playerID: UUID) async throws {
        let params: [String: AnyJSON] = ["p_player_id": .string(playerID.uuidString)]
        _ = try await RallyUpBackend.client.rpc("block_player", params: params).execute()
    }

    func unblockPlayer(_ playerID: UUID) async throws {
        let params: [String: AnyJSON] = ["p_player_id": .string(playerID.uuidString)]
        _ = try await RallyUpBackend.client.rpc("unblock_player", params: params).execute()
    }

    func reportPlayer(
        _ playerID: UUID,
        reason: PlayerReportReason,
        details: String = "",
        matchID: UUID? = nil
    ) async throws {
        let params: [String: AnyJSON] = [
            "p_player_id": .string(playerID.uuidString),
            "p_reason": .string(reason.rawValue),
            "p_details": .string(String(details.prefix(2_000))),
            "p_match_id": matchID.map { .string($0.uuidString) } ?? .null,
        ]
        let _: UUID = try await RallyUpBackend.client.rpc("report_player", params: params).execute().value
    }

    func refreshDiscoverablePlayers(
        searchQuery: String? = nil,
        skillLevel: SkillLevel? = nil
    ) async -> [PlayerProfile] {
        guard let session = try? await RallyUpBackend.client.auth.session else { return [] }
        do {
            let availabilityTerms = ["Weekdays", "Weekends", "Evenings"].filter {
                currentAccount?.availabilitySummary.localizedCaseInsensitiveContains($0) == true
            }
            let params: [String: AnyJSON] = [
                "p_search_query": searchQuery.map { .string($0) } ?? .null,
                "p_skill_level": skillLevel.map { .string($0.rawValue) } ?? .null,
                "p_area": currentAccount?.homeArea.map { .string($0) } ?? .null,
                "p_availability_terms": .array(availabilityTerms.map { .string($0) }),
            ]
            let profiles: [SupabaseProfileRecord] = try await RallyUpBackend.client
                .rpc("discover_profiles", params: params)
                .execute()
                .value

            var players: [PlayerProfile] = []
            for profile in profiles where profile.user_id != session.user.id {
                players.append(try await playerProfile(from: profile))
            }
            return players
        } catch {
            return []
        }
    }

    private func fetchProfile(userID: UUID, email: String) async throws -> LocalAccount {
        let profile: SupabaseProfileRecord = try await RallyUpBackend.client
            .from("profiles")
            .select("user_id,display_name,skill_level,home_area,availability_summary,avatar_path,player_strengths")
            .eq("user_id", value: userID.uuidString)
            .single()
            .execute()
            .value

        let rackets: [SupabaseRacketRecord] = (try? await RallyUpBackend.client
            .from("profile_rackets")
            .select("id,user_id,position,name,photo_path")
            .eq("user_id", value: userID.uuidString)
            .order("position", ascending: true)
            .execute()
            .value) ?? []
        let enrichedProfile = SupabaseProfileRecord(
            user_id: profile.user_id,
            display_name: profile.display_name,
            skill_level: profile.skill_level,
            home_area: profile.home_area,
            availability_summary: profile.availability_summary,
            avatar_path: profile.avatar_path,
            player_strengths: profile.player_strengths,
            profile_rackets: rackets
        )
        return try await localAccount(from: enrichedProfile, email: email)
    }

    private func publishProfile(from draft: PendingSignupDraft) async throws -> LocalAccount {
        var avatarPath: String?
        if let localAvatarPhotoURL = draft.localAvatarPhotoURL,
           let fileURL = URL(string: localAvatarPhotoURL),
           fileURL.isFileURL,
           FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            let path = "\(draft.userID.uuidString.lowercased())/profile.jpg"
            try await RallyUpBackend.client.storage
                .from("profile-photos")
                .upload(
                    path,
                    data: data,
                    options: FileOptions(cacheControl: "31536000", contentType: "image/jpeg", upsert: true)
                )
            avatarPath = path
        }

        var racketRows: [SupabaseRacketRecord] = []
        for (index, racket) in draft.rackets.prefix(RacketLimits.maximumRackets).enumerated() {
            var photoPath: String?
            if let localPhotoURL = racket.localPhotoURL,
               let fileURL = URL(string: localPhotoURL),
               fileURL.isFileURL,
               FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let path = "\(draft.userID.uuidString.lowercased())/rackets/\(racket.id.uuidString.lowercased()).jpg"
                try await RallyUpBackend.client.storage
                    .from("racket-photos")
                    .upload(
                        path,
                        data: data,
                        options: FileOptions(cacheControl: "31536000", contentType: "image/jpeg", upsert: true)
                    )
                photoPath = path
            }
            racketRows.append(SupabaseRacketRecord(
                id: racket.id,
                user_id: draft.userID,
                position: index + 1,
                name: racket.name,
                photo_path: photoPath
            ))
        }

        let profileUpdate = SupabaseProfileUpdate(
            display_name: draft.displayName,
            skill_level: draft.skillLevel.rawValue,
            home_area: draft.homeArea,
            availability_summary: draft.availabilitySummary,
            avatar_path: avatarPath,
            player_strengths: draft.strengths.map(\.rawValue)
        )
        let profileExists = try? await RallyUpBackend.client
            .from("profiles")
            .select("user_id")
            .eq("user_id", value: draft.userID.uuidString)
            .single()
            .execute()
        if profileExists != nil {
            try await RallyUpBackend.client
                .from("profiles")
                .update(profileUpdate)
                .eq("user_id", value: draft.userID.uuidString)
                .execute()
        } else {
            let profile = SupabaseProfileRecord(
                user_id: draft.userID,
                display_name: draft.displayName,
                skill_level: draft.skillLevel.rawValue,
                home_area: draft.homeArea,
                availability_summary: draft.availabilitySummary,
                avatar_path: avatarPath,
                player_strengths: draft.strengths.map(\.rawValue),
                profile_rackets: nil
            )
            try await RallyUpBackend.client.from("profiles").insert(profile).execute()
        }
        if !racketRows.isEmpty {
            try await RallyUpBackend.client.from("profile_rackets").upsert(racketRows).execute()
        }
        return try await fetchProfile(userID: draft.userID, email: draft.email)
    }

    private func localAccount(from profile: SupabaseProfileRecord, email: String) async throws -> LocalAccount {
        let avatarURL = await signedPhotoURL(path: profile.avatar_path, bucket: "profile-photos")
        let strengths = profile.player_strengths.compactMap(PlayerStrength.init(rawValue:))
        let rackets = try await materializedRackets(from: profile.profile_rackets ?? [])
        return LocalAccount(
            id: profile.user_id,
            displayName: profile.display_name,
            email: email,
            skillLevel: SkillLevel(rawValue: profile.skill_level) ?? .intermediate,
            homeArea: profile.home_area,
            availabilitySummary: profile.availability_summary,
            avatarURL: avatarURL,
            strengths: strengths,
            rackets: rackets
        )
    }

    private func localAccountFromAuthUser(_ user: User, email: String) -> LocalAccount {
        let displayName = metadataString("display_name", from: user)
            ?? email.split(separator: "@").first.map(String.init)
            ?? "Player"
        let skillLevel = SkillLevel(rawValue: metadataString("skill_level", from: user) ?? "intermediate") ?? .intermediate
        return LocalAccount(
            id: user.id,
            displayName: String(displayName.prefix(60)),
            email: email,
            skillLevel: skillLevel,
            homeArea: metadataString("home_area", from: user),
            availabilitySummary: metadataString("availability_summary", from: user) ?? "Availability not set",
            avatarURL: nil,
            strengths: [],
            rackets: []
        )
    }

    private func playerProfile(from profile: SupabaseProfileRecord) async throws -> PlayerProfile {
        let avatarURL = await signedPhotoURL(path: profile.avatar_path, bucket: "profile-photos")
        let strengths = profile.player_strengths.compactMap(PlayerStrength.init(rawValue:))
        let rackets = try await materializedRackets(from: profile.profile_rackets ?? [])
        let initials = profile.display_name
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
        return PlayerProfile(
            id: profile.user_id,
            displayName: profile.display_name,
            initials: initials,
            skillLevel: SkillLevel(rawValue: profile.skill_level) ?? .intermediate,
            homeArea: profile.home_area,
            availabilitySummary: profile.availability_summary,
            avatarURL: avatarURL,
            strengths: strengths,
            rackets: rackets
        )
    }

    private func signedPhotoURL(path: String?, bucket: String) async -> String? {
        guard let path else { return nil }
        do {
            let url = try await RallyUpBackend.client.storage
                .from(bucket)
                .createSignedURL(path: path, expiresIn: 86_400)
            return url.absoluteString
        } catch {
            return nil
        }
    }

    private func materializedRackets(from records: [SupabaseRacketRecord]) async throws -> [PlayerRacket] {
        var rackets: [PlayerRacket] = []
        for record in records.sorted(by: { $0.position < $1.position }).prefix(RacketLimits.maximumRackets) {
            let photoURL: String?
            if let path = record.photo_path {
                do {
                    let url = try await RallyUpBackend.client.storage
                        .from("racket-photos")
                        .createSignedURL(path: path, expiresIn: 86_400)
                    photoURL = url.absoluteString
                } catch {
                    photoURL = nil
                }
            } else {
                photoURL = nil
            }
            rackets.append(PlayerRacket(id: record.id, name: record.name, photoURL: photoURL))
        }
        return rackets
    }

    private func metadataString(_ key: String, from user: User) -> String? {
        guard case let .string(value)? = user.userMetadata[key] else { return nil }
        return value
    }

    private func pendingSignupKey(for email: String) -> String {
        "rallyup.pending-signup.\(email.lowercased())"
    }

    private func savePendingSignup(_ draft: PendingSignupDraft) throws {
        let data = try JSONEncoder().encode(draft)
        defaults.set(data, forKey: pendingSignupKey(for: draft.email))
    }

    private func pendingSignup(for email: String) -> PendingSignupDraft? {
        guard let data = defaults.data(forKey: pendingSignupKey(for: email)) else { return nil }
        return try? JSONDecoder().decode(PendingSignupDraft.self, from: data)
    }

    private func clearPendingSignup(for email: String) {
        defaults.removeObject(forKey: pendingSignupKey(for: email))
    }

    private func tryLocalSignIn(email: String, password: String) -> LocalAccount? {
        guard let stored = credential(for: email),
              let attemptedDigest = try? passwordDigest(password, salt: stored.passwordSalt),
              constantTimeEqual(attemptedDigest, stored.passwordDigest) else { return nil }
        return stored.account
    }

    private func restoreSupabaseSession() async {
        guard let session = try? await RallyUpBackend.client.auth.session else { return }
        let email = session.user.email?.lowercased() ?? ""
        let pending = pendingSignup(for: email)
        do {
            if let pending {
                currentAccount = try await publishProfile(from: pending)
                clearPendingSignup(for: email)
                RacketPhotoStore.remove(pending.localPhotoURLs)
            } else {
                currentAccount = try await fetchProfile(userID: session.user.id, email: email)
            }
            defaults.removeObject(forKey: activeEmailKey)
            isDemoMode = false
            isCloudBacked = true
        } catch {
            // Keep the signed-out UI available if a profile needs a retry.
        }
    }

    private func credential(for email: String) -> LocalAccountCredential? {
        let identityQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: email,
        ]
        var query = identityQuery
        query.merge([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]) { _, newValue in newValue }
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        if let credential = try? JSONDecoder().decode(LocalAccountCredential.self, from: data) {
            return credential
        }
        guard let legacy = try? JSONDecoder().decode(LegacyLocalAccountCredential.self, from: data),
              let salt = try? makePasswordSalt(),
              let digest = try? passwordDigest(legacy.password, salt: salt) else { return nil }
        let upgraded = LocalAccountCredential(account: legacy.account, passwordSalt: salt, passwordDigest: digest)
        guard let upgradedData = try? JSONEncoder().encode(upgraded) else { return nil }
        let update = [kSecValueData as String: upgradedData]
        guard SecItemUpdate(identityQuery as CFDictionary, update as CFDictionary) == errSecSuccess else { return nil }
        return upgraded
    }

    private func makePasswordSalt() throws -> Data {
        var salt = Data(count: 16)
        let status = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, bytes.baseAddress!)
        }
        guard status == errSecSuccess else { throw AccountAuthError.keychainFailure }
        return salt
    }

    private func passwordDigest(_ password: String, salt: Data) throws -> Data {
        var digest = Data(count: 32)
        let passwordLength = password.utf8.count
        let saltLength = salt.count
        let digestLength = digest.count
        let status = password.withCString { passwordPointer in
            salt.withUnsafeBytes { saltBytes in
                digest.withUnsafeMutableBytes { digestBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordPointer,
                        passwordLength,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress!,
                        saltLength,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        passwordDerivationRounds,
                        digestBytes.bindMemory(to: UInt8.self).baseAddress!,
                        digestLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw AccountAuthError.keychainFailure }
        return digest
    }

    private func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for (leftByte, rightByte) in zip(lhs, rhs) {
            difference |= leftByte ^ rightByte
        }
        return difference == 0
    }
}

@MainActor
final class RallyStore: ObservableObject {
    @Published private(set) var players = DemoData.players
    @Published private(set) var courts = DemoData.courts
    @Published private(set) var matches: [MatchRecord]
    @Published private(set) var scoreHistory: [UUID: [TennisScore]] = [:]
    @Published private(set) var currentUser: PlayerProfile
    @Published private(set) var isSyncing = false
    @Published private(set) var syncError: String?

    private let defaults: UserDefaults
    private let matchesKey = "rallyup.demo.matches.v1"
    private let profileKey = "rallyup.demo.profile.v1"
    private var activeAccountID: UUID?
    private var cloudBacked = false
    private var remoteScoreRevisions: [UUID: Int64] = [:]
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeTask: Task<Void, Never>?

    var isCloudBacked: Bool { cloudBacked }

    private var currentMatchesKey: String {
        activeAccountID.map { "rallyup.account.\($0.uuidString).matches.v1" } ?? matchesKey
    }

    private var currentProfileKey: String {
        activeAccountID.map { "rallyup.account.\($0.uuidString).profile.v1" } ?? profileKey
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentUser = DemoData.currentUser
        matches = DemoData.matches
        if let savedProfile = defaults.data(forKey: currentProfileKey),
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: savedProfile) {
            currentUser = decoded
        } else {
            currentUser = DemoData.currentUser
        }
        if let saved = defaults.data(forKey: currentMatchesKey),
           let decoded = try? JSONDecoder().decode([MatchRecord].self, from: saved) {
            matches = decoded
        } else {
            matches = DemoData.matches
        }
    }

    func activate(account: LocalAccount?, cloudBacked: Bool = false) {
        self.cloudBacked = cloudBacked
        guard activeAccountID != account?.id else {
            if cloudBacked { Task { await refreshRemoteMatches() } }
            return
        }
        activeAccountID = account?.id
        players = cloudBacked ? [] : DemoData.players
        courts = cloudBacked ? [] : DemoData.courts

        if let account {
            if let savedProfile = defaults.data(forKey: currentProfileKey),
               let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: savedProfile) {
                var profile = decoded
                profile.rackets = account.rackets
                profile.racketPhotoURLs = nil
                profile.avatarURL = account.avatarURL
                profile.strengths = account.strengths
                currentUser = profile
            } else {
                currentUser = PlayerProfile(
                    id: account.id,
                    displayName: account.displayName,
                    initials: account.displayName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased(),
                    skillLevel: account.skillLevel,
                    approximateDistanceKm: 0,
                    homeArea: account.homeArea,
                    availabilitySummary: account.availabilitySummary,
                    avatarURL: account.avatarURL,
                    strengths: account.strengths,
                    rackets: account.rackets
                )
            }
            if let saved = defaults.data(forKey: currentMatchesKey),
               let decoded = try? JSONDecoder().decode([MatchRecord].self, from: saved) {
                matches = decoded
            } else if cloudBacked {
                matches = []
            } else {
                matches = demoMatches(for: currentUser)
            }
        } else {
            if let savedProfile = defaults.data(forKey: currentProfileKey),
               let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: savedProfile) {
                currentUser = decoded
            } else {
                currentUser = DemoData.currentUser
            }
            if let saved = defaults.data(forKey: currentMatchesKey),
               let decoded = try? JSONDecoder().decode([MatchRecord].self, from: saved) {
                matches = decoded
            } else {
                matches = DemoData.matches
            }
        }
        scoreHistory = [:]
        remoteScoreRevisions = [:]
        syncError = nil
        realtimeTask?.cancel()
        if let realtimeChannel {
            Task { await RallyUpBackend.client.removeChannel(realtimeChannel) }
            self.realtimeChannel = nil
        }
        if cloudBacked {
            Task {
                await refreshRemoteCourts()
                await refreshRemoteMatches()
                await startRealtimeMatchSync()
            }
        }
    }

    private func startRealtimeMatchSync() async {
        guard cloudBacked else { return }
        let channel = RallyUpBackend.client.channel("rallyup-match-scores")
        let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "match_live_scores")
        do {
            try await channel.subscribeWithError()
            realtimeChannel = channel
            realtimeTask = Task { [weak self] in
                for await _ in changes {
                    guard let self else { return }
                    await self.refreshRemoteMatches()
                }
            }
        } catch {
            syncError = "Live score sync is unavailable right now."
        }
    }

    private func refreshRemoteCourts() async {
        guard cloudBacked else { return }
        do {
            let rows: [SupabaseCourtRecord] = try await RallyUpBackend.client
                .from("courts")
                .select("id,name,address,surface,setting,latitude,longitude")
                .eq("is_active", value: true)
                .order("area", ascending: true)
                .order("name", ascending: true)
                .execute()
                .value
            courts = rows.map {
                TennisCourt(
                    id: $0.id,
                    name: $0.name,
                    address: $0.address,
                    surface: $0.surface,
                    setting: $0.setting,
                    latitude: $0.latitude,
                    longitude: $0.longitude
                )
            }
        } catch {
            syncError = "Courts couldn’t be refreshed right now."
        }
    }

    func refreshRemoteMatches() async {
        guard cloudBacked, let accountID = activeAccountID else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let rows: [SupabaseMatchRecord] = try await RallyUpBackend.client
                .from("matches")
                .select("id,created_by,court_id,scheduled_at,match_type,match_format,status,note,courts(id,name,address,surface,setting,latitude,longitude),match_participants(match_id,player_id,side,team_slot,invite_response)")
                .order("scheduled_at", ascending: true)
                .execute()
                .value

            let scoreRows: [SupabaseLiveScoreRecord] = (try? await RallyUpBackend.client
                .from("match_live_scores")
                .select("match_id,score_state,revision")
                .execute()
                .value) ?? []
            remoteScoreRevisions = Dictionary(uniqueKeysWithValues: scoreRows.map { ($0.match_id, $0.revision) })
            let scoreByMatch = Dictionary(uniqueKeysWithValues: scoreRows.map { ($0.match_id, $0.score_state) })
            let participantIDs = Array(Set(rows.flatMap { $0.match_participants.map(\.player_id) }))
            let profileRows: [SupabaseParticipantProfileName] = (try? await RallyUpBackend.client
                .from("profiles")
                .select("user_id,display_name")
                .in("user_id", values: participantIDs.map(\.uuidString))
                .execute()
                .value) ?? []
            let profileNames = Dictionary(uniqueKeysWithValues: profileRows.map { ($0.user_id, $0.display_name) })

            var remoteCourts: [TennisCourt] = []
            var remoteMatches: [MatchRecord] = []
            for row in rows {
                guard let court = row.courts else { continue }
                let tennisCourt = TennisCourt(
                    id: court.id,
                    name: court.name,
                    address: court.address,
                    surface: court.surface,
                    setting: court.setting,
                    latitude: court.latitude,
                    longitude: court.longitude
                )
                remoteCourts.append(tennisCourt)
                let participants = row.match_participants
                    .filter { $0.invite_response != "declined" }
                    .sorted { $0.team_slot < $1.team_slot }
                    .map { participant in
                        MatchParticipant(
                            playerID: participant.player_id,
                            displayName: participant.player_id == accountID
                                ? currentUser.displayName
                                : profileNames[participant.player_id]
                                    ?? players.first(where: { $0.id == participant.player_id })?.displayName
                                    ?? "Player",
                            side: participant.side == "side_one" ? .you : .opponent
                        )
                    }
                guard !participants.isEmpty else { continue }
                let status = remoteStatus(
                    rawValue: row.status,
                    createdBy: row.created_by,
                    accountID: accountID,
                    participants: row.match_participants
                )
                remoteMatches.append(MatchRecord(
                    id: row.id,
                    participants: participants,
                    scheduledAt: row.scheduled_at,
                    court: tennisCourt,
                    matchType: MatchType(rawValue: row.match_type) ?? .singles,
                    format: matchFormat(rawValue: row.match_format),
                    status: status,
                    score: scoreByMatch[row.id] ?? TennisScore(),
                    note: row.note
                ))
            }
            courts = remoteCourts.isEmpty ? courts : remoteCourts
            matches = remoteMatches
            persist()
            syncError = nil
        } catch {
            syncError = "Matches couldn’t be refreshed. Showing the last saved copy."
        }
    }

    private func remoteStatus(
        rawValue: String,
        createdBy: UUID,
        accountID: UUID,
        participants: [SupabaseMatchParticipantRecord]
    ) -> MatchStatus {
        if rawValue == "invite_pending" {
            return createdBy == accountID ? .inviteSent : .invited
        }
        switch rawValue {
        case "scheduled": return .scheduled
        case "in_progress": return .inProgress
        case "awaiting_confirmation": return .awaitingConfirmation
        case "completed": return .completed
        case "cancelled": return .cancelled
        case "disputed": return .disputed
        default: return .scheduled
        }
    }

    private func matchFormat(rawValue: String) -> MatchFormat {
        switch rawValue {
        case "one_set": return .oneSet
        case "pro_set": return .proSet
        default: return .bestOfThree
        }
    }

    private func remoteFormatValue(_ format: MatchFormat) -> String {
        switch format {
        case .oneSet: return "one_set"
        case .proSet: return "pro_set"
        case .bestOfThree: return "best_of_three"
        }
    }

    private func reportSyncError(_ error: Error) {
        syncError = error.localizedDescription
    }

    private func sendMatchPush(matchID: UUID, event: String) async {
        let request = MatchPushRequest(match_id: matchID, event: event)
        try? await RallyUpBackend.client.functions.invoke(
            "send-match-push",
            options: FunctionInvokeOptions(body: request)
        )
    }

    func setDiscoverablePlayers(_ remotePlayers: [PlayerProfile]) {
        players = remotePlayers
    }

    func removePlayer(_ playerID: UUID) {
        players.removeAll { $0.id == playerID }
    }

    var upcomingMatches: [MatchRecord] {
        matches
            .filter { $0.status == .scheduled || $0.status == .inProgress || $0.status == .awaitingConfirmation }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var invitations: [MatchRecord] {
        matches.filter { $0.status == .invited }.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var sentInvites: [MatchRecord] {
        matches.filter { $0.status == .inviteSent }.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var history: [MatchRecord] {
        matches
            .filter { $0.status == .completed }
            .sorted { $0.scheduledAt > $1.scheduledAt }
    }

    func teamProfiles(in match: MatchRecord, on side: PlayerSide) -> [PlayerProfile] {
        match.participants(on: side).map(profile(for:))
    }

    func profile(for participant: MatchParticipant) -> PlayerProfile {
        if participant.playerID == currentUser.id { return currentUser }
        if let player = players.first(where: { $0.id == participant.playerID }) { return player }

        let initials = participant.displayName
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
        return PlayerProfile(
            id: participant.playerID,
            displayName: participant.displayName,
            initials: initials,
            skillLevel: .intermediate
        )
    }

    var wins: Int { history.filter { $0.score.winner == .you }.count }
    var losses: Int { history.filter { $0.score.winner == .opponent }.count }
    var currentWinStreak: Int { history.prefix(while: { $0.score.winner == .you }).count }
    var winRate: Int {
        let total = wins + losses
        return total == 0 ? 0 : Int((Double(wins) / Double(total) * 100).rounded())
    }

    func makeInvite(
        for player: PlayerProfile,
        date: Date,
        court: TennisCourt,
        matchType: MatchType = .singles,
        format: MatchFormat,
        note: String?,
        teammate: PlayerProfile? = nil,
        opponentPartner: PlayerProfile? = nil
    ) {
        if cloudBacked {
            Task {
                do {
                    let opponentIDs = [player.id] + (opponentPartner.map { [$0.id] } ?? [])
                    var params: [String: AnyJSON] = [
                        "p_court_id": .string(court.id.uuidString),
                        "p_scheduled_at": .string(ISO8601DateFormatter().string(from: date)),
                        "p_match_type": .string(matchType.rawValue),
                        "p_match_format": .string(remoteFormatValue(format)),
                        "p_opponent_ids": .array(opponentIDs.map { .string($0.uuidString) }),
                        "p_note": note.map(AnyJSON.string) ?? .null,
                    ]
                    params["p_teammate_id"] = teammate.map { .string($0.id.uuidString) } ?? .null
                    let matchID: UUID = try await RallyUpBackend.client.rpc("create_match_invite", params: params).execute().value
                    await sendMatchPush(matchID: matchID, event: "invite")
                    await refreshRemoteMatches()
                } catch {
                    reportSyncError(error)
                }
            }
            return
        }
        guard let participants = makeParticipants(
            matchType: matchType,
            teammate: teammate,
            opponents: [player] + (opponentPartner.map { [$0] } ?? [])
        ) else { return }
        let match = MatchRecord(
            participants: participants,
            scheduledAt: date,
            court: court,
            matchType: matchType,
            format: format,
            status: .inviteSent,
            note: note
        )
        matches.append(match)
        persist()
    }

    func createRemoteManualMatch(
        scheduledAt: Date,
        courtName: String,
        matchType: MatchType,
        format: MatchFormat,
        teammateName: String?,
        opponentName: String,
        opponentPartnerName: String?,
        note: String?,
        startsImmediately: Bool
    ) async throws -> UUID {
        guard cloudBacked else { throw MatchSyncError.courtNotFound(courtName) }
        guard let court = courts.first(where: { $0.name.caseInsensitiveCompare(courtName.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame }) else {
            throw MatchSyncError.courtNotFound(courtName)
        }
        func playerID(named name: String) throws -> UUID {
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let player = players.first(where: { $0.displayName.caseInsensitiveCompare(cleanName) == .orderedSame }) else {
                throw MatchSyncError.playerNotFound(cleanName)
            }
            return player.id
        }
        let opponentIDs = try [playerID(named: opponentName)] + (opponentPartnerName.map { [try playerID(named: $0)] } ?? [])
        let teammateID = try teammateName.map { try playerID(named: $0) }
        let params: [String: AnyJSON] = [
            "p_court_id": .string(court.id.uuidString),
            "p_scheduled_at": .string(ISO8601DateFormatter().string(from: scheduledAt)),
            "p_match_type": .string(matchType.rawValue),
            "p_match_format": .string(remoteFormatValue(format)),
            "p_opponent_ids": .array(opponentIDs.map { .string($0.uuidString) }),
            "p_teammate_id": teammateID.map { .string($0.uuidString) } ?? .null,
            "p_note": note.map(AnyJSON.string) ?? .null,
            "p_start_immediately": .bool(startsImmediately),
        ]
        let id: UUID = try await RallyUpBackend.client.rpc("create_manual_match", params: params).execute().value
        await refreshRemoteMatches()
        return id
    }

    @discardableResult
    func createManualMatch(
        scheduledAt: Date,
        courtName: String,
        courtAddress: String,
        surface: String,
        setting: String,
        matchType: MatchType,
        format: MatchFormat,
        teammateName: String?,
        opponentName: String,
        opponentPartnerName: String?,
        note: String?,
        startsImmediately: Bool
    ) -> UUID? {
        let cleanCourtName = courtName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOpponent = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCourtName.isEmpty, !cleanOpponent.isEmpty else { return nil }

        let cleanTeammate = teammateName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOpponentPartner = opponentPartnerName?.trimmingCharacters(in: .whitespacesAndNewlines)
        var participants = [
            MatchParticipant(playerID: currentUser.id, displayName: currentUser.displayName, side: .you)
        ]

        if matchType == .doubles {
            guard let cleanTeammate, !cleanTeammate.isEmpty,
                  let cleanOpponentPartner, !cleanOpponentPartner.isEmpty else { return nil }
            participants.append(MatchParticipant(playerID: UUID(), displayName: cleanTeammate, side: .you))
        }

        participants.append(MatchParticipant(playerID: UUID(), displayName: cleanOpponent, side: .opponent))
        if matchType == .doubles, let cleanOpponentPartner {
            participants.append(MatchParticipant(playerID: UUID(), displayName: cleanOpponentPartner, side: .opponent))
        }

        let court = TennisCourt(
            name: cleanCourtName,
            address: courtAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Address not provided"
                : courtAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            surface: surface,
            setting: setting,
            latitude: 0,
            longitude: 0
        )
        let cleanNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let match = MatchRecord(
            participants: participants,
            scheduledAt: startsImmediately ? .now : scheduledAt,
            court: court,
            matchType: matchType,
            format: format,
            status: startsImmediately ? .inProgress : .scheduled,
            note: cleanNote?.isEmpty == true ? nil : cleanNote
        )

        matches.append(match)
        persist()
        return match.id
    }

    @discardableResult
    func updateScheduledMatch(
        _ matchID: UUID,
        scheduledAt: Date,
        court: TennisCourt,
        matchType: MatchType,
        format: MatchFormat,
        teammate: PlayerProfile?,
        opponent: PlayerProfile,
        opponentPartner: PlayerProfile?,
        note: String?
    ) -> Bool {
        if cloudBacked {
            guard matchType == .singles || (teammate != nil && opponentPartner != nil) else { return false }
            Task {
                do {
                    let opponents = [opponent.id] + (opponentPartner.map { [$0.id] } ?? [])
                    let params: [String: AnyJSON] = [
                        "p_match_id": .string(matchID.uuidString),
                        "p_court_id": .string(court.id.uuidString),
                        "p_scheduled_at": .string(ISO8601DateFormatter().string(from: scheduledAt)),
                        "p_match_type": .string(matchType.rawValue),
                        "p_match_format": .string(remoteFormatValue(format)),
                        "p_opponent_ids": .array(opponents.map { .string($0.uuidString) }),
                        "p_teammate_id": teammate.map { .string($0.id.uuidString) } ?? .null,
                        "p_note": note.map(AnyJSON.string) ?? .null,
                    ]
                    _ = try await RallyUpBackend.client.rpc("update_scheduled_match", params: params).execute()
                    await refreshRemoteMatches()
                } catch { reportSyncError(error) }
            }
            return true
        }
        guard let index = matches.firstIndex(where: { $0.id == matchID }),
              matches[index].status == .scheduled,
              let participants = makeParticipants(
                  matchType: matchType,
                  teammate: teammate,
                  opponents: [opponent] + (opponentPartner.map { [$0] } ?? [])
              ) else { return false }

        matches[index].scheduledAt = scheduledAt
        matches[index].court = court
        matches[index].matchType = matchType
        matches[index].format = format
        matches[index].participants = participants
        matches[index].note = note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true
            ? nil
            : note?.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
        return true
    }

    func updateProfile(displayName: String, skillLevel: SkillLevel, availabilitySummary: String, homeArea: String? = nil) {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        currentUser.displayName = cleanName
        currentUser.initials = cleanName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
        currentUser.skillLevel = skillLevel
        currentUser.homeArea = homeArea
        currentUser.availabilitySummary = availabilitySummary
        if let data = try? JSONEncoder().encode(currentUser) { defaults.set(data, forKey: currentProfileKey) }
        for matchIndex in matches.indices {
            if let participantIndex = matches[matchIndex].participants.firstIndex(where: { $0.playerID == currentUser.id }) {
                matches[matchIndex].participants[participantIndex].displayName = currentUser.displayName
            }
        }
        persist()
    }

    func respondToInvite(_ matchID: UUID, accept: Bool) {
        if cloudBacked {
            Task {
                do {
                    let params: [String: AnyJSON] = [
                        "p_match_id": .string(matchID.uuidString),
                        "p_accept": .bool(accept),
                    ]
                    _ = try await RallyUpBackend.client.rpc(
                        "respond_to_match_invite",
                        params: params
                    ).execute()
                    await sendMatchPush(matchID: matchID, event: "response")
                    await refreshRemoteMatches()
                } catch { reportSyncError(error) }
            }
            return
        }
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        matches[index].status = accept ? .scheduled : .cancelled
        persist()
    }

    func cancelSentInvite(_ matchID: UUID) {
        if cloudBacked {
            Task {
                do {
                    let params: [String: AnyJSON] = ["p_match_id": .string(matchID.uuidString)]
                    _ = try await RallyUpBackend.client.rpc(
                        "cancel_match",
                        params: params
                    ).execute()
                    await refreshRemoteMatches()
                } catch { reportSyncError(error) }
            }
            return
        }
        guard let index = matches.firstIndex(where: { $0.id == matchID }), matches[index].status == .inviteSent else { return }
        matches[index].status = .cancelled
        persist()
    }

    func startMatch(_ matchID: UUID) {
        if cloudBacked {
            Task {
                do {
                    let params: [String: AnyJSON] = ["p_match_id": .string(matchID.uuidString)]
                    _ = try await RallyUpBackend.client.rpc(
                        "start_match",
                        params: params
                    ).execute()
                    await refreshRemoteMatches()
                } catch { reportSyncError(error) }
            }
            return
        }
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        matches[index].status = .inProgress
        matches[index].score = TennisScore()
        scoreHistory[matchID] = []
        persist()
    }

    func awardPoint(_ matchID: UUID, to side: PlayerSide) {
        guard let index = matches.firstIndex(where: { $0.id == matchID }), matches[index].status == .inProgress else { return }
        scoreHistory[matchID, default: []].append(matches[index].score)
        matches[index].score.awardPoint(to: side, format: matches[index].format)
        persist()
        if cloudBacked {
            let score = matches[index].score
            let revision = remoteScoreRevisions[matchID] ?? 0
            Task {
                do {
                    let nextRevision = try await saveRemoteScore(matchID: matchID, score: score, revision: revision)
                    remoteScoreRevisions[matchID] = nextRevision
                    if score.isComplete { await finishRemoteMatch(matchID, score: score) }
                } catch {
                    reportSyncError(error)
                    await refreshRemoteMatches()
                }
            }
        }
    }

    func undoPoint(_ matchID: UUID) {
        guard let previous = scoreHistory[matchID]?.popLast(),
              let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        matches[index].score = previous
        persist()
    }

    func finishMatch(_ matchID: UUID) {
        guard let index = matches.firstIndex(where: { $0.id == matchID }), matches[index].score.isComplete else { return }
        matches[index].status = .awaitingConfirmation
        matches[index].resultConfirmedBy.insert(currentUser.id)
        persist()
        if cloudBacked {
            let score = matches[index].score
            Task { await finishRemoteMatch(matchID, score: score) }
        }
    }

    func confirmResult(_ matchID: UUID) {
        if cloudBacked {
            Task {
                do {
                    let params: [String: AnyJSON] = [
                        "p_match_id": .string(matchID.uuidString),
                        "p_accept": .bool(true),
                    ]
                    _ = try await RallyUpBackend.client.rpc(
                        "confirm_match_result",
                        params: params
                    ).execute()
                    await refreshRemoteMatches()
                } catch { reportSyncError(error) }
            }
            return
        }
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        matches[index].resultConfirmedBy.insert(currentUser.id)
        matches[index].status = .completed
        persist()
    }

    private func saveRemoteScore(matchID: UUID, score: TennisScore, revision: Int64) async throws -> Int64 {
        let data = try JSONEncoder().encode(score)
        let scoreState = try JSONDecoder().decode(AnyJSON.self, from: data)
        let params: [String: AnyJSON] = [
            "p_match_id": .string(matchID.uuidString),
            "p_expected_revision": .integer(Int(revision)),
            "p_score_state": scoreState,
        ]
        let response: Int64 = try await RallyUpBackend.client.rpc(
            "save_live_score",
            params: params
        ).execute().value
        return response
    }

    private func finishRemoteMatch(_ matchID: UUID, score: TennisScore) async {
        do {
            let sets: [AnyJSON] = score.completedSets.map { set in
                .object([
                    "side_one_games": .integer(set.you),
                    "side_two_games": .integer(set.opponent),
                    "side_one_tiebreak_points": .null,
                    "side_two_tiebreak_points": .null,
                ])
            }
            let params: [String: AnyJSON] = [
                "p_match_id": .string(matchID.uuidString),
                "p_winner_side": .string(score.winner == .you ? "side_one" : "side_two"),
                "p_sets": .array(sets),
            ]
            _ = try await RallyUpBackend.client.rpc(
                "submit_match_result",
                params: params
            ).execute()
            await refreshRemoteMatches()
        } catch { reportSyncError(error) }
    }

    func resetDemoData() {
        if activeAccountID == nil {
            currentUser = DemoData.currentUser
        }
        if let data = try? JSONEncoder().encode(currentUser) { defaults.set(data, forKey: currentProfileKey) }
        matches = activeAccountID == nil ? DemoData.matches : demoMatches(for: currentUser)
        scoreHistory = [:]
        persist()
    }

    private func demoMatches(for user: PlayerProfile) -> [MatchRecord] {
        DemoData.matches.map { match in
            var personalizedMatch = match
            for index in personalizedMatch.participants.indices
            where personalizedMatch.participants[index].playerID == DemoData.currentUser.id {
                personalizedMatch.participants[index].playerID = user.id
                personalizedMatch.participants[index].displayName = user.displayName
            }
            if personalizedMatch.resultConfirmedBy.remove(DemoData.currentUser.id) != nil {
                personalizedMatch.resultConfirmedBy.insert(user.id)
            }
            return personalizedMatch
        }
    }

    private func makeParticipants(
        matchType: MatchType,
        teammate: PlayerProfile?,
        opponents: [PlayerProfile]
    ) -> [MatchParticipant]? {
        let expectedOpponents = matchType == .singles ? 1 : 2
        guard opponents.count == expectedOpponents,
              (matchType == .doubles) == (teammate != nil) else { return nil }

        var lineup: [(PlayerProfile, PlayerSide)] = [(currentUser, .you)]
        if let teammate { lineup.append((teammate, .you)) }
        lineup.append(contentsOf: opponents.map { ($0, .opponent) })

        let ids = lineup.map { $0.0.id }
        guard Set(ids).count == ids.count else { return nil }

        return lineup.map { player, side in
            MatchParticipant(playerID: player.id, displayName: player.displayName, side: side)
        }
    }

    private func persist() {
        guard let encoded = try? JSONEncoder().encode(matches) else { return }
        defaults.set(encoded, forKey: currentMatchesKey)
    }
}

enum DemoData {
    private static func id(_ value: String) -> UUID { UUID(uuidString: value)! }

    static let currentUser = PlayerProfile(
        id: id("00000000-0000-0000-0000-000000000001"),
        displayName: "Eric Rotaquio",
        initials: "ER",
        skillLevel: .intermediate,
        approximateDistanceKm: 0,
        homeArea: "Metro Manila",
        wins: 15,
        losses: 9,
        availabilitySummary: "Usually available weekends"
    )

    static let players = [
        PlayerProfile(id: id("00000000-0000-0000-0000-000000000011"), displayName: "Jamie Cruz", initials: "JC", skillLevel: .intermediate, approximateDistanceKm: 2.4, wins: 18, losses: 12, availabilitySummary: "Available Saturday", compatibilityPercent: 94),
        PlayerProfile(id: id("00000000-0000-0000-0000-000000000012"), displayName: "Miguel Santos", initials: "MS", skillLevel: .intermediate, approximateDistanceKm: 4.1, wins: 21, losses: 16, availabilitySummary: "Available Thursday", compatibilityPercent: 89),
        PlayerProfile(id: id("00000000-0000-0000-0000-000000000013"), displayName: "Sofia Lim", initials: "SL", skillLevel: .intermediate, approximateDistanceKm: 3.2, wins: 17, losses: 10, availabilitySummary: "Available Sunday", compatibilityPercent: 86),
        PlayerProfile(id: id("00000000-0000-0000-0000-000000000014"), displayName: "Alex Reyes", initials: "AR", skillLevel: .advanced, approximateDistanceKm: 5.8, wins: 32, losses: 14, availabilitySummary: "Available Saturday", compatibilityPercent: 82),
    ]

    static let courts = [
        TennisCourt(id: id("10000000-0000-0000-0000-000000000001"), name: "BGC Tennis Club", address: "Bonifacio Global City", surface: "Hard", setting: "Outdoor", latitude: 14.5514, longitude: 121.0465),
        TennisCourt(id: id("10000000-0000-0000-0000-000000000002"), name: "Makati Sports Club", address: "Makati City", surface: "Hard", setting: "Indoor / Outdoor", latitude: 14.5590, longitude: 121.0196),
        TennisCourt(id: id("10000000-0000-0000-0000-000000000003"), name: "PhilSports Tennis Courts", address: "Pasig City", surface: "Hard", setting: "Outdoor", latitude: 14.5720, longitude: 121.0640),
    ]

    static var matches: [MatchRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let saturday = calendar.date(byAdding: .day, value: 6, to: today) ?? .now
        let nextFriday = calendar.date(byAdding: .day, value: 12, to: today) ?? .now
        let lastWeekend = calendar.date(byAdding: .day, value: -2, to: today) ?? .now
        let jamie = players[0]
        let miguel = players[1]
        let sofia = players[2]

        let fixedMatches = [
            MatchRecord(
                id: id("20000000-0000-0000-0000-000000000001"),
                participants: participants(with: jamie),
                scheduledAt: date(saturday, hour: 19),
                court: courts[0],
                format: .bestOfThree,
                status: .scheduled
            ),
            MatchRecord(
                id: id("20000000-0000-0000-0000-000000000002"),
                participants: participants(with: miguel),
                scheduledAt: date(nextFriday, hour: 20),
                court: courts[1],
                format: .bestOfThree,
                status: .scheduled
            ),
            MatchRecord(
                id: id("20000000-0000-0000-0000-000000000003"),
                participants: participants(with: sofia),
                scheduledAt: date(calendar.date(byAdding: .day, value: 1, to: today) ?? .now, hour: 18),
                court: courts[2],
                format: .bestOfThree,
                status: .invited,
                note: "Let's get a match in this weekend."
            ),
        ]
        let historicalMatches = (0..<24).map { index -> MatchRecord in
            let opponent = players[index % players.count]
            let isWin = index < 3 || index >= 12
            let matchDay = Calendar.current.date(byAdding: .day, value: -(2 + index * 7), to: today) ?? lastWeekend
            let sets = isWin
                ? [SetScore(you: 6, opponent: 4), SetScore(you: 3, opponent: 6), SetScore(you: 6, opponent: 2)]
                : [SetScore(you: 3, opponent: 6), SetScore(you: 4, opponent: 6)]
            return MatchRecord(
                id: id("30000000-0000-0000-0000-\(String(format: "%012d", index + 1))"),
                participants: participants(with: opponent),
                scheduledAt: date(matchDay, hour: 16),
                court: courts[index % courts.count],
                format: .bestOfThree,
                status: .completed,
                score: TennisScore(completedSets: sets, winner: isWin ? .you : .opponent),
                resultConfirmedBy: [currentUser.id, opponent.id]
            )
        }
        return fixedMatches + historicalMatches
    }

    private static func participants(with opponent: PlayerProfile) -> [MatchParticipant] {
        [
            MatchParticipant(playerID: currentUser.id, displayName: currentUser.displayName, side: .you),
            MatchParticipant(playerID: opponent.id, displayName: opponent.displayName, side: .opponent),
        ]
    }

    private static func date(_ day: Date, hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}
