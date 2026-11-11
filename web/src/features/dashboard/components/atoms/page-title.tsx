export default function PageTitle({ children }: { children: string }) {
  return (
    <h1 className="text-2xl font-semibold tracking-[-0.01em] text-ink">{children}</h1>
  );
}
