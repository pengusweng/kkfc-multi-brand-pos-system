export const STORAGE_KEY = "theme";
export const DARK_QUERY = "(prefers-color-scheme: dark)";

// Runs in <head> before first paint (see app/layout.tsx): a saved choice wins,
// otherwise the OS preference. Lives outside the "use client" theme module so
// the server layout receives the string itself, not a client reference.
export const THEME_SCRIPT = `(function(){try{var t=localStorage.getItem("${STORAGE_KEY}");if(t!=="light"&&t!=="dark")t=matchMedia("${DARK_QUERY}").matches?"dark":"light";document.documentElement.classList.toggle("dark",t==="dark")}catch(e){}})()`;
