# Calculator FSM state diagram

```mermaid
stateDiagram-v2
    [*] --> S0_IDLE: KEY0 reset
    S0_IDLE --> S1_SHOW_A: KEY1 released
    S1_SHOW_A --> S2_SELECT_OP: KEY1 released / A <- SW
    S2_SELECT_OP --> S3_SHOW_OP: KEY1 released
    S3_SHOW_OP --> S4_PROMPT_B: KEY1 released / OP <- SW(1:0)
    S4_PROMPT_B --> S5_SHOW_B: KEY1 released
    S5_SHOW_B --> S6_START_CALC: KEY1 released / B <- SW
    S6_START_CALC --> S8_RESULT: ADD or SUB, in range
    S6_START_CALC --> S9_ERROR: ADD or SUB overflow for display
    S6_START_CALC --> S7_WAIT_CALC: MUL/DIV start pulse
    S7_WAIT_CALC --> S7_WAIT_CALC: !submodule_DONE
    S7_WAIT_CALC --> S8_RESULT: submodule_DONE & displayable
    S7_WAIT_CALC --> S9_ERROR: error / out of display range
    S8_RESULT --> S8_RESULT: hold until KEY0 reset
    S9_ERROR --> S9_ERROR: hold until KEY0 reset
```

Asynchronous active-low KEY0 reset always returns to S0_IDLE and clears values and DONE.
The hardware KEY1 button event is generated once on a **stable release**, not every 50 MHz tick.

Submodule state machines:
- Multiplier10: S_IDLE -> S_CALC (10 rounds) -> S_SIGN -> S_DONE
- Divider10: S_IDLE -> S_SUB -> S_TEST / S_RESTORE (10 rounds) -> S_SIGN_Q -> S_SIGN_R -> S_DONE
