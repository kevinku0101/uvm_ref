///-------------------------------------------------------------
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


//------------------------------------------------------------------------------
//
// CLASS: uvm_vcs_recorder
//
// The uvm_vcs_recorder class provides a policy object for recording <uvm_objects>.
// The policies define VCS recording for DVE.
//
// A default recorder instance, <uvm_default_recorder>, is used when the
// <uvm_object::record> is called without specifying a recorder.
//
//------------------------------------------------------------------------------

`include "uvm_vcs_tr_database.svh"

class uvm_vcs_recorder extends uvm_recorder;

  `uvm_object_utils(uvm_vcs_recorder)

  //------------------------------
  // VCS Implementation of
  // Group- Vendor-Independent API
  // 
  // Couple this with the following VCS files:
  // msglog.svh
  // uvm_msglog_report_server.sv
  // uvm_vcs_record_interface.sv
  //------------------------------

  // UVM provides only a text-based default implementation.
  // Vendors provide subtype implementations.

  //Temporary Changes
  string filename;
  UVM_FILE file;

  uvm_vcs_tr_database m_vcs_db;

  // Function: new
  //
  // Creates a new objection instance. 
  //
  function new(string name = "uvm_vcs_recorder");
    super.new(name);
  endfunction

  // Function: open_file
  //
  // Opens the file in the <filename> property and assigns to the
  // file descriptor <file>.
  //
  virtual function bit open_file();
    if (file == 0)
      file = $fopen(filename);
    return (file > 0);
  endfunction

   // Function: do_open
   // Callback triggered via <uvm_tr_stream::open_recorder>.
   //
   // VPD-backend specific implementation.
   protected virtual function void do_open(uvm_tr_stream stream,
                                             time open_time,
                                             string type_name);
      integer handle = 0, stream_id = 0;
      uvm_vcs_tr_stream vcs_stream;
      $cast(m_vcs_db, stream.get_db());

      if (m_vcs_db.open_db()) begin
        $cast(vcs_stream,stream);
        stream_id = vcs_stream.get_handle();
        handle = begin_tr("txtype", stream_id, this.get_name() /* nm */, type_name /* label */, "" /* desc */, open_time);
        if (handle==0) begin
          $display("Failed to create transaction!");
          return;
        end
      end
    endfunction

   // Function: do_close
   // Callback triggered via <close>.
   //
   // VPD-backend specific implementation.
   protected virtual function void do_close(time close_time);
      if (m_vcs_db.open_db()) begin
          end_tr(this.get_handle(), close_time); 
      end
   endfunction : do_close

   // Function: do_free
   // Callback triggered via <free>.
   //
   // VPD-backend specific implementation.
   protected virtual function void do_free();
      m_vcs_db = null;
   endfunction : do_free

    // Function: do_record_field
   // Records an integral field (less than or equal to 4096 bits).
   //
   // VPD-backend specific implementation.
   protected virtual function void do_record_field(string name,
                                                   uvm_bitstream_t value,
                                                   int size,
                                                   uvm_radix_enum radix);
     set_attribute2(this.get_handle(), name, value, radix, size);
   endfunction : do_record_field

   // Function: do_record_field_int
   // Records an integral field (less than or equal to 64 bits).
   //
   // VPD-backend specific implementation.
   protected virtual function void do_record_field_int(string name,
                                                       uvm_integral_t value,
                                                       int          size,
                                                       uvm_radix_enum radix);
     set_attribute2(this.get_handle(), name, value, radix, size);
   endfunction : do_record_field_int

   // Function: do_record_field_real
   // Record a real field.
   //
   // VPD-backened specific implementation.
   protected virtual function void do_record_field_real(string name,
                                                        real value);
     bit [63:0] ivalue = $realtobits(value);
     set_attribute2(this.get_handle(), name, ivalue, UVM_REAL, 64);
   endfunction : do_record_field_real

   // Function: do_record_object
   // Record an object field.
   //
   // VPD-backend specific implementation.
   //
   // The method uses <identifier> to determine whether or not to
   // record the object instance id, and <recursion_policy> to
   // determine whether or not to recurse into the object.
   protected virtual function void do_record_object(string name,
                                                    uvm_object value);
     string str;
     $swrite(str, "@%0d", value.get_inst_id());
     m_set_attribute(this.get_handle(), name, str);
   endfunction : do_record_object

   // Function: do_record_string
   // Records a string field.
   //
   // VPD-backend specific implementation.
   protected virtual function void do_record_string(string name,
                                                    string value);
     m_set_attribute(this.get_handle(), name, value);
   endfunction : do_record_string

   // Function: do_record_time
   // Records a time field.
   //
   // VPD-backend specific implementation.
   protected virtual function void do_record_time(string name,
                                                    time value);
     set_attribute2(this.get_handle(), name, value, UVM_TIME, 64);
   endfunction : do_record_time

   // Function: do_record_generic
   // Records a name/value pair, where ~value~ has been converted to a string.
   //
   // VPD-backend specific implementation.
   protected virtual function void do_record_generic(string name,
                                                     string value,
                                                     string type_name);
     m_set_attribute(this.get_handle(), name, value);
   endfunction : do_record_generic

  // Function: create_stream
  //
  //
  virtual function integer create_stream (string name,
                                 string t,
                                 string scope);
    return vcs_create_stream(name, t, scope);
  endfunction

   
  // Function: m_set_attribute
  //
  //
  virtual function void m_set_attribute (integer txh,
                                 string nm,
                                 string value);
    vcs_m_set_attribute(txh, nm, value);
  endfunction
  
  
  // Function: set_attribute
  //
  //
  virtual function void set_attribute (integer txh,
                               string nm,
                               logic [1023:0] value,
                               uvm_radix_enum radix,
                               integer numbits=1024);
    string rdx=uvm_radix_to_string(radix);
    vcs_set_attribute_by_name(txh, nm, value, rdx, numbits);
  endfunction

  // Function: set_attribute
  //
  //
  virtual function void set_attribute2 (integer txh,
                               string nm,
                               uvm_bitstream_t value,
                               uvm_radix_enum radix,
                               integer numbits=1024);
    string rdx=uvm_radix_to_string(radix);
    vcs_set_attribute_by_name(txh, nm, value, rdx, numbits);
  endfunction
  
  
  // Function: check_handle_kind
  //
  //
  virtual function integer check_handle_kind (string htype, integer handle);
    return vcs_check_handle_kind (htype, handle);
  endfunction
  
  
  // Function: begin_tr
  //
  //
  virtual function integer begin_tr(string txtype,
                                     integer stream,
                                     string nm,
                                     string label="",
                                     string desc="",
                                     time begin_time=0);
    return vcs_begin_tr(txtype, get_handle(), stream, nm, label,
                                 desc, begin_time);
  endfunction
  
  
  // Function: end_tr
  //
  //
  virtual function void end_tr (integer handle, time end_time=0);
    vcs_end_tr(handle, end_time);
  endfunction
  
  
  // Function: link_tr
  //
  //
  virtual function void link_tr(integer h1,
                                 integer h2,
                                 string relation="");
    vcs_link_tr(h1, h2, relation);
  endfunction
  
  
  
  // Function: free_tr
  //
  //
  virtual function void free_tr(integer handle);
    vcs_free_tr(handle);
  endfunction
  

endclass
