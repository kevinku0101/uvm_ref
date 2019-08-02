//-------------------------------------------------------------
// SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary work of 
// Synopsys, Inc., and is fully protected under copyright and trade 
// secret laws. You may not view, use, disclose, copy, or distribute this 
// file or any information contained herein except pursuant to a valid 
// written license from Synopsys. 
//-------------------------------------------------------------

static int g_refclass_id[string][string];
static string g_visited_regfile[uvm_reg_file];
static string g_regfile_handle_class_name[uvm_reg_file];
static string g_regblk_handle_class_name[uvm_reg_block];
static bit g_visited_regname[uvm_object][string];

function automatic void insert_refclass_id(input uvm_object parent_handle, input string class_name, input string reg_name, int id);
   string new_reg_name;
   chandle _ptr;
  
   new_reg_name = remove_array_index(reg_name, _ptr);

   if(g_visited_regname.exists(parent_handle) &&
      g_visited_regname[parent_handle].exists(new_reg_name))
      return;
 
   g_visited_regname[parent_handle][new_reg_name] = 1'b1;

   g_refclass_id[class_name][new_reg_name] = id; 
endfunction

function automatic int find_refclass_id(input uvm_object parent_handle, input string class_name, input string reg_name);
   string _reg_name_wo_range;
   chandle _ptr;

   _reg_name_wo_range = remove_array_index(reg_name, _ptr);

   if(g_visited_regname.exists(parent_handle) &&
      g_visited_regname[parent_handle].exists(_reg_name_wo_range)) begin

      if(g_refclass_id.exists(class_name) &&
         g_refclass_id[class_name].exists(_reg_name_wo_range))
         g_refclass_id[class_name].delete(_reg_name_wo_range);

      return 0;
   end


   if(g_refclass_id.exists(class_name) && g_refclass_id[class_name].exists(_reg_name_wo_range)) begin
      return g_refclass_id[class_name][_reg_name_wo_range];
   end

   return 0;
endfunction

function automatic uvm_reg_map_info retrieve_mem_map_info(uvm_reg_map _map, uvm_mem _mem);
   uvm_reg_map _parent_map;
   uvm_reg_map_info _map_info;

   _map_info = null;
   _parent_map = _map.get_parent_map();

   while(_parent_map!= null) begin
      _map = _parent_map;
      _map_info = _map.get_mem_map_info(_mem, 0);

      if(_map_info)
         return _map_info;

      _parent_map = _map.get_parent_map();
   end
   
   return null;
endfunction

function automatic uvm_reg_map_info retrieve_reg_map_info(uvm_reg_map _map, uvm_reg _reg);
   uvm_reg_map _parent_map;
   uvm_reg_map_info _map_info;

   _map_info = null;
   _parent_map = _map.get_parent_map();

   while(_parent_map!= null) begin
      _map = _parent_map;
      _map_info = _map.get_reg_map_info(_reg, 0);

      if(_map_info)
         return _map_info;

      _parent_map = _map.get_parent_map();
   end
   
   return null;
endfunction


function automatic bit has_blk_hdl_path(uvm_reg_block _blk);
   uvm_reg_block _parent_blk;

   _parent_blk = _blk.get_parent();

   if(_parent_blk == null)
      return _blk.has_hdl_path();
   else
      return has_blk_hdl_path(_parent_blk) & _blk.has_hdl_path();
endfunction

function int pli_reghier_begin_event(input string streamN);
   string comp_stream, des_str;
   longint unsigned streamId, handle; 

   streamId = 0;
   handle = 0;
   $sformat(comp_stream, "UVM.REG_HIER.%0s", streamN);

   if (!streamArrByName.exists(comp_stream)) begin
// 9001353389
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       des_str = "+description+type=register";
`else
       des_str = "type=register";
`endif
       streamId = pli_inst.create_stream_begin(comp_stream,des_str);
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

function void pli_reghier_set_label(input int handle, input string label);
   pli_inst.set_label(handle, label);
endfunction

function void pli_reghier_add_attribute_string(input int handle, input string attrName, input string valName);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
   pli_inst.add_attribute_string(handle, $sformatf("%0s", valName), $sformatf("+name+%0s", attrName), "+numbit+0");
`else
   pli_inst.add_attribute_string(handle, $sformatf("%0s", valName), $sformatf("%0s", attrName), "");
`endif
//
endfunction

function void pli_reghier_add_attribute_int(input int handle, input string attr_name, input int attr_value);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
   pli_inst.add_attribute_int(handle, attr_value, $sformatf("+name+%0s", attr_name));
`else
   pli_inst.add_attribute_int(handle, attr_value, $sformatf("%0s", attr_name));
`endif
//
endfunction

function void pli_reghier_add_attribute_logic(input int handle, input string attr_name, input logic [1023:0] attr_value, input string radix, input integer numbits=1024);
// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
   pli_inst.add_attribute_logic(handle, attr_value, $sformatf("+name+%0s", attr_name), radix, $sformatf("+numbit+%0d", numbits));
`else
   pli_inst.add_attribute_logic(handle, attr_value, $sformatf("%0s", attr_name), radix, $sformatf("%0d", numbits));
`endif
// 
endfunction

function void pli_reghier_end_event(input int handle); 
   pli_inst.end_tr(handle);

endfunction

function automatic void record_reghier_map(uvm_reg_map _map); begin
   uvm_reg _regs[$], _reg;
   uvm_reg_field _fields[$], _field;
   uvm_mem _mems[$], _mem;
   int _handle;
   string _full_name, _address, _regid, _label_name;
   uvm_sequencer_base _sequencer;
   uvm_reg_map _parent_map;
   uvm_reg_block _parent_blk;
   uvm_reg_addr_t _base_addr;
   int _decl;
   bit _need_end_event;
   int g_policy_id[string]; 

   _need_end_event = 1'b0;
   _decl = 0;
   _full_name = _map.get_full_name();
   _handle = pli_reghier_begin_event(_full_name);

   _parent_map = _map.get_parent_map();
   _parent_blk = _map.get_parent();

   if(_parent_blk) 
      $sformat(_label_name, "MAP_%0d_%0d", _map.get_inst_id(), _parent_blk.get_inst_id());
   else
      $sformat(_label_name, "MAP_%0d_", _map.get_inst_id());

   pli_reghier_set_label(_handle, _label_name);

   pli_reghier_add_attribute_string(_handle, "name", _full_name);
   if(_parent_blk) begin
      if (!verdi_clp.is_verdi_trace_no_decl())
          _decl = record_reg_decl_name(_handle, "_parent_blk", "_map", _map.get_name());
   end

   if(_parent_map) begin
      pli_reghier_add_attribute_int(_handle, "parent_map_id", _parent_map.get_inst_id());
   end

   retrieve_reg_def_class("_map", _handle);

   pli_reghier_add_attribute_int(_handle, "bus_width_in_bytes", _map.get_n_bytes());

   _base_addr = _map.get_base_addr();
   pli_reghier_add_attribute_logic(_handle, "base_address",  _base_addr, "+radix+hex", $size(_base_addr));

   _sequencer = _map.get_sequencer();

   if(_sequencer !=null)
      pli_reghier_add_attribute_string(_handle, "sequencer", _sequencer.get_full_name());

   pli_reghier_end_event(_handle);
   
   _map.get_registers(_regs, UVM_NO_HIER);

   _need_end_event = 1'b0;
   if(_regs.size()>0) begin
      _need_end_event = 1'b1;
      _handle = pli_reghier_begin_event(_full_name);
      pli_reghier_set_label(_handle, _label_name);
      //pli_reghier_add_attribute_int(_handle, "inst_id", _map.get_inst_id());
   end
  
   while(_regs.size() > 0) begin
      uvm_reg_addr_t _addr, _offset;
      uvm_reg_map_info _map_info;
      string _right;
      uvm_map_access_recorder _inst;

      _reg = _regs.pop_front();

      if(_map) 
         _map_info = _map.get_reg_map_info(_reg, 0); 
      
      if(_map_info==null) 
         _map_info = retrieve_reg_map_info(_map, _reg);

      if(_map_info!=null && !_map_info.unmapped) begin

         _right = _reg.get_rights(_map);

         if(!g_policy_id.exists(_right)) begin
            int _policy_size;

            _policy_size = g_policy_id.size();
            pli_reghier_add_attribute_string(_handle, $sformatf("policy_%0d", (_policy_size+1)), _right);
            g_policy_id[_right] = _policy_size+1;
         end
         pli_reghier_add_attribute_int(_handle, $sformatf("reg_%0d_access_policy_id", _reg.get_inst_id()), g_policy_id[_right]);

         _addr = _reg.get_address(_map);
         _inst = uvm_map_access_recorder::get_inst();
         _inst.insert_register(_addr, _map.get_full_name(), _reg);

         pli_reghier_add_attribute_logic(_handle, $sformatf("reg_%0d_address", _reg.get_inst_id()),  _addr, "+radix+hex", $size(_addr));

         _offset = _reg.get_offset(_map);
         pli_reghier_add_attribute_logic(_handle, $sformatf("reg_%0d_offset", _reg.get_inst_id()), _offset, "+radix+hex", $size(_offset));

         _reg.get_fields(_fields);
         while(_fields.size() > 0) begin
      
            _field = _fields.pop_front(); 
            _right = _field.get_access(_map);
 
            if(!g_policy_id.exists(_right)) begin
               int _policy_size;

               _policy_size = g_policy_id.size();
               pli_reghier_add_attribute_string(_handle, $sformatf("policy_%0d", (_policy_size+1)), _right);
               g_policy_id[_right] = _policy_size+1;
            end
            pli_reghier_add_attribute_int(_handle, $sformatf("field_%0d_access_policy_id", _field.get_inst_id()), g_policy_id[_right]);
      
         end
      end
   end
   
   if(_need_end_event==1'b1)
      pli_reghier_end_event(_handle);
   
   _map.get_memories(_mems, UVM_NO_HIER);
   _need_end_event =1'b0;
   if(_mems.size() > 0) begin
      _need_end_event =1'b1;
      _handle = pli_reghier_begin_event(_full_name);
      pli_reghier_set_label(_handle, _label_name);
      //pli_reghier_add_attribute_int(_handle, "inst_id", _map.get_inst_id());
   end

   while(_mems.size() > 0) begin
      uvm_reg_addr_t _addr, _offset;
      uvm_reg_map_info _map_info;
      uvm_map_access_recorder _inst;

      _mem = _mems.pop_front(); 

      if(_map)
         _map_info = _map.get_mem_map_info(_mem, 0);

      if(_map_info==null)
         _map_info = retrieve_mem_map_info(_map, _mem);

      if(_map_info!=null && !_map_info.unmapped) begin
         $sformat(_regid, "mem_%0d_access_policy", _mem.get_inst_id()); 
         pli_reghier_add_attribute_string(_handle, _regid, _mem.get_access(_map));

         _addr = _mem.get_address(0, _map); // base address
         _inst = uvm_map_access_recorder::get_inst();
         _inst.insert_register(_addr, _map.get_full_name(), _mem);
 
         $sformat(_regid, "mem_%0d_address", _mem.get_inst_id()); 
         pli_reghier_add_attribute_logic(_handle, _regid,  _addr, "+radix+hex", $size(_addr));
   
   
         _offset = _mem.get_offset(0, _map); // base offset 
         $sformat(_regid, "mem_%0d_offset", _mem.get_inst_id()); 
         pli_reghier_add_attribute_logic(_handle, _regid,  _offset, "+radix+hex", $size(_offset));
      end
   end

   if(_need_end_event==1'b1)
      pli_reghier_end_event(_handle);

end
endfunction

function automatic void record_reghier_field(uvm_reg_field _field, string _stream_name, int refId); begin
   int _handle, _objid;
   uvm_reg _parent_reg;
   uvm_reg_block _parent_blk;
   uvm_reg_file _parent_regfile;

   int _decl, _classRefId=0;
   string _field_class_name;
   uvm_reg_field _cur_field;
   static verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst();
   static int g_fieldclass_bit_lsb[string][int][int];

   _handle = pli_reghier_begin_event(_stream_name);

   _parent_reg = _field.get_parent();

   _decl = 0;
   if(refId!=0) begin
      _decl= 1;
   end
  
   if((_parent_reg!=null) && refId==0) begin
      if (!verdi_clp.is_verdi_trace_no_decl())
          _decl = record_reg_decl_name(_handle, "_parent_reg", "_field", _field.get_name());
   end

   if(_parent_reg)
      pli_reghier_set_label(_handle, $sformatf("FIELD_%0d_%0d", _field.get_inst_id(), _parent_reg.get_inst_id()));
   else
      pli_reghier_set_label(_handle, $sformatf("FIELD_%0d_", _field.get_inst_id()));

   _cur_field = _field;
   _field_class_name = retrieve_def_class("_cur_field", _objid);

   if(_field_class_name.len()>0 && 
      g_fieldclass_bit_lsb.exists(_field_class_name) &&
      g_fieldclass_bit_lsb[_field_class_name].exists(_field.get_n_bits()) &&
      g_fieldclass_bit_lsb[_field_class_name][_field.get_n_bits()].exists(_field.get_lsb_pos())) begin

      _classRefId = g_fieldclass_bit_lsb[_field_class_name][_field.get_n_bits()][_field.get_lsb_pos()];

   end else begin
      g_fieldclass_bit_lsb[_field_class_name][_field.get_n_bits()][_field.get_lsb_pos()] = _field.get_inst_id();
   end 

   if(refId!=0 && refId!=_classRefId) 
      pli_reghier_add_attribute_int(_handle, "reference_declaration_inst_id", refId);
   if(_classRefId!=0 && _classRefId!=refId)
      pli_reghier_add_attribute_int(_handle, "reference_class_inst_id", _classRefId);
   if(refId!=0 && refId==_classRefId)
      pli_reghier_add_attribute_int(_handle, "reference_class_declaration_inst_id", _classRefId);
  

   if(_classRefId==0) begin
      pli_reghier_add_attribute_int(_handle, "num_bits", _field.get_n_bits());
      pli_reghier_add_attribute_int(_handle, "lsb_pos", _field.get_lsb_pos());
   end

   pli_reghier_add_attribute_string(_handle, "name", $sformatf("%s.%s.%s", _stream_name, _parent_reg.get_name(), _field.get_name()));

   if(_decl==0 && _parent_reg!=null) begin
      _parent_blk = _parent_reg.get_parent();
      if (!verdi_clp.is_verdi_trace_no_decl())
         _decl = record_reg_decl_name(_handle, "_parent_blk", "_field", _field.get_name());
   end

   if(_classRefId==0)
      retrieve_reg_def_class("_field", _handle);
`ifdef VCS
   else if(_objid!=0)
      pli_reghier_add_attribute_string(_handle, "snps_object_id", $sformatf("\\%s @%0d", _field_class_name, _objid));
`endif

   pli_reghier_end_event(_handle);

end
endfunction

function automatic string record_reghier_regfile(uvm_reg_file _regfile); begin
   uvm_reg_block _top_blk;
   uvm_reg_file _parent_regfile;
   int _handle, _num_hdl;
   string _full_name;
   string _hdl_paths[$], _hdl, _hdl_attr, _blk_class_name, _regfile_class_name, _cur_regfile_class_name;
   int _decl, _refId, _objid;
   uvm_reg_file _cur_regfile;
   static verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst();
   static int g_regfile_class[string];

   _decl = 0;   
   _num_hdl = 0;
   _regfile_class_name = "";

   if(g_visited_regfile.exists(_regfile)) begin
      return g_visited_regfile[_regfile];
   end

   _parent_regfile = _regfile.get_regfile();
   _top_blk = _regfile.get_parent();

   
   _refId = 0;
   if(_parent_regfile!=null && g_regfile_handle_class_name.exists(_parent_regfile)) begin
      _regfile_class_name = g_regfile_handle_class_name[_parent_regfile];
   end

   if(_parent_regfile!=null && _regfile_class_name.len()==0) begin
      _regfile_class_name = retrieve_def_class("_parent_regfile", _objid);
      if(_regfile_class_name.len() > 0)
         g_regfile_handle_class_name[_parent_regfile] = _regfile_class_name;
   end

   if(_regfile_class_name.len() > 0)
      _refId = find_refclass_id(uvm_object'(_parent_regfile), _regfile_class_name, _regfile.get_name());

   _blk_class_name = "";
   if(_refId==0) begin
      _blk_class_name = retrieve_def_class("_top_blk", _objid);
      _refId = find_refclass_id(uvm_object'(_top_blk), _blk_class_name, _regfile.get_name());
   end

   if(_parent_regfile) begin

      _full_name = record_reghier_regfile(_parent_regfile);
      _full_name = {_full_name, ".", _regfile.get_name()};

      g_visited_regfile[_regfile] = _full_name;
      _handle = pli_reghier_begin_event(_full_name);

      if (!verdi_clp.is_verdi_trace_no_decl() && _refId==0) begin
          _decl = record_reg_decl_name(_handle, "_parent_regfile", "_regfile", _regfile.get_name());
          if(_decl) 
             insert_refclass_id(uvm_object'(_parent_regfile), _regfile_class_name, _regfile.get_name(), _regfile.get_inst_id());
          
          if(_decl==0 && _top_blk!=null) begin
             _decl = record_reg_decl_name(_handle, "_top_blk", "_regfile", _regfile.get_name());
             if(_decl)
                insert_refclass_id(uvm_object'(_top_blk), _blk_class_name, _regfile.get_name(), _regfile.get_inst_id());
          end

      end
   end else begin
      _full_name = _regfile.get_full_name();
      g_visited_regfile[_regfile] = _full_name;
      _handle = pli_reghier_begin_event(_full_name);

      if(_top_blk) begin
         if (!verdi_clp.is_verdi_trace_no_decl() && _refId==0) begin
             _decl = record_reg_decl_name(_handle, "_top_blk", "_regfile", _regfile.get_name());
             if(_decl)
                insert_refclass_id(uvm_object'(_top_blk), _blk_class_name, _regfile.get_name(), _regfile.get_inst_id());
         end
      end
   end
   
   if(_parent_regfile) begin
      pli_reghier_set_label(_handle, $sformatf("REGFILE_%0d_%0d", _regfile.get_inst_id(), _parent_regfile.get_inst_id()));
   end else if(_top_blk) begin
      pli_reghier_set_label(_handle, $sformatf("REGFILE_%0d_%0d", _regfile.get_inst_id(), _top_blk.get_inst_id()));
   end else begin
      pli_reghier_set_label(_handle, $sformatf("REGFILE_%0d_", _regfile.get_inst_id()));
   end

   pli_reghier_add_attribute_string(_handle, "name", _full_name);

   _objid = 0;
   if(_refId!=0) begin
      pli_reghier_add_attribute_int(_handle, "reference_class_declaration_inst_id", _refId);
      retrieve_reg_def_class("_regfile", _handle, 1);
   end else begin

      _cur_regfile = _regfile;
      _cur_regfile_class_name = retrieve_def_class("_cur_regfile", _objid); 

      if(_cur_regfile_class_name.len()>0 && g_regfile_class.exists(_cur_regfile_class_name)) begin

         pli_reghier_add_attribute_int(_handle, "reference_class_inst_id", g_regfile_class[_cur_regfile_class_name]);
         pli_reghier_add_attribute_string(_handle, "snps_object_id", $sformatf("\\%s @%0d", _cur_regfile_class_name, _objid));

      end else begin

         g_regfile_class[_cur_regfile_class_name] = _regfile.get_inst_id();
         retrieve_reg_def_class("_regfile", _handle);

      end
   end

   if (_regfile.has_hdl_path())
       _regfile.get_hdl_path(_hdl_paths);

   while(_hdl_paths.size() > 0 ) begin
      _hdl = _hdl_paths.pop_front();
      if(_hdl.len()>0) begin
         $sformat(_hdl_attr, "hdl_path_%0d", _num_hdl++);
         pli_reghier_add_attribute_string(_handle, _hdl_attr, _hdl);
      end
   end
   pli_reghier_end_event(_handle);

   return _full_name;
end
endfunction

function automatic void record_reghier_reg(uvm_reg _reg); begin
   uvm_reg _cur_reg;
   uvm_reg_file _parent_regfile;
   uvm_reg_block _parent_blk;
   string _stream_name, _reg_name, _label_name, _class_name;
   uvm_reg_field _fields[$], _field;
   uvm_reg_map _default_map;

   uvm_hdl_path_concat _hdl_paths[$], _hdl_path;
   uvm_hdl_path_slice _hdl_slice;
   string _hdl, _hdl_attr_name, _reg_class_name, _blk_class_name, _regfile_class_name;
   int _hdl_offset, _hdl_size, _hdl_idx, _slice_idx;
   int _handle, _inst_id;
   int _decl, _refId, _classRefId, _objid;
   static verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst();
   static int g_regclass_bits[string][int];

   _hdl_idx = 0;
   _slice_idx = 0;
   _decl = 0;
   _regfile_class_name = "";
   _blk_class_name = "";

   // Handle regfiles
   _parent_regfile = _reg.get_regfile();
   _parent_blk = _reg.get_parent();

   _refId = 0;
   _inst_id = _reg.get_inst_id(); 

   if(_parent_regfile!=null && g_regfile_handle_class_name.exists(_parent_regfile)) begin
      _regfile_class_name = g_regfile_handle_class_name[_parent_regfile];
   end

   if(_parent_regfile!=null && _regfile_class_name.len()==0) begin
      _regfile_class_name = retrieve_def_class("_parent_regfile", _objid);
      g_regfile_handle_class_name[_parent_regfile] = _regfile_class_name;
   end

   if(_regfile_class_name.len() > 0) 
      _refId = find_refclass_id(uvm_object'(_parent_regfile), _regfile_class_name, _reg.get_name());

   if(_refId==0 && (_parent_blk!=null)) begin
      if(g_regblk_handle_class_name.exists(_parent_blk)) begin
         _blk_class_name = g_regblk_handle_class_name[_parent_blk];
      end else begin
         _blk_class_name = retrieve_def_class("_parent_blk", _objid);
         g_regblk_handle_class_name[_parent_blk] = _blk_class_name;
      end
      _refId = find_refclass_id(uvm_object'(_parent_blk), _blk_class_name, _reg.get_name());
   end

   if(_parent_regfile) begin

      _stream_name = record_reghier_regfile(_parent_regfile);
      _handle = pli_reghier_begin_event(_stream_name);

      if (!verdi_clp.is_verdi_trace_no_decl() && _refId==0) begin
          _decl = record_reg_decl_name(_handle, "_parent_regfile", "_reg", _reg.get_name());
          if(_decl)
             insert_refclass_id(uvm_object'(_parent_regfile), _regfile_class_name, _reg.get_name(), _inst_id);
      end 

   end else begin
      _stream_name = _parent_blk.get_full_name();
      _handle = pli_reghier_begin_event(_stream_name);
   end


   if(_parent_blk!=null && _decl==0 && _refId==0) begin
      if (!verdi_clp.is_verdi_trace_no_decl()) begin
          _decl = record_reg_decl_name(_handle, "_parent_blk", "_reg", _reg.get_name());
          if(_decl)
             insert_refclass_id(uvm_object'(_parent_blk), _blk_class_name, _reg.get_name(), _inst_id);
      end
   end

   _cur_reg = _reg;
   _reg_class_name = retrieve_def_class("_cur_reg", _objid);

   _classRefId = 0;
   if(_reg_class_name.len()>0 && g_regclass_bits.exists(_reg_class_name) && g_regclass_bits[_reg_class_name].exists(_reg.get_n_bits())) begin
      _classRefId = g_regclass_bits[_reg_class_name][_reg.get_n_bits()];
   end else begin
      g_regclass_bits[_reg_class_name][_reg.get_n_bits()] = _inst_id;
   end

   if(_refId!=0 && _classRefId!=_refId)
      pli_reghier_add_attribute_int(_handle, "reference_declaration_inst_id", _refId);
   if(_classRefId!=0 && _classRefId!=_refId)
      pli_reghier_add_attribute_int(_handle, "reference_class_inst_id", _classRefId);
   if(_refId!=0 && _classRefId==_refId)
      pli_reghier_add_attribute_int(_handle, "reference_class_declaration_inst_id", _classRefId);

   _default_map = _reg.get_default_map();

   if(_parent_regfile) begin
      $sformat(_label_name, "REG_%0d_%0d_%0d", _inst_id, _parent_regfile.get_inst_id(), _default_map.get_inst_id());
   end else if(_parent_blk) begin
      if (_default_map)
          $sformat(_label_name, "REG_%0d_%0d_%0d", _inst_id, _parent_blk.get_inst_id(), _default_map.get_inst_id());
      else
          $sformat(_label_name, "REG_%0d_%0d", _inst_id, _parent_blk.get_inst_id());
   end else begin
      if (_default_map)
          $sformat(_label_name, "REG_%0d__%0d", _inst_id, _default_map.get_inst_id());
      else
          $sformat(_label_name, "REG_%0d", _inst_id);
   end

   pli_reghier_set_label(_handle, _label_name);

   if(_classRefId==0)
      pli_reghier_add_attribute_int(_handle, "num_bits", _reg.get_n_bits());

   $sformat(_reg_name, "%s.%s", _stream_name, _reg.get_name());
   pli_reghier_add_attribute_string(_handle, "name", _reg_name);


   if(_classRefId==0)
      retrieve_reg_def_class("_reg", _handle);
`ifdef VCS
   else if(_objid!=0)
      pli_reghier_add_attribute_string(_handle, "snps_object_id", $sformatf("\\%s @%0d", _reg_class_name, _objid));
`endif

   if (_reg.has_hdl_path())
       _reg.get_hdl_path(_hdl_paths);

   while(_hdl_paths.size() > 0) begin
      _hdl_path = _hdl_paths.pop_front();
      for(_slice_idx=0; _slice_idx < _hdl_path.slices.size(); _slice_idx++) begin
         $sformat(_hdl_attr_name, "hdl_slice_path_%0d_%0d", _hdl_idx, _slice_idx);
         pli_reghier_add_attribute_string(_handle, _hdl_attr_name, _hdl_path.slices[_slice_idx].path);
         $sformat(_hdl_attr_name, "hdl_slice_offset_%0d_%0d", _hdl_idx, _slice_idx);
         pli_reghier_add_attribute_int(_handle, _hdl_attr_name, _hdl_path.slices[_slice_idx].offset);
         $sformat(_hdl_attr_name, "hdl_slice_size_%0d_%0d", _hdl_idx, _slice_idx);
         pli_reghier_add_attribute_int(_handle, _hdl_attr_name, _hdl_path.slices[_slice_idx].size);
      end
      _hdl_idx++;
   end

   pli_reghier_end_event(_handle);


   // Iterate reg fields
   _refId = 0;

   _reg.get_fields(_fields);

   while(_fields.size() > 0) begin
      _field = _fields.pop_front(); 

      _refId = find_refclass_id(uvm_object'(_reg), _reg_class_name, _field.get_name());
      if(_refId==0)
         insert_refclass_id(uvm_object'(_reg), _reg_class_name, _field.get_name(), _field.get_inst_id());
      record_reghier_field(_field, _stream_name, _refId);
   end

  
end
endfunction

function automatic void record_reghier_mem(uvm_mem _mem); begin
   string _mem_name, _blk_name;
   int _handle;
   uvm_reg_block _parent_blk;
   uvm_reg_map _default_map;

   uvm_hdl_path_concat _hdl_paths[$], _hdl_path;
   uvm_hdl_path_slice _hdl_slice;
   string _hdl, _hdl_attr_name;
   int _hdl_offset, _hdl_size, _hdl_idx, _slice_idx;
   int _decl;
   static verdi_cmdline_processor verdi_clp = verdi_cmdline_processor::get_inst(); 

   _hdl_idx = 0;
   _slice_idx = 0;
   _mem_name = _mem.get_full_name();
   _parent_blk = _mem.get_parent();
   _blk_name = _parent_blk.get_full_name();
   _decl = 0;

   _handle = pli_reghier_begin_event(_mem_name);

   if (!verdi_clp.is_verdi_trace_no_decl())
       _decl = record_reg_decl_name(_handle, "_parent_blk", "_mem", _mem.get_name());
  
   _default_map = _mem.get_default_map();

   if(_parent_blk) begin
      pli_reghier_set_label(_handle, $sformatf("MEM_%0d_%0d_%0d", _mem.get_inst_id(), _parent_blk.get_inst_id(), _default_map.get_inst_id()));
   end else begin
      pli_reghier_set_label(_handle, $sformatf("MEM_%0d__%0d", _mem.get_inst_id(), _default_map.get_inst_id()));
   end

   pli_reghier_add_attribute_string(_handle, "name", _mem_name);
   pli_reghier_add_attribute_int(_handle, "width_in_bits", _mem.get_n_bits());
   pli_reghier_add_attribute_int(_handle, "memory_size", _mem.get_size());

   retrieve_reg_def_class("_mem", _handle);


   if (_mem.has_hdl_path()) 
       _mem.get_hdl_path(_hdl_paths);

   while(_hdl_paths.size() > 0) begin
      _hdl_path = _hdl_paths.pop_front();
      for(_slice_idx=0; _slice_idx < _hdl_path.slices.size(); _slice_idx++) begin
         $sformat(_hdl_attr_name, "hdl_slice_path_%0d_%0d", _hdl_idx, _slice_idx);
         pli_reghier_add_attribute_string(_handle, _hdl_attr_name, _hdl_path.slices[_slice_idx].path);
         $sformat(_hdl_attr_name, "hdl_slice_offset_%0d_%0d", _hdl_idx, _slice_idx);
         pli_reghier_add_attribute_int(_handle, _hdl_attr_name, _hdl_path.slices[_slice_idx].offset);
         $sformat(_hdl_attr_name, "hdl_slice_size_%0d_%0d", _hdl_idx, _slice_idx);
         pli_reghier_add_attribute_int(_handle, _hdl_attr_name, _hdl_path.slices[_slice_idx].size);
      end
      _hdl_idx++;
   end

   pli_reghier_end_event(_handle);
 
end
endfunction

function automatic void record_reghier_blk(uvm_reg_block _blk); begin
   uvm_reg _regs[$], _reg;
   //uvm_reg_map _maps[$], _map;
   uvm_reg_block  _blks[$], _parent_blk, _sub_blk;
   uvm_mem _mems[$], _mem;
   int _handle, _num_hdl;
   string _hdl_path, _block_name;
   uvm_reg_map _default_map;
   string _hdl_paths[$], _hdl, _hdl_attr;
   int _decl;
   static int max_reg_dump_limit = 5000;
   static int max_reg_dump_limit_check = 0;
   static int dumped_reg_num=0;
   static int is_limit_message_recorded=0;

   _num_hdl = 0;
   _decl = 0;

   // Record Block Attributes
   _block_name = _blk.get_full_name();
   _handle = pli_reghier_begin_event(_block_name);

   _default_map = _blk.get_default_map();

   _parent_blk = _blk.get_parent();
   if(_parent_blk) begin
      pli_reghier_set_label(_handle, $sformatf("BLOCK_%0d_%0d_%0d", _blk.get_inst_id(), _parent_blk.get_inst_id(), _default_map.get_inst_id()));
   end else begin
      pli_reghier_set_label(_handle, $sformatf("BLOCK_%0d__%0d", _blk.get_inst_id(), _default_map.get_inst_id()));
   end

   pli_reghier_add_attribute_string(_handle, "name", _block_name);

   _parent_blk = _blk.get_parent();
   if(_parent_blk) begin

      if (!verdi_clp.is_verdi_trace_no_decl())
          _decl = record_reg_decl_name(_handle, "_parent_blk", "_blk", _blk.get_name());

   end


   retrieve_reg_def_class("_blk", _handle);


   if (_blk.is_hdl_path_root() || has_blk_hdl_path(_blk))
       _blk.get_full_hdl_path(_hdl_paths);
   while(_hdl_paths.size() > 0 ) begin
      _hdl = _hdl_paths.pop_front();
      if(_hdl.len()>0) begin 
         $sformat(_hdl_attr, "hdl_path_%0d", _num_hdl++);
         pli_reghier_add_attribute_string(_handle, _hdl_attr, _hdl);
      end
   end

   pli_reghier_end_event(_handle);

   _hdl_path = "";
  
   // Iterate registers
   if(max_reg_dump_limit_check==0) begin
      uvm_cmdline_processor clp;
      string val_str;

      val_str = "";
      max_reg_dump_limit_check = 1;
      clp = uvm_cmdline_processor::get_inst();
      if (clp.get_arg_value("+UVM_REG_DUMP_LIMIT=", val_str))
          max_reg_dump_limit = val_str.atoi();

   end

   if(verdi_clp.is_verdi_trace_ral() && (dumped_reg_num < max_reg_dump_limit||max_reg_dump_limit==0)) 
      _blk.get_registers(_regs, UVM_NO_HIER);


   while(_regs.size() > 0) begin
      int _refId=0;

      _reg = _regs.pop_front();
   
      if(verdi_clp.is_verdi_trace_ral() && (dumped_reg_num < max_reg_dump_limit||max_reg_dump_limit==0)) begin
         record_reghier_reg(_reg);
         dumped_reg_num++;
      end else if(is_limit_message_recorded==0) begin
         _handle = pli_reghier_begin_event("max_reg_recorded");
         is_limit_message_recorded = 1;
        pli_reghier_set_label(_handle, $sformatf("MAX_%0d_REG_RECORDED", max_reg_dump_limit));
        pli_reghier_end_event(_handle);
         
      end
   end

   _blk.get_memories(_mems, UVM_NO_HIER);
   while(_mems.size() > 0) begin
      _mem = _mems.pop_front();
      record_reghier_mem(_mem);
   end
  
end
endfunction 

// record_hierarchy_complete_stream
function automatic void record_hierarchy_complete_stream(); begin
   string stream_name;
   int _handle;

   stream_name = "reg_hier_complete";
   _handle = pli_reghier_begin_event(stream_name);
   pli_reghier_set_label(_handle,"Reg_Hier_Complete");
   pli_reghier_end_event(_handle);  
end
endfunction

function automatic int record_reg_hier(); begin
   uvm_reg_block _root_blks[$], _blk, _blks[$], _parent_blk;
   int _blk_idx;
   uvm_reg_map _maps[$], _map, _umaps[int];
   uvm_cmdline_processor clp;


   uvm_reg_block::get_root_blocks(_root_blks);

   if (_root_blks.size()==0)
       return 0;
   for(int _blk_idx=0; _blk_idx < _root_blks.size(); _blk_idx++) begin
      _root_blks[_blk_idx].get_blocks(_blks, UVM_HIER);
   end

   while(_root_blks.size() > 0) begin
      _blk = _root_blks.pop_front();
      _blk.get_maps(_maps);
      record_reghier_blk(_blk);
   end

   while(_blks.size() > 0) begin
      _blk = _blks.pop_front();
      _blk.get_maps(_maps);
      _parent_blk = _blk.get_parent();
      record_reghier_blk(_blk);
   end

   while(_maps.size() > 0) begin
      _map = _maps.pop_front();

     if(!_umaps.exists(_map.get_inst_id())) begin
        _umaps[_map.get_inst_id()] = _map;
     end
   end

   foreach (_umaps[_id]) begin
      _map = _umaps[_id];
      record_reghier_map(_umaps[_id]);
   end

   g_refclass_id.delete();
   g_visited_regfile.delete();
   g_regfile_handle_class_name.delete();
   g_regblk_handle_class_name.delete();
   g_visited_regname.delete();

   // Register hierarchy is completed
   // Record specific stream
   record_hierarchy_complete_stream();
   return 1;
end
endfunction 
