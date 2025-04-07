
# Branch Description: `serviceIPERF`

## Objective
Deploy and validate the **iperf** service to perform network performance testing between virtual machines (VMs) in the ISP lab environment.

## Scope
- Installation of `iperf3` on client and server nodes.
- Execution of both TCP and UDP tests.
- Measurement of **bandwidth**, **latency**, and **jitter**.
- Logging and documentation of test results.

## Involved Infrastructure
- Virtual machines managed with Vagrant and VirtualBox.
- Internal virtual network with IPv4/IPv6 addressing.
- VLAN segmentation as defined in the lab architecture.

## Expected Results
- Validation of basic connectivity and network performance.
- Establish a performance baseline for comparison with other tools or configurations.
- Detect bottlenecks or misconfigurations in the current setup.

## Notes
If using Prometheus, consider integrating test metrics into Grafana dashboards for visualization.

---

> **Owner:** [Samuel Barona]  
> **Start Date:** [6/04/2025]  
> **Status:** 🚧 In Progress 
