--#######################################################################
--2025/02/25 maojin
--2025/08/8 LS
--sdi_makeframe
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity sdi_makeframe is
generic(
    NUM_STREAMS                         : integer:= 4

);
port(
    sdi_clk                             : in  std_logic;
    sdi_nRST                            : in  std_logic;--vsync

    --from sdi_ip
    tx_enable                           : in  std_logic;   
    
    sdi_tx_std                          : in  std_logic_vector(2 downto 0); 
    sdi_tx_trs                          : out std_logic;
    sdi_tx_ln                           : out std_logic_vector(NUM_STREAMS*11-1 downto 0);   
    sdi_tx_ln_b                         : out std_logic_vector(NUM_STREAMS*11-1 downto 0);       
    sdi_tx_data                         : out std_logic_vector(NUM_STREAMS*20-1 downto 0);
    sdi_tx_vld                          : out std_logic;

    --from ctrl
    vidout_din_en                       : out std_logic;---to req data in
    vidout_data                         : in  std_logic_vector(NUM_STREAMS*20-1 downto 0);--YCBCR
    vidout_data_vld                     : in  std_logic;
    viout_anc                           : out std_logic;--Just to check the ANC signal.
    vidout_word_cnt                     : out std_logic_vector(12 downto 0);
    vidout_vs                           : in  std_logic;
    
    words_per_active_line               : in  std_logic_vector(12 downto 0); --Total words in active part of line  pixel
    words_per_total_line                : in  std_logic_vector(12 downto 0); --Total words per line
    lines_per_frame                     : in  std_logic_vector(10 downto 0); --Total lines per frame
    line_hanc_word                      : in  std_logic_vector(11 downto 0); --hanc words per line
    sd_hanc_y_word                      : in  std_logic_vector(7 downto 0);  --sd hanc y words per line
    --F V
    f_rise_line                         : in  std_logic_vector(10 downto 0); --defualt is 0
    f_fall_line                         : in  std_logic_vector(10 downto 0); --defualt is 0
    v_fall_line_1                       : in  std_logic_vector(10 downto 0); -- Line number when V falls for first field
    v_rise_line_1                       : in  std_logic_vector(10 downto 0); -- Line number when V rises for first field
    v_fall_line_2                       : in  std_logic_vector(10 downto 0); -- defualt is 0
    v_rise_line_2                       : in  std_logic_vector(10 downto 0); -- defualt is 0

    vpid_line_f0                        : in  std_logic_vector(10 downto 0); --how much line to insert vpid 
    vpid_line_f1                        : in  std_logic_vector(10 downto 0);

    vpid_byte1                          : in  std_logic_vector(7 downto 0);
    vpid_byte2                          : in  std_logic_vector(7 downto 0);
    vpid_byte3                          : in  std_logic_vector(7 downto 0);
    vpid_byte4                          : in  std_logic_vector(7 downto 0);
    vpid_byte1_b                        : in  std_logic_vector(7 downto 0);
    vpid_byte2_b                        : in  std_logic_vector(7 downto 0);
    vpid_byte3_b                        : in  std_logic_vector(7 downto 0);
    vpid_byte4_b                        : in  std_logic_vector(7 downto 0)

);
end entity;

architecture behav of sdi_makeframe is




constant Y_BLANKING_DATA					: std_logic_vector(9 downto 0):= conv_std_logic_vector(64,10); --40h
constant C_BLANKING_DATA					: std_logic_vector(9 downto 0):= conv_std_logic_vector(512,10); --200h
constant SIGNAL_3FF					        : std_logic_vector(9 downto 0):= conv_std_logic_vector(1023,10);--3ff
constant SIGNAL_000					        : std_logic_vector(9 downto 0):= conv_std_logic_vector(0,10);--000


--state 
type state is(
	GEN_IDLE,
	GEN_EAV_1,
    GEN_EAV_2,
    GEN_EAV_3,
    GEN_EAV_4,
    GEN_HANC,
    GEN_HANC_Y,
    GEN_SAV_1,
    GEN_SAV_2,
    GEN_SAV_3,
    GEN_SAV_4,
    GEN_DATA ,
    GEN_ADF0 ,
    GEN_ADF1 ,
    GEN_ADF2 ,
    GEN_DID  ,
    GEN_SDID ,
    GEN_DC   ,
    GEN_VPID1,
    GEN_VPID2,
    GEN_VPID3,
    GEN_VPID4,
    GEN_CS   ,
    GEN_LN_CRC
);

attribute keep : boolean;


signal pstate							    : state:= GEN_IDLE;

signal F_sdi                                : std_logic;
signal V_sdi                                : std_logic;
signal H_sdi                                : std_logic;
signal anc_sdi                              : std_logic;
signal anc_sdi_r2                           : std_logic;

signal calc_xyz                             : std_logic_vector(9 downto 0);
signal FVH_sdi                              : std_logic_vector(2 downto 0);

signal line_cnt                             : std_logic_vector(10 downto 0);
signal word_cnt                             : std_logic_vector(12 downto 0);

signal data_out                             : std_logic_vector(NUM_STREAMS*20-1 downto 0);
signal data_out_vld                         : std_logic;

signal line_now                             : std_logic_vector(10 downto 0);    
signal lineb_now                            : std_logic_vector(10 downto 0); 

signal init_line_hanc_word                  : std_logic_vector(11 downto 0);
signal init_sd_hanc_y_word                  : std_logic_vector(7 downto 0);

signal vpid_did                             : std_logic_vector(9 downto 0) := conv_std_logic_vector(577,10);--x"241"
signal vpid_sdid                            : std_logic_vector(9 downto 0) := conv_std_logic_vector(257,10);--x"101"
signal vpid_dc                              : std_logic_vector(9 downto 0) := conv_std_logic_vector(260,10);--x"104"
signal vpid_byte1_parity                    : std_logic;
signal vpid_byte2_parity                    : std_logic;
signal vpid_byte3_parity                    : std_logic;
signal vpid_byte4_parity                    : std_logic;

signal insert_cs                            : std_logic;
signal out_trs                              : std_logic;

signal insert_chcksumen                     : std_logic;
signal checksum_en1                         : std_logic;
signal checksum_en2                         : std_logic;

signal anc_parity_msb                       : std_logic;
signal anc_parity_lsb                       : std_logic;
signal anc_checksum_msb                     : std_logic_vector(8 downto 0);
signal anc_checksum_lsb                     : std_logic_vector(8 downto 0);

---dealy
signal sdi_tx_enable_r1                     : std_logic;

signal F_sdi_r1                             : std_logic;
signal V_sdi_r1                             : std_logic;
signal H_sdi_r1                             : std_logic;
signal anc_sdi_r1                           : std_logic;

signal line_now_r1                          : std_logic_vector(10 downto 0);    
signal lineb_now_r1                         : std_logic_vector(10 downto 0); 

signal data_out_r1                          : std_logic_vector(NUM_STREAMS*20-1 downto 0);
signal data_out_r2                          : std_logic_vector(NUM_STREAMS*20-1 downto 0);
signal data_out_r3                          : std_logic_vector(NUM_STREAMS*20-1 downto 0);
signal data_out_r4                          : std_logic_vector(NUM_STREAMS*20-1 downto 0);

signal data_out_vld_r1                      : std_logic;
signal data_out_vld_r2                      : std_logic;
signal data_out_vld_r3                      : std_logic;

signal insert_cs_r1                         : std_logic;
signal insert_cs_r2                         : std_logic;

signal out_trs_r1                           : std_logic;
signal out_trs_r2                           : std_logic;
signal out_trs_r3                           : std_logic;
signal out_trs_r4                           : std_logic;

signal checksum_en1_r1                      : std_logic;
signal checksum_en2_r1                      : std_logic;


attribute keep of pstate       : signal is true;
attribute keep of F_sdi        : signal is true;
attribute keep of V_sdi        : signal is true;
attribute keep of H_sdi        : signal is true;
attribute keep of line_cnt     : signal is true;

begin


--xyz
FVH_sdi <= F_sdi & V_sdi & H_sdi;

process(sdi_clk,sdi_nRST)
begin
    if sdi_nRST = '0' then
        calc_xyz <= "10"&X"00";
	elsif rising_edge(sdi_clk) then
        case FVH_sdi is
            when "000" => calc_xyz <= "10"&X"00";--10'h200
            when "001" => calc_xyz <= "10"&X"74";--10'h274
            when "010" => calc_xyz <= "10"&X"ac";--10'h2ac
            when "011" => calc_xyz <= "10"&X"d8";--10'h2d8
            when "100" => calc_xyz <= "11"&X"1c";--10'h31c
            when "101" => calc_xyz <= "11"&X"68";--10'h368
            when "110" => calc_xyz <= "11"&X"b0";--10'h3b0
            when "111" => calc_xyz <= "11"&X"c4";--10'h3c4
            when others => calc_xyz <= "00"&X"00";
        end case;
	end if;
end process;

--hanc_word lock
process(sdi_clk,sdi_nRST)
begin
    if sdi_nRST = '0' then
        init_line_hanc_word <= (others => '0');
        init_sd_hanc_y_word <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if(line_now = vpid_line_f0 or line_now = vpid_line_f1)then
            init_line_hanc_word <= line_hanc_word - 11;
            init_sd_hanc_y_word <= sd_hanc_y_word - 11;
        else
            init_line_hanc_word <= line_hanc_word;
            init_sd_hanc_y_word <= sd_hanc_y_word;
        end if;
    end if;
end process;

--check
vpid_byte1_parity <= vpid_byte1(7) xor vpid_byte1(6) xor vpid_byte1(5) xor vpid_byte1(4)  xor vpid_byte1(3) xor vpid_byte1(2) xor vpid_byte1(1) xor vpid_byte1(0);
vpid_byte2_parity <= vpid_byte2(7) xor vpid_byte2(6) xor vpid_byte2(5) xor vpid_byte2(4)  xor vpid_byte2(3) xor vpid_byte2(2) xor vpid_byte2(1) xor vpid_byte2(0);
vpid_byte3_parity <= vpid_byte3(7) xor vpid_byte3(6) xor vpid_byte3(5) xor vpid_byte3(4)  xor vpid_byte3(3) xor vpid_byte3(2) xor vpid_byte3(1) xor vpid_byte3(0);
vpid_byte4_parity <= vpid_byte4(7) xor vpid_byte4(6) xor vpid_byte4(5) xor vpid_byte4(4)  xor vpid_byte4(3) xor vpid_byte4(2) xor vpid_byte4(1) xor vpid_byte4(0);

anc_parity_msb    <= data_out(17) xor data_out(16) xor data_out(15) xor data_out(14) xor data_out(13) xor data_out(12) xor data_out(11) xor data_out(10);
anc_parity_lsb    <= data_out(7) xor data_out(6) xor data_out(5) xor data_out(4) xor data_out(3) xor data_out(2) xor data_out(1) xor data_out(0);

--sfm
process(sdi_clk,sdi_nRST)
begin
    if(sdi_nRST = '0' )then
        pstate        <= GEN_IDLE;

        line_cnt      <= conv_std_logic_vector(1,11);
        word_cnt      <= (others => '0');

        F_sdi         <= '0';
        V_sdi         <= '1';
        H_sdi         <= '1';

        vidout_din_en <= '0';

        anc_sdi   <= '0';
        insert_cs <= '0';
        out_trs   <= '0';

        checksum_en1 <= '0';
        checksum_en2 <= '0';

        line_now  <= (others => '0');
        lineb_now <= (others => '0');
        
        --data
        for i in 0 to NUM_STREAMS-1 loop
            data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
            data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
        end loop;
   --elsif(vidout_vs = '1') then
    elsif rising_edge(sdi_clk) then

--            out_trs        <= '0';

        if(tx_enable = '1')then

               checksum_en1   <= '0';
               checksum_en2   <= '0';
               insert_cs      <= '0';
               anc_sdi        <= '0';
               out_trs        <= '0';

            case pstate is
                when GEN_IDLE =>
                    pstate   <= GEN_EAV_1;
                    line_cnt <= conv_std_logic_vector(1,11);
                    
                    F_sdi <= '0';
                    V_sdi <= '1';
                    H_sdi <= '1';

                    anc_sdi   <= '0';
                    insert_cs <= '0';
                    out_trs   <= '0';

                    checksum_en1 <= '0';
                    checksum_en2 <= '0';
                      
                when GEN_EAV_1 =>
                    pstate <= GEN_EAV_2;
                    
                    line_now  <= line_cnt;
                    lineb_now <= line_cnt;
                    out_trs   <= '1';

                    --H
                    H_sdi     <= '1';                    

                    --V
                    if(line_cnt = v_fall_line_1 or line_cnt = v_fall_line_2 )then--v_ctrl
                        V_sdi <= '0';
                    elsif(line_cnt = v_rise_line_1 or line_cnt = v_rise_line_2  )then
                        V_sdi <= '1';
                    end if;

                    --F
                    if(line_cnt = f_fall_line )then--f_ctrl
                        F_sdi <= '0';
                    elsif(line_cnt = f_rise_line  )then
                        F_sdi <= '1';
                    end if;

                    --data 
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--HD 3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                        for i in 1 to NUM_STREAMS-1 loop
                            data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                            data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                        end loop;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= Y_BLANKING_DATA;
                        for i in 1 to NUM_STREAMS-1 loop
                            data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                            data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                        end loop;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                        data_out(29 downto 20)  <= SIGNAL_3FF;
                        data_out(39 downto 30)  <= SIGNAL_3FF;
                        if(sdi_tx_std(1) = '1') then
                            for i in 2 to NUM_STREAMS-1 loop
                            data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_3FF;
                            data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_3FF;
                        end loop;
                        else --6G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                                data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                            end loop;
                        end if;
                    end if;

                when GEN_EAV_2 =>
                    pstate <= GEN_EAV_3;
                    
                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_000;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                        data_out(29 downto 20)  <= SIGNAL_000;
                        data_out(39 downto 30)  <= SIGNAL_000;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_000;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_000;
                            end loop;
                        end if;
                    end if;

                when GEN_EAV_3 =>
                    pstate <= GEN_EAV_4;

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_000;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                        data_out(29 downto 20)  <= SIGNAL_000;
                        data_out(39 downto 30)  <= SIGNAL_000;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_000;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_000;
                            end loop;
                        end if;
                    end if;
                    
                when GEN_EAV_4 =>
                    if(sdi_tx_std = "000") then
                        if(line_cnt = vpid_line_f0 or line_cnt = vpid_line_f1) then
                            pstate <= GEN_ADF0;
                        else
                            pstate <= GEN_HANC;                            
                        end if;
                    else
                        pstate <= GEN_LN_CRC;
                    end if;

                    word_cnt <= conv_std_logic_vector(1,13);

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= calc_xyz;
                        data_out(19 downto 10)  <= calc_xyz;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= calc_xyz;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= calc_xyz;
                        data_out(19 downto 10)  <= calc_xyz;
                        data_out(29 downto 20)  <= calc_xyz;
                        data_out(39 downto 30)  <= calc_xyz;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= calc_xyz;
                                data_out((i+1)*20-1 downto i*20+10) <= calc_xyz;
                            end loop;
                        end if;
                    end if;

                when GEN_LN_CRC =>
                    if(word_cnt >= 4)then  --add ln crc
                        word_cnt <= conv_std_logic_vector(1,13);
                        if(line_now = vpid_line_f0 or line_now = vpid_line_f1) then
                            pstate <= GEN_ADF0;
                        else
                            pstate <= GEN_HANC;
                        end if;
                    else
                        word_cnt <= word_cnt + 1;
                        pstate <= GEN_LN_CRC;
                    end if;

                    for i in 0 to NUM_STREAMS-1 loop
                        data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                        data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                    end loop;

                when GEN_ADF0 =>
                    pstate <= GEN_ADF1; 

                    anc_sdi <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_000;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                        data_out(29 downto 20)  <= SIGNAL_000;
                        data_out(39 downto 30)  <= SIGNAL_000;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_000;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_000;
                            end loop;
                        end if;
                    end if;

                when GEN_ADF1 =>
                    pstate <= GEN_ADF2;   

                    anc_sdi <= '1'; 

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_3FF;  
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                        data_out(29 downto 20)  <= SIGNAL_3FF;
                        data_out(39 downto 30)  <= SIGNAL_3FF;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_3FF;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_3FF;
                            end loop;
                        end if;
                    end if;

                when GEN_ADF2 =>
                    pstate <= GEN_DID;   

                    anc_sdi <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_3FF;  
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                        data_out(29 downto 20)  <= SIGNAL_3FF;
                        data_out(39 downto 30)  <= SIGNAL_3FF;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_3FF;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_3FF;
                            end loop;
                        end if;
                    end if;

                when GEN_DID =>
                    pstate <= GEN_SDID;   

                    anc_sdi <= '1';
                    checksum_en1 <= '1';
                                        
                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= vpid_did;
                        data_out(19 downto 10)  <= vpid_did;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= vpid_did;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= vpid_did;
                        data_out(19 downto 10)  <= vpid_did;
                        data_out(29 downto 20)  <= vpid_did;
                        data_out(39 downto 30)  <= vpid_did;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= vpid_did;
                                data_out((i+1)*20-1 downto i*20+10) <= vpid_did;
                            end loop;
                        end if;
                    end if;

                when GEN_SDID =>
                    pstate <= GEN_DC; 

                    anc_sdi <= '1';
                    checksum_en1 <= '0';
                    checksum_en2 <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= vpid_sdid;
                        data_out(19 downto 10)  <= vpid_sdid;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= vpid_sdid;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= vpid_sdid;   
                        data_out(19 downto 10)  <= vpid_sdid;
                        data_out(29 downto 20)  <= vpid_sdid;
                        data_out(39 downto 30)  <= vpid_sdid;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= vpid_sdid;
                                data_out((i+1)*20-1 downto i*20+10) <= vpid_sdid;
                            end loop;
                        end if;
                    end if;



                when GEN_DC =>
                    pstate <= GEN_VPID1; 

                    anc_sdi <= '1';
                    checksum_en2 <= '1';
                    
                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= vpid_dc;
                        data_out(19 downto 10)  <= vpid_dc;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= vpid_dc; 
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= vpid_dc;
                        data_out(19 downto 10)  <= vpid_dc;
                        data_out(29 downto 20)  <= vpid_dc;
                        data_out(39 downto 30)  <= vpid_dc;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= vpid_dc;
                                data_out((i+1)*20-1 downto i*20+10) <= vpid_dc;
                            end loop;
                        end if;
                    end if;

                when GEN_VPID1 =>
                    pstate <= GEN_VPID2; 

                    anc_sdi <= '1';
                    checksum_en2 <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                        data_out(19 downto 10)  <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                        data_out(19 downto 10)  <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                        data_out(29 downto 20)  <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                        data_out(39 downto 30)  <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                                data_out((i+1)*20-1 downto i*20+10) <= (not vpid_byte1_parity) & vpid_byte1_parity & vpid_byte1;
                            end loop;
                        end if;
                    end if;

                when GEN_VPID2 =>
                    pstate <= GEN_VPID3; 

                    anc_sdi <= '1';
                    checksum_en2 <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                        data_out(19 downto 10)  <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                        data_out(19 downto 10)  <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                        data_out(29 downto 20)  <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                        data_out(39 downto 30)  <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                                data_out((i+1)*20-1 downto i*20+10) <= (not vpid_byte2_parity) & vpid_byte2_parity & vpid_byte2;
                            end loop;
                        end if;
                    end if;

                when GEN_VPID3 =>
                    pstate <= GEN_VPID4; 

                    anc_sdi <= '1';
                    checksum_en2 <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                        data_out(19 downto 10)  <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                        data_out(19 downto 10)  <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                        data_out(29 downto 20)  <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                        data_out(39 downto 30)  <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                                data_out((i+1)*20-1 downto i*20+10) <= (not vpid_byte3_parity) & vpid_byte3_parity & vpid_byte3;
                            end loop;
                        end if;
                    end if;

                when GEN_VPID4 =>
                    pstate <= GEN_CS; 

                    anc_sdi <= '1';
                    checksum_en2 <= '1';

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                        data_out(19 downto 10)  <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                        data_out(19 downto 10)  <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                        data_out(29 downto 20)  <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                        data_out(39 downto 30)  <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                                data_out((i+1)*20-1 downto i*20+10) <= (not vpid_byte4_parity) & vpid_byte4_parity & vpid_byte4;
                            end loop;
                        end if;
                    end if;

                when GEN_CS =>
                    if(sdi_tx_std = "000") then
                        pstate <= GEN_HANC_Y;
                    else
                        pstate <= GEN_HANC;
                    end if;
                    
                    insert_cs    <= '1';

                when GEN_HANC =>
                    if(sdi_tx_std = "000" )then
                        pstate <= GEN_HANC_Y;
                    else
                        if(word_cnt >= init_line_hanc_word)then
                            pstate <= GEN_SAV_1;
                            word_cnt <= conv_std_logic_vector(0,13); 
                        else
                            pstate <= GEN_HANC;
                            word_cnt <= word_cnt + 1;
                        end if;
                    end if;

                    --data
                    for i in 0 to NUM_STREAMS-1 loop
                        data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                        data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                    end loop;

                when GEN_HANC_Y =>
                    if(word_cnt >= init_sd_hanc_y_word)then
                        pstate <= GEN_SAV_1;
                        word_cnt <= conv_std_logic_vector(0,13); 
                    else
                        pstate <= GEN_HANC_Y;
                        word_cnt <= word_cnt + 1;
                    end if;

                    --data
                        data_out(9 downto 0)    <= Y_BLANKING_DATA;

                when GEN_SAV_1 =>   
                    pstate <= GEN_SAV_2;

                    out_trs   <= '1';
                    H_sdi     <= '0';

                    --data 
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                        for i in 1 to NUM_STREAMS-1 loop
                            data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                            data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                        end loop;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= Y_BLANKING_DATA;
                        for i in 1 to NUM_STREAMS-1 loop
                            data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                            data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                        end loop;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_3FF;
                        data_out(19 downto 10)  <= SIGNAL_3FF;
                        data_out(29 downto 20)  <= SIGNAL_3FF;
                        data_out(39 downto 30)  <= SIGNAL_3FF;
                        if(sdi_tx_std(1) = '1') then
                            for i in 2 to NUM_STREAMS-1 loop
                            data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_3FF;
                            data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_3FF;
                        end loop;
                        else --6G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                                data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                            end loop;
                        end if;
                    end if;

                when GEN_SAV_2 =>   
                    pstate <= GEN_SAV_3;
                    
                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_000;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                        data_out(29 downto 20)  <= SIGNAL_000;
                        data_out(39 downto 30)  <= SIGNAL_000;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_000;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_000;
                            end loop;
                        end if;
                    end if;

                when GEN_SAV_3 =>   
                    pstate <= GEN_SAV_4;

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= SIGNAL_000;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= SIGNAL_000;
                        data_out(19 downto 10)  <= SIGNAL_000;
                        data_out(29 downto 20)  <= SIGNAL_000;
                        data_out(39 downto 30)  <= SIGNAL_000;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= SIGNAL_000;
                                data_out((i+1)*20-1 downto i*20+10) <= SIGNAL_000;
                            end loop;
                        end if;
                    end if;


                when GEN_SAV_4 =>   
                    pstate <= GEN_DATA;

                    vidout_din_en <= not(V_sdi); 
                    word_cnt      <= conv_std_logic_vector(1,13);                    

                    --data
                    if(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                        data_out(9 downto 0)    <= calc_xyz;
                        data_out(19 downto 10)  <= calc_xyz;
                    elsif(sdi_tx_std ="000") then --SD SDI
                        data_out(9 downto 0)    <= calc_xyz;
                    elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                        data_out(9 downto 0)    <= calc_xyz;
                        data_out(19 downto 10)  <= calc_xyz;
                        data_out(29 downto 20)  <= calc_xyz;
                        data_out(39 downto 30)  <= calc_xyz;
                        if(sdi_tx_std(1) = '1') then --12G
                            for i in 2 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= calc_xyz;
                                data_out((i+1)*20-1 downto i*20+10) <= calc_xyz;
                            end loop;
                        end if;
                    end if;

                when GEN_DATA =>
                    if(word_cnt >= words_per_active_line)then
                        pstate <= GEN_EAV_1;
                        word_cnt <= conv_std_logic_vector(0,13); 
                        vidout_din_en <= '0';

                        if(line_cnt >= lines_per_frame)then
                            line_cnt <= conv_std_logic_vector(1,11);
                        else
                            line_cnt <= line_cnt + 1;
                        end if;
                    else
                        pstate <= GEN_DATA;
                        word_cnt <= word_cnt + 1;
                        vidout_din_en <= not(V_sdi);
                    end if;

                    --data
                    if(V_sdi = '0') then  
                        if(sdi_tx_std = "011" or sdi_tx_std = "001") then--3G SDI 
                            data_out(9 downto 0)    <= vidout_data(9 downto 0)  ;
                            data_out(19 downto 10)  <= vidout_data(19 downto 10);
                        elsif(sdi_tx_std ="000") then --SD SDI
                            data_out(9 downto 0)    <= vidout_data(9 downto 0)  ;
                        elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                            data_out(9 downto 0)    <= vidout_data(9 downto 0)  ;
                            data_out(19 downto 10)  <= vidout_data(19 downto 10);
                            data_out(29 downto 20)  <= vidout_data(29 downto 20);
                            data_out(39 downto 30)  <= vidout_data(39 downto 30);
                            if(sdi_tx_std(1) = '1') then --12G
                                for i in 2 to NUM_STREAMS-1 loop
                                    data_out((i+1)*20-10-1 downto i*20) <= vidout_data( (i*20)+9 downto i*20);
                                    data_out((i+1)*20-1 downto i*20+10) <= vidout_data((i*20)+19 downto (i*20)+10);
                                end loop;
                            end if;
                        end if;
                    else 
                        if(sdi_tx_std ="000") then --SD SDI
                            data_out(9 downto 0)    <= Y_BLANKING_DATA;
                        else
                            for i in 0 to NUM_STREAMS-1 loop
                                data_out((i+1)*20-10-1 downto i*20) <= C_BLANKING_DATA;
                                data_out((i+1)*20-1 downto i*20+10) <= Y_BLANKING_DATA;
                            end loop;
                        end if;
                    end if;
            
                when others =>
                    pstate <= GEN_IDLE;

                    F_sdi <= '0';
                    V_sdi <= '1';
                    H_sdi <= '1';

                    anc_sdi <= '0';
                    insert_cs <= '0';

                    vidout_din_en <= '0';
                    word_cnt <= conv_std_logic_vector(0,13);
                    line_now <= (others => '0');
                    lineb_now<= (others => '0');  
            end case;
        
        else
            vidout_din_en <= '0';
        

        end if;
    end if;
end process;


--Delayed signals for output

process(sdi_clk,sdi_nRST)
begin
    if sdi_nRST = '0' then
        insert_cs_r1 <= '0';
        insert_cs_r2 <= '0';

        F_sdi_r1    <= '0';
        V_sdi_r1    <= '0';                         
        H_sdi_r1    <= '0';                         
        anc_sdi_r1  <= '0';  
        anc_sdi_r2  <= '0';                 
        line_now_r1 <= (others => '0');                       
        lineb_now_r1<= (others => '0');                                         
        out_trs_r1      <= '0';  
        out_trs_r2      <= '0';  
        out_trs_r3     <= '0';
        out_trs_r4     <= '0';       
        sdi_tx_enable_r1 <= '0'; 

    elsif rising_edge(sdi_clk) then
        insert_cs_r1 <= insert_cs;
        insert_cs_r2 <= insert_cs_r1;
        F_sdi_r1    <= F_sdi;
        V_sdi_r1    <= V_sdi;                         
        H_sdi_r1    <= H_sdi;                         
        anc_sdi_r1  <= anc_sdi;   
        anc_sdi_r2  <= anc_sdi_r1;                  
        line_now_r1 <= line_now;                         
        lineb_now_r1<= lineb_now;                         
        out_trs_r1      <= out_trs; 
        out_trs_r2      <= out_trs_r1;  
        out_trs_r3      <= out_trs_r2;
        out_trs_r4      <= out_trs_r3;         
        sdi_tx_enable_r1 <= tx_enable  ;              

    end if;
end process;


--insert checksum in output data
insert_chcksumen <= insert_cs; --no leve B

process(sdi_clk,sdi_nRST)
begin
    if sdi_nRST = '0' then
        data_out_r1     <= (others => '0'); 
        data_out_r2     <= (others => '0'); 
        data_out_r3     <= (others => '0'); 
        data_out_r4     <= (others => '0'); 

        data_out_vld    <= '0';                    
        data_out_vld_r1 <= '0';  
        data_out_vld_r2 <= '0';          
        data_out_vld_r3 <= '0';  

    elsif rising_edge(sdi_clk) then
        if(insert_chcksumen = '1')then
            if(sdi_tx_std = "000")then --SD SDI
                data_out_r1(9 downto 0)    <= (not anc_checksum_lsb(8)) & anc_checksum_lsb;
                data_out_r1(19 downto 10)  <= Y_BLANKING_DATA;
            elsif(sdi_tx_std = "001")then--HD SDI
                data_out_r1(9 downto 0)    <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                data_out_r1(19 downto 10)  <= C_BLANKING_DATA;            
            elsif(sdi_tx_std = "011" or sdi_tx_std = "001")then--3G SDI 
                data_out_r1(19 downto 10) <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                data_out_r1(9 downto 0  ) <= (not anc_checksum_msb(8)) & anc_checksum_msb;
            elsif(sdi_tx_std(2) ='1') then --SDI 12G /6G
                data_out_r1(9 downto 0)    <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                data_out_r1(19 downto 10)  <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                data_out_r1(29 downto 20)  <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                data_out_r1(39 downto 30)  <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                if(sdi_tx_std(1) = '1') then --12G
                    for i in 2 to NUM_STREAMS-1 loop
                        data_out_r1((i+1)*20-10-1 downto i*20) <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                        data_out_r1((i+1)*20-1 downto i*20+10) <= (not anc_checksum_msb(8)) & anc_checksum_msb;
                    end loop;
                end if;
            end if;         
        else
            data_out_r1 <= data_out;  
            data_out_r2 <= data_out_r1;     
            data_out_r3 <= data_out_r2;  
            data_out_r4 <= data_out_r3;      
        end if;
        data_out_vld    <= sdi_tx_enable_r1;
        data_out_vld_r1 <= data_out_vld;  
        data_out_vld_r2 <= data_out_vld_r1;  
        data_out_vld_r3 <= data_out_vld_r2;     

    end if;
end process;

--checksum calculation
process(sdi_clk,sdi_nRST)
begin
    if sdi_nRST = '0' then
        anc_checksum_msb <= (others => '0');
        anc_checksum_lsb <= (others => '0');
    elsif rising_edge(sdi_clk) then
        if(sdi_tx_enable_r1 = '1')then
            if(checksum_en1 = '1')then
                anc_checksum_msb <= anc_parity_msb & data_out(17 downto 10);
                anc_checksum_lsb <= anc_parity_lsb & data_out(7  downto 0 );
            elsif(checksum_en2 = '1')then
                anc_checksum_msb <= anc_checksum_msb + (anc_parity_msb & data_out(17 downto 10));
                anc_checksum_lsb <= anc_checksum_lsb + (anc_parity_lsb & data_out(7  downto 0 ));
            end if;
        end if;
    end if;
end process;



process(sdi_clk,sdi_nRST)
begin
    if sdi_nRST = '0' then
        sdi_tx_data     <= (others => '0');
        sdi_tx_vld      <= '0';
        sdi_tx_trs      <= '0';
        sdi_tx_ln       <= (others => '0');
        sdi_tx_ln_b     <= (others => '0');
        viout_anc       <= '0';
        vidout_word_cnt <= (others => '0');

    elsif rising_edge(sdi_clk) then
        sdi_tx_data      <=  data_out_r3;--sd/Hd

        sdi_tx_vld      <= data_out_vld_r2; --sd/Hd

        sdi_tx_trs       <=  out_trs_r3;--sd/HD

        sdi_tx_ln        <=  line_now_r1&line_now_r1&line_now_r1&line_now_r1;
        sdi_tx_ln_b      <=  lineb_now_r1&lineb_now_r1&lineb_now_r1&lineb_now_r1;
        viout_anc        <=  anc_sdi_r1;
        vidout_word_cnt  <=  word_cnt;

    end if;
end process;


--sdi_tx_data      <=  data_out_r2; --12G
--sdi_tx_data      <=  data_out_r4;--sd/Hd
--sdi_tx_data      <=  data_out_r1;--HD/12G

--sdi_tx_vld       <=  data_out_vld_r1; --12G

--sdi_tx_vld       <=  data_out_vld; --hd/12G

--sdi_tx_trs       <=  out_trs_r2;--12G
--sdi_tx_trs       <=  out_trs_r4;--sd/HD
--sdi_tx_trs       <=  out_trs_r1;--hd/12G

--sdi_tx_ln        <=  line_now_r1&line_now_r1&line_now_r1&line_now_r1;
--sdi_tx_ln_b      <=  lineb_now_r1&lineb_now_r1&lineb_now_r1&lineb_now_r1;
--viout_anc        <=  anc_sdi_r2;
--vidout_word_cnt  <=  word_cnt;

end behav;

