//
// -------------------------------------------------------------
//    Copyright 2004-2013 Synopsys, Inc.
//    Copyright 2010-2011 Mentor Graphics Corporation
//    Copyright 2010-2011 Cadence Design Systems, Inc.
//    All Rights Reserved Worldwide
//
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------
//
//-----------------------------------------------------------------
`ifndef SNPS_UVM_REG_BANK__SV
`define SNPS_UVM_REG_BANK__SV


// CLASS: snps_uvm_reg_bank_group
// Class specifying the modes available in a 
// bankGroup and the current mode a bankGroup 
// is currently in.Extensions of this class 
// specify a bankGroup type, with all of the 
// valid bankModes in that group.
// Instances of this class specify the current 
// mode a bankGroup is in. There is one instance
// of this class for each address map instance
// where that bankGroup exists. All instances 
// of this class are put in the uvm_resource_DB#
// (snps_uvm_reg_bank_group) resource database 
// under the full hierarchical name of the group.

// The user is responsible for retrieving the 
// appropriate instance of this class from the 
// resource database and calling a method on it
// to specify the current bankMode whenever it 
// changes. By default, a bankGroup is in its 
// first declared bankMode.
//
//-----------------------------------------------------------------
class snps_uvm_reg_bank_group extends uvm_object;
  `uvm_object_utils(snps_uvm_reg_bank_group)
   string                  modes[$];
   string                  m_currentmode;
   int m_mode;
   local int               m_has_cover;
   local int               m_cover_on;

   function new(string name = "", uvm_object parent = null, int has_coverage = UVM_NO_COVERAGE);
      super.new(name);
      m_has_cover   = has_coverage;
   endfunction

   protected virtual function void  sample();
   endfunction

   function uvm_reg_cvr_t build_coverage(uvm_reg_cvr_t models);
      typedef uvm_resource #(uvm_reg_cvr_t) rsrc_t;
      rsrc_t rsrc = uvm_reg_cvr_rsrc_db::get_by_name({"uvm_reg::", get_full_name()}, 
                                "include_coverage", 0); 
    
      if (rsrc == null) begin
           return UVM_NO_COVERAGE;
      end 
    
      return rsrc.read(this) & models; 
   endfunction: build_coverage

   // add_coverage
   function void add_coverage(uvm_reg_cvr_t models);
      this.m_has_cover |= models;
   endfunction: add_coverage

   // has_coverage
   function bit has_coverage(uvm_reg_cvr_t models);
      return ((m_has_cover & models) == models);
   endfunction: has_coverage

   // set_coverage
   function uvm_reg_cvr_t set_coverage(uvm_reg_cvr_t is_on);
      if (is_on == uvm_reg_cvr_t'(UVM_NO_COVERAGE)) begin
         m_cover_on = is_on;
         return m_cover_on;
      end
   
      m_cover_on = m_has_cover & is_on;
   
      return m_cover_on;
   endfunction: set_coverage
   
   
   // get_coverage
   function bit get_coverage(uvm_reg_cvr_t is_on);
      if (has_coverage(is_on) == 0)
         return 0;
      return ((m_cover_on & is_on) == is_on);
   endfunction: get_coverage

   function void set_current_mode(string mode = "");
      bit valid_mode = 0;
      foreach(modes[i]) begin
         if (modes[i] == mode) begin
            m_currentmode = mode;
            m_mode = i;
            sample();
            valid_mode = 1;
            break;
         end
      end
      if (!valid_mode) begin
        `uvm_error("RegModel", $sformatf("Attempting to set an invalid mode \"%s\" on Bank Group \"%s\", Ignoring..", mode, get_name()))
      end
   endfunction


   function string get_current_mode();
      return m_currentmode;
   endfunction


endclass



//-----------------------------------------------------------------
// CLASS: snps_uvm_reg_bank_set 
// Extension of the uvm_reg class to encapsulate
// all of the banked registers mapped at the same
// address. Instances of this class are created 
// during the address caching process (aka model
// locking) and is inserted in the reg_by_offset[]
// associative array as a placeholder for all of 
// the registers mapped at the same address.

// This class will be returned by the uvm_reg_map::
// get_reg_by_offset() method. The user API should
// be suitably overloaded to indicate to the user 
// that multiple registers are mapped to this address
// and thus cannot be used through this container.
//
// It provides a get_selected() method that returns
// the banked register that is currently selected 
// (or null if none are selected).
 
//
//-----------------------------------------------------------------
typedef class snps_uvm_reg_banked;
class snps_uvm_reg_bank_set extends uvm_reg;

  snps_uvm_reg_banked regs[$];

  function new(string name = "", int unsigned n_bits = 8, int has_coverage = 0);
    super.new(name, n_bits, has_coverage);
  endfunction

  function snps_uvm_reg_banked get_selected();
   foreach(regs[i]) begin
       snps_uvm_reg_bank_group _grp = regs[i].get_bankgroup();
       if(regs[i].get_bankmode() == _grp.get_current_mode())
          return regs[i];
   end
   return null;
  endfunction
  

endclass


//-----------------------------------------------------------------
// CLASS: snps_uvm_reg_banked
// Register abstraction base class for banked registers
//
// Banked registers are modeled by extending this class 
// instead of the uvm_reg class. 
// as a single entity.
//
//-----------------------------------------------------------------
typedef class snps_uvm_reg_map;
virtual class snps_uvm_reg_banked extends uvm_reg;

   local bit               m_selected;
   local snps_uvm_reg_bank_group m_bankgroup;
   local string            m_bankmode;

  // Function: new
   //
   // Create a new instance and type-specific configuration
   //
   // Creates an instance of a register abstraction class with the specified
   // name.
   extern function new (string name="",
                        int unsigned n_bits,
                        int has_coverage);


 

   // Function: configure
   //
   // Instance-specific configuration
   //
   // method takes an additional snps_uvm_reg_bank_group 
   // argument and a string argument to specify the 
   // bankMode that must be selected in the specified
   // bank group class instance for this banked register
   // to be selected.
   //
   extern function void configure (uvm_reg_block blk_parent,
                                   uvm_reg_file regfile_parent = null,
                                   string hdl_path = "",
                                   snps_uvm_reg_bank_group bankgroup = null,
                                   string bankmode = "" );


   // Task: write
   //
   // Write the specified value in this register
   //
   // Check that the register is indeed selected 
   // if a front-door operation is performed. 
   //
   //
   extern virtual task write(output uvm_status_e      status,
                             input  uvm_reg_data_t    value,
                             input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                             input  uvm_reg_map       map = null,
                             input  uvm_sequence_base parent = null,
                             input  int               prior = -1,
                             input  uvm_object        extension = null,
                             input  string            fname = "",
                             input  int               lineno = 0);


   // Task: read
   //
   // Read the current value from this register
   //
   // Check that the register is indeed selected 
   // if a front-door operation is performed.  
   //
   extern virtual task read(output uvm_status_e      status,
                            output uvm_reg_data_t    value,
                            input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                            input  uvm_reg_map       map = null,
                            input  uvm_sequence_base parent = null,
                            input  int               prior = -1,
                            input  uvm_object        extension = null,
                            input  string            fname = "",
                            input  int               lineno = 0);



   // Task: update
   //
   // Updates the content of the register in the design to match the
   // desired value
   //
   // Check that the register is indeed selected 
   // if a front-door operation is performed. 
   //
   extern virtual task update(output uvm_status_e      status,
                              input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map       map = null,
                              input  uvm_sequence_base parent = null,
                              input  int               prior = -1,
                              input  uvm_object        extension = null,
                              input  string            fname = "",
                              input  int               lineno = 0);


   // Task: mirror
   //
   // Read the register and update/check its mirror value
   //
   // Check that the register is indeed selected 
   // if a front-door operation is performed. 
   //
   extern virtual task mirror(output uvm_status_e      status,
                              input uvm_check_e        check  = UVM_NO_CHECK,
                              input uvm_door_e         path = UVM_DEFAULT_DOOR,
                              input uvm_reg_map        map = null,
                              input uvm_sequence_base  parent = null,
                              input int                prior = -1,
                              input  uvm_object        extension = null,
                              input string             fname = "",
                              input int                lineno = 0);


   // Function: get_bank_set
   //
   // method to return the container of banked
   // registers mapped to the same address 
   //
   extern virtual function snps_uvm_reg_bank_set get_bank_set();
   
   extern virtual function string get_bankmode();
   
   extern virtual function snps_uvm_reg_bank_group get_bankgroup();
endclass: snps_uvm_reg_banked






//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------
function snps_uvm_reg_banked::new(string name="", int unsigned n_bits, int has_coverage);
   super.new(name, n_bits, has_coverage);
endfunction

// configure

function void snps_uvm_reg_banked::configure (uvm_reg_block blk_parent,
                                   uvm_reg_file regfile_parent = null,
                                   string hdl_path = "",
                                   snps_uvm_reg_bank_group bankgroup = null,
                                   string bankmode = "" );
   super.configure(blk_parent,regfile_parent, hdl_path);
   m_bankmode = bankmode;
   m_bankgroup = bankgroup;
endfunction: configure


function snps_uvm_reg_bank_set snps_uvm_reg_banked::get_bank_set();
begin
   uvm_reg_map rg_maps[$];
   snps_uvm_reg_map _map;
   this.get_maps(rg_maps);
   foreach(rg_maps[i]) begin
       $cast(_map,rg_maps[i]);
       if(_map.reg_by_offset.exists(this.get_address()))
          return  _map.reg_by_offset[this.get_address()];
   end
   return null ; 
end
endfunction
   
function string snps_uvm_reg_banked::get_bankmode();
   return m_bankmode;
endfunction
   
function snps_uvm_reg_bank_group snps_uvm_reg_banked::get_bankgroup();
   return m_bankgroup;
endfunction

task snps_uvm_reg_banked::write(output uvm_status_e      status,
                    input  uvm_reg_data_t    value,
                    input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                    input  uvm_reg_map       map = null,
                    input  uvm_sequence_base parent = null,
                    input  int               prior = -1,
                    input  uvm_object        extension = null,
                    input  string            fname = "",
                    input  int               lineno = 0);
 if(m_bankmode != m_bankgroup.get_current_mode())
   `uvm_error("RegModel", $sformatf("Trying to write to a Banked Register \"%s\" which is not slected, the current bankmode is \"%s\"", get_full_name(), m_bankmode))
 else
    super.write(status,value,path,map, parent, prior,extension,fname,lineno);
  

endtask

task snps_uvm_reg_banked::read(output uvm_status_e      status,
                   output uvm_reg_data_t    value,
                   input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                   input  uvm_reg_map       map = null,
                   input  uvm_sequence_base parent = null,
                   input  int               prior = -1,
                   input  uvm_object        extension = null,
                   input  string            fname = "",
                   input  int               lineno = 0);
 if(m_bankmode != m_bankgroup.get_current_mode())
   `uvm_error("RegModel", $sformatf("Trying to read to a Banked Register \"%s\" which is not slected, the current bankmode is \"%s\"", get_full_name(), m_bankmode))
 else
   super.read (status, value, path, map, parent, prior, extension, fname, lineno);
endtask: read


// update

task snps_uvm_reg_banked::update(output uvm_status_e      status,
                     input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                     input  uvm_reg_map       map = null,
                     input  uvm_sequence_base parent = null,
                     input  int               prior = -1,
                     input  uvm_object        extension = null,
                     input  string            fname = "",
                     input  int               lineno = 0);
 if(m_bankmode != m_bankgroup.get_current_mode())
   `uvm_error("RegModel", $sformatf("Trying to update a Banked Register \"%s\" which is not slected, the current bankmode is \"%s\"", get_full_name(), m_bankmode))
 else
   super.update (status, path, map, parent, prior, extension, fname, lineno);
endtask: update


// mirror

task snps_uvm_reg_banked::mirror(output uvm_status_e       status,
                     input  uvm_check_e        check = UVM_NO_CHECK,
                     input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                     input  uvm_reg_map        map = null,
                     input  uvm_sequence_base  parent = null,
                     input  int                prior = -1,
                     input  uvm_object         extension = null,
                     input  string             fname = "",
                     input  int                lineno = 0);
 if(m_bankmode != m_bankgroup.get_current_mode())
   `uvm_error("RegModel", $sformatf("Trying to mirror a Banked Register \"%s\" which is not slected, the current bankmode is \"%s\"", get_full_name(), m_bankmode))
 else
   super.mirror (status, check, path, map, parent, prior, extension, fname, lineno);
endtask: mirror


//-----------------------------------------------------------------
// CLASS: snps_uvm_reg_map
// Override the uvm_reg_map::Xinit_address_mapX()
// method to detect banked registers mapped to 
// the same physical address and wrap them in an
// instance of snps_uvm_reg_bank_set class. All 
// registers mapped to the same physical address 
// must be banked registers and must be in the
// same bankGroup and be mutually exclusively 
// selected. 
//
//-----------------------------------------------------------------

class snps_uvm_reg_map extends uvm_reg_map;

   `uvm_object_utils(snps_uvm_reg_map)

   extern function new(string name="snps_uvm_reg_map");

   snps_uvm_reg_bank_set reg_by_offset[uvm_reg_addr_t];
   //local uvm_reg_block m_parent;
    
   // Function: get_reg_by_offset
   //
   // Get registers mapped at offset
   //
   // Identify the snps_uvm_reg_bank_set or the group of 
   // registers  located at the same specified offset within
   // this address map for the specified type of access.
   // Returns set or single register
   //
   // The model must be locked using <uvm_reg_block::lock_model()>
   // to enable this functionality.
   //
   extern virtual function uvm_reg get_reg_by_offset(uvm_reg_addr_t offset,
                                                     bit            read = 1);

   extern /*local*/ function void Xinit_address_mapX();

endclass

// new

function snps_uvm_reg_map::new(string name = "snps_uvm_reg_map");
   super.new(name);
endfunction

// Xinit_address_mapX

function void snps_uvm_reg_map::Xinit_address_mapX();

   int unsigned bus_width;
   uvm_reg regs[$];
   uvm_reg unmapped_regs[$];

   get_registers(regs);

   foreach (regs[idx]) begin
     uvm_reg rg = regs[idx];
     uvm_reg_map_info reg_info = get_reg_map_info(rg);
     reg_info.is_initialized=1;
     if (reg_info.unmapped) begin
        unmapped_regs.push_back(rg);
     end
   end

   super.Xinit_address_mapX();


   foreach (unmapped_regs[idx]) begin // {
     uvm_reg rg = unmapped_regs[idx];
     uvm_reg_map_info reg_info = get_reg_map_info(rg);
     reg_info.is_initialized=1;

     begin //{
     string rg_acc = rg.Xget_fields_accessX(this);
       uvm_reg_addr_t addrs[];
        
       bus_width = get_physical_addresses(reg_info.offset,0,rg.get_n_bytes(),addrs);
        
       foreach (addrs[i]) begin //{
         uvm_reg_addr_t addr = addrs[i];
         uvm_reg rg2 = get_reg_by_offset(addr);

         if (rg2) begin //{
            snps_uvm_reg_bank_set bank_set = new();
            snps_uvm_reg_banked _reg_banked;

            string rg2_acc = rg2.Xget_fields_accessX(this);
           
            if($cast(_reg_banked, rg))
               bank_set.regs.push_back(_reg_banked); 

            if (rg_acc != "RO" && rg2_acc != "WO") begin //{
                if (rg_acc != "WO" && rg2_acc != "RO") begin //{
                    if($cast(_reg_banked, rg))
                        bank_set.regs.push_back(_reg_banked); 
                end //}
            end //}
          
         end //}
       end //}
       reg_info.addr = addrs;
     end //}
   end //}


endfunction


// get_reg_by_offset

function uvm_reg snps_uvm_reg_map::get_reg_by_offset(uvm_reg_addr_t offset,
                                                bit            read = 1);
   uvm_reg_block parent = get_parent();
   if (!parent.is_locked()) begin
      `uvm_error("RegModel", $sformatf("Cannot get register by offset: Block %s is not locked.", parent.get_full_name()));
      return null;
   end

   if (reg_by_offset.exists(offset))
     return reg_by_offset[offset];
   else 
     return super.get_reg_by_offset(offset,read);

endfunction

//-----------------------------------------------------------------
// CLASS: snps_uvm_reg_predictor
// This class is a modified version of 
// uvm_reg_predictor::write() to handle the 
// case where uvm_reg_map::get_reg_by_offset()
// returns an instance of snps_uvm_reg_bank_set
// instead of a plain uvm_reg.

// Instances of this predictor must be used 
// instead of the uvm_reg_predictor class in
// environments where banked registers are used.

//
//-----------------------------------------------------------------
class snps_uvm_reg_predictor#(type BUSTYPE=int) extends uvm_reg_predictor#(BUSTYPE);
   `uvm_component_param_utils(snps_uvm_reg_predictor#(BUSTYPE))


  // Variable: map
  //
  // The map used to convert a bus address to the corresponding register
  // or memory handle. Must be configured before the run phase.
  // 
  snps_uvm_reg_map map;
  local uvm_predict_s m_pending[uvm_reg];



  // Function: new
  //
  // Create a new instance of this type, giving it the optional ~name~
  // and ~parent~.
  //
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // This method is documented in uvm_object
  //static string type_name = "";
  virtual function string get_type_name();
    if (type_name == "") begin
      BUSTYPE t;
      t = BUSTYPE::type_id::create("t");
      type_name = {"snps_uvm_reg_predictor #(", t.get_type_name(), ")"};
    end
    return type_name;
  endfunction


 // Function- write
  //
  // not a user-level method. Do not call directly. See documentation
  // for the ~bus_in~ member.
  //
  virtual function void write(BUSTYPE tr);
     uvm_reg rg;
     snps_uvm_reg_bank_set rg_set;
     uvm_reg   tmp_reg;
     uvm_reg_bus_op rw;
    if (adapter == null)
     `uvm_fatal("REG/WRITE/NULL","write: adapter handle is null") 

     // In case they forget to set byte_en
     rw.byte_en = -1;
     adapter.bus2reg(tr,rw);
     tmp_reg = map.get_reg_by_offset(rw.addr, (rw.kind == UVM_READ));
     if((tmp_reg != null) && $cast(rg_set, tmp_reg))
        rg = rg_set.get_selected();
     else 
        rg = tmp_reg;


     // ToDo: Add memory look-up and call uvm_mem::XsampleX()

     if (rg != null) begin
       bit found;
       uvm_reg_item reg_item;
       snps_uvm_reg_map local_map;
       uvm_reg_map local_reg_map;
       uvm_reg_map_info map_info;
       uvm_predict_s predict_info;
       uvm_reg_indirect_data ireg;
       uvm_reg ir;
 
       if (!m_pending.exists(rg)) begin
         uvm_reg_item item = new;
         predict_info =new;
         item.element_kind = UVM_REG;
         item.element      = rg;
         item.path         = UVM_PREDICT;
         item.map          = map;
         item.kind         = rw.kind;
         predict_info.reg_item = item;
         m_pending[rg] = predict_info;
       end
       predict_info = m_pending[rg];
       reg_item = predict_info.reg_item;

       if (predict_info.addr.exists(rw.addr)) begin
          `uvm_error("REG_PREDICT_COLLISION",{"Collision detected for register '",
                     rg.get_full_name(),"'"})
          // TODO: what to do with subsequent collisions?
          m_pending.delete(rg);
       end

       local_reg_map = rg.get_local_map(map);
       if (!$cast(local_map, local_reg_map)) begin
         `uvm_fatal("REG_PREDICT_NOOVERRIDE", "uvm_reg_map type is not overriden to snps_uvm_reg_map");
       end
       map_info = local_map.get_reg_map_info(rg);
       ir=($cast(ireg, rg))?ireg.get_indirect_reg():rg;

       foreach (map_info.addr[i]) begin
         if (rw.addr == map_info.addr[i]) begin
            found = 1;
           reg_item.value[0] |= rw.data << (i * map.get_n_bytes()*8);
           predict_info.addr[rw.addr] = 1;
           if (predict_info.addr.num() == map_info.addr.size()) begin
              // We've captured the entire abstract register transaction.
              uvm_predict_e predict_kind = 
                  (reg_item.kind == UVM_WRITE) ? UVM_PREDICT_WRITE : UVM_PREDICT_READ;

              if (reg_item.kind == UVM_READ &&
                  local_map.get_check_on_read() &&
                  reg_item.status != UVM_NOT_OK) begin
                 void'(rg.do_check(ir.get_mirrored_value(), reg_item.value[0], local_map));
              end
              
              pre_predict(reg_item);

              ir.XsampleX(reg_item.value[0], rw.byte_en,
                          reg_item.kind == UVM_READ, local_map);
              begin
                 uvm_reg_block blk = rg.get_parent();
                 blk.XsampleX(map_info.offset,
                              reg_item.kind == UVM_READ,
                              local_map);
              end

              rg.do_predict(reg_item, predict_kind, rw.byte_en);
              if(reg_item.kind == UVM_WRITE)
                `uvm_info("REG_PREDICT", {"Observed WRITE transaction to register ",
                         ir.get_full_name(), ": value='h",
                         $sformatf("%0h",reg_item.value[0]), " : updated value = 'h", 
                         $sformatf("%0h",ir.get())},UVM_HIGH)
              else
                `uvm_info("REG_PREDICT", {"Observed READ transaction to register ",
                         ir.get_full_name(), ": value='h",
                         $sformatf("%0h",reg_item.value[0])},UVM_HIGH)
              reg_ap.write(reg_item);
              m_pending.delete(rg);
           end
           break;
         end
       end
       if (!found)
         `uvm_error("REG_PREDICT_INTERNAL",{"Unexpected failed address lookup for register '",
                  rg.get_full_name(),"'"})
     end
     else begin
       `uvm_info("REG_PREDICT_NOT_FOR_ME",
          {"Observed transaction does not target a register: ",
            $sformatf("%p",tr)},UVM_FULL)
     end
  endfunction

  
  
   

endclass

`endif


