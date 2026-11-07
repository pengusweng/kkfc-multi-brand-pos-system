import UnauthorizedPage from "@/src/features/auth/containers/unauthorized";
import type { Metadata } from "next";

export const instant = false;

export const metadata: Metadata = {
  title: "Access restricted | KKFC Management",
};

export default function Unauthorized() {
  return(
    <UnauthorizedPage />    
  );
}
