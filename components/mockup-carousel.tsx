"use client";

import Image from "next/image";
import { useEffect, useRef } from "react";

const mockups = [
  ["courts", "Courts"],
  ["performance", "Performance"],
  ["live-scorekeeper", "Live scorekeeper"],
  ["point-scoring", "Point scoring"],
  ["match-details", "Match details"],
  ["player-profile", "Player profile"],
  ["find-players", "Find players"],
  ["home", "Home"],
] as const;

export function MockupCarousel() {
  const trackRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const track = trackRef.current;
    if (!track || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const timer = window.setInterval(() => {
      const maxScroll = track.scrollWidth - track.clientWidth;
      if (track.scrollLeft >= maxScroll - 8) {
        track.scrollTo({ left: 0, behavior: "smooth" });
      } else {
        track.scrollBy({ left: 300, behavior: "smooth" });
      }
    }, 2600);

    return () => window.clearInterval(timer);
  }, []);

  return (
    <div className="mockup-carousel" aria-label="RallyUp app screens">
      <div className="mockup-carousel-controls">
        <span>EXPLORE THE APP</span>
      </div>
      <div className="mockup-carousel-track" ref={trackRef} tabIndex={0}>
        {mockups.map(([name, label]) => (
          <figure className="mockup-carousel-item" key={name}>
            <Image src={`/images/mockups/${name}.png`} alt={`RallyUp ${label} screen`} width={410} height={887} sizes="(max-width: 680px) 68vw, 245px" />
            <figcaption>{label}</figcaption>
          </figure>
        ))}
      </div>
    </div>
  );
}
