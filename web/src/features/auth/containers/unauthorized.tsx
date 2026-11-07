import PageBackground from "@/src/components/layout/page-background";
import LoginSide from "../components/login-side";
import { ArrowRight, LockKeyhole } from "lucide-react";
import Link from "next/link";
import { cn } from "cn";
import { buttonVariants } from "@/components/ui/button";

export default function UnauthorizedPage() {
  return (
    <PageBackground>
      <section
        aria-labelledby="access-denied-title"
        className="grid w-full max-w-md overflow-hidden rounded-[1rem] border border-[#e3d8cc] bg-card selection:bg-primary/15 selection:text-[#19293e] lg:min-h-140 lg:max-w-240 lg:grid-cols-[20rem_minmax(0,1fr)]"
      >
        <LoginSide />

        <div className="w-full max-w-132 self-center justify-self-center px-6 py-8 lg:p-12">
          <LockKeyhole aria-hidden="true" strokeWidth={1.75} className="size-9 text-primary" />

          <h1
            id="access-denied-title"
            className="mt-6 text-2xl leading-tight font-semibold tracking-tight text-balance text-[#19293e] sm:text-3xl"
          >
            Web access restricted
          </h1>
          <p className="mt-3 text-base leading-7 text-[#526070]">
            Your role doesn&apos;t include access to KKFC Web Management.
            Please sign in with an authorized account.
          </p>

          <Link
            href="/login"
            className={cn(
              buttonVariants(),
              "mt-8 h-12 w-full gap-2 text-base font-semibold focus-visible:border-primary focus-visible:ring-primary/25",
            )}
          >
            Back to sign in
            <ArrowRight aria-hidden="true" className="size-4" />
          </Link>

          <div className="mt-8 flex items-start justify-between gap-6 border-t border-[#e3d8cc] pt-6 text-sm leading-6 text-[#526070]">
            <p className="max-w-64">
              Need web access? Contact your company administrator.
            </p>
            <span aria-label="Error 403: Forbidden" className="shrink-0 font-medium tabular-nums">
              403
            </span>
          </div>
        </div>
      </section>
    </PageBackground>
  );
}
