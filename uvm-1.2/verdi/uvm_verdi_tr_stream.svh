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
`ifndef UVM_VERDI_TR_STREAM_SVH
`define UVM_VERDI_TR_STREAM_SVH

//------------------------------------------------------------------------------
// File: Transaction Recording Streams
//

typedef class uvm_verdi_recorder;
typedef class uvm_verdi_tr_database;

static longint unsigned streamArrByName [string];
static bit hooks_version_flag = 0;

//------------------------------------------------------------------------------
//
// CLASS: uvm_verdi_tr_stream
//
// The ~uvm_verdi_tr_stream~ is the default stream implementation for the
// <uvm_text_tr_database>.  
//
//                     
static integer verdi_recorder_counter = 0;
class uvm_verdi_tr_stream extends uvm_tr_stream;

   // Variable- m_verdi_db
   // Internal reference to the text-based backend
   local uvm_verdi_tr_database m_verdi_db;
   longint unsigned stream_id;
   local static integer m_verdi_ids_by_stream[uvm_verdi_tr_stream];
   local static uvm_verdi_tr_stream m_verdi_streams_by_id[integer];
   
   
   `uvm_object_utils_begin(uvm_verdi_tr_stream)
   `uvm_object_utils_end

   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Instance name
   function new(string name="unnamed-uvm_verdi_tr_stream");
      super.new(name);
   endfunction : new

   // Group: Implementation Agnostic API

   function string split_string(string t_str);
    int s = 0, e = 0;
    string values[$];
    string ret_str;

    for(s=0; s<t_str.len(); ++s)
        if (t_str[s] == ":") break;
    ret_str = t_str.substr(s+1,t_str.len()-1);
    return ret_str;
   endfunction

   // Function: do_open
   // Callback triggered via <uvm_tr_database::open_stream>.
   //
   protected virtual function void do_open(uvm_tr_database db,
                                           string scope,
                                           string stream_type_name);
       static string stream_name="";
       static string des_str, comp_str;

       des_str = "";
       comp_str = split_string(stream_type_name);
// 9001353389
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       if (comp_str!="")
           des_str = {"+description+type=",comp_str};
`else
       if (comp_str!="")
           des_str = {"type=",comp_str};
`endif
       if (scope != "")
           stream_name = scope;
       else
           stream_name = stream_type_name;
      $cast(m_verdi_db, db);
      if (m_verdi_db.open_db()) begin
        if (!streamArrByName.exists(scope)) begin
            if (verdi_recorder_counter==0)
                $display("*Verdi* Enable Verdi Recorder."); 
            verdi_recorder_counter++;
            stream_name = scope;
            if (des_str!="")
                stream_id = pli_inst.create_stream_begin(stream_name,des_str);
            else
                stream_id = pli_inst.create_stream_begin(stream_name);
            if (stream_id==0) begin
                $display("Failed to create stream!\n");
                if (is_verdi_debug_enabled()) begin
                    $fdisplay(file_h,"Failed CREATE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                    $time,
                    this.get_name(),
                    stream_type_name,
                    scope,
                    this.get_handle());
                    $fdisplay(file_h,"Failed create_stream @%0t stream_name=%s streamId=%0d",$realtime,stream_name,stream_id);
                end
                return;
            end

`ifndef UVM_NO_VERDI_DPI
          verdi_dump_vif_name(stream_name, stream_id);
`endif
  
            pli_inst.create_stream_end(stream_id);
            streamArrByName[stream_name] = stream_id;
        end else begin
          stream_id = streamArrByName[scope];
        end
        if (hooks_version_flag==0) begin
            $display("Info: Verdi UVM 1.2 Hooks File 06/17/2014 ");
            hooks_version_flag = 1;
        end
        if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"  CREATE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                  $time,
                  this.get_name(),
                  stream_type_name,
                  scope,
                  this.get_handle());
            $fdisplay(file_h,"create_stream @%0t stream_name=%s streamId=%0d",$realtime,stream_name,stream_id);
        end
      end
   endfunction : do_open

   // Function: do_close
   // Callback triggered via <uvm_tr_database::close_stream>.
   protected virtual function void do_close();
      if (m_verdi_db.open_db())
        $display("  CLOSE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                  $time,
                  this.get_name(),
                  this.get_stream_type_name(),
                  this.get_scope(),
                  this.get_handle());
   endfunction : do_close
      
   // Function: do_free
   // Callback triggered via <uvm_tr_database::free_stream>.
   //
   protected virtual function void do_free();
      if (m_verdi_db.open_db())
        $display("  FREE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                  $time,
                  this.get_name(),
                  this.get_stream_type_name(),
                  this.get_scope(),
                  this.get_handle());
      m_verdi_db = null;
      return;
   endfunction : do_free
   
   // Function: do_open_recorder
   // Marks the beginning of a new record in the stream
   //
   // Text-backend specific implementation.
   protected virtual function uvm_recorder do_open_recorder(string name,
                                                           time   open_time,
                                                           string type_name);
      process p;
      string rand_state;
      uvm_recorder recorder = null;
      if (m_verdi_db.open_db()) begin
         if (p != null)
             rand_state = p.get_randstate();
         recorder = uvm_verdi_recorder::type_id::create(name);
         if (p != null)
             p.set_randstate(rand_state);
      end
      return recorder;
   endfunction : do_open_recorder

   function integer get_handle();
      if (!is_open() && !is_closed()) begin
        return 0;
      end
      else begin
         integer handle = stream_id;
        
         // Check for the weird case where our handle changed.
         if (m_verdi_ids_by_stream.exists(this) && m_verdi_ids_by_stream[this] != handle)
           m_verdi_streams_by_id.delete(m_verdi_ids_by_stream[this]);

         if (handle>=0) begin 
             m_verdi_streams_by_id[handle] = this;
             m_verdi_ids_by_stream[this] = handle;
         end

         return handle;
      end
   endfunction : get_handle

endclass : uvm_verdi_tr_stream
`endif
