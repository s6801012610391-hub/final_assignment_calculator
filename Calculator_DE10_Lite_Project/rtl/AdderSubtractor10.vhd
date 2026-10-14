library ieee;
use ieee.std_logic_1164.all;

entity AdderSubtractor10 is
    port (
        A : in  std_logic_vector(9 downto 0);
        B : in  std_logic_vector(9 downto 0);
        M : in  std_logic;
        S : out std_logic_vector(10 downto 0);
        V : out std_logic
    );
end AdderSubtractor10;

architecture Structural of AdderSubtractor10 is
    signal A_ext : std_logic_vector(10 downto 0);
    signal B_ext : std_logic_vector(10 downto 0);
    signal B_mod : std_logic_vector(10 downto 0);
    signal Carry : std_logic_vector(11 downto 0);
begin
    -- Sign extension
    A_ext <= A(9) & A;
    B_ext <= B(9) & B;
    -- Initial carry
    Carry(0) <= M;
    -- XOR gates for addition/subtraction
    GEN_XOR : for i in 0 to 10 generate
    begin
        B_mod(i) <= B_ext(i) xor M;
    end generate GEN_XOR;
    -- Ripple Carry Full Adders
    GEN_FA : for i in 0 to 10 generate
    begin
        FA : entity work.FullAdder
            port map (
                X => A_ext(i),
                Y => B_mod(i),
                Z => Carry(i),
                S => S(i),
                C => Carry(i + 1)
            );
    end generate GEN_FA;
    -- Signed 10-bit overflow
    V <= Carry(9) xor Carry(10);
end Structural;
