# Visual Architecture Diagrams

## 1. System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         VANET SIMULATION SYSTEM                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                    MAIN SIMULATION (routing.cc)                 │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │  │
│  │  │  Network     │  │   Mobility   │  │  Applications│          │  │
│  │  │  Topology    │  │   Models     │  │   & Traffic  │          │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                  │                                     │
│                                  ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │              ATTACK MODULE (wormhole_attack.h/cc)               │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │         WormholeAttackManager                           │   │  │
│  │  │  • Initialize malicious nodes                           │   │  │
│  │  │  • Create tunnels between pairs                         │   │  │
│  │  │  • Manage attack lifecycle                              │   │  │
│  │  │  • Collect & export statistics                          │   │  │
│  │  └─────────────────────────────────────────────────────────┘   │  │
│  │                          │                                      │  │
│  │                          ▼                                      │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │         WormholeEndpointApp (per tunnel end)            │   │  │
│  │  │  • Intercept packets (promiscuous mode)                 │   │  │
│  │  │  • Selective tunneling/dropping                         │   │  │
│  │  │  • Statistics tracking                                  │   │  │
│  │  └─────────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                  │                                     │
│                                  ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                        OUTPUT MODULES                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │  │
│  │  │   NetAnim    │  │ CSV Export   │  │   Console    │          │  │
│  │  │ Visualization│  │  Statistics  │  │    Output    │          │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                  │                                     │
│                                  ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                    ANALYSIS TOOLS                               │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │  │
│  │  │   Python     │  │     Bash     │  │   MATLAB/R   │          │  │
│  │  │   Scripts    │  │  Test Suite  │  │   Analysis   │          │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 2. Wormhole Attack Flow

```
NORMAL ROUTING                          WORMHOLE ATTACK
═══════════════                          ═══════════════

 Node A                                  Node A
   │                                       │
   │ (hop 1)                              │ (hop 1)
   ▼                                       ▼
 Node B                                  Malicious M1 ◄─────┐
   │                                       │                │
   │ (hop 2)                              │ INTERCEPT       │
   ▼                                       │                │ WORMHOLE
 Node C                                   ╞═══════════════╡ TUNNEL
   │                                      ║ 1000 Mbps     ║ (High-speed
   │ (hop 3)                              ║ 1 μs delay    ║  bypass)
   ▼                                      ╞═══════════════╡
 Node D                                   │                │
   │                                      │ REPLAY         │
   │ (hop 4)                              │                │
   ▼                                       ▼                │
 Node E                                  Malicious M2 ◄────┘
 (Dest)                                   │
                                          │ (hop 2)
   Total: 4 hops                          ▼
   Delay: ~40ms                         Node E
                                        (Dest)

                                          Total: 2 hops
                                          Delay: ~20ms + 1μs
                                          
   Result: Normal routing               Result: Disrupted topology
                                               False neighbor info
                                               Incorrect route metrics
```

## 3. Class Relationship Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                         NS-3 CLASSES                               │
└────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
        ┌───────────▼──────────┐    ┌──────────▼─────────┐
        │   ns3::Application   │    │   ns3::Object      │
        └───────────┬──────────┘    └──────────┬─────────┘
                    │                           │
                    │                           │
        ┌───────────▼──────────────┐            │
        │  WormholeEndpointApp     │            │
        ├──────────────────────────┤            │
        │ - m_peer                 │            │
        │ - m_peerAddress          │            │
        │ - m_tunnelSocket         │            │
        │ - m_stats                │            │
        ├──────────────────────────┤            │
        │ + SetPeer()              │            │
        │ + SetTunnelId()          │            │
        │ + ReceivePacket()        │            │
        │ + TunnelPacket()         │            │
        │ + GetStatistics()        │            │
        └──────────────────────────┘            │
                                                │
                              ┌─────────────────▼──────────────────┐
                              │   WormholeAttackManager           │
                              │   (Standalone Manager)            │
                              ├───────────────────────────────────┤
                              │ - m_tunnels[]                     │
                              │ - m_maliciousNodes[]              │
                              │ - m_behavior_config               │
                              ├───────────────────────────────────┤
                              │ + Initialize()                    │
                              │ + CreateWormholeTunnels()         │
                              │ + ActivateAttack()                │
                              │ + GetAggregateStatistics()        │
                              │ + ExportStatistics()              │
                              └───────────────────────────────────┘
                                        │
                                        │ manages
                                        ▼
                    ┌────────────────────────────────────┐
                    │      WormholeTunnel Struct         │
                    ├────────────────────────────────────┤
                    │ - endpointA, endpointB             │
                    │ - tunnelDevices                    │
                    │ - tunnelInterfaces                 │
                    │ - stats (WormholeStatistics)       │
                    └────────────────────────────────────┘
```

## 4. Packet Interception Mechanism

```
REGULAR PACKET FLOW                   WORMHOLE INTERCEPTION
═══════════════════                   ═════════════════════

Application Layer                     Application Layer
       ▲                                     ▲
       │                                     │
       │                                     │
Transport Layer                       Transport Layer
       ▲                                     ▲
       │                                     │
       │                                     │
Network Layer (IP)                    Network Layer (IP)
       ▲                                     ▲
       │                                     │
       │                                     │
Link Layer                            Link Layer
       ▲                                     ▲
       │                                     │
       │                                     │
Physical Layer                        Physical Layer
       │                                     │
   [Receive]                             [Receive]
       │                                     │
       │                                     ├──────────────────┐
       │                                     │                  │
       │                              Promiscuous Mode          │
       │                              Callback Set              │
       │                                     │                  │
       ▼                                     ▼                  │
  [Forward]                          [Intercept by             │
                                    WormholeEndpointApp]       │
                                             │                  │
                                             │                  │
                                      ┌──────▼───────┐         │
                                      │  Decision:   │         │
                                      │  • Tunnel?   │         │
                                      │  • Drop?     │         │
                                      │  • Forward?  │         │
                                      └──────┬───────┘         │
                                             │                  │
                                    ┌────────┼────────┐        │
                                    │        │        │        │
                                    ▼        ▼        ▼        │
                                [Tunnel] [Drop]  [Forward]    │
                                    │                          │
                                    │ UDP Socket               │
                                    │ to Peer                  │
                                    ▼                          │
                            [Peer Receives] ◄─────────────────┘
                                    │
                                    │ Replay to Network
                                    ▼
                            [Injected Back]
```

## 5. Statistics Collection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    PACKET INTERCEPTION                          │
│                            │                                    │
│                            ▼                                    │
│                  ┌──────────────────┐                           │
│                  │  Update Stats:   │                           │
│                  │  • Intercepted++ │                           │
│                  │  • Timestamp     │                           │
│                  └────────┬─────────┘                           │
│                           │                                     │
│              ┌────────────┴────────────┐                        │
│              │                         │                        │
│              ▼                         ▼                        │
│     ┌─────────────────┐      ┌─────────────────┐              │
│     │  If TUNNELED:   │      │  If DROPPED:    │              │
│     │  • Tunneled++   │      │  • Dropped++    │              │
│     │  • Delay calc   │      │  • Update time  │              │
│     │  • Type check   │      └─────────────────┘              │
│     └────────┬────────┘                                        │
│              │                                                  │
│              ▼                                                  │
│     ┌─────────────────┐                                        │
│     │ Routing/Data?   │                                        │
│     └────────┬────────┘                                        │
│              │                                                  │
│      ┌───────┴───────┐                                         │
│      ▼               ▼                                         │
│  [Routing++]    [Data++]                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PER-ENDPOINT STATISTICS                            │
│  WormholeStatistics {                                           │
│    packetsIntercepted = 1234                                    │
│    packetsTunneled = 1200                                       │
│    packetsDropped = 34                                          │
│    routingPacketsAffected = 856                                 │
│    dataPacketsAffected = 378                                    │
│    totalTunnelingDelay = 0.0012s                                │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                PER-TUNNEL AGGREGATION                           │
│  tunnel.stats = endpointA.stats + endpointB.stats               │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              GLOBAL AGGREGATION                                 │
│  aggregate = Σ(all tunnel.stats)                                │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXPORT                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Console    │  │     CSV      │  │   NetAnim    │         │
│  │   Output     │  │    File      │  │   Visual     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## 6. Configuration Hierarchy

```
┌──────────────────────────────────────────────────────────────┐
│                    USER CONFIGURATION                        │
│  • Command-line arguments                                    │
│  • Code constants                                            │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              WORMHOLE ATTACK MANAGER                         │
│                                                              │
│  Global Configuration:                                       │
│  ├─ attack_percentage: 0.1                                  │
│  ├─ use_enhanced_wormhole: true                             │
│  ├─ wormhole_random_pairing: true                           │
│  └─ total_nodes: 100                                        │
│                                                              │
│  Tunnel Configuration:                                       │
│  ├─ wormhole_tunnel_bandwidth: "1000Mbps"                   │
│  └─ wormhole_tunnel_delay_us: 1                             │
│                                                              │
│  Behavior Configuration:                                     │
│  ├─ wormhole_drop_packets: false                            │
│  ├─ wormhole_tunnel_routing: true                           │
│  └─ wormhole_tunnel_data: true                              │
│                                                              │
│  Timing Configuration:                                       │
│  ├─ wormhole_start_time: 0.0                                │
│  └─ wormhole_stop_time: 300.0                               │
│                                                              │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                 PER-TUNNEL INSTANCES                         │
│                                                              │
│  Tunnel 0 (Node 5 ↔ Node 23):                               │
│  ├─ Bandwidth: 1000Mbps                                     │
│  ├─ Delay: 1μs                                              │
│  ├─ Active: true                                            │
│  └─ Endpoints configured with behavior                      │
│                                                              │
│  Tunnel 1 (Node 12 ↔ Node 45):                              │
│  ├─ Bandwidth: 1000Mbps                                     │
│  ├─ Delay: 1μs                                              │
│  ├─ Active: true                                            │
│  └─ Endpoints configured with behavior                      │
│                                                              │
│  ... (more tunnels)                                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## 7. Timeline Diagram

```
Simulation Timeline (0s → 300s)
═══════════════════════════════════════════════════════════════════

0s ┬──────────────────────────────────────────────────────────── 300s
   │
   │ ┌─ Network Initialization
   ├─┤
   │ └─ Nodes created, mobility set, routing initialized
   │
   │ ┌─ Wormhole Attack Setup
   ├─┤
   │ └─ Malicious nodes marked, tunnels created
   │
   │   [wormhole_start_time] ←─────────────────────┐
   │                                                │
   ├───────────┬─ Attack Activation                │
   │           │  • Endpoints start interception    │
   │           │  • Promiscuous mode enabled        │
   │           │  • Tunneling begins                │
   │           │                                    │
   │           │ ═══════════════════════════════════╣
   │           │     ACTIVE ATTACK PERIOD           ║
   │           │   • Packets intercepted            ║
   │           │   • Tunneling/dropping occurs      ║
   │           │   • Statistics collected           ║
   │           │ ═══════════════════════════════════╣
   │           │                                    │
   │           │               [wormhole_stop_time] │
   │           └─ Attack Deactivation ◄─────────────┘
   │             • Endpoints stop
   │             • Final statistics recorded
   │
   │ ┌─ Data Transmission Period
   ├─┤  • Applications send/receive data
   │ │  • Routing protocol messages
   │ └─ • Impact of attack measured
   │
   ├───────── Simulation End
   │         • Statistics exported
   │         • Animation saved
   │         • Console summary printed
   │
   └─────────────────────────────────────────────────────────────────

Legend:
┬ Event marker
├ Time point
│ Continuous activity
═ Attack active period
```

## 8. Data Flow Diagram

```
┌───────────┐
│   USER    │
└─────┬─────┘
      │ runs ./waf --run "routing ..."
      ▼
┌─────────────────────────────────────────────────────────┐
│              main() in routing.cc                       │
│  1. Parse arguments                                     │
│  2. Initialize network                                  │
│  3. Setup wormhole if enabled                           │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         WormholeAttackManager::Initialize()             │
│  • Select malicious nodes                               │
│  • Store configuration                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│       WormholeAttackManager::CreateWormholeTunnels()    │
│  • Pair malicious nodes                                 │
│  • Create P2P links                                     │
│  • Assign IP addresses                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│       WormholeAttackManager::ActivateAttack()           │
│  • Create endpoint apps                                 │
│  • Install on nodes                                     │
│  • Set callbacks                                        │
│  • Schedule start/stop                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Simulator::Run()                           │
│                                                         │
│  During simulation:                                     │
│  ┌──────────────────────────────────────────────┐      │
│  │  Packet arrives at malicious node            │      │
│  │         │                                     │      │
│  │         ▼                                     │      │
│  │  WormholeEndpointApp::ReceivePacket()        │      │
│  │         │                                     │      │
│  │         ├─→ Check if should tunnel           │      │
│  │         │                                     │      │
│  │         ├─→ Update statistics                │      │
│  │         │                                     │      │
│  │         └─→ Tunnel/Drop/Forward              │      │
│  │                                               │      │
│  └──────────────────────────────────────────────┘      │
│                                                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Simulation Completes                            │
│  • Attack stops (if not already)                        │
│  • Statistics finalized                                 │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│    WormholeAttackManager::PrintStatistics()             │
│    WormholeAttackManager::ExportStatistics()            │
│  • Console output                                       │
│  • CSV file generation                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌───────────┐    ┌──────────────┐    ┌─────────────────┐
│  Console  │    │    CSV File  │    │  NetAnim XML    │
│  Output   │    │              │    │                 │
└───────────┘    └──────────────┘    └─────────────────┘
                        │
                        ▼
             ┌────────────────────┐
             │  wormhole_analysis │
             │       .py          │
             │  • Parse CSV       │
             │  • Generate plots  │
             │  • Analysis report │
             └────────────────────┘
```

---

These diagrams provide visual understanding of the wormhole attack implementation architecture, data flow, and operation.
