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

The system is organized into a modular hierarchy controlled by the top-level wrapper:

* **ethernet_top (Top Level):**
    * Integrates the MAC TX/RX paths with the RGMII I/O logic.
    * Manages the reset and clock distribution.

* **MAC Layer (eth_mac_tx / eth_mac_rx):**
    * **TX:** Receives data from the user application, appends Preamble/SFD, calculates CRC, and formats the Ethernet frame.
    * **RX:** Detects incoming frames, validates the CRC32, strips the header, and passes the payload to the user application.

* **Physical Layer (rgmii_tx / rgmii_rx):**
    * Handles the specific timing requirements of the RGMII standard.
    * Converts 8-bit internal data to 4-bit DDR external signals (and vice versa).

graph TD
    subgraph Ethernet_System [ethernet_top]
        direction LR
        
        %% Clocks and Resets
        CLK[clk_125m / rst_n] --- MAC_TX
        CLK --- MAC_RX
        
        %% Transmit Path
        subgraph TX_Path [Transmit Path]
            User_TX[User Logic] -->|tx_data, tx_start| MAC_TX[eth_mac_tx]
            MAC_TX -->|Generate CRC| CRC_GEN[crc32_gen]
            CRC_GEN -->|CRC Result| MAC_TX
            MAC_TX -->|8-bit data| RGMII_TX[rgmii_tx]
            RGMII_TX -->|4-bit DDR| PHY_TX[To PHY]
        end

        %% Receive Path
        subgraph RX_Path [Receive Path]
            PHY_RX[From PHY] -->|4-bit DDR| RGMII_RX[rgmii_rx]
            RGMII_RX -->|8-bit data| MAC_RX[eth_mac_rx]
            MAC_RX -->|Check CRC| CRC_CHK[crc32_eth]
            CRC_CHK -->|Valid/Error| MAC_RX
            MAC_RX -->|rx_data, rx_valid| User_RX[User Logic]
        end
    end
    
    style Ethernet_System fill:#f9f9f9,stroke:#333,stroke-width:2px
    style MAC_TX fill:#d4e1f5,stroke:#333
    style MAC_RX fill:#d4e1f5,stroke:#333
    style RGMII_TX fill:#e1f5d4,stroke:#333
    style RGMII_RX fill:#e1f5d4,stroke:#333

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
