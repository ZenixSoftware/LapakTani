const v = (name) => `color-mix(in srgb, var(${name}) calc(<alpha-value> * 100%), transparent)`;

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
        "lt-primary": v("--lt-primary"),
        "lt-primary-dark": v("--lt-primary-dark"),
        "lt-primary-tint": v("--lt-primary-tint"),
        "lt-primary-border": v("--lt-primary-border"),
        "lt-secondary": v("--lt-secondary"),
        "lt-secondary-dark": v("--lt-secondary-dark"),
        "lt-secondary-tint": v("--lt-secondary-tint"),
        "lt-secondary-border": v("--lt-secondary-border"),
        "lt-tertiary": v("--lt-tertiary"),
        "lt-tertiary-text": v("--lt-tertiary-text"),
        "lt-tertiary-tint": v("--lt-tertiary-tint"),
        "lt-tertiary-border": v("--lt-tertiary-border"),
        "lt-neutral": v("--lt-neutral"),
        "lt-neutral-muted": v("--lt-neutral-muted"),
        "lt-neutral-border": v("--lt-neutral-border"),
        "lt-neutral-subtle": v("--lt-neutral-subtle"),
        "lt-border": v("--lt-border"),
        "lt-surface-card": v("--lt-surface-card"),
        "lt-surface-canvas": v("--lt-surface-canvas"),
        "lt-error": v("--lt-error"),
        "lt-error-tint": v("--lt-error-tint"),
        "lt-error-border": v("--lt-error-border"),
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
