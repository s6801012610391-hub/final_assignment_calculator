-- Main FSM (one transition per debounced KEY1 press/release).
-- Uses all five modules from the original GitHub repository.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Calculator_Core is
    port (
        CLK : in std_logic;
        RST_N : in std_logic;
        STEP_PULSE : in std_logic;
        SW : in std_logic_vector(9 downto 0);
        DISP_MODE : out std_logic_vector(2 downto 0);
        DISP_VALUE : out std_logic_vector(19 downto 0);
        DISP_OP : out std_logic_vector(1 downto 0);
        DISP_Q : out std_logic_vector(10 downto 0);
        DISP_R : out std_logic_vector(10 downto 0);
        DONE : out std_logic;
        DEBUG_STATE : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of Calculator_Core is
    type state_t is (S0_IDLE, S1_SHOW_A, S2_SELECT_OP, S3_SHOW_OP,
                     S4_PROMPT_B, S5_SHOW_B, S6_START_CALC, S7_WAIT_CALC,
                     S8_RESULT, S9_ERROR);
    signal state : state_t := S0_IDLE;
    signal a_reg, b_reg : std_logic_vector(9 downto 0) := (others => '0');
    signal op_reg : std_logic_vector(1 downto 0) := (others => '0');
    signal result_reg : std_logic_vector(19 downto 0) := (others => '0');
    signal quotient_reg, remainder_reg : std_logic_vector(10 downto 0) := (others => '0');

    signal addsub_mode : std_logic;
    signal addsub_result : std_logic_vector(10 downto 0);
    signal unused_overflow : std_logic;
    signal mul_result : std_logic_vector(19 downto 0);
    signal mul_done : std_logic;
    signal div_q, div_r : std_logic_vector(10 downto 0);
    signal div_done, div_by_zero : std_logic;
    signal mul_start, div_start : std_logic;

    function fits_result_display(x : signed(19 downto 0)) return boolean is
        variable n : integer;
    begin
        n := to_integer(x);
        if n >= 0 then return n <= 999999; -- HEX5..HEX0 = 6 decimal digits
        else return n >= -99999;            -- HEX5 = sign, 5 digits remain
        end if;
    end function;

    function fits_division(q : signed(10 downto 0);
                           r : signed(10 downto 0)) return boolean is
        variable qi, ri : integer;
    begin
        qi := to_integer(q); ri := to_integer(r);
        return (qi <= 99 and qi >= -99 and ri <= 99 and ri >= -99);
    end function;
begin
    addsub_mode <= '1' when op_reg = "10" else '0';
    ADD_SUB : entity work.AdderSubtractor10
        port map (A => a_reg, B => b_reg, M => addsub_mode,
                  S => addsub_result, V => unused_overflow);

    mul_start <= '1' when state = S6_START_CALC and op_reg = "01" else '0';
    div_start <= '1' when state = S6_START_CALC and op_reg = "00" else '0';
    MUL : entity work.Multiplier10
        port map (CLK => CLK, RST_N => RST_N, START => mul_start,
                  A => a_reg, B => b_reg, R => mul_result, DONE => mul_done);
    DIV : entity work.Divider10
        port map (CLK => CLK, RST_N => RST_N, START => div_start,
                  A => a_reg, B => b_reg, QUOTIENT => div_q,
                  REMAINDER => div_r, DONE => div_done, DIV_BY_ZERO => div_by_zero);

    process(CLK, RST_N)
        variable ext_addsub : signed(19 downto 0);
    begin
        if RST_N = '0' then
            state <= S0_IDLE;
            a_reg <= (others => '0'); b_reg <= (others => '0');
            op_reg <= (others => '0');
            result_reg <= (others => '0');
            quotient_reg <= (others => '0');
            remainder_reg <= (others => '0');
        elsif rising_edge(CLK) then
            case state is
                when S0_IDLE =>
                    if STEP_PULSE = '1' then state <= S1_SHOW_A; end if;
                when S1_SHOW_A =>
                    if STEP_PULSE = '1' then
                        a_reg <= SW;
                        state <= S2_SELECT_OP;
                    end if;
                when S2_SELECT_OP =>
                    if STEP_PULSE = '1' then state <= S3_SHOW_OP; end if;
                when S3_SHOW_OP =>
                    if STEP_PULSE = '1' then
                        op_reg <= SW(1 downto 0);
                        state <= S4_PROMPT_B;
                    end if;
                when S4_PROMPT_B =>
                    if STEP_PULSE = '1' then state <= S5_SHOW_B; end if;
                when S5_SHOW_B =>
                    if STEP_PULSE = '1' then
                        b_reg <= SW;
                        state <= S6_START_CALC;
                    end if;
                when S6_START_CALC =>
                    if op_reg = "11" or op_reg = "10" then
                        ext_addsub := resize(signed(addsub_result), 20);
                        result_reg <= std_logic_vector(ext_addsub);
                        if fits_result_display(ext_addsub) then
                            state <= S8_RESULT;
                        else
                            state <= S9_ERROR;
                        end if;
                    else
                        -- MUL_START or DIV_START is a single clock-wide pulse
                        state <= S7_WAIT_CALC;
                    end if;
                when S7_WAIT_CALC =>
                    if op_reg = "01" and mul_done = '1' then
                        result_reg <= mul_result;
                        if fits_result_display(signed(mul_result)) then
                            state <= S8_RESULT;
                        else
                            state <= S9_ERROR;
                        end if;
                    elsif op_reg = "00" and div_done = '1' then
                        quotient_reg <= div_q;
                        remainder_reg <= div_r;
                        if div_by_zero = '1' or
                           not fits_division(signed(div_q), signed(div_r)) then
                            state <= S9_ERROR;
                        else
                            state <= S8_RESULT;
                        end if;
                    end if;
                when S8_RESULT => null;  -- only KEY0 reset exits
                when S9_ERROR  => null;
            end case;
        end if;
    end process;

    -- Modes: 0 InputA, 1 LIVE NUMBER, 2 FunC PROMPT, 3 LIVE OP,
    --        4 B PROMPT, 5 RESULT, 6 ERROR, 7 PROCESSING.
    with state select DISP_MODE <=
        "000" when S0_IDLE,
        "001" when S1_SHOW_A,
        "010" when S2_SELECT_OP,
        "011" when S3_SHOW_OP,
        "100" when S4_PROMPT_B,
        "001" when S5_SHOW_B,
        "111" when S6_START_CALC,
        "111" when S7_WAIT_CALC,
        "101" when S8_RESULT,
        "110" when S9_ERROR;

    DISP_VALUE <= std_logic_vector(resize(signed(SW), 20))
                  when state = S1_SHOW_A or state = S5_SHOW_B else result_reg;
    DISP_OP <= SW(1 downto 0) when state = S3_SHOW_OP else op_reg;
    DISP_Q <= quotient_reg;
    DISP_R <= remainder_reg;
    DONE <= '1' when state = S8_RESULT or state = S9_ERROR else '0';
    with state select DEBUG_STATE <=
        "0000" when S0_IDLE, "0001" when S1_SHOW_A,
        "0010" when S2_SELECT_OP, "0011" when S3_SHOW_OP,
        "0100" when S4_PROMPT_B, "0101" when S5_SHOW_B,
        "0110" when S6_START_CALC, "0111" when S7_WAIT_CALC,
        "1000" when S8_RESULT, "1001" when S9_ERROR;
end architecture;
