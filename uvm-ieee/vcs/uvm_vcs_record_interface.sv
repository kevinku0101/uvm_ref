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

`ifndef UVM_VCS_RECORD_INTERFACE
`define UVM_VCS_RECORD_INTERFACE

`include "macros/uvm_global_defines.svh"
//----------------------------------------------------------------------------
// msglog_msgname
//----------------------------------------------------------------------------
class msglog_msgname;
  string  name;
  int     stream_id;

  function new(string name, int stream_id);
    this.name        = name;  
    this.stream_id   = stream_id;
  endfunction
endclass

//----------------------------------------------------------------------------
// Class: msglog
//----------------------------------------------------------------------------
//
// Group: VCS Transaction Recording
//
// Variable: +UVM_TR_RECORD
// To enable recording for DVE waveform and transaction pane:
//
// Compilation  
//    On the "vcs" compile line, compile with UVM from VCS install: 
//    -ntb_opts uvm
//    +define+UVM_TR_RECORD <-debug_pp|-debug|-debug_all>
//
//    - Note: When defining UVM_TR_RECORD, you MUST also compile with 
//      debug enabled (-debug_pp|-debug|-debug_all) 
//
// Runtime
//    Add "+UVM_TR_RECORD" as a simulation argument for transaction recording
//
// Variable: +UVM_LOG_RECORD
//    Add "+UVM_LOG_RECORD" as a simulation argument for message log recording
//
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
class msglog;
  static int cur_stream_id = 0;

  static string         stream_aa[int];
  static msglog_msgname msgname_aa[int];
  static string         xtend_msg_aa[int];

  static int recording_detail_fptr = 0;  // default is to not record

  // create_stream
  static function int create_stream(string name);
    // associate the msglog stream with an id/handle and store
    cur_stream_id++;
    stream_aa[cur_stream_id] = name;
    return cur_stream_id;
  endfunction
 
  // create_msgname
  // UVM 1.2 uses a recorder instance for each transaction
  // Use the recorder ID as the index (and no longer a counter)
  static function int create_msgname(int txh, string name, int stream_id);
    msglog_msgname mname;
    if ( !(stream_aa.exists(stream_id)) ) return 0; // error check
    // associate the msglog msgname with an id/handle and store
    mname = new(name, stream_id);
    msgname_aa[txh] = mname;
    return txh;
  endfunction
 
  // begin_transaction
  static function bit begin_transaction(int msgname_id, string header="", string msg="");
    string         stream, msgname;

    if (!(decode_msgname_id(msgname_id, stream, msgname))) return 0;

    if (recording_detail_fptr != 0)
      $fdisplay(recording_detail_fptr,"@ %0t: %0s (%0d):  Stream: %0s   Msgname: %0s", $time, msg, msgname_id, stream, msgname);

    msgname = msglog::map_name(msgname);
    stream  = msglog::map_name(stream);
    $vcdplusmsglog(stream, _vcs_msglog::XACTION, msgname, _vcs_msglog::NORMAL, header, msg, _vcs_msglog::START);
    xtend_msg_aa[msgname_id] = ""; 
    return 1;
  endfunction

  // xtend_transaction_msg -- build message to display during end_transaction
  static function bit xtend_transaction_msg(int msgname_id, string msg);

    if (!(xtend_msg_aa.exists(msgname_id))) return 0; // error check

    if (recording_detail_fptr != 0)
      $fdisplay(recording_detail_fptr,"@ %0t: Xtend (%0d): %0s", $time, msgname_id, msg); 

    if (xtend_msg_aa[msgname_id] != "")
      xtend_msg_aa[msgname_id] = {xtend_msg_aa[msgname_id],"<br>",msg};
    else
      xtend_msg_aa[msgname_id] = msg;

    return 1;
  endfunction

  // end_transaction
  static function bit end_transaction(int msgname_id, string msg="End transaction");
    string         stream, msgname, tr;

    if (!(decode_msgname_id(msgname_id, stream, msgname))) return 0;

    if (recording_detail_fptr != 0)
      $fdisplay(recording_detail_fptr,"@ %0t: %0s (%0d):  Stream: %0s   Msgname: %0s", $time, msg, msgname_id, stream, msgname);

    msgname = msglog::map_name(msgname);
    stream  = msglog::map_name(stream);
    tr = xtend_msg_aa[msgname_id];
    if (tr != "") begin // sequence_items will contain values, sequences will not
      if (msg != "") 
        msg = {"<pre>", tr, "</pre><br>", msg};
      else
        msg = {"<pre>", tr, "</pre>"};
    end
    $vcdplusmsglog(stream, _vcs_msglog::XACTION, msgname, _vcs_msglog::NORMAL, "", msg, _vcs_msglog::FINISH);

    msgname_aa.delete(msgname_id); //free memory since transaction is complete
    xtend_msg_aa.delete(msgname_id); //free memory since transaction is complete
    return 1;
  endfunction

  // link_transaction
  // link_transaction
  static function bit link_transaction(int h1, int h2, string relation="", string msg="Link");
    string      tmp, stream_link, stream, msgname1, msgname2;

    if (relation != "child") return 0;

    if (!(decode_msgname_id(h1, stream_link, msgname1))) return 0;
    if (!(decode_msgname_id(h2, stream, msgname2))) return 0;

    if (recording_detail_fptr != 0)
      $fdisplay(recording_detail_fptr,"@ %0t: %0s (%0d)&(%0d):  Stream: %0s   Msgname2: %0s  %0s of Stream:%0s Msgname1: %0s", $time, msg, h1, h2, stream, msgname2, relation, stream_link, msgname1);

    stream_link = msglog::map_name(stream_link);
    msgname1 = msglog::map_name(msgname1);
    msgname2 = msglog::map_name(msgname2);
    stream   = msglog::map_name(stream);
    tmp      =  {stream_link,".",msgname1};


    $vcdplusmsglog(stream, _vcs_msglog::XACTION, msgname2, _vcs_msglog::NORMAL, _vcs_msglog::CHILD, tmp);
    return 1;
  endfunction

  // decode_msgname_id
  static function bit decode_msgname_id(input int msgname_id, output string stream, output string msgname);
    msglog_msgname mname;

    if ( !(msgname_aa.exists(msgname_id)) || !(stream_aa.exists(msgname_aa[msgname_id].stream_id))) return 0; // error check 
     
    mname   = msgname_aa[msgname_id];
    msgname = mname.name; 
    stream  = stream_aa[mname.stream_id]; 
    return 1;
  endfunction

 // msglog::map_name
 static function string map_name(string text);
   string result;
   if (text[0]>="0" && text[0]<="9")  // msglog does not accept 0-9 in the first character
     result = {"_",text};  
   else 
     result = text;

   foreach(result[i]) begin
     if (!( (result[i]>="a" && result[i]<="z") ||
            (result[i]>="A" && result[i]<="Z") ||
            (result[i]>="0" && result[i]<="9") ||
            (result[i]=="_")))
       if (result[i]==".") 
        result[i] = "$";  // use "#" to denote testbench logical hierarchy separator
       else  
        result[i] = "_";
   end
   return result;
 endfunction

endclass

//----------------------------------------------------------------------------
// vcs_smartlog_catcher - used to trap uvm_report calls
// and redirect them to VPD dumping.
// Should be used in conjunction with +smartlog run-time switch 
//----------------------------------------------------------------------------
class vcs_smartlog_catcher extends uvm_report_catcher;
   static int seen = 0;

   function new(string name = "uvm_report_catcher");
     super.new(name);
   endfunction    

   virtual function action_e catch();
      string stream, msg_name, msg, finfo, title;
      uvm_report_object client;
      $sformat(stream, "LOG.%0s", get_id());
      stream   = msglog::map_name(stream);  
      msg_name = "report_server";
      client = get_client();
      if(client.get_full_name() != "")
        title = client.get_full_name();
      else
        title = "reporter";
      if (get_fname() != "") 
	finfo = $psprintf("%s(%0d):", get_fname(), get_line());
      else
        finfo = "";
      msg = {"<html>", finfo, "<pre>", get_message(), "</pre></html>"};
      `msglog_decode(stream, get_verbosity(), msg_name, get_severity(), title, msg)
      catch = action_e'(get_action());
      catch = ((catch == UNKNOWN_ACTION) ? THROW : catch);
   endfunction
endclass

//----------------------------------------------------------------------------
// set_recording_detail_file -- make global to mimic set_config_*()
//----------------------------------------------------------------------------
static function void set_recording_detail_file(string filename="");
  // Register the tr to files
  if ($test$plusargs("UVM_TR_RECORD")) begin
    if (filename != "") begin
     msglog::recording_detail_fptr = $fopen(filename, "w");
     if (msglog::recording_detail_fptr != 0) begin 
      $fdisplay(msglog::recording_detail_fptr, "@ %0t: [Recording detail] File '%0s' opened", $time, filename);
     end
     else begin  
      msglog::recording_detail_fptr=1;  
      $fdisplay(msglog::recording_detail_fptr, "@ %0t: [Recording detail] Could NOT open file '%0s', recording will be to stdout", $time, filename);
     end
    end
    else begin
      msglog::recording_detail_fptr=1;
      $fdisplay(msglog::recording_detail_fptr, "@ %0t: [Recording detail] NO file provided, recording will be to stdout", $time);
    end

    uvm_config_int::set(uvm_root::get(), "*", "recording_detail", UVM_FULL);
  end

endfunction



//----------------------------------------------------------------------------
// VCS Implementation of "Group-Vendor-Independent API" defined in uvm_recorder.svh  
//----------------------------------------------------------------------------

// vcs_create_stream
// -----------------
function integer vcs_create_stream (string name,
                                    string t,
                                    string scope);
  string scope_with_name;

  //if (scope != "") scope_with_name = {scope, ".", name};
  if (scope != "") scope_with_name = scope;
  else scope_with_name = name;

  vcs_create_stream = msglog::create_stream(scope_with_name);

  return vcs_create_stream;
endfunction

/* No longer needed per UVM-1.0 Group-Vendor-Independent API
// uvm_set_index_attribute_by_name
// -------------------------------
function void uvm_set_index_attribute_by_name (integer txh,
                                         string nm,
                                         int index,
                                         logic [1023:0] value,
                                         string radix,
                                         integer numbits=32);
  string nm_with_index;
  $sformat(nm_with_index, "%s[%0d]", nm, index);
  vcs_set_attribute_by_name(txh, nm_with_index, value, radix, numbits);
endfunction
*/


// vcs_m_set_attribute
// -------------------
function void vcs_m_set_attribute (integer txh,
                                   string nm,
                                   string value);

  string msg;
  $sformat(msg, "%0s: %0s", nm, value);
  void'(msglog::xtend_transaction_msg(txh, msg));  
endfunction


// vcs_set_attribute_by_name
// -------------------------
function void vcs_set_attribute_by_name (integer txh,
                                         string nm,
                                         uvm_bitstream_t value,
                                         string radix,
                                         integer numbits=0);
  uvm_bitstream_t mask;
  string msg;
 
  mask = {`UVM_MAX_STREAMBITS{1'b1}};
  mask <<= numbits;
  mask = ~mask;

  case(radix)
    "b": $sformat(msg, "%0s: %0b", nm, value&mask); // bin
    "o": $sformat(msg, "%0s: %0o", nm, value&mask); // oct
    "d": $sformat(msg, "%0s: %0d", nm, value&mask); // dec
    "t": $sformat(msg, "%0s: %0d", nm, value&mask); // time
    "g": $sformat(msg, "%0s: %0f", nm, value&mask); // real
    "x": $sformat(msg, "%0s: %0x", nm, value&mask); // hex
    "s": $sformat(msg, "%0s: %0s", nm, value&mask); // string/enum
    "u": $sformat(msg, "%0s: %0t", nm, value&mask); // unsigned
    default: $sformat(msg, "%0s: %0x", nm, value&mask); // default
  endcase
 
  void'(msglog::xtend_transaction_msg(txh, msg));  
endfunction


// vcs_check_handle_kind
// ---------------------
function integer vcs_check_handle_kind (string htype, integer handle);
  integer handle_check_ok;

  handle_check_ok = 0;

  if ($isunknown(handle)) return 0; // check for X or Z to avoid VCS warnings

  if ((htype == "Fiber") && (msglog::stream_aa.exists(handle))) 
     handle_check_ok = 1;
  else if ((htype == "Transaction") && (msglog::msgname_aa.exists(handle)))
     handle_check_ok = 1;

  return handle_check_ok;
endfunction


// vcs_begin_tr
// ------------
function integer vcs_begin_tr(string txtype,
			      integer txh,
                              integer stream,
                              string nm,
                              string label="",
                              string desc="",
                              time begin_time=0
                              );
  // ignore txtype since we are not creating parent/child relationships with this code yet

  vcs_begin_tr = msglog::create_msgname(txh, nm, stream);  
  if (vcs_begin_tr == 0) return 0;   //vcs_begin_tr == 0 indicates unsuccesful due to no associated stream
  
  // open_recorder() passes an empty 'desc' but the description in 'kind' and this gets into 'label'
  if (desc == "")
     void'(msglog::begin_transaction(vcs_begin_tr, nm, label));  
  else
     void'(msglog::begin_transaction(vcs_begin_tr, nm, desc));  

  return vcs_begin_tr;
endfunction


// vcs_end_tr
// ----------
function void vcs_end_tr (integer handle, time end_time=0);
  void'(msglog::end_transaction(handle, ""));
endfunction


// vcs_link_tr
// -----------
function void vcs_link_tr(integer h1, integer h2, string relation="");
  void'(msglog::link_transaction(h1, h2, relation));
endfunction


// vcs_free_tr
// ---------------------------
function void vcs_free_tr(integer handle);
  msglog::msgname_aa.delete(handle);
endfunction

    
`endif // UVM_VCS_RECORD_INTERFACE
