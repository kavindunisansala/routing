/**
 * @file wormhole_attack.cc
 * @brief Implementation of Wormhole Attack for VANET
 */

#include "wormhole_attack.h"
#include "ns3/simulator.h"
#include "ns3/packet.h"
#include "ns3/ipv4-header.h"
#include "ns3/ipv4-interface-address.h"
#include "ns3/udp-header.h"
#include "ns3/tcp-header.h"
#include "ns3/ipv4-raw-socket-factory.h"
#include "ns3/uinteger.h"
#include "ns3/node-list.h"
#include <algorithm>
#include <random>
#include <iomanip>

namespace {

void WormholeVerificationReceive(Ptr<Socket> socket) {
    Ptr<Packet> packet;
    Address from;

    while ((packet = socket->RecvFrom(from))) {
        // Consume packet; statistics handled elsewhere.
    }
}

void ScheduleWormholeVerificationSend(Ptr<Socket> socket,
                                      uint32_t packetSize,
                                      Time interval,
                                      Time stopTime) {
    if (Simulator::Now() >= stopTime) {
        return;
    }

    Ptr<Packet> packet = Create<Packet>(packetSize);
    socket->Send(packet);

    Simulator::Schedule(interval, &ScheduleWormholeVerificationSend,
                        socket, packetSize, interval, stopTime);
}

} // anonymous namespace

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
    
    std::cout << "\n=== WORMHOLE ATTACK STARTING on Node " << GetNode()->GetId() 
              << " (Tunnel " << m_tunnelId << ") ===" << std::endl;
    std::cout << "Attack Type: AODV Route Poisoning (WAVE-compatible)" << std::endl;
    std::cout << "Peer Node: " << m_peer->GetId() << " @ " << m_peerAddress << std::endl;
    
    // Create socket for tunneling packets through wormhole
    if (m_peerAddress != Ipv4Address::GetZero()) {
        TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
        m_tunnelSocket = Socket::CreateSocket(GetNode(), tid);
        
        // Bind to wormhole tunnel port (9999)
        InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), 9999);
        if (m_tunnelSocket->Bind(local) < 0) {
            std::cerr << "ERROR: Failed to bind tunnel socket on node " << GetNode()->GetId() << std::endl;
        }
        
        // Set receive callback to handle tunneled packets from peer
        m_tunnelSocket->SetRecvCallback(MakeCallback(&WormholeEndpointApp::HandleTunneledPacket, this));
        
        std::cout << "✓ Tunnel socket created and bound to port 9999" << std::endl;
    }
    
    // Get AODV routing protocol for route manipulation
    Ptr<Ipv4> ipv4 = GetNode()->GetObject<Ipv4>();
    if (!ipv4) {
        std::cerr << "ERROR: No IPv4 on node " << GetNode()->GetId() << std::endl;
        return;
    }
    
    // Create UDP socket for sending fake AODV messages (bind to ephemeral port)
    m_aodvSocket = Socket::CreateSocket(GetNode(), TypeId::LookupByName("ns3::UdpSocketFactory"));
    if (m_aodvSocket->Bind() < 0) {
        std::cerr << "ERROR: Failed to bind AODV injection socket on node "
                  << GetNode()->GetId() << std::endl;
    }
    m_aodvSocket->SetAllowBroadcast(true);

    // Create raw socket sniffer to intercept existing AODV traffic (UDP protocol)
    m_aodvSniffer = Socket::CreateSocket(GetNode(),
        TypeId::LookupByName("ns3::Ipv4RawSocketFactory"));
    m_aodvSniffer->SetAttribute("Protocol", UintegerValue(17)); // UDP protocol number
    if (m_aodvSniffer->Bind() < 0) {
        std::cerr << "ERROR: Failed to bind AODV sniffer socket on node "
                  << GetNode()->GetId() << std::endl;
    } else {
        m_aodvSniffer->SetRecvCallback(MakeCallback(&WormholeEndpointApp::ReceiveAODVMessage, this));
    }
    
    std::cout << "✓ AODV manipulation sockets ready (raw sniffer + UDP injector)" << std::endl;
    
    // Start periodic AODV route poisoning to attract traffic
    double attackInterval = 0.5; // Send fake RREP every 0.5 seconds
    Simulator::Schedule(Seconds(0.1), &WormholeEndpointApp::SendFakeRouteAdvertisement, this);
    Simulator::Schedule(Seconds(attackInterval), &WormholeEndpointApp::PeriodicAttack, this);
    
    std::cout << "✓ Route poisoning scheduled (interval: " << attackInterval << "s)" << std::endl;
    std::cout << "=== Wormhole attack ACTIVE on node " << GetNode()->GetId() << " ===" << std::endl << std::endl;
}

void WormholeEndpointApp::StopApplication(void) {
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
    
    std::cout << "\n=== WORMHOLE STOPPING on Node " << GetNode()->GetId() << " ===" << std::endl;
    std::cout << "Final Stats - Intercepted: " << m_stats.packetsIntercepted 
              << ", Tunneled: " << m_stats.packetsTunneled << std::endl;
    
    if (m_tunnelSocket) {
        m_tunnelSocket->Close();
        m_tunnelSocket = nullptr;
    }
    
    if (m_aodvSocket) {
        m_aodvSocket->Close();
        m_aodvSocket = nullptr;
    }

    if (m_aodvSniffer) {
        m_aodvSniffer->Close();
        m_aodvSniffer = nullptr;
    }
}

// ============================================================================
// AODV Route Poisoning Attack Methods
// ============================================================================

void WormholeEndpointApp::ReceiveAODVMessage(Ptr<Socket> socket) {
    // Intercept AODV routing traffic using a raw socket sniffing UDP packets
    Ptr<Packet> packet;
    Address from;

    while ((packet = socket->RecvFrom(from))) {
        if (packet->GetSize() == 0) {
            continue;
        }

        Ptr<Packet> copy = packet->Copy();
        Ipv4Header ipHeader;

        if (copy->GetSize() < ipHeader.GetSerializedSize()) {
            continue;
        }

        copy->RemoveHeader(ipHeader);

        // Filter only UDP packets (AODV control messages)
        if (ipHeader.GetProtocol() != 17) {
            continue;
        }

        UdpHeader udpHeader;
        if (copy->GetSize() < udpHeader.GetSerializedSize()) {
            continue;
        }

        copy->RemoveHeader(udpHeader);

        if (udpHeader.GetDestinationPort() != 654 && udpHeader.GetSourcePort() != 654) {
            continue;
        }

        if (copy->GetSize() == 0) {
            continue;
        }

        uint8_t buffer[1500];
        uint32_t payloadSize = std::min<uint32_t>(copy->GetSize(), sizeof(buffer));
        copy->CopyData(buffer, payloadSize);

        uint8_t msgType = buffer[0];
        Ipv4Address requester = ipHeader.GetSource();

        m_stats.routingPacketsAffected++;

        if (msgType == 1) {  // RREQ intercepted
            m_stats.packetsIntercepted++;

            std::cout << "[WORMHOLE] Node " << GetNode()->GetId()
                      << " intercepted AODV RREQ from " << requester
                      << " (Total intercepted: " << m_stats.packetsIntercepted << ")" << std::endl;

            // Reply with fake RREP to attract traffic through wormhole
            SendFakeRREP(requester);

            // Tunnel the RREQ to peer so they can also respond
            if (m_tunnelSocket && m_peerAddress != Ipv4Address::GetZero()) {
                Ptr<Packet> forwardCopy = packet->Copy();
                m_tunnelSocket->SendTo(forwardCopy, 0, InetSocketAddress(m_peerAddress, 9999));
                m_stats.packetsTunneled++;

                std::cout << "[WORMHOLE] Node " << GetNode()->GetId()
                          << " tunneled RREQ to peer " << m_peer->GetId()
                          << " (Total tunneled: " << m_stats.packetsTunneled << ")" << std::endl;
            }
        } else if (msgType == 2) {
            // Track legitimate RREPs for visibility
            std::cout << "[WORMHOLE] Node " << GetNode()->GetId()
                      << " observed AODV RREP from " << requester << std::endl;
        }
    }
}

void WormholeEndpointApp::SendFakeRREP(Ipv4Address requester) {
    // Create fake AODV RREP (Route Reply) with very short hop count
    // This makes nodes think wormhole provides shortest path
    
    uint8_t fakeRREP[32];  // AODV RREP is ~20 bytes
    memset(fakeRREP, 0, sizeof(fakeRREP));
    
    // AODV RREP format (simplified):
    // Byte 0: Type (2 = RREP)
    // Byte 1: Flags
    // Byte 2-3: Reserved
    // Byte 4: Hop Count (set to 1 to appear closest)
    // Bytes 5-8: Destination IP
    // Bytes 9-12: Destination Sequence Number
    // Bytes 13-16: Originator IP
    // Bytes 17-20: Lifetime
    
    fakeRREP[0] = 2;  // RREP type
    fakeRREP[4] = 1;  // Hop count = 1 (appears very close!)
    
    // Set destination to peer (other wormhole endpoint)
    uint32_t peerIp = m_peerAddress.Get();
    memcpy(&fakeRREP[5], &peerIp, 4);
    
    // Set originator to requester
    uint32_t reqIp = requester.Get();
    memcpy(&fakeRREP[13], &reqIp, 4);
    
    // Set lifetime (seconds)
    uint32_t lifetime = 10000;  // Long lifetime
    memcpy(&fakeRREP[17], &lifetime, 4);
    
    // Send fake RREP back to requester
    Ptr<Packet> replyPacket = Create<Packet>(fakeRREP, 24);
    
    if (m_aodvSocket) {
        m_aodvSocket->SendTo(replyPacket, 0, InetSocketAddress(requester, 654));
    }
    
}

void WormholeEndpointApp::SendFakeRouteAdvertisement() {
    // Proactively advertise routes to attract traffic
    // Broadcast that we have route to peer with hop count = 1
    
    if (!m_peer || m_peerAddress == Ipv4Address::GetZero()) {
        return;
    }
    
    std::cout << "Node " << GetNode()->GetId() << " advertising fake route to " 
              << m_peerAddress << " (peer node " << m_peer->GetId() << ")" << std::endl;
    
    // Get all neighbors' addresses to advertise to
    Ptr<Ipv4> ipv4 = GetNode()->GetObject<Ipv4>();
    if (!ipv4) return;
    
    // Broadcast fake RREP for the peer
    uint8_t fakeRREP[32];
    memset(fakeRREP, 0, sizeof(fakeRREP));
    
    fakeRREP[0] = 2;  // RREP
    fakeRREP[4] = 1;  // Hop count = 1
    
    uint32_t peerIp = m_peerAddress.Get();
    memcpy(&fakeRREP[5], &peerIp, 4);
    
    // Broadcast
    Ptr<Packet> advPacket = Create<Packet>(fakeRREP, 24);
    if (m_aodvSocket) {
        m_aodvSocket->SendTo(advPacket, 0, 
            InetSocketAddress(Ipv4Address("255.255.255.255"), 654));
    }
    
    m_stats.routingPacketsAffected++;
}

void WormholeEndpointApp::PeriodicAttack() {
    // Periodically send fake route advertisements
    SendFakeRouteAdvertisement();
    
    // Schedule next attack
    Simulator::Schedule(Seconds(0.5), &WormholeEndpointApp::PeriodicAttack, this);
}

void WormholeEndpointApp::HandleTunneledPacket(Ptr<Socket> socket) {
    // Receive packet from wormhole peer and rebroadcast locally
    Ptr<Packet> packet;
    Address from;
    
    while ((packet = socket->RecvFrom(from))) {
        m_stats.packetsTunneled++;
        
        std::cout << "[WORMHOLE] Node " << GetNode()->GetId() 
                  << " received tunneled packet from peer (Total: " 
                  << m_stats.packetsTunneled << ")" << std::endl;
        
        // Rebroadcast the tunneled packet in local area
        // This makes it appear as if packet traveled through wormhole instantly
        
        // In real implementation, would extract and reinject into network
        // For now, just count statistics
    }
}

// Legacy method kept for compatibility but not used
bool WormholeEndpointApp::ReceivePacket(Ptr<NetDevice> device, 
                                        Ptr<const Packet> packet,
                                        uint16_t protocol, 
                                        const Address &from,
                                        const Address &to,
                                        NetDevice::PacketType packetType) {
    // Old promiscuous callback method - no longer used
    // Replaced by AODV route poisoning approach
    return false;  // Let packet continue normally
}

bool WormholeEndpointApp::ShouldTunnelPacket(Ptr<const Packet> packet, 
                                              uint16_t protocol) {
    // Accept all packets by default if both routing and data tunneling are enabled
    bool tunnelByDefault = (m_tunnelRoutingPackets && m_tunnelDataPackets);
    
    // For IPv4 packets, try to classify them
    if (protocol == 0x0800) {
        Ptr<Packet> copy = packet->Copy();
        
        // Check if packet is large enough for IPv4 header
        if (copy->GetSize() < 20) {
            return tunnelByDefault;
        }
        
        Ipv4Header ipHeader;
        uint32_t bytesRead = copy->RemoveHeader(ipHeader);
        
        // Verify header was read successfully
        if (bytesRead == 0) {
            return tunnelByDefault;
        }
        
        uint8_t ipProtocol = ipHeader.GetProtocol();
        
        // Check if it's a routing protocol packet (typically UDP with specific ports)
        // AODV uses UDP port 654
        if (ipProtocol == 17) { // UDP
            // Check if there's enough data for UDP header
            if (copy->GetSize() < 8) {
                m_stats.dataPacketsAffected++;
                return m_tunnelDataPackets;
            }
            UdpHeader udpHeader;
            uint32_t udpBytes = copy->PeekHeader(udpHeader);
            if (udpBytes == 0) {
                m_stats.dataPacketsAffected++;
                return m_tunnelDataPackets;
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
        } else {
            // Other IP protocols (ICMP, etc.)
            m_stats.dataPacketsAffected++;
            return m_tunnelDataPackets;
        }
    }
    
    // Non-IPv4 packets
    return tunnelByDefault;
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
      m_defaultDelay(MicroSeconds(1)),
      m_enableVerificationTraffic(true),
      m_verificationFlowCount(3),
      m_verificationPacketRate(40.0),
      m_verificationPacketSize(512),
      m_verificationStartOffset(0.5),
      m_verificationBasePort(50000)
{
    // // NS_LOG_FUNCTION(this);  // Disabled  // Disabled when included in routing.cc
}

WormholeAttackManager::~WormholeAttackManager() {
    for (auto& socket : m_testSourceSockets) {
        if (socket) {
            socket->Close();
        }
    }
    m_testSourceSockets.clear();

    for (auto& socket : m_testSinkSockets) {
        if (socket) {
            socket->Close();
        }
    }
    m_testSinkSockets.clear();
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
    
    std::cout << "=== ACTIVATING " << m_tunnels.size() << " WORMHOLE TUNNELS ===" << std::endl;
    std::cout << "Start time: " << startTime.GetSeconds() << "s, Stop time: " << stopTime.GetSeconds() << "s" << std::endl;
    
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
    
    double startSeconds = startTime.GetSeconds();
    double stopSeconds = stopTime.GetSeconds();
    if (stopSeconds <= startSeconds) {
        stopSeconds = startSeconds + 5.0;
    }
    DeployVerificationTraffic(startSeconds + m_verificationStartOffset, stopSeconds);

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

void WormholeAttackManager::ConfigureVerificationTraffic(bool enable,
                                                         uint32_t flowCount,
                                                         double packetRate,
                                                         uint32_t packetSize,
                                                         double startOffsetSec,
                                                         uint16_t basePort) {
    m_enableVerificationTraffic = enable;
    m_verificationFlowCount = flowCount;
    m_verificationPacketRate = packetRate;
    m_verificationPacketSize = packetSize;
    m_verificationStartOffset = std::max(0.0, startOffsetSec);
    m_verificationBasePort = (basePort == 0) ? 50000 : basePort;
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

Ipv4Address WormholeAttackManager::GetPrimaryAddress(Ptr<Node> node) {
    if (!node) {
        return Ipv4Address::GetZero();
    }

    Ptr<Ipv4> ipv4 = node->GetObject<Ipv4>();
    if (!ipv4) {
        return Ipv4Address::GetZero();
    }

    for (uint32_t i = 0; i < ipv4->GetNInterfaces(); ++i) {
        for (uint32_t j = 0; j < ipv4->GetNAddresses(i); ++j) {
            Ipv4InterfaceAddress iface = ipv4->GetAddress(i, j);
            Ipv4Address address = iface.GetLocal();
            if (!address.IsLoopback() && address != Ipv4Address::GetZero()) {
                return address;
            }
        }
    }

    return Ipv4Address::GetZero();
}

void WormholeAttackManager::DeployVerificationTraffic(double startTimeSec,
                                                      double stopTimeSec) {
    if (stopTimeSec <= startTimeSec) {
        stopTimeSec = startTimeSec + 5.0;
    }

    for (auto& socket : m_testSourceSockets) {
        if (socket) {
            socket->Close();
        }
    }
    m_testSourceSockets.clear();

    for (auto& socket : m_testSinkSockets) {
        if (socket) {
            socket->Close();
        }
    }
    m_testSinkSockets.clear();

    if (!m_enableVerificationTraffic) {
        std::cout << "[WORMHOLE] Verification traffic disabled per configuration." << std::endl;
        return;
    }

    std::vector<uint32_t> innocents;
    for (uint32_t i = 0; i < m_totalNodes; ++i) {
        if (i >= m_maliciousNodes.size() || !m_maliciousNodes[i]) {
            innocents.push_back(i);
        }
    }

    if (innocents.size() < 2) {
        std::cout << "[WORMHOLE] Skipping verification traffic (not enough non-malicious nodes)." << std::endl;
        return;
    }

    if (m_verificationFlowCount == 0) {
        std::cout << "[WORMHOLE] Verification flow count set to 0, skipping traffic." << std::endl;
        return;
    }

    uint32_t availablePairs = innocents.size() / 2;
    uint32_t desiredPairs = std::min<uint32_t>(m_verificationFlowCount, availablePairs);
    if (desiredPairs == 0) {
        std::cout << "[WORMHOLE] Unable to allocate verification flows (insufficient innocent nodes)." << std::endl;
        return;
    }

    Time startTime = Seconds(startTimeSec);
    Time stopTime = Seconds(stopTimeSec);
    bool scheduleTraffic = (m_verificationPacketRate > 0.0);
    Time interval = Seconds(scheduleTraffic ? (1.0 / m_verificationPacketRate) : 0.5);
    uint32_t packetSize = std::max<uint32_t>(m_verificationPacketSize, 64);
    uint16_t basePort = m_verificationBasePort;

    for (uint32_t i = 0; i < desiredPairs; ++i) {
        uint32_t srcIndex = innocents[i % innocents.size()];
        uint32_t dstIndex = innocents[(i + innocents.size() / 2) % innocents.size()];
        if (srcIndex == dstIndex) {
            dstIndex = innocents[(i + 1) % innocents.size()];
            if (srcIndex == dstIndex) {
                continue;
            }
        }

        Ptr<Node> srcNode = NodeList::GetNode(srcIndex);
        Ptr<Node> dstNode = NodeList::GetNode(dstIndex);
        if (!srcNode || !dstNode) {
            continue;
        }

        Ipv4Address dstAddress = GetPrimaryAddress(dstNode);
        if (dstAddress == Ipv4Address::GetZero()) {
            continue;
        }

        uint16_t port = basePort + i;

        Ptr<Socket> sink = Socket::CreateSocket(dstNode, TypeId::LookupByName("ns3::UdpSocketFactory"));
        if (sink->Bind(InetSocketAddress(Ipv4Address::GetAny(), port)) < 0) {
            continue;
        }
        sink->SetRecvCallback(MakeCallback(&WormholeVerificationReceive));
        m_testSinkSockets.push_back(sink);

        Ptr<Socket> source = Socket::CreateSocket(srcNode, TypeId::LookupByName("ns3::UdpSocketFactory"));
        if (source->Bind() < 0) {
            continue;
        }
        source->Connect(InetSocketAddress(dstAddress, port));
        m_testSourceSockets.push_back(source);

        if (scheduleTraffic) {
            Simulator::Schedule(startTime, &ScheduleWormholeVerificationSend,
                                source, packetSize, interval, stopTime);
        }

        std::cout << "[WORMHOLE] Verification flow " << i
                  << ": node " << srcIndex << " -> node " << dstIndex
                  << " targeting " << dstAddress << ":" << port << std::endl;
    }

    if (!m_testSourceSockets.empty()) {
        std::cout << "[WORMHOLE] Installed " << m_testSourceSockets.size()
                  << " verification flow(s) to stimulate routing activity." << std::endl;
        if (!scheduleTraffic) {
            std::cout << "[WORMHOLE] Verification packet rate <= 0, sockets created without scheduled transmissions." << std::endl;
        }
    } else {
        std::cout << "[WORMHOLE] Verification traffic setup produced no active flows." << std::endl;
    }
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
