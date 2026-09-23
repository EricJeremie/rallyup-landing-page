import Link from "next/link";

export const metadata = {
  title: "Privacy Policy — RallyUp",
  description: "How RallyUp collects, uses, and protects information.",
};

export default function PrivacyPolicyPage() {
  return (
    <main className="legal-page">
      <header className="legal-header">
        <Link href="/" className="legal-brand">Rally<span>Up</span></Link>
        <Link href="/" className="legal-back">Back to RallyUp</Link>
      </header>
      <article className="legal-document">
        <p className="legal-eyebrow">RallyUp / Privacy</p>
        <h1>Privacy Policy</h1>
        <p className="legal-updated">Last updated September 22, 2026</p>

        <p>RallyUp helps tennis players find people to play with, organize matches, discover courts, and keep track of their progress. This Privacy Policy explains what information RallyUp may collect, how we use it, and the choices available to you.</p>

        <h2>Information you provide</h2>
        <p>When you use RallyUp, you may provide a name, profile photo, playing level, availability, match preferences, match results, and other information you choose to add to your profile. You may also provide details when you create a match, invite another player, or contact the RallyUp team.</p>

        <h2>Information collected through use</h2>
        <p>RallyUp may collect information about how you use the service, such as the screens you view, features you use, match activity, device type, and basic technical information needed to keep the service secure and working properly. If you enable location access, RallyUp may use your approximate location to show nearby players and courts.</p>

        <h2>How we use information</h2>
        <ul>
          <li>Provide player discovery, match coordination, court discovery, scoring, and performance features.</li>
          <li>Show your profile and match information to other RallyUp users when needed for the feature you choose to use.</li>
          <li>Personalize recommendations, improve the product, and understand which features are useful.</li>
          <li>Protect RallyUp users, prevent misuse, and maintain the security and reliability of the service.</li>
          <li>Send service messages, such as match invitations, updates, and important account notices.</li>
        </ul>

        <h2>When information is shared</h2>
        <p>RallyUp shares information when you ask it to, such as when you publish a player profile or invite someone to a match. We may also share information with service providers that help us operate the product, or when required to comply with applicable law, protect users, or defend the service. RallyUp does not sell personal information.</p>

        <h2>Your choices</h2>
        <p>You can review or update information in your profile, choose what you add to RallyUp, and control location access through your device settings. You may stop using the service at any time. To request help with your information, contact the RallyUp team through the support contact made available in the app.</p>

        <h2>Data retention and security</h2>
        <p>We keep information for as long as it is needed to provide the service, meet legal obligations, resolve disputes, and enforce our agreements. We use reasonable administrative, technical, and organizational measures to protect information, but no online service can guarantee absolute security.</p>

        <h2>Children</h2>
        <p>RallyUp is intended for people who can lawfully use the service in their location. We do not knowingly collect personal information from children who are not permitted to use RallyUp. If you believe a child has provided information, contact the RallyUp team so we can review it.</p>

        <h2>Changes to this policy</h2>
        <p>We may update this Privacy Policy as RallyUp changes. When we do, we will update the date above and provide additional notice when required.</p>

        <div className="legal-footer-note">
          <a href="/terms">Read the Terms &amp; Conditions <span aria-hidden="true">→</span></a>
          <Link href="/">Return home <span aria-hidden="true">→</span></Link>
        </div>
      </article>
    </main>
  );
}
