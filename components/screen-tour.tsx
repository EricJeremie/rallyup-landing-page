"use client";

import Image from "next/image";
import { ArrowRight, MapPin, Search, Swords, Trophy } from "lucide-react";
import { useRef, useState, type KeyboardEvent } from "react";

const screens = [
  {
    id: "players",
    label: "Find players",
    eyebrow: "01 / PEOPLE",
    title: "Find someone who plays your game.",
    body: "Browse nearby players by level, availability, and match fit.",
    src: "/images/screens/find-players.png",
    alt: "RallyUp Find Players screen",
    icon: Search,
  },
  {
    id: "score",
    label: "Score live",
    eyebrow: "02 / PLAY",
    title: "Keep the match moving.",
    body: "Track every point with a live score built for the court.",
    src: "/images/screens/live-scoring.png",
    alt: "RallyUp live match scoring screen",
    icon: Swords,
  },
  {
    id: "courts",
    label: "Find courts",
    eyebrow: "03 / PLAY",
    title: "Know where the next rally starts.",
    body: "See nearby courts and the details you need before you head out.",
    src: "/images/screens/court-locator.png",
    alt: "RallyUp court locator screen",
    icon: MapPin,
  },
  {
    id: "progress",
    label: "Track progress",
    eyebrow: "04 / PROGRESS",
    title: "Every match adds up.",
    body: "Keep your record, rivalries, and progress in one place.",
    src: "/images/screens/performance.png",
    alt: "RallyUp performance screen",
    icon: Trophy,
  },
] as const;

export function ScreenTour() {
  const [activeId, setActiveId] = useState<(typeof screens)[number]["id"]>("players");
  const tabRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const active = screens.find((screen) => screen.id === activeId) ?? screens[0];
  const Icon = active.icon;
  const selectTab = (index: number) => {
    const nextIndex = (index + screens.length) % screens.length;
    setActiveId(screens[nextIndex].id);
    tabRefs.current[nextIndex]?.focus();
  };
  const onTabKeyDown = (event: KeyboardEvent<HTMLButtonElement>, index: number) => {
    if (event.key === "ArrowRight" || event.key === "ArrowDown") {
      event.preventDefault();
      selectTab(index + 1);
    } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
      event.preventDefault();
      selectTab(index - 1);
    } else if (event.key === "Home") {
      event.preventDefault();
      selectTab(0);
    } else if (event.key === "End") {
      event.preventDefault();
      selectTab(screens.length - 1);
    }
  };

  return (
    <div className="screen-tour" data-reveal="fade-up">
      <div className="screen-tour-tabs" role="tablist" aria-label="RallyUp features">
        {screens.map((screen, index) => {
          const TabIcon = screen.icon;
          return (
            <button
              key={screen.id}
              type="button"
              ref={(node) => { tabRefs.current[index] = node; }}
              role="tab"
              aria-selected={active.id === screen.id}
              aria-controls="rallyup-tour-panel"
              id={`rallyup-tour-tab-${screen.id}`}
              tabIndex={active.id === screen.id ? 0 : -1}
              className={active.id === screen.id ? "is-active" : ""}
              onClick={() => setActiveId(screen.id)}
              onKeyDown={(event) => onTabKeyDown(event, index)}
            >
              <TabIcon aria-hidden="true" />
              <span>{screen.label}</span>
            </button>
          );
        })}
      </div>
      <div className="screen-tour-stage" role="tabpanel" id="rallyup-tour-panel" aria-labelledby={`rallyup-tour-tab-${active.id}`} tabIndex={0}>
        <div className="screen-tour-copy" key={`${active.id}-copy`}>
          <div className="screen-tour-icon"><Icon aria-hidden="true" /></div>
          <p className="screen-index">{active.eyebrow}</p>
          <h3>{active.title}</h3>
          <p>{active.body}</p>
          <span className="screen-tour-hint">Tap a feature to explore <ArrowRight aria-hidden="true" /></span>
        </div>
        <div className="screen-tour-phone" key={`${active.id}-phone`}>
          <div className="iphone-mockup screen-tour-device" data-tilt>
            <div className="iphone-screen">
              <Image src={active.src} alt={active.alt} fill sizes="(max-width: 680px) 58vw, 330px" className="iphone-screen-image" />
              <span className="iphone-island" aria-hidden="true" />
            </div>
          </div>
          <span className="screen-tour-shadow" aria-hidden="true" />
        </div>
      </div>
    </div>
  );
}
