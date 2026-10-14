library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_display is end entity;
architecture test of tb_display is
    signal mode : std_logic_vector(2 downto 0) := "000";
    signal val : std_logic_vector(19 downto 0) := (others => '0');
    signal op : std_logic_vector(1 downto 0) := "11";
    signal q, r : std_logic_vector(10 downto 0) := (others => '0');
    signal h0,h1,h2,h3,h4,h5 : std_logic_vector(7 downto 0);
begin
    DUT : entity work.Display6
        port map(MODE => mode, VALUE => val, OP => op, Q => q, R => r,
                 HEX0 => h0, HEX1 => h1, HEX2 => h2, HEX3 => h3,
                 HEX4 => h4, HEX5 => h5);
    process
    begin
        wait for 2 ns;
        assert h5 /= x"FF" and h0 /= x"FF" report "SELECT not displayed" severity failure;
        mode <= "001"; val <= std_logic_vector(to_signed(-23,20));
        wait for 2 ns;
        assert h5 = x"BF" report "Negative sign incorrect" severity failure;
        assert h0 = x"B0" and h1 = x"A4" report "-23 digits wrong" severity failure;
        mode <= "101"; op <= "11"; val <= std_logic_vector(to_signed(20,20));
        wait for 2 ns;
        assert h0 = x"C0" and h1 = x"A4" report "20 digits wrong" severity failure;
        mode <= "101"; op <= "00";
        q <= std_logic_vector(to_signed(6,11));
        r <= std_logic_vector(to_signed(1,11));
        wait for 2 ns;
        assert h0 = x"F9" and h1 = x"C0" and h3 = x"82" and h4 = x"C0"
            report "Division format wrong" severity failure;
        mode <= "110"; wait for 2 ns;
        assert h0 = x"8E" and h5 = x"8E" report "FFFFFF error wrong" severity failure;
        report "PASS: display decoder" severity note;
        wait;
    end process;
end architecture;
