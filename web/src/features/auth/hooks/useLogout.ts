import { useMutation } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { logout } from "../services/auth.service";

export function useLogout() {
  const router = useRouter();

  return useMutation({
    mutationFn: logout,
    retry: false,
    onSuccess: () => router.replace("/login"),
  });
}
