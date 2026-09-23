import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "RallyUp — More tennis. Better days.",
  description: "Find tennis players, set up a match, find a court, and keep track of your game with RallyUp.",
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
