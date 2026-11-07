"use client";

import { useEffect } from "react";
import { useAnimate, useReducedMotion } from "framer-motion";
import LoginBackground from "../components/login-background";
import LoginCard from "../components/login-card";
import LoginSide from "../components/login-side";

export default function LoginPage(){
  const [scope, animate] = useAnimate<HTMLDivElement>();
  const reducedMotion = useReducedMotion();

  useEffect(() => {
    if (reducedMotion !== false || !scope.current) return;

    const entrance = animate(
      scope.current,
      { opacity: [0, 1], y: [14, 0] },
      { duration: 0.8, ease: [0.25, 0.1, 0.25, 1] },
    );

    return () => entrance.complete();
  }, [animate, reducedMotion, scope]);

  return (
    <LoginBackground>
      <div ref={scope} className="grid w-full max-w-md overflow-hidden rounded-[1rem] border border-[#e3d8cc] bg-card lg:min-h-140 lg:max-w-240 lg:grid-cols-[20rem_minmax(0,1fr)]">
        <LoginSide />
        <LoginCard />
      </div>
    </LoginBackground>
  )
}
