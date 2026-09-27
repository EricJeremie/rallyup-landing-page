"use client";

import Image from "next/image";

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
  return (
    <div className="mockup-carousel" aria-label="RallyUp app screens">
      <div className="mockup-carousel-controls">
        <span>EXPLORE THE APP</span>
      </div>
      <div className="mockup-carousel-track" tabIndex={0}>
        {[0, 1].map((group) => (
          <div className="mockup-carousel-group" key={group} aria-hidden={group === 1}>
            {mockups.map(([name, label]) => (
              <figure className="mockup-carousel-item" key={`${group}-${name}`}>
                <Image src={`/images/mockups/${name}.png`} alt={`RallyUp ${label} screen`} width={410} height={887} sizes="(max-width: 680px) 68vw, 245px" />
                <figcaption>{label}</figcaption>
              </figure>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
