import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: '#4A90D9',
        secondary: '#7B61FF',
        success: '#34C759',
        warning: '#FF9500',
        danger: '#FF3B30',
      },
    },
  },
  plugins: [],
};

export default config;
