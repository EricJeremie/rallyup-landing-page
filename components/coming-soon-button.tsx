"use client";

import { ArrowRight } from "lucide-react";
import { useState, type ReactNode } from "react";

export function ComingSoonButton({
  className,
  children = "Explore RallyUp",
}: {
  className: string;
  children?: ReactNode;
}) {
  const [comingSoon, setComingSoon] = useState(false);

  return (
    <button
      type="button"
      className={`coming-soon-button ${className}`}
      onClick={() => setComingSoon(true)}
      aria-label={comingSoon ? "RallyUp is coming soon" : undefined}
    >
      {comingSoon ? "Coming Soon" : children}
      {!comingSoon && <ArrowRight aria-hidden="true" />}
    </button>
  );
}
