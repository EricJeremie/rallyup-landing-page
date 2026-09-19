import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "RallyUp — Find your match",
  description: "Find tennis players, schedule matches, score live, and track your game.",
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="antialiased">{children}</body>
    </html>
  );
}
