/**
 * @file wormhole_example.cc
 * @brief Example demonstrating wormhole attack implementation
 * 
 * This example shows how to use the enhanced wormhole attack module
 * in your VANET simulation.
 */

#include "wormhole_attack.h"
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-module.h"
#include "ns3/wifi-module.h"
#include "ns3/applications-module.h"
#include "ns3/netanim-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("WormholeExample");

int main(int argc, char *argv[]) {
    // Configuration parameters
    uint32_t nNodes = 50;
    double simTime = 100.0;
    double attackPercentage = 0.2; // 20% of nodes are malicious
    bool randomPairing = true;
    std::string tunnelBandwidth = "1000Mbps";
    uint32_t tunnelDelayMicroseconds = 1;
    bool dropPackets = false;
    bool tunnelRouting = true;
    bool tunnelData = true;
    
    // Command line arguments
    CommandLine cmd;
    cmd.AddValue("nNodes", "Number of nodes", nNodes);
    cmd.AddValue("simTime", "Simulation time (seconds)", simTime);
    cmd.AddValue("attackPercentage", "Percentage of malicious nodes", attackPercentage);
    cmd.AddValue("randomPairing", "Random pairing of wormhole nodes", randomPairing);
    cmd.AddValue("tunnelBandwidth", "Bandwidth of wormhole tunnel", tunnelBandwidth);
    cmd.AddValue("tunnelDelay", "Delay of wormhole tunnel (microseconds)", tunnelDelayMicroseconds);
    cmd.AddValue("dropPackets", "Drop packets instead of tunneling", dropPackets);
    cmd.AddValue("tunnelRouting", "Tunnel routing protocol packets", tunnelRouting);
    cmd.AddValue("tunnelData", "Tunnel data packets", tunnelData);
    cmd.Parse(argc, argv);
    
    // Enable logging
    LogComponentEnable("WormholeAttack", LOG_LEVEL_INFO);
    
    NS_LOG_INFO("Creating " << nNodes << " nodes...");
    
    // Create nodes
    NodeContainer nodes;
    nodes.Create(nNodes);
    
    // Setup mobility
    MobilityHelper mobility;
    mobility.SetPositionAllocator("ns3::GridPositionAllocator",
                                  "MinX", DoubleValue(0.0),
                                  "MinY", DoubleValue(0.0),
                                  "DeltaX", DoubleValue(100.0),
                                  "DeltaY", DoubleValue(100.0),
                                  "GridWidth", UintegerValue(10),
                                  "LayoutType", StringValue("RowFirst"));
    
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(nodes);
    
    // Setup WiFi for VANET
    WifiHelper wifi;
    wifi.SetStandard(WIFI_STANDARD_80211p);
    
    YansWifiPhyHelper wifiPhy;
    YansWifiChannelHelper wifiChannel = YansWifiChannelHelper::Default();
    wifiPhy.SetChannel(wifiChannel.Create());
    
    WifiMacHelper wifiMac;
    wifiMac.SetType("ns3::AdhocWifiMac");
    
    NetDeviceContainer devices = wifi.Install(wifiPhy, wifiMac, nodes);
    
    // Install Internet stack
    InternetStackHelper internet;
    internet.Install(nodes);
    
    // Assign IP addresses
    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer interfaces = address.Assign(devices);
    
    NS_LOG_INFO("Network setup complete");
    
    // ========================================================================
    // WORMHOLE ATTACK SETUP
    // ========================================================================
    
    NS_LOG_INFO("Setting up wormhole attack...");
    
    // Create wormhole attack manager
    WormholeAttackManager wormholeManager;
    
    // Initialize with malicious nodes
    std::vector<bool> maliciousNodes;
    wormholeManager.Initialize(maliciousNodes, attackPercentage, nNodes);
    
    // Set wormhole behavior
    wormholeManager.SetWormholeBehavior(dropPackets, tunnelRouting, tunnelData);
    
    // Create wormhole tunnels
    Time tunnelDelay = MicroSeconds(tunnelDelayMicroseconds);
    wormholeManager.CreateWormholeTunnels(tunnelBandwidth, tunnelDelay, randomPairing);
    
    // Activate attack
    wormholeManager.ActivateAttack(Seconds(10.0), Seconds(simTime));
    
    NS_LOG_INFO("Wormhole attack configured with " 
                << wormholeManager.GetTunnelCount() << " tunnels");
    
    // Setup animation
    AnimationInterface anim("wormhole-attack-animation.xml");
    wormholeManager.ConfigureVisualization(anim, 255, 0, 0); // Red nodes
    
    // ========================================================================
    // APPLICATION SETUP (for testing)
    // ========================================================================
    
    // Create UDP echo server on node 0
    uint16_t port = 9;
    UdpEchoServerHelper echoServer(port);
    ApplicationContainer serverApps = echoServer.Install(nodes.Get(0));
    serverApps.Start(Seconds(1.0));
    serverApps.Stop(Seconds(simTime));
    
    // Create UDP echo clients on other nodes
    for (uint32_t i = 1; i < nNodes; i += 5) {
        UdpEchoClientHelper echoClient(interfaces.GetAddress(0), port);
        echoClient.SetAttribute("MaxPackets", UintegerValue(100));
        echoClient.SetAttribute("Interval", TimeValue(Seconds(1.0)));
        echoClient.SetAttribute("PacketSize", UintegerValue(1024));
        
        ApplicationContainer clientApps = echoClient.Install(nodes.Get(i));
        clientApps.Start(Seconds(2.0 + i * 0.1));
        clientApps.Stop(Seconds(simTime - 1.0));
    }
    
    NS_LOG_INFO("Applications configured");
    
    // ========================================================================
    // RUN SIMULATION
    // ========================================================================
    
    NS_LOG_INFO("Starting simulation...");
    
    Simulator::Stop(Seconds(simTime));
    Simulator::Run();
    
    NS_LOG_INFO("Simulation complete");
    
    // ========================================================================
    // EXPORT STATISTICS
    // ========================================================================
    
    wormholeManager.PrintStatistics();
    wormholeManager.ExportStatistics("wormhole-statistics.csv");
    
    Simulator::Destroy();
    
    return 0;
}
