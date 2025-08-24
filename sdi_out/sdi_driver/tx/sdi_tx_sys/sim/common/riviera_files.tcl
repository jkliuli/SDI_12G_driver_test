source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_core_rst/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi_clkout/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl_clk/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl/sim/common/riviera_files.tcl]

namespace eval sdi_tx_sys {
  proc get_design_libraries {} {
    set libraries [dict create]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_core_rst::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_sdi::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_phy_reset::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_sdi_clkout::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_phy::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_phy_reset_0::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_design_libraries]]
    set libraries [dict merge $libraries [sdi_tx_sys_tx_phy_rst_ctrl::get_design_libraries]]
    dict set libraries altera_reset_controller_1921 1
    dict set libraries sdi_tx_sys                   1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR} {
    set memory_files [list]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_core_rst::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_core_rst/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_sdi::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_phy_reset::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_sdi_clkout::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi_clkout/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_phy::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_phy_reset_0::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset_0/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl_clk/sim/"]]
    set memory_files [concat $memory_files [sdi_tx_sys_tx_phy_rst_ctrl::get_memory_files "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl/sim/"]]
    return $memory_files
  }
  
  proc get_common_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [dict create]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_core_rst::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_core_rst/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_sdi::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_phy_reset::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_sdi_clkout::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi_clkout/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_phy::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_phy_reset_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset_0/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl_clk/sim/"]]
    set design_files [dict merge $design_files [sdi_tx_sys_tx_phy_rst_ctrl::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl/sim/"]]
    return $design_files
  }
  
  proc get_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [list]
    set design_files [concat $design_files [sdi_tx_sys_tx_core_rst::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_core_rst/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_sdi::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_phy_reset::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_sdi_clkout::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_sdi_clkout/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_phy::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_phy_reset_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_reset_0/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl_clk/sim/"]]
    set design_files [concat $design_files [sdi_tx_sys_tx_phy_rst_ctrl::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/sdi_tx_sys/sdi_tx_sys_tx_phy_rst_ctrl/sim/"]]
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_1921/sim/altera_reset_controller.v"]\"  -work altera_reset_controller_1921"  
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_1921/sim/altera_reset_synchronizer.v"]\"  -work altera_reset_controller_1921"
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/sdi_tx_sys.v"]\"  -work sdi_tx_sys"                                                                     
    return $design_files
  }
  
  proc get_elab_options {SIMULATOR_TOOL_BITNESS} {
    set ELAB_OPTIONS ""
    append ELAB_OPTIONS [sdi_tx_sys_tx_core_rst::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_sdi::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_phy_reset::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_sdi_clkout::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_phy::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_phy_reset_0::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_elab_options $SIMULATOR_TOOL_BITNESS]
    append ELAB_OPTIONS [sdi_tx_sys_tx_phy_rst_ctrl::get_elab_options $SIMULATOR_TOOL_BITNESS]
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    append SIM_OPTIONS [sdi_tx_sys_tx_core_rst::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_sdi::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_phy_reset::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_sdi_clkout::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_phy::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_phy_reset_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [sdi_tx_sys_tx_phy_rst_ctrl::get_sim_options $SIMULATOR_TOOL_BITNESS]
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_core_rst::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_sdi::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_phy_reset::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_sdi_clkout::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_phy::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_phy_reset_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_phy_rst_ctrl_clk::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [sdi_tx_sys_tx_phy_rst_ctrl::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    dict set ENV_VARIABLES "LD_LIBRARY_PATH" $LD_LIBRARY_PATH
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ENV_VARIABLES
  }
  
  
  proc normalize_path {FILEPATH} {
      if {[catch { package require fileutil } err]} { 
          return $FILEPATH 
      } 
      set path [fileutil::lexnormalize [file join [pwd] $FILEPATH]]  
      if {[file pathtype $FILEPATH] eq "relative"} { 
          set path [fileutil::relative [pwd] $path] 
      } 
      return $path 
  } 
}
