# CapBots: Swarm Simulation Without Wireless Communication

This project implements a simulation framework for **CapBot networks** — energy-constrained swarm robots that exchange data and energy via **physical trophallaxis**, inspired by social insects. The swarm operates **without wireless communication**, relying instead on decentralized behavior and local interactions.

## 🛠 Core Features

- **Full simulation engine written in Ruby**:
  - Custom-built **core**, **graphics**, and **physics engine**
  - Modular architecture for swarm behavior modeling
  - Dynamic configuration system for agents, maps, and behavior

- **Integrated experiment system**:
  - Configurable **stop conditions**, **iteration counts**, and **parameter sweeps**
  - Automated experimentation for parameter tuning and benchmarking

- **Replayer tool**:
  - Load and visualize simulation replays for debugging and performance analysis

- **CLI interface**:
  - Run **simulations**, **replays**, and **experiments**
  - Supports **headless mode** and **configurable logging**

## 📊 Rust/Python-Based Analysis Backend

- High-performance **Rust module** for automated data processing and visualization
- Generates statistics and comparative plots for:
  - `Bot Data`
  - `Bot Energy Levels`
  - `Bot Statusses`
  - `Bot Locations`
  - `Cumulative Data`
  - `Cumulative Energy`
- Includes best- & worst-parameter analysis for experiment optimization

## 📦 Project Overview

```shell
.
├── ansible                     - Ansible playbooks for deployment of experiments
├── bin                         - Ruby binaries
├── configurations              - Configuration files
│ └── maps                      - Map configurations
├── lib
│ ├── experiment                - Experiment management
│ ├── graphics                  - Graphics handling
│ ├── kd_tree                   - KD-Tree implementation
│ ├── logger                    - Logging utilities (for replays, experiments, etc.)
│ ├── physics                   - Physics engine
│ │ └── shape                   - Shape definitions
│ ├── replay                    - Replay system
│ └── simulation                - Simulation core
│     └── object                - Simulation objects
│         ├── bot               - Bot definitions
│         │ ├── capabilities    - Bot capabilities
│         │ ├── communication   - Communication management
│         │ ├── path            - Path and collision handling
│         │ ├── strategy        - Bot strategies
│         │ └── tasks           - Bot tasks (e.g. trophallaxis, data transfer, collisions, etc.)
│         ├── data              - Data bundles
│         └── obstacle          - Obstacle definitions (walls, stations, target stations)
├── logs                        - Log files (for replays)
├── spec                        - RSpec tests ;) 
├── sprites                     - Sprites
└── stats                       - Statistics and analysis
```
