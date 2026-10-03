## 🌐 Project 1: Enterprise Hub-Spoke Network Topology

### 📊 Network Traffic Detour Path
This layout isolates your workloads. Instead of a direct shortcut (bypass) between Production (A) and Data (C), your code forces all data packets to take an enforced detour through the security checkpoint in the Hub (B).

```mermaid
graph TD
    A[A: Production Subnet - 10.1.1.0/24] --->|1. Enforced Detour via UDR| B(B: Central Hub Router - 10.0.1.4)
    B --->|2. Approved Traffic Delivery| C[C: Private Data Subnet - 10.2.1.0/24]

    A <.-.-> |VNet Peering: allowForwardedTraffic| B
    C <.-.-> |VNet Peering: allowForwardedTraffic| B
```

### 🧠 Core Architectural Strategy Explained
* **The Peering Transit Flag (`allowForwardedTraffic: true`):** By default, Azure virtual network peering is non-transitive. Setting this flag to `true` authorizes the Hub network to act as an active middleman router, accepting and passing along packets it did not originate.
* **The User-Defined Route Override (UDR):** Injected a custom Route Table directly into the Production application subnet. This forces an explicit detour rule: any packet bound for the database subnet (`10.2.0.0/16`) is blocked from routing directly and is forced into the central router IP (`10.0.1.4`) in the Hub first.
