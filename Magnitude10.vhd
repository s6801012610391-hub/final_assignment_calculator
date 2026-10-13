library ieee;
use ieee.std_logic_1164.all;

entity Magnitude10 is
    port (
        X         : in  std_logic_vector(9 downto 0);
        Magnitude : out std_logic_vector(9 downto 0)
    );
end Magnitude10;

architecture Structural of Magnitude10 is
    signal X_mod : std_logic_vector(9 downto 0);
    signal Carry : std_logic_vector(10 downto 0);
begin
    Carry(0) <= X(9);

    GEN_MAG : for i in 0 to 9 generate
    begin
        X_mod(i) <= X(i) xor X(9);

        FA : entity work.FullAdder
            port map (
                X => X_mod(i),
                Y => '0',
                Z => Carry(i),
                S => Magnitude(i),
                C => Carry(i + 1)
            );
    end generate GEN_MAG;
end Structural;
