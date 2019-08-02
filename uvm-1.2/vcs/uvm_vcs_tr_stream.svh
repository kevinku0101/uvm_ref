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
// File: Transaction Recording Streams
//

typedef class uvm_vcs_recorder;
typedef class uvm_vcs_tr_database;

static integer streamIdArrByName [string];

//------------------------------------------------------------------------------
//
// CLASS: uvm_vcs_tr_stream
//
// The ~uvm_vcs_tr_stream~ is the default stream implementation for the
// <uvm_tr_database>.  
//
//                     

class uvm_vcs_tr_stream extends uvm_tr_stream;

   local uvm_vcs_tr_database m_vcs_db;
   integer stream_id;
   local static integer m_vcs_ids_by_stream[uvm_vcs_tr_stream];
   local static uvm_vcs_tr_stream m_vcs_streams_by_id[integer];
   
   `uvm_object_utils_begin(uvm_vcs_tr_stream)
   `uvm_object_utils_end

   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Instance name
   function new(string name="unnamed-uvm_vcs_tr_stream");
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
       static int streamId=0;
       static string stream_name="";
       static string des_str, comp_str;

       des_str = "";
       comp_str = split_string(stream_type_name);
       if (comp_str!="")
           des_str = {"+description+type=",comp_str};
       if (scope != "")
           stream_name = scope;
       else
           stream_name = stream_type_name;
      $cast(m_vcs_db, db);
      if (m_vcs_db.open_db()) begin
        if (!streamIdArrByName.exists(scope)) begin
            stream_id = vcs_create_stream(stream_name, stream_type_name, scope);
            streamIdArrByName[stream_name] = stream_id;
        end else begin
          stream_id = streamIdArrByName[scope];
        end
      end
   endfunction : do_open

   // Function: do_close
   // Callback triggered via <uvm_tr_database::close_stream>.
   protected virtual function void do_close();
      if (m_vcs_db.open_db())
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
      if (m_vcs_db.open_db())
        $display("  FREE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                  $time,
                  this.get_name(),
                  this.get_stream_type_name(),
                  this.get_scope(),
                  this.get_handle());
      m_vcs_db = null;
      return;
   endfunction : do_free
   
   // Function: do_open_recorder
   // Marks the beginning of a new record in the stream
   //
   // Text-backend specific implementation.
   protected virtual function uvm_recorder do_open_recorder(string name,
                                                           time   open_time,
                                                           string type_name);
      if (m_vcs_db.open_db()) begin
         return uvm_vcs_recorder::type_id::create(name);
      end

      return null;
   endfunction : do_open_recorder

   function integer get_handle();
      if (!is_open() && !is_closed()) begin
        return 0;
      end
      else begin
         integer handle = stream_id;
        
         // Check for the weird case where our handle changed.
         if (m_vcs_ids_by_stream.exists(this) && m_vcs_ids_by_stream[this] != handle)
           m_vcs_streams_by_id.delete(m_vcs_ids_by_stream[this]);

         if (handle>=0) begin 
             m_vcs_streams_by_id[handle] = this;
             m_vcs_ids_by_stream[this] = handle;
         end

         return handle;
      end
   endfunction : get_handle

endclass : uvm_vcs_tr_stream
