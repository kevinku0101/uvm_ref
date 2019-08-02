//
//-----------------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc.
//   Copyright 2010 Synopsys, Inc.
//   Copyright 2013 NVIDIA Corporation
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//-----------------------------------------------------------------------------

`ifndef UVM_VERDI_TR_DATABASE_SVH
`define UVM_VERDI_TR_DATABASE_SVH

//------------------------------------------------------------------------------
// File: Transaction Recording Databases
//
// The UVM "Transaction Recording Database" classes are an abstract representation
// of the backend tool which is recording information for the user.  Usually this
// tool would be dumping information such that it can be viewed with the ~waves~ 
// of the DUT.
//

`include "uvm_verdi_tr_stream.svh"
typedef class verdi_cmdline_processor;
static bit plusargs_tested = 0;
static bit enable_verdi_debug = 0;
static bit enable_port_recording = 0;
static bit enable_tlm2_port_recording = 0;
static bit enable_imp_port_recording = 0;
static longint unsigned uvmPliHandleMap[integer];
static int uvmHandle = 0;

function bit test_port_plusargs ();
    static verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst();
    static uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
    string trace_args[$];
    if (!plusargs_tested) begin
        if (verdi_clp.is_verdi_trace_tlm()) begin
            enable_port_recording = 1;
            if (verdi_clp.is_verdi_trace_imp())
                enable_imp_port_recording = 1 ;
        end
        if (clp.get_arg_matches("+verdi_recorder_debug",trace_args))
            enable_verdi_debug = 1;
        plusargs_tested = 1;
    end
    return plusargs_tested;
endfunction

function bit test_tlm2_port_plusargs ();
    static verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst();
    static uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
    string trace_args[$];
    if (!plusargs_tested) begin
        if (verdi_clp.is_verdi_trace_tlm2()) begin
            enable_tlm2_port_recording = 1;
            if (verdi_clp.is_verdi_trace_imp())
                enable_imp_port_recording = 1 ;
        end
        if (clp.get_arg_matches("+verdi_recorder_debug",trace_args))
            enable_verdi_debug = 1;
        plusargs_tested = 1;
    end
    return plusargs_tested;
endfunction

function bit is_verdi_debug_enabled ();
    if (!test_port_plusargs()) return 0;
    if (!enable_verdi_debug) return 0;
    return open_debug_file();
endfunction
   
//------------------------------------------------------------------------------
//
// CLASS: uvm_verdi_tr_database
//
// The ~uvm_verdi_tr_database~ is the default implementation for the
// <uvm_tr_database>.  It provides the ability to store recording information
// into a textual log file.
//
//
   
class uvm_verdi_tr_database extends uvm_tr_database;

   // Variable- m_filename_dap
   // Data Access Protected Filename
   local uvm_simple_lock_dap#(string) m_filename_dap;

   // Variable- m_file
   UVM_FILE m_file;

   `uvm_object_utils_begin(uvm_verdi_tr_database)
   `uvm_object_utils_end

   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Instance name
   function new(string name="unnamed-uvm_verdi_tr_database");
      super.new(name);

      m_filename_dap = new("filename_dap");
      m_filename_dap.set("tr_db.log");
   endfunction : new

   // Group: Implementation Agnostic API
   // Function: do_open_db
   // Open the backend connection to the database.
   protected virtual function bit do_open_db();
      return 1;
   endfunction : do_open_db

   // Function: do_close_db
   // Close the backend connection to the database.
   protected virtual function bit do_close_db();
      return 1;
   endfunction : do_close_db
   
   // Function: do_open_stream
   // Provides a reference to a ~stream~ within the
   // database.
   //
   protected virtual function uvm_tr_stream do_open_stream(string name,
                                                           string scope,
                                                           string type_name);
      uvm_verdi_tr_stream m_stream = uvm_verdi_tr_stream::type_id::create(name);
      return m_stream;
   endfunction : do_open_stream

   // Function: do_establish_link
   // Establishes a ~link~ between two elements in the database
   //
   protected virtual function void do_establish_link(uvm_link_base link);
      uvm_recorder r_lhs, r_rhs;
      uvm_verdi_recorder r_verdi_lhs, r_verdi_rhs;
      static longint unsigned pliHandle1 = 0, pliHandle2 = 0;
      int tr_h1 = 0,tr_h2 = 0;
      uvm_object lhs = link.get_lhs();
      uvm_object rhs = link.get_rhs();
      string relation_name = ""; 
       
      void'($cast(r_lhs, lhs));
      void'($cast(r_rhs, rhs));
      
      if ((r_lhs == null) ||
          (r_rhs == null))
        return;
      else begin
         uvm_parent_child_link pc_link;
         uvm_related_link re_link;
         if ($cast(pc_link, link)) begin
            $cast(r_verdi_lhs,r_lhs);
            $cast(r_verdi_rhs,r_rhs);
            tr_h1 = r_verdi_lhs.get_handle();
            tr_h2 = r_verdi_rhs.get_handle();
            pliHandle1 = uvmPliHandleMap[tr_h1];
            pliHandle2 = uvmPliHandleMap[tr_h2]; 
            pli_inst.link_tr("parent_child",pliHandle1,pliHandle2);
            if (is_verdi_debug_enabled()) begin
                $fdisplay(m_file,"  LINK @%0t {TXH1:%0d TXH2:%0d RELATION=%0s}",
                      $time,
                      r_lhs.get_handle(),
                      r_rhs.get_handle(),
                      "child");
            end 
         end
         else if ($cast(re_link, link)) begin
            relation_name = re_link.get_name();
            $cast(r_verdi_lhs,r_lhs);
            $cast(r_verdi_rhs,r_rhs);
            tr_h1 = r_verdi_lhs.get_handle();
            tr_h2 = r_verdi_rhs.get_handle();
            pliHandle1 = uvmPliHandleMap[tr_h1];
            pliHandle2 = uvmPliHandleMap[tr_h2];
            pli_inst.link_tr(relation_name,pliHandle1,pliHandle2);
            if (is_verdi_debug_enabled()) begin
                $fdisplay(m_file,"  LINK @%0t {TXH1:%0d TXH2:%0d RELATION=%0s}",
                      $time,
                         r_lhs.get_handle(),
                      r_rhs.get_handle(),
                      "");
            end
            
         end
      end
   endfunction : do_establish_link

   // Group: Implementation Specific API

`ifndef UVM_VERDI_NO_PORT_RECORDING 
function integer port_begin_tr (uvm_port_component_base port_comp,
                                string label,
                                time begin_time);
    integer stream_h;
    integer tr_h;
    string stream_name;
    uvm_tr_database verdi_db;
    uvm_tr_stream verdi_stream;
    uvm_recorder recorder;
    uvm_verdi_recorder verdi_recorder;
    if (verdi_db == null) begin
         uvm_coreservice_t cs = uvm_coreservice_t::get();
         verdi_db = cs.get_default_tr_database();
    end
    stream_name = port_comp.get_full_name();
    verdi_stream = verdi_db.open_stream("", stream_name,"TVM:port_stream");
    if (verdi_stream == null)
        return -1;

    recorder = verdi_stream.open_recorder(label, begin_time, "PORT, Link");
    return recorder.get_handle();
endfunction

function void port_end_tr(integer tr_h, uvm_object obj, time end_time);
    uvm_recorder recorder = uvm_recorder::get_recorder_from_handle(tr_h);
    if (end_time == 0)
        end_time = $time; 
    if (recorder != null) begin
        if (obj != null) begin
            obj.record(recorder);
        end
        recorder.close(end_time);
        recorder.free();
    end
endfunction

function void port_begin_recording_cb (uvm_port_component_base port_comp,
                                         string func_name,
                                         uvm_object req,
                                         time begin_time = 0,
                                         time end_time = 0,
                                         bit has_response = 0,
                                         uvm_object rsp = null,
                                         bit has_return_value = 0,
                                         bit return_value = 0,
                                         ref int r_tr_h1,
                                         ref int r_tr_h2);
    string label,ret_str, name_str;

    if (!test_port_plusargs()) return;
    if (!enable_port_recording) return;
    if (!enable_imp_port_recording && port_comp.is_imp()) return;
    if (uvm_verbosity'(port_comp.recording_detail) == UVM_NONE) return;

    ret_str = has_return_value?{"=",return_value?"1":"0"}:"";
    name_str = req==null?"":(req.get_name()==""?req.get_type_name():req.get_name());
    label = {func_name,"(",has_response?"REQ:":"",name_str,")",ret_str};

    r_tr_h1 = port_begin_tr (port_comp, label, begin_time);

    if (has_response) begin
        integer tr_h_2;

        name_str = rsp==null?"":(rsp.get_name()==""?rsp.get_type_name():rsp.get_name());
        label = {func_name,"(RSP:",name_str,")",ret_str};
        r_tr_h2 = port_begin_tr (port_comp, label, begin_time);
    end
endfunction

function void port_end_recording_cb (uvm_port_component_base port_comp,
                                         string func_name,
                                         uvm_object req,
                                         int tr_h1,
                                         int tr_h2,
                                         time begin_time = 0,
                                         time end_time = 0,
                                         bit has_response = 0,
                                         uvm_object rsp = null,
                                         bit has_return_value = 0,
                                         bit return_value = 0);
    static string label, ret_str, name_str;
    static longint pliHandle1 = 0, pliHandle2 = 0;
    uvm_recorder r_lhs, r_rhs;
    uvm_verdi_recorder r_verdi_lhs, r_verdi_rhs;

    if (!test_port_plusargs()) return;
    if (!enable_port_recording) return;
    if (!enable_imp_port_recording && port_comp.is_imp()) return;
    if (uvm_verbosity'(port_comp.recording_detail) == UVM_NONE) return;

    ret_str = has_return_value?{"=",return_value?"1":"0"}:"";
    name_str = req==null?"":(req.get_name()==""?req.get_type_name():req.get_name());
    label = {func_name,"(",has_response?"REQ:":"",name_str,")",ret_str};
    pliHandle1 = uvmPliHandleMap[tr_h1];
    pli_inst.set_label(pliHandle1,label);

    if (has_response) begin
        uvm_recorder recorder1 = uvm_recorder::get_recorder_from_handle(tr_h1);
        uvm_recorder recorder2 = uvm_recorder::get_recorder_from_handle(tr_h2);
        this.establish_link(uvm_related_link::get_link(recorder1,recorder2,"response"));
        this.establish_link(uvm_related_link::get_link(recorder2,recorder1,"request")); 

        name_str = rsp==null?"":(rsp.get_name()==""?rsp.get_type_name():rsp.get_name());
        label = {func_name,"(RSP:",name_str,")",ret_str};
        pliHandle2 = uvmPliHandleMap[tr_h2];
        pli_inst.set_label(pliHandle2,label);
        port_end_tr (tr_h2, rsp, end_time);
    end
    port_end_tr (tr_h1, req, end_time);
endfunction

virtual function void tlm2_begin_recording_cb (uvm_port_component_base port_comp,
                                         string func_name,
                                         uvm_object req,
                                         uvm_tlm_time delay,
                                         bit is_nonblocking,
                                         int begin_phase,
                                         ref int tr_h);
    static longint unsigned pliHandle;
    static string tlm2_delay;
    static uvm_tlm_phase_e tlm2_begin_phase;
    real abs_delay_time;
    string stream_name;

    if (!test_tlm2_port_plusargs()) return;
    if (!enable_tlm2_port_recording) return;
    if (!enable_imp_port_recording && port_comp.is_imp()) return;
    if (uvm_verbosity'(port_comp.recording_detail) == UVM_NONE) return;

    stream_name = port_comp.get_full_name();
    if (stream_name.substr(0,14) == "UVMC_COMP_WITH_") return;

    tr_h = port_begin_tr (port_comp, func_name, 0);
    pliHandle = uvmPliHandleMap[tr_h];
    if (delay) begin
      abs_delay_time = delay.get_abstime(1e-9);
      $sformat(tlm2_delay, "%g ns", abs_delay_time);
      pli_inst.add_attribute_string(pliHandle, tlm2_delay, "tlm2_delay", "");
    end
    if (is_nonblocking) begin
      tlm2_begin_phase = uvm_tlm_phase_e'(begin_phase);
      pli_inst.add_attribute_uvm_tlm_phase(pliHandle, tlm2_begin_phase);
    end
endfunction

virtual function void tlm2_end_recording_cb (uvm_port_component_base port_comp,
                                         string func_name,
                                         uvm_object req,
                                         uvm_tlm_time delay,
                                         int tr_h,
                                         bit is_nonblocking,
                                         int end_phase,
                                         int sync);
    static longint unsigned pliHandle;
    static uvm_tlm_phase_e tlm2_end_phase;
    static uvm_tlm_sync_e tlm2_sync;
    string stream_name;

    if (!test_tlm2_port_plusargs()) return;
    if (!enable_tlm2_port_recording) return;
    if (!enable_imp_port_recording && port_comp.is_imp()) return;
    if (uvm_verbosity'(port_comp.recording_detail) == UVM_NONE) return;

    stream_name = port_comp.get_full_name();
    if (stream_name.substr(0,14) == "UVMC_COMP_WITH_") return;

    if (is_nonblocking) begin
      pliHandle = uvmPliHandleMap[tr_h];
      tlm2_end_phase = uvm_tlm_phase_e'(end_phase);
      tlm2_sync = uvm_tlm_sync_e'(sync);
      pli_inst.add_attribute_uvm_tlm_phase(pliHandle, tlm2_end_phase);
      pli_inst.add_attribute_uvm_tlm_sync(pliHandle, tlm2_sync);
    end

    port_end_tr (tr_h, req, 0);
endfunction
`endif

`ifndef UVM_VCS_RECORD
// 9001130255
virtual function string get_object_id (uvm_object obj);
   return pli_inst.get_object_id(obj);
endfunction
`endif   
endclass : uvm_verdi_tr_database
`endif
