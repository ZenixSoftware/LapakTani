export const LT = {
  primary: '--lt-primary',
  primaryDark: '--lt-primary-dark',
  primaryTint: '--lt-primary-tint',
  primaryBorder: '--lt-primary-border',
  secondary: '--lt-secondary',
  secondaryDark: '--lt-secondary-dark',
  secondaryTint: '--lt-secondary-tint',
  secondaryBorder: '--lt-secondary-border',
  tertiary: '--lt-tertiary',
  tertiaryText: '--lt-tertiary-text',
  tertiaryTint: '--lt-tertiary-tint',
  tertiaryBorder: '--lt-tertiary-border',
  neutral: '--lt-neutral',
  neutralMuted: '--lt-neutral-muted',
  neutralSubtle: '--lt-neutral-subtle',
  neutralBorder: '--lt-neutral-border',
  border: '--lt-border',
  surfaceCard: '--lt-surface-card',
  surfaceCanvas: '--lt-surface-canvas',
  error: '--lt-error',
  errorTint: '--lt-error-tint',
  errorBorder: '--lt-error-border',
} as const;

export function cssVar(name: string): string {
  if (typeof document === 'undefined') return '';
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}
