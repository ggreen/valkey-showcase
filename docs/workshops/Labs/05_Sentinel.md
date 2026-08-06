# Valkey Sentinel Administration Workshop

*Objective:*

By the end of this workshop, participants will: 

- Understand the role of Valkey Sentinel
- Deploy a Valkey Sentinel environment 
- Simulate failover
- Perform basic operational tasks

## Prerequisites

 - Podman or Docker installed 
 - curl and valkey-cli

# Introduction to Sentinel

Valkey Sentinel provides:

- Monitoring: checks if a master is down 
- Notification: alerts other Sentinels and clients 
- Automatic failover: promotes a replica to master 
- Service discovery: tells clients the current master


valkey-sentinel-workshop/
├── master/
│   └── valkey.conf
├── replica1/
│   └── valkey.conf
├── replica2/
│   └── valkey.conf
├── sentinel1/
│   └── sentinel.conf
├── sentinel2/
│   └── sentinel.conf
├── sentinel3/
│   └── sentinel.conf
├── docker-compose.yml
