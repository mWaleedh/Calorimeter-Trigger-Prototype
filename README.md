# Technical Specification: 4-Stage Pipelined Calorimeter Trigger

## 1. Project Overview
This project implements a high-throughput, cycle-accurate calorimeter trigger prototype designed for real-time data reduction in high-energy physics environments. The system processes 12 parallel channels of digitized energy data to identify "jet" candidates through local energy concentrations and global energy sums. 

To handle the high event frequency characteristic of Large Hadron Collider (LHC) experiments, the design utilizes a **streaming pipelined architecture**. This approach ensures that the system can accept a new input event on every clock cycle, regardless of the total calculation latency.

## 2. Architectural Design Philosophy
The architecture follows a streaming paradigm rather than a centralized Finite State Machine (FSM) control structure. 

*   **Streaming vs. FSM:** Centralized FSMs often introduce stall cycles or complex handshaking that limits throughput. By utilizing streaming semantics, this design achieves a throughput of one event per clock cycle.
*   **Valid-Signal Propagation:** Control is decentralized. A "valid" bit travels alongside the data through every register stage. This ensures that the control logic is always perfectly synchronized with the data path, eliminating the risk of misaligning decisions with the wrong event.
*   **Register-Defined Boundaries:** Pipeline registers are placed to break the critical path of the arithmetic logic (adders and comparators), allowing for higher maximum frequencies ($F_{max}$) while maintaining deterministic, fixed latency.

## 3. Top-Level Block Diagram Description
The system is partitioned into a single linear pipeline. The diagram (referenced in accompanying artifacts) should be interpreted as a series of four vertical register banks (Stage 0 through Stage 3). 
*   **Vertical Rails:** Represent the clock-edge boundaries.
*   **Logic Clouds:** Represent the combinatorial operations performed on the data while it resides in a specific stage's registers.
*   **Horizontal Paths:** Represent the data and control signals flowing forward.

## 4. Pipeline Stage-by-Stage Breakdown

### Stage 0: Input Sampling
*   **Purpose:** To provide a clean, registered boundary for external asynchronous or poorly timed inputs.
*   **Inputs:** Raw channel data (12x12-bit), `event_valid_i`, and thresholds.
*   **Operation:** On the rising edge, all inputs are captured into the `s0` register bank. 
*   **Valid Handling:** `s0_valid` is asserted based on the external `event_valid_i`.

### Stage 1: Sliding Window Evaluation (Local Feature Extraction)
*   **Purpose:** To identify local energy clusters (jets) using a 3-channel sliding window.
*   **Combinatorial Logic:** 10 parallel 3-input adders followed by 10 parallel comparators. A final 10-input OR-reduction identifies if any window exceeded the `stage1_threshold`.
*   **Operation:** The results of the OR-reduction and a copy of the raw `s0_channels` are prepared for the next register bank.
*   **Registered Outputs:** `s1_stage1_pass`, `s1_channels`, `s1_valid`.

### Stage 2: Global Energy Evaluation (Global Summation)
*   **Purpose:** To compute the total energy of the event for high-precision filtering.
*   **Combinatorial Logic:** A 12-input balanced adder tree and a single global comparator.
*   **Operation:** Performs the full summation of all channels residing in the `s1` registers. This stage implements "early rejection" logic: if `s1_stage1_pass` is low, the `s2_valid` bit is de-asserted to prevent downstream processing.
*   **Registered Outputs:** `s2_stage2_pass`, `s2_valid`.

### Stage 3: Final Decision Register
*   **Purpose:** To provide a stable, registered output for the final trigger decision.
*   **Combinatorial Logic:** A logical AND between the propagated `s2_stage1_pass` and the newly calculated `s2_stage2_pass`.
*   **Operation:** The final result is gated by `s2_valid` to ensure no false triggers are emitted during idle cycles or after rejections.
*   **Output:** `final_accept_o`.

## 5. Cycle-Accurate Timing Description
The pipeline operates with a fixed latency of **4 clock cycles**.

| Relative Cycle | Event Position | Activity |
| :--- | :--- | :--- |
| **Cycle N** | Input Ports | Event arrives at system boundary. |
| **Cycle N+1** | Stage 0 | Event is sampled and stabilized. |
| **Cycle N+2** | Stage 1 | Sliding window sums and local thresholds evaluated. |
| **Cycle N+3** | Stage 2 | Global sum and global threshold evaluated. |
| **Cycle N+4** | Stage 3 | Final decision is registered and appears at `final_accept_o`. |

**Throughput:** 1 event / cycle.
**Latency:** 4 cycles.

## 6. Valid Signal Semantics
The `valid` signal represents the presence of a meaningful physics event within a specific pipeline stage.
*   **Reset Behavior:** On `reset_i`, only the `valid` registers are cleared to '0'. 
*   **Data Persistence:** Data registers are not reset. This reduces power consumption and toggle rates. The system relies on the `valid` bit to qualify whether the data in a register is "garbage" or "event."
*   **Flushing:** Dropping the input `event_valid_i` to '0' allows the pipeline to "drain" naturally; the last valid event will exit Stage 3 four cycles later.

## 7. Design Correctness Guarantees
*   **Deterministic Latency:** Because no feedback loops or stall-logic (backpressure) exist, the latency is invariant.
*   **Race Condition Prevention:** By pipelining the `valid` bit and the `threshold` signals alongside the channel data, all components of a decision are guaranteed to be derived from the same temporal snapshot.
*   **Combinatorial Path Control:** Registers are placed after every major arithmetic operation (Adder Tree, Sliding Window) to prevent long propagation delays.

## 8. Simulation Methodology
Verification was performed using a cycle-accurate VHDL testbench.
*   **Throughput Verification:** Demonstrated by asserting `valid_i` for multiple consecutive cycles and observing back-to-back pulses on `final_accept_o`.
*   **Latency Verification:** Measured by the cycle count between the first `valid_i` assertion and the first `final_accept_o` assertion.
*   **Corner Cases:** The simulation includes events that pass Stage 1 but fail Stage 2 to verify the multi-stage rejection logic.

## 9. Limitations and Non-Goals
*   **Backpressure:** This design does not support `READY` signaling (handshaking). It assumes the downstream consumer can always accept data at the line rate.
*   **Physical Constraints:** Pin assignments and timing closure for specific hardware (e.g., Artix-7/Cyclone V) are outside the scope of this RTL-only verification.
*   **Asynchronous Resets:** The design assumes a synchronous reset strategy.

## 10. Future Extensions
*   **AXI4-Stream Compliance:** Future iterations could wrap this pipeline in a formal AXI-Stream interface (adding `TLAST` and `TREADY`).
*   **Muon Integration:** Parallel track-finding pipelines can be integrated into the Stage 2 decision logic.
*   **Programmable Thresholds:** Replacing internal constants with an AXI-Lite register interface for dynamic threshold adjustment.

***

# Meta-Analysis: How to write like an Engineer

When you write documentation like the above, you are learning several high-level professional skills:

1.  **Terminology as a Precision Tool:** Notice words like *Deterministic*, *Throughput*, *Critical Path*, and *Propagated*. These aren't fancy synonyms; they have specific mathematical and physical meanings in hardware. Using them correctly tells an employer you understand the underlying physics of FPGAs.
2.  **The "Separation of Concerns":** You didn't just explain the code; you explained the *semantics* (the rules). Section 6 (Valid Signal Semantics) is the most important section for a professional. It explains the "Control Law" of your chip.
3.  **Admitting Limitations:** In Section 9, we list what the project *doesn't* do. Students often try to hide weaknesses. Professionals list "Non-Goals" to define the scope of the contract. It proves you know what a full system requires (like AXI or timing closure) even if you didn't implement it here.
4.  **Formatting for Skimmers:** Engineers are busy. They look for tables (Section 5) and bullet points. If they can understand your pipeline without reading the paragraphs, you've written a great document.

**How to practice this:** Next time you write a component (even a small one), try to write a "Timing Table" for it first. If you can't define the timing in a table, you haven't fully designed the hardware yet.