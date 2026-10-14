library ieee;
use ieee.std_logic_1164.all;
entity tb_button_release is end entity;
architecture test of tb_button_release is
    signal clk : std_logic := '0';
    signal reset_n, key_n : std_logic := '1';
    signal event_pulse : std_logic;
    signal total_events : integer := 0;
begin
    clk <= not clk after 5 ns;
    DUT : entity work.ButtonRelease
        generic map (DEBOUNCE_CYCLES => 3)
        port map (CLK => clk, RST_N => reset_n,
                  KEY_N => key_n, RELEASE_PULSE => event_pulse);
    process(clk)
    begin
        if rising_edge(clk) then
            if event_pulse = '1' then total_events <= total_events + 1; end if;
        end if;
    end process;
    process
    begin
        reset_n <= '0'; wait for 20 ns;
        reset_n <= '1'; wait for 30 ns;
        key_n <= '0'; wait for 100 ns; -- press and HOLD; no state changes
        assert total_events = 0 report "Press generated event (should be release)" severity failure;
        key_n <= '1'; wait for 100 ns;
        assert total_events = 1 report "Expected one event after release" severity failure;
        key_n <= '0'; wait for 100 ns;
        key_n <= '1'; wait for 100 ns;
        assert total_events = 2 report "Expected exactly two events" severity failure;
        report "PASS: button press-release one-shot" severity note;
        wait;
    end process;
end architecture;
