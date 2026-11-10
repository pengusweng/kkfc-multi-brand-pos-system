"use client";

import { useEffect, useRef, type ReactNode } from "react";
import PageBackground from "@/src/components/layout/page-background";

const waveShapes = [
  [
    "M0 0H217C185 52 128 59 73 70C31 82 13 104 0 129Z",
    "M0 0H143C110 38 62 40 0 60Z",
  ],
  [
    "M345 605C418 549 451 545 523 553C658 575 675 452 786 393V605Z",
    "M444 605C540 552 595 557 640 557C705 557 752 507 786 483V605Z",
  ],
];

export default function LoginBackground({ children }: { children: ReactNode }) {
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const layers = rootRef.current?.querySelectorAll<SVGSVGElement>(":scope > main > svg");
    if (!layers) return;

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    const animations: SVGAnimationElement[] = [];

    layers.forEach((layer, layerIndex) => {
      layer.pauseAnimations();
      layer.querySelectorAll("path").forEach((path, pathIndex) => {
        const original = path.getAttribute("d");
        const wave = waveShapes[layerIndex]?.[pathIndex];
        if (!original || !wave) return;

        const animation = document.createElementNS("http://www.w3.org/2000/svg", "animate");
        animation.setAttribute("attributeName", "d");
        animation.setAttribute("values", `${original};${wave};${original}`);
        animation.setAttribute("dur", layerIndex === 0 ? "8s" : "10s");
        animation.setAttribute("begin", `${-pathIndex * 0.8}s`);
        animation.setAttribute("repeatCount", "indefinite");
        animation.setAttribute("calcMode", "spline");
        animation.setAttribute("keyTimes", "0;0.5;1");
        animation.setAttribute("keySplines", "0.45 0 0.55 1;0.45 0 0.55 1");
        const drift = document.createElementNS("http://www.w3.org/2000/svg", "animateTransform");
        drift.setAttribute("attributeName", "transform");
        drift.setAttribute("type", "translate");
        drift.setAttribute("values", `0 0;${layerIndex === 0 ? -14 : 22} 0;0 0`);
        drift.setAttribute("dur", layerIndex === 0 ? "8s" : "10s");
        drift.setAttribute("begin", `${-pathIndex * 1.4}s`);
        drift.setAttribute("repeatCount", "indefinite");
        drift.setAttribute("calcMode", "spline");
        drift.setAttribute("keyTimes", "0;0.5;1");
        drift.setAttribute("keySplines", "0.45 0 0.55 1;0.45 0 0.55 1");
        path.append(animation, drift);
        animations.push(animation, drift);
      });
      layer.setCurrentTime(0);
    });

    const visibleLayers = new Set<Element>();
    const updatePlayback = () => {
      layers.forEach((layer) => {
        if (document.hidden || reducedMotion.matches || !visibleLayers.has(layer)) {
          layer.pauseAnimations();
        } else {
          layer.unpauseAnimations();
        }
      });
    };
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) visibleLayers.add(entry.target);
        else visibleLayers.delete(entry.target);
      });
      updatePlayback();
    });

    layers.forEach((layer) => observer.observe(layer));
    document.addEventListener("visibilitychange", updatePlayback);
    reducedMotion.addEventListener("change", updatePlayback);

    return () => {
      observer.disconnect();
      document.removeEventListener("visibilitychange", updatePlayback);
      reducedMotion.removeEventListener("change", updatePlayback);
      animations.forEach((animation) => animation.remove());
    };
  }, []);

  return (
    <div
      ref={rootRef}
      data-login-background
      className="flex min-w-0 flex-1 [&>main]:min-h-0 [&>main]:overflow-clip [&>main]:pt-10 sm:[&>main]:pt-16 lg:[&>main]:min-h-dvh lg:[&>main]:pt-8 [&>main>svg:first-of-type]:w-72 [&>main>svg:last-of-type]:w-96 lg:[&>main>svg:first-of-type]:w-112 lg:[&>main>svg:last-of-type]:w-160"
    >
      <PageBackground>{children}</PageBackground>
    </div>
  );
}
