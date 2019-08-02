//-------------------------------------------------------
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
`ifndef UVM_VERDI_RECORDER_SVH
`define UVM_VERDI_RECORDER_SVH

`include "uvm_verdi_pli_base.svh"
//------------------------------------------------------------------------------
//
// CLASS: uvm_verdi_recorder
//
// The uvm_verdi_recorder class provides a policy object for recording <uvm_objects>.
// The policies define Verdi recording.
//
// A default recorder instance, <uvm_default_recorder>, is used when the
// <uvm_object::record> is called without specifying a recorder.
//
//------------------------------------------------------------------------------
// Modified by Verdi
typedef class verdi_cmdline_processor;

static longint unsigned streamArrByName [string];
static string  streamArrByHandle [longint unsigned];
static string  transactionArrByHandle [integer];
`ifdef VERDI_RECORD_RELATION
static longint transactionArrByInstId [integer];
static integer unlinkObjTable [integer];
static string unlinkRelTable [integer];
`endif
static longint unsigned uvmPliHandleMap[integer];
static integer uvmHandle = 0;
static bit hooks_version_flag = 0;
static bit plusargs_tested = 0;
static bit enable_port_recording = 0;
static bit enable_tlm2_port_recording = 0;
static bit enable_imp_port_recording = 0;
static bit enable_verdi_debug = 0;
static int file_h = 0;
static string debug_log_file_name = "verdi_recorder_debug.log";
static uvm_verdi_pli_base pli_inst = uvm_verdi_pli_base::get_inst();

function bit open_debug_file();
  if (file_h == 0)
      file_h = $fopen(debug_log_file_name);
  return (file_h > 0);
endfunction

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


class uvm_verdi_recorder extends uvm_recorder;
  //------------------------------
  // VERDI Implementation of
  // Group- Vendor-Independent API
  // 
  //------------------------------

  // UVM provides only a text-based default implementation.
  // Vendors provide subtype implementations and overwrite the
  // <uvm_default_recorder> handle.

  integer verdi_recorder_counter = 0;
  // Function: new
  //
  // Creates a new objection instance. 
  //
  function new(string name = "uvm_verdi_recorder");
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

  function string split_string(string t_str);
    int s = 0, e = 0;
    string values[$];
    string ret_str;

    for(s=0; s<t_str.len(); ++s)
        if (t_str[s] == ":") break;
    ret_str = t_str.substr(s+1,t_str.len()-1);
    return ret_str;
  endfunction 

  // Function: create_stream
  //
  //
  virtual function integer create_stream (string name,
                                 string t,
                                 string scope);
  static longint unsigned streamId=0;
  static string stream_name="";
  static string des_str, comp_str;

  if (verdi_recorder_counter==0)
      $display("*Verdi* Enable Verdi Recorder.");
  verdi_recorder_counter++; 
  des_str = "";
  comp_str = split_string(t);
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
     stream_name = name;
  if (!streamArrByName.exists(stream_name)) begin

          if (des_str!="")
              streamId = pli_inst.create_stream_begin(stream_name,des_str);
          else
              streamId = pli_inst.create_stream_begin(stream_name);
          if (streamId==0) begin
              $display("Failed to create stream!\n");
              if (is_verdi_debug_enabled()) begin
                  $fdisplay(file_h,"Failed create_stream: name=%s t=%s scope=%s real_time=%0d",name,t,scope,$time);
                  $fdisplay(file_h,"Failed create_stream: stream_name=%s stream=%0d",stream_name,streamId);
              end
              return streamId;
          end

`ifndef UVM_NO_VERDI_DPI
          verdi_dump_vif_name(stream_name, streamId);
`endif

          streamArrByName[stream_name] = streamId;
          streamArrByHandle[streamId] = stream_name;
          pli_inst.create_stream_end(streamId);
  end
  else begin
          streamId = streamArrByName[stream_name];
  end
  if (hooks_version_flag==0) begin
      $display("Info: Verdi UVM 1.1d Hooks File 07/11/2013 ");
      hooks_version_flag = 1;
  end
  if (is_verdi_debug_enabled()) begin
      $fdisplay(file_h,"create_stream: name=%s t=%s scope=%s real_time=%0d",name,t,scope,$time);
      $fdisplay(file_h,"create_stream: stream_name=%s stream=%0d",stream_name,streamId);
  end
  return streamId;
  endfunction

   
  // Function: m_set_attribute
  //
  //
  virtual function void m_set_attribute (integer txh,
                                 string nm,
                                 string value);
  longint unsigned pliHandle = 0;

  pliHandle = uvmPliHandleMap[txh];
  if (open_file())
      $fdisplay(file,"  SET_ATTR: {TXH:%-5d NAME:%s VALUE:%s}", pliHandle,nm,value);
  if (is_verdi_debug_enabled()) begin
      $fdisplay(file_h,"m_set_attribute: txh=%0d nm=%s value=%s",pliHandle,nm,value);
  end
  endfunction
 
  virtual function void string_to_enum(longint unsigned txh,string val_name,string nm);
      static uvm_severity_type severity_type;
      static uvm_verbosity verbosity_type;
      static string attr_name;
      static longint unsigned st_txh=0;

      st_txh = txh; 
      if (nm=="severity"||nm=="uvm_severity") begin
          case (val_name)
            "UVM_INFO" : severity_type = UVM_INFO;
            "UVM_WARNING" : severity_type = UVM_WARNING;
            "UVM_ERROR" : severity_type = UVM_ERROR;
            "UVM_FATAL" : severity_type = UVM_FATAL;
          endcase
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",nm);
`else
       attr_name = nm;
`endif
//
          pli_inst.add_attribute_severity_type(st_txh, severity_type, attr_name);
      end if (nm=="verbosity"||nm=="uvm_verbosity") begin
          case (val_name)
            "UVM_NONE" : verbosity_type = UVM_NONE;
            "UVM_LOW" : verbosity_type = UVM_LOW;
            "UVM_MEDIUM" : verbosity_type = UVM_MEDIUM;
            "UVM_HIGH" : verbosity_type = UVM_HIGH;
            "UVM_FULL" : verbosity_type = UVM_FULL;
            "UVM_DEBUG" : verbosity_type = UVM_DEBUG;
          endcase
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",nm);
`else
       attr_name = nm;
`endif
//
          pli_inst.add_attribute_verbosity_type(st_txh, verbosity_type, attr_name);
      end    
  endfunction
 
  
  // Function: set_attribute
  //
  //
  virtual function void set_attribute (integer txh,
                               string nm,
                               logic [1023:0] value,
                               uvm_radix_enum radix,
                               integer numbits=1024);
    string stream_name = "", val_str = "";
    static string attr_name,numbits_name,val_name,tmp_nm;
    integer stream_handle = 0;
    static string real_str; 
    static longint unsigned pliHandle = 0;
`ifdef VERDI_RECORD_RELATION
    int snps_inst_id_val = 0;
    integer unlink_inst_id = 0;
    string unlink_relation;
    longint unsigned pliHandle2 = 0;
`endif
    static logic [1023:0] st_value;
    static string st_val_name="";
    static real st_real;

    pliHandle = uvmPliHandleMap[txh];
    if (pliHandle==0) 
        return;
    tmp_nm = nm;
    if (tmp_nm=="0")
        tmp_nm = "Error_0";
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",tmp_nm);
       $sformat(numbits_name,"+numbit+%0d",numbits);
`else
       attr_name = tmp_nm;
       $sformat(numbits_name,"%0d",numbits);
`endif
//
`ifdef VERDI_RECORD_RELATION
    if (nm=="snps_inst_id") begin
        snps_inst_id_val = value;
        transactionArrByInstId[snps_inst_id_val] = pliHandle;
        unlink_inst_id = unlinkObjTable[snps_inst_id_val];
        if (unlink_inst_id!=0) begin
            pliHandle2 = transactionArrByInstId[unlink_inst_id];
            if (pliHandle2!=0) begin
                unlink_relation = unlinkRelTable[snps_inst_id_val];
                pli_inst.link_tr(unlink_relation,pliHandle,pliHandle2);
                unlinkObjTable.delete(snps_inst_id_val);
                unlinkRelTable.delete(snps_inst_id_val);
            end 
        end
    end
`endif
    st_value = value;
    case (radix)
      UVM_BIN      : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+bin", numbits_name);
      UVM_DEC      : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+dec", numbits_name);
      UVM_UNSIGNED : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "", numbits_name);
      UVM_UNFORMAT2: pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+bin", numbits_name);
      UVM_UNFORMAT4: pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+bin", numbits_name);
      UVM_OCT      : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+oct", numbits_name);
      UVM_HEX      : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+hex", numbits_name);
      UVM_STRING   : begin
                       $sformat(val_name,"%0s",value);
                       if (nm=="severity"||nm=="verbosity"||nm=="uvm_severity"||nm=="uvm_verbosity") begin
                           string_to_enum(pliHandle,val_name,nm);
                       end else begin
                           st_val_name = val_name;
                           pli_inst.add_attribute_string(pliHandle, st_val_name, attr_name, numbits_name);
                       end
                     end
      UVM_TIME     : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "+radix+dec", numbits_name); 
      UVM_ENUM     : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "", numbits_name);
      UVM_REAL     : begin
                       st_real = $bitstoreal(value);
                       pli_inst.add_attribute_real(pliHandle, st_real, attr_name, numbits_name);
                     end
      UVM_REAL_DEC : begin
                       st_real = $bitstoreal(value);
                       pli_inst.add_attribute_real(pliHandle, st_real, attr_name, numbits_name);
                     end
      UVM_REAL_EXP : begin
                       st_real = $bitstoreal(value);
                       pli_inst.add_attribute_real(pliHandle, st_real, attr_name, numbits_name);
                     end
      UVM_NORADIX  : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "", numbits_name);
      default      : pli_inst.add_attribute_logic(pliHandle, st_value, attr_name, "", numbits_name);
    endcase
    if (is_verdi_debug_enabled()) begin
        val_str = "";
        $sformat(val_str,"%0s",value);
        $fdisplay(file_h,"set_attribute: txh=%0d nm=%s value=%0d radix=%s numbits=%0d",pliHandle,nm,value,radix,numbits);
        if (value!=13)
            $fdisplay(file_h,"set_attribute: value string=%s",val_str);
    end
  endfunction
  
  
  // Function: check_handle_kind
  //
  //
  virtual function integer check_handle_kind (string htype, integer handle);
  longint unsigned pliHandle = 0;
  int handle_val = 0;

  if (handle>=0) begin
      if (uvmPliHandleMap.exists(handle))
          pliHandle = uvmPliHandleMap[handle];
  end
  handle_val = handle;
  if (is_verdi_debug_enabled()) begin
      if (htype=="Transaction")
          $fdisplay(file_h,"check_handle_kind: htype=%s handle=%0d",htype,pliHandle);
      if (htype=="Fiber")
          $fdisplay(file_h,"check_handle_kind: htype=%s handle=%0d",htype,handle);
  end
  case (htype)
    "TRANSACTION":
      return transactionArrByHandle.exists(handle_val);
    "Transaction":
      return transactionArrByHandle.exists(handle_val);
    "transaction":
      return transactionArrByHandle.exists(handle_val);
    "STREAM":
      return streamArrByHandle.exists(handle_val);
    "Stream":
      return streamArrByHandle.exists(handle_val);
    "stream":
      return streamArrByHandle.exists(handle_val);
    "FIBER":
      return streamArrByHandle.exists(handle_val);
    "Fiber":
      return streamArrByHandle.exists(handle_val);
    "fiber":
      return streamArrByHandle.exists(handle_val);
    default:
      return 0;
  endcase
  endfunction
 
function string process_object_type(string right_string);
  string ret_str;

  ret_str = "";
  for (int j=0;j<right_string.len();j++) begin
       if (right_string[j]!="\\") begin
           ret_str = {ret_str,right_string[j]};
       end
  end
  return ret_str;
endfunction

function void process_desc(string desc,int txh);
  int first_sep_idx=0, second_sep_idx=0, sep_num=0;
  int first_n_idx=0, second_n_idx=0, third_n_idx=0, fourth_n_idx=0, n_num=0, at_idx=0;
  string left_string_one, right_string_one;
  string left_string_two, right_string_two;
  static string left_string_three, right_string_three;
  static string left_string_four, right_string_four;
  static string object_id_str, sequencer_id_str, object_type_str, sequencer_type_str;
  static string numbits_name;
  static int st_txh=0;

  if (desc=="")
      return;
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
  $sformat(numbits_name,"+numbit+%0d",0);
`else
  $sformat(numbits_name,"%0d",0);
`endif
//
  for (int i=0;i<desc.len();i++) begin
       if (desc[i]=="\n") begin
           if (n_num==0)
               first_n_idx = i;
           else if (n_num==1)
               second_n_idx = i;
           else if (n_num==2)
               third_n_idx = i;
           else if (n_num==3)
               fourth_n_idx = i;
           n_num++;
       end
  end
  left_string_one = desc.substr(0,8);
  right_string_one = desc.substr(11,first_n_idx-1);
  st_txh = txh;
  if (left_string_one=="Object ID") begin
      object_type_str = process_object_type(right_string_one);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
      pli_inst.add_attribute_string(st_txh, object_type_str, "+name+snps_object_id", "+numbit+0");
`else
      pli_inst.add_attribute_string(st_txh, object_type_str, "snps_object_id", "");
`endif
//
      if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h,"set_attribute: txh=%0d nm=%s value=%0s radix=%s numbits=%0s",txh,"+name+object_type",object_type_str,"UVM_STRING",numbits_name);
      end
  end
  left_string_two = desc.substr(first_n_idx+1,first_n_idx+12);
  right_string_two = desc.substr(first_n_idx+15,second_n_idx-1);
  if (left_string_two=="Sequencer ID") begin
      sequencer_type_str = process_object_type(right_string_two);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
      pli_inst.add_attribute_string_hidden(st_txh, sequencer_type_str, "+name+sequencer_type");
`else
      pli_inst.add_attribute_string_hidden(st_txh, sequencer_type_str, "sequencer_type");
`endif
//
      if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h,"set_attribute: txh=%0d nm=%s value=%0s radix=%s numbits=%0s",txh,"+name+sequencer_type",sequencer_type_str,"UVM_STRING",numbits_name);
      end
  end
  left_string_three = desc.substr(second_n_idx+1,second_n_idx+5);
  right_string_three = desc.substr(second_n_idx+8,third_n_idx-1);
  if (left_string_three=="Phase") begin
`ifdef VERDI_REPLACE_DPI_WITH_PLI
      pli_inst.add_attribute_string_hidden(st_txh, right_string_three, "+name+starting_phase");
`else
      pli_inst.add_attribute_string_hidden(st_txh, right_string_three, "starting_phase");
`endif
//
      if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h,"set_attribute: txh=%0d nm=%s value=%0s radix=%s numbits=%0s",txh,"+name+starting_phase",right_string_three,"UVM_STRING",numbits_name);
      end
  end else begin
      left_string_three = desc.substr(second_n_idx+1,second_n_idx+18);
      right_string_three = desc.substr(second_n_idx+21,third_n_idx-1);
      if (left_string_three=="Parent Sequence ID") begin
`ifdef VERDI_REPLACE_DPI_WITH_PLI
          pli_inst.add_attribute_string_hidden(st_txh, right_string_three, "+name+parent_sequence");
`else
          pli_inst.add_attribute_string_hidden(st_txh, right_string_three, "parent_sequence"); 
`endif
//
          if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"set_attribute: txh=%0d nm=%s value=%0s radix=%s numbits=%0s",txh,"+name+parent_sequence",right_string_three,"UVM_STRING",numbits_name);
          end
      end
  end
  left_string_four = desc.substr(third_n_idx+1,third_n_idx+18);
  right_string_four = desc.substr(third_n_idx+21,fourth_n_idx-1);
  if (left_string_four=="Parent Sequence ID") begin
`ifdef VERDI_REPLACE_DPI_WITH_PLI
      pli_inst.add_attribute_string_hidden(st_txh, right_string_four, "+name+parent_sequence");
`else
      pli_inst.add_attribute_string_hidden(st_txh, right_string_four, "parent_sequence");
`endif
//
      if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h,"set_attribute: txh=%0d nm=%s value=%0s radix=%s numbits=%0s",txh,"+name+parent_sequence",right_string_four,"UVM_STRING",numbits_name);
      end
  end
endfunction
 
// 9000831514
virtual function string get_time_unit();
  begin

    int scaled_time;

    // The following algorithm depends on simulators exhibiting scaling errors
    // when time literals are utilized that are too small for the compiled time
    // unit.

    // NOTE: get_time_unit assumes that the 'largest' time supported is 100s.

    scaled_time = 100s;
    if ( scaled_time == 0 ) return "";

    scaled_time = 10s;
    if ( scaled_time == 0 ) return "100s";

    scaled_time = 1s;
    if ( scaled_time == 0 ) return "10s";

    scaled_time = 100ms;
    if ( scaled_time == 0 ) return "1s";

    scaled_time = 10ms;
    if ( scaled_time == 0 ) return "100ms";

    scaled_time = 1ms;
    if ( scaled_time == 0 ) return "10ms";

    scaled_time = 100us;
    if ( scaled_time == 0 ) return "1ms";

    scaled_time = 10us;
    if ( scaled_time == 0 ) return "100us";

    scaled_time = 1us;
    if ( scaled_time == 0 ) return "10us";

    scaled_time = 100ns;
    if ( scaled_time == 0 ) return "1us";

    scaled_time = 10ns;
    if ( scaled_time == 0 ) return "100ns";

    scaled_time = 1ns;
    if ( scaled_time == 0 ) return "10ns";

    scaled_time = 100ps;
    if ( scaled_time == 0 ) return "1ns";

    scaled_time = 10ps;
    if ( scaled_time == 0 ) return "100ps";

    scaled_time = 1ps;
    if ( scaled_time == 0 ) return "10ps";

    scaled_time = 100fs;
    if ( scaled_time == 0 ) return "1ps";

    scaled_time = 10fs;
    if ( scaled_time == 0 ) return "100fs";

    scaled_time = 1fs;
    if ( scaled_time == 0 ) return "10fs";

    // If none of the assignments above resulted in scaling errors, then we
    // have to assume that the time unit is 1fs which is the smallest time
    // unit described in IEEE 1800-2012
    return "1fs";
  end
endfunction
//
  
  // Function: begin_tr
  //
  //
  virtual function integer begin_tr(string txtype,
                                     integer stream,
                                     string nm,
                                     string label="",
                                     string desc="",
                                     time begin_time=0);
    static longint unsigned handle = 0, st_stream=0;
    string streamName = "";
    string trName = "";
    static string event_label;
    integer eventId;

    if (streamArrByHandle.exists(stream))
        streamName = streamArrByHandle[stream];
    trName = {streamName, ".", nm};

    st_stream = stream;
    if (begin_time == 0) begin
      handle = pli_inst.begin_tr(st_stream,"+type+transaction");
    end
    else begin
      string time_unit = get_time_unit();
      handle = pli_inst.begin_tr(st_stream, "+type+transaction", begin_time, time_unit);
    end
    if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h,"begin_tr: txtype=%s stream=%0d nm=%s label=%s desc=%s begin_time=%0d real_time=%0d",txtype,stream,nm,label,desc,begin_time,$time);
        $fdisplay(file_h,"begin_tr: trName=%s txh=%0d",trName,handle);
    end
    if (handle==0) begin
        $display("Failed to create transaction!");
        if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"Failed begin_tr: txtype=%s stream=%0d nm=%s label=%s desc=%s begin_time=%0d real_time=%0d",txtype,stream,nm,label,desc,begin_time,$time);
            $fdisplay(file_h,"Failed begin_tr: trName=%s txh=%0d",trName,handle);
        end
        return handle;
    end
    $sformat(event_label,nm);
    pli_inst.set_label(handle,event_label);
    process_desc(desc,handle);
    uvmHandle = uvmHandle + 1;
    uvmPliHandleMap[uvmHandle] = handle;
    transactionArrByHandle[uvmHandle] = trName;
    return uvmHandle;
  endfunction
  
  
  // Function: end_tr
  //
  //
  virtual function void end_tr (integer handle, time end_time=0);
  static longint unsigned pliHandle = 0;

  pliHandle = uvmPliHandleMap[handle];
  if (is_verdi_debug_enabled()) begin
      $fdisplay(file_h,"end_tr: handle=%0d end_time=%0d real_time=%0d",pliHandle,end_time,$time);
  end
  if (pliHandle==0) 
      return;
  pli_inst.end_tr(pliHandle);
  endfunction
  
  
  // Function: link_tr
  //
  //
  virtual function void link_tr(integer h1,
                                 integer h2,
                                 string relation="");
  static longint unsigned pliHandle1 = 0, pliHandle2 = 0;
  static string st_relation="";

  pliHandle1 = uvmPliHandleMap[h1];
  pliHandle2 = uvmPliHandleMap[h2];
  if (is_verdi_debug_enabled()) begin
      $fdisplay(file_h,"link_tr: h1=%0d h2=%0d relation=%s real_time=%0d",pliHandle1,pliHandle2,relation,$time);
  end
  if (pliHandle1==0 || pliHandle2==0)
      return;
  if (relation=="child")
      relation = "parent_child";
  // 9001041770
  if (relation=="")
      relation = "ce_link";
  //
  st_relation = relation;
  pli_inst.link_tr(st_relation,pliHandle1,pliHandle2);
  endfunction
  
  
  
  // Function: free_tr
  //
  //
  virtual function void free_tr(integer handle);
  longint unsigned pliHandle = 0;
  string trName;

  pliHandle = uvmPliHandleMap[handle];
  if (is_verdi_debug_enabled()) begin
      $fdisplay(file_h,"free_tr: handle=%0d real_time=%0d",pliHandle,$time);
  end
  if (pliHandle==0)
      return;
  if (transactionArrByHandle.exists(handle)) begin
      trName = transactionArrByHandle[handle];
      transactionArrByHandle.delete(handle);
  end
  uvmPliHandleMap.delete(handle);
  endfunction
  
function integer port_begin_tr (uvm_port_component_base port_comp,
                                string label,
                                time begin_time);
    longint unsigned stream_h;
    integer tr_h;
    string stream_name;

    stream_name = port_comp.get_full_name();
    stream_h = streamArrByName[stream_name];
    if (check_handle_kind("Fiber", stream_h) != 1) begin
        stream_h = create_stream("","TVM:port_stream",stream_name);
        streamArrByName[stream_name] = stream_h;
    end
    tr_h = begin_tr("PORT, Link",stream_h,label,"","",begin_time);
    return tr_h;
endfunction

function void port_end_tr(integer tr_h, uvm_object obj, time end_time);
    if (end_time == 0) end_time = $time;
    if (check_handle_kind("Transaction", tr_h) == 1) begin
        if (obj != null) begin
            tr_handle = tr_h;
            obj.record(this);
        end

        end_tr(tr_h,end_time);
        free_tr(tr_h);
    end
endfunction

virtual function void port_begin_recording_cb (uvm_port_component_base port_comp,
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

virtual function void port_end_recording_cb (uvm_port_component_base port_comp,
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
    static longint unsigned pliHandle1 = 0, pliHandle2 = 0;

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

        link_tr (tr_h1, tr_h2, "response");
        link_tr (tr_h2, tr_h1, "request");

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

`ifndef UVM_VCS_RECORD
// 9001130255
virtual function string get_object_id (uvm_object obj);
   return pli_inst.get_object_id(obj);
endfunction
`endif

`ifdef VERDI_RECORD_RELATION
static function void link_tr_by_id(integer instId1, integer instId2, string relation);
   static longint unsigned pliHandle1 = 0, pliHandle2 = 0;
   static string st_relation=""; 

   pliHandle1 = transactionArrByInstId[instId1];
   pliHandle2 = transactionArrByInstId[instId2];
   if (pliHandle1==0) begin
       unlinkObjTable[instId1] = instId2;
       unlinkRelTable[instId1] = relation;
   end
   if (pliHandle2==0) begin
       unlinkObjTable[instId2] = instId1;
       unlinkRelTable[instId2] = relation;
   end
   if (is_verdi_debug_enabled()) begin
       $fdisplay(file_h,"link_tr: h1=%0d h2=%0d relation=%s real_time=%0d",pliHandle1,pliHandle2,relation,$time);
   end
   if (pliHandle1==0 || pliHandle2==0)
       return;
   st_relation = relation;
   pli_inst.link_tr(relation,pliHandle1,pliHandle2);
endfunction
`endif

endclass
`endif
