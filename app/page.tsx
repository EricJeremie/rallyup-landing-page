import Image from "next/image";
import {
  ArrowDownRight,
  ArrowRight,
  ChartNoAxesCombined,
  MapPin,
  Search,
  Swords,
} from "lucide-react";

type PhoneProps = {
  src: string;
  alt: string;
  className?: string;
  priority?: boolean;
};

function IPhone({ src, alt, className = "", priority = false }: PhoneProps) {
  return (
    <div className={`iphone-mockup ${className}`}>
      <div className="iphone-screen">
        <Image
          src={src}
          alt={alt}
          fill
          priority={priority}
          sizes="(max-width: 700px) 42vw, 260px"
          className="iphone-screen-image"
        />
        <span className="iphone-island" aria-hidden="true" />
      </div>
    </div>
  );
}

const features = [
  {
    number: "01",
    icon: Search,
    title: "Find your kind of player",
    text: "Meet nearby players by level, availability, and the way you like to play.",
  },
  {
    number: "02",
    icon: Swords,
    title: "Make every match count",
    text: "Set up a match, keep score point by point, and revisit the result after the last ball.",
  },
  {
    number: "03",
    icon: ChartNoAxesCombined,
    title: "See your game grow",
    text: "Keep your record, head-to-head history, and performance in one place.",
  },
];

export default function LandingPage() {
  return (
    <main className="landing-page" id="top">
      <header className="marketing-header">
        <a className="marketing-logo" href="/" aria-label="RallyUp home">
          <Image
            src="/assets/branding/rallyup-logo-horizontal.svg"
            alt="RallyUp — Play, People, Progress"
            width={230}
            height={53}
            priority
          />
        </a>
        <nav className="marketing-nav" aria-label="Main navigation">
          <a href="#features">Features</a>
          <a href="#screens">The app</a>
          <a className="nav-cta" href="/app">
            Explore RallyUp <ArrowRight aria-hidden="true" />
          </a>
        </nav>
      </header>

      <section className="hero-panel" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="hero-kicker"><Image src="/assets/branding/rallyup-ball.svg" alt="" width={18} height={18} /> Tennis is better together</p>
          <h1 id="hero-title">More tennis.<br /><em>Better days.</em></h1>
          <p className="hero-description">
            Find your next hitting partner, make a match, and keep your game moving with RallyUp.
          </p>
          <div className="hero-actions">
            <a className="button-lime" href="#features">
              See what you can do <ArrowRight aria-hidden="true" />
            </a>
            <a className="text-link-light" href="#screens">
              Take a look around <ArrowDownRight aria-hidden="true" />
            </a>
          </div>
          <div className="hero-brand-line"><span>PLAY</span><i /><span>PEOPLE</span><i /><span>PROGRESS</span></div>
        </div>

        <div className="hero-phones" aria-label="RallyUp app screen previews">
          <IPhone
            src="/images/screens/find-players.png"
            alt="RallyUp Find Players screen with nearby tennis players and match filters"
            className="hero-phone hero-phone-back"
            priority
          />
          <IPhone
            src="/images/screens/home.png"
            alt="RallyUp home screen showing a next match, quick actions, and player record"
            className="hero-phone hero-phone-front"
            priority
          />
          <span className="hero-orbit hero-orbit-one" aria-hidden="true" />
          <span className="hero-orbit hero-orbit-two" aria-hidden="true" />
        </div>
        <a className="hero-scroll-cue" href="#features" aria-label="Scroll to RallyUp features">
          <ArrowDownRight aria-hidden="true" />
        </a>
      </section>

      <section className="feature-section section-wrap" id="features" aria-labelledby="features-title">
        <div className="section-intro">
          <p className="eyebrow">The game, brought closer</p>
          <h2 id="features-title">Good games start with good people.</h2>
          <p>From the first invite to the final point, RallyUp helps you spend less time coordinating and more time on court.</p>
        </div>
        <div className="feature-list">
          {features.map(({ number, icon: Icon, title, text }) => (
            <article className="feature-row" key={number}>
              <span className="feature-number">{number}</span>
              <span className="feature-icon"><Icon aria-hidden="true" /></span>
              <div>
                <h3>{title}</h3>
                <p>{text}</p>
              </div>
              <ArrowRight className="feature-arrow" aria-hidden="true" />
            </article>
          ))}
          <div className="courts-note">
            <span className="courts-note-icon"><MapPin aria-hidden="true" /></span>
            <p><strong>Need a place to play?</strong><br />Find nearby courts and save your favorite spots.</p>
            <a href="#screens" aria-label="See RallyUp court finder screen"><ArrowRight aria-hidden="true" /></a>
          </div>
        </div>
      </section>

      <section className="screens-section" id="screens" aria-labelledby="screens-title">
        <div className="screens-heading section-wrap">
          <div>
            <p className="eyebrow eyebrow-light">A closer look</p>
            <h2 id="screens-title">Made for the moments<br />that make the match.</h2>
          </div>
          <p>Clear before you play. Simple while you play. Useful when you look back.</p>
        </div>

        <div className="screen-showcase section-wrap">
          <article className="screen-feature screen-feature-score">
            <div className="showcase-phone-wrap">
              <IPhone
                src="/images/screens/live-scoring.png"
                alt="RallyUp live match scoring screen with player score and point controls"
                className="showcase-phone"
              />
            </div>
            <div className="screen-caption">
              <p className="screen-index">01 / ON COURT</p>
              <h3>Keep your eyes<br />on the next point.</h3>
              <p>Live scoring keeps the match flowing and the score easy to follow.</p>
            </div>
          </article>

          <article className="screen-feature screen-feature-courts">
            <div className="showcase-phone-wrap">
              <IPhone
                src="/images/screens/court-locator.png"
                alt="RallyUp court locator screen with a map and nearby tennis venues"
                className="showcase-phone"
              />
            </div>
            <div className="screen-caption">
              <p className="screen-index">02 / FIND A COURT</p>
              <h3>Your next court,<br />closer than you think.</h3>
              <p>Explore nearby places to play and get the details before you head out.</p>
            </div>
          </article>

          <article className="screen-feature screen-feature-progress">
            <div className="showcase-phone-wrap">
              <IPhone
                src="/images/screens/performance.png"
                alt="RallyUp performance screen with tennis record, win rate, and match trends"
                className="showcase-phone"
              />
            </div>
            <div className="screen-caption">
              <p className="screen-index">03 / YOUR PROGRESS</p>
              <h3>Every match<br />adds to your story.</h3>
              <p>Look back on your results, rivalries, and the progress between them.</p>
            </div>
          </article>
        </div>
      </section>

      <section className="closing-section section-wrap" aria-labelledby="closing-title">
        <div>
          <p className="eyebrow">Play · People · Progress</p>
          <h2 id="closing-title">Ready when<br />you are.</h2>
        </div>
        <a className="button-dark" href="/app">
          Explore RallyUp <ArrowRight aria-hidden="true" />
        </a>
        <span className="closing-mark" aria-hidden="true">R</span>
      </section>

      <footer className="marketing-footer section-wrap">
        <Image
          src="/assets/branding/rallyup-logo.svg"
          alt="RallyUp"
          width={145}
          height={63}
        />
        <p>Find your people. Play more tennis.</p>
        <div className="footer-links">
          <a href="/privacy">Privacy</a>
          <a href="/terms">Terms</a>
          <a href="#top">Back to top <ArrowRight aria-hidden="true" /></a>
        </div>
      </footer>
    </main>
  );
}
