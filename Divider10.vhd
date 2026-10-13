library ieee;
use ieee.std_logic_1164.all;

entity Divider10 is
    port (
        CLK         : in  std_logic;
        RST_N       : in  std_logic;
        START       : in  std_logic;
        A           : in  std_logic_vector(9 downto 0);
        B           : in  std_logic_vector(9 downto 0);
        QUOTIENT    : out std_logic_vector(10 downto 0);
        REMAINDER   : out std_logic_vector(10 downto 0);
        DONE        : out std_logic;
        DIV_BY_ZERO : out std_logic
    );
end Divider10;

architecture Structural of Divider10 is
    type State_Type is (
        S_IDLE, S_SUB, S_TEST, S_RESTORE,
        S_SIGN_Q, S_SIGN_R, S_DONE
    );

    signal State : State_Type := S_IDLE;
    signal A_mag, B_mag : std_logic_vector(9 downto 0);

    -- shift-right-divisor algorithm.
    signal Data_Divisor   : std_logic_vector(19 downto 0) := (others => '0');
    signal Data_Remainder : std_logic_vector(19 downto 0) := (others => '0');
    signal Data_Quotient  : std_logic_vector(9 downto 0)  := (others => '0');

    signal Sign_Q, Sign_R : std_logic := '0';
    signal Bit_Counter : integer range 0 to 9 := 0;

    signal Q_Ext : std_logic_vector(19 downto 0);
    signal Add_X, Add_Y, Add_S : std_logic_vector(19 downto 0);
    signal Carry : std_logic_vector(20 downto 0);

    signal Quotient_Reg, Remainder_Reg : std_logic_vector(10 downto 0)
        := (others => '0');
    signal Zero_Flag : std_logic := '0';
begin

    MAG_A : entity work.Magnitude10
        port map (X => A, Magnitude => A_mag);
    MAG_B : entity work.Magnitude10
        port map (X => B, Magnitude => B_mag);

    -- Extend the unsigned quotient magnitude to 20 bits.
    Q_Ext <= "0000000000" & Data_Quotient;

    Add_X <= not Q_Ext when (State = S_SIGN_Q and Sign_Q = '1') else
             Q_Ext     when (State = S_SIGN_Q) else
             not Data_Remainder
                       when (State = S_SIGN_R and Sign_R = '1') else
             Data_Remainder;

    Add_Y <= not Data_Divisor when (State = S_SUB) else
             Data_Divisor     when (State = S_RESTORE) else
             (others => '0');

    Carry(0) <= '1' when (State = S_SUB) or
                         (State = S_SIGN_Q and Sign_Q = '1') or
                         (State = S_SIGN_R and Sign_R = '1')
                else '0';

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
            State          <= S_IDLE;
            Data_Divisor   <= (others => '0');
            Data_Remainder <= (others => '0');
            Data_Quotient  <= (others => '0');
            Sign_Q         <= '0';
            Sign_R         <= '0';
            Bit_Counter    <= 0;
            Quotient_Reg   <= (others => '0');
            Remainder_Reg  <= (others => '0');
            Zero_Flag      <= '0';

        elsif rising_edge(CLK) then
            case State is
                when S_IDLE =>
                    if START = '1' then
                        Sign_Q <= A(9) xor B(9);
                        Sign_R <= A(9);
                        Zero_Flag <= '0';
                        Quotient_Reg <= (others => '0');
                        Remainder_Reg <= (others => '0');
                        Data_Remainder <= "0000000000" & A_mag;
                        -- First trial divisor is |B| shifted left 9 bits.
                        Data_Divisor <= '0' & B_mag & "000000000";
                        Data_Quotient <= (others => '0');
                        Bit_Counter <= 0;

                        if B_mag = "0000000000" then
                            Zero_Flag <= '1';
                            State <= S_DONE;
                        else
                            State <= S_SUB;
                        end if;
                    end if;

                when S_SUB =>
                    -- Subtract via complement and Carry(0)=1.
                    Data_Remainder <= Add_S;
                    State <= S_TEST;

                when S_TEST =>
                    if Data_Remainder(19) = '1' then
                        -- Trial remainder is negative: restore it next.
                        State <= S_RESTORE;
                    else
                        -- Trial remainder >= 0: quotient bit is 1.
                        Data_Quotient <= Data_Quotient(8 downto 0) & '1';
                        Data_Divisor <= '0' & Data_Divisor(19 downto 1);
                        if Bit_Counter = 9 then
                            State <= S_SIGN_Q;
                        else
                            Bit_Counter <= Bit_Counter + 1;
                            State <= S_SUB;
                        end if;
                    end if;

                when S_RESTORE =>
                    -- Restore by adding the divisor back.
                    Data_Remainder <= Add_S;
                    Data_Quotient <= Data_Quotient(8 downto 0) & '0';
                    Data_Divisor <= '0' & Data_Divisor(19 downto 1);
                    if Bit_Counter = 9 then
                        State <= S_SIGN_Q;
                    else
                        Bit_Counter <= Bit_Counter + 1;
                        State <= S_SUB;
                    end if;

                when S_SIGN_Q =>
                    -- 11-bit signed quotient also represents +512.
                    Quotient_Reg <= Add_S(10 downto 0);
                    State <= S_SIGN_R;

                when S_SIGN_R =>
                    -- Truncation-toward-zero remainder has sign of A.
                    Remainder_Reg <= Add_S(10 downto 0);
                    State <= S_DONE;

                when S_DONE =>
                    null; -- Hold result until asynchronous reset.
            end case;
        end if;
    end process;

    QUOTIENT <= Quotient_Reg;
    REMAINDER <= Remainder_Reg;
    DIV_BY_ZERO <= Zero_Flag;
    DONE <= '1' when State = S_DONE else '0';
end Structural;
