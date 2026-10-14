library ieee;
use ieee.std_logic_1164.all;

entity FullAdder is
    port (
        X : in  std_logic;
        Y : in  std_logic;
        Z : in  std_logic;
        S : out std_logic;
        C : out std_logic
    );
end FullAdder;

architecture Dataflow of FullAdder is
begin
    S <= X xor Y xor Z;
    C <= (X and Y) or (X and Z) or (Y and Z);
end Dataflow;
