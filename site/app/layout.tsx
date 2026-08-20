import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "DevPulse — Your code's heartbeat, always in sight",
  description: "A macOS menu bar app that monitors your opencode sessions in real-time. See agent states, token usage, and subagent activity at a glance.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className="h-full antialiased" data-mode="dark">
      <body className="min-h-full flex flex-col bg-[#0a0a0f] text-[#f0f0f5]">{children}</body>
    </html>
  );
}
