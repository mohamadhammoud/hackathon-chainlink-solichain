'use client'
import { useDisconnect, useAppKit, useAppKitNetwork, useAppKitAccount  } from '@reown/appkit/react'
import { networks } from '@/config'

export const ActionButtonList = () => {
    const { disconnect } = useDisconnect();
    const { switchNetwork } = useAppKitNetwork();
    // const { open } = useAppKit();

    const {address, caipAddress, isConnected, embeddedWalletInfo} = useAppKitAccount();


    const handleDisconnect = async () => {
      try {
        await disconnect();
      } catch (error) {
        console.error("Failed to disconnect:", error);
      }
    }
  return (
    <div>
        {/* <button onClick={() => open()}>Open</button> */}
       {isConnected &&  <button onClick={handleDisconnect}>Disconnect</button>}
        <button onClick={() => switchNetwork(networks[1]) }>Switch</button>
    </div>
  )
}
