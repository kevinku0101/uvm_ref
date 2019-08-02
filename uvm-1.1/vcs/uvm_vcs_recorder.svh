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
  // Vendors provide subtype implementations and overwrite the
  // <uvm_default_recorder> handle.


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
    return vcs_begin_tr(txtype, stream, nm, label,
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
