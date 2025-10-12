/**
 * @file wormhole_attack.h
 * @brief Comprehensive Wormhole Attack Implementation for VANET
 * 
 * This module implements a realistic wormhole attack in vehicular networks.
 * A wormhole attack creates a tunnel between two or more colluding malicious nodes,
 * allowing them to relay packets at higher speeds than normal, disrupting routing.
 * 
 * Features:
 * - Configurable tunnel bandwidth and latency
 * - Support for multiple wormhole pairs
 * - Real-time packet interception and tunneling
 * - Statistical tracking and logging
 * - Animation/visualization support
 * - Dynamic wormhole activation/deactivation
 */

#ifndef WORMHOLE_ATTACK_H
#define WORMHOLE_ATTACK_H

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-helper.h"
#include "ns3/netanim-module.h"
#include <vector>
#include <map>
#include <fstream>

namespace ns3 {

/**
 * @brief Statistics for wormhole attack monitoring
 */
struct WormholeStatistics {
    uint32_t packetsIntercepted;      // Total packets intercepted by wormhole endpoints
    uint32_t packetsTunneled;         // Total packets successfully tunneled
    uint32_t packetsDropped;          // Packets dropped during tunneling
    uint32_t routingPacketsAffected;  // Routing protocol packets affected
    uint32_t dataPacketsAffected;     // Data packets affected
    double totalTunnelingDelay;       // Cumulative tunneling delay
    Time firstPacketTime;             // First packet intercepted
    Time lastPacketTime;              // Last packet intercepted
    
    WormholeStatistics() 
        : packetsIntercepted(0), packetsTunneled(0), packetsDropped(0),
          routingPacketsAffected(0), dataPacketsAffected(0), 
          totalTunnelingDelay(0.0) {}
};

/**
 * @brief Represents a wormhole tunnel between two endpoints
 */
struct WormholeTunnel {
    Ptr<Node> endpointA;              // First endpoint node
    Ptr<Node> endpointB;              // Second endpoint node
    uint32_t nodeIdA;                 // Node ID of endpoint A
    uint32_t nodeIdB;                 // Node ID of endpoint B
    NetDeviceContainer tunnelDevices; // Point-to-point devices for tunnel
    Ipv4InterfaceContainer tunnelInterfaces; // IP interfaces
    bool isActive;                    // Whether tunnel is currently active
    Time activationTime;              // When tunnel was activated
    Time deactivationTime;            // When tunnel will be deactivated (if scheduled)
    WormholeStatistics stats;         // Statistics for this tunnel
    
    WormholeTunnel() : nodeIdA(0), nodeIdB(0), isActive(false) {}
};

/**
 * @brief Application that intercepts and tunnels packets (wormhole endpoint)
 */
class WormholeEndpointApp : public Application {
public:
    static TypeId GetTypeId(void);
    
    WormholeEndpointApp();
    virtual ~WormholeEndpointApp();
    
    /**
     * @brief Set the peer endpoint for tunneling
     * @param peer Pointer to the peer node
     * @param peerAddress IP address of peer's tunnel interface
     */
    void SetPeer(Ptr<Node> peer, Ipv4Address peerAddress);
    
    /**
     * @brief Set tunnel ID for statistics tracking
     */
    void SetTunnelId(uint32_t id);
    
    /**
     * @brief Set whether to drop packets instead of tunneling
     */
    void SetDropPackets(bool drop);
    
    /**
     * @brief Set selective tunneling (only tunnel certain packet types)
     */
    void SetSelectiveTunneling(bool routing, bool data);
    
    /**
     * @brief Get statistics for this endpoint
     */
    WormholeStatistics GetStatistics() const { return m_stats; }
    
protected:
    virtual void StartApplication(void);
    virtual void StopApplication(void);
    
private:
    /**
     * @brief Callback for packet reception (promiscuous mode)
     */
    bool ReceivePacket(Ptr<NetDevice> device, Ptr<const Packet> packet, 
                       uint16_t protocol, const Address &from,
                       const Address &to, NetDevice::PacketType packetType);
    
    /**
     * @brief Tunnel packet to peer
     */
    void TunnelPacket(Ptr<Packet> packet, uint16_t protocol);
    
    /**
     * @brief Check if packet should be tunneled
     */
    bool ShouldTunnelPacket(Ptr<const Packet> packet, uint16_t protocol);
    
    Ptr<Node> m_peer;
    Ipv4Address m_peerAddress;
    Ptr<Socket> m_tunnelSocket;
    uint32_t m_tunnelId;
    bool m_dropPackets;
    bool m_tunnelRoutingPackets;
    bool m_tunnelDataPackets;
    WormholeStatistics m_stats;
};

/**
 * @brief Wormhole Attack Manager - Manages all wormhole tunnels
 */
class WormholeAttackManager {
public:
    /**
     * @brief Constructor
     */
    WormholeAttackManager();
    
    /**
     * @brief Destructor
     */
    ~WormholeAttackManager();
    
    /**
     * @brief Initialize the wormhole attack
     * @param maliciousNodes Vector indicating which nodes are malicious
     * @param attackPercentage Percentage of nodes to make malicious (if not pre-set)
     * @param totalNodes Total number of nodes in network
     */
    void Initialize(std::vector<bool>& maliciousNodes, double attackPercentage, 
                    uint32_t totalNodes);
    
    /**
     * @brief Create wormhole tunnels between malicious nodes
     * @param tunnelBandwidth Bandwidth of tunnel link (e.g., "1000Mbps")
     * @param tunnelDelay Delay of tunnel link (e.g., MicroSeconds(1))
     * @param selectRandom If true, randomly pair nodes. If false, pair sequentially
     */
    void CreateWormholeTunnels(std::string tunnelBandwidth, Time tunnelDelay, 
                               bool selectRandom = true);
    
    /**
     * @brief Create a single wormhole tunnel between two specific nodes
     */
    uint32_t CreateWormholeTunnel(uint32_t nodeIdA, uint32_t nodeIdB,
                                  std::string bandwidth, Time delay);
    
    /**
     * @brief Activate wormhole attack (start intercepting packets)
     * @param startTime When to start the attack
     * @param stopTime When to stop the attack
     */
    void ActivateAttack(Time startTime, Time stopTime);
    
    /**
     * @brief Deactivate all wormhole tunnels
     */
    void DeactivateAttack();
    
    /**
     * @brief Configure visualization for wormhole nodes
     * @param anim Animation interface
     * @param nodeColor RGB color for malicious nodes (default: red)
     */
    void ConfigureVisualization(AnimationInterface& anim, 
                                uint8_t r = 255, uint8_t g = 0, uint8_t b = 0);
    
    /**
     * @brief Set wormhole behavior
     * @param dropPackets If true, drop packets instead of tunneling
     * @param tunnelRouting Tunnel routing protocol packets
     * @param tunnelData Tunnel data packets
     */
    void SetWormholeBehavior(bool dropPackets, bool tunnelRouting, bool tunnelData);
    
    /**
     * @brief Get total number of wormhole tunnels
     */
    uint32_t GetTunnelCount() const { return m_tunnels.size(); }
    
    /**
     * @brief Get statistics for a specific tunnel
     */
    WormholeStatistics GetTunnelStatistics(uint32_t tunnelId) const;
    
    /**
     * @brief Get aggregate statistics across all tunnels
     */
    WormholeStatistics GetAggregateStatistics() const;
    
    /**
     * @brief Export statistics to file
     */
    void ExportStatistics(std::string filename) const;
    
    /**
     * @brief Print current statistics to console
     */
    void PrintStatistics() const;
    
    /**
     * @brief Get list of malicious node IDs
     */
    std::vector<uint32_t> GetMaliciousNodeIds() const;
    
private:
    /**
     * @brief Randomly select node pairs for wormhole tunnels
     */
    void SelectRandomPairs(std::vector<uint32_t>& maliciousNodeIds);
    
    /**
     * @brief Select sequential pairs (for deterministic testing)
     */
    void SelectSequentialPairs(std::vector<uint32_t>& maliciousNodeIds);
    
    std::vector<WormholeTunnel> m_tunnels;
    std::vector<bool> m_maliciousNodes;
    bool m_dropPackets;
    bool m_tunnelRoutingPackets;
    bool m_tunnelDataPackets;
    uint32_t m_totalNodes;
    std::string m_defaultBandwidth;
    Time m_defaultDelay;
};

/**
 * @brief Helper function to setup wormhole attack (backward compatibility)
 */
void SetupWormholeAttack(
    std::vector<bool>& wormhole_malicious_nodes,
    uint32_t total_size,
    double attack_percentage,
    double simTime,
    AnimationInterface& anim,
    std::string tunnelBandwidth = "1000Mbps",
    Time tunnelDelay = MicroSeconds(1),
    bool randomPairing = true
);

} // namespace ns3

#endif // WORMHOLE_ATTACK_H
