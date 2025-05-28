"use client";

import React, { useState } from "react";
import {
  DesktopOutlined,
  FileOutlined,
  PieChartOutlined,
  TeamOutlined,
} from "@ant-design/icons";
import type { MenuProps } from "antd";
import { Layout, Menu, theme } from "antd";
import WalletConnect from "./WalletConnect";
import BridgeFromEthereum from "./BridgeFromEthereum/BridgeFromEthereum";
import BridgeFromBase from "./BridgeFromBase/BridgeFromBase";
import RWAInvestment from "./RWAInvestment/RWAInvestment";

const { Header, Content, Footer, Sider } = Layout;

type MenuItem = Required<MenuProps>["items"][number];

function getItem(
  label: React.ReactNode,
  key: React.Key,
  icon?: React.ReactNode,
  children?: MenuItem[]
): MenuItem {
  return {
    key,
    icon,
    children,
    label,
  } as MenuItem;
}

const items: MenuItem[] = [
  getItem("🔁 Swap USDC → SCT", "swap", <PieChartOutlined />),
  getItem("🌉 Bridge SCT", "bridge", <DesktopOutlined />, [
    getItem("Ethereum Sepolia", "bridge-eth"),
    getItem("Base Sepolia", "bridge-base"),
  ]),
  getItem("🏡 RWA Investment", "rwa", <FileOutlined />),
  getItem("💸 Lending Vault", "vault", <TeamOutlined />),
];

const SolichainDashboard: React.FC = () => {
  const [collapsed, setCollapsed] = useState(false);
  const [activeView, setActiveView] = useState("swap");

  const {
    token: { colorBgContainer, borderRadiusLG },
  } = theme.useToken();

  const renderContent = () => {
    switch (activeView) {
      case "swap":
        return <div className="mt-6">🔁 Swap USDC to SCT — DEX Coming Soon</div>;
      case "bridge-eth":
        return <div className="mt-6"> <BridgeFromEthereum /> </div>;
      case "bridge-base":
        return <div className="mt-6"><BridgeFromBase /></div>;
      case "rwa":
        return <div className="mt-6"><RWAInvestment /></div>;
      case "vault":
        return <div className="mt-6">💸 Lending Vault — Deposit & Borrow with Chainlink Prices</div>;
      default:
        return (
          <div className="text-center mt-10 text-gray-600">
            Select an action from the sidebar.
          </div>
        );
    }
  };

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Sider collapsible collapsed={collapsed} onCollapse={(value) => setCollapsed(value)}>
        <div className="text-white text-xl font-bold text-center py-4">Solichain</div>
        <Menu
          theme="dark"
          mode="inline"
          defaultSelectedKeys={["swap"]}
          selectedKeys={[activeView]}
          onClick={({ key }) => setActiveView(key)}
          items={items}
        />
      </Sider>
      <Layout>
        <Header style={{ margin: 12, padding: 0, background: colorBgContainer, height: 100 }}>
          <WalletConnect />
        </Header>
        <Content style={{ margin: "0 16px" }}>
          <div
            style={{
              padding: 24,
              minHeight: 360,
              background: colorBgContainer,
              borderRadius: borderRadiusLG,
              marginTop: 16,
            }}
          >
            {renderContent()}
          </div>
        </Content>
        <Footer style={{ textAlign: "center" }}>
          Solichain ©{new Date().getFullYear()} Hackathon Prototype
        </Footer>
      </Layout>
    </Layout>
  );
};

export default SolichainDashboard;
