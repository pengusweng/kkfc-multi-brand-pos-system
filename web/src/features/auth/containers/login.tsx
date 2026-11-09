"use client";

import LoginBackground from "../components/login-background";
import LoginCard from "../components/login-card";
import LoginSide from "../components/login-side";
import { useLogin } from "../hooks/useLogin";
import { WEB_ROLES } from "../utils/webRoles";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const { form, serverError, session } = useLogin(({ user }) => {
    router.replace(WEB_ROLES.has(user.role) ? "/dashboard" : "/unauthorized");
  });

  return (
    <div className="flex min-h-dvh flex-1 flex-col selection:bg-primary/15 selection:text-[#19293e] lg:flex-row">
      <LoginSide className="lg:sticky lg:top-0 lg:h-dvh lg:w-[26rem] lg:shrink-0 lg:px-12 xl:w-[30rem]" />
      <LoginBackground>
        <LoginCard form={form} serverError={serverError} redirecting={Boolean(session)} />
      </LoginBackground>
    </div>
  );
}
