
`ifndef UVM_VERDI_PLI_BASE_SVH
`define UVM_VERDI_PLI_BASE_SVH

typedef enum
{
  MESSAGE,
  ACTION,
  GROUP,
  TRANSACTION
} verdi_trans_type;

class uvm_verdi_pli_base;
  static local uvm_verdi_pli_base m_inst;

  static function uvm_verdi_pli_base get_inst();
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

  virtual function longint unsigned create_stream_begin(string stream_str,string desc="");
    return 0;
  endfunction

  virtual function void create_stream_end(longint unsigned stream_id);
    return;
  endfunction

//9000831514
  virtual function longint unsigned begin_tr(longint unsigned stream,string type_str, time begin_time=0, string time_unit="");
    return 0;
  endfunction
//

  virtual function void end_tr(longint unsigned stream);
    return;
  endfunction

  virtual function void link_tr(string relation,longint unsigned h1,longint unsigned h2);
    return;
  endfunction

  virtual function void add_dense_attribute_enum_severity_type(longint unsigned txh,int severity,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_severity_type(longint unsigned txh,uvm_severity severity_type,string attr_name);
    return;
  endfunction

  virtual function void add_dense_attribute_enum_verbosity_type(longint unsigned txh,int verbosity,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_verbosity_type(longint unsigned txh,uvm_verbosity verbosity_type,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_logic(longint unsigned txh,logic [1023:0] value,string attr_name,string radix_name,string numbits_name);
    return;
  endfunction

  virtual function void add_dense_attribute_int(longint unsigned txh,int int_value,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_int(longint unsigned txh,int int_value,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_real(longint unsigned txh,real real_value,string attr_name,string numbits_name);
    return;
  endfunction

  virtual function void add_dense_attribute_string(longint unsigned txh,string str_value,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_string(longint unsigned txh,string str_value,string attr_name,string numbits_name);
    return;
  endfunction

  virtual function void add_attribute_uvm_tlm_phase(longint unsigned txh,uvm_tlm_phase_e tlm2_phase);
    return;
  endfunction

  virtual function void add_attribute_uvm_tlm_sync(longint unsigned txh,uvm_tlm_sync_e tlm2_sync);
    return;
  endfunction

  virtual function void add_attribute_string_hidden(longint unsigned txh,string str_value,string attr_name);
    return;
  endfunction

  virtual function void add_dense_attribute_trans_type_enum(longint unsigned txh,verdi_trans_type trans_type_enum);
    return;
  endfunction
 
  virtual function void add_attribute_trans_type_enum(longint unsigned txh,verdi_trans_type trans_type_enum);
    return;
  endfunction

  virtual function void set_label(longint unsigned txh,string label);
    return;
  endfunction

  virtual function void add_stream_attribute(longint unsigned streamId, string attr_val, string attr);
    return;
  endfunction

  virtual function void add_scope_attribute(string inst_scope_name, string inst_vif_name, string attr_name);
    return;
  endfunction

`else
  virtual function int create_stream_begin(string stream_str,string desc="");
    return 0;
  endfunction

  virtual function void create_stream_end(int stream_id);
    return;
  endfunction

  virtual function longint begin_tr(int stream,string type_str,time begin_time=0,string time_unit="");
    return 0;
  endfunction

  virtual function void end_tr(longint txh);
    return;
  endfunction 

  virtual function void link_tr(string relation,longint h1,longint h2);
    return;
  endfunction

  virtual function void add_dense_attribute_enum_severity_type(longint txh,int severity,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_severity_type(longint txh,uvm_severity severity_type,string attr_name);
    return;
  endfunction

  virtual function void add_dense_attribute_enum_verbosity_type(longint txh,int verbosity,string attr_name);    return;
  endfunction

  virtual function void add_attribute_verbosity_type(longint txh,uvm_verbosity verbosity_type,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_logic(longint txh,logic [1023:0] value,string attr_name,string radix_name,string numbits_name);
    return;
  endfunction

  virtual function void add_dense_attribute_int(longint txh,int int_value,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_int(longint txh,int int_value,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_real(longint txh,real real_value,string attr_name,string numbits_name);
    return;
  endfunction

  virtual function void add_attribute_uvm_tlm_phase(longint txh,uvm_tlm_phase_e tlm2_phase);
    return;
  endfunction

  virtual function void add_attribute_uvm_tlm_sync(longint txh,uvm_tlm_sync_e tlm2_sync);
    return;
  endfunction

  virtual function void add_dense_attribute_string(longint txh,string str_value,string attr_name);
    return;
  endfunction

  virtual function void add_attribute_string(longint txh,string str_value,string attr_name,string numbits_name);
    return;
  endfunction

  virtual function void add_attribute_string_hidden(longint txh,string str_value,string attr_name);
    return;
  endfunction

  virtual function void add_dense_attribute_trans_type_enum(longint txh,verdi_trans_type trans_type_enum);
    return;
  endfunction

  virtual function void add_attribute_trans_type_enum(longint txh,verdi_trans_type trans_type_enum);
    return;
  endfunction

  virtual function void set_label(longint txh,string label);
    return;
  endfunction

  virtual function void add_stream_attribute(int streamId, string attr_val, string attr);
    return;
  endfunction

  virtual function void add_scope_attribute(string inst_scope_name, string inst_vif_name, string attr_name);
    return;
  endfunction

`endif
//

  virtual function void dump_class_object_by_file(string file_name);
    return;
  endfunction

  virtual function void dump_comp_object_by_file(string file_name);
    return;
  endfunction

`ifndef UVM_VCS_RECORD
// 9001130255
  virtual function string get_object_id(uvm_object obj);
    return "";
  endfunction
//
`endif
endclass

//------------------------------------------------------------------------------
//
// CLASS: verdi_cmdline_processor
//
// Handles runtime option +UVM_VERDI_TRACE
//------------------------------------------------------------------------------

class verdi_cmdline_processor;
     bit verdi_trace_tlm_flag = 0;
     bit verdi_trace_tlm2_flag = 0;
     bit verdi_trace_imp_flag = 0;
     bit verdi_trace_msg_flag = 0;
     bit verdi_trace_dht_flag = 0;
     bit verdi_trace_uvm_aware_flag = 0;
     bit verdi_trace_ral_flag = 0;
     bit verdi_trace_ralwave_flag = 0;
     bit verdi_trace_compwave_flag = 0;
     bit verdi_trace_print_flag = 0;
     bit verdi_trace_fac_flag = 0;
     bit verdi_trace_vif_flag = 0;
     bit verdi_trace_no_decl_flag = 0;
`ifdef VCS
     bit minus_gui_verdi_flag = 0;
`endif
     bit is_verdi_trace_option_checked = 0;
     
     static local verdi_cmdline_processor m_inst;  
     
     static function verdi_cmdline_processor get_inst();
       if(m_inst == null) begin
          process p = process::self();
          string p_rand = p.get_randstate();
          m_inst = new;
          p.set_randstate(p_rand);
       end
       return m_inst;
     endfunction

     function void verdi_trace_option_check_by_sep (byte sep);
         string verdi_trace_values[$], split_values[$];
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();  
         void'(clp.get_arg_values("+UVM_VERDI_TRACE=",verdi_trace_values));
         foreach (verdi_trace_values[i]) begin
           uvm_split_string(verdi_trace_values[i], sep, split_values);
           foreach (split_values[j]) begin
             case (split_values[j])
             "UVM_AWARE": begin
                    verdi_trace_uvm_aware_flag = 1;
             end
             "TLM": verdi_trace_tlm_flag = 1;
             "TLM2": verdi_trace_tlm2_flag = 1;
             "IMP" : verdi_trace_imp_flag = 1;
             "MSG": verdi_trace_msg_flag = 1;
             "HIER": verdi_trace_dht_flag = 1;
             "RAL": verdi_trace_ral_flag = 1;
             "RALWAVE": begin
                    verdi_trace_ralwave_flag = 1;
                    verdi_trace_ral_flag = 1;
             end
             "COMPWAVE": begin
                    verdi_trace_compwave_flag = 1;
                    verdi_trace_dht_flag = 1;
             end
             "PRINT": verdi_trace_print_flag = 1;
             "FAC": verdi_trace_fac_flag = 1;
             "VIF": verdi_trace_vif_flag = 1;
             "NO_DECL" : verdi_trace_no_decl_flag = 1;
             endcase
           end
         end
     endfunction

     function void verdi_trace_option_check ();
         verdi_trace_option_check_by_sep("|");
         verdi_trace_option_check_by_sep("+");
`ifdef VCS
         verdi_minus_option_check("+");
`endif
         is_verdi_trace_option_checked = 1;
     endfunction

`ifdef VCS
     function void verdi_minus_option_check (byte sep);
         string verdi_trace_values[$], split_values[$];
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();
         void'(clp.get_arg_values("-gui=",verdi_trace_values));
         foreach (verdi_trace_values[i]) begin
           uvm_split_string(verdi_trace_values[i], sep, split_values);
           foreach (split_values[j]) begin
             case (split_values[j])
             "verdi": begin
                    minus_gui_verdi_flag = 1;
             end
             endcase
           end
         end
     endfunction

     function bit is_minus_gui_verdi ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return minus_gui_verdi_flag;
     endfunction
`endif
 
     function bit is_verdi_trace_tlm ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_tlm_flag;
     endfunction

     function bit is_verdi_trace_tlm2 ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_tlm2_flag;
     endfunction

     function bit is_verdi_trace_imp ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_imp_flag;
     endfunction

     function bit is_verdi_trace_msg ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_msg_flag;
     endfunction

     function bit is_verdi_trace_dht ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_dht_flag;
     endfunction

     function bit is_verdi_trace_uvm_aware ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_uvm_aware_flag;
     endfunction

     function bit is_verdi_trace_ral ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_ral_flag;
     endfunction

     function bit is_verdi_trace_ralwave ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_ralwave_flag;
     endfunction

     function bit is_verdi_trace_compwave ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_compwave_flag;
     endfunction

     function bit is_verdi_trace_print ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_print_flag;
     endfunction

     function bit is_verdi_trace_fac ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_fac_flag;
     endfunction

     function bit is_verdi_trace_vif ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_vif_flag;
     endfunction
    
     function bit is_verdi_trace_no_decl ();
         if (!is_verdi_trace_option_checked)
             verdi_trace_option_check();

         return verdi_trace_no_decl_flag;
     endfunction

     function int get_arg_value (string match, ref string value);
         uvm_cmdline_processor clp;
         int num = 0;

         clp = uvm_cmdline_processor::get_inst();
         num = clp.get_arg_value(match,value);
         return num;
     endfunction

     function bit is_uvm_inc_internal_rsrc ();
         string rsrc_args[$];
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();
         return clp.get_arg_matches("+UVM_INC_INTERNAL_RSRC", rsrc_args);
     endfunction

     function bit is_uvm_phase_trace ();
         string val;
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();
         return clp.get_arg_value("+UVM_PHASE_TRACE", val);
     endfunction

     function bit is_uvm_objection_trace ();
         string trace_args[$];
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();
         return clp.get_arg_matches("+UVM_OBJECTION_TRACE", trace_args);
     endfunction

     function bit is_uvm_config_db_trace ();
         string trace_args[$];
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();
         return clp.get_arg_matches("+UVM_CONFIG_DB_TRACE", trace_args);
     endfunction

     function bit is_uvm_resource_db_trace ();
         string trace_args[$];
         uvm_cmdline_processor clp;

         clp = uvm_cmdline_processor::get_inst();
         return clp.get_arg_matches("+UVM_RESOURCE_DB_TRACE", trace_args);
     endfunction 
endclass:verdi_cmdline_processor
`endif
