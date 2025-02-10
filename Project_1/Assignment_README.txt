Memory Game Using BRAM, Switches, and LEDs
Objective:

Design a simple memory matching game using the Zybo Z7 board, on-chip BRAM, switches, and LEDs. Players will guess random 4-bit values stored in BRAM by using switches and receive feedback through LEDs.

Task:

    1) BRAM Initialization: Store 10 random 4-bit values in BRAM.
    2) Player Input: Players use SW0–SW3 to input a 4-bit guess and press BTN0 to submit it.
    3) Feedback Mechanism:
        If the player’s guess matches the stored value, LED0 (Green) lights up.
        If the guess is incorrect, LED1 (Red) lights up.
    4) Sequential Progress: Move to the next BRAM address after each guess, looping back after 10 addresses.

Hardware Connections:

    * SW0–SW3: Player input (4-bit guess)
    * BTN0: Guess submission
    * LED0: Correct guess indicator (Green)
    * LED1: Incorrect guess indicator (Red)

Deliverables:

	All Verilog, Constraint, and Waveform files (can be submitted via GitHub repository).
	Screenshots of the Testbench simulation results (can be included in the GitHub repository or a README file).

