import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ArrowLeft, ArrowRight } from "lucide-react";

import { MotionLayer } from "@/components/motion-layer";

export const metadata: Metadata = {
  title: "Coming soon — RallyUp",
  description: "RallyUp is getting ready for its next match.",
};

export default function ComingSoonPage() {
  return (
    <main className="bevel2-coming-soon">
      <MotionLayer />

      <header className="bevel2-coming-header">
        <Link href="/" className="bevel2-coming-logo" aria-label="Back to RallyUp home">
          <Image src="/assets/branding/rallyup-logo-dark.svg" alt="RallyUp" width={108} height={47} priority />
        </Link>
        <Link href="/" className="bevel2-coming-back">
          Back to home <ArrowLeft aria-hidden="true" />
        </Link>
      </header>

      <section className="bevel2-coming-stage" aria-labelledby="coming-soon-title">
        <div className="bevel2-coming-orbit bevel2-coming-orbit-one" aria-hidden="true" />
        <div className="bevel2-coming-orbit bevel2-coming-orbit-two" aria-hidden="true" />
        <div className="bevel2-coming-copy" data-reveal="fade-up" data-reveal-children>
          <p className="bevel2-overline">THE NEXT RALLY IS CLOSE</p>
          <h1 id="coming-soon-title">RallyUp is<br /><em>coming soon.</em></h1>
          <p>We&apos;re putting the finishing touches on the app that helps you find your people, play more matches, and keep your game moving.</p>
          <div className="bevel2-coming-actions">
            <Link href="/" className="bevel2-dark-button">
              <ArrowLeft aria-hidden="true" /> Back to home
            </Link>
            <a href="mailto:hello@rallyup.app" className="bevel2-coming-contact">
              Get launch updates <ArrowRight aria-hidden="true" />
            </a>
          </div>
        </div>

        <div className="bevel2-coming-mark" data-reveal="fade-up" data-reveal-delay="140" aria-hidden="true">
          <div className="bevel2-coming-ball"><Image src="/assets/branding/rallyup-ball.svg" alt="" width={270} height={270} /></div>
          <span>PLAY · PEOPLE · PROGRESS</span>
        </div>
      </section>
    </main>
  );
}
