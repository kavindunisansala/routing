/**
 * @file wormhole_attack.cc
 * @brief Implementation of Wormhole Attack for VANET
 */

#include "wormhole_attack.h"
#include "ns3/simulator.h"
#include "ns3/packet.h"
#include "ns3/ipv4-header.h"
#include "ns3/udp-header.h"
#include "ns3/tcp-header.h"
#include <algorithm>
#include <random>
#include <iomanip>

namespace ns3 {

// Note: NS_LOG_COMPONENT_DEFINE removed to avoid conflict when included in routing.cc
// Logging will use the parent file's log component

// ============================================================================
// WormholeEndpointApp Implementation
// ============================================================================

NS_OBJECT_ENSURE_REGISTERED(WormholeEndpointApp);

TypeId WormholeEndpointApp::GetTypeId(void) {
    static TypeId tid = TypeId("ns3::WormholeEndpointApp")
        .SetParent<Application>()
        .SetGroupName("Applications")
        .AddConstructor<WormholeEndpointApp>();
    return tid;
}

WormholeEndpointApp::WormholeEndpointApp()
    : m_peer(nullptr),
      m_peerAddress(Ipv4Address::GetZero()),
      m_tunnelSocket(nullptr),
      m_tunnelId(0),
      m_dropPackets(false),
      m_tunnelRoutingPackets(true),
      m_tunnelDataPackets(true)
{
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
}

WormholeEndpointApp::~WormholeEndpointApp() {
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
}

void WormholeEndpointApp::SetPeer(Ptr<Node> peer, Ipv4Address peerAddress) {
    m_peer = peer;
    m_peerAddress = peerAddress;
}

void WormholeEndpointApp::SetTunnelId(uint32_t id) {
    m_tunnelId = id;
}

void WormholeEndpointApp::SetDropPackets(bool drop) {
    m_dropPackets = drop;
}

void WormholeEndpointApp::SetSelectiveTunneling(bool routing, bool data) {
    m_tunnelRoutingPackets = routing;
    m_tunnelDataPackets = data;
}

void WormholeEndpointApp::StartApplication(void) {
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
    
    // Hook into all network devices to intercept packets
    Ptr<Node> node = GetNode();
    for (uint32_t i = 0; i < node->GetNDevices(); ++i) {
        Ptr<NetDevice> dev = node->GetDevice(i);
        // Set promiscuous receive callback to intercept all packets
        dev->SetPromiscReceiveCallback(
            MakeCallback(&WormholeEndpointApp::ReceivePacket, this)
        );
    }
    
    // Create socket for tunneling if peer is set
    if (m_peerAddress != Ipv4Address::GetZero()) {
        TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
        m_tunnelSocket = Socket::CreateSocket(GetNode(), tid);
        
        // Bind to any address
        InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), 9999);
        m_tunnelSocket->Bind(local);
        
        // Connect to peer
        InetSocketAddress remote = InetSocketAddress(m_peerAddress, 9999);
        m_tunnelSocket->Connect(remote);
        
        // // NS_LOG_INFO("Wormhole endpoint " << GetNode()->GetId() 
        //             << " connected to peer at " << m_peerAddress);  // Disabled
    }
}

void WormholeEndpointApp::StopApplication(void) {
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
    
    if (m_tunnelSocket) {
        m_tunnelSocket->Close();
        m_tunnelSocket = nullptr;
    }
}

bool WormholeEndpointApp::ReceivePacket(Ptr<NetDevice> device, 
                                        Ptr<const Packet> packet,
                                        uint16_t protocol, 
                                        const Address &from,
                                        const Address &to,
                                        NetDevice::PacketType packetType) {
    // // NS_LOG_FUNCTION(this << device << packet << protocol);  // Disabled  // Disabled when included in routing.cc
    
    // Only intercept packets not destined for this node in normal routing
    // (We want to intercept packets in transit)
    
    m_stats.packetsIntercepted++;
    
    if (m_stats.packetsIntercepted == 1) {
        m_stats.firstPacketTime = Simulator::Now();
    }
    m_stats.lastPacketTime = Simulator::Now();
    
    // Check if we should tunnel this packet
    if (ShouldTunnelPacket(packet, protocol)) {
        if (m_dropPackets) {
            // Drop the packet (don't forward it normally or through tunnel)
            m_stats.packetsDropped++;
            // NS_LOG_DEBUG("Wormhole endpoint " << GetNode()->GetId() 
            //             << " dropped packet");  // Disabled
            return true; // Packet consumed
        } else {
            // Tunnel the packet
            Ptr<Packet> copy = packet->Copy();
            TunnelPacket(copy, protocol);
            m_stats.packetsTunneled++;
            // NS_LOG_DEBUG("Wormhole endpoint " << GetNode()->GetId() 
            //             << " tunneled packet");  // Disabled
            return true; // Packet consumed (tunneled, not forwarded normally)
        }
    }
    
    // Let packet continue normal processing
    return false;
}

bool WormholeEndpointApp::ShouldTunnelPacket(Ptr<const Packet> packet, 
                                              uint16_t protocol) {
    // For IPv4 packets
    if (protocol == 0x0800) {
        Ptr<Packet> copy = packet->Copy();
        
        // Check if packet is large enough for IPv4 header
        if (copy->GetSize() < 20) {
            return false;
        }
        
        Ipv4Header ipHeader;
        uint32_t bytesRead = copy->RemoveHeader(ipHeader);
        
        // Verify header was read successfully
        if (bytesRead == 0) {
            return false;
        }
        
        uint8_t ipProtocol = ipHeader.GetProtocol();
        
        // Check if it's a routing protocol packet (typically UDP with specific ports)
        // AODV uses UDP port 654
        if (ipProtocol == 17) { // UDP
            // Check if there's enough data for UDP header
            if (copy->GetSize() < 8) {
                return false;
            }
            UdpHeader udpHeader;
            uint32_t udpBytes = copy->PeekHeader(udpHeader);
            if (udpBytes == 0) {
                return false;
            }
            uint16_t port = udpHeader.GetDestinationPort();
            
            if (port == 654 || port == 520) { // AODV or RIP
                m_stats.routingPacketsAffected++;
                return m_tunnelRoutingPackets;
            } else {
                m_stats.dataPacketsAffected++;
                return m_tunnelDataPackets;
            }
        } else if (ipProtocol == 6) { // TCP
            m_stats.dataPacketsAffected++;
            return m_tunnelDataPackets;
        }
    }
    
    return false;
}

void WormholeEndpointApp::TunnelPacket(Ptr<Packet> packet, uint16_t protocol) {
    if (!m_tunnelSocket) {
        // // NS_LOG_WARN("No tunnel socket available");  // Disabled  // Disabled when included in routing.cc
        m_stats.packetsDropped++;
        return;
    }
    
    Time startTime = Simulator::Now();
    
    // Add custom header with protocol information
    // For simplicity, we just send the packet as-is
    int sent = m_tunnelSocket->Send(packet);
    
    if (sent > 0) {
        Time endTime = Simulator::Now();
        m_stats.totalTunnelingDelay += (endTime - startTime).GetSeconds();
        
        // NS_LOG_DEBUG("Tunneled " << sent << " bytes from node " 
        //             << GetNode()->GetId() << " to " << m_peerAddress);  // Disabled
    } else {
        // // NS_LOG_WARN("Failed to tunnel packet");  // Disabled  // Disabled when included in routing.cc
        m_stats.packetsDropped++;
    }
}

// ============================================================================
// WormholeAttackManager Implementation
// ============================================================================

WormholeAttackManager::WormholeAttackManager()
    : m_dropPackets(false),
      m_tunnelRoutingPackets(true),
      m_tunnelDataPackets(true),
      m_totalNodes(0),
      m_defaultBandwidth("1000Mbps"),
      m_defaultDelay(MicroSeconds(1))
{
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
}

WormholeAttackManager::~WormholeAttackManager() {
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
}

void WormholeAttackManager::Initialize(std::vector<bool>& maliciousNodes, 
                                       double attackPercentage,
                                       uint32_t totalNodes) {
    // // NS_LOG_FUNCTION(this << attackPercentage << totalNodes);  // Disabled  // Disabled when included in routing.cc
    
    m_totalNodes = totalNodes;
    m_maliciousNodes.resize(totalNodes, false);
    
    // If maliciousNodes is pre-populated, use it
    if (maliciousNodes.size() == totalNodes) {
        m_maliciousNodes = maliciousNodes;
    } else {
        // Otherwise, randomly select nodes based on attackPercentage
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<> dis(0.0, 1.0);
        
        for (uint32_t i = 0; i < totalNodes; ++i) {
            m_maliciousNodes[i] = (dis(gen) < attackPercentage);
            maliciousNodes.push_back(m_maliciousNodes[i]);
        }
    }
    
    // Count malicious nodes
    uint32_t count = 0;
    for (bool isMalicious : m_maliciousNodes) {
        if (isMalicious) count++;
    }
    
    // // NS_LOG_INFO("Initialized wormhole attack with " << count 
    //             << " malicious nodes out of " << totalNodes);  // Disabled  // Disabled when included in routing.cc
}

void WormholeAttackManager::CreateWormholeTunnels(std::string tunnelBandwidth,
                                                  Time tunnelDelay,
                                                  bool selectRandom) {
    // // NS_LOG_FUNCTION(this << tunnelBandwidth << tunnelDelay << selectRandom);  // Disabled  // Disabled when included in routing.cc
    
    m_defaultBandwidth = tunnelBandwidth;
    m_defaultDelay = tunnelDelay;
    
    // Collect malicious node IDs
    std::vector<uint32_t> maliciousNodeIds;
    for (uint32_t i = 0; i < m_maliciousNodes.size(); ++i) {
        if (m_maliciousNodes[i]) {
            maliciousNodeIds.push_back(i);
        }
    }
    
    if (maliciousNodeIds.size() < 2) {
        // // NS_LOG_WARN("Not enough malicious nodes to create wormhole tunnels");  // Disabled  // Disabled when included in routing.cc
        return;
    }
    
    // Pair nodes
    if (selectRandom) {
        SelectRandomPairs(maliciousNodeIds);
    } else {
        SelectSequentialPairs(maliciousNodeIds);
    }
    
    // NS_LOG_INFO("Created " << m_tunnels.size() << " wormhole tunnels");  // Disabled
}

void WormholeAttackManager::SelectSequentialPairs(
    std::vector<uint32_t>& maliciousNodeIds) {
    
    // Pair nodes sequentially: 0-1, 2-3, 4-5, etc.
    for (size_t i = 0; i + 1 < maliciousNodeIds.size(); i += 2) {
        CreateWormholeTunnel(maliciousNodeIds[i], maliciousNodeIds[i+1],
                            m_defaultBandwidth, m_defaultDelay);
    }
}

void WormholeAttackManager::SelectRandomPairs(
    std::vector<uint32_t>& maliciousNodeIds) {
    
    // Shuffle and pair randomly
    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(maliciousNodeIds.begin(), maliciousNodeIds.end(), g);
    
    SelectSequentialPairs(maliciousNodeIds); // Use sequential after shuffling
}

uint32_t WormholeAttackManager::CreateWormholeTunnel(uint32_t nodeIdA, 
                                                     uint32_t nodeIdB,
                                                     std::string bandwidth,
                                                     Time delay) {
    // // NS_LOG_FUNCTION(this << nodeIdA << nodeIdB << bandwidth << delay);  // Disabled  // Disabled when included in routing.cc
    
    WormholeTunnel tunnel;
    tunnel.nodeIdA = nodeIdA;
    tunnel.nodeIdB = nodeIdB;
    tunnel.endpointA = NodeList::GetNode(nodeIdA);
    tunnel.endpointB = NodeList::GetNode(nodeIdB);
    
    // Create point-to-point link for the tunnel
    PointToPointHelper p2p;
    p2p.SetDeviceAttribute("DataRate", StringValue(bandwidth));
    p2p.SetChannelAttribute("Delay", TimeValue(delay));
    
    tunnel.tunnelDevices = p2p.Install(tunnel.endpointA, tunnel.endpointB);
    
    // Assign IP addresses to tunnel
    Ipv4AddressHelper address;
    std::ostringstream subnet;
    subnet << "100." << (m_tunnels.size() / 254) << "."
           << (m_tunnels.size() % 254) << ".0";
    address.SetBase(subnet.str().c_str(), "255.255.255.0");
    tunnel.tunnelInterfaces = address.Assign(tunnel.tunnelDevices);
    
    tunnel.isActive = false;
    
    uint32_t tunnelId = m_tunnels.size();
    m_tunnels.push_back(tunnel);
    
    // // NS_LOG_INFO("Created wormhole tunnel " << tunnelId 
    //             << " between nodes " << nodeIdA << " and " << nodeIdB
    //             << " with bandwidth " << bandwidth << " and delay " << delay);  // Disabled  // Disabled when included in routing.cc
    
    return tunnelId;
}

void WormholeAttackManager::ActivateAttack(Time startTime, Time stopTime) {
    // // NS_LOG_FUNCTION(this << startTime << stopTime);  // Disabled  // Disabled when included in routing.cc
    
    for (size_t i = 0; i < m_tunnels.size(); ++i) {
        WormholeTunnel& tunnel = m_tunnels[i];
        
        // Create wormhole endpoint applications
        Ptr<WormholeEndpointApp> appA = CreateObject<WormholeEndpointApp>();
        Ptr<WormholeEndpointApp> appB = CreateObject<WormholeEndpointApp>();
        
        // Configure applications
        Ipv4Address addrB = tunnel.tunnelInterfaces.GetAddress(1);
        Ipv4Address addrA = tunnel.tunnelInterfaces.GetAddress(0);
        
        appA->SetPeer(tunnel.endpointB, addrB);
        appA->SetTunnelId(i);
        appA->SetDropPackets(m_dropPackets);
        appA->SetSelectiveTunneling(m_tunnelRoutingPackets, m_tunnelDataPackets);
        
        appB->SetPeer(tunnel.endpointA, addrA);
        appB->SetTunnelId(i);
        appB->SetDropPackets(m_dropPackets);
        appB->SetSelectiveTunneling(m_tunnelRoutingPackets, m_tunnelDataPackets);
        
        // Install applications
        tunnel.endpointA->AddApplication(appA);
        tunnel.endpointB->AddApplication(appB);
        
        appA->SetStartTime(startTime);
        appA->SetStopTime(stopTime);
        appB->SetStartTime(startTime);
        appB->SetStopTime(stopTime);
        
        tunnel.isActive = true;
        tunnel.activationTime = startTime;
        tunnel.deactivationTime = stopTime;
    }
    
    // NS_LOG_INFO("Activated " << m_tunnels.size() << " wormhole tunnels from " 
    //             << startTime << " to " << stopTime);
}

void WormholeAttackManager::DeactivateAttack() {
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
    
    for (auto& tunnel : m_tunnels) {
        tunnel.isActive = false;
    }
    
    // // NS_LOG_INFO("Deactivated all wormhole tunnels");  // Disabled  // Disabled when included in routing.cc
}

void WormholeAttackManager::ConfigureVisualization(AnimationInterface& anim,
                                                   uint8_t r, uint8_t g, uint8_t b) {
    // NS_LOG_FUNCTION(this << (uint32_t)r << (uint32_t)g << (uint32_t)b);  // Disabled
    
    for (const auto& tunnel : m_tunnels) {
        // Color both endpoints
        anim.UpdateNodeColor(tunnel.endpointA, r, g, b);
        anim.UpdateNodeColor(tunnel.endpointB, r, g, b);
        
        // Optionally increase node size for visibility
        anim.UpdateNodeSize(tunnel.nodeIdA, 15.0, 15.0);
        anim.UpdateNodeSize(tunnel.nodeIdB, 15.0, 15.0);
        
        // Add description
        std::ostringstream desc;
        desc << "Wormhole Node " << tunnel.nodeIdA;
        anim.UpdateNodeDescription(tunnel.nodeIdA, desc.str());
        
        desc.str("");
        desc << "Wormhole Node " << tunnel.nodeIdB;
        anim.UpdateNodeDescription(tunnel.nodeIdB, desc.str());
    }
    
    // NS_LOG_INFO("Configured visualization for " << m_tunnels.size() << " tunnels");  // Disabled
}

void WormholeAttackManager::SetWormholeBehavior(bool dropPackets, 
                                                bool tunnelRouting,
                                                bool tunnelData) {
    m_dropPackets = dropPackets;
    m_tunnelRoutingPackets = tunnelRouting;
    m_tunnelDataPackets = tunnelData;
    
    // // NS_LOG_INFO("Set wormhole behavior - Drop: " << dropPackets 
    //             << ", Tunnel Routing: " << tunnelRouting 
    //             << ", Tunnel Data: " << tunnelData);  // Disabled  // Disabled when included in routing.cc
}

WormholeStatistics WormholeAttackManager::GetTunnelStatistics(
    uint32_t tunnelId) const {
    
    if (tunnelId >= m_tunnels.size()) {
        // // NS_LOG_WARN("Invalid tunnel ID: " << tunnelId);  // Disabled  // Disabled when included in routing.cc
        return WormholeStatistics();
    }
    
    return m_tunnels[tunnelId].stats;
}

WormholeStatistics WormholeAttackManager::GetAggregateStatistics() const {
    WormholeStatistics aggregate;
    
    for (const auto& tunnel : m_tunnels) {
        aggregate.packetsIntercepted += tunnel.stats.packetsIntercepted;
        aggregate.packetsTunneled += tunnel.stats.packetsTunneled;
        aggregate.packetsDropped += tunnel.stats.packetsDropped;
        aggregate.routingPacketsAffected += tunnel.stats.routingPacketsAffected;
        aggregate.dataPacketsAffected += tunnel.stats.dataPacketsAffected;
        aggregate.totalTunnelingDelay += tunnel.stats.totalTunnelingDelay;
    }
    
    return aggregate;
}

void WormholeAttackManager::ExportStatistics(std::string filename) const {
    // // NS_LOG_FUNCTION(this << filename);  // Disabled  // Disabled when included in routing.cc
    
    std::ofstream outFile(filename);
    if (!outFile.is_open()) {
        // // NS_LOG_ERROR("Failed to open file: " << filename);  // Disabled  // Disabled when included in routing.cc
        return;
    }
    
    // Write header
    outFile << "TunnelID,NodeA,NodeB,PacketsIntercepted,PacketsTunneled,"
            << "PacketsDropped,RoutingAffected,DataAffected,AvgDelay\n";
    
    // Write data for each tunnel
    for (size_t i = 0; i < m_tunnels.size(); ++i) {
        const auto& tunnel = m_tunnels[i];
        const auto& stats = tunnel.stats;
        
        double avgDelay = (stats.packetsTunneled > 0) 
            ? stats.totalTunnelingDelay / stats.packetsTunneled 
            : 0.0;
        
        outFile << i << ","
                << tunnel.nodeIdA << ","
                << tunnel.nodeIdB << ","
                << stats.packetsIntercepted << ","
                << stats.packetsTunneled << ","
                << stats.packetsDropped << ","
                << stats.routingPacketsAffected << ","
                << stats.dataPacketsAffected << ","
                << avgDelay << "\n";
    }
    
    // Write aggregate statistics
    WormholeStatistics aggregate = GetAggregateStatistics();
    double avgDelay = (aggregate.packetsTunneled > 0)
        ? aggregate.totalTunnelingDelay / aggregate.packetsTunneled
        : 0.0;
    
    outFile << "TOTAL,ALL,ALL,"
            << aggregate.packetsIntercepted << ","
            << aggregate.packetsTunneled << ","
            << aggregate.packetsDropped << ","
            << aggregate.routingPacketsAffected << ","
            << aggregate.dataPacketsAffected << ","
            << avgDelay << "\n";
    
    outFile.close();
    // // NS_LOG_INFO("Exported wormhole statistics to " << filename);  // Disabled  // Disabled when included in routing.cc
}

void WormholeAttackManager::PrintStatistics() const {
    std::cout << "\n========== WORMHOLE ATTACK STATISTICS ==========\n";
    std::cout << "Total Tunnels: " << m_tunnels.size() << "\n\n";
    
    for (size_t i = 0; i < m_tunnels.size(); ++i) {
        const auto& tunnel = m_tunnels[i];
        const auto& stats = tunnel.stats;
        
        std::cout << "Tunnel " << i << " (Node " << tunnel.nodeIdA 
                  << " <-> Node " << tunnel.nodeIdB << "):\n";
        std::cout << "  Packets Intercepted: " << stats.packetsIntercepted << "\n";
        std::cout << "  Packets Tunneled: " << stats.packetsTunneled << "\n";
        std::cout << "  Packets Dropped: " << stats.packetsDropped << "\n";
        std::cout << "  Routing Packets Affected: " << stats.routingPacketsAffected << "\n";
        std::cout << "  Data Packets Affected: " << stats.dataPacketsAffected << "\n";
        
        if (stats.packetsTunneled > 0) {
            double avgDelay = stats.totalTunnelingDelay / stats.packetsTunneled;
            std::cout << "  Avg Tunneling Delay: " << avgDelay << " s\n";
        }
        std::cout << "\n";
    }
    
    // Print aggregate
    WormholeStatistics aggregate = GetAggregateStatistics();
    std::cout << "AGGREGATE STATISTICS:\n";
    std::cout << "  Total Packets Intercepted: " << aggregate.packetsIntercepted << "\n";
    std::cout << "  Total Packets Tunneled: " << aggregate.packetsTunneled << "\n";
    std::cout << "  Total Packets Dropped: " << aggregate.packetsDropped << "\n";
    std::cout << "  Total Routing Packets Affected: " << aggregate.routingPacketsAffected << "\n";
    std::cout << "  Total Data Packets Affected: " << aggregate.dataPacketsAffected << "\n";
    
    if (aggregate.packetsTunneled > 0) {
        double avgDelay = aggregate.totalTunnelingDelay / aggregate.packetsTunneled;
        std::cout << "  Overall Avg Tunneling Delay: " << avgDelay << " s\n";
    }
    std::cout << "================================================\n\n";
}

std::vector<uint32_t> WormholeAttackManager::GetMaliciousNodeIds() const {
    std::vector<uint32_t> nodeIds;
    for (uint32_t i = 0; i < m_maliciousNodes.size(); ++i) {
        if (m_maliciousNodes[i]) {
            nodeIds.push_back(i);
        }
    }
    return nodeIds;
}

// ============================================================================
// Helper Function (Backward Compatibility)
// ============================================================================

void SetupWormholeAttack(
    std::vector<bool>& wormhole_malicious_nodes,
    uint32_t total_size,
    double attack_percentage,
    double simTime,
    AnimationInterface& anim,
    std::string tunnelBandwidth,
    Time tunnelDelay,
    bool randomPairing)
{
    // NS_LOG_FUNCTION_NOARGS();  // Disabled when included in routing.cc
    
    // Create manager
    WormholeAttackManager manager;
    
    // Initialize
    manager.Initialize(wormhole_malicious_nodes, attack_percentage, total_size);
    
    // Create tunnels
    manager.CreateWormholeTunnels(tunnelBandwidth, tunnelDelay, randomPairing);
    
    // Activate attack
    manager.ActivateAttack(Seconds(0.0), Seconds(simTime));
    
    // Configure visualization
    manager.ConfigureVisualization(anim, 255, 0, 0); // Red color
    
    // // NS_LOG_INFO("Wormhole attack setup complete");  // Disabled  // Disabled when included in routing.cc
}

} // namespace ns3
