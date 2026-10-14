library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Segment order is HEXn(7 downto 0) = DP, g, f, e, d, c, b, a
-- Segments are active-low (0 lights segment). DP always off.
entity Display6 is
    port (
        MODE : in std_logic_vector(2 downto 0);
        VALUE : in std_logic_vector(19 downto 0);
        OP : in std_logic_vector(1 downto 0);
        Q : in std_logic_vector(10 downto 0);
        R : in std_logic_vector(10 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of Display6 is
    type digits_t is array(0 to 5) of std_logic_vector(7 downto 0);

    function glyph(c : character) return std_logic_vector is
    begin
        case c is
            when ' ' => return x"FF"; -- blank
            when '0' => return x"C0"; -- abcdef
            when '1' => return x"F9"; -- bc
            when '2' => return x"A4"; -- abdeg
            when '3' => return x"B0"; -- abcdg
            when '4' => return x"99"; -- bcfg
            when '5' => return x"92"; -- acdfg
            when '6' => return x"82"; -- acdefg
            when '7' => return x"F8"; -- abc
            when '8' => return x"80"; -- abcdefg
            when '9' => return x"90"; -- abcdfg
            when 'A' => return x"88"; -- abcefg
            when 'b' => return x"83"; -- cdefg
            when 'C' => return x"C6"; -- adef
            when 'd' => return x"A1"; -- bcdeg
            when 'E' => return x"86"; -- adefg
            when 'F' => return x"8E"; -- aefg
            when 'G' => return x"C2"; -- acdef
            when 'H' => return x"89"; -- bcefg
            when 'I' => return x"F9"; -- bc
            when 'L' => return x"C7"; -- def
            when 'n' => return x"AB"; -- ceg
            when 'O' => return x"C0"; -- abcdef
            when 'P' => return x"8C"; -- abefg
            when 'r' => return x"AF"; -- eg
            when 'S' => return x"92"; -- acdfg
            when 't' => return x"87"; -- defg
            when 'U' => return x"C1"; -- bcdef
            when 'x' => return x"89"; -- bcefg
            when '+' => return x"89"; -- bcefg
            when '-' => return x"BF"; -- g
            when '/' => return x"AD"; -- beg
            when '=' => return x"B6"; -- adg
            when others => return x"FF";
        end case;
    end function;

    function numeric_digit(n : natural) return std_logic_vector is
    begin
        case n is
            when 0 => return glyph('0'); when 1 => return glyph('1');
            when 2 => return glyph('2'); when 3 => return glyph('3');
            when 4 => return glyph('4'); when 5 => return glyph('5');
            when 6 => return glyph('6'); when 7 => return glyph('7');
            when 8 => return glyph('8'); when 9 => return glyph('9');
            when others => return glyph(' ');
        end case;
    end function;

    function op_symbol(o : std_logic_vector(1 downto 0)) return std_logic_vector is
    begin
        case o is
            when "11" => return glyph('+');
            when "10" => return glyph('-');
            when "01" => return glyph('x');
            when others => return glyph('d'); -- approx DIV glyph
        end case;
    end function;

    -- Shift/add-3 (double dabble): 20-bit unsigned binary -> 6 decimal BCD digits.
    -- Avoids synthesis of variable hardware division by ten.
    function bcd20(n : unsigned(19 downto 0)) return std_logic_vector is
        variable b : unsigned(23 downto 0) := (others => '0');
    begin
        for bitpos in 19 downto 0 loop
            for k in 0 to 5 loop
                if b(4*k+3 downto 4*k) > 4 then
                    b(4*k+3 downto 4*k) := b(4*k+3 downto 4*k) + 3;
                end if;
            end loop;
            b := b(22 downto 0) & n(bitpos);
        end loop;
        return std_logic_vector(b);
    end function;

    function absolute20(n : signed(19 downto 0)) return unsigned is
    begin
        if n(19) = '1' then return unsigned(-n);
        else return unsigned(n);
        end if;
    end function;
begin
    process(MODE, VALUE, OP, Q, R)
        variable d : digits_t;
        variable bcdv, qbcd, rbcd : std_logic_vector(23 downto 0);
        variable show_digit : boolean;
        variable digit_val : natural range 0 to 9;
    begin
        for i in 0 to 5 loop d(i) := glyph(' '); end loop;
        case MODE is
            when "000" => -- SELECT, HEX5 .. HEX0
                d(5) := glyph('S'); d(4) := glyph('E'); d(3) := glyph('L');
                d(2) := glyph('E'); d(1) := glyph('C'); d(0) := glyph('t');

            when "001" => -- Signed live switch value
                bcdv := bcd20(absolute20(signed(VALUE)));
                if VALUE(19) = '1' then d(5) := glyph('-'); end if;
                show_digit := false;
                for i in 4 downto 0 loop
                    digit_val := to_integer(unsigned(bcdv(i*4+3 downto i*4)));
                    if digit_val /= 0 or i = 0 then show_digit := true; end if;
                    if show_digit then d(i) := numeric_digit(digit_val); end if;
                end loop;

            when "010" => -- Choose operation prompt
                d(1) := glyph('O'); d(0) := glyph('P');

            when "011" => -- SW[1:0] selects 2 display symbols
                d(1) := op_symbol(OP); d(0) := op_symbol(OP);

            when "100" => -- Prompt for input B
                d(4) := glyph('I'); d(3) := glyph('n');
                d(2) := glyph('P'); d(0) := glyph('b');

            when "101" => -- Final result
                if OP /= "00" then
                    bcdv := bcd20(absolute20(signed(VALUE)));
                    d(5) := op_symbol(OP);
                    if VALUE(19) = '1' then
                        d(4) := glyph('-');
                        show_digit := false;
                        for i in 3 downto 0 loop
                            digit_val := to_integer(unsigned(bcdv(i*4+3 downto i*4)));
                            if digit_val /= 0 or i = 0 then show_digit := true; end if;
                            if show_digit then d(i) := numeric_digit(digit_val); end if;
                        end loop;
                    else
                        show_digit := false;
                        for i in 4 downto 0 loop
                            digit_val := to_integer(unsigned(bcdv(i*4+3 downto i*4)));
                            if digit_val /= 0 or i = 0 then show_digit := true; end if;
                            if show_digit then d(i) := numeric_digit(digit_val); end if;
                        end loop;
                    end if;
                else
                    -- Divide: HEX5 signed quotient indicator, HEX4:3 = quotient,
                    -- HEX2 triple bar, HEX1:0 = remainder.
                    -- The remainder magnitude is shown. Its negative sign
                    -- is indicated by HEX1 decimal point (active-low).
                    qbcd := bcd20(absolute20(resize(signed(Q), 20)));
                    rbcd := bcd20(absolute20(resize(signed(R), 20)));
                    if Q(10) = '1' then d(5) := glyph('-');
                    else d(5) := glyph('d'); end if;
                    d(4) := numeric_digit(to_integer(unsigned(qbcd(7 downto 4))));
                    d(3) := numeric_digit(to_integer(unsigned(qbcd(3 downto 0))));
                    d(2) := glyph('=');
                    d(1) := numeric_digit(to_integer(unsigned(rbcd(7 downto 4))));
                    d(0) := numeric_digit(to_integer(unsigned(rbcd(3 downto 0))));
                    if R(10) = '1' then d(1)(7) := '0'; end if;
                end if;

            when "110" => -- unrepresentable result / divide-by-zero
                for i in 0 to 5 loop d(i) := glyph('F'); end loop;

            when others => -- processing indication
                for i in 0 to 5 loop d(i) := glyph('-'); end loop;
        end case;
        HEX0 <= d(0); HEX1 <= d(1); HEX2 <= d(2);
        HEX3 <= d(3); HEX4 <= d(4); HEX5 <= d(5);
    end process;
end architecture;
