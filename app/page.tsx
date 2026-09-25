import Image from "next/image";
import Link from "next/link";
import type { CSSProperties } from "react";
import { ArrowRight, ArrowUpRight, Check, Swords, Trophy, UsersRound } from "lucide-react";

import { ComingSoonButton } from "@/components/coming-soon-button";
import { MotionLayer } from "@/components/motion-layer";
import { ScreenTour } from "@/components/screen-tour";

const pillars = [
  { eyebrow: "01 / PEOPLE", title: "Find your people", body: "Match with players who fit your level, schedule, and energy.", icon: UsersRound, tone: "mint" },
  { eyebrow: "02 / PLAY", title: "Make it to match point", body: "Find a court, invite your crew, and keep the score moving.", icon: Swords, tone: "cream" },
  { eyebrow: "03 / PROGRESS", title: "See your game grow", body: "Your history, rivalries, and next win—all in one place.", icon: Trophy, tone: "green" },
];

function Phone({ src, alt, className = "" }: { src: string; alt: string; className?: string }) {
  return (
    <div className={`bevel-phone ${className}`}>
      <div className="bevel-phone-screen">
        <Image src={src} alt={alt} fill sizes="(max-width: 760px) 58vw, 300px" className="bevel-phone-image" />
        <span className="bevel-phone-island" aria-hidden="true" />
      </div>
    </div>
  );
}

export default function LandingPage() {
  return (
    <main className="bevel-landing" id="top">
      <MotionLayer />

      <header className="bevel-header">
        <Link href="/" prefetch={false} className="bevel-logo" aria-label="RallyUp home"><Image src="/assets/branding/rallyup-logo-dark.svg" alt="RallyUp" width={112} height={49} priority /></Link>
        <nav className="bevel-nav" aria-label="Main navigation"><a href="#product">Product</a><a href="#how-it-works">How it works</a><a href="#progress">Progress</a></nav>
        <div className="bevel-header-actions"><Link href="/app" prefetch={false} className="bevel-login">Log in</Link><ComingSoonButton className="bevel-button bevel-button-small">Get started</ComingSoonButton></div>
      </header>

      <section className="bevel-hero" aria-labelledby="hero-title">
        <div className="bevel-hero-copy" data-reveal="fade-up">
          <p className="bevel-eyebrow"><span /> THE SOCIAL APP FOR TENNIS</p>
          <h1 id="hero-title">Find your people.<br /><em>Play your best game.</em></h1>
          <p className="bevel-hero-lede">RallyUp brings the whole tennis experience together—players, courts, matches, and progress.</p>
          <div className="bevel-hero-actions"><ComingSoonButton className="bevel-button bevel-button-dark">Get started free</ComingSoonButton><a className="bevel-arrow-link" href="#how-it-works">See how it works <ArrowRight aria-hidden="true" /></a></div>
          <div className="bevel-hero-meta"><span><Check aria-hidden="true" /> Free to join</span><span><Check aria-hidden="true" /> Made for every level</span></div>
        </div>

        <div className="bevel-hero-art" data-reveal="fade-up">
          <div className="bevel-art-wash" aria-hidden="true" /><div className="bevel-hero-photo"><Image src="/images/tennis/forehand-hard-court.webp" alt="Tennis player hitting a forehand on a hard court" fill priority sizes="(max-width: 760px) 90vw, 48vw" /></div>
          <div className="bevel-art-label"><span /> LIVE FROM THE COURT</div><Phone src="/images/screens/home.png" alt="RallyUp home screen showing an upcoming match" className="bevel-phone-hero" /><Phone src="/images/screens/find-players.png" alt="RallyUp find players screen" className="bevel-phone-secondary" />
          <div className="bevel-floating-score"><span>YOUR RECORD</span><strong>15—9</strong><small>63% win rate <i>↗</i></small></div><span className="bevel-art-number">01</span>
        </div>
      </section>

      <section className="bevel-proof" aria-label="RallyUp highlights"><p>Everything you need to keep playing</p><div className="bevel-proof-items"><span>Find a match</span><i /><span>Track your progress</span><i /><span>Play more often</span><i /><span>Meet your people</span></div></section>

      <section className="bevel-pillars" id="product" aria-labelledby="pillars-title">
        <div className="bevel-section-heading" data-reveal="fade-up"><p className="bevel-eyebrow"><span /> ONE APP. EVERY PART OF THE GAME.</p><h2 id="pillars-title">Your game,<br /><em>all in one place.</em></h2><p>From the first invite to the final point, RallyUp gives you a simpler way to make tennis part of your life.</p></div>
        <div className="bevel-pillar-grid">{pillars.map(({ eyebrow, title, body, icon: Icon, tone }, index) => <article className={`bevel-pillar bevel-pillar-${tone}`} key={eyebrow} data-reveal="fade-up" style={{ "--reveal-delay": `${index * 90}ms` } as CSSProperties}><div className="bevel-pillar-top"><span>{eyebrow}</span><Icon aria-hidden="true" /></div><div><h3>{title}</h3><p>{body}</p></div><a href="#how-it-works" aria-label={`Learn more about ${title}`}><ArrowUpRight aria-hidden="true" /></a></article>)}</div>
      </section>

      <section className="bevel-feature" id="how-it-works" aria-labelledby="feature-title">
        <div className="bevel-feature-intro" data-reveal="fade-up"><p className="bevel-eyebrow bevel-eyebrow-light"><span /> MADE FOR THE WAY YOU PLAY</p><h2 id="feature-title">Good tennis<br /><em>starts here.</em></h2><p>RallyUp makes the invisible work of playing easier, so you can spend more time on the court.</p></div>
        <ScreenTour /><div className="bevel-feature-footer"><span>EXPLORE THE APP</span><span>SELECT A FEATURE <ArrowRight aria-hidden="true" /></span></div>
      </section>

      <section className="bevel-progress" id="progress" aria-labelledby="progress-title">
        <div className="bevel-progress-art" data-reveal="fade-up"><Image src="/images/tennis/serve-grass-court.webp" alt="Tennis player serving on a grass court" fill sizes="(max-width: 760px) 100vw, 42vw" /><div className="bevel-progress-card"><span>THIS SEASON</span><strong>+24%</strong><small>more matches played</small><div><i /><i /><i /><i /><i /><i /><i /></div></div></div>
        <div className="bevel-progress-copy" data-reveal="fade-up"><p className="bevel-eyebrow"><span /> THE LONG GAME</p><h2 id="progress-title">Every match<br /><em>adds up.</em></h2><p>Keep your scores, see your patterns, and turn the matches you play into momentum for the next one.</p><div className="bevel-progress-list"><span><b>01</b> Match history <ArrowRight aria-hidden="true" /></span><span><b>02</b> Head-to-heads <ArrowRight aria-hidden="true" /></span><span><b>03</b> Performance <ArrowRight aria-hidden="true" /></span></div></div>
      </section>

      <section className="bevel-cta" aria-labelledby="cta-title"><div className="bevel-cta-orbit" aria-hidden="true" /><div data-reveal="fade-up"><p className="bevel-eyebrow"><span /> YOUR NEXT MATCH IS OUT THERE</p><h2 id="cta-title">Ready to<br /><em>rally?</em></h2></div><ComingSoonButton className="bevel-button bevel-button-dark">Get started free</ComingSoonButton></section>

      <footer className="bevel-footer"><div className="bevel-footer-top"><Image src="/assets/branding/rallyup-logo-dark.svg" alt="RallyUp" width={112} height={49} /><p>Find your people. Play your best game.</p><div><Link href="/privacy" prefetch={false}>Privacy</Link><Link href="/terms" prefetch={false}>Terms</Link><a href="#top">Back to top <ArrowUpRight aria-hidden="true" /></a></div></div><div className="bevel-footer-bottom"><span>© 2026 RallyUp</span><span>PLAY · PEOPLE · PROGRESS</span></div></footer>
    </main>
  );
}
