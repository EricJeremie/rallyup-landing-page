import RallyUpCore
import PhotosUI
import SwiftUI
import UIKit

enum RallyTab: Hashable {
    case home
    case play
    case matches
    case courts
    case profile
}

struct RallyRootView: View {
    @EnvironmentObject private var store: RallyStore
    @EnvironmentObject private var accountSession: AccountSessionStore
    @State private var selectedTab: RallyTab = .home
    @State private var requestsManualMatch = false

    var body: some View {
        Group {
            if accountSession.isSignedIn {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        HomeView(
                            onSelectTab: { selectedTab = $0 },
                            onStartManualMatch: {
                                selectedTab = .matches
                                requestsManualMatch = true
                            }
                        )
                    }
                        .tabItem { Label("Home", systemImage: selectedTab == .home ? "house.fill" : "house") }
                        .tag(RallyTab.home)

                    NavigationStack { PlayerDiscoveryView() }
                        .tabItem { Label("Play", systemImage: "tennisball") }
                        .tag(RallyTab.play)

                    NavigationStack { MatchesView(manualMatchRequested: $requestsManualMatch) }
                        .tabItem { Label("Matches", systemImage: "calendar") }
                        .badge(store.invitations.count)
                        .tag(RallyTab.matches)

                    NavigationStack { CourtsView() }
                        .tabItem { Label("Courts", systemImage: "map") }
                        .tag(RallyTab.courts)

                    NavigationStack { ProfileView() }
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(RallyTab.profile)
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(RallyTheme.canvas, for: .tabBar)
            } else {
                AccountAccessView()
            }
        }
        .tint(RallyTheme.darkGreen)
        .onAppear {
            store.activate(account: accountSession.currentAccount, cloudBacked: accountSession.isCloudBacked)
            preparePushNotifications()
        }
        .onChange(of: accountSession.currentAccount?.id) { _, _ in
            store.activate(account: accountSession.currentAccount, cloudBacked: accountSession.isCloudBacked)
            preparePushNotifications()
        }
        .onChange(of: accountSession.isSignedIn) { _, _ in
            store.activate(account: accountSession.currentAccount, cloudBacked: accountSession.isCloudBacked)
            preparePushNotifications()
        }
        .onChange(of: accountSession.isCloudBacked) { _, _ in
            store.activate(account: accountSession.currentAccount, cloudBacked: accountSession.isCloudBacked)
            preparePushNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .rallyUpAPNsToken)) { notification in
            guard let token = notification.object as? String else { return }
            accountSession.registerPushToken(token)
        }
        .onOpenURL { url in
            accountSession.handleAuthURL(url)
        }
    }

    private func preparePushNotifications() {
        guard accountSession.isCloudBacked else { return }
        Task { await RallyUpPushNotifications.requestPermissionAndRegister() }
    }
}

private enum AccountAccessMode: Equatable {
    case signIn
    case signUp
}

private enum AccountSignupStep: Int, CaseIterable, Identifiable, Equatable {
    case name
    case profilePhoto
    case credentials
    case level
    case strengths
    case area
    case availability
    case rackets
    case review

    var id: Self { self }

    var isSkippable: Bool {
        self == .profilePhoto || self == .level || self == .strengths || self == .area || self == .availability || self == .rackets
    }

    var title: String {
        switch self {
        case .name: "What should we call you?"
        case .profilePhoto: "Add a profile photo."
        case .credentials: "Secure your account."
        case .level: "How would you rate your game?"
        case .strengths: "What are you strongest at?"
        case .area: "Where do you usually play?"
        case .availability: "When do you like to rally?"
        case .rackets: "Which rackets do you play with?"
        case .review: "Your player card is ready."
        }
    }

    var subtitle: String {
        switch self {
        case .name: "Your name will appear on your player card."
        case .profilePhoto: "Optional · help other players recognize you."
        case .credentials: "Use an email and password to sign in on this device."
        case .level: "Pick the closest fit. You can change this any time."
        case .strengths: "Choose the parts of your game you feel best about."
        case .area: "A broad city helps us suggest nearby matches."
        case .availability: "Choose the windows that usually work for you."
        case .rackets: "Add up to 3 rackets. Name each one so opponents know your setup; photos are optional."
        case .review: "Take a quick look before you step on court."
        }
    }
}

private struct AccountAccessView: View {
    @EnvironmentObject private var accountSession: AccountSessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: AccountAccessMode = .signIn
    @State private var signupStep: AccountSignupStep = .name
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var skillLevel: SkillLevel = .intermediate
    @State private var selectedStrengths: Set<PlayerStrength> = []
    @State private var homeAreaSelection = "Prefer not to share"
    @State private var selectedAvailability: Set<String> = ["Weekends"]
    @State private var profilePhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var isLoadingProfilePhoto = false
    @State private var profilePhotoError: String?
    @State private var errorMessage: String?
    @State private var authInfoMessage: String?
    @State private var showsAuthInfo = false
    @State private var isPasswordVisible = false
    @State private var racketDrafts: [SignupRacketInput] = []
    @State private var loadingRacketIDs: Set<UUID> = []
    @State private var racketPhotoError: String?
    @State private var isSubmitting = false
    @State private var showingPasswordReset = false
    @State private var showingPasswordUpdate = false

    private var isLoadingRacketPhotos: Bool { !loadingRacketIDs.isEmpty }

    private let areaOptions = ["Metro Manila", "Cebu City", "Davao City", "Other / later", "Prefer not to share"]
    private let availabilityOptions = ["Weekdays", "Weekends", "Evenings"]

    private var passwordsMatch: Bool {
        confirmation.isEmpty || password == confirmation
    }

    private var isEmailValid: Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = normalized.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !normalized.contains(where: \.isWhitespace)
    }

    private var canContinueWithAccount: Bool {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanName.isEmpty && cleanName.count <= 60
    }

    private var canContinueWithCredentials: Bool {
        isEmailValid && password.count >= 8 && password == confirmation
    }

    private var canContinueWithRackets: Bool {
        racketDrafts.allSatisfy {
            let name = $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !name.isEmpty && name.count <= 80
        }
    }

    private var canSubmit: Bool {
        if mode == .signIn {
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
        }
        return switch signupStep {
        case .name: canContinueWithAccount
        case .credentials: canContinueWithCredentials
        case .profilePhoto, .level, .strengths, .area, .availability, .review: true
        case .rackets: canContinueWithRackets
        }
    }

    private var homeArea: String? {
        areaOptions.contains(homeAreaSelection) && !["Other / later", "Prefer not to share"].contains(homeAreaSelection)
            ? homeAreaSelection
            : nil
    }

    private var normalizedAvailability: String {
        let selected = availabilityOptions.filter { selectedAvailability.contains($0) }
        return selected.isEmpty ? "Availability not set" : "Usually available " + selected.joined(separator: " · ")
    }

    private var initials: String {
        let value = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "YOU" }
        return value.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }

    private var primaryButtonTitle: String {
        if mode == .signIn { return "Sign in" }
        return switch signupStep {
        case .review: "Create account"
        default: "Continue"
        }
    }

    private var signupStepAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.34, dampingFraction: 1)
    }

    var body: some View {
        Group {
            if mode == .signIn {
                signInScreen
            } else {
                signUpScreen
            }
        }
        .animation(.snappy(duration: 0.22), value: mode)
        .alert("Sign-in option unavailable", isPresented: $showsAuthInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authInfoMessage ?? "")
        }
        .onChange(of: accountSession.isPasswordRecovery) { _, isRecovering in
            if isRecovering { showingPasswordUpdate = true }
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetSheet(email: email)
                .environmentObject(accountSession)
        }
        .sheet(isPresented: $showingPasswordUpdate) {
            PasswordUpdateSheet()
                .environmentObject(accountSession)
        }
    }

    private var signInScreen: some View {
        GeometryReader { viewport in
            ZStack {
                RallyTheme.authForest
                    .ignoresSafeArea()
                AuthHeroBackdrop()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(RallyTheme.tennis)
                                .frame(width: 12, height: 12)
                            Text("TENNIS IS BETTER TOGETHER")
                                .font(.inter(10, weight: .bold, relativeTo: .caption))
                                .tracking(2.2)
                                .foregroundStyle(RallyTheme.authMuted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .padding(.bottom, 22)

                        loginBrandHeader
                            .padding(.bottom, 30)

                        VStack(alignment: .leading, spacing: -5) {
                            Text("More tennis.")
                                .foregroundStyle(.white)
                            Text("Better days.")
                                .foregroundStyle(RallyTheme.tennis)
                        }
                        .font(.inter(min(46, max(34, viewport.size.width * 0.11)), weight: .black, relativeTo: .largeTitle))
                        .tracking(-1.8)
                        .lineSpacing(-5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 18)

                        Text("Find your next hitting partner, make a match, and keep your game moving with RallyUp.")
                            .font(.inter(17, relativeTo: .body))
                            .foregroundStyle(RallyTheme.authMuted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 28)

                        loginPanel

                        HStack(spacing: 7) {
                            Text("New to RallyUp?")
                                .foregroundStyle(RallyTheme.authMuted)
                            Button {
                                setMode(.signUp)
                            } label: {
                                Text("Sign up")
                                    .font(.inter(16, weight: .semibold, relativeTo: .body))
                                    .foregroundStyle(RallyTheme.tennis)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.inter(16, relativeTo: .body))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 22)

                        Text("PLAY  •  PEOPLE  •  PROGRESS")
                            .font(.inter(10, weight: .bold, relativeTo: .caption))
                            .tracking(2.8)
                            .foregroundStyle(RallyTheme.authMuted.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    }
                    .padding(.horizontal, viewport.size.width > 700 ? 60 : 22)
                    .padding(.top, 34)
                    .padding(.bottom, 34)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: viewport.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)

            }
        }
        .preferredColorScheme(.dark)
    }

    private var signUpScreen: some View {
        GeometryReader { viewport in
            ZStack {
                Color.white
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Image("RallyUpWordmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 72, alignment: .leading)
                                .accessibilityLabel("RallyUp")
                            Spacer(minLength: 12)
                            Button("Log in") { setMode(.signIn) }
                                .font(.subheadline.weight(.bold))
                                .underline()
                                .foregroundStyle(RallyTheme.darkGreen)
                        }
                        .frame(height: 96)
                        .padding(.bottom, 12)

                        signupProgress
                            .padding(.bottom, 30)
                        titleBlock
                            .padding(.bottom, 24)
                        signupStepContent

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(Color(red: 0.55, green: 0.08, blue: 0.08))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 14)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: viewport.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            authFooter
        }
        .environment(\.colorScheme, .light)
    }

    private var loginPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            signInFields

            HStack {
                Spacer()
                Button {
                    showingPasswordReset = true
                } label: {
                    Text("Forgot password?")
                        .font(.inter(14, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                        .underline()
                }
                .buttonStyle(.plain)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.inter(13, relativeTo: .footnote))
                    .foregroundStyle(Color(red: 1, green: 0.68, blue: 0.63))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: submit) {
                Text(isSubmitting ? "Logging in…" : "Log in")
                    .font(.inter(18, weight: .bold, relativeTo: .headline))
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .foregroundStyle(RallyTheme.authForest)
                    .background(RallyTheme.tennis, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || isSubmitting)
            .opacity(canSubmit && !isSubmitting ? 1 : 0.76)

        }
        .padding(24)
        .background(RallyTheme.authPanel.opacity(0.96), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
    }

    private var loginBrandHeader: some View {
        RallyUpLoginWordmark()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 118, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("RallyUp")
    }

    private func presentAuthInfo(_ message: String) {
        authInfoMessage = message
        showsAuthInfo = true
    }

    private func setMode(_ nextMode: AccountAccessMode) {
        mode = nextMode
        signupStep = .name
        errorMessage = nil
        password = ""
        confirmation = ""
        isPasswordVisible = false
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .tracking(-0.6)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .animation(.snappy(duration: 0.22), value: mode)
        .animation(.snappy(duration: 0.22), value: signupStep)
    }

    private var title: String {
        if mode == .signIn { return "Welcome back." }
        return signupStep.title
    }

    private var subtitle: String {
        if mode == .signIn { return "Sign in to pick up where your next rally begins." }
        return signupStep.subtitle
    }

    private var signupProgress: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                ForEach(AccountSignupStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= signupStep.rawValue ? RallyTheme.tennis : RallyTheme.separator)
                        .frame(height: 5)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text("SETUP · \(String(format: "%02d", signupStep.rawValue + 1)) / \(String(format: "%02d", AccountSignupStep.allCases.count))")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(RallyTheme.darkGreen)
                Spacer()
                if signupStep.isSkippable
                    && !(signupStep == .rackets && !racketDrafts.isEmpty)
                    && !(signupStep == .profilePhoto && profilePhotoData != nil) {
                    Button("Skip") { advanceSignup() }
                        .font(.caption.weight(.semibold))
                        .tint(RallyTheme.ink)
                        .disabled(isLoadingProfilePhoto)
                }
            }
        }
    }

    @ViewBuilder
    private var signupStepContent: some View {
        Group {
            switch signupStep {
            case .name: nameStep
            case .profilePhoto: profilePhotoStep
            case .credentials: credentialsStep
            case .level: levelStep
            case .strengths: strengthsStep
            case .area: areaStep
            case .availability: availabilityStep
            case .rackets: racketPhotosStep
            case .review: reviewStep
            }
        }
        .id(signupStep)
        .transition(reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(signupStepAnimation, value: signupStep)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Full name", text: $displayName)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .rallyAuthField()
            Text("This name will appear on your RallyUp player card.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var profilePhotoStep: some View {
        VStack(spacing: 18) {
            Group {
                if let data = profilePhotoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(RallyTheme.darkGreen.opacity(0.32))
                        .padding(20)
                        .background(RallyTheme.tennis.opacity(0.12))
                }
            }
            .frame(width: 156, height: 156)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(RallyTheme.separator, lineWidth: 1))
            .accessibilityLabel(profilePhotoData == nil ? "Profile photo placeholder" : "Selected profile photo")

            PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                Label(profilePhotoData == nil ? "Add a photo" : "Change photo", systemImage: "photo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RallyTheme.darkGreen)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 18)
                    .background(RallyTheme.tennis.opacity(0.14), in: Capsule())
            }
            .disabled(isLoadingProfilePhoto)

            if profilePhotoData != nil {
                Button("Remove photo", role: .destructive) {
                    profilePhotoData = nil
                    profilePhotoItem = nil
                    profilePhotoError = nil
                }
                .font(.footnote.weight(.medium))
                .disabled(isLoadingProfilePhoto)
            }

            if isLoadingProfilePhoto {
                ProgressView("Loading photo…")
                    .tint(RallyTheme.darkGreen)
            }

            if let profilePhotoError {
                Text(profilePhotoError)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.55, green: 0.08, blue: 0.08))
                    .multilineTextAlignment(.center)
            }

            Text("Optional. Your picture appears on your player card and is visible to players when your profile is discoverable.")
                .font(.caption)
                .foregroundStyle(RallyTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .onChange(of: profilePhotoItem) { _, item in
            guard let item else { return }
            loadProfilePhoto(item)
        }
    }

    @MainActor
    private func loadProfilePhoto(_ item: PhotosPickerItem) {
        isLoadingProfilePhoto = true
        profilePhotoError = nil
        Task {
            defer { isLoadingProfilePhoto = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self), UIImage(data: data) != nil else {
                    profilePhotoError = "That image couldn’t be loaded. Choose another or leave this optional."
                    return
                }
                profilePhotoData = data
            } catch {
                profilePhotoError = "That image couldn’t be loaded. Choose another or leave this optional."
            }
        }
    }

    private var credentialsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Email address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .rallyAuthField()

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .rallyAuthField()

            SecureField("Confirm password", text: $confirmation)
                .textContentType(.newPassword)
                .rallyAuthField()

            HStack(spacing: 7) {
                Image(systemName: "lock.shield")
                Text("At least 8 characters")
                if !confirmation.isEmpty {
                    Spacer(minLength: 0)
                    Label(passwordsMatch ? "Match" : "Check", systemImage: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(passwordsMatch ? RallyTheme.darkGreen : .red)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var signInFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.inter(14, weight: .semibold, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                TextField("Email address", text: $email, prompt: Text("you@rallyup.com").foregroundStyle(.white.opacity(0.42)))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .foregroundStyle(.white)
                    .font(.inter(16, relativeTo: .body))
                    .accessibilityLabel("Email address")
                    .padding(.horizontal, 16)
                    .frame(minHeight: 58)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(.white.opacity(0.42), lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.inter(14, weight: .semibold, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                HStack(spacing: 12) {
                    Group {
                        if isPasswordVisible {
                            TextField("Password", text: $password, prompt: Text("••••••••").foregroundStyle(.white.opacity(0.42)))
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $password, prompt: Text("••••••••").foregroundStyle(.white.opacity(0.42)))
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    .submitLabel(.go)
                    .onSubmit(submit)
                    .foregroundStyle(.white)
                    .font(.inter(16, relativeTo: .body))
                    .accessibilityLabel("Password")

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.white.opacity(0.68))
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 58)
                .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(.white.opacity(0.42), lineWidth: 1)
                }
            }
        }
    }

    private var levelStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(SkillLevel.allCases) { level in
                Button {
                    withAnimation(.snappy(duration: 0.18)) { skillLevel = level }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: levelSymbol(level))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(skillLevel == level ? RallyTheme.darkGreen : RallyTheme.secondaryInk)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(level.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(levelDescription(level))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: skillLevel == level ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(skillLevel == level ? RallyTheme.darkGreen : RallyTheme.separator)
                    }
                    .padding(14)
                    .background(skillLevel == level ? RallyTheme.tennis.opacity(0.2) : RallyTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(skillLevel == level ? RallyTheme.tennis : RallyTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(skillLevel == level ? .isSelected : [])
            }
            Text("Not sure? Intermediate is a fine place to start—you can change it later.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var areaStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick a general area so RallyUp can suggest nearby players and courts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Menu {
                ForEach(areaOptions, id: \.self) { area in
                    Button {
                        homeAreaSelection = area
                    } label: {
                        if area == homeAreaSelection {
                            Label(area, systemImage: "checkmark")
                        } else {
                            Text(area)
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.headline)
                        .foregroundStyle(RallyTheme.darkGreen)
                    Text(homeAreaSelection)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))
            }
            Label("Broad area only. No exact address or GPS is needed.", systemImage: "hand.raised")
                .font(.caption)
                .foregroundStyle(RallyTheme.darkGreen)
        }
    }

    private var strengthsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(PlayerStrength.allCases) { strength in
                let isSelected = selectedStrengths.contains(strength)
                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        if isSelected {
                            selectedStrengths.remove(strength)
                        } else {
                            selectedStrengths.insert(strength)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: strengthSymbol(strength))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(isSelected ? RallyTheme.darkGreen : RallyTheme.secondaryInk)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(strength.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(strength.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? RallyTheme.darkGreen : RallyTheme.separator)
                    }
                    .padding(14)
                    .background(isSelected ? RallyTheme.tennis.opacity(0.2) : RallyTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(isSelected ? RallyTheme.tennis : RallyTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Text("Choose all that fit, or skip if you’re still figuring out your strengths.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var availabilityStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(availabilityOptions, id: \.self) { option in
                Button {
                    toggleAvailability(option)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: availabilitySymbol(option))
                            .font(.headline)
                            .foregroundStyle(selectedAvailability.contains(option) ? RallyTheme.darkGreen : RallyTheme.secondaryInk)
                            .frame(width: 30)
                        Text(option)
                            .font(.headline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: selectedAvailability.contains(option) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedAvailability.contains(option) ? RallyTheme.darkGreen : RallyTheme.separator)
                    }
                    .padding(14)
                    .background(selectedAvailability.contains(option) ? RallyTheme.tennis.opacity(0.2) : RallyTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(selectedAvailability.contains(option) ? RallyTheme.tennis : RallyTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedAvailability.contains(option) ? .isSelected : [])
            }
            Text("Choose more than one, or skip if your schedule changes week to week.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var racketPhotosStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Rackets", systemImage: "tennis.racket")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RallyTheme.ink)
                Spacer()
                Text("\(racketDrafts.count) / \(RacketLimits.maximumRackets)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(RallyTheme.ink)
            }

            ForEach($racketDrafts) { $racket in
                SignupRacketCard(
                    racket: $racket,
                    loadingRacketIDs: $loadingRacketIDs,
                    photoError: $racketPhotoError,
                    onRemove: { removeRacket(id: racket.id) }
                )
            }

            if racketDrafts.count < RacketLimits.maximumRackets {
                Button {
                    withAnimation(signupStepAnimation) {
                        racketDrafts.append(SignupRacketInput())
                        racketPhotoError = nil
                    }
                } label: {
                    Label(racketDrafts.isEmpty ? "Add a racket" : "Add another racket", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RallyTheme.darkGreen)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(RallyTheme.tennis.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(RallyTheme.tennis.opacity(0.8), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Add up to three rackets. A photo is optional.")
            }

            if isLoadingRacketPhotos {
                ProgressView("Loading racket photo…")
                    .tint(RallyTheme.darkGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let racketPhotoError {
                Label(racketPhotoError, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.55, green: 0.08, blue: 0.08))
            }

            Text("Rackets are optional. Add a brand and model for each one; a photo is optional.")
                .font(.caption)
                .foregroundStyle(RallyTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func removeRacket(id: UUID) {
        guard let index = racketDrafts.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(signupStepAnimation) {
            racketDrafts.remove(at: index)
            loadingRacketIDs.remove(id)
            racketPhotoError = nil
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            playerCardPreview
            VStack(spacing: 0) {
                reviewRow(symbol: "envelope", title: "Email", value: email.trimmingCharacters(in: .whitespacesAndNewlines))
                Divider().padding(.leading, 48)
                reviewRow(symbol: "person.crop.circle", title: "Profile photo", value: profilePhotoData == nil ? "Not added" : "Added")
                Divider().padding(.leading, 48)
                reviewRow(symbol: "chart.bar", title: "Level", value: skillLevel.title)
                Divider().padding(.leading, 48)
                reviewRow(
                    symbol: "scope",
                    title: "Game strengths",
                    value: selectedStrengths.isEmpty ? "Not specified" : PlayerStrength.allCases.filter { selectedStrengths.contains($0) }.map(\.title).joined(separator: ", ")
                )
                Divider().padding(.leading, 48)
                reviewRow(symbol: "mappin.and.ellipse", title: "Area", value: homeArea ?? "Private")
                Divider().padding(.leading, 48)
                reviewRow(symbol: "calendar", title: "Availability", value: normalizedAvailability.replacingOccurrences(of: "Usually available ", with: ""))
                Divider().padding(.leading, 48)
                if racketDrafts.isEmpty {
                    reviewRow(symbol: "tennis.racket", title: "Rackets", value: "None added")
                } else {
                    ForEach(Array(racketDrafts.enumerated()), id: \.element.id) { index, racket in
                        if index > 0 { Divider().padding(.leading, 48) }
                        reviewRow(
                            symbol: "tennis.racket",
                            title: racket.name.trimmingCharacters(in: .whitespacesAndNewlines),
                            value: racket.photoData == nil ? "No photo" : "Photo added"
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RallyTheme.separator, lineWidth: 1))

            Label("You can edit these details later from Profile.", systemImage: "pencil.line")
                .font(.caption)
                .foregroundStyle(RallyTheme.darkGreen)
        }
    }

    private func reviewRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(RallyTheme.darkGreen)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
    }

    private func levelSymbol(_ level: SkillLevel) -> String {
        switch level {
        case .beginner: "figure.walk"
        case .intermediate: "figure.run"
        case .advanced: "figure.tennis"
        }
    }

    private func levelDescription(_ level: SkillLevel) -> String {
        switch level {
        case .beginner: "Learning rallies and building the basics."
        case .intermediate: "Comfortable rallying and ready for regular play."
        case .advanced: "Confident match player with consistent experience."
        }
    }

    private func strengthSymbol(_ strength: PlayerStrength) -> String {
        switch strength {
        case .forehand: "arrow.right"
        case .backhand: "arrow.left"
        case .serve: "arrow.up.right"
        case .volley: "figure.tennis"
        case .footwork: "figure.run"
        case .consistency: "arrow.triangle.2.circlepath"
        }
    }

    private func availabilitySymbol(_ option: String) -> String {
        switch option {
        case "Weekdays": "sun.max"
        case "Weekends": "sun.horizon"
        default: "moon.stars"
        }
    }

    private var playerCardPreview: some View {
        HStack(spacing: 12) {
            if let profilePhotoData, let image = UIImage(data: profilePhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .accessibilityLabel("Selected profile photo")
            } else {
                PlayerAvatarView(player: previewProfile, size: 52)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Your player card" : displayName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Text("\(skillLevel.title) · \(homeArea ?? "Area private")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.title3)
                .foregroundStyle(RallyTheme.darkGreen)
        }
        .padding(12)
        .background(RallyTheme.tennis.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var previewProfile: PlayerProfile {
        PlayerProfile(
            displayName: displayName.isEmpty ? "Your name" : displayName,
            initials: initials,
            skillLevel: skillLevel,
            homeArea: homeArea,
            availabilitySummary: normalizedAvailability
        )
    }

    private var demoOption: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle().fill(RallyTheme.separator).frame(height: 1)
                Text("OR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Rectangle().fill(RallyTheme.separator).frame(height: 1)
            }
            Button {
                accountSession.continueWithDemo()
            } label: {
                Label("Continue with demo data", systemImage: "play.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
            .tint(RallyTheme.darkGreen)
        }
    }

    private var authFooter: some View {
        VStack(spacing: 10) {
            if mode == .signUp {
                HStack(spacing: 10) {
                    Button(action: goBack) {
                        Label("Back", systemImage: "arrow.left")
                            .font(.subheadline.weight(.semibold))
                            .frame(minWidth: 98, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .tint(RallyTheme.darkGreen)
                    .disabled(signupStep == .name)

                    Button(action: submit) {
                        HStack(spacing: 8) {
                            Text(primaryButtonTitle)
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RallyTheme.ink, in: Capsule())
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit || isLoadingRacketPhotos || isLoadingProfilePhoto || isSubmitting)
                    .opacity(canSubmit && !isLoadingRacketPhotos && !isLoadingProfilePhoto && !isSubmitting ? 1 : 0.55)
                }
            } else {
                Button(action: submit) {
                    Text(primaryButtonTitle)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(RallyTheme.tennis, in: Capsule())
                        .foregroundStyle(RallyTheme.ink)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.55)
                demoOption
            }
        }
        .padding(.horizontal, RallyTheme.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RallyTheme.separator)
                .frame(height: 1)
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        errorMessage = nil

        if mode == .signIn {
            isSubmitting = true
            Task {
                defer { isSubmitting = false }
                do {
                    try await accountSession.signIn(email: email, password: password)
                } catch {
                    errorMessage = accountSession.userFacingAuthError(error)
                }
            }
            return
        }

        switch signupStep {
        case .name, .profilePhoto, .credentials, .level, .strengths, .area, .availability, .rackets:
            advanceSignup()
        case .review:
            isSubmitting = true
            Task {
                defer { isSubmitting = false }
                do {
                    let sessionCreated = try await accountSession.signUp(
                        displayName: displayName,
                        email: email,
                        password: password,
                        skillLevel: skillLevel,
                        homeArea: homeArea,
                        availabilitySummary: normalizedAvailability,
                        avatarPhotoData: profilePhotoData,
                        strengths: PlayerStrength.allCases.filter { selectedStrengths.contains($0) },
                        rackets: racketDrafts
                    )
                    if !sessionCreated {
                        setMode(.signIn)
                        presentAuthInfo("Your account was created. Check your email to verify it, then log in to finish syncing your profile photo and rackets.")
                    }
                } catch {
                    errorMessage = accountSession.userFacingAuthError(error)
                }
            }
        }
    }

    private func advanceSignup() {
        guard let next = AccountSignupStep(rawValue: signupStep.rawValue + 1) else { return }
        errorMessage = nil
        withAnimation(signupStepAnimation) {
            signupStep = next
        }
    }

    private func goBack() {
        guard let previous = AccountSignupStep(rawValue: signupStep.rawValue - 1) else { return }
        errorMessage = nil
        withAnimation(signupStepAnimation) {
            signupStep = previous
        }
    }

    private func toggleAvailability(_ option: String) {
        withAnimation(.snappy(duration: 0.18)) {
            if selectedAvailability.contains(option) {
                selectedAvailability.remove(option)
            } else {
                selectedAvailability.insert(option)
            }
        }
    }
}

private struct SignupRacketCard: View {
    @Binding var racket: SignupRacketInput
    @Binding var loadingRacketIDs: Set<UUID>
    @Binding var photoError: String?
    let onRemove: () -> Void

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Racket")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(RallyTheme.secondaryInk)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RallyTheme.secondaryInk)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove racket")
            }

            TextField("Brand and model", text: $racket.name)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .rallyAuthField()
                .accessibilityHint("For example, Wilson Blade 98")

            HStack(spacing: 12) {
                racketPhotoPreview
                VStack(alignment: .leading, spacing: 4) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(racket.photoData == nil ? "Add photo" : "Change photo", systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RallyTheme.darkGreen)
                    }
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(RallyTheme.secondaryInk)
                }
                Spacer(minLength: 0)
                if racket.photoData != nil {
                    Button {
                        racket.photoData = nil
                        photoItem = nil
                        photoError = nil
                    } label: {
                        Text("Remove photo")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RallyTheme.secondaryInk)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RallyTheme.separator, lineWidth: 1)
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            loadPhoto(item)
        }
    }

    @ViewBuilder
    private var racketPhotoPreview: some View {
        if let data = racket.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Selected racket photo")
        } else {
            Image(systemName: "tennis.racket")
                .font(.title2)
                .foregroundStyle(RallyTheme.darkGreen.opacity(0.65))
                .frame(width: 68, height: 76)
                .background(RallyTheme.tennis.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) {
        loadingRacketIDs.insert(racket.id)
        photoError = nil
        Task { @MainActor in
            defer { loadingRacketIDs.remove(racket.id) }
            do {
                guard let data = try await item.loadTransferable(type: Data.self), UIImage(data: data) != nil else {
                    photoError = "That image couldn’t be loaded. Choose another photo or leave this optional."
                    return
                }
                racket.photoData = data
            } catch {
                photoError = "That image couldn’t be loaded. Choose another photo or leave this optional."
            }
        }
    }
}

private struct PasswordResetSheet: View {
    @EnvironmentObject private var accountSession: AccountSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var isSending = false
    @State private var message: String?
    @State private var errorMessage: String?

    init(email: String) {
        _email = State(initialValue: email)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Reset your password")
                } footer: {
                    Text("We’ll send a secure reset link to this address.")
                }

                if let message {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(RallyTheme.darkGreen)
                }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Forgot password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSending ? "Sending…" : "Send link") { sendResetLink() }
                        .disabled(isSending)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sendResetLink() {
        isSending = true
        message = nil
        errorMessage = nil
        Task {
            defer { isSending = false }
            do {
                try await accountSession.requestPasswordReset(email: email)
                message = "Check your inbox for a RallyUp password reset link."
            } catch {
                errorMessage = accountSession.userFacingAuthError(error)
            }
        }
    }
}

private struct PasswordUpdateSheet: View {
    @EnvironmentObject private var accountSession: AccountSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canSave: Bool { password.count >= 8 && password == confirmation }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New password", text: $password)
                        .textContentType(.newPassword)
                    SecureField("Confirm password", text: $confirmation)
                        .textContentType(.newPassword)
                } header: {
                    Text("Choose a new password")
                } footer: {
                    Text("Use at least 8 characters.")
                }

                if !confirmation.isEmpty && password != confirmation {
                    Label("Passwords don’t match.", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Update password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { save() }
                        .disabled(!canSave || isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .presentationDetents([.medium])
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            defer { isSaving = false }
            do {
                try await accountSession.updatePassword(password)
                dismiss()
            } catch {
                errorMessage = accountSession.userFacingAuthError(error)
            }
        }
    }
}

private struct RallyUpLoginWordmark: View {
    var body: some View {
        Image("RallyUpHeroLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 235, height: 118, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AuthHeroBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                Ellipse()
                    .fill(RallyTheme.authForestSoft.opacity(0.2))
                    .frame(width: width * 1.65, height: height * 1.35)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -width * 0.64, y: -height * 0.12)

                Ellipse()
                    .stroke(RallyTheme.authForestSoft.opacity(0.38), lineWidth: 1)
                    .frame(width: width * 1.22, height: height * 1.08)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -width * 0.48, y: -height * 0.08)

                Circle()
                    .stroke(RallyTheme.tennis.opacity(0.2), lineWidth: 1)
                    .frame(width: width * 0.72)
                    .offset(x: width * 0.48, y: height * 0.48)
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
}

private struct AuthEditorialCallout: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(.inter(10, weight: .medium, relativeTo: .caption2))
                .tracking(3.2)
                .lineSpacing(6)
                .foregroundStyle(RallyTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(RallyTheme.ink)
                .frame(width: 24, height: 1)
        }
        .frame(width: 124, alignment: .leading)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private extension View {
    func rallyAuthField() -> some View {
        padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(RallyTheme.separator, lineWidth: 1)
            }
    }
}
