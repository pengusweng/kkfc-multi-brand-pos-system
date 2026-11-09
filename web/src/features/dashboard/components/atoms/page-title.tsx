export default function PageTitle({ children }: { children: string }) {
  return (
    <h1 className="text-2xl font-semibold tracking-[-0.02em] text-[#19293e]">{children}</h1>
  );
}
