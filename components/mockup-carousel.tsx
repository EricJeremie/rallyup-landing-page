"use client";

import Image from "next/image";
import { ArrowLeft, ArrowRight } from "lucide-react";
import { useRef } from "react";

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
  const scroll = (direction: number) => trackRef.current?.scrollBy({ left: direction * 360, behavior: "smooth" });

  return (
    <div className="mockup-carousel" aria-label="RallyUp app screens">
      <div className="mockup-carousel-controls">
        <span>EXPLORE THE APP</span>
        <div>
          <button type="button" aria-label="Previous mockup" onClick={() => scroll(-1)}><ArrowLeft aria-hidden="true" /></button>
          <button type="button" aria-label="Next mockup" onClick={() => scroll(1)}><ArrowRight aria-hidden="true" /></button>
        </div>
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
