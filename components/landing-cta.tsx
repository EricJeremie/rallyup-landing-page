import { ArrowRight } from "lucide-react";
import type { ReactNode } from "react";

export function LandingCta({
  className,
  children = "Explore RallyUp",
}: {
  className: string;
  children?: ReactNode;
}) {
  return (
    <a href="#product" className={`landing-cta ${className}`}>
      {children}
      <ArrowRight aria-hidden="true" />
    </a>
  );
}
