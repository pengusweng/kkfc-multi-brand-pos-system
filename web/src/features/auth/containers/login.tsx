import PageBackground from "@/src/components/layout/page-background";
import LoginCard from "../components/login-card";
import LoginSide from "../components/login-side";

export default function LoginPage(){
  return (
    <div className="flex min-h-dvh flex-1 flex-col lg:flex-row">
      <LoginSide />
      <PageBackground>
        <LoginCard />
      </PageBackground>
    </div>
  )
}
