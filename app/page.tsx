import Image from "next/image";
import Link from "next/link";
import { ArrowRight, ArrowUpRight, ShieldCheck } from "lucide-react";

import { LandingCta } from "@/components/landing-cta";
import { MockupCarousel } from "@/components/mockup-carousel";
import { MotionLayer } from "@/components/motion-layer";
import { ScreenTour } from "@/components/screen-tour";

const extras = [
  ["Player matching", "Find someone who fits your level, location, and schedule."],
  ["Court discovery", "See where the next rally can start and save your favorites."],
  ["Match invites", "Make plans with less back-and-forth and more time on court."],
  ["Head-to-heads", "Keep the friendly rivalry alive with every result."],
  ["Match notes", "Remember the conditions, the turning point, and the feeling."],
  ["Player profiles", "Share the way you play before you ever meet at the net."],
  ["Live scoring", "Keep your eyes up and your score right where it belongs."],
  ["Home widgets", "Keep your next match close, even between sessions."],
];

const reviews = [
  ["Finally, a reason to play more", "RallyUp makes it so much easier to turn a casual idea into an actual match.", "Mika R."],
  ["The app I wanted years ago", "Finding players at my level used to be the hardest part. Now I just open RallyUp.", "Alex T."],
  ["Beautiful and genuinely useful", "It feels calm, clear, and made for the moments around tennis—not just the score.", "Jordan C."],
  ["Every match feels connected", "The history and head-to-head view make even a weeknight hit feel like progress.", "Sam P."],
  ["Good people. Better tennis.", "RallyUp helped me find a regular group and actually stick with the game.", "Chris L."],
];

function Phone({ src, alt, className = "", priority = false }: { src: string; alt: string; className?: string; priority?: boolean }) {
  return <div className={`bevel2-supplied-mockup ${className}`}><Image src={src} alt={alt} width={410} height={887} priority={priority} sizes="(max-width: 760px) 58vw, 300px" /></div>;
}

function MiniScore({ value, label, tone = "lime" }: { value: string; label: string; tone?: string }) {
  return <div className={`bevel2-mini-score bevel2-mini-${tone}`}><span>{label}</span><strong>{value}</strong><small><i /> tracked in RallyUp</small></div>;
}

export default function LandingPage() {
  return (
    <main className="bevel2-landing" id="top">
      <MotionLayer />

      <header className="bevel2-header">
        <div className="bevel2-header-pill">
          <Link href="/" prefetch={false} className="bevel2-logo" aria-label="RallyUp home"><Image src="/assets/branding/rallyup-logo-dark.svg" alt="RallyUp" width={108} height={47} priority /></Link>
          <nav aria-label="Main navigation"><a href="#product">Product</a><a href="#stories">Stories</a><a href="#intelligence">RallyUp coach</a></nav>
          <div className="bevel2-header-actions"><LandingCta className="bevel2-pill-button">Get started</LandingCta></div>
        </div>
      </header>

      <section className="bevel2-hero" aria-labelledby="hero-title">
        <div className="bevel2-hero-surface">
          <div className="bevel2-hero-copy" data-reveal="fade-up">
            <p className="bevel2-overline">THE CONNECTED TENNIS APP</p>
            <h1 id="hero-title">Your tennis,<br /><em>in motion.</em></h1>
            <p>Make sense of the whole game—from finding players and courts to keeping score and seeing your progress.</p>
            <LandingCta className="bevel2-dark-button">Get started free</LandingCta>
            <div className="bevel2-rating"><span>★★★★★</span><small>4.9 / 12K players already rallying</small></div>
          </div>
          <div className="bevel2-hero-art" data-reveal="fade-up"><div className="bevel2-hero-court"><Image src="/images/generated/rallyup-player-forehand.png" alt="Tennis player finishing a forehand on a hard court" fill priority sizes="(max-width: 760px) 100vw, 56vw" /></div><Phone src="/images/mockups/home.png" alt="RallyUp home screen with upcoming match" className="bevel2-hero-phone" priority /><div className="bevel2-hero-float"><MiniScore value="15—9" label="YOUR RECORD" /><MiniScore value="63%" label="WIN RATE" tone="soft" /></div></div>
        </div>
      </section>

      <section className="bevel2-download" id="product" aria-label="Get RallyUp">
        <div className="bevel2-download-copy"><p className="bevel2-overline">ONE PLACE TO PLAY MORE</p><h2>Everything around the match.</h2><p>RallyUp brings your players, courts, scores, and progress into one simple rhythm.</p><div className="bevel2-download-points"><span><i /> Find your next player</span><span><i /> Keep every point in motion</span><span><i /> See your game add up</span></div></div>
        <div className="bevel2-download-card"><Phone src="/images/mockups/home.png" alt="RallyUp mobile app home screen" className="bevel2-download-phone" /><div><span className="bevel2-download-mark" aria-hidden="true">↗</span><strong>See RallyUp in action</strong><small>Explore the app before your next match</small><LandingCta className="bevel2-download-button">Explore the app</LandingCta></div></div>
      </section>

      <section className="bevel2-community" id="stories" aria-labelledby="community-title"><div className="bevel2-centered-heading" data-reveal="fade-up"><p className="bevel2-overline">THE RALLYUP COMMUNITY</p><h2 id="community-title">Join the next generation<br /><em>of tennis players.</em></h2></div><MockupCarousel /></section>

      <section className="bevel2-chapters" aria-labelledby="chapters-title"><div className="bevel2-chapters-heading"><p className="bevel2-overline">EVERYTHING IN ITS PLACE</p><h2 id="chapters-title">Start every match<br /><em>with confidence.</em></h2><p>Turn the moments around tennis into clear, actionable next steps.</p></div><ScreenTour /></section>

      <section className="bevel2-intelligence" id="intelligence" aria-labelledby="intelligence-title"><div className="bevel2-intelligence-heading" data-reveal="fade-up"><p className="bevel2-overline">GO DEEPER WITH RALLYUP COACH</p><h2 id="intelligence-title">A better coach<br /><em>for your game.</em></h2><p>Personalized guidance and useful nudges for the player you are becoming.</p></div><div className="bevel2-intelligence-grid"><article><div className="bevel2-intelligence-copy"><span>01</span><h3>Get answers<br /><em>from your game.</em></h3><p>Ask what your record means, where you are improving, and what to work on next.</p></div><Image src="/images/generated/rallyup-coach-racket.png" alt="RallyUp racket and performance insight visual" width={1024} height={1536} className="bevel2-intelligence-visual bevel2-intelligence-visual-racket" /></article><article><div className="bevel2-intelligence-copy"><span>02</span><h3>Proactive<br /><em>match check-ins.</em></h3><p>Get reminders, summaries, and small prompts without having to ask first.</p></div><Image src="/images/generated/rallyup-coach-handshake.png" alt="Two tennis players celebrating at the net" width={1208} height={1302} className="bevel2-intelligence-visual bevel2-intelligence-visual-handshake" /></article><article><div className="bevel2-intelligence-copy"><span>03</span><h3>Find patterns<br /><em>you can trust.</em></h3><p>See which surfaces, opponents, and rhythms bring out your best tennis.</p></div><Image src="/images/generated/rallyup-coach-surfaces.png" alt="Tennis balls across clay, hard, and grass surfaces" width={1536} height={1024} className="bevel2-intelligence-visual bevel2-intelligence-visual-surfaces" /></article></div></section>

      <section className="bevel2-extras" aria-labelledby="extras-title"><div className="bevel2-extras-heading"><p className="bevel2-overline">AND THAT&apos;S NOT ALL</p><h2 id="extras-title">More ways to<br /><em>stay in the game.</em></h2><p>The little details that make the habit of playing feel effortless.</p></div><div className="bevel2-extras-grid">{extras.map(([title, body], index) => <article key={title}><span>0{index + 1}</span><div><h3>{title}</h3><p>{body}</p></div><ArrowUpRight aria-hidden="true" /></article>)}</div></section>

      <section className="bevel2-privacy" aria-labelledby="privacy-title"><div className="bevel2-privacy-orbit" aria-hidden="true" /><div data-reveal="fade-up"><ShieldCheck aria-hidden="true" /><p className="bevel2-overline">BUILT FOR THE LONG GAME</p><h2 id="privacy-title">Your game is<br /><em>yours.</em></h2><p>RallyUp keeps your match history, player profile, and progress in one secure place. We build with care because the details matter.</p><a href="/privacy">Read our privacy promise <ArrowRight aria-hidden="true" /></a></div></section>

      <section className="bevel2-reviews" aria-labelledby="reviews-title"><div className="bevel2-centered-heading"><p className="bevel2-overline">CRAFTED WITH CARE. LOVED BY PLAYERS.</p><h2 id="reviews-title">Don’t take our word<br /><em>for it.</em></h2><p>See why players keep coming back for the next rally.</p></div><div className="bevel2-review-rail">{reviews.map(([title, body, name]) => <article key={title}><div className="bevel2-review-stars">★★★★★</div><h3>{title}</h3><p>“{body}”</p><span>{name} <i>RallyUp player</i></span></article>)}</div></section>

      <section className="bevel2-final" aria-labelledby="final-title"><div className="bevel2-final-image"><Image src="/images/tennis/serve-grass-court.webp" alt="Tennis player reaching for a serve" fill sizes="100vw" /></div><div className="bevel2-final-copy"><p className="bevel2-overline">YOUR NEXT MATCH AWAITS</p><h2 id="final-title">Ready when<br /><em>you are.</em></h2><p>Start with one player, one court, one match. RallyUp meets you where you are and helps you keep going.</p><LandingCta className="bevel2-dark-button">Get started free</LandingCta></div></section>

      <footer className="bevel2-footer"><div className="bevel2-footer-brand"><Image src="/assets/branding/rallyup-logo-dark.svg" alt="RallyUp" width={112} height={49} /><span>Find your people. Play your best game.</span><div><Link href="/privacy" prefetch={false}>Privacy</Link><Link href="/terms" prefetch={false}>Terms</Link><a href="mailto:hello@rallyup.app">Contact us</a></div></div><div className="bevel2-footer-links"><div><strong>Company</strong><a href="#stories">About RallyUp</a><a href="#stories">Player stories</a><a href="#intelligence">Our approach</a></div><div><strong>Product</strong><a href="#product">Get started</a><a href="#product">How it works</a><a href="#intelligence">RallyUp Coach</a></div><div><strong>Explore</strong><a href="#top">Back to top</a><a href="/privacy">Privacy promise</a><a href="mailto:hello@rallyup.app">Report a bug</a></div></div><div className="bevel2-footer-bottom"><span>© 2026 RallyUp</span><span>PLAY · PEOPLE · PROGRESS</span></div></footer>
    </main>
  );
}
