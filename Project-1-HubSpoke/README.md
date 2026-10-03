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


