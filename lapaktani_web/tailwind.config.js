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
        canvas: "#F6F3EB",
        cream: {
          50: "#FCFAF6",
          100: "#F7F3EA",
          200: "#EFE9DC",
          300: "#E4DCcb"
        },
        brutal: {
          border: "#1E293B",
          dark: "#0F172A",
          shadow: "#1E293B"
        },
        brand: {
          DEFAULT: "#2E7D32",
          hover: "#256629",
          light: "#E8F5E9",
          sage: "#D8E8D9",
          pill: "#3B7A57"
        },
        amberSoft: "#FEF3C7",
        amberText: "#92400E",
        roseSoft: "#FEE2E2",
        roseText: "#991B1B"
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
      },
      boxShadow: {
        'brutal-sm': '2px 2px 0px #1E293B',
        'brutal': '3.5px 3.5px 0px #1E293B',
        'brutal-lg': '5px 5px 0px #1E293B',
        'brutal-active': '1px 1px 0px #1E293B',
      }
    },
  },
  plugins: [],
}
