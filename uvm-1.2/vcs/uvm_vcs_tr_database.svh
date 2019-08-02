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

//------------------------------------------------------------------------------
// File: Transaction Recording Databases
//
// The UVM "Transaction Recording Database" classes are an abstract representation
// of the backend tool which is recording information for the user.  Usually this
// tool would be dumping information such that it can be viewed with the ~waves~ 
// of the DUT.
//

`include "uvm_vcs_tr_stream.svh"

//------------------------------------------------------------------------------
//
// CLASS: uvm_vcs_tr_database
//
// The ~uvm_vcs_tr_database~ is the default implementation for the
// <uvm_tr_database>.  It provides the ability to store recording information
// into a textual log file.
//
//
   
class uvm_vcs_tr_database extends uvm_tr_database;

   // Variable- m_filename_dap
   // Data Access Protected Filename
   local uvm_simple_lock_dap#(string) m_filename_dap;

   // Variable- m_file
   UVM_FILE m_file;

   `uvm_object_utils_begin(uvm_vcs_tr_database)
   `uvm_object_utils_end

   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Instance name
   function new(string name="unnamed-uvm_vcs_tr_database");
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
      uvm_vcs_tr_stream m_stream = uvm_vcs_tr_stream::type_id::create(name);
      return m_stream;
   endfunction : do_open_stream

   // Function: do_establish_link
   // Establishes a ~link~ between two elements in the database
   //
   protected virtual function void do_establish_link(uvm_link_base link);
      uvm_recorder r_lhs, r_rhs;
      uvm_vcs_recorder r_vcs_lhs, r_vcs_rhs;
      static longint pliHandle1 = 0, pliHandle2 = 0;
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
            $cast(r_vcs_lhs,r_lhs);
            $cast(r_vcs_rhs,r_rhs);
            tr_h1 = r_vcs_lhs.get_handle();
            tr_h2 = r_vcs_rhs.get_handle();
            vcs_link_tr(tr_h1, tr_h2, "child");
         end
      end
   endfunction : do_establish_link

   // Group: Implementation Specific API

function integer port_begin_tr (uvm_port_component_base port_comp,
                                string label,
                                time begin_time);
    return 0;
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
    return;
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
    return;
endfunction
   
endclass : uvm_vcs_tr_database
