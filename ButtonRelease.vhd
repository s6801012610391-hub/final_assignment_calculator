-- Synchronizer + debounce + one-clock pulse on each completed press/release.
library ieee;
use ieee.std_logic_1164.all;

entity ButtonRelease is
    generic (DEBOUNCE_CYCLES : positive := 1000000);  -- 20 ms @ 50 MHz
    port (
        CLK : in std_logic;
        RST_N : in std_logic;
        KEY_N : in std_logic;      -- physical pushbutton, 0 = pressed
        RELEASE_PULSE : out std_logic
    );
end entity;

architecture rtl of ButtonRelease is
    signal sync1, sync2 : std_logic := '1';
    signal stable_key : std_logic := '1';
    signal counter : natural range 0 to DEBOUNCE_CYCLES - 1 := 0;
    signal seen_press : std_logic := '0';
    signal pulse : std_logic := '0';
begin
    process(CLK, RST_N)
    begin
        if RST_N = '0' then
            sync1 <= '1'; sync2 <= '1';
            stable_key <= '1';
            counter <= 0;
            seen_press <= '0';
            pulse <= '0';
        elsif rising_edge(CLK) then
            sync1 <= KEY_N;
            sync2 <= sync1;
            pulse <= '0';
            if sync2 = stable_key then
                counter <= 0;
            elsif counter = DEBOUNCE_CYCLES - 1 then
                stable_key <= sync2;
                counter <= 0;
                if sync2 = '0' then
                    seen_press <= '1';
                elsif seen_press = '1' then
                    seen_press <= '0';
                    pulse <= '1';
                end if;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    RELEASE_PULSE <= pulse;
end architecture;
