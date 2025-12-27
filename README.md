# Ethernet MAC with RGMII Interface

## 1. Introduction

### What is this project?
This project implements a simplified Ethernet Media Access Controller (MAC) capable of handling Layer 2 network packets. It is designed to interface with an external Ethernet PHY using the **RGMII (Reduced Gigabit Media Independent Interface)** standard.

The core logic handles the encapsulation and decapsulation of Ethernet frames, including Preamble generation, Start Frame Delimiter (SFD) handling, and Frame Check Sequence (CRC32) calculation. This design serves as a foundational block for FPGA-based network communication, allowing custom hardware to send and receive raw Ethernet packets.

### Key Features
* **RGMII Interface:** Implements Double Data Rate (DDR) logic to communicate with external PHYs at high speeds.
* **Full Duplex Operation:** Independent Transmit (TX) and Receive (RX) paths allow simultaneous data flow.
* **CRC32 Integrity:** Hardware-accelerated cyclic redundancy check generation (for TX) and validation (for RX).
* **Modular Architecture:** Clean separation between the physical interface logic (RGMII) and the MAC protocol logic.
* **SystemVerilog Design:** Written in modern SystemVerilog for readability and robust simulation.


## 2. Architecture & Block Diagram

<img width="734" height="640" alt="דיאגרמת מלבנים" src="https://github.com/user-attachments/assets/d03e2f0f-7959-4f0c-90c1-40d2de7a92bf" />

The system is organized into a modular hierarchy controlled by the top-level wrapper, designed with strict **Clock Domain Crossing (CDC)** separation as shown in the diagram above:

### Clock Domains (Color Coded)
To ensure robust operation and prevent metastability, the design is split into two independent clock regions:
* **Blue Region (TX Path):** Operates on the FPGA system clock (`clk_125m`). This logic drives the transmission data generation and CRC calculation.
* **Green Region (RX Path):** Operates on the recovered PHY clock (`rgmii_rxc`). This logic is synchronized to the incoming network traffic.

### Module Description

* **ethernet_top (Top Level Wrapper)**
    * Acts as the bridge between the **User Logic** and the external **Ethernet PHY**.
    * Manages resets (`rst_n`) and signal distribution between the sub-modules.

* **MAC Layer (`eth_mac_tx` / `eth_mac_rx`)**
    * **TX Path:** Receives raw data from the user, encapsulates it into Ethernet frames (adds Preamble & SFD), calculates the Frame Check Sequence (CRC32), and handles the transmission state machine.
    * **RX Path:** Monitors the line for incoming frames, detects the SFD, validates the data integrity using CRC32, strips the protocol headers, and passes the clean payload to the user.

* **Physical Layer / RGMII (`rgmii_tx` / `rgmii_rx`)**
    * Implements the **RGMII (Reduced Gigabit Media Independent Interface)** standard.
    * **DDR Logic:** Converts 8-bit internal SDR data (Single Data Rate) into 4-bit external DDR signals (Double Data Rate) for transmission, and vice versa for reception.


## 3. Design Details

### RGMII Interface Logic
To interface with modern Gigabit PHYs, the design uses RGMII:
* **TX Path:** Converts internal 8-bit data @ 125MHz (SDR) into 4-bit data @ 125MHz (DDR) triggering on both rising and falling edges.
* **RX Path:** Samples incoming 4-bit DDR data from the PHY and reconstructs the 8-bit internal byte stream.

### CRC32 Calculation
Data integrity is ensured using standard Ethernet CRC32 (polynomial `0x04C11DB7`):
* **Generator:** Calculates the checksum on-the-fly as data is transmitted.
* **Checker:** Verifies the checksum of incoming packets to ensure no bits were corrupted during transmission.


## 4. Verification

The project includes a comprehensive **SystemVerilog Testbench** (`ethernet_tb.sv`) that simulates the interaction between the MAC and an external PHY:
* **Clock Generation:** Generates the main system clock (`clk_125m`) and the asynchronous RGMII RX clock (`rgmii_rxc`) to simulate real hardware timing.
* **Traffic Generation:** Simulates incoming packets from a PHY and initiates outgoing transmissions from the user logic.
* **Protocol Checks:** Verifies the RGMII Double Data Rate (DDR) timing, Preamble/SFD detection, and correct State Machine transitions.
* **Data Integrity:** Validates that the received payload matches the expected data after header stripping.
  
### Simulation Results

Below is the waveform showing a complete Receive (RX) and Transmit (TX) sequence:

<img width="1841" height="344" alt="דיאגרמת גלים" src="https://github.com/user-attachments/assets/b367ccbd-a4bd-4d58-80fa-229a42ecde3b" />

1.  **RX Path:** The simulation begins with `rst_n` de-asserting. The PHY drives `rgmii_rx_ctl` high and sends data. The MAC detects the frame, transitions the `state` (from 0 to 1, 2, 3...), and asserts `rx_valid` to output the stripped payload on `rx_data`.
2.  **TX Path:** A transmission is triggered by the `tx_start` signal. The MAC immediately asserts `rgmii_tx_ctl` and drives the packet data onto the `rgmii_txd` bus towards the PHY.


## 5. File Descriptions

* `ethernet_top.sv`: The top-level module acting as the wrapper for the entire Ethernet MAC system.
* `eth_mac_tx.sv`: Implements the Transmit FSM, handling frame construction (Preamble, SFD, Data, CRC).
* `eth_mac_rx.sv`: Implements the Receive FSM, handling frame detection and deframing.
* `rgmii_tx.sv`: Handles the DDR output logic for transmitting data to the PHY via RGMII.
* `rgmii_rx.sv`: Handles the DDR input logic for receiving data from the PHY via RGMII.
* `crc32_gen.sv`: Logic module for generating the 32-bit CRC for outgoing packets.
* `crc32_eth.sv`: Logic module for CRC calculations/checking (shared or specific implementation).


## 6. Tools Used

* **Language:** SystemVerilog (IEEE 1800)
* **Simulation:** Aldec Riviera-PRO (via EDA Playground)
* **Waveform Viewing:** EPWave
* **Diagram:** draw.io
