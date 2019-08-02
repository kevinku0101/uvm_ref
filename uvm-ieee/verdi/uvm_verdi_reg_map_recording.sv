//-------------------------------------------------------------
// SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary work of 
// Synopsys, Inc., and is fully protected under copyright and trade 
// secret laws. You may not view, use, disclose, copy, or distribute this 
// file or any information contained herein except pursuant to a valid 
// written license from Synopsys. 
//-------------------------------------------------------------

class uvm_map_access_recorder;
   static local uvm_map_access_recorder m_inst=null;

   static function uvm_map_access_recorder get_inst(); 
      if(m_inst==null)
         m_inst = new;
      return m_inst;
   endfunction

   local int address_to_register[uvm_reg_addr_logic_t][string];
   local uvm_reg_addr_logic_t register_end_address[int];
   local string access_statuses[uvm_reg_addr_logic_t];

   local string inst_id_to_reg_name[int];
   local int reg_name_to_inst_id[string];

   local int current_access_reg[string][string];
   local string current_access_reg_map[string][string];

   extern virtual function void insert_register(uvm_reg_addr_logic_t addr, string map_name, uvm_object reg_object);
   extern virtual function string get_register_name_by_address(uvm_reg_addr_logic_t addr, string map_name); 
   extern virtual function int  get_register_id_by_address(uvm_reg_addr_logic_t addr, string map_name); 
   extern virtual function void insert_access_status(uvm_reg_addr_logic_t addr, string map_name, string status);
   extern virtual function bit pop_access_status(input string reg_name, input string map_name, output string status, output uvm_reg_addr_logic_t addr, input string event_type);

   extern virtual function void begin_recording(uvm_reg_addr_logic_t addr, string map_name, string event_type);
   extern virtual function bit  end_recording(string event_type, string path_s, string value_s, string reg_name);
endclass

function void uvm_map_access_recorder::insert_register(uvm_reg_addr_logic_t addr, string map_name, uvm_object reg_object);
   uvm_reg _reg;
   uvm_mem _mem;
   uvm_reg_addr_logic_t _end_addr;
   int _inst_id;
   
   _end_addr = 0; 
   _inst_id = reg_object.get_inst_id();

   if($cast(_reg, reg_object)) begin
      _end_addr = addr + _reg.get_n_bits();
      inst_id_to_reg_name[_inst_id] = _reg.get_full_name();
   end else if($cast(_mem, reg_object)) begin
      _end_addr = addr + _mem.get_size() * _mem.get_n_bits();
      inst_id_to_reg_name[_inst_id] = _mem.get_full_name();
   end else
      return;
 
   if(address_to_register.exists(addr) &&
      address_to_register[addr].exists(map_name))
      return;

   address_to_register[addr][map_name] = _inst_id;
   register_end_address[_inst_id] = _end_addr;
endfunction


function string uvm_map_access_recorder::get_register_name_by_address(uvm_reg_addr_logic_t addr, string map_name);
   int _inst_id;

   _inst_id = get_register_id_by_address(addr, map_name);

   if(inst_id_to_reg_name.exists(_inst_id))
      return inst_id_to_reg_name[_inst_id];

   return "";
endfunction

function int uvm_map_access_recorder::get_register_id_by_address(uvm_reg_addr_logic_t addr, string map_name);
  
   uvm_reg_addr_logic_t addr_key;
   string addr_map_name;
 
   if(address_to_register.exists(addr) && address_to_register[addr].exists(map_name))
      return address_to_register[addr][map_name];

   foreach(address_to_register[addr_key, addr_map_name]) begin
      int _inst_id;
      uvm_reg_addr_logic_t _end_addr;

      if(addr_map_name!=map_name)
         continue;

      _inst_id = address_to_register[addr_key][addr_map_name];
      if(!register_end_address.exists(_inst_id))
         return 0;

      _end_addr = register_end_address[_inst_id];
      
      if(addr>addr_key && addr <= _end_addr)
         return _inst_id;
   end

   return 0;
endfunction

function void uvm_map_access_recorder::insert_access_status(uvm_reg_addr_logic_t addr, string map_name, string status);
    int _inst_id;
    string _reg_name;

    $sformat(access_statuses[addr], "%0s", status);

    _inst_id = get_register_id_by_address(addr, map_name);

endfunction

function bit uvm_map_access_recorder::pop_access_status(input string reg_name, input string map_name, output string status, output uvm_reg_addr_logic_t addr, input string event_type);
    
    string _access_map_name, _e_type;

    if(!current_access_reg_map.exists(reg_name))
       return 0;


    if(event_type.substr(0,4) == "Wrote") begin
       _e_type = "WRITE";
    end else if(event_type.substr(0,3) == "Read") begin
       _e_type = "READ";
    end

    if(!current_access_reg_map[reg_name].exists(_e_type))
       return 0;

    _access_map_name = current_access_reg_map[reg_name][_e_type];

    if(map_name != _access_map_name)
       return 0;

    if(access_statuses.size()==0)
       return 0;

    if(!access_statuses.first(addr))
       return 0;

    status = access_statuses[addr];

    access_statuses.delete(addr);

    return 1;
endfunction

function void uvm_map_access_recorder::begin_recording(uvm_reg_addr_logic_t addr, string map_name, string event_type);
    longint unsigned _cur_tr_h;
    int _inst_id;
    string _stream_name, _cur_reg_name;
    longint unsigned _stream_h;
    int is_writing= 0;

    _inst_id = get_register_id_by_address(addr, map_name);
    if(!inst_id_to_reg_name.exists(_inst_id)) 
       return;

    _cur_reg_name = inst_id_to_reg_name[_inst_id];

    if(event_type.substr(0,6) == "Writing") begin
       is_writing = 1;    
       if(current_access_reg.exists(_cur_reg_name) && 
          current_access_reg[_cur_reg_name].exists("WRITE")) begin

          if(current_access_reg_map.exists(_cur_reg_name) &&
             current_access_reg_map[_cur_reg_name].exists("WRITE") &&
             current_access_reg_map[_cur_reg_name]["WRITE"] == map_name)
             return;
       end   

    end else if(event_type.substr(0,6) == "Reading") begin
       is_writing = 2;
       if(current_access_reg.exists(_cur_reg_name) && 
          current_access_reg[_cur_reg_name].exists("READ")) begin

          if(current_access_reg_map.exists(_cur_reg_name) &&
             current_access_reg_map[_cur_reg_name].exists("READ") &&
             current_access_reg_map[_cur_reg_name]["READ"] == map_name)
             return;
       end   
    end

    $sformat(_stream_name, "UVM.RAL_TRACE.%0s", _cur_reg_name);

    if(streamArrByName.exists(_stream_name))
       _stream_h = streamArrByName[_stream_name];
    else begin
// 9001353389
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       _stream_h = pli_inst.create_stream_begin(_stream_name, $sformatf("+description+type=register_access"));
`else
       _stream_h = pli_inst.create_stream_begin(_stream_name, $sformatf("type=register_access"));
`endif
       streamArrByName[_stream_name] = _stream_h;
       pli_inst.create_stream_end(_stream_h); 
    end

    _cur_tr_h = pli_inst.begin_tr(_stream_h, "+type+transaction");


    if(is_writing==1) begin
       pli_inst.set_label(_cur_tr_h, "Write Value");
       current_access_reg[_cur_reg_name]["WRITE"] = _cur_tr_h;
       current_access_reg_map[_cur_reg_name]["WRITE"] = map_name;
    end else if(is_writing==2) begin
       pli_inst.set_label(_cur_tr_h, "Read Value");
       current_access_reg[_cur_reg_name]["READ"] = _cur_tr_h;
       current_access_reg_map[_cur_reg_name]["READ"] = map_name;
    end


endfunction

function bit uvm_map_access_recorder::end_recording(string event_type, string path_s, string value_s, string reg_name);
    uvm_reg_addr_logic_t addr;
    uvm_reg_data_logic_t value_logic;
    int _cur_tr_h;
    string status, nvalue_s, _e_type;
    

    if(!current_access_reg.exists(reg_name))
       return 0;

    if(event_type.substr(0, 4) == "Wrote") begin
       _e_type = "WRITE";
    end else if(event_type.substr(0,3) == "Read") begin
       _e_type = "READ";
    end

    if(!current_access_reg[reg_name].exists(_e_type))
       return 0;
 
    _cur_tr_h = current_access_reg[reg_name][_e_type];
    if(_cur_tr_h==0)
       return 0;

    if(value_s.substr(0,1) == "0x")
       nvalue_s = value_s.substr(2, value_s.len()-1);
    else
       nvalue_s = value_s;

    value_logic = nvalue_s.atohex();

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
    pli_inst.add_attribute_string(_cur_tr_h, path_s, "+name+path", "+numbit+0");
    pli_inst.add_attribute_logic(_cur_tr_h, value_logic, "+name+value", "+radix+hex", $sformatf("+numbit+%0d", $size(value_logic))); 
`else
    pli_inst.add_attribute_string(_cur_tr_h, path_s, "path", "");
    pli_inst.add_attribute_logic(_cur_tr_h, value_logic, "value", "+radix+hex", $sformatf("%0d", $size(value_logic)));
`endif
//

    while(pop_access_status(reg_name, path_s, status, addr, event_type)) begin 

// 6000025017
`ifdef VERDI_REPLACE_DPI_WITH_PLI
       pli_inst.add_attribute_string(_cur_tr_h, status, $sformatf("+name+address_%0h", addr), "+numbit+0");
`else
       pli_inst.add_attribute_string(_cur_tr_h, status, $sformatf("address_%0h", addr), "");
`endif
//
    end

    pli_inst.end_tr(_cur_tr_h);

        
    current_access_reg[reg_name].delete(_e_type);
    current_access_reg_map[reg_name].delete(_e_type);
     
    return 1;
endfunction

