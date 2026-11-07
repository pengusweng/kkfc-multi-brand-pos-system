export default function LoginSide() {
  return (
    <aside
      aria-label="KKFC Web Management"
      className="relative isolate flex flex-col justify-between overflow-hidden bg-[rgb(25,41,62)] px-6 py-6 text-white sm:px-8 lg:py-12"
    >
      <svg
        aria-hidden="true"
        viewBox="0 0 464 910"
        preserveAspectRatio="xMaxYMid slice"
        fill="none"
        stroke="currentColor"
        strokeWidth="1"
        className="pointer-events-none absolute inset-y-0 right-0 -z-10 h-full w-1/3 text-primary opacity-40 lg:inset-y-auto lg:top-32 lg:h-52 lg:w-full lg:opacity-60 lg:[mask-image:linear-gradient(to_bottom,transparent,black_15%,black_85%,transparent)]"
      >
        <path d="M-30 566C99 468 169 485 251 435S365 277 410 177S448 93 480 50" vectorEffect="non-scaling-stroke" />
        <path d="M-30 619C97 520 175 532 266 477S378 323 426 227S461 157 490 113" vectorEffect="non-scaling-stroke" />
        <path d="M-30 673C95 575 181 574 278 520S391 372 441 278S474 223 502 184" vectorEffect="non-scaling-stroke" />
        <path d="M-30 732C91 635 188 616 290 563S405 423 455 330S487 290 514 255" vectorEffect="non-scaling-stroke" />
      </svg>

      <p className="text-center lg:text-left">
        <span className="text-xl font-bold tracking-[0.12em] lg:text-3xl">KKFC</span>{" "}
        <span className="text-base text-[#c7d9ed] lg:mt-2 lg:block lg:text-lg">Web Management</span>
      </p>

      <ul className="mt-6 flex flex-wrap justify-center gap-x-3 gap-y-2 border-t border-[#30445a] pt-4 text-sm sm:gap-x-5 lg:mt-32 lg:block lg:border-t-0 lg:pt-0 lg:text-base">
        <li className="lg:border-t lg:border-[#30445a] lg:py-4">Gamcheon</li>
        <li className="lg:border-t lg:border-[#30445a] lg:py-4">Aurelia&apos;s Inasal</li>
        <li className="lg:border-t lg:border-[#30445a] lg:pt-4">King Kung&apos;s Kafé</li>
      </ul>
    </aside>
  );
}
