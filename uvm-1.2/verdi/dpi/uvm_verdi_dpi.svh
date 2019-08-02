//-------------------------------------------------------------
// SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary work of 
// Synopsys, Inc., and is fully protected under copyright and trade 
// secret laws. You may not view, use, disclose, copy, or distribute this 
// file or any information contained herein except pursuant to a valid 
// written license from Synopsys. 
//-------------------------------------------------------------

`ifndef UVM_VERDI_DPI_SVH
`define UVM_VERDI_DPI_SVH

`ifdef UVM_NO_DPI
   `define UVM_NO_VERDI_DPI
`endif

`ifdef INCA
   `define UVM_NO_VERDI_DPI
`endif

`ifdef UVM_VERDI_DPI
    `undef UVM_NO_VERDI_DPI
`endif


`ifndef UVM_NO_VERDI_DPI

`ifdef VERDI_MSG_PARSE_DPI
   import "DPI-C" context function int parse_rsrc_msg(input string message, output rsrc_msg_struct _msg_fields);
   import "DPI-C" context function int parse_phase_msg(input string message, output string domain, output string schedule, output string phase);
`endif

   import "DPI-C" context function int find_substr_by_C(input string org_str, input string search_str); 
   import "DPI-C" context function string verdi_dump_resource_value(input string rsrc);
   import "DPI-C" context function int verdi_dump_component_interface(input string scope_name, input int streamId);
   import "DPI-C" context function string verdi_upper_scope(input string inst_scope_name, output chandle upper_scope_pointer);
   import "DPI-C" context function void verdi_dhier_interface(input string var_name);
   import "DPI-C" context function void retrieve_reg_def_class(input string var_name, input int _handle, input int is_objid_only=0);
   import "DPI-C" context function string retrieve_def_class(input string var_name, output int objid);
   import "DPI-C" context function int record_reg_decl_name(input int handle, input string parent_var_name, input string var_name, input string obj_name);
   import "DPI-C" context function int check_is_sequencer();
   import "DPI-C" context function string remove_array_index(input string name_w_ary_idx, output chandle name_c_ptr);
`else
   static int is_error_printed =0;
   function string remove_array_index(input string name_w_ary_idx, output chandle name_c_ptr);

      if(is_error_printed) 
         return "";
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return "";
   endfunction

   function int check_is_sequencer();
      if(is_error_printed) 
         return 0;
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return 0;
   endfunction
 
   function string verdi_dump_resource_value(input string rsrc);
      if(is_error_printed) 
         return "";
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return "";
   endfunction

   function int verdi_dump_component_interface(input string scope_name, input int streamId);
      if(is_error_printed) 
         return 0;
      is_error_printed = 1; 

      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return 0;
   endfunction

   function string verdi_upper_scope(input string inst_scope_name, chandle upper_scope_pointer);
      if(is_error_printed) 
         return "";
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return "";
   endfunction

   function void verdi_dhier_interface(input string var_name);
      if(is_error_printed) 
         return;
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return;
   endfunction

   function void retrieve_reg_def_class(input string var_name, int stream_handle, input int is_objid_only=0); 
      if(is_error_printed) 
         return;
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return;
   endfunction

   function string retrieve_def_class(input string var_name, output int objid);
      if(is_error_printed) 
         return "";
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return "";
   endfunction

   function int record_reg_decl_name(input int handle, input string parent_var_name, input string var_name, input string obj_name);
      if(is_error_printed) 
         return 0;
      is_error_printed = 1; 
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return 0;
   endfunction

   function int parse_rsrc_msg(input string message, output rsrc_msg_struct _msg_fields);
      if(is_error_printed)
         return 0;
      is_error_printed = 1;
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return 0;
   endfunction

   function int parse_phase_msg(input string message, output string domain, output string schedule, output string phase);
      if(is_error_printed)
         return 0;
      is_error_printed = 1;
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return 0;
   endfunction

   function int find_substr_by_C(input string org_str, input string search_str);
      if(is_error_printed)
         return 0;
      is_error_printed = 1;
      uvm_report_info("UVM_VERDI_DPI",
         ($sformatf("uvm_verdi DPI routines are compiled off. Recompile without +define+UVM_NO_VERDI_DPI")));
      return 0;
   endfunction

`endif

   export "DPI-C" function pli_dhier_begin_event;
   export "DPI-C" function pli_dhier_set_label;
   export "DPI-C" function pli_dhier_add_attribute;
   export "DPI-C" function pli_dhier_add_attribute_int;
   export "DPI-C" function pli_dhier_end_event;
   export "DPI-C" function pli_trans_add_vif_attr;
   export "DPI-C" function pli_trans_add_class_name_attr;

   static int scope_hash[string];

   function void set_dhier_message_attribute_str(input int handle, input string valName, input string attrName);
     string attr_name;

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
     $sformat(attr_name,"+name+%s",attrName);
     pli_inst.add_attribute_string(handle, valName, attr_name,"+numbit+0");
`else
     $sformat(attr_name,"%s",attrName);
     pli_inst.add_attribute_string(handle, valName, attr_name,"");
`endif
//
   endfunction

   function void set_dhier_message_attribute_int(input int handle, input int val, input string attrName);
     string attr_name;
     int st_handle;

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
     $sformat(attr_name,"+name+%s",attrName);
`else
     $sformat(attr_name,"%s",attrName);
`endif
//
     pli_inst.add_attribute_int(handle, val, attr_name);
   endfunction

   function int pli_dhier_begin_event(input string streamN);
      string comp_stream;
      automatic int streamId=0, handle=0; 

      $sformat(comp_stream, "UVM.HIER_TRACE.%s", streamN);

      if (!streamArrByName.exists(comp_stream)) begin
          streamId = pli_inst.create_stream_begin(comp_stream);
          streamArrByName[comp_stream] = streamId;
          pli_inst.create_stream_end(streamId);
      end else begin
          streamId = streamArrByName[comp_stream];
      end

      handle = pli_inst.begin_tr(streamId,"+type+message");

      if (handle==0) begin
          $display("Failed to create transaction!\n");
          return 0;
      end

      return handle;
   endfunction


   function void pli_trans_add_class_name_attr(input string scope_name, input string attribute_value, input int streamId);
      string attribute_name;

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
      attribute_name = "+name+class_name";
`else
      attribute_name = "class_name";
`endif
//

      if(streamId==0)
`ifndef VERDI_NO_TRANS_SCOPE_ATTR
         pli_inst.add_scope_attribute(scope_name, attribute_value, attribute_name);
`else
         uvm_report_info("UVM_VERDI_DPI", 
                          $sformat("scope=%s, %s=%s", scope_name, attribute_name, attribute_value));
`endif
      else
         pli_inst.add_stream_attribute(streamId, attribute_value, attribute_name);
   endfunction

   function void pli_trans_add_vif_attr(input string scope_name, input int idx, input string attribute_value, input int streamId);

      string attribute_name;

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
      if(idx==-1)
         attribute_name = "+name+verdi_link_interface";
      else 
         $sformat(attribute_name, "+name+verdi_link_interface_%0d", idx);
`else
      if(idx==-1)
         attribute_name = "verdi_link_interface";
      else
         $sformat(attribute_name, "verdi_link_interface_%0d", idx);
`endif
//

      if(streamId==0)
`ifndef VERDI_NO_TRANS_SCOPE_ATTR
         pli_inst.add_scope_attribute(scope_name, attribute_value, attribute_name);
`else
         uvm_report_info("UVM_VERDI_DPI", 
                          $sformat("scope=%s, %s=%s", scope_name, attribute_name, attribute_value));
`endif
      else
         pli_inst.add_stream_attribute(streamId, attribute_value, attribute_name);

   endfunction

   function void pli_dhier_set_label(input int handle, input string label);

      pli_inst.set_label(handle, label);

   endfunction

   function void pli_dhier_add_attribute(input int handle, input string attr_name, input string attr_value);
     
      set_dhier_message_attribute_str(handle, attr_value, attr_name);

   endfunction

   function void pli_dhier_add_attribute_int(input int handle, input string attr_name, input int attr_value);
     
      set_dhier_message_attribute_int(handle, attr_value, attr_name);

   endfunction

   function void pli_dhier_end_event(input int handle);
      pli_inst.end_tr(handle);
   endfunction


   function automatic void add_driver_vif_to_sequencer(ref uvm_port_list connected_drivers, input int streamId);
      int num_written_vif = 0;
      foreach (connected_drivers[idx]) begin
         uvm_component verdi_cur_component;
         verdi_cur_component = connected_drivers[idx].get_parent();
         num_written_vif = verdi_dump_component_interface(verdi_cur_component.get_full_name(), streamId); 
      end

      connected_drivers.delete();
   endfunction

   function automatic void verdi_dump_vif_name(string component_name, input int streamId);
      string inst_vif_name,inst_scope_name, inst_prev_scope; 

      uvm_root m_top;
      uvm_component verdi_cur_component;
      int num_if_written;
      
      if(component_name.len()==0  || scope_hash.exists(component_name))
         return;

      inst_scope_name = component_name;

      m_top = uvm_root::get();

      if(m_top==null)
         return;

      do begin

         verdi_cur_component = m_top.find(inst_scope_name);

         if(verdi_cur_component==null)
            break;

         if(component_name!=inst_scope_name)
            num_if_written = verdi_dump_component_interface(inst_scope_name, 0);
         else begin
           
            num_if_written = verdi_dump_component_interface(inst_scope_name, streamId);
            if(num_if_written==0 && check_is_sequencer() != 0) begin
               uvm_port_list connected_drivers;
               string port_component_name;
               uvm_port_component_base seqr_port=null;

               port_component_name = {inst_scope_name, ".seq_item_export"};
               $cast(seqr_port, m_top.find(port_component_name));

               if(seqr_port!=null) begin
                  seqr_port.get_provided_to(connected_drivers);
                  add_driver_vif_to_sequencer(connected_drivers, streamId);
               end
            end

         end

         scope_hash[inst_scope_name] = 1;


         do begin
            chandle ptr;
            inst_prev_scope = inst_scope_name;
            inst_scope_name = verdi_upper_scope(inst_prev_scope, ptr);
         end while(inst_scope_name.len() > 0 && scope_hash.exists(inst_scope_name));

      end while(inst_scope_name.len()> 0);


      return;
   endfunction

   function string verdi_dump_rsrc_obj(string scope_name, string field_name);
      uvm_resource_pool cp;
      uvm_resource_base verdi_object_if_recording;
      string rsrc_name;
      static verdi_cmdline_processor verdi_clp;

      verdi_clp = verdi_cmdline_processor::get_inst();
      if(!verdi_clp.is_verdi_trace_vif())
         return "";

      cp = uvm_resource_pool::get();
      if((cp!=null) && cp.rtab.exists(field_name)) begin
         verdi_object_if_recording = cp.get_by_name(scope_name, field_name, null, 0);

         if(verdi_object_if_recording!=null)
            rsrc_name = verdi_dump_resource_value("verdi_object_if_recording");
      end
      return rsrc_name; 
   endfunction


`endif // end UVM_VERDI_DPI_SVH
