"use client";

import { useEffect } from "react";

export function MotionLayer() {
  useEffect(() => {
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const revealNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-reveal]"));
    const parallaxNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-parallax]"));
    const tiltNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-tilt]"));

    if (reducedMotion) {
      revealNodes.forEach((node) => node.classList.add("is-visible"));
    } else {
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              (entry.target as HTMLElement).classList.add("is-visible");
              observer.unobserve(entry.target);
            }
          });
        },
        { rootMargin: "0px 0px -10% 0px", threshold: 0.12 },
      );
      revealNodes.forEach((node) => observer.observe(node));

      const updateScroll = () => {
        const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
        const progress = maxScroll > 0 ? window.scrollY / maxScroll : 0;
        document.documentElement.style.setProperty("--scroll-progress", progress.toFixed(3));

        parallaxNodes.forEach((node) => {
          const speed = Number(node.dataset.parallax ?? 0);
          const rect = node.getBoundingClientRect();
          const distanceFromCenter = rect.top + rect.height / 2 - window.innerHeight / 2;
          node.style.setProperty("--parallax-y", `${Math.round(distanceFromCenter * speed * -0.12)}px`);
        });
      };
      let frame = 0;
      const onScroll = () => {
        if (!frame) frame = requestAnimationFrame(() => { frame = 0; updateScroll(); });
      };
      updateScroll();
      window.addEventListener("scroll", onScroll, { passive: true });
      window.addEventListener("resize", onScroll);

      return () => {
        observer.disconnect();
        window.removeEventListener("scroll", onScroll);
        window.removeEventListener("resize", onScroll);
        if (frame) cancelAnimationFrame(frame);
      };
    }

    const onPointerMove = (event: PointerEvent) => {
      const node = event.currentTarget as HTMLElement;
      const bounds = node.getBoundingClientRect();
      const x = ((event.clientX - bounds.left) / bounds.width - 0.5) * 2;
      const y = ((event.clientY - bounds.top) / bounds.height - 0.5) * 2;
      node.style.setProperty("--tilt-x", `${(y * -2.2).toFixed(2)}deg`);
      node.style.setProperty("--tilt-y", `${(x * 2.2).toFixed(2)}deg`);
    };
    const resetTilt = (event: PointerEvent) => {
      const node = event.currentTarget as HTMLElement;
      node.style.setProperty("--tilt-x", "0deg");
      node.style.setProperty("--tilt-y", "0deg");
    };

    if (!reducedMotion && window.matchMedia("(hover: hover)").matches) {
      tiltNodes.forEach((node) => {
        node.addEventListener("pointermove", onPointerMove);
        node.addEventListener("pointerleave", resetTilt);
      });
    }

    return () => {
      tiltNodes.forEach((node) => {
        node.removeEventListener("pointermove", onPointerMove);
        node.removeEventListener("pointerleave", resetTilt);
      });
    };
  }, []);

  return null;
}
