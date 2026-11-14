import SkeletonBar from "@/src/components/ui/atoms/skeleton-bar";

// Stands in for the Items and History sections while the order's lines load;
// same headings and rhythm, so nothing jumps when the real content arrives.
export default function OrderDetailSkeleton() {
  return (
    <div aria-hidden="true" className="motion-safe:animate-pulse">
      <section className="mt-6">
        <p className="mb-1 text-sm font-semibold text-ink">Items</p>
        {["w-40", "w-32"].map((width) => (
          <div key={width} className="grid grid-cols-[2rem_minmax(0,1fr)_auto] gap-x-3 border-t border-hairline py-3">
            <SkeletonBar className="w-5" />
            <div className="flex flex-col gap-1.5">
              <SkeletonBar className={width} />
              <SkeletonBar className="w-24" />
            </div>
            <SkeletonBar className="w-16" />
          </div>
        ))}
      </section>
      <section className="mt-6">
        <p className="mb-1 text-sm font-semibold text-ink">History</p>
        <div className="flex flex-col gap-4 border-t border-hairline pt-3">
          {["w-28", "w-24", "w-36"].map((width) => (
            <div key={width} className="grid grid-cols-[0.625rem_minmax(0,1fr)_auto] items-center gap-x-3">
              <span className="size-2.5 rounded-full bg-ink/10" />
              <SkeletonBar className={width} />
              <SkeletonBar className="w-20" />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
