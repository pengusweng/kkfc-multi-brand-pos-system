// Sized to one 20px line of table text so skeleton rows match real row heights.
export default function SkeletonBar({ className }: { className: string }) {
  return <span className={`my-0.75 block h-3.5 rounded-full bg-ink/8 ${className}`} />;
}
