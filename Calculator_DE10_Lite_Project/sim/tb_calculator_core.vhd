-- Run with GHDL, or set tb_calculator_core as ModelSim simulation top.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_calculator_core is
end entity;

architecture test of tb_calculator_core is
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal pulse : std_logic := '0';
    signal sw : std_logic_vector(9 downto 0) := (others => '0');
    signal mode : std_logic_vector(2 downto 0);
    signal value : std_logic_vector(19 downto 0);
    signal operation : std_logic_vector(1 downto 0);
    signal q, r : std_logic_vector(10 downto 0);
    signal done : std_logic;
    signal state_code : std_logic_vector(3 downto 0);
begin
    clk <= not clk after 5 ns;
    UUT : entity work.Calculator_Core
        port map (CLK => clk, RST_N => rst_n, STEP_PULSE => pulse,
                  SW => sw, DISP_MODE => mode, DISP_VALUE => value,
                  DISP_OP => operation, DISP_Q => q, DISP_R => r,
                  DONE => done, DEBUG_STATE => state_code);

    process
        procedure tick is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;
        procedure step is
        begin
            pulse <= '1'; tick;
            pulse <= '0'; tick;
        end procedure;
        procedure reset_core is
        begin
            rst_n <= '0'; pulse <= '0'; sw <= (others => '0');
            wait for 2 ns;
            assert done = '0' and state_code = "0000" report "reset failed" severity failure;
            tick; rst_n <= '1'; tick;
        end procedure;
        procedure begin_calculation(a : integer; b : integer; op : natural) is
        begin
            -- Initial prompt -> show A -> save A -> op prompt -> show OP
            step;
            assert state_code = "0001" report "Expected SHOW_A" severity failure;
            sw <= std_logic_vector(to_signed(a, 10));
            tick; step;
            assert state_code = "0010" report "Expected SELECT_OP" severity failure;
            step;
            assert state_code = "0011" report "Expected SHOW_OP" severity failure;
            sw <= std_logic_vector(to_unsigned(op, 10));
            tick; step;
            assert state_code = "0100" report "Expected PROMPT_B" severity failure;
            step;
            assert state_code = "0101" report "Expected SHOW_B" severity failure;
            sw <= std_logic_vector(to_signed(b, 10));
            tick; step;
            assert state_code = "0110" or state_code = "0111" or done = '1'
                report "Expected calculation start" severity failure;
            -- Wait for sequential MUL/DIV if necessary
            for i in 0 to 100 loop
                exit when done = '1';
                tick;
            end loop;
            assert done = '1' report "Calculation timed out" severity failure;
        end procedure;
        procedure expect_number(expected : integer) is
        begin
            assert mode = "101" report "Expected result, got ERROR" severity failure;
            assert to_integer(signed(value)) = expected
                report "Incorrect arithmetic result" severity failure;
            step;  -- pressing KEY1 after DONE must NOT restart the FSM
            assert state_code = "1000" report "Result must be held until reset" severity failure;
        end procedure;
        procedure expect_division(expected_q : integer; expected_r : integer) is
        begin
            assert mode = "101" report "Expected division result" severity failure;
            assert to_integer(signed(q)) = expected_q report "Wrong quotient" severity failure;
            assert to_integer(signed(r)) = expected_r report "Wrong remainder" severity failure;
        end procedure;
        procedure expect_error is
        begin
            assert mode = "110" and state_code = "1001"
                report "Expected FFFFFF / ERROR" severity failure;
            step;
            assert state_code = "1001" report "ERROR must remain latched" severity failure;
        end procedure;
    begin
        reset_core;
        begin_calculation(12, 8, 3); expect_number(20);
        reset_core;
        begin_calculation(3, 9, 2); expect_number(-6);
        reset_core;
        begin_calculation(-17, 7, 1); expect_number(-119);
        reset_core;
        begin_calculation(25, 4, 0); expect_division(6, 1);
        reset_core;
        begin_calculation(7, -3, 0); expect_division(-2, 1);
        reset_core;
        begin_calculation(-7, 3, 0); expect_division(-2, -1);
        reset_core;
        begin_calculation(-7, -3, 0); expect_division(2, -1);
        reset_core;
        begin_calculation(0, 3, 0); expect_division(0, 0);
        reset_core;
        begin_calculation(10, 0, 0); expect_error;
        reset_core;
        begin_calculation(511, 511, 1); expect_error;
        reset_core;
        begin_calculation(511, 1, 0); expect_error;
        report "PASS: tb_calculator_core all cases completed" severity note;
        wait;
    end process;
end architecture;
