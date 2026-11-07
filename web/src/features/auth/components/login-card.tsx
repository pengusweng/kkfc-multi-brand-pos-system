"use client";

import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/src/components/ui/atoms/input";
import { Button } from "@/components/ui/button";

export default function LoginCard() {
  const [showPassword, setShowPassword] = useState(false);

  return(
    <Card className="w-full self-center justify-self-center gap-8 rounded-none ring-0 [--card-spacing:--spacing(6)] lg:max-w-132 lg:[--card-spacing:--spacing(12)]">
      <CardHeader>
        <CardTitle>
          <h1 className="text-2xl leading-8 font-semibold tracking-tight">Sign In</h1>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <form id="login-form">
          <div className="flex flex-col gap-6">
            <div className="grid gap-2">
              <Label htmlFor="username" className="leading-5">Username</Label>
              <Input 
                id="username"
                type="text"
                placeholder="Enter your username"
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="password" className="leading-5">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  className="pr-14"
                  placeholder="Enter your password"
                  required
                />
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="absolute top-0.5 right-0.5 size-11 cursor-pointer"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  aria-controls="password"
                  onClick={() => setShowPassword((visible) => !visible)}
                >
                  {showPassword ? <EyeOff className="size-5" aria-hidden="true" /> : <Eye className="size-5" aria-hidden="true" />}
                </Button>
              </div>
            </div>

            <Button type="submit" form="login-form" className="h-12 w-full cursor-pointer text-base font-semibold">
              Sign In
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
