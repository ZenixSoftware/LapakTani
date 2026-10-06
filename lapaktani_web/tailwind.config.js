/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "primary": "#03ac0e",
        "primary-dark": "#02870b",
        "forest-dark": "#0a3020",
        "forest-card": "#11422d",
        "forest-emerald": "#134e38",
        "forest-light": "#e8f7ee",
        "surface-bg": "#f6f8f6",
        "surface-white": "#ffffff",
        "neutral-slate": "#475569",
        "neutral-dark": "#131f18",
        "amber-warm": "#d97706",
        "amber-bg": "#fef3c7"
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
