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

`ifndef UVM_CUSTOM_INSTALL_VERDI_RECORDER
`define UVM_CUSTOM_INSTALL_VERDI_RECORDER

`ifndef UVM_VERDI_VIF_RECORD
   `define UVM_NO_VERDI_DPI
`endif

`ifndef UVM_VERDI_OBJECT_RECORD
`define UVM_VERDI_NO_COMPWAVE
`endif

static int is_reg_hier_recorded = 0;
static int is_dhier_visited = 0;
static int is_reg_hier_dumping = 0;

// 9001357026 Fix linter error
`ifdef VERDI_KEEP_UNIT_IMPORT
`ifndef _SNPS_UVM_PKG_IMPORTED_
 import uvm_pkg::*;
`define _SNPS_UVM_PKG_IMPORTED_
`endif
static int user_verbosity = UVM_MEDIUM; // 9001338477 9001317799
`include "uvm_macros.svh"
`include "uvm_verdi_recorder.svh"
`include "uvm_verdi_reg_map_recording.sv"
`include "uvm_verdi_message_catcher.svh"
`include "uvm_verdi_factory.svh"
`include "./dpi/uvm_verdi_dpi.svh"
`include "uvm_verdi_reg_recording.sv"
static verdi_cmdline_processor verdi_clp;
`endif
//

module uvm_custom_install_verdi_recording;
// 9001357026 Fix linter error
`ifndef VERDI_KEEP_UNIT_IMPORT
 import uvm_pkg::*;
`endif
static int user_verbosity = UVM_MEDIUM; // 9001338477 9001317799
`include "uvm_macros.svh"
`include "uvm_verdi_recorder.svh"
`include "uvm_verdi_reg_map_recording.sv"
`include "uvm_verdi_message_catcher.svh"
`include "uvm_verdi_factory.svh"
`include "./dpi/uvm_verdi_dpi.svh"
`include "uvm_verdi_reg_recording.sv"

static verdi_cmdline_processor verdi_clp;

class uvm_dhier_component extends uvm_component;
      `uvm_component_utils(uvm_dhier_component)

      virtual function void start_of_simulation_phase(uvm_phase phase);
         uvm_component top_comp, root;
         uvm_component top_comps[$];
         root = uvm_root::get();

`ifndef UVM_NO_VERDI_DPI
         if (verdi_clp.is_verdi_trace_compwave()||verdi_clp.is_verdi_trace_dht()) begin
             root.get_children(top_comps);

             while(top_comps.size() > 0) begin
                top_comp = top_comps.pop_front();
                verdi_dhier_interface("top_comp");
             end
         end
`endif
         if (verdi_clp.is_verdi_trace_ral()) begin
             // Make sure that the register should be recorded here first
             is_dhier_visited = 1;
             is_reg_hier_dumping = 1;
             is_reg_hier_recorded = record_reg_hier();
             is_reg_hier_dumping = 0;
         end
      endfunction

      function new (string name="DHIER", uvm_component parent);
         super.new(name, parent);
      endfunction
 endclass
//

// 9001346000 9001445100
`ifndef VERDI_REPLACE_DPI_WITH_PLI
`ifdef VCS
`ifdef __VERDI_TRANS_HEADER
`define STRINGIFY(x) `"x`"
`include `STRINGIFY(`__VERDI_TRANS_HEADER)
`else
`include "verdi_trans_recorder_dpi.svh" // 6000025017
`endif
`endif
`endif
//
`ifdef VCS
import "DPI-C" function string getenv(input string env_name);
`endif
   `include "uvm_verdi_pli.svh" //Hide dumper tasks inside this module
   static uvm_cmdline_processor clp;
   string tr_args[$];
   uvm_coreservice_t cs;
   uvm_verdi_tr_database verdi_db;
   uvm_factory factory;
`ifndef UVM_VERDI_NO_FACTORY_RECORDING
   uvm_verdi_factory verdi_factory;
`endif
   process p;
   string rand_state;
`ifdef VCS
   string env_str,vc_env_str="",sanity_file_name="";
   int file_handle=0, is_sanity_exist=0, is_vpd_record = 0;
   string env_vcs_home = "", env_vcs_uvm_home ="";
   int is_vcs_home_exist = 0, is_vcs_uvm_home_exist = 0;
`endif 

   initial begin
     p = process::self();
     if (p != null)
         rand_state = p.get_randstate();
     verdi_clp = verdi_cmdline_processor::get_inst();
     clp = uvm_cmdline_processor::get_inst();
     pli_inst = uvm_verdi_pli::get_inst();
     cs = uvm_coreservice_t::get();
`ifdef VCS
     env_vcs_home = getenv("VCS_HOME");
     if (env_vcs_home!="")
         is_vcs_home_exist = 1;
     env_vcs_uvm_home = getenv("VCS_UVM_HOME");
     if (env_vcs_uvm_home!="")
         is_vcs_uvm_home_exist = 1;
     if (clp.get_arg_matches("+UVM_VPD_RECORD", tr_args))
         is_vpd_record = 1;
     env_str = getenv("SNPS_SIM_DEFAULT_GUI");
     vc_env_str = getenv("VC_HOME");
     if (vc_env_str!="")begin
         sanity_file_name = {vc_env_str,"/etc/.sanity"};
         file_handle = $fopen(sanity_file_name,"r");
         if (file_handle!=0) begin
             if (is_vpd_record)
                 is_sanity_exist = 0;
             else
                 is_sanity_exist = 1;
             $fclose(file_handle);
         end
     end
`endif 

`ifndef UVM_NO_VERDI_RECORD
     if (verdi_clp.is_verdi_trace_ral()) begin
         uvm_root r_obj;
         // 9001338477
         string verb_settings[$];
         string verb_string;
         int verb_count;
         //

         // 9001338477
         verb_count = clp.get_arg_values("+UVM_VERBOSITY=",verb_settings);
         if (verb_count > 0) begin
             verb_string = verb_settings[0];
             case(verb_string)
              "UVM_NONE"    : user_verbosity = UVM_NONE;
              "NONE"        : user_verbosity = UVM_NONE;
              "UVM_LOW"     : user_verbosity = UVM_LOW;
              "LOW"         : user_verbosity = UVM_LOW;
              "UVM_MEDIUM"  : user_verbosity = UVM_MEDIUM;
              "MEDIUM"      : user_verbosity = UVM_MEDIUM;
              "UVM_HIGH"    : user_verbosity = UVM_HIGH;
              "HIGH"        : user_verbosity = UVM_HIGH;
              "UVM_FULL"    : user_verbosity = UVM_FULL;
              "FULL"        : user_verbosity = UVM_FULL;
              "UVM_DEBUG"   : user_verbosity = UVM_DEBUG;
              "DEBUG"       : user_verbosity = UVM_DEBUG;
              default       : begin
                user_verbosity = verb_string.atoi();
                if(user_verbosity > 0)
                   uvm_report_info("NSTVERB", $sformatf("Non-standard verbosity value, using provided '%0d'.", user_verbosity), UVM_NONE);
                if(user_verbosity == 0) begin
                   user_verbosity = UVM_MEDIUM;
                   uvm_report_warning("ILLVERB", "Illegal verbosity value, using default of UVM_MEDIUM.", UVM_NONE);
                end
              end
            endcase
         end
         //
         r_obj = uvm_root::get();
         r_obj.set_report_id_verbosity("RegModel", UVM_HIGH);
         r_obj.set_report_id_verbosity("uvm_reg_map", UVM_FULL);
     end
`endif

     // Register the verdi_catcher to dump messages into FSDB
`ifdef VCS
     if ((clp.get_arg_matches("+UVM_LOG_RECORD", tr_args)&&clp.get_arg_matches("+UVM_VERDI_TRACE", tr_args))
         ||(clp.get_arg_matches("+UVM_LOG_RECORD", tr_args)&&(env_str=="verdi"))
         ||verdi_clp.is_verdi_trace_fac()||verdi_clp.is_verdi_trace_msg()||verdi_clp.is_verdi_trace_uvm_aware()
         ||verdi_clp.is_verdi_trace_ral()||verdi_clp.is_verdi_trace_dht()
         ||(clp.get_arg_matches("+UVM_LOG_RECORD", tr_args) && verdi_clp.is_minus_gui_verdi())
         ||(clp.get_arg_matches("+UVM_LOG_RECORD", tr_args)&&is_sanity_exist)
         ||verdi_clp.is_verdi_trace_ralwave()||verdi_clp.is_verdi_trace_compwave())
     begin
`else
     if ((clp.get_arg_matches("+UVM_LOG_RECORD", tr_args)&&clp.get_arg_matches("+UVM_VERDI_TRACE", tr_args))
         ||verdi_clp.is_verdi_trace_fac()||verdi_clp.is_verdi_trace_msg()
         ||verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_ral()
         ||verdi_clp.is_verdi_trace_dht())
     begin
`endif
       static verdi_report_catcher _verdi_catcher;

       _verdi_catcher = new();
       uvm_report_cb::add(null,_verdi_catcher);
       if (verdi_clp.is_verdi_trace_compwave()||verdi_clp.is_verdi_trace_dht()
           ||verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_ral()) begin
           uvm_dhier_component dhier_comp;

           dhier_comp = new("DHIER_COMP", uvm_root::get());
       end
`ifdef UVM_VERDI_RALWAVE
       if (verdi_clp.is_verdi_trace_ralwave()) begin
           if (is_vcs_uvm_home_exist)
               pli_inst.dump_class_object_by_file("${VCS_UVM_HOME}/verdi/register.config");
           else if (is_vcs_home_exist)
               pli_inst.dump_class_object_by_file("${VCS_HOME}/etc/uvm-1.2/verdi/register.config");
       end
`endif
`ifndef UVM_VERDI_NO_COMPWAVE
`ifdef VCS
       if (verdi_clp.is_verdi_trace_compwave()) begin
           if (is_vcs_uvm_home_exist)
               pli_inst.dump_comp_object_by_file("${VCS_UVM_HOME}/verdi/component.config");
           else if (is_vcs_home_exist)
               pli_inst.dump_comp_object_by_file("${VCS_HOME}/etc/uvm-1.2/verdi/component.config");
       end
`endif
`endif
       if (verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_fac()) begin
           factory = cs.get_factory();
`ifndef UVM_VERDI_NO_FACTORY_RECORDING
           // create new factory
           verdi_factory = new();
           // set the delegate
           verdi_factory.delegate=factory;
           // enable new factory
           cs.set_factory(verdi_factory);
`endif
       end
     end

     // Register the uvm_verdi_recorder to record transactions into FSDB
`ifdef VCS
     if ((clp.get_arg_matches("+UVM_TR_RECORD", tr_args)&&clp.get_arg_matches("+UVM_VERDI_TRACE", tr_args))
         ||(clp.get_arg_matches("+UVM_TR_RECORD", tr_args)&&(env_str=="verdi"))
         ||verdi_clp.is_verdi_trace_tlm()
         ||(clp.get_arg_matches("+UVM_TR_RECORD", tr_args)&&verdi_clp.is_minus_gui_verdi())
         ||(clp.get_arg_matches("+UVM_TR_RECORD", tr_args)&&is_sanity_exist))
     begin
`else
     if ((clp.get_arg_matches("+UVM_TR_RECORD", tr_args)&&clp.get_arg_matches("+UVM_VERDI_TRACE", tr_args))
         ||verdi_clp.is_verdi_trace_tlm())
     begin
`endif
         verdi_db = new();
         cs.set_default_tr_database(verdi_db);
         if (clp.get_arg_matches("+UVM_DISABLE_AUTO_COMPONENT", tr_args)) begin
             `uvm_info("VERDI_TR_AUTO", "+UVM_DISABLE_AUTO_COMPONENT enabled but transaction recording enabled, usage model requires user to explicitly set recording_detail on components", UVM_MEDIUM)
         end
         else begin
             `uvm_info("VERDI_TR_AUTO", "+UVM_TR_RECORD implicitly enables recording_details to UVM_FULL for all components. For explicit control use +UVM_DISABLE_AUTO_COMPONENT and set recording_detail on components accordingly", UVM_MEDIUM)
             uvm_config_db#(uvm_bitstream_t)::set(uvm_root::get(), "*", "recording_detail", UVM_FULL);
         end
     end
     if (p != null)
         p.set_randstate(rand_state);
   end
 endmodule

`endif // UVM_CUSTOM_INSTALL_VERDI_RECORDER
