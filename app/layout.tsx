import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "RallyUp — Find your people. Play your best game.",
  description: "Find players, discover courts, play more matches, and track your tennis progress with RallyUp.",
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
