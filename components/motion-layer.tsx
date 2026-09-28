"use client";

import { useEffect } from "react";

export function MotionLayer() {
  useEffect(() => {
    const root = document.documentElement;
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const revealNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-reveal]"));
    const parallaxNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-parallax]"));
    const tiltNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-tilt]"));
    const pointerGlowNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-pointer-glow]"));
    const magneticNodes = Array.from(document.querySelectorAll<HTMLElement>("[data-magnetic]"));
    let observer: IntersectionObserver | null = null;
    let frame = 0;

    root.classList.add("motion-ready");

    if (reducedMotion) {
      revealNodes.forEach((node) => node.classList.add("is-visible"));
    } else {
      revealNodes.forEach((node, index) => {
        if (!node.style.getPropertyValue("--reveal-delay")) {
          const explicitDelay = Number(node.dataset.revealDelay ?? 0);
          node.style.setProperty("--reveal-delay", `${explicitDelay || Math.min(index * 55, 260)}ms`);
        }
      });
      observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              (entry.target as HTMLElement).classList.add("is-visible");
              observer?.unobserve(entry.target);
            }
          });
        },
        { rootMargin: "0px 0px -10% 0px", threshold: 0.12 },
      );
      revealNodes.forEach((node) => observer?.observe(node));
    }

    const updateScroll = () => {
      const maxScroll = root.scrollHeight - window.innerHeight;
      const progress = maxScroll > 0 ? window.scrollY / maxScroll : 0;
      root.style.setProperty("--scroll-progress", progress.toFixed(3));

      if (!reducedMotion) {
        parallaxNodes.forEach((node) => {
          const speed = Number(node.dataset.parallax ?? 0);
          const rect = node.getBoundingClientRect();
          const distanceFromCenter = rect.top + rect.height / 2 - window.innerHeight / 2;
          node.style.setProperty("--parallax-y", `${Math.round(distanceFromCenter * speed * -0.12)}px`);
        });
      }
    };
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(() => { frame = 0; updateScroll(); });
    };

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

    const updatePointerGlow = (event: PointerEvent) => {
      const node = event.currentTarget as HTMLElement;
      const bounds = node.getBoundingClientRect();
      node.style.setProperty("--pointer-x", `${event.clientX - bounds.left}px`);
      node.style.setProperty("--pointer-y", `${event.clientY - bounds.top}px`);
    };
    const resetPointerGlow = (event: PointerEvent) => {
      const node = event.currentTarget as HTMLElement;
      node.style.setProperty("--pointer-x", `${node.clientWidth * 0.5}px`);
      node.style.setProperty("--pointer-y", `${node.clientHeight * 0.35}px`);
    };
    const updateMagnetic = (event: PointerEvent) => {
      const node = event.currentTarget as HTMLElement;
      const bounds = node.getBoundingClientRect();
      const x = ((event.clientX - bounds.left) / bounds.width - 0.5) * 10;
      const y = ((event.clientY - bounds.top) / bounds.height - 0.5) * 7;
      node.style.setProperty("--magnetic-x", `${x.toFixed(2)}px`);
      node.style.setProperty("--magnetic-y", `${y.toFixed(2)}px`);
    };
    const resetMagnetic = (event: PointerEvent) => {
      const node = event.currentTarget as HTMLElement;
      node.style.setProperty("--magnetic-x", "0px");
      node.style.setProperty("--magnetic-y", "0px");
    };

    updateScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    if (!reducedMotion && window.matchMedia("(hover: hover)").matches) {
      tiltNodes.forEach((node) => {
        node.addEventListener("pointermove", onPointerMove);
        node.addEventListener("pointerleave", resetTilt);
      });
      pointerGlowNodes.forEach((node) => {
        node.addEventListener("pointermove", updatePointerGlow);
        node.addEventListener("pointerleave", resetPointerGlow);
      });
      magneticNodes.forEach((node) => {
        node.addEventListener("pointermove", updateMagnetic);
        node.addEventListener("pointerleave", resetMagnetic);
      });
    }

    return () => {
      observer?.disconnect();
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
      tiltNodes.forEach((node) => {
        node.removeEventListener("pointermove", onPointerMove);
        node.removeEventListener("pointerleave", resetTilt);
      });
      pointerGlowNodes.forEach((node) => {
        node.removeEventListener("pointermove", updatePointerGlow);
        node.removeEventListener("pointerleave", resetPointerGlow);
      });
      magneticNodes.forEach((node) => {
        node.removeEventListener("pointermove", updateMagnetic);
        node.removeEventListener("pointerleave", resetMagnetic);
      });
      if (frame) cancelAnimationFrame(frame);
      root.classList.remove("motion-ready");
    };
  }, []);

  return null;
}
