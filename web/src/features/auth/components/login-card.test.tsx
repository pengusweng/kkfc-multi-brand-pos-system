// @vitest-environment jsdom
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { expect, test, vi } from "vitest";
import { server } from "@/tests/mocks/server";
import { useLogin } from "../hooks/useLogin";
import LoginCard from "./login-card";

test("shows the API's invalid-credentials error without navigating", async () => {
  server.use(http.post("*/api/auth/login", () =>
    HttpResponse.json({ message: "Invalid credentials" }, { status: 401 }),
  ));
  const onSuccess = vi.fn();
  function LoginForm() {
    const { form, serverError } = useLogin(onSuccess);
    return <LoginCard form={form} serverError={serverError} />;
  }
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const user = userEvent.setup();
  render(<QueryClientProvider client={client}><LoginForm /></QueryClientProvider>);

  await user.type(screen.getByLabelText("Username"), "manager");
  await user.type(screen.getByLabelText("Password", { exact: true }), "wrong-password");
  await user.click(screen.getByRole("button", { name: "Sign In" }));

  expect(await screen.findByRole("alert")).toHaveTextContent("Invalid username or password.");
  expect(onSuccess).not.toHaveBeenCalled();
  client.clear();
});
