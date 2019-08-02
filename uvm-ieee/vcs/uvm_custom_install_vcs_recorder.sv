//-------------------------------------------------------------
//    Copyright 2011 Synopsys, Inc.
//    All Rights Reserved Worldwide
//
// SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary work of 
// Synopsys, Inc., and is fully protected under copyright and trade 
// secret laws. You may not view, use, disclose, copy, or distribute this 
// file or any information contained herein except pursuant to a valid 
// written license from Synopsys. 
//
//-------------------------------------------------------------

`ifndef UVM_CUSTOM_INSTALL_VCS_RECORDER
`define UVM_CUSTOM_INSTALL_VCS_RECORDER

`ifdef _SNPS_UVM_PKG_GLOBAL_IMPORT_
`ifndef _SNPS_UVM_PKG_IMPORTED

 import uvm_pkg::*;

 import "DPI-C" function string getenv(input string env_name);

`define _SNPS_UVM_PKG_IMPORTED
`endif

 `include "msglog.svh"
 `include "uvm_msglog_report_server.sv"
 `include "uvm_vcs_recorder.svh"
 `include "uvm_vcs_record_interface.sv"

 module uvm_custom_install_recording;
`else

 `include "msglog.svh"
 `include "uvm_msglog_report_server.sv"

 module uvm_custom_install_recording;

 import uvm_pkg::*;

 import "DPI-C" function string getenv(input string env_name);

 `include "uvm_vcs_recorder.svh"
 `include "uvm_vcs_record_interface.sv"
`endif

   uvm_cmdline_processor clp;
   string tr_args[$];
   uvm_coreservice_t cs;
   uvm_vcs_tr_database vcs_db;
   string env_str,vc_env_str="",sanity_file_name="";
   int file_handle=0, is_sanity_exist=0;
     
   initial begin

     clp = uvm_cmdline_processor::get_inst();
     cs = uvm_coreservice_t::get();
     env_str = getenv("SNPS_SIM_DEFAULT_GUI");
     vc_env_str = getenv("VC_HOME");
     if (vc_env_str!="")begin
         sanity_file_name = {vc_env_str,"/etc/.sanity"};
         file_handle = $fopen(sanity_file_name,"r");
         if (file_handle!=0) begin
             is_sanity_exist = 1;
             $fclose(file_handle);
         end
     end

     // Register the vcs_smartlog_catcher to dump messages into VPD
     if (clp.get_arg_matches("+UVM_LOG_RECORD", tr_args) && (!clp.get_arg_matches("+UVM_VERDI_TRACE", tr_args) 
                                                            && (env_str != "verdi") && !is_sanity_exist)) begin
       static vcs_smartlog_catcher _vcs_catcher = new();
       uvm_report_cb::add(null,_vcs_catcher);
     end

     // Register the uvm_vcs_recorder to record transactions into VPD
     if (clp.get_arg_matches("+UVM_TR_RECORD", tr_args) && (!clp.get_arg_matches("+UVM_VERDI_TRACE", tr_args)
                                                            && (env_str != "verdi")&& !is_sanity_exist)) begin
      vcs_db = new();
      cs.set_default_tr_database(vcs_db);
      if (clp.get_arg_matches("+UVM_DISABLE_AUTO_COMPONENT", tr_args)) begin
	 `uvm_info("VCS_TR_AUTO", "+UVM_DISABLE_AUTO_COMPONENT enabled but transaction recording enabled, usage model requires user to explicitly set recording_detail on components", UVM_MEDIUM)
      end
      else begin
	 `uvm_info("VCS_TR_AUTO", "+UVM_TR_RECORD implicitly enables recording_details to UVM_FULL for all components. For explicit control use +UVM_DISABLE_AUTO_COMPONENT and set recording_detail on components accordingly", UVM_MEDIUM)
	  uvm_config_db#(uvm_bitstream_t)::set(uvm_root::get(), "*", "recording_detail", UVM_FULL);
      end
     end
   end
 endmodule

`endif // UVM_CUSTOM_INSTALL_VCS_RECORDER
