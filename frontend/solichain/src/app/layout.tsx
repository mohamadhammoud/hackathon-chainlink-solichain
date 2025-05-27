import type { Metadata } from "next";

import './globals.css';
import ContextProvider from '@/context'
import { Store } from "@/store/store";
import Sidebar from "@/components/Sidebar";
import { AntdRegistry } from "@ant-design/nextjs-registry";

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

      <AntdRegistry>
      

    
        {/* <Store> */}
          <ContextProvider>   <Sidebar />
          
          {children}
          </ContextProvider>
        {/* </Store> */}

      </AntdRegistry>

     
      </body>
    </html>
  );
}
