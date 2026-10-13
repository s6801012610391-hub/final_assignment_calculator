library ieee;
use ieee.std_logic_1164.all;

entity Multiplier10 is
    port (
        CLK   : in  std_logic;
        RST_N : in  std_logic;
        START : in  std_logic;
        A     : in  std_logic_vector(9 downto 0);
        B     : in  std_logic_vector(9 downto 0);
        R     : out std_logic_vector(19 downto 0);
        DONE  : out std_logic
    );
end Multiplier10;

architecture Structural of Multiplier10 is

    type State_Type is (S_IDLE, S_CALC, S_SIGN, S_DONE);
    signal State : State_Type := S_IDLE;

    signal A_mag, B_mag : std_logic_vector(9 downto 0);

    signal Data_A       : std_logic_vector(19 downto 0)
                          := (others => '0');
    signal Data_B       : std_logic_vector(9 downto 0)
                          := (others => '0');
    signal Data_Product : std_logic_vector(19 downto 0)
                          := (others => '0');

    signal Result_Sign : std_logic := '0';
    signal Bit_Counter : integer range 0 to 9 := 0;

    signal Add_X, Add_Y, Add_S :
        std_logic_vector(19 downto 0);
    signal Carry : std_logic_vector(20 downto 0);

begin

    MAG_A : entity work.Magnitude10
        port map (X => A, Magnitude => A_mag);

    MAG_B : entity work.Magnitude10
        port map (X => B, Magnitude => B_mag);

    -- Reuse the adder for multiplication and sign correction
    Add_X <= not Data_Product
             when (State = S_SIGN and Result_Sign = '1')
             else Data_Product;

    Add_Y <= (others => '0')
             when State = S_SIGN else Data_A;

    Carry(0) <= '1'
                when (State = S_SIGN and Result_Sign = '1')
                else '0';

    -- 20-bit Ripple Carry Adder
    GEN_FA : for i in 0 to 19 generate
    begin
        FA : entity work.FullAdder
            port map (
                X => Add_X(i),
                Y => Add_Y(i),
                Z => Carry(i),
                S => Add_S(i),
                C => Carry(i + 1)
            );
    end generate GEN_FA;

    process (CLK, RST_N)
    begin
        if RST_N = '0' then
            State        <= S_IDLE;
            Data_A       <= (others => '0');
            Data_B       <= (others => '0');
            Data_Product <= (others => '0');
            Result_Sign  <= '0';
            Bit_Counter  <= 0;

        elsif rising_edge(CLK) then
            case State is

                when S_IDLE =>
                    if START = '1' then
                        Data_A <= "0000000000" & A_mag;
                        Data_B <= B_mag;
                        Data_Product <= (others => '0');
                        Result_Sign <= A(9) xor B(9);
                        Bit_Counter <= 0;
                        State <= S_CALC;
                    end if;

                when S_CALC =>
                    -- Add only when multiplier LSB is 1
                    if Data_B(0) = '1' then
                        Data_Product <= Add_S;
                    end if;

                    -- Shift registers
                    Data_A <= Data_A(18 downto 0) & '0';
                    Data_B <= '0' & Data_B(9 downto 1);

                    if Bit_Counter = 9 then
                        State <= S_SIGN;
                    else
                        Bit_Counter <= Bit_Counter + 1;
                    end if;

                when S_SIGN =>
                    -- Restore negative sign if necessary
                    if Result_Sign = '1' then
                        Data_Product <= Add_S;
                    end if;
                    State <= S_DONE;

                when S_DONE =>
                    null;

            end case;
        end if;
    end process;

    R <= Data_Product;
    DONE <= '1' when State = S_DONE else '0';

end Structural;
