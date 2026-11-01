import type { Config } from "tailwindcss";

// Todas as cores vêm de variáveis CSS (tokens.css). Nos componentes use bg-surface, text-muted, etc., nunca hex.
const v = (name: string) => `var(--color-${name})`;

export default {
  darkMode: ["selector", '[data-theme="dark"]'],
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        bg: v("bg"),
        surface: v("surface"),
        "surface-2": v("surface-2"),
        border: v("border"),
        "border-input": v("border-input"),
        text: v("text"),
        muted: v("text-muted"),
        accent: v("accent"),
        "on-accent": v("on-accent"),
        "accent-soft": v("accent-soft"),
        danger: v("danger"),
        success: v("success"),
        warning: v("warning"),
        info: v("info"),
        series: Object.fromEntries(Array.from({ length: 10 }, (_, i) => [i + 1, `var(--series-${i + 1})`])),
      },
      fontFamily: { sans: ["var(--font-sans)"], display: ["var(--font-display)"], mono: ["var(--font-mono)"] },
      borderRadius: { sm: "var(--radius-sm)", md: "var(--radius-md)", lg: "var(--radius-lg)", pill: "var(--radius-pill)" },
      boxShadow: { card: "var(--shadow-card)", pop: "var(--shadow-pop)" },
      screens: { sm: "640px", md: "900px", lg: "1200px" },
      transitionDuration: { fast: "120ms", base: "200ms" },
    },
  },
} satisfies Config;
