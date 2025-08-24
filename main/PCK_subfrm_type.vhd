
library IEEE;
use IEEE.std_logic_1164.all;

package PCK_subfrm_type is

constant PCB_ver						: std_logic_vector(7 downto 0):= x"00";
constant port_type						: std_logic_vector(7 downto 0):= x"12";
constant flash_type                 	: std_logic_vector( 1 downto 0):= "00";    ---- "00" is micron spi flash;"01"is macronix spi flash
constant FRAME_VIDEO_SEL				: std_logic_vector(7 downto 0):= x"03";
------------------------------------------------------------------------------------------------------------------------------
--frame type
constant FRAME_CLR_INFO                 : std_logic_vector(7 downto 0):= x"3C"; 
constant FRAME_DET_CARD                 : std_logic_vector(7 downto 0):= x"07";
constant FRAME_DET_CARD_ACK             : std_logic_vector(7 downto 0):= x"08";
constant FRAME_DET_SUBBOARD_INFO        : std_logic_vector(7 downto 0):= x"09";
constant FRAME_DET_SUBBOARD_INFO_ACK    : std_logic_vector(7 downto 0):= x"0A";
---flash
constant FRAME_SOPFLASH                 : std_logic_vector(7 downto 0):= x"06";--S means "slow". F means "fast".
constant FRAME_SOPFLASH_WRITE           : std_logic_vector(7 downto 0):= x"86";
constant FRAME_SOPFLASH_CHECK           : std_logic_vector(7 downto 0):= x"87";

constant FRAME_FOPFLASH                 : std_logic_vector(7 downto 0):= x"9F";--S means "slow". F means "fast".
constant FRAME_FOPFLASH_ERASE           : std_logic_vector(7 downto 0):= x"01";
constant FRAME_FOPFLASH_WDDR            : std_logic_vector(7 downto 0):= x"02";
constant FRAME_FOPFLASH_RDDR            : std_logic_vector(7 downto 0):= x"03";
constant FRAME_FOPFLASH_FAST_READBACK   : std_logic_vector(7 downto 0):= x"06";
constant FRAME_FOPFLASH_CRC_CHECK       : std_logic_vector(7 downto 0):= x"07";

constant FRAME_EDID                     : std_logic_vector(7 downto 0):= x"69";
constant FRAME_BACKGROUND_SIZE          : std_logic_vector(7 downto 0):= x"15";

constant FRAME_OUTPUT_PORTS_BACKUP      : std_logic_vector(7 downto 0):= x"22";

constant FRAME_PARAM_DONE               : std_logic_vector(7 downto 0):= x"49";
constant FRAME_PLLCHIP_CFG              : std_logic_vector(7 downto 0):= x"6A";

constant FRAME_VIDSRC_ENABLE            : std_logic_vector(7 downto 0):= x"32";
constant FRAME_VSYNC_SEL                : std_logic_vector(7 downto 0):= x"34";
constant FRAME_SERDES_CONFIG			: std_logic_vector(7 downto 0):= x"A3";
------------------------------------------------------------------------------------------------------------------------------
constant INPUT_SUBBAORD                 : std_logic_vector(7 downto 0):= x"00";
------------------------------------------------------------------------------------------------------------------------------
--                                                                                                                      --x200
constant TYPE_SDIx4_IN                  : std_logic_vector(7 downto 0):= X"16";                                         --x200

constant DEVNUM_FPGA                    : std_logic_vector(7 downto 0):= x"00";--used in ctrl_uart_rx.                   --x200
constant DEVNUM_ARM                     : std_logic_vector(7 downto 0):= x"01";--used in ctrl_uart_rx.                   --x200

constant Altera_FPGA            		: std_logic_vector(7 downto 0) := X"01";
constant CX220            				: std_logic_vector(7 downto 0) := X"00";

--program
constant PROGRAM_SIZE                   : std_logic_vector(15 downto 0):= x"00B0";  --In the unit of sector (64Kbyte)
constant PROGRAM_START                  : std_logic_vector(15 downto 0):= x"0100";  --In the unit of sector (64Kbyte)
constant PROGRAM_APPEND                 : std_logic_vector( 7 downto 0):= x"26";    --In the unit of byte.
------------------------------------------------------------------------------------------------------------------------------
end PCK_subfrm_type;
