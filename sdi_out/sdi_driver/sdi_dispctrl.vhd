----------------------------------------------------------------------------------
-- Create Date: 9:35 2022/10/9
--
-- Engineer: lijb
--
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sdi_dispctrl is
generic(
    SIM                         : std_logic:= '0'
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    time_ms_en                  : in  std_logic;

    source_vsync                : in  std_logic;--sysclk domain
    source_stable               : in  std_logic;--sysclk domain
    work_status                 : out std_logic_vector(1 downto 0);--sysclk domain
    
    odck_ref                    : in  std_logic;
    sink_vsync                  : in  std_logic;--odck domain
    
    nRST_odck_out               : out std_logic ;
    port_disable                : in  std_logic;
    format_reset_sys            : in  std_logic;--sysclk domain
    disp_en                     : out std_logic --odck domain
);
end entity;

architecture behav of sdi_dispctrl is

constant VSYNC_MONITOR_EN       : std_logic:= '1';
constant DELAY                  : integer:= 7;
constant PENUM                  : integer:= 10;--PENUM means "permissible error number".

component vsync_monitor is
generic(
    DELAY                       : integer:= 5;
    PENUM                       : integer:= 10      --PENUM means "permissible error number".
);
port(
    nRST                        : in  std_logic;
    refclk                      : in  std_logic;
    monitor_en                  : in  std_logic;
    source_vsync_neg            : in  std_logic;--1 pulse only in refclk
    sink_vsync_neg              : in  std_logic;--1 pulse only in refclk

    vsync_lost_odck             : out std_logic;
    not_pass                    : out std_logic
);
end component;
signal monitor_en               : std_logic;
signal vsync_lost_odck          : std_logic;
signal not_pass                 : std_logic;

signal source_vsync_delay       : std_logic_vector(1 downto 0):=(others=>'0');
signal source_vsync_delay32       : std_logic_vector(1 downto 0):=(others=>'0');
signal source_vsync_neg         : std_logic;

signal sink_vsync_d1            : std_logic;
signal sink_vsync_pos_odck      : std_logic;

signal source_vsync_neg_hold_cnt: std_logic_vector(4 downto 0);
signal source_vsync_leave       : std_logic;
signal source_vsync_leave_cross : std_logic_vector(1 downto 0):=(others=>'0');
signal source_vsync_leave_odck  : std_logic_vector(1 downto 0):=(others=>'0');
signal source_vsync_neg_odck    : std_logic :='0';

constant CNT_W  : integer := 10;
signal restart_mscnt            : std_logic_vector(CNT_W downto 0):=(others=>'0');
signal restart_enable           : std_logic:= '0';
signal restart_enable_cross     : std_logic_vector(2 downto 0);
signal disp_launch              : std_logic:= '0';
signal rst_high                 : std_logic;

signal not_pass_delay           : std_logic_vector(2 downto 0);
signal not_pass_hold            : std_logic;
signal not_pass_cross           : std_logic_vector(1 downto 0):=(others=>'0');
signal not_pass_sys32           : std_logic_vector(1 downto 0):=(others=>'0');
signal not_pass_sys             : std_logic;
signal sync_time_cnt            : std_logic_vector(13 downto 0);
signal serdes_sync_dvi          : std_logic;

component PCS5GE_ff_synchronizer_rst  
port  (
    clk                         : in std_logic ;
    rst                         : in std_logic ;
    data_in                     : in std_logic ;
    data_out                    :out std_logic 
);
end component ;
signal  check_enable_odck       : std_logic;
signal  nRST_new_odck           : std_logic;


attribute ASYNC_REG         : string;
attribute shreg_extract     : string;
attribute ASYNC_REG     of source_vsync_delay         : signal is "TRUE";
attribute shreg_extract of source_vsync_delay         : signal is "no";
attribute ASYNC_REG     of source_vsync_leave_cross         : signal is "TRUE";
attribute shreg_extract of source_vsync_leave_cross         : signal is "no";
attribute ASYNC_REG     of restart_enable_cross         : signal is "TRUE";
attribute shreg_extract of restart_enable_cross         : signal is "no";
attribute ASYNC_REG     of not_pass_cross               : signal is "TRUE";
attribute shreg_extract of not_pass_cross               : signal is "no";

begin


vsync_monitor_inst: vsync_monitor
generic map(
    DELAY                       => DELAY,
    PENUM                       => PENUM
)
port map(
    -- nRST                        => nRST                 ,
    nRST                        => nRST_new_odck        ,
    refclk                      => odck_ref             ,
    monitor_en                  => monitor_en           ,
    source_vsync_neg            => source_vsync_neg_odck,
    sink_vsync_neg              => sink_vsync_pos_odck  ,

    vsync_lost_odck             => vsync_lost_odck      ,
    not_pass                    => not_pass
);


process(nRST,sysclk)
begin
    if nRST = '0' then
        source_vsync_delay <= (others => '0');
        source_vsync_delay32 <= (others => '0');
        source_vsync_neg <= '0';
        source_vsync_neg_hold_cnt <= (others => '0');
        source_vsync_leave <= '0';
    elsif rising_edge(sysclk) then
        source_vsync_delay  <= source_vsync_delay(0 downto 0)&source_vsync;
        source_vsync_delay32 <= source_vsync_delay32(0 downto 0)&source_vsync_delay(1);
        if source_vsync_delay32 = "10" then source_vsync_neg <= '1';
        else                                          source_vsync_neg <= '0';
        end if;
        
        if source_vsync_neg = '1' then
            source_vsync_neg_hold_cnt <= (others => '1');
        else
            if source_vsync_neg_hold_cnt(4) = '1' then
                source_vsync_neg_hold_cnt <= source_vsync_neg_hold_cnt - '1';
            end if;
        end if;
        source_vsync_leave <= source_vsync_neg_hold_cnt(4);
    end if;
end process;


process(nRST_new_odck,odck_ref)
begin
    if nRST_new_odck = '0' then
        source_vsync_leave_cross <= (others => '0');
        source_vsync_neg_odck <= '0';

        sink_vsync_d1 <= '0';
        sink_vsync_pos_odck <= '0';
    elsif rising_edge(odck_ref) then
        source_vsync_leave_cross <= source_vsync_leave_cross(0 downto 0)&source_vsync_leave;
        source_vsync_leave_odck <= source_vsync_leave_odck(0 downto 0)&source_vsync_leave_cross(1);
        if source_vsync_leave_odck = "10" then
            source_vsync_neg_odck <= '1';
        else
            source_vsync_neg_odck <= '0';
        end if;

        sink_vsync_d1 <= sink_vsync  ;
        if sink_vsync_d1 = '0' and sink_vsync = '1' then sink_vsync_pos_odck <= '1';--posedge
        else                                             sink_vsync_pos_odck <= '0';
        end if;
    end if;
end process;

process(sysclk,nRST)
begin
    if nRST = '0' then
        restart_mscnt <= (others => '0');
        restart_enable <= '0';
        rst_high       <= '1';
    elsif rising_edge(sysclk) then
        if source_stable = '0' or not_pass_sys = '1' or format_reset_sys = '1' or port_disable = '1' then
            restart_mscnt <= (others => '0');
        else
            if time_ms_en = '1' then
                if restart_mscnt(CNT_W) = '0' then
                    restart_mscnt <= restart_mscnt + '1';
                end if;
            end if;
        end if;

        restart_enable <= restart_mscnt(CNT_W);
        rst_high       <= (not restart_mscnt(CNT_W));

    end if;
end process;

rst_sync: PCS5GE_ff_synchronizer_rst  
port map(
    clk      => odck_ref            ,
    rst      => (rst_high)          ,
    data_in  => '1'                 , --release 
    data_out => check_enable_odck
);

nRST_new_odck <= check_enable_odck;
nRST_odck_out <= check_enable_odck;


process(odck_ref,nRST_new_odck)
begin
    if nRST_new_odck = '0' then
        disp_launch <= '0';
    elsif rising_edge(odck_ref) then
        restart_enable_cross <= restart_enable_cross(1 downto 0)&restart_enable;
    
        if restart_enable_cross(2) = '1' then
            if source_vsync_neg_odck = '1' then
                disp_launch <= '1';
            end if;
        else
            disp_launch <= '0';
        end if;
    end if;
end process;
disp_en <= disp_launch;
monitor_en <= disp_launch when VSYNC_MONITOR_EN = '1' else '0';

-----------------------------------------------------------------
-- ---- status control
-- process(odck_ref)
-- begin
--     if rising_edge(odck_ref) then
--         not_pass_delay <= not_pass_delay(1 downto 0)&not_pass;
--         if not_pass_delay > 0 then not_pass_hold <= '1';--max odck freq is 165 mhz.system clock freq is 125 mhz.
--         else                       not_pass_hold <= '0';
--         end if;
--     end if;
-- end process;

---- status control
process(nRST_new_odck,odck_ref)
begin
    if nRST_new_odck = '0' then 
        not_pass_hold <= '0';
        not_pass_delay <= (others=>'0');
    elsif rising_edge(odck_ref) then
        not_pass_delay <= not_pass_delay(1 downto 0)&not_pass;
        if not_pass_delay > 0 then not_pass_hold <= '1';--max odck freq is 165 mhz.system clock freq is 125 mhz.
        else                       not_pass_hold <= '0';
        end if;
    end if;
end process;


process(sysclk)
begin
    if rising_edge(sysclk) then
        not_pass_cross <= not_pass_cross(0 downto 0)&not_pass_hold; --odck to sys clock domain 
	not_pass_sys32 <= not_pass_sys32(0 downto 0)&not_pass_cross(1);
        -- if not_pass_cross32 = "01" then not_pass_sys <= '1';
        if not_pass_sys32 = "01" then not_pass_sys <= '1';
        else                                      not_pass_sys <= '0';
        end if;
    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        work_status <= (others => '0');
    elsif rising_edge(sysclk) then
        if source_stable = '0' then
            work_status <= (others => '0');
        elsif serdes_sync_dvi = '0' then
            work_status <= "01";
        else
            work_status <= "10";
        end if;
        
        if not_pass_sys = '1' then
            sync_time_cnt <= (others => '0');
        else
            if time_ms_en = '1' then
                if sync_time_cnt(13) = '0' then
                    sync_time_cnt <= sync_time_cnt + '1';
                end if;
            end if;
        end if;
        serdes_sync_dvi <= sync_time_cnt(13);
    end if;
end process;
-----------------------------------------------------------------



end behav;