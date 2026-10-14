-- Board top-level for Terasic DE10-Lite MAX10 10M50DAF484C7G
library ieee;
use ieee.std_logic_1164.all;

entity Calculator_DE10_Lite is
    generic (DEBOUNCE_CYCLES : positive := 1000000);
    port (
        CLOCK_50 : in std_logic;
        KEY : in std_logic_vector(1 downto 0);
        SW : in std_logic_vector(9 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of Calculator_DE10_Lite is
    signal step : std_logic;
    signal mode : std_logic_vector(2 downto 0);
    signal value : std_logic_vector(19 downto 0);
    signal operation : std_logic_vector(1 downto 0);
    signal quotient, remainder : std_logic_vector(10 downto 0);
    signal done : std_logic;
    signal unused_debug : std_logic_vector(3 downto 0);
begin
    BUTTON : entity work.ButtonRelease
        generic map (DEBOUNCE_CYCLES => DEBOUNCE_CYCLES)
        port map (CLK => CLOCK_50, RST_N => KEY(0), KEY_N => KEY(1),
                  RELEASE_PULSE => step);

    CONTROL : entity work.Calculator_Core
        port map (CLK => CLOCK_50, RST_N => KEY(0), STEP_PULSE => step,
                  SW => SW, DISP_MODE => mode, DISP_VALUE => value,
                  DISP_OP => operation, DISP_Q => quotient, DISP_R => remainder,
                  DONE => done, DEBUG_STATE => unused_debug);

    DISPLAY : entity work.Display6
        port map (MODE => mode, VALUE => value, OP => operation,
                  Q => quotient, R => remainder,
                  HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2,
                  HEX3 => HEX3, HEX4 => HEX4, HEX5 => HEX5);

    LEDR <= "000000000" & done;
end architecture;
