This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3001](http://localhost:3001) with your browser to see the result.

### Backend login

The login service sends `POST /api/auth/login` through a same-origin Next.js
proxy. Configure the backend origin in `web/.env`:

```dotenv
API_URL=http://localhost:3000
```

Restart the development server after changing the backend URL.
The backend contract is documented at `http://localhost:3000/api/docs`.

`useLogin` exposes the validated `{ token, expires_at, user }` response as `session`.
The login handler also saves the token in an HttpOnly, SameSite=Lax cookie that
expires with the backend session (Secure in production). The API proxy attaches it
as a bearer token to `/api/*` requests, including `GET /api/auth/me`, after refresh.
Browser requests that change data must come from the same origin.
Post-login navigation and restoring the user into client state are not configured yet.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
