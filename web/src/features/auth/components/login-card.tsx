"use client";

import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export default function LoginCard() {
  const [showPassword, setShowPassword] = useState(false);

  return(
    <Card className="w-full max-w-md gap-6 [--card-spacing:--spacing(5)] sm:[--card-spacing:--spacing(8)]">
      <CardHeader>
        <CardTitle>
          <h1 className="text-xl font-semibold sm:text-2xl">Sign In</h1>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <form id="login-form">
          <div className="flex flex-col gap-6">
            <div className="grid gap-2">
              <Label htmlFor="username">Username</Label>
              <Input 
                id="username"
                type="text"
                className="h-12 px-3 md:text-base"
                placeholder="Enter your username"
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  className="h-12 pr-14 pl-3 md:text-base"
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

            <Button type="submit" form="login-form" className="h-12 w-full text-base cursor-pointer">
              Sign In
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
