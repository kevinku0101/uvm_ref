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
`ifndef UVM_VERDI_RECORDER_SVH
`define UVM_VERDI_RECORDER_SVH

`include "uvm_verdi_pli_base.svh"
`include "uvm_verdi_tr_database.svh"

//integer streamArrByName [string];
static string  streamArrByHandle [integer];
static string  transactionArrByHandle [integer];
`ifdef VERDI_RECORD_RELATION
static longint  transactionArrByInstId [integer];
`endif
static int file_h = 0;
static string debug_log_file_name = "verdi_recorder_debug.log";
static uvm_verdi_pli_base pli_inst = uvm_verdi_pli_base::get_inst();

function bit open_debug_file();
  if (file_h == 0)
      file_h = $fopen(debug_log_file_name);
  return (file_h > 0);
endfunction

//------------------------------------------------------------------------------
//
// CLASS: uvm_verdi_recorder
//
// The ~uvm_verdi_recorder~ is the default recorder implementation for the
// <uvm_text_tr_database>.
//

class uvm_verdi_recorder extends uvm_recorder;

   `uvm_object_utils(uvm_verdi_recorder)

   // Variable- m_verdi_db
   //
   // Reference to the text database backend
   uvm_verdi_tr_database m_verdi_db;

   // Variable- scope
   // Imeplementation detail
   uvm_scope_stack scope = new;

   local static integer m_verdi_ids_by_recorder[uvm_verdi_recorder];
   local static uvm_recorder m_verdi_recorders_by_id[integer];
   integer m_tr_handle = 0;

   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Instance name
   function new(string name="unnamed-uvm_verdi_recorder");
      super.new(name);
   endfunction : new

   // Group: Implementation Agnostic API

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
      static longint unsigned st_pli_handle=0;

      if (desc=="")
          return;
      st_pli_handle = uvmPliHandleMap[txh];
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
          pli_inst.add_attribute_string(st_pli_handle, object_type_str, "+name+snps_object_id", "+numbit+0");
`else
          pli_inst.add_attribute_string(st_pli_handle, object_type_str, "snps_object_id", "");
`endif
//
          if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"set_attribute @%0t txh=%0d nm=%s value=%0s radix=%s numbits=%0s",$realtime,txh,"+name+object_type",object_type_str,"UVM_STRING",numbits_name);
          end
      end
      left_string_two = desc.substr(first_n_idx+1,first_n_idx+12);
      right_string_two = desc.substr(first_n_idx+15,second_n_idx-1);
      if (left_string_two=="Sequencer ID") begin
          sequencer_type_str = process_object_type(right_string_two);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
          pli_inst.add_attribute_string_hidden(st_pli_handle, sequencer_type_str, "+name+sequencer_type");
`else
          pli_inst.add_attribute_string_hidden(st_pli_handle, sequencer_type_str, "sequencer_type");
`endif
//
          if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"set_attribute @%0t txh=%0d nm=%s value=%0s radix=%s numbits=%0s",$realtime,txh,"+name+sequencer_type",sequencer_type_str,"UVM_STRING",numbits_name);
          end
      end
      left_string_three = desc.substr(second_n_idx+1,second_n_idx+5);
      right_string_three = desc.substr(second_n_idx+8,third_n_idx-1);
      if (left_string_three=="Phase") begin
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
          pli_inst.add_attribute_string_hidden(st_pli_handle, right_string_three, "+name+starting_phase");
`else
          pli_inst.add_attribute_string_hidden(st_pli_handle, right_string_three, "starting_phase");
`endif
//
          if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"set_attribute @%0t txh=%0d nm=%s value=%0s radix=%s numbits=%0s",$realtime,txh,"+name+starting_phase",right_string_three,"UVM_STRING",numbits_name);
          end
      end else begin
          left_string_three = desc.substr(second_n_idx+1,second_n_idx+18);
          right_string_three = desc.substr(second_n_idx+21,third_n_idx-1);
          if (left_string_three=="Parent Sequence ID") begin
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
              pli_inst.add_attribute_string_hidden(st_pli_handle, right_string_three, "+name+parent_sequence");
`else
              pli_inst.add_attribute_string_hidden(st_pli_handle, right_string_three, "parent_sequence");
`endif
//
              if (is_verdi_debug_enabled()) begin
                $fdisplay(file_h,"set_attribute @%0t txh=%0d nm=%s value=%0s radix=%s numbits=%0s",$realtime,txh,"+name+parent_sequence",right_string_three,"UVM_STRING",numbits_name);
              end
          end
      end
      left_string_four = desc.substr(third_n_idx+1,third_n_idx+18);
      right_string_four = desc.substr(third_n_idx+21,fourth_n_idx-1);
      if (left_string_four=="Parent Sequence ID") begin
// 6000025017 
`ifdef VERDI_REPLACE_DPI_WITH_PLI
          pli_inst.add_attribute_string_hidden(st_pli_handle, right_string_four, "+name+parent_sequence");
`else
          pli_inst.add_attribute_string_hidden(st_pli_handle, right_string_four, "parent_sequence");
`endif
//
          if (is_verdi_debug_enabled()) begin
            $fdisplay(file_h,"set_attribute @%0t txh=%0d nm=%s value=%0s radix=%s numbits=%0s",$realtime,txh,"+name+parent_sequence",right_string_four,"UVM_STRING",numbits_name);
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

   
   // Function: do_open
   // Callback triggered via <uvm_tr_stream::open_recorder>.
   //
   // Text-backend specific implementation.
   protected virtual function void do_open(uvm_tr_stream stream,
                                             time open_time,
                                             string type_name);
      static longint unsigned handle = 0, stream_id=0;
      static string event_label;
      uvm_verdi_tr_stream verdi_stream;

      $cast(m_verdi_db, stream.get_db());
      if (m_verdi_db.open_db()) begin
         $cast(verdi_stream,stream);
         stream_id = verdi_stream.get_handle();
         if (open_time == 0) begin
             handle = pli_inst.begin_tr(stream_id,"+type+transaction");
         end
         else begin
             string time_unit = get_time_unit();
             handle = pli_inst.begin_tr(stream_id, "+type+transaction", open_time, time_unit);
         end
         if (handle==0) begin
             $display("Failed to create transaction!");
             if (is_verdi_debug_enabled()) begin
                 $fdisplay(file_h,"Failed to create transaction!");
                 $fdisplay(file_h,"Failed OPEN_RECORDER @%0t {TXH:%0d STREAM:%0d NAME:%s TIME:%0t TYPE=\"%0s\"}",
                 $realtime,
                 this.get_handle(),
                 stream.get_handle(),
                 this.get_name(),
                 open_time,
                 type_name);
                 $fdisplay(file_h,"Failed begin_tr@%0t: streamId=%0d txh=%0d label=%s\n",
                        $realtime,stream_id,handle,event_label);
             end
             return;
         end
         $sformat(event_label,this.get_name());
         pli_inst.set_label(handle,event_label);
         uvmHandle = this.get_handle();
         uvmPliHandleMap[uvmHandle] = handle;
         if (is_verdi_debug_enabled()) begin
              $fdisplay(file_h,"    OPEN_RECORDER @%0t {TXH:%0d STREAM:%0d NAME:%s TIME:%0t TYPE=\"%0s\"}",
                 $realtime,
                 this.get_handle(),
                 stream.get_handle(),
                 this.get_name(),
                 open_time,
                 type_name);
              $fdisplay(file_h,"begin_tr@%0t: streamId=%0d txh=%0d label=%s\n",
                        $realtime,stream_id,handle,event_label);
         end
      end
   endfunction : do_open

   // Function: do_close
   // Callback triggered via <close>.
   //
   // Text-backend specific implementation.
   protected virtual function void do_close(time close_time);
      static longint pliHandle = 0;

      if (m_verdi_db.open_db()) begin
          m_tr_handle = this.get_handle(); 
          pliHandle = uvmPliHandleMap[m_tr_handle];
          pli_inst.end_tr(pliHandle);
          if (is_verdi_debug_enabled()) begin
               $fdisplay(file_h,"    CLOSE_RECORDER @%0t {TXH:%0d TIME=%0t}",
                   $realtime,
                   this.get_handle(),
                   close_time);
               $fdisplay(file_h,"end_tr@%0t txh=%0d\n",$realtime,pliHandle);
          end
      end
   endfunction : do_close

   // Function: do_free
   // Callback triggered via <free>.
   //
   // Text-backend specific implementation.
   protected virtual function void do_free();
      if (!plusargs_tested)
          void'(test_port_plusargs());
      if (m_verdi_db.open_db()) begin
          if (is_verdi_debug_enabled())
              $fdisplay(file_h,"    FREE_RECORDER @%0t {TXH:%0d}",
                   $realtime,
                   this.get_handle());
      end
      m_verdi_db = null;
   endfunction : do_free
   
   // Function: do_record_field
   // Records an integral field (less than or equal to 4096 bits).
   //
   // Text-backend specific implementation.
   protected virtual function void do_record_field(string name,
                                                   uvm_bitstream_t value,
                                                   int size,
                                                   uvm_radix_enum radix);
      scope.set_arg(name);
      if (!radix)
        radix = default_radix;
      
      write_attribute_int(scope.get(),
                      value,
                      radix,
                      size);

   endfunction : do_record_field
  
   
   // Function: do_record_field_int
   // Records an integral field (less than or equal to 64 bits).
   //
   // Text-backend specific implementation.
   protected virtual function void do_record_field_int(string name,
                                                       uvm_integral_t value,
                                                       int          size,
                                                       uvm_radix_enum radix);
      scope.set_arg(name);
      if (!radix)
        radix = default_radix;

      write_attribute_int(scope.get(),
                          value,
                          radix,
                          size);

   endfunction : do_record_field_int


   // Function: do_record_field_real
   // Record a real field.
   //
   // Text-backened specific implementation.
   protected virtual function void do_record_field_real(string name,
                                                        real value);
      bit [63:0] ival = $realtobits(value);
      scope.set_arg(name);

      write_attribute_int(scope.get(),
                          ival,
                          UVM_REAL,
                          64);
   endfunction : do_record_field_real

   // Function: do_record_object
   // Record an object field.
   //
   // Text-backend specific implementation.
   //
   // The method uses <identifier> to determine whether or not to
   // record the object instance id, and <recursion_policy> to
   // determine whether or not to recurse into the object.
   protected virtual function void do_record_object(string name,
                                                    uvm_object value);
      int            v;
      string         str;
      
      if(identifier) begin 
         if(value != null) begin
            $swrite(str, "%0d", value.get_inst_id());
            v = str.atoi(); 
         end
         scope.set_arg(name);
         write_attribute_int(scope.get(), 
                             v, 
                             UVM_DEC, 
                             32);
      end
 
      if(policy != UVM_REFERENCE) begin
         if(value!=null) begin
            if(value.__m_uvm_status_container.cycle_check.exists(value)) return;
            value.__m_uvm_status_container.cycle_check[value] = 1;
            scope.down(name);
            value.record(this);
            scope.up();
            value.__m_uvm_status_container.cycle_check.delete(value);
         end
      end
   endfunction : do_record_object

   // Function: do_record_string
   // Records a string field.
   //
   // Text-backend specific implementation.
   protected virtual function void do_record_string(string name,
                                                    string value);
      static longint pliHandle = 0;
      static string val_name="",attr_name="",numbits_name="";

      m_tr_handle = this.get_handle();
      pliHandle = uvmPliHandleMap[m_tr_handle];
      scope.set_arg(name);
      if (m_verdi_db.open_db()) begin
          if (name=="desc") begin
              process_desc(value,m_tr_handle); 
          end else begin 
              val_name = value;
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
              $sformat(attr_name,"+name+%s",scope.get());//Verdi 9001179360
              $sformat(numbits_name,"+numbit+%0d",8*value.len());
`else
              $sformat(attr_name,"%s",scope.get());//Verdi 9001179360
              $sformat(numbits_name,"%0d",8*value.len());
`endif
//
              pli_inst.add_attribute_string(pliHandle, val_name, attr_name, numbits_name);
          end
          if (is_verdi_debug_enabled()) begin
              $fdisplay(file_h,"      SET_ATTR @%0t {TXH:%0d NAME:%s VALUE:%s   RADIX:%s BITS=%0d}",
                   $realtime,
                   this.get_handle(),
                   scope.get(),
                   value,
                   "UVM_STRING",
                   8+value.len());
              $fdisplay(file_h,"add_attribute_string@%0t txh=%0d val_name=%s attr_name=%s numbits_name=%s",$realtime,pliHandle,val_name, attr_name, numbits_name);
          end 
      end
   endfunction : do_record_string

   // Function: do_record_time
   // Records a time field.
   //
   // Text-backend specific implementation.
   protected virtual function void do_record_time(string name,
                                                    time value);
      scope.set_arg(name);
      write_attribute_int(scope.get(), 
                          value,
                          UVM_TIME, 
                          64);
   endfunction : do_record_time

   // Function: do_record_generic
   // Records a name/value pair, where ~value~ has been converted to a string.
   //
   // Text-backend specific implementation.
   protected virtual function void do_record_generic(string name,
                                                     string value,
                                                     string type_name);
      scope.set_arg(name);
      write_attribute(scope.get(), 
                      uvm_string_to_bits(value), 
                      UVM_STRING, 
                      8+value.len());
   endfunction : do_record_generic

   // Group: Implementation Specific API
   
   // Function: write_attribute
   // Outputs an integral attribute to the textual log
   //
   // Parameters:
   // nm - Name of the attribute
   // value - Value
   // radix - Radix of the output
   // numbits - number of valid bits
   function void write_attribute(string nm,
                                 uvm_bitstream_t value,
                                 uvm_radix_enum radix,
                                 integer numbits=$bits(uvm_bitstream_t));
      static longint pliHandle = 0;
      static string val_name="",attr_name="",numbits_name="";

      m_tr_handle = this.get_handle();
      pliHandle = uvmPliHandleMap[m_tr_handle];
      if (m_verdi_db.open_db()) begin
          val_name = uvm_bitstream_to_string(value, numbits, radix);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
          $sformat(attr_name,"+name+%s",nm);
          $sformat(numbits_name,"+numbit+%0d",numbits);
`else
          attr_name = nm;
          $sformat(numbits_name,"%0d",numbits);
`endif
//
          pli_inst.add_attribute_string(pliHandle, val_name, attr_name, numbits_name);
          if (is_verdi_debug_enabled()) begin
              $fdisplay(file_h,"      SET_ATTR @%0t {TXH:%0d NAME:%s VALUE:%s   RADIX:%s BITS=%0d}",
                  $realtime,
                   this.get_handle(),
                   nm,
                   uvm_bitstream_to_string(value, numbits, radix),
                    radix.name(),
                   numbits);
              $fdisplay(file_h,"add_attribute_string @%0t txh=%0d val_name=%s attr_name=%s numbits_name=%s",$realtime,pliHandle,val_name,attr_name,numbits_name);
          end 
      end
   endfunction : write_attribute

   function void string_to_enum(longint txh,string val_name,string nm);
      static uvm_severity severity_type;
      static uvm_verbosity verbosity_type;
      static string attr_name;
      static int st_txh=0;

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
          $sformat(attr_name,"%s",nm);
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
          $sformat(attr_name,"%s",nm);
`endif
//
          pli_inst.add_attribute_verbosity_type(st_txh, verbosity_type, attr_name);
      end
  endfunction
   // Function: write_attribute_int
   // Outputs an integral attribute to the textual log
   //
   // Parameters:
   // nm - Name of the attribute
   // value - Value
   // radix - Radix of the output
   // numbits - number of valid bits
   function void write_attribute_int(string  nm,
                                     uvm_integral_t value,
                                     uvm_radix_enum radix,
                                     integer numbits=$bits(uvm_bitstream_t));
      string stream_name = "", val_str = "";
      static string attr_name="",numbits_name="",val_name="",tmp_nm="";
      integer stream_handle = 0;
      static string real_str="";
      static longint pliHandle = 0;
`ifdef VERDI_RECORD_RELATION
      int snps_inst_id_val = 0;
`endif
      static logic [1023:0] st_value;
      static string st_val_name="";
      static real st_real=0;

      m_tr_handle = this.get_handle(); 
      pliHandle = uvmPliHandleMap[m_tr_handle];
      if (pliHandle==0)
          return;

      if (m_verdi_db.open_db()) begin
         tmp_nm = nm;
         if (tmp_nm=="0")
             tmp_nm = "Error_0";
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
         $sformat(attr_name,"+name+%s",tmp_nm);
         $sformat(numbits_name,"+numbit+%0d",numbits);
`else
         $sformat(attr_name,"%s",tmp_nm);
         $sformat(numbits_name,"%0d",numbits); 
`endif
//
`ifdef VERDI_RECORD_RELATION
         if (nm=="snps_inst_id") begin
             snps_inst_id_val = value;
             transactionArrByInstId[snps_inst_id_val] = pliHandle;
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
             $fdisplay(file_h,"      SET_ATTR @%0t {TXH:%0d NAME:%s VALUE:%s   RADIX:%s BITS=%0d}",
                   $realtime,
                   this.get_handle(),
                   nm,
                   uvm_integral_to_string(value, numbits, radix),
                   radix.name(),
                   numbits);
             $fdisplay(file_h,"add_attribute_logic @%0t txh=%0d value=%0d attr_name=%s numbits_name=%s",
                       $realtime,pliHandle,st_value,attr_name,numbits_name);
         end 
      end
   endfunction : write_attribute_int

`ifdef VERDI_RECORD_RELATION
static function void link_tr_by_id(integer instId1, integer instId2, string relation);
   static longint pliHandle1 = 0, pliHandle2 = 0;
   static string st_relation=""; 

   pliHandle1 = transactionArrByInstId[instId1];
   pliHandle2 = transactionArrByInstId[instId2];
   if (is_verdi_debug_enabled()) begin
       $fdisplay(file_h,"link_tr: h1=%0d h2=%0d relation=%s real_time=%0d",pliHandle1,pliHandle2,relation,$time);
   end
   if (pliHandle1==0 || pliHandle2==0)
       return;
   st_relation = relation;
   pli_inst.link_tr(relation,pliHandle1,pliHandle2);
endfunction
`endif

endclass : uvm_verdi_recorder
`endif
