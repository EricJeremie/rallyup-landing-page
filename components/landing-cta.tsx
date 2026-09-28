import { ArrowRight } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";

export function LandingCta({
  className,
  children = "Explore RallyUp",
}: {
  className: string;
  children?: ReactNode;
}) {
  return (
    <Link href="/coming-soon" className={`landing-cta ${className}`} data-magnetic>
      <span className="landing-cta-label">{children}</span>
      <ArrowRight aria-hidden="true" />
    </Link>
  );
}
