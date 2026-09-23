import Image from "next/image";
import { ArrowDownRight, ArrowRight, Check, Swords, Trophy, UsersRound } from "lucide-react";

import { ComingSoonButton } from "@/components/coming-soon-button";
import { MotionLayer } from "@/components/motion-layer";
import { ScreenTour } from "@/components/screen-tour";

const featureRows = [
  { number: "01", kicker: "PEOPLE", title: "Find your kind of player", body: "Discover nearby players by level, availability, and the way you like to compete.", icon: UsersRound },
  { number: "02", kicker: "PLAY", title: "Make every match count", body: "Set up the match, keep score point by point, and stay in the moment.", icon: Swords },
  { number: "03", kicker: "PROGRESS", title: "See your game grow", body: "Keep your record, rivalries, and performance in one place.", icon: Trophy },
];

function IPhone({ src, alt, className = "", priority = false }: { src: string; alt: string; className?: string; priority?: boolean }) {
  return (
    <div className={`iphone-mockup ${className}`} data-tilt>
      <div className="iphone-screen">
        <Image src={src} alt={alt} fill priority={priority} sizes="(max-width: 700px) 46vw, 310px" className="iphone-screen-image" />
        <span className="iphone-island" aria-hidden="true" />
      </div>
    </div>
  );
}

export default function LandingPage() {
  return (
    <main className="landing-page court-energy" id="top">
      <MotionLayer />
      <div className="scroll-progress" aria-hidden="true"><span /></div>

      <header className="marketing-header court-header">
        <a className="marketing-logo" href="/" aria-label="RallyUp home">
          <Image src="/assets/branding/rallyup-logo.svg" alt="RallyUp" width={150} height={65} priority />
        </a>
        <nav className="marketing-nav" aria-label="Main navigation">
          <a href="#play">Play</a>
          <a href="#people">People</a>
          <a href="#progress">Progress</a>
          <ComingSoonButton className="nav-cta" />
        </nav>
      </header>

      <section className="court-hero" aria-labelledby="hero-title">
        <div className="court-hero-photo parallax-layer" data-parallax="0.06" aria-hidden="true">
          <Image src="/images/tennis/forehand-hard-court.webp" alt="" fill priority sizes="(max-width: 680px) 100vw, 58vw" />
        </div>
        <div className="court-hero-wash" aria-hidden="true" />
        <div className="court-hero-content" data-reveal="fade-up">
          <p className="court-kicker"><span /> Play your next point</p>
          <h1 id="hero-title">Find your<br /><em>rally.</em></h1>
          <p>RallyUp brings players, courts, and progress together so more days end with a better match.</p>
          <div className="court-hero-actions">
            <a className="button-lime" href="#play">Explore the app <ArrowRight aria-hidden="true" /></a>
            <a className="text-link-light" href="#screens">See it in motion <ArrowDownRight aria-hidden="true" /></a>
          </div>
          <div className="court-hero-meta"><span>01</span><i /><span>PLAY</span><i /><span>PEOPLE</span><i /><span>PROGRESS</span></div>
        </div>
        <div className="court-hero-phone" data-reveal="fade-up">
          <IPhone src="/images/screens/home.png" alt="RallyUp home screen with a next match and quick actions" className="court-phone" priority />
          <span className="court-phone-caption">Your next match starts here</span>
        </div>
        <a className="court-scroll" href="#play" aria-label="Scroll to RallyUp features"><span>Scroll to rally</span><ArrowDownRight aria-hidden="true" /></a>
      </section>

      <section className="court-intro" id="play" aria-labelledby="intro-title">
        <div className="court-intro-label" data-reveal="fade-up"><span>RALLYUP / 001</span><span>MADE FOR THE NEXT MATCH</span></div>
        <div className="court-intro-grid">
          <h2 id="intro-title" data-reveal="fade-up">Less planning.<br /><strong>More playing.</strong></h2>
          <div data-reveal="fade-up">
            <p className="court-lead">The best part of tennis is the part between “we should play” and the first ball. RallyUp gets you there faster.</p>
            <div className="court-checks">
              <span><Check aria-hidden="true" /> Find a fit</span>
              <span><Check aria-hidden="true" /> Start a match</span>
              <span><Check aria-hidden="true" /> Keep your story</span>
            </div>
          </div>
        </div>
      </section>

      <section className="court-feature-rail" id="people" aria-labelledby="feature-title">
        <div className="court-feature-sticky" data-reveal="fade-up">
          <p className="eyebrow">The RallyUp rhythm</p>
          <h2 id="feature-title">A better way<br />to keep playing.</h2>
          <p>Three simple moves from finding your people to seeing how far your game has come.</p>
        </div>
        <div className="court-feature-list">
          {featureRows.map(({ number, kicker, title, body, icon: Icon }) => (
            <article className="court-feature-row" key={number} data-reveal="fade-up">
              <span className="court-feature-num">{number}</span>
              <div className="court-feature-icon"><Icon aria-hidden="true" /></div>
              <div><p className="screen-index">{kicker}</p><h3>{title}</h3><p>{body}</p></div>
              <ArrowRight className="court-feature-arrow" aria-hidden="true" />
            </article>
          ))}
        </div>
      </section>

      <section className="court-tour-section" id="screens" aria-labelledby="tour-title">
        <div className="court-tour-heading" data-reveal="fade-up">
          <p className="eyebrow eyebrow-light">A closer look</p>
          <h2 id="tour-title">Made for the<br /><em>next point.</em></h2>
          <p>Tap through the parts of RallyUp that make getting on court feel easy.</p>
        </div>
        <ScreenTour />
      </section>

      <section className="court-match-moment" id="progress" aria-labelledby="moment-title">
        <div className="court-moment-photo parallax-layer" data-parallax="0.08">
          <Image src="/images/tennis/serve-grass-court.webp" alt="Tennis player serving on a grass court" fill sizes="(max-width: 680px) 100vw, 50vw" />
          <span>Every point leaves a mark.</span>
        </div>
        <div className="court-moment-copy" data-reveal="fade-up">
          <p className="eyebrow">Progress you can feel</p>
          <h2 id="moment-title">Your game<br /><em>has a story.</em></h2>
          <p>Match history, head-to-heads, and performance patterns make the time between games count too.</p>
          <a className="button-dark" href="#screens">Explore your progress <ArrowRight aria-hidden="true" /></a>
        </div>
      </section>

      <section className="court-close" aria-labelledby="close-title" data-reveal="fade-up">
        <div className="court-close-mark parallax-layer" data-parallax="0.08" aria-hidden="true">R</div>
        <p className="eyebrow">Play · People · Progress</p>
        <h2 id="close-title">Your next rally<br /><em>is closer.</em></h2>
        <ComingSoonButton className="button-dark" />
      </section>

      <footer className="marketing-footer court-footer section-wrap">
        <Image src="/assets/branding/rallyup-logo.svg" alt="RallyUp" width={145} height={63} />
        <p>Find your people. Play more tennis.</p>
        <div className="footer-links"><a href="/privacy">Privacy</a><a href="/terms">Terms</a><a href="#top">Back to top <ArrowRight aria-hidden="true" /></a></div>
      </footer>
    </main>
  );
}
