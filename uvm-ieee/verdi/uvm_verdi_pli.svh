`ifndef UVM_VERDI_PLI_SVH
`define UVM_VERDI_PLI_SVH

class uvm_verdi_pli extends uvm_verdi_pli_base;
  static local uvm_verdi_pli m_inst;

`ifndef VERDI_REPLACE_DPI_WITH_PLI
  typedef enum 
  {
     UVM_INFO,
     UVM_WARNING,
     UVM_ERROR,
     UVM_FATAL
  } verdi_uvm_severity_type; // 9001374185
`endif

  static function uvm_verdi_pli get_inst();
    if(m_inst == null) begin
       process p = process::self();
       string p_rand = p.get_randstate();
       m_inst = new;
       p.set_randstate(p_rand);
    end
    return m_inst;
  endfunction

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
  function longint unsigned create_stream_begin(string stream_str,string desc="");
    longint unsigned streamId = 0;
    string stream_name = "", desc_str="";

    stream_name = stream_str;
    desc_str = desc;

    if (desc_str!="")
        streamId = $fsdbTrans_create_stream_begin(stream_name,desc_str);
    else
        streamId = $fsdbTrans_create_stream_begin(stream_name);
    if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h, "create stream stream_name=%s streamId=%0d desc_str=%s\n",stream_name,streamId,desc_str);
        if (streamId==0)
            $fdisplay(file_h, "invalid stream!\n");
    end
    return streamId;
  endfunction

  function void create_stream_end(longint unsigned stream_id);
    longint unsigned streamId = 0;

    streamId = stream_id;
    $fsdbTrans_create_stream_end(streamId);
  endfunction

// 9000831514
  function longint unsigned begin_tr(longint unsigned stream,string type_str,time begin_time=0,string time_unit="");
    int st_stream;
    longint unsigned handle = 0;

    st_stream = stream;
    if (begin_time != 0) begin
        static real st_start_time = 0;
        static string st_time_unit = "";
        st_start_time =  begin_time;
        st_time_unit = time_unit;

        handle = $fsdbTrans_begin(st_stream,type_str,"+time",st_start_time,"+time_unit",st_time_unit);
        return handle;
    end

    if (type_str=="+type+transaction")
        handle = $fsdbTrans_begin(st_stream,"+type+transaction");
    else
        handle = $fsdbTrans_begin(st_stream,type_str);
    return handle;
  endfunction
//

  function void end_tr(longint unsigned stream);
    longint unsigned st_stream;

    st_stream = stream;
    $fsdbTrans_end(st_stream);
  endfunction

  function void link_tr(string relation,longint unsigned h1,longint unsigned h2);
    string st_relation = "";
    longint unsigned st_h1 = 0, st_h2 = 0;

    st_relation = relation;
    st_h1 = h1;
    st_h2 = h2;
    $fsdbTrans_add_relation(st_relation,st_h1,st_h2);
  endfunction

  function void add_dense_attribute_enum_severity_type(longint unsigned txh,int severity,string attr_name);
    longint unsigned st_txh = 0;
    uvm_severity st_severity_type;
    string st_attr_name = "";

    case(severity)
         UVM_INFO: st_severity_type = UVM_INFO;
         UVM_WARNING: st_severity_type = UVM_WARNING;
         UVM_ERROR: st_severity_type = UVM_ERROR;
         UVM_FATAL: st_severity_type = UVM_FATAL;
       endcase
    st_txh = txh;
    $sformat(st_attr_name,"+name+%s",attr_name);
    $fsdbTrans_define_attribute(st_txh, st_severity_type, st_attr_name);
  endfunction

  function void add_attribute_severity_type(longint unsigned txh,uvm_severity severity_type,string attr_name);
    longint unsigned st_txh = 0;
    uvm_severity st_severity_type;
    string st_attr_name = "";

    st_txh = txh;
    st_severity_type = severity_type;
    st_attr_name = attr_name;
    $fsdbTrans_add_attribute(st_txh, st_severity_type, st_attr_name);
  endfunction

  function void add_dense_attribute_enum_verbosity_type(longint unsigned txh,int verbosity,string attr_name);
    longint unsigned st_txh = 0;
    uvm_verbosity st_verbosity_type;
    string st_attr_name = "";

    case(verbosity)
         UVM_NONE: st_verbosity_type = UVM_NONE;
         UVM_LOW: st_verbosity_type = UVM_LOW;
         UVM_MEDIUM: st_verbosity_type = UVM_MEDIUM;
         UVM_HIGH: st_verbosity_type = UVM_HIGH;
         UVM_FULL: st_verbosity_type = UVM_FULL;
         UVM_DEBUG: st_verbosity_type = UVM_DEBUG;
    endcase

    st_txh = txh;
    $sformat(st_attr_name,"+name+%s",attr_name);
    $fsdbTrans_define_attribute(st_txh, st_verbosity_type, st_attr_name);
  endfunction

  function void add_attribute_verbosity_type(longint unsigned txh,uvm_verbosity verbosity_type,string attr_name);
    longint unsigned st_txh = 0;
    uvm_verbosity st_verbosity_type;
    string st_attr_name = "";

    st_txh = txh;
    st_verbosity_type = verbosity_type;
    st_attr_name = attr_name;
    $fsdbTrans_add_attribute(st_txh, st_verbosity_type, st_attr_name);
  endfunction

  function void add_attribute_logic(longint unsigned txh,logic [1023:0] value,string attr_name,string radix_name,string numbits_name);
    longint unsigned st_txh = 0;
    logic [1023:0] st_value;
    string st_attr_name = "", st_numbits_name = "";

    st_txh = txh;
    st_value = value;
    st_attr_name = attr_name;
    st_numbits_name = numbits_name;
    case(radix_name)
      "+radix+bin": $fsdbTrans_add_attribute(st_txh, st_value, st_attr_name, "+radix+bin", st_numbits_name);
      "+radix+dec": $fsdbTrans_add_attribute(st_txh, st_value, st_attr_name, "+radix+dec", st_numbits_name);
      "+radix+oct": $fsdbTrans_add_attribute(st_txh, st_value, st_attr_name, "+radix+oct", st_numbits_name);
      "+radix+hex": $fsdbTrans_add_attribute(st_txh, st_value, st_attr_name, "+radix+hex", st_numbits_name);
      default: $fsdbTrans_add_attribute(st_txh, st_value, st_attr_name, st_numbits_name);
    endcase
  endfunction

  function void add_dense_attribute_int(longint unsigned txh,int int_value,string attr_name);
    longint unsigned st_txh = 0;
    int st_int_value;
    string st_attr_name = "";

    st_txh = txh;
    st_int_value = int_value;
    $sformat(st_attr_name,"+name+%s",attr_name);
    $fsdbTrans_define_attribute(st_txh, st_int_value, st_attr_name, "+radix+dec");
  endfunction

  function void add_attribute_int(longint unsigned txh,int int_value,string attr_name);
    longint unsigned st_txh = 0;
    int st_int_value;
    string st_attr_name = "";

    st_txh = txh;
    st_int_value = int_value;
    st_attr_name = attr_name;
    $fsdbTrans_add_attribute(st_txh, st_int_value, st_attr_name, "+radix+dec", "+numbit+32");
  endfunction

  function void add_attribute_real(longint unsigned txh,real real_value,string attr_name,string numbits_name);
    longint unsigned st_txh = 0;
    real st_real_value;
    string st_attr_name = "", st_numbits_name = "";

    st_txh = txh;
    st_real_value = real_value;
    st_attr_name = attr_name;
    st_numbits_name = numbits_name;
    $fsdbTrans_add_attribute(st_txh, st_real_value, st_attr_name, st_numbits_name);
  endfunction

  function void add_attribute_uvm_tlm_phase(longint unsigned txh,uvm_tlm_phase_e tlm2_phase);
    longint unsigned st_txh = 0;
    uvm_tlm_phase_e st_tlm2_phase;

    st_txh = txh;
    st_tlm2_phase = tlm2_phase;
    $fsdbTrans_add_attribute(st_txh, st_tlm2_phase, "tlm2_phase", "");
  endfunction

  function void add_attribute_uvm_tlm_sync(longint unsigned txh,uvm_tlm_sync_e tlm2_sync);
    longint unsigned st_txh = 0;
    uvm_tlm_sync_e st_tlm2_sync;

    st_txh = txh;
    st_tlm2_sync = tlm2_sync;
    $fsdbTrans_add_attribute(st_txh, st_tlm2_sync, "tlm2_sync", "");
  endfunction

  function void add_dense_attribute_string(longint unsigned txh,string str_value,string attr_name);
    longint unsigned st_txh = 0;
    string st_str_value="", st_attr_name="";

    st_txh = txh;
    st_str_value = str_value;
    $sformat(st_attr_name,"+name+%s",attr_name);
    $fsdbTrans_define_attribute(st_txh, st_str_value, st_attr_name);
  endfunction

  function void add_attribute_string(longint unsigned txh,string str_value,string attr_name,string numbits_name);
    longint unsigned st_txh = 0;
    string st_str_value="", st_attr_name="", st_numbits_name="";

    st_txh = txh;
    st_str_value = str_value;
    st_attr_name = attr_name;
    st_numbits_name = numbits_name;
    $fsdbTrans_add_attribute(st_txh, st_str_value, st_attr_name, st_numbits_name);
  endfunction

  function void add_attribute_string_hidden(longint unsigned txh,string str_value,string attr_name);
    longint unsigned st_txh = 0;
    string st_str_value;

    st_txh = txh;
    st_str_value = str_value;
    case (attr_name)
      "+name+object_type": $fsdbTrans_add_attribute(st_txh, st_str_value, "+name+object_type", "+numbit+0" );
      "+name+sequencer_type": $fsdbTrans_add_attribute(st_txh, st_str_value, "+name+sequencer_type", "+numbit+0", "+hidden");
      "+name+starting_phase": $fsdbTrans_add_attribute(st_txh, st_str_value, "+name+starting_phase", "+numbit+0", "+hidden");
      "+name+parent_sequence": $fsdbTrans_add_attribute(st_txh, st_str_value, "+name+parent_sequence", "+numbit+0", "+hidden");
    endcase
  endfunction

  function void add_dense_attribute_trans_type_enum(longint unsigned txh,verdi_trans_type trans_type_enum);
    longint unsigned st_txh = 0;
    verdi_trans_type st_trans_type_enum;

    st_txh = txh;
    st_trans_type_enum = trans_type_enum;
    $fsdbTrans_define_attribute(st_txh, st_trans_type_enum, "+name+$trans_type");
  endfunction

  function void add_attribute_trans_type_enum(longint unsigned txh,verdi_trans_type trans_type_enum);
    longint unsigned st_txh = 0;
    verdi_trans_type st_trans_type_enum;

    st_txh = txh;
    st_trans_type_enum = trans_type_enum;
    $fsdbTrans_add_attribute(st_txh, st_trans_type_enum, "+name+$trans_type");
  endfunction

  function void set_label(longint unsigned txh,string label);
    longint unsigned st_txh = 0;
    string st_label;

    st_txh = txh;
    st_label = label;
    if (st_label!="")
        $fsdbTrans_set_label(st_txh,st_label);
  endfunction

`ifdef UVM_VERDI_RALWAVE
  function void dump_class_object_by_file(string file_name);
    string st_file_name;
    st_file_name = file_name;
    if (st_file_name!="")
        $fsdbDumpClassObjectByFile(st_file_name,"+ralwave");
  endfunction
`endif

`ifndef UVM_VERDI_NO_COMPWAVE
`ifdef VCS
  function void dump_comp_object_by_file(string file_name);
     string st_file_name;
    st_file_name = file_name;
    if (st_file_name!="")
        $fsdbDumpClassObjectByFile(st_file_name);
  endfunction
`endif
`endif

`ifdef UVM_VERDI_VIF_RECORD

  function void add_stream_attribute(longint unsigned streamId, string attr_val, string attr);
    longint unsigned st_streamId = 0;
    string st_attr_val, st_attr;

    st_streamId = streamId;
    st_attr_val = attr_val;
    st_attr = attr;
    $fsdbTrans_add_stream_attribute(st_streamId, st_attr_val, st_attr);
  endfunction

  function void add_scope_attribute(string inst_scope_name, string inst_vif_name, string attr_name);
    string st_inst_scope_name, st_inst_vif_name, st_attr_name;

    st_inst_scope_name = inst_scope_name;
    st_inst_vif_name = inst_vif_name;
    st_attr_name = attr_name;
    $fsdbTrans_add_scope_attribute(st_inst_scope_name, st_inst_vif_name, st_attr_name);
  endfunction

`endif
 
`else
`ifdef VCS
  // With DPI 
  function int create_stream_begin(string stream_str,string desc="");
    int streamId = 0;
    int state = 0;
    
    streamId = fsdbTransDPI_create_stream_begin(state, stream_str, desc, "");
    if (is_verdi_debug_enabled()) begin
        $fdisplay(file_h, "create stream stream_name=%s streamId=%0d desc_str=%s\n",stream_str,streamId,desc);
        if (streamId==0)
            $fdisplay(file_h, "invalid stream!\n");
    end
    return streamId;
  endfunction

  function void create_stream_end(int stream_id);
    int state = 0;

    fsdbTransDPI_create_stream_end(state,stream_id,"");
  endfunction

// 9000831514
  function longint begin_tr(int stream,string type_str,time begin_time=0,string time_unit="");
    longint handle = 0;
    int state = 0;
    string options = "";

    if (begin_time != 0) begin
        $sformat(options,"+time+%0d +time_unit+%s",begin_time,time_unit); // 9001386444
        handle = fsdbTransDPI_begin(state, stream, type_str, options);
        return handle;
    end

    handle = fsdbTransDPI_begin(state, stream, type_str, options);
    return handle;
  endfunction
//

  function void end_tr(longint txh);
    int state = 0;

    fsdbTransDPI_end(state, txh, "");
  endfunction

  function void link_tr(string relation,longint h1,longint h2);
    int state = 0;

    fsdbTransDPI_add_relation(state, relation, h1, h2, "");
  endfunction

  function void add_dense_attribute_enum_severity_type(longint txh,int severity,string attr_name);
    int state = 0; 
    int unsigned enum_id = 0;
    verdi_uvm_severity_type severity_type; // 9001374185

    case(severity)
         UVM_INFO: severity_type = UVM_INFO;
         UVM_WARNING: severity_type = UVM_WARNING;
         UVM_ERROR: severity_type = UVM_ERROR;
         UVM_FATAL: severity_type = UVM_FATAL;
    endcase
    enum_id = fsdbTransDPI_get_enum_id(state, "severity_type");
    fsdbTransDPI_define_enum_int_attribute(state, txh, attr_name, enum_id, severity_type, "");
  endfunction


  function void add_attribute_severity_type(longint txh,uvm_severity severity_type,string attr_name);
    int state = 0; 
    int unsigned enum_id = 0;
    verdi_uvm_severity_type verdi_severity_type; // 9001374185

    case(severity_type)
         UVM_INFO: verdi_severity_type = UVM_INFO;
         UVM_WARNING: verdi_severity_type = UVM_WARNING;
         UVM_ERROR: verdi_severity_type = UVM_ERROR;
         UVM_FATAL: verdi_severity_type = UVM_FATAL;
    endcase
    enum_id = fsdbTransDPI_get_enum_id(state, "verdi_severity_type");
    fsdbTransDPI_add_enum_int_attribute(state, txh, attr_name, enum_id, verdi_severity_type, "");
  endfunction

  function void add_dense_attribute_enum_verbosity_type(longint txh,int verbosity,string attr_name);
    int state = 0; 
    int unsigned enum_id = 0;
    uvm_verbosity verbosity_type;

    case(verbosity)
         UVM_NONE: verbosity_type = UVM_NONE;
         UVM_LOW: verbosity_type = UVM_LOW;
         UVM_MEDIUM: verbosity_type = UVM_MEDIUM;
         UVM_HIGH: verbosity_type = UVM_HIGH;
         UVM_FULL: verbosity_type = UVM_FULL;
         UVM_DEBUG: verbosity_type = UVM_DEBUG;
    endcase
    enum_id = fsdbTransDPI_get_enum_id(state, "verbosity_type");
    fsdbTransDPI_define_enum_int_attribute(state, txh, attr_name, enum_id, verbosity_type, "");
  endfunction
 
  function void add_attribute_verbosity_type(longint txh,uvm_verbosity verbosity_type,string attr_name);
    int state = 0; 
    int unsigned enum_id = 0;

    enum_id = fsdbTransDPI_get_enum_id(state, "verbosity_type");
    fsdbTransDPI_add_enum_int_attribute(state, txh, attr_name, enum_id, verbosity_type, "");
  endfunction

  function void add_attribute_logic(longint txh,logic [1023:0] value,string attr_name,string radix_name,string numbits_name);
    int state = 0, numbits = 0;
   
    numbits = numbits_name.atoi();
    fsdbTransDPI_add_logicvec_attribute(state, txh, attr_name, value, numbits, radix_name);
  endfunction

  function void add_dense_attribute_int(longint txh,int int_value,string attr_name);
    int state = 0;

    fsdbTransDPI_define_int_attribute(state, txh, attr_name, int_value, "+radix+dec");
  endfunction

  function void add_attribute_int(longint txh,int int_value,string attr_name);
    int state = 0;

    fsdbTransDPI_add_int_attribute(state, txh, attr_name, int_value, "+radix+dec");
  endfunction
 
  function void add_attribute_real(longint txh,real real_value,string attr_name,string numbits_name);
    int state = 0;

    fsdbTransDPI_add_real_attribute(state, txh, attr_name, real_value, "");
  endfunction

  function void add_attribute_uvm_tlm_phase(longint txh,uvm_tlm_phase_e tlm2_phase);
    int state = 0; 
    int unsigned enum_id = 0;

    enum_id = fsdbTransDPI_get_enum_id(state, "tlm2_phase");
    fsdbTransDPI_add_enum_int_attribute(state, txh, "tlm2_phase", enum_id, tlm2_phase, "");
  endfunction

  function void add_attribute_uvm_tlm_sync(longint txh,uvm_tlm_sync_e tlm2_sync);
    int state = 0;
    int unsigned enum_id = 0;

    enum_id = fsdbTransDPI_get_enum_id(state, "tlm2_sync");
    fsdbTransDPI_add_enum_int_attribute(state, txh, "tlm2_sync", enum_id, tlm2_sync, "");
  endfunction

  function void add_dense_attribute_string(longint txh,string str_value,string attr_name);
    int state = 0;

    fsdbTransDPI_define_string_attribute(state, txh,  attr_name, str_value, "");
  endfunction

  function void add_attribute_string(longint txh,string str_value,string attr_name,string numbits_name);
    int state = 0;

    fsdbTransDPI_add_string_attribute(state, txh, attr_name, str_value, "");
  endfunction

  function void add_attribute_string_hidden(longint txh,string str_value,string attr_name);
    int state = 0;

    case (attr_name)
      "object_type": fsdbTransDPI_add_string_attribute(state, txh, "object_type", str_value, ""); 
      "sequencer_type": fsdbTransDPI_add_string_attribute(state, txh, "sequencer_type", str_value, "+hidden"); 
      "starting_phase": fsdbTransDPI_add_string_attribute(state, txh, "starting_phase", str_value, "+hidden");
      "parent_sequence": fsdbTransDPI_add_string_attribute(state, txh, "parent_sequence", str_value, "+hidden");
    endcase 
  endfunction

  function void add_dense_attribute_trans_type_enum(longint txh,verdi_trans_type trans_type_enum);
    int state = 0;
    int unsigned enum_id = 0;

    enum_id = fsdbTransDPI_get_enum_id(state, "trans_type_enum");
    fsdbTransDPI_define_enum_int_attribute(state, txh, "$trans_type", enum_id, trans_type_enum, ""); 
  endfunction

  function void add_attribute_trans_type_enum(longint txh,verdi_trans_type trans_type_enum);
    int state = 0;
    int unsigned enum_id = 0;

    enum_id = fsdbTransDPI_get_enum_id(state, "trans_type_enum");
    fsdbTransDPI_add_enum_int_attribute(state, txh, "$trans_type", enum_id, trans_type_enum, ""); 
  endfunction

  function void set_label(longint txh,string label);
    int state = 0;

    if (label!="")
        fsdbTransDPI_set_label(state, txh, label, "");
  endfunction

`ifdef UVM_VERDI_RALWAVE
  function void dump_class_object_by_file(string file_name);
    string st_file_name;
    st_file_name = file_name;
    if (st_file_name!="")
        $fsdbDumpClassObjectByFile(st_file_name,"+ralwave");
  endfunction
`endif

`ifndef UVM_VERDI_NO_COMPWAVE
`ifdef VCS
  function void dump_comp_object_by_file(string file_name);
     string st_file_name;
    st_file_name = file_name;
    if (st_file_name!="")
        $fsdbDumpClassObjectByFile(st_file_name);
  endfunction
`endif
`endif

`ifdef UVM_VERDI_VIF_RECORD

  function void add_stream_attribute(int streamId, string attr_val, string attr);
    int state = 0;

    fsdbTransDPI_stream_add_string_attribute(state, streamId, attr, attr_val, "");
  endfunction

  function void add_scope_attribute(string inst_scope_name, string inst_vif_name, string attr_name);
    int state = 0;

    fsdbTransDPI_scope_add_string_attribute(state, inst_scope_name, attr_name, inst_vif_name, "");
  endfunction    

`endif
`endif
`endif
// end of 6000025017

`ifndef UVM_VCS_RECORD
// 9001130255
  virtual function string get_object_id (uvm_object obj);
     string ret_str="";

`ifdef VCS
     $sformat(ret_str,"%0s",$vcs_get_object_id(obj));   
`else
     ret_str = obj.get_type_name();
`endif 
     return ret_str;
  endfunction
`endif
// End
endclass
`endif
