# DIAGRAMA DE RED
- [DRAW.io](https://drive.google.com/file/d/1fOLiqbf9Dqsi6Pjz7pXQDc1abWRWNbg0/view?usp=drive_link)

# Link de referencia 
- [Link De uso](https://www.youtube.com/watch?v=A-mDAB6jzbU)

# 🛰️ Network Performance Testing with iperf3

This repository documents and automates the use of `iperf` to evaluate network performance between virtual machines (VMs) within a virtualized ISP lab environment.

---

## 📌 Overview

`iperf` is a modern network testing tool that measures:

- Bandwidth (TCP/UDP)
- Latency and jitter (UDP)
- Parallel stream performance
- Upload and download throughput

This is useful for validating VM network configurations, testing performance baselines, and identifying potential bottlenecks in lab infrastructure.

---

## 🧰 Requirements

- Ubuntu Server or similar Linux environment.
- `iperf` installed on all test nodes:
  ```bash
  sudo apt update && sudo apt install iperf
  ```

- VMs must be on the same network or reachable over routed infrastructure.
- (Optional) Prometheus and Grafana if monitoring integration is needed.

---

## ⚙️ Usage

### 1. Start the iperf Server
On the receiver VM:
```bash
iperf -s
```

### 2. Run the iperf3 Client
On the sender VM:
```bash
iperf -c <server_ip>
```

---

## 📦 Advanced Testing Scenarios

### UDP Mode (with bandwidth target)
```bash
iperf -c <server_ip> -u -b 100M
```

### Set Test Duration
```bash
iperf -c <server_ip> -t 30
```

### Bidirectional Testing
```bash
iperf -c <server_ip> --bidir
```

### Parallel Streams (Concurrency Test)
```bash
iperf -c <server_ip> -P 5
```

### JSON Output for Logging
```bash
iperf -c <server_ip> -J > results.json
```

---

## 🔒 Firewall Rules (if needed)
Allow traffic on default iperf port:
```bash
sudo ufw allow 5201/tcp
```

---

## 📊 Integration Suggestions

- Use the `--json` flag and push results to **Prometheus PushGateway**.
- Visualize metrics with **Grafana** dashboards.
- Combine with **LibreQoS** for advanced traffic shaping analysis.

---

## 📁 Structure

```
.
├── README.md
├── scripts/
│   └── iperf-test.sh         # Optional automation script
├── results/
│   └── iperf-output.json    # Example output files
└── grafana/
    └── iperf-dashboard.json  # Optional dashboard config
```

---

## 📄 License

MIT License. Use freely, improve boldly.

---

> **Maintained by:** [Samuel Barona]  
> **Last updated:** 7/4/2025
