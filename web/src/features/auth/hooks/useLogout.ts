import { useMutation } from "@tanstack/react-query";
import { useEffectEvent, useLayoutEffect } from "react";
import { useRouter } from "next/navigation";
import { logout } from "../services/auth.service";

export function useLogout() {
  const router = useRouter();

  const mutation = useMutation({
    mutationFn: logout,
    retry: false,
    onSuccess: () => router.replace("/login"),
  });

  // The hidden dashboard is restored on the next sign-in; don't bring back "Signing out…".
  const resetOnHide = useEffectEvent(() => mutation.reset());
  useLayoutEffect(() => () => resetOnHide(), []);

  return mutation;
}
