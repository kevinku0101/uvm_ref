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
`ifndef UVM_VERDI_MESSAGE_CATCHER_SVH
`define UVM_VERDI_MESSAGE_CATCHER_SVH
`include "uvm_verdi_pli_base.svh"
//================================
// Report Catacher Implementations
//================================

`ifdef VCS
`ifndef UVM_NO_VERDI_DPI
`define VERDI_MSG_PARSE_DPI
`define VERDI_USE_C_SUBSTR
`endif
`endif

typedef struct {
  string scope_name;
  string field_name;
  string type_name;
  string action;
  string accessor;
  string resource;
} rsrc_msg_struct;

class verdi_report_catcher extends uvm_report_catcher;
     int verdi_catcher_counter = 0;
     int objtn_trc_num = 0;
     int objtn_raise_drop_num = 0;
     int objtn_trc_maximum = 5000;
     int reg_trc_num = 0;
     uvm_phase domain_phase_array[string];

`ifdef VCS
     function new(string name = "verdi_report_catcher"); //9001367328
         super.new(name);
     endfunction
`endif

     function int find_substr (string full_name, string sub_name);
`ifdef VERDI_USE_C_SUBSTR
         return find_substr_by_C(full_name, sub_name);
`else
         int full_length = full_name.len();
         int sub_length = sub_name.len();

         for (int pos = 0; pos <= (full_length - sub_length); pos++)
           if (full_name.substr(pos, pos + sub_length - 1) == sub_name)
             return pos;

         return -1;
`endif
     endfunction

     function int find_substr_bw (string full_name, string sub_name);
         int full_length = full_name.len();
         int sub_length = sub_name.len();

         for (int pos = (full_length - sub_length); pos >= 0; pos--)
           if (full_name.substr(pos, pos + sub_length - 1) == sub_name)
             return pos;

         return -1;
     endfunction

     function void deassemble_phase_full_name (string phase_full_name,
                                               output string domain,
                                               output string schedule,
                                               output string phase);
`ifdef VERDI_MSG_PARSE_DPI
         void'(parse_phase_msg(phase_full_name, domain, schedule, phase));
`else
         int first_dot = -1;
         int second_dot = -1;
         int full_length = phase_full_name.len();

         for (int pos = 0; pos < full_length; pos++)
           if (phase_full_name[pos] == ".") begin
             if (first_dot < 0) first_dot = pos;
             else begin
               second_dot = pos;
               break;
             end
           end

         schedule = "";
         if (first_dot < 0) begin
            domain = phase_full_name;
            phase = phase_full_name;
         end
         else if (second_dot < 0) begin
            domain = phase_full_name.substr(0,first_dot-1);
            phase = phase_full_name.substr(first_dot+1,full_length-1);
         end
         else begin
            domain = phase_full_name.substr(0,first_dot-1);
            schedule = phase_full_name.substr(first_dot+1,second_dot-1);
            phase = phase_full_name.substr(second_dot+1,full_length-1);
         end
`endif
     endfunction

     function void severity_to_string (uvm_severity sev, output string sev_str);
       case (sev)
         UVM_INFO: sev_str = "UVM_INFO";
         UVM_WARNING: sev_str = "UVM_WARNING";
         UVM_ERROR: sev_str = "UVM_ERROR";
         UVM_FATAL: sev_str = "UVM_FATAL";
         default: sev_str = "";
       endcase
     endfunction

     function void verbosity_to_string (uvm_verbosity ver, output string ver_str);
       case (ver)
         UVM_NONE: ver_str = "UVM_NONE";
         UVM_LOW: ver_str = "UVM_LOW";
         UVM_MEDIUM: ver_str = "UVM_MEDIUM";
         UVM_HIGH: ver_str = "UVM_HIGH";
         UVM_FULL: ver_str = "UVM_FULL";
         UVM_DEBUG: ver_str = "UVM_DEBUG";
         default: ver_str = "";
       endcase
     endfunction

     function void set_message_attribute_str(longint unsigned handle,string attrName,string valName);
       static string attr_name = "", val_name = "";
       static longint unsigned st_handle=0;

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",attrName);
`else
       attr_name = attrName;
`endif
//
       $sformat(val_name,"%s",valName);
       st_handle = handle;
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       pli_inst.add_attribute_string(st_handle,val_name,attr_name,"+numbit+0");
`else
       pli_inst.add_attribute_string(st_handle,val_name,attr_name,"");
`endif
//
     endfunction

     function void set_message_attribute_int(longint unsigned handle,string attrName,int value);
       static string attr_name = "";
       static longint unsigned st_handle=0, st_value=0;

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",attrName);
`else
       attr_name = attrName;
`endif
//
       st_handle = handle;
       st_value = value;
       pli_inst.add_attribute_int(st_handle,st_value,attr_name);
     endfunction

     function void set_message_attribute_enum_severity(longint unsigned handle,string attrName,int severity);
       static uvm_severity severity_type;
       static string attr_name = "";
       static longint unsigned st_handle=0;

       case(severity)
         UVM_INFO: severity_type = UVM_INFO;
         UVM_WARNING: severity_type = UVM_WARNING;
         UVM_ERROR: severity_type = UVM_ERROR;
         UVM_FATAL: severity_type = UVM_FATAL;
       endcase
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",attrName);
`else
       attr_name = attrName;
`endif
//
       st_handle = handle;
       pli_inst.add_attribute_severity_type(st_handle,severity_type,attr_name);
     endfunction

     function void set_message_attribute_enum_verbosity(longint unsigned handle,string attrName,int verbosity);
       static uvm_verbosity verbosity_type;
       static string attr_name = "";
       static longint unsigned st_handle=0;

       case(verbosity)
         UVM_NONE: verbosity_type = UVM_NONE;
         UVM_LOW: verbosity_type = UVM_LOW;
         UVM_MEDIUM: verbosity_type = UVM_MEDIUM;
         UVM_HIGH: verbosity_type = UVM_HIGH;
         UVM_FULL: verbosity_type = UVM_FULL;
         UVM_DEBUG: verbosity_type = UVM_DEBUG;
       endcase
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       $sformat(attr_name,"+name+%s",attrName);
`else
       attr_name = attrName;
`endif
//
       st_handle = handle;
       pli_inst.add_attribute_verbosity_type(st_handle,verbosity_type,attr_name);
     endfunction

     function longint unsigned rmodel_begin_tr(longint unsigned stream_id,string event_label);
       static longint unsigned handle = 0;
       static string stream_name="", tr_name="", st_event_label="";
       static longint unsigned st_stream_id=0;

       if (streamArrByHandle.exists(stream_id))
           stream_name = streamArrByHandle[stream_id];
       tr_name = {stream_name, ".","stream_attribute"};
       st_stream_id = stream_id;
       handle = pli_inst.begin_tr(st_stream_id,"+type+transaction");
       if (handle==0) begin
           $display("Failed to create transaction!");
           return handle;
       end
       uvmHandle = uvmHandle + 1;
       uvmPliHandleMap[uvmHandle] = handle;
       transactionArrByHandle[uvmHandle] = tr_name;
       // label
       st_event_label = event_label; 
       pli_inst.set_label(handle,st_event_label);
       return handle;
     endfunction
     
     function void rmodel_end_tr (longint unsigned handle, time end_time=0);
       static longint unsigned st_handle=0;

       st_handle = handle;
       pli_inst.end_tr(st_handle);
     endfunction

     function void create_register_mirrored_desired_event(longint unsigned stream_id,string event_type,string path_s,string value_s,string mirrored_s,string desired_s);
       string label="";
       longint unsigned tr_h=0;

       $sformat(label,"%s Value",event_type);
       tr_h = rmodel_begin_tr(stream_id,label);
       if (tr_h>0) begin
          // Path
          set_message_attribute_str(tr_h,"path",path_s);
          // Value
          set_message_attribute_str(tr_h,"value",value_s);
          rmodel_end_tr(tr_h);
       end
     endfunction

     function void create_uvm_reg_map_event(longint unsigned stream_id,string event_type,string value_s,string address_s);
       string label="";
       longint unsigned tr_h=0;

       $sformat(label,"%s Value",event_type);
       tr_h = rmodel_begin_tr(stream_id,label);
       if (tr_h>0) begin
          // Value
          set_message_attribute_str(tr_h,"value",value_s);
          // Address
          set_message_attribute_str(tr_h,"address",address_s);
          rmodel_end_tr(tr_h);
       end
     endfunction

     function void generate_domain_phase_array();
       uvm_domain domains[string];
       uvm_phase phases[$];
       string domain_phase_name;

       uvm_domain::get_domains(domains);
       foreach(domains[c]) begin
          domains[c].m_get_transitive_children(phases);
          foreach(phases[c]) begin
             domain_phase_name = {phases[c].get_domain_name()," ",phases[c].get_name()};
             domain_phase_array[domain_phase_name] = phases[c];
          end
       end
     endfunction

     function void assign_domain_name(uvm_report_object client, int handle);
       uvm_objection tobj;

       if($cast(tobj, client)) begin
         foreach(domain_phase_array[c]) begin
            if(domain_phase_array[c].phase_done==null)
               return;
            if(tobj.get_inst_id()== domain_phase_array[c].phase_done.get_inst_id()) begin
               set_message_attribute_str(handle,"domain_name",domain_phase_array[c].get_domain_name());
            end
         end
       end
     endfunction

     virtual function action_e catch();
         static string file_name = "", label = "", message = "", stream = "", id = "", revised_stream = "";
         static string implicit_stream = "";
         int severity = 0;
         int line_num = 0, verbosity = 0, stream_len = 0;
         static string client_name = "";
         uvm_report_object  client = null;
         int position, position1, position2; 
         string val; //9001164313 
         string trace_args[$]; //9001164313
         static longint unsigned streamId = 0, handle = 0;
         string original_type_name, override_type_name, full_inst_path;
         action_e ret_action = THROW;
         verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst();
         static integer r_stream_h=0;
         static string reg_full_name="",value_s="",address_s="",mirrored_s="",desired_s="",event_type="",path_s="";
         static string comp_label,comp_message,comp_severity,comp_stream,comp_name;
         static string comp_full_name,comp_type_name,comp_full_type_name,comp_caller_name,comp_provider_name;
         static int objtn_maximum_option_check = 0;
         static int rsrc_option_check = 0;
         static int is_rsrc_inc_internal = 0;

         // Get UVM_OBJ_DUMP_LIMIT number and set it to objtn_trc_maximum
         if (objtn_maximum_option_check==0) begin
             string val_str="";

             objtn_maximum_option_check = 1;
             if (verdi_clp.get_arg_value("+UVM_OBJ_DUMP_LIMIT=", val_str))
                 objtn_trc_maximum = val_str.atoi();
         end
         //
         if (rsrc_option_check==0) begin
             string rsrc_args[$];

             rsrc_option_check = 1;
             if (verdi_clp.is_uvm_inc_internal_rsrc()) begin
                 is_rsrc_inc_internal = 1;
             end
         end

         if (verdi_catcher_counter==0)
             $display("*Verdi* Enable Verdi Message Catcher.");
         verdi_catcher_counter++;
         client = get_client();
         client_name = client.get_full_name();
         if (client_name=="")
             client_name = "reporter";
         file_name = get_fname();
         line_num = get_line();
         severity = get_severity();
         id = get_id();
         verbosity = get_verbosity();
         message = get_message();

         if (!plusargs_tested)
             void'(test_port_plusargs());

         if ((id == "SNPS_COMP_TRACE")||(id == "SNPS_PORT_TRACE"))
         begin
           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "%s: %s", id, message);
           end
           position = find_substr(message,"label:");
           position1 = find_substr(message,"name:");
           comp_label = message.substr(position+6,position1-2);
           position = find_substr(message,"full_name:");
           comp_name = message.substr(position1+5,position-2);
           position1 = find_substr(message,"type_name:");
           comp_full_name = message.substr(position+10,position1-2);
           position = find_substr(message,"full_type_name:");
           comp_type_name = message.substr(position1+10,position-2);
           comp_full_type_name = message.substr(position+15,message.len()-1);
           $sformat(comp_stream,"UVM.HIER_TRACE.%s",id); 
           if (!streamArrByName.exists(comp_stream)) begin
                streamId = pli_inst.create_stream_begin(comp_stream);
                streamArrByName[comp_stream] = streamId;
                pli_inst.add_dense_attribute_string(streamId,comp_name,"name");
                pli_inst.add_dense_attribute_string(streamId,comp_full_name,"full_name");
                pli_inst.add_dense_attribute_string(streamId,comp_type_name,"type_name");
                pli_inst.add_dense_attribute_string(streamId,comp_full_type_name,"full_type_name");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[comp_stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,comp_label);
           set_message_attribute_str(handle,"name",comp_name);
           set_message_attribute_str(handle,"full_name",comp_full_name);
           set_message_attribute_str(handle,"type_name",comp_type_name);
           set_message_attribute_str(handle,"full_type_name",comp_full_type_name);
           pli_inst.end_tr(handle);

           if ((verdi_clp.is_verdi_trace_dht()||verdi_clp.is_verdi_trace_msg()
               ||verdi_clp.is_verdi_trace_uvm_aware())
               && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
         end else
         if (id == "SNPS_PORT_CONN_TRACE") begin
           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "%s: %s", id, message);
           end
           position = find_substr(message,"label:");
           position1 = find_substr(message,"caller_name:");
           comp_label = message.substr(position+6,position1-2);
           position = find_substr(message,"provider_name:");
           comp_caller_name = message.substr(position1+12,position-2);
           comp_provider_name = message.substr(position+14,message.len()-1);
           $sformat(comp_stream,"UVM.HIER_TRACE.%s",id);
           if (!streamArrByName.exists(comp_stream)) begin
                streamId = pli_inst.create_stream_begin(comp_stream);
                streamArrByName[comp_stream] = streamId;
                pli_inst.add_dense_attribute_string(streamId,comp_caller_name,"caller_name");
                pli_inst.add_dense_attribute_string(streamId,comp_provider_name,"provider_name");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[comp_stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,comp_label);
           set_message_attribute_str(handle,"caller_name",comp_caller_name);
           set_message_attribute_str(handle,"provider_name",comp_provider_name);
           pli_inst.end_tr(handle);

           if ((verdi_clp.is_verdi_trace_dht()||verdi_clp.is_verdi_trace_msg()
               ||verdi_clp.is_verdi_trace_uvm_aware())
               && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
         end 
         else if ((id == "PH/TRC/STRT") ||
                 (id == "PH/TRC/SCHEDULED") ||
                 (id == "PH/TRC/DONE") ||
                 (id == "PH/TRC/SKIP") ||
                 (id == "PH/TRC/EXE/JUMP") ||
                 (id == "PH/TRC/EXE/ALLDROP") ||
                 (id == "PH_READY_TO_END") ||
                 (id == "PH_READY_TO_END_CB") ||
                 (id == "PH/TRC/TO_WAIT") ||
                 (id == "PH/TRC/TIMEOUT") ||
                 (id == "PH/TRC/TIMEOUT/OBJCTN") ||
                 (id == "PH/TRC/EXE/3") ||
                 (id == "PH_END") ||
                 (id == "PH/TRC/WAIT_PRED_OF_SUCC")) 
         begin
           string phase, domain, schedule, sub_message; 
           int inst_id;

           string phase_full_name;

           void'($sscanf(message, "Phase %s (id=%d) ", phase_full_name, inst_id));
           phase_full_name = phase_full_name.substr(1,phase_full_name.len()-2);
           deassemble_phase_full_name(phase_full_name,domain,schedule,phase);

           stream = "PH_TRC";
           stream = {stream, "_[", domain, "]"};
           $sformat(stream,"UVM.PHASE_TRACE.%s",stream);
 
           label = {id.substr(7, id.len()-1),": "};
           label = {label, phase};

           if (!streamArrByName.exists(stream)) begin
                streamId = pli_inst.create_stream_begin(stream);
                streamArrByName[stream] = streamId;
                //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                pli_inst.add_dense_attribute_string(streamId,schedule,"schedule");
                pli_inst.add_dense_attribute_int(streamId,inst_id,"inst_id");
                pli_inst.add_dense_attribute_string(streamId,phase,"phase");
                pli_inst.add_dense_attribute_string(streamId,domain,"domain");
                //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,label);
           //set_message_attribute_str(handle,"Msg",message);
           //set_message_attribute_int(handle,"Severity",severity);
           set_message_attribute_str(handle,"schedule",schedule);
           set_message_attribute_int(handle,"inst_id",inst_id);
           set_message_attribute_str(handle,"phase",phase);
           set_message_attribute_str(handle,"domain",domain);
           //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
           //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
           //set_message_attribute_str(handle,"file_name",file_name);
           //set_message_attribute_int(handle,"line_num",line_num);
           pli_inst.end_tr(handle);


           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "label=%s stream=%s schedule=%s inst_id=%0d phase=%s domain=%s",
                               label, stream, schedule, inst_id, phase, domain); 
           end
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg()) 
               && !verdi_clp.is_verdi_trace_print()
               && !verdi_clp.is_uvm_phase_trace()) //9001164313
               ret_action = CAUGHT;
         end
         else if (id == "PH_JUMP")
         begin
           string phase, domain, schedule;
           int inst_id;

           position = find_substr(message,"domain");
           position2 = find_substr(message,") is");
           domain = message.substr(position+7,position2-1);
           inst_id = -1;

           position2 = find_substr(message,"(schedule");
           schedule = message.substr(position2+10,position-3);
           phase = message.substr(6,position2-2);


           stream = "PH_TRC";
           stream = {stream, "_[", domain, "]"};
           $sformat(stream,"UVM.PHASE_TRACE.%s",stream);

           label = {id.substr(3, id.len()-1),": "};
           label = {label, phase};
           position = find_substr(message,"jumping to");
           label = {label, " -> ", message.substr(position+17,message.len()-1)};

           if (!streamArrByName.exists(stream)) begin
                streamId = pli_inst.create_stream_begin(stream);
                streamArrByName[stream] = streamId;
                //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                pli_inst.add_dense_attribute_string(streamId,schedule,"schedule");
                pli_inst.add_dense_attribute_int(streamId,inst_id,"inst_id");
                pli_inst.add_dense_attribute_string(streamId,phase,"phase");
                pli_inst.add_dense_attribute_string(streamId,domain,"domain");
                //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,label);
           //set_message_attribute_str(handle,"Msg",message);
           //set_message_attribute_int(handle,"Severity",severity);
           set_message_attribute_str(handle,"schedule",schedule);
           set_message_attribute_int(handle,"inst_id",inst_id);
           set_message_attribute_str(handle,"phase",phase);
           set_message_attribute_str(handle,"domain",domain);
           //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
           //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
           //set_message_attribute_str(handle,"file_name",file_name);
           //set_message_attribute_int(handle,"line_num",line_num);
           pli_inst.end_tr(handle);


           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "label=%s stream=%s schedule=%s inst_id=%0d phase=%s domain=%s",
                               label, stream, schedule, inst_id, phase, domain);
           end
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg())
               && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
         end
         else if (id == "OBJTN_TRC") begin
           // Skip recording if objtn_raise_drop_num is larger than maximum
           // If objtn_trc_maximum is 0, it means recording all objection messages
           if (((objtn_raise_drop_num<objtn_trc_maximum)||(objtn_trc_maximum==0))&& 
              (message.substr(7,13) == "uvm_top") && (find_substr(message,"all_dropped") == -1) 
              && (find_substr(message,"uvm_top raised") == -1) && 
              (find_substr(message,"uvm_top dropped") == -1))
           begin
             int count, total;
             string source, action, description, sub_message; 

             objtn_trc_num++;
             if (objtn_trc_num==1) begin
                 generate_domain_phase_array();
             end
             stream = {"OBJ_TRC_[", client_name, "]"};
             $sformat(stream,"UVM.OBJ_TRACE.%s",stream);
          
             position = find_substr(message,"added");
             position1 = find_substr(message,"subtracted"); 
             if (position != -1) begin
               position2 = find_substr(message,"objection");
               label = {"ADD ", message.substr(position+6,position2-1)};
               action = "raised";
             end
             else if (position1 != -1) begin 
               position2 = find_substr(message,"objection");
               label = {"SUB ", message.substr(position1+11,position2-1)};
               action = "dropped";
             end

             position = find_substr(message,"count=");
             label = {label, "(", message.substr(position, message.len()-1),")"};
 
             position2 = find_substr(message,"total=");
             sub_message = message.substr(position+6,position2-2);
             count = sub_message.atoi(); 
             sub_message =  message.substr(position2+6,message.len()-1); 
             total = sub_message.atoi(); 

             position = find_substr(message,"source object");
             position1 = find_substr(message,"): count");
             position2 = find_substr(message,", ");
             if (position2 == -1) position2 = position1;
             else description = message.substr(position2+2,position1-1);
             source = message.substr(position+14,position2-1);

             if (!streamArrByName.exists(stream)) begin
                  streamId = pli_inst.create_stream_begin(stream);
                  streamArrByName[stream] = streamId;
                  //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                  //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                  pli_inst.add_dense_attribute_string(streamId,source,"source");
                  pli_inst.add_dense_attribute_int(streamId,total,"total");
                  pli_inst.add_dense_attribute_int(streamId,count,"count");
                  pli_inst.add_dense_attribute_string(streamId,action,"action");
                  pli_inst.add_dense_attribute_string(streamId,description,"description");
                  //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                  //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                  //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                  //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                  pli_inst.create_stream_end(streamId);
             end else begin
                  streamId = streamArrByName[stream];
             end
             handle = pli_inst.begin_tr(streamId,"+type+message");
             if (handle==0) begin
                 $display("Failed to create transaction!\n");
                 return THROW;
             end
             pli_inst.set_label(handle,label);
             //set_message_attribute_str(handle,"Msg",message);
             //set_message_attribute_int(handle,"Severity",severity);
             set_message_attribute_str(handle,"source",source);
             set_message_attribute_int(handle,"total",total);
             set_message_attribute_int(handle,"count",count);
             set_message_attribute_str(handle,"action",action);
             set_message_attribute_str(handle,"description",description);
             //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
             //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
             //set_message_attribute_str(handle,"file_name",file_name);
             //set_message_attribute_int(handle,"line_num",line_num);
             assign_domain_name(client,handle);
             pli_inst.end_tr(handle);
             if (is_verdi_debug_enabled()) begin
               $fdisplay(file_h, "label=%s stream=%s source=%s total=%0d count=%0d action=%s description=%s",label, stream, source, total, count, action, description); 
             end
           end
           // Skip recording if objtn_raise_drop_num is larger than maximum
           // If objtn_trc_maximum is 0, it means recording all objection messages
           else if (((objtn_raise_drop_num<objtn_trc_maximum)||(objtn_trc_maximum==0))&&
              (find_substr(message,"subtracted") == -1) && (find_substr(message,"all_dropped") == -1) 
              && (find_substr(message,"added") == -1))
           begin
             int count, total;
             string source, action, description, sub_message; 

             objtn_trc_num++;
             if (objtn_trc_num==1) begin
                 generate_domain_phase_array();
             end
             stream = {"OBJ_TRC_[", client_name, "]"};
             $sformat(stream,"UVM.OBJ_TRACE.%s",stream);

             position = find_substr(message,"raised");
             position1 = find_substr(message,"dropped"); 
             if (position != -1) begin
               position2 = find_substr(message,"objection");
               label = {"RAISE ", message.substr(position+7,position2-1)};
               action = "raised";
               objtn_raise_drop_num++;
             end
             else if (position1 != -1) begin 
               position2 = find_substr(message,"objection");
               label = {"DROP ", message.substr(position1+8,position2-1)};
               action = "dropped";
               objtn_raise_drop_num++;
             end

             position = find_substr(message,"count=");
             label = {label, "(", message.substr(position, message.len()-1),")"};

             position2 = find_substr(message,"total=");
             sub_message = message.substr(position+6,position2-2); 
             count = sub_message.atoi();
             sub_message =  message.substr(position2+6,message.len()-1); 
             total = sub_message.atoi(); 

             position = find_substr(message,"Object");
             position1 = find_substr(message,"): count");
             position2 = find_substr(message,", ");
             if (position2 == -1) position2 = position1;
             else description = message.substr(position2+2,position1-1);
             position1 = find_substr(message,"raised");
             position2 = find_substr(message,"dropped");
             if (position1 != -1) begin
                 source = message.substr(position+7,position1-2);
             end
             else if (position2 != -1) begin
                 source = message.substr(position+7,position2-2);
             end

             if (!streamArrByName.exists(stream)) begin
                  streamId = pli_inst.create_stream_begin(stream);
                  streamArrByName[stream] = streamId;
                  //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                  //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                  pli_inst.add_dense_attribute_string(streamId,source,"source");
                  pli_inst.add_dense_attribute_int(streamId,total,"total");
                  pli_inst.add_dense_attribute_int(streamId,count,"count");
                  pli_inst.add_dense_attribute_string(streamId,action,"action");
                  pli_inst.add_dense_attribute_string(streamId,description,"description");
                  //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                  //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                  //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                  //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                  pli_inst.create_stream_end(streamId);
             end else begin
                  streamId = streamArrByName[stream];
             end
             handle = pli_inst.begin_tr(streamId,"+type+message");
             if (handle==0) begin
                 $display("Failed to create transaction!\n");
                 return THROW;
             end
             pli_inst.set_label(handle,label);
             //set_message_attribute_str(handle,"Msg",message);
             //set_message_attribute_int(handle,"Severity",severity);
             set_message_attribute_str(handle,"source",source);
             set_message_attribute_int(handle,"total",total);
             set_message_attribute_int(handle,"count",count);
             set_message_attribute_str(handle,"action",action);
             set_message_attribute_str(handle,"description",description);
             //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
             //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
             //set_message_attribute_str(handle,"file_name",file_name);
             //set_message_attribute_int(handle,"line_num",line_num);
             assign_domain_name(client,handle);
             pli_inst.end_tr(handle);
             if (is_verdi_debug_enabled()) begin
               $fdisplay(file_h, "label=%s stream=%s source=%s total=%0d count=%0d action=%s description=%s",
                               label, stream, source, total, count, action, description);
             end
             // Create specific message if raise/drop message number is equal to maximum
             if (objtn_raise_drop_num==objtn_trc_maximum) begin
                 handle = pli_inst.begin_tr(streamId,"+type+message");
                 if (handle==0) begin
                     $display("Failed to create transaction!\n");
                     return THROW;
                 end
                 label = "Maximum Reached";
                 pli_inst.set_label(handle,label);
                 set_message_attribute_int(handle,"Maximum",objtn_trc_maximum);
                 pli_inst.end_tr(handle);
             end
             //
           end
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg())
               && !verdi_clp.is_verdi_trace_print()
               && !verdi_clp.is_uvm_objection_trace())//9001164313
               ret_action = CAUGHT;
         end
         else if (id == "OBJTN_CLEAR")
         begin
           int count = 0, total = 0;
           string source = "";
           string action = "cleared";
           string description = "";

           stream = {"OBJ_TRC_[", client_name, "]"};
           $sformat(stream,"UVM.OBJ_TRACE.%s",stream);
           label = "CLR (count=0 total=0)";

           position = find_substr(message,"Object");
           position1 = find_substr(message,"): count");
           position2 = find_substr(message,", ");
           if (position2 == -1) position2 = position1;
           else description = message.substr(position2+2,position1-1);
           position1 = find_substr(message,"cleared");
           if (position1 != -1) begin
               source = message.substr(position+7,position1-2);
           end

           if (!streamArrByName.exists(stream)) begin
                streamId = pli_inst.create_stream_begin(stream);
                streamArrByName[stream] = streamId;
                //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                pli_inst.add_dense_attribute_string(streamId,source,"source");
                pli_inst.add_dense_attribute_int(streamId,total,"total");
                pli_inst.add_dense_attribute_int(streamId,count,"count");
                pli_inst.add_dense_attribute_string(streamId,action,"action");
                pli_inst.add_dense_attribute_string(streamId,description,"description");
                //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,label);
           //set_message_attribute_str(handle,"Msg",message);
           //set_message_attribute_int(handle,"Severity",severity);
           set_message_attribute_str(handle,"source",source);
           set_message_attribute_int(handle,"total",total);
           set_message_attribute_int(handle,"count",count);
           set_message_attribute_str(handle,"action",action);
           set_message_attribute_str(handle,"description",description);
           //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
           //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
           //set_message_attribute_str(handle,"file_name",file_name);
           //set_message_attribute_int(handle,"line_num",line_num);
           assign_domain_name(client,handle);
           pli_inst.end_tr(handle);


           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "label=%s stream=%s source=%s total=%0d count=%0d action=%s description=%s",
                               label, stream, source, total, count, action, description);
           end
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg())
               && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
         end
         else if ((id == "CFGDB/SET") || (id == "CFGDB/GET") ||
                  (id == "RSRCDB/SET") /*|| (id == "RSRCDB/SETANON")*/ || (id == "RSRCDB/SETOVRD") ||
                  /*(id == "RSRCDB/SETOVRDTYP") ||*/ (id == "RSRCDB/SETOVRDNAM") || (id == "RSRCDB/RDBYNAM") ||
                  /*(id == "RSRCDB/RDBYTYP") ||*/ (id == "RSRCDB/WR") /*|| (id == "RSRCDB/WRTYP")*/)
         begin
           string scope_and_field, scope_name, field_name, type_name, action, accessor, resource, failed;
           string tmp_name;
           rsrc_msg_struct msg_struct;
           bit is_check_connection_relationships=0,is_recording_detail=0, is_default_sequence=0; 
`ifndef UVM_NO_VERDI_DPI
           string found_rsrc_obj_name;
           bit question_mark_rsrc, vif_class_type;
`endif            

`ifdef VERDI_MSG_PARSE_DPI
           void'(parse_rsrc_msg(message, msg_struct));
`else
           position = find_substr(message," '");
           position1 = find_substr(message,"' (type ");
           scope_and_field = message.substr(position+2,position1-1);
           position = find_substr(message,") ");
           msg_struct.type_name = message.substr(position1+8,position-1);
           position1 = find_substr(message," by ");
           msg_struct.action = message.substr(position+2,position1-1);
           position = find_substr(message," = ");
           msg_struct.accessor = message.substr(position1+4,position-1);
           msg_struct.resource = message.substr(position+3,message.len()-1);
           position = find_substr_bw(scope_and_field,".");

           if(position!=-1) begin
              msg_struct.scope_name = scope_and_field.substr(0,position-1);
              msg_struct.field_name = scope_and_field.substr(position+1,scope_and_field.len()-1);
           end else begin
              msg_struct.scope_name = scope_and_field;
              msg_struct.field_name = "";
           end
`endif
           if (!is_rsrc_inc_internal && msg_struct.field_name=="check_connection_relationships")
               is_check_connection_relationships = 1;
           if (!is_rsrc_inc_internal && msg_struct.field_name=="recording_detail")
               is_recording_detail = 1;
           if (!is_rsrc_inc_internal && msg_struct.field_name=="default_sequence")
               is_default_sequence = 1;

`ifndef UVM_NO_VERDI_DPI
           found_rsrc_obj_name = "";
           question_mark_rsrc  =  0;
           vif_class_type      = 0;
           if(msg_struct.resource!="" && msg_struct.resource[msg_struct.resource.len()-1] == "?")
              question_mark_rsrc =  1;
           if(msg_struct.type_name!="" && msg_struct.resource.substr(0, 4)!="null " && (msg_struct.type_name.substr(0,17) == "virtual interface " || msg_struct.type_name.substr(0,5) == "class "))
              vif_class_type = 1;

           if(question_mark_rsrc || vif_class_type) begin
              found_rsrc_obj_name = { $psprintf("%0s", verdi_dump_rsrc_obj(msg_struct.scope_name, msg_struct.field_name))};
           end

           if(found_rsrc_obj_name!="")
              msg_struct.resource = (question_mark_rsrc!=1 && msg_struct.resource!="") ? {found_rsrc_obj_name, ":", msg_struct.resource} : found_rsrc_obj_name;
`endif
           if (msg_struct.field_name[msg_struct.field_name.len()-1]==" ") begin
               tmp_name = msg_struct.field_name.substr(0,msg_struct.field_name.len()-2);
               msg_struct.field_name = tmp_name;
           end

           failed = "";
           if (msg_struct.resource.substr(0,4) == "null ") failed = " - failed lookup";
           if (id.substr(0,4) == "CFGDB") begin
             label = {id.substr(6,8),failed};
             stream = {"CFGDB_[",msg_struct.field_name,"]"};
           end
           else begin
             label = {id.substr(7,id.len()-1),failed};
             stream = {"RSRCDB_[",msg_struct.field_name,"]"};
           end

           // 9001175645 Don't record check_connection_relationships and recording_detail by default
           if (is_check_connection_relationships==0 && is_recording_detail==0
               && is_default_sequence==0) begin
           $sformat(stream,"UVM.RSRC_TRACE.%s",stream); 

           if (!streamArrByName.exists(stream)) begin
                streamId = pli_inst.create_stream_begin(stream);
                streamArrByName[stream] = streamId;
                //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                pli_inst.add_dense_attribute_string(streamId,msg_struct.scope_name,"scope_name");
                pli_inst.add_dense_attribute_string(streamId,msg_struct.field_name,"field_name");
                pli_inst.add_dense_attribute_string(streamId,msg_struct.type_name,"type_name");
                pli_inst.add_dense_attribute_string(streamId,msg_struct.action,"action");
                pli_inst.add_dense_attribute_string(streamId,msg_struct.accessor,"accessor");
                pli_inst.add_dense_attribute_string(streamId,msg_struct.resource,"resource");
                //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,label);
           //set_message_attribute_str(handle,"Msg",message);
           //set_message_attribute_int(handle,"Severity",severity);
           set_message_attribute_str(handle,"scope_name",msg_struct.scope_name);
           set_message_attribute_str(handle,"field_name",msg_struct.field_name);
           set_message_attribute_str(handle,"type_name",msg_struct.type_name);
           set_message_attribute_str(handle,"action",msg_struct.action);
           set_message_attribute_str(handle,"accessor",msg_struct.accessor);
           set_message_attribute_str(handle,"resource",msg_struct.resource);
           //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
           //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
           //set_message_attribute_str(handle,"file_name",file_name);
           //set_message_attribute_int(handle,"line_num",line_num);
           pli_inst.end_tr(handle);
           end

           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "label=%s stream=%s scope_name=%s field_name=%s type_name=%s action=%s accessor=%s resource=%s",
                               label, stream, msg_struct.scope_name, msg_struct.field_name, msg_struct.type_name, msg_struct.action, msg_struct.accessor, msg_struct.resource);
           end
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg())
               && !verdi_clp.is_verdi_trace_print()
               && !verdi_clp.is_uvm_resource_db_trace()//9001164313 
               && !verdi_clp.is_uvm_config_db_trace())//9001164313
               ret_action = CAUGHT;
         end
         else if (id=="FAC/CREATE"||id=="FAC/SET") begin
           position = find_substr(message,"original_type_name");
           position1 = find_substr(message,"override_type_name");
           original_type_name = message.substr(position+19,position1-2);
           position = find_substr(message,"override_type_name");
           position1 = find_substr(message,"full_inst_path");
           override_type_name = message.substr(position+19,position1-2);
           full_inst_path = message.substr(position1+15,message.len()-1);
           if (id=="FAC/CREATE")
               label = {"CREATE ",override_type_name}; 
           else if (id=="FAC/SET")
               label = {"SET ",override_type_name};
           stream = {"Factory_[",original_type_name,"]"};
           $sformat(stream,"UVM.FAC_TRACE.%s",stream);
           //$sformat(stream,"UVM.FAC_TRACE.Factory_seq_item#(MODE_WIDTH, DELAY_WIDTH, HYST_WIDTH)");
           stream_len = stream.len();
           revised_stream = "";
           for (int pos = 0; pos <stream_len; pos++) begin
                if (stream[pos] != " ")
                    revised_stream = {revised_stream,stream[pos]};
           end 
           if (!streamArrByName.exists(revised_stream)) begin
                streamId = pli_inst.create_stream_begin(revised_stream);
                streamArrByName[revised_stream] = streamId;
                pli_inst.add_dense_attribute_string(streamId,full_inst_path,"instance");
                pli_inst.add_dense_attribute_string(streamId,original_type_name,"original_type");
                pli_inst.add_dense_attribute_string(streamId,override_type_name,"override_type");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[revised_stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return CAUGHT;
           end
           pli_inst.set_label(handle,label);
           set_message_attribute_str(handle,"instance",full_inst_path);
           set_message_attribute_str(handle,"original_type",original_type_name);
           set_message_attribute_str(handle,"override_type",override_type_name);
           pli_inst.end_tr(handle);
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg())
               && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
         end
         else if (id=="RegModel") begin
           static string stream_type = "register",des_str="";

           if ((verdi_clp.is_verdi_trace_uvm_aware() && !verdi_clp.is_verdi_trace_ral()
               && !verdi_clp.is_verdi_trace_msg() && !is_reg_hier_dumping) || 
               (verdi_clp.is_verdi_trace_uvm_aware() && verdi_clp.is_verdi_trace_ral() 
               && severity!=UVM_INFO))
               return THROW;
           //9001162946
           if (verdi_clp.is_verdi_trace_uvm_aware() && !verdi_clp.is_verdi_trace_ral()
               && is_reg_hier_dumping)
               return CAUGHT;
           // End
           if (reg_trc_num==0 && is_dhier_visited==1 && is_reg_hier_recorded==0)
               is_reg_hier_recorded = record_reg_hier();
           reg_trc_num++;
           reg_full_name = "";
           position = find_substr(message," ");
           event_type = message.substr(0,position-1);
           if (event_type=="Peeked" || event_type=="Poked") begin
               position = find_substr(message,"register");
               if (position>0) begin 
                   position = find_substr(message,"register");
                   position1 = find_substr(message,":");
                   reg_full_name = message.substr(position+10,position1-2);
                   position = find_substr(message,":");
                   value_s = message.substr(position+2,message.len()-1);
               end else begin
                   position = find_substr(message,"memory");
                   if (event_type=="Peeked") begin
                       position1 = find_substr(message,"has");
                   end else if (event_type=="Poked") begin
                       position1 = find_substr(message,"with");
                   end
                   reg_full_name = message.substr(position+8,position1-3);
                   position = find_substr(message,"value");
                   value_s = message.substr(position+6,message.len()-1);
               end 
           end else begin
               position = find_substr(message,"register");
               event_type = message.substr(0,position-2);
               if (position<0) begin
                   position = find_substr(message,"memory");
                   event_type = message.substr(0,position-2);
               end
               position = find_substr(message,":");
               position1 = find_substr(message,"=");
               if (event_type!="")
                   reg_full_name = message.substr(position+2,position1-1);
               position = find_substr(message,"=");
               value_s = message.substr(position+1,message.len()-1);
               if (position1<0) begin
                   value_s = message.substr(position+1,message.len()-1);
               end 
               position = find_substr(message,"map");
               position1 = find_substr(message,":");
               if (position>0) begin
                   path_s = message.substr(position+4,position1-1);
               end else begin
                   position = find_substr(message,"DPI");
                   path_s = message.substr(position+4,position1-1);
               end
           end
           begin
              uvm_map_access_recorder _mapr_inst;

              _mapr_inst = uvm_map_access_recorder::get_inst();

              if (!_mapr_inst.end_recording(event_type, path_s, value_s, reg_full_name)) begin
                 if (reg_full_name!="")
                     $sformat(reg_full_name,"UVM.RAL_TRACE.%s",reg_full_name);

                 if (streamArrByName.exists(reg_full_name)) begin
                     r_stream_h = streamArrByName[reg_full_name];
                     create_register_mirrored_desired_event(r_stream_h,event_type,path_s,value_s,mirrored_s,desired_s);
                 end else if (reg_full_name!="") begin
// 9001353389
`ifdef VERDI_REPLACE_DPI_WITH_PLI
                     des_str = {"+description+type=",stream_type};
`else
                     des_str = {"type=",stream_type};
`endif
                     r_stream_h = pli_inst.create_stream_begin(reg_full_name,des_str);
                     streamArrByName[reg_full_name] = r_stream_h;
                     pli_inst.create_stream_end(r_stream_h);
                     create_register_mirrored_desired_event(r_stream_h,event_type,path_s,value_s,mirrored_s,desired_s);
                 end

              end
           end
           // 9001338477
           if (((verdi_clp.is_verdi_trace_ral()&&severity==UVM_INFO&&user_verbosity<UVM_HIGH)
               ||verdi_clp.is_verdi_trace_msg())
                && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
           //
         end
         else if (id=="uvm_reg_map") begin
           string map_full_name, access_status;
           bit is_status_access;

           is_status_access = 0;
           if ((verdi_clp.is_verdi_trace_uvm_aware() && !verdi_clp.is_verdi_trace_ral()
               && !verdi_clp.is_verdi_trace_msg()) || severity!=UVM_INFO)
               return THROW;
           position = find_substr(message," ");
           event_type = message.substr(0,position-1);
           case (event_type)
             "Reading": begin
               position = find_substr(message,"address");
               position1 = find_substr(message,"via");
               address_s = message.substr(position+8,position1-2);
               position = find_substr(message,"\"");
               position1 = find_substr(message,"...");
               map_full_name = message.substr(position+1,position1-2);
             end
             "Read": begin
               position1 = find_substr(message,"at");
               value_s = message.substr(position+1,position1-2);
               position = find_substr(message,"via");
               address_s = message.substr(position1+3,position-2);
               position = find_substr(message,"\"");
               position1 = find_substr(message,":");
               map_full_name = message.substr(position+1,position1-2);
               position = find_substr(message, "...");
               access_status = message.substr(position1+1, position-1);
               is_status_access = 1;
             end
             "Writing": begin
               position1 = find_substr(message,"at");
               value_s = message.substr(position+1,position1-2);
               position = find_substr(message,"via");
               address_s = message.substr(position1+3,position-2);
               position = find_substr(message,"\"");
               position1 = find_substr(message,"...");
               map_full_name = message.substr(position+1,position1-2);
             end
             "Wrote": begin
               position1 = find_substr(message,"at");
               value_s = message.substr(position+1,position1-2);
               position = find_substr(message,"via");
               address_s = message.substr(position1+3,position-2);
               position = find_substr(message,"\"");
               position1 = find_substr(message,":");
               map_full_name = message.substr(position+1,position1-2);
               position = find_substr(message, "...");
               access_status = message.substr(position1+1, position-1);
               is_status_access = 1;
             end
           endcase
           begin
              uvm_reg_addr_logic_t hex_address;
              uvm_map_access_recorder _mapr_inst;
              _mapr_inst = uvm_map_access_recorder::get_inst();

              hex_address = address_s.atohex();

              if(is_status_access==0) begin
                 uvm_map_access_recorder _mapr_inst;

                 _mapr_inst = uvm_map_access_recorder::get_inst();
                 _mapr_inst.begin_recording(hex_address, map_full_name, event_type);
              end else if(is_status_access) begin
                 _mapr_inst.insert_access_status(hex_address, map_full_name, access_status);
              end
           end
           if ((verdi_clp.is_verdi_trace_ral()||verdi_clp.is_verdi_trace_msg())
                && !verdi_clp.is_verdi_trace_print())
               ret_action = CAUGHT;
         end
         else if (id=="VERDI_TR_AUTO") begin
           return THROW; 
         end
         else if (id=="CFGAPL") begin
           string field_name = "", scope_name = "", value_str = "";
           string type_name = "", resource_name="";

           position = find_substr(message,"field");
           if (position<0)
               return THROW;
           position1 = find_substr(message,"type");
           field_name = message.substr(position+6,position1-2);
           position = find_substr(message,"type");
           position1 = find_substr(message,"value");
           type_name = message.substr(position+5,position1-2);
           position = find_substr(message,"value=");
           value_str = message.substr(position+6,message.len()-1);
           if (type_name=="string")
               $sformat(resource_name,"(%s) \"%s\"",type_name,value_str);
           else
               $sformat(resource_name,"(%s) %s",type_name,value_str);
           stream = {"CFGDB_[",field_name,"]"};
           $sformat(stream,"UVM.RSRC_TRACE.%s",stream);
           implicit_stream = "";
           stream_len = stream.len();
           for (int pos = 0; pos <stream_len; pos++) begin
                if (stream[pos] != " ")
                    implicit_stream = {implicit_stream,stream[pos]};
           end
           if (!streamArrByName.exists(implicit_stream)) begin
                streamId = pli_inst.create_stream_begin(implicit_stream);
                streamArrByName[implicit_stream] = streamId;
                pli_inst.add_dense_attribute_string(streamId,client_name,"scope_name");
                pli_inst.add_dense_attribute_string(streamId,field_name,"field_name");
                pli_inst.add_dense_attribute_string(streamId,type_name,"type_name");
                pli_inst.add_dense_attribute_string(streamId,"implicit_get","action");
                pli_inst.add_dense_attribute_string(streamId,client_name,"accessor");
                pli_inst.add_dense_attribute_string(streamId,resource_name,"resource");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[implicit_stream];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return CAUGHT;
           end
           label = "IMPLICIT_GET";
           pli_inst.set_label(handle,label);
           set_message_attribute_str(handle,"scope_name",client_name);
           set_message_attribute_str(handle,"field_name",field_name);
           set_message_attribute_str(handle,"type_name",type_name);
           set_message_attribute_str(handle,"action","implcit_get");
           set_message_attribute_str(handle,"accessor",client_name);
           set_message_attribute_str(handle,"resource",resource_name);
           pli_inst.end_tr(handle);
           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "label=%s stream=%s scope_name=%s field_name=%s type_name=%s action=implicit_get accessor=%s resource=%s",
                               label, stream, scope_name, field_name, type_name, client_name, resource_name);
           end
           if ((verdi_clp.is_verdi_trace_uvm_aware()||verdi_clp.is_verdi_trace_msg())
               && !verdi_clp.is_verdi_trace_print()
               && !verdi_clp.is_uvm_resource_db_trace()//9001164313
               && !verdi_clp.is_uvm_config_db_trace())//9001164313
               ret_action = CAUGHT;
         end
         else begin
           if (message.len() > 30) begin
               position = 30;
               label = {message.substr(0,position)," ..."};
           end else begin position = message.len()-1;
               label = message;
           end 
`ifndef UVM_VERDI_NO_VERDI_TRACE
           if ((verdi_clp.is_verdi_trace_uvm_aware()&&!verdi_clp.is_verdi_trace_msg())
               || (verdi_clp.is_verdi_trace_ral()&&!verdi_clp.is_verdi_trace_msg())
               || (verdi_clp.is_verdi_trace_dht()&&!verdi_clp.is_verdi_trace_msg()))
               return THROW;
`endif
           if (!streamArrByName.exists(client_name)) begin
                streamId = pli_inst.create_stream_begin(client_name);
                streamArrByName[client_name] = streamId;
                //pli_inst.add_dense_attribute_string(streamId,message,"Msg");
                //pli_inst.add_dense_attribute_int(streamId,severity,"Severity");
                pli_inst.add_dense_attribute_string(streamId,id,"id");
                //pli_inst.add_dense_attribute_enum_severity_type(streamId,severity,"uvm_severity");
                //pli_inst.add_dense_attribute_enum_verbosity_type(streamId,verbosity,"uvm_verbosity");
                //pli_inst.add_dense_attribute_string(streamId,file_name,"file_name");
                //pli_inst.add_dense_attribute_int(streamId,line_num,"line_num");
                pli_inst.create_stream_end(streamId);
           end else begin
                streamId = streamArrByName[client_name];
           end
           handle = pli_inst.begin_tr(streamId,"+type+message");
           if (handle==0) begin
               $display("Failed to create transaction!\n");
               return THROW;
           end
           pli_inst.set_label(handle,label);
           //set_message_attribute_str(handle,"Msg",message);
           //set_message_attribute_int(handle,"Severity",severity);
           set_message_attribute_str(handle,"id",id);
           //set_message_attribute_enum_severity(handle,"uvm_severity",severity);
           //set_message_attribute_enum_verbosity(handle,"uvm_verbosity",verbosity);
           //set_message_attribute_str(handle,"file_name",file_name);
           //set_message_attribute_int(handle,"line_num",line_num);
           pli_inst.end_tr(handle);
           if (is_verdi_debug_enabled()) begin
             $fdisplay(file_h, "label=%s stream=%s Msg=%s Severity=%0d id=%s verbosity=%0d file_name=%s line_num=%0d",label, stream, message, severity, id, verbosity, file_name, line_num);
           end
           if (verdi_clp.is_verdi_trace_msg()&&!verdi_clp.is_verdi_trace_print()) 
               ret_action = CAUGHT;
         end
         return ret_action; 
     endfunction
endclass : verdi_report_catcher
`endif
