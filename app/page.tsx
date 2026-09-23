import Image from "next/image";
import type { CSSProperties } from "react";
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
    <main className="landing-page club-luxe" id="top">
      <MotionLayer />
      <div className="scroll-progress" aria-hidden="true"><span /></div>

      <header className="marketing-header luxe-header">
        <a className="luxe-logo" href="/" aria-label="RallyUp home">
          <Image src="/assets/branding/rallyup-logo.svg" alt="RallyUp" width={150} height={65} priority />
        </a>
        <nav className="luxe-nav" aria-label="Main navigation">
          <a href="#philosophy">The game</a>
          <a href="#screens">RallyUp</a>
          <a href="#progress">The details</a>
          <ComingSoonButton className="luxe-nav-cta" />
        </nav>
      </header>

      <section className="luxe-hero" aria-labelledby="hero-title">
        <div className="luxe-hero-copy" data-reveal="fade-up">
          <p className="luxe-overline"><span /> THE GAME, WELL PLAYED</p>
          <h1 id="hero-title">Tennis<br />starts<br />together.</h1>
          <p>Good people. A court nearby. Every point remembered.</p>
          <div className="luxe-hero-actions">
            <a className="luxe-primary" href="#philosophy">Discover RallyUp <ArrowDownRight aria-hidden="true" /></a>
            <span className="luxe-edition">A NEW WAY TO FIND YOUR MATCH</span>
          </div>
        </div>
        <div className="luxe-hero-image parallax-layer" data-parallax="0.035">
          <Image src="/images/tennis/forehand-hard-court.webp" alt="A tennis player reaching for a forehand on a hard court" fill priority sizes="(max-width: 680px) 100vw, 62vw" />
          <span className="luxe-image-caption"><i /> FIG. 01 <span>THE MOMENT BEFORE THE POINT</span></span>
        </div>
        <div className="luxe-hero-index" aria-hidden="true">RALLYUP · 001</div>
        <div className="luxe-hero-phone" data-reveal="fade-up">
          <IPhone src="/images/screens/home.png" alt="RallyUp home screen with an upcoming match and player record" className="luxe-phone" priority />
          <span className="luxe-phone-note">Your next match,<br />already in motion.</span>
        </div>
      </section>

      <div className="luxe-marquee" aria-label="Play, people, progress">
        <div><span>PLAY</span><i /> <span>PEOPLE</span><i /> <span>PROGRESS</span><i /> <span>PLAY</span><i /> <span>PEOPLE</span><i /> <span>PROGRESS</span></div>
      </div>

      <section className="luxe-philosophy" id="philosophy" aria-labelledby="philosophy-title">
        <div className="luxe-section-meta" data-reveal="fade-up"><span>THE RALLYUP PHILOSOPHY</span><span>01 — 03</span></div>
        <div className="luxe-philosophy-grid">
          <h2 id="philosophy-title" data-reveal="fade-up">A better match<br />begins before<br />the first serve.</h2>
          <div className="luxe-philosophy-copy" data-reveal="fade-up">
            <p>RallyUp brings the parts of tennis together: finding the right people, choosing where to play, and keeping the progress you make along the way.</p>
            <a className="luxe-text-link" href="#screens">Meet the app <ArrowRight aria-hidden="true" /></a>
          </div>
        </div>
        <div className="luxe-feature-list" id="people">
          {featureRows.map(({ number, kicker, title, body, icon: Icon }, index) => (
            <article className="luxe-feature-row" key={number} data-reveal="fade-up" style={{ "--reveal-delay": `${index * 80}ms` } as CSSProperties}>
              <span className="luxe-feature-number">{number}</span>
              <Icon aria-hidden="true" />
              <p className="luxe-feature-label">{kicker}</p>
              <div><h3>{title}</h3><p>{body}</p></div>
              <ArrowRight className="luxe-feature-arrow" aria-hidden="true" />
            </article>
          ))}
        </div>
      </section>

      <section className="luxe-tour" id="screens" aria-labelledby="tour-title">
        <div className="luxe-tour-head" data-reveal="fade-up">
          <div><p className="luxe-overline"><span /> INSIDE RALLYUP</p><h2 id="tour-title">Every part<br />in its place.</h2></div>
          <p>Considered for the moments around the match, and the ones that happen on court.</p>
        </div>
        <ScreenTour />
        <div className="luxe-tour-foot"><span>SELECT A CHAPTER</span><span>02 — 04</span></div>
      </section>

      <section className="luxe-progress" id="progress" aria-labelledby="progress-title">
        <div className="luxe-progress-image parallax-layer" data-parallax="0.04">
          <Image src="/images/tennis/serve-grass-court.webp" alt="A tennis player preparing a grass-court serve" fill sizes="(max-width: 680px) 100vw, 50vw" />
          <span>THE LONG GAME · FIG. 02</span>
        </div>
        <div className="luxe-progress-copy" data-reveal="fade-up">
          <p className="luxe-overline"><span /> A GAME THAT ADDS UP</p>
          <h2 id="progress-title">Keep the<br />whole story.</h2>
          <p>Every match leaves something behind. RallyUp keeps your scores, your story, and the progress taking shape between games.</p>
          <a className="luxe-text-link" href="#screens">See your game in view <ArrowRight aria-hidden="true" /></a>
          <div className="luxe-progress-rule"><span>PLAY WELL</span><i /><span>COME BACK BETTER</span></div>
        </div>
      </section>

      <section className="luxe-close" aria-labelledby="close-title" data-reveal="fade-up">
        <p className="luxe-overline"><span /> YOUR NEXT MATCH AWAITS</p>
        <h2 id="close-title">Make time<br />for tennis.</h2>
        <ComingSoonButton className="luxe-primary luxe-close-cta" />
        <span className="luxe-close-mark" aria-hidden="true">R</span>
      </section>

      <footer className="luxe-footer">
        <div className="luxe-footer-top">
          <Image src="/assets/branding/rallyup-logo.svg" alt="RallyUp" width={145} height={63} />
          <p>Find your people. Play more tennis.</p>
          <div><a href="/privacy">Privacy</a><a href="/terms">Terms</a><a href="#top">Back to top <ArrowRight aria-hidden="true" /></a></div>
        </div>
        <span className="luxe-footer-note">PLAY · PEOPLE · PROGRESS</span>
      </footer>
    </main>
  );
}
