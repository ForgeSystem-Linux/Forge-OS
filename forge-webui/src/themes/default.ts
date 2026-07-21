/**
 * Forge DE - Theme System
 */

export interface ForgeTheme {
  name: string;
  colors: {
    primary: string;
    secondary: string;
    background: string;
    surface: string;
    text: string;
    textSecondary: string;
    border: string;
    error: string;
    warning: string;
    success: string;
  };
  spacing: {
    xs: string;
    sm: string;
    md: string;
    lg: string;
    xl: string;
  };
  borderRadius: {
    sm: string;
    md: string;
    lg: string;
  };
}

export const defaultTheme: ForgeTheme = {
  name: "Forge Dark",
  colors: {
    primary: "#6366f1",
    secondary: "#8b5cf6",
    background: "#0f0f23",
    surface: "#1a1a2e",
    text: "#ffffff",
    textSecondary: "#a1a1aa",
    border: "#27272a",
    error: "#ef4444",
    warning: "#f59e0b",
    success: "#22c55e",
  },
  spacing: {
    xs: "4px",
    sm: "8px",
    md: "16px",
    lg: "24px",
    xl: "32px",
  },
  borderRadius: {
    sm: "4px",
    md: "8px",
    lg: "12px",
  },
};

export function generateCSSVariables(theme: ForgeTheme): string {
  const vars: string[] = [];
  
  Object.entries(theme.colors).forEach(([key, value]) => {
    vars.push(`--forge-color-${key}: ${value}`);
  });

  Object.entries(theme.spacing).forEach(([key, value]) => {
    vars.push(`--forge-spacing-${key}: ${value}`);
  });

  Object.entries(theme.borderRadius).forEach(([key, value]) => {
    vars.push(`--forge-radius-${key}: ${value}`);
  });

  return `:root {\n  ${vars.join(";\n  ")};\n}`;
}
