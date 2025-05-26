import type { Metadata } from "next";

import './globals.css';
import ContextProvider from '@/context'
import { Store } from "@/store/store";

export const metadata: Metadata = {
  title: "AppKit in Next.js + ethers",
  description: "AppKit example dApp",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {

  return (
    <html lang="en">
      <body>
        <Store>
          <ContextProvider>{children}</ContextProvider>
        </Store>
      </body>
    </html>
  );
}
