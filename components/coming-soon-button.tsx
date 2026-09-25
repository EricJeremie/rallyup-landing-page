import Link from "next/link";
import { ArrowRight } from "lucide-react";
import type { ReactNode } from "react";

export function ComingSoonButton({
  className,
  children = "Explore RallyUp",
}: {
  className: string;
  children?: ReactNode;
}) {
  return (
    <Link
      href="/app"
      prefetch={false}
      className={`coming-soon-button ${className}`}
    >
      {children}
      <ArrowRight aria-hidden="true" />
    </Link>
  );
}
