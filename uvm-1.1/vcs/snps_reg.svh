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

`ifndef SNPS_REG_SVH
`define SNPS_REG_SVH
import uvm_pkg::*;

class snps_reg;

   class m_context;
      uvm_pkg::uvm_reg_block blk;
      uvm_pkg::uvm_reg_map   map;
   endclass

   local static int m_next_context_id = 1;
   local static m_context m_context_registry[int];
   
   static function int create_context(uvm_pkg::uvm_reg_block blk,
                                      uvm_pkg::uvm_reg_map map = null);
      m_context ctxt = new;
      ctxt.blk = blk;

      if (map == null) map = blk.default_map;
      ctxt.map = map;

      m_context_registry[m_next_context_id] = ctxt;
      
      return m_next_context_id++;;
   endfunction


   static function string get_context_name(int id);
      if (!m_context_registry.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/BADCTXT",
                    $sformatf("Context #%0d does not exist", id))
         return "";
      end
      return m_context_registry[id].blk.get_full_name();
   endfunction
   
   local static uvm_pkg::uvm_reg_map m_use_map;
   static function void use_context_map(int id);
      if (!m_context_registry.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/BADCTXT",
                    $sformatf("Context #%0d does not exist", id))
         return;
      end

      m_use_map = m_context_registry[id].map;
   endfunction
   
   
   local static int m_next_reg_id = 1;
   local static uvm_pkg::uvm_reg m_reg_id[int];
   
   static function int get_reg_id(string path,
                                  string name, int index1 = -1, int index2 = -1, int index3 = -1);
      uvm_pkg::uvm_reg rg;

      if (index1 == -1)
         rg = uvm_pkg::uvm_reg::m_get_reg_by_full_name({path, ".", name});
      else  begin
        if (index2 == -1)
            rg = uvm_pkg::uvm_reg::m_get_reg_by_full_name({path, ".", name,$sformatf("[%0d]",index1)});
        else begin
          if (index3 == -1)
              rg = uvm_pkg::uvm_reg::m_get_reg_by_full_name({path, ".", name,$sformatf("[%0d][%0d]",index1, index2)});
          else begin
              rg = uvm_pkg::uvm_reg::m_get_reg_by_full_name({path, ".", name,$sformatf("[%0d][%0d][%0d]",index1, index2, index3)});
          end
        end
      end

      if (rg == null) begin
         `uvm_error("SNPS/REG/CAPI/NOREG",
                    {"No register named \"", path, ".", name,
                     "\" exists in the UVM register model"})
         return 0;
      end

      m_reg_id[m_next_reg_id] = rg;

      return m_next_reg_id++;
   endfunction


   local static longint m_next_fld_id = -1;
   local static uvm_pkg::uvm_reg_field m_fld_id[int];

   static function int get_fld_id(string path,
                                  string rg,
                                  string name, int index1 = -1, int index2 = -1, int index3 = -1);
      uvm_pkg::uvm_reg_field fld;

      if (index1 == -1)
         fld = uvm_pkg::uvm_reg_field::m_get_field_by_full_name({path, ".", rg, ".", name});
      else  begin
        if (index2 == -1)
            fld = uvm_pkg::uvm_reg_field::m_get_field_by_full_name({path, ".", rg,$sformatf("[%0d]",index1), ".", name});
        else begin
          if (index3 == -1)
              fld = uvm_pkg::uvm_reg_field::m_get_field_by_full_name({path, ".", rg,$sformatf("[%0d][%0d]",index1, index2), ".", name});
          else begin
              fld = uvm_pkg::uvm_reg_field::m_get_field_by_full_name({path, ".", rg,$sformatf("[%0d][%0d][%0d]",index1, index2, index3), ".", name});
          end
        end
      end

      if (fld == null) begin
         `uvm_error("SNPS/REG/CAPI/NOFLD",
                    {"No field named \"", path, ".", rg, ".", name,
                     "\" exists in the UVM register model"})
         return 0;
      end

      m_fld_id[m_next_fld_id] = fld;

      return m_next_fld_id--;
   endfunction

   static task regRead(input int id, output longint val);
      if (id == 0) begin
         `uvm_error("SNPS/REG/CAPI/NOREG",
                    "Attempting to read a register that does not exists in the UVM register model")
         return;
      end
      
      if (id < 0) begin
         fldRead(id, val);
         return;
      end

      if (!m_reg_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOREGID",
                    $sformatf("INTERNAL ERROR: No register with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg rg = m_reg_id[id];
         uvm_pkg::uvm_status_e status;
         `uvm_info("SNPS/REG/CAPI/RD",
                   $sformatf("Reading from register %s", rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         rg.read(status, val, .map(m_use_map));
 `endif
      end
   endtask

   static function uvm_pkg::uvm_reg getRegByAddr(input int reg_addr);
         uvm_pkg::uvm_reg rg;
         uvm_pkg::uvm_status_e status;
         if (!m_use_map) use_context_map(1);
         rg = m_use_map.get_reg_by_offset(reg_addr);
         if (!rg) begin
            `uvm_error("SNPS/REG/CAPI/NOREGATADDR",
                       $sformatf("INTERNAL ERROR: No register with address  %0x exists in C API",
                                 reg_addr))
         end
         return rg;
     
   endfunction


   static task regReadAtAddr(input int reg_addr, output longint val);
         uvm_pkg::uvm_reg rg = getRegByAddr(reg_addr);
         uvm_pkg::uvm_status_e status;
         if (!rg) return;
         `uvm_info("SNPS/REG/CAPI/RD",
                   $sformatf("Reading from register %s", rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         rg.read(status, val, .map(m_use_map));
 `endif
   endtask

   local static task fldRead(input int id, output longint val);
      if (!m_fld_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOFLDID",
                    $sformatf("INTERNAL ERROR: No field with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg_field fld = m_fld_id[id];
         uvm_pkg::uvm_status_e status;
         `uvm_info("SNPS/REG/CAPI/RD",
                   $sformatf("Reading from field %s", fld.get_full_name()),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         fld.read(status, val, .map(m_use_map));
 `endif
      end
   endtask

   static task regWrite(int id, longint val);
      if (id == 0) begin
         `uvm_error("SNPS/REG/CAPI/NOREG",
                    "Attempting to write a register that does not exists in the UVM register model")
         return;
      end
      
      if (id < 0) begin
         fldWrite(id, val);
         return;
      end

      if (!m_reg_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOREGID",
                    $sformatf("INTERNAL ERROR: No register with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg rg = m_reg_id[id];
         uvm_pkg::uvm_status_e status;

         `uvm_info("SNPS/REG/CAPI/WR",
                   $sformatf("Writing 'h%h to register %s", val, rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         rg.write(status, val, .map(m_use_map));
`endif
      end
   endtask

   static task regWriteAtAddr(int reg_addr, longint val);
         uvm_pkg::uvm_reg rg = getRegByAddr(reg_addr);
         uvm_pkg::uvm_status_e status;
         if (!rg) return;

         `uvm_info("SNPS/REG/CAPI/WR",
                   $sformatf("Writing 'h%h to register %s", val, rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         rg.write(status, val, .map(m_use_map));
`endif
   endtask

   local static task fldWrite(int id, longint val);
      if (!m_fld_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOFLDID",
                    $sformatf("INTERNAL ERROR: No field with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg_field fld = m_fld_id[id];
         uvm_pkg::uvm_status_e status;

         `uvm_info("SNPS/REG/CAPI/WR",
                   $sformatf("Writing 'h%h to field %s", val, fld.get_full_name()),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         fld.write(status, val, .map(m_use_map));
`endif
      end
   endtask

`ifdef SNPS_UVMC_ONLY
   static task regGet(input int id, output longint val);
      if (id == 0) begin
         `uvm_error("SNPS/REG/CAPI/NOREG",
                    "Attempting to get a register that does not exists in the UVM register model")
         return;
      end
      
      if (id < 0) begin
         fldGet(id, val);
         return;
      end

      if (!m_reg_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOREGID",
                    $sformatf("INTERNAL ERROR: No register with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg rg = m_reg_id[id];
         uvm_pkg::uvm_status_e status;
         `uvm_info("SNPS/REG/CAPI/RD",
                   $sformatf("Reading from register %s in the UVM Register Model", rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
          val = rg.get();
 `endif
      end
   endtask

   static task regGetAtAddr(input int reg_addr, output longint val);
         uvm_pkg::uvm_reg rg = getRegByAddr(reg_addr);
         uvm_pkg::uvm_status_e status;
         if (!rg) return;

         `uvm_info("SNPS/REG/CAPI/GET",
                   $sformatf("Getting from register %s in the UVM Register Model", rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
          val = rg.get();
 `endif
   endtask

   local static task fldGet(input int id, output longint val);
      if (!m_fld_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOFLDID",
                    $sformatf("INTERNAL ERROR: No field with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg_field fld = m_fld_id[id];
         uvm_pkg::uvm_status_e status;
         `uvm_info("SNPS/REG/CAPI/RD",
                   $sformatf("Reading from field %s in the UVM Register Model", fld.get_full_name()),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         val = fld.get();
 `endif
      end
   endtask

   static task regSet(int id, longint val);
      if (id == 0) begin
         `uvm_error("SNPS/REG/CAPI/NOREG",
                    "Attempting to write a register that does not exists in the UVM register model")
         return;
      end
      
      if (id < 0) begin
         fldSet(id, val);
         return;
      end

      if (!m_reg_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOREGID",
                    $sformatf("INTERNAL ERROR: No register with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg rg = m_reg_id[id];
         uvm_pkg::uvm_status_e status;

         `uvm_info("SNPS/REG/CAPI/WR",
                   $sformatf("Writing 'h%h to register %s in the UVM Register Model", val, rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         rg.set(val);
`endif
      end
   endtask

   static task regSetAtAddr(int reg_addr, longint val);
         uvm_pkg::uvm_reg rg = getRegByAddr(reg_addr);
         uvm_pkg::uvm_status_e status;
         if (!rg) return;

         `uvm_info("SNPS/REG/CAPI/SET",
                   $sformatf("Setting 'h%h to register %s in the UVM Register Model", val, rg.get_full_name),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         rg.set(val);
`endif
   endtask

   local static task fldSet(int id, longint val);
      if (!m_fld_id.exists(id)) begin
         `uvm_error("SNPS/REG/CAPI/NOFLDID",
                    $sformatf("INTERNAL ERROR: No field with ID %0d exists in C API",
                              id))
         return;
      end

      begin
         uvm_pkg::uvm_reg_field fld = m_fld_id[id];
         uvm_pkg::uvm_status_e status;

         `uvm_info("SNPS/REG/CAPI/WR",
                   $sformatf("Writing 'h%h to field %s in the UVM Register Model", val, fld.get_full_name()),
                   UVM_MEDIUM)

`ifndef SNPS_REG_NOP
         fld.set(val);
`endif
      end
   endtask
`endif

endclass


export "DPI-C" function snps_reg__get_context_name;
function string snps_reg__get_context_name(int id);
   return snps_reg::get_context_name(id);
endfunction

export "DPI-C" function snps_reg__get_reg_id;
function int snps_reg__get_reg_id(string path,
                                  string name);
   return snps_reg::get_reg_id(path, name);
endfunction

export "DPI-C" function snps_reg__get_reg_array_id;
function int snps_reg__get_reg_array_id(string path,
                                  string name, int index1, int index2, int index3);
   return snps_reg::get_reg_id(path, name, index1, index2, index3);
endfunction

export "DPI-C" function snps_reg__get_fld_id;
function int snps_reg__get_fld_id(string path,
                                  string rg,
                                  string name);
   return snps_reg::get_fld_id(path, rg, name);
endfunction

export "DPI-C" function snps_reg__get_fld_array_id;
function int snps_reg__get_fld_array_id(string path,
                                  string rg,
                                  string name, int index1, int index2, int index3);
   return snps_reg::get_fld_id(path, rg, name, index1, index2, index3);
endfunction

export "DPI-C" function snps_reg__use_context_map;
function void snps_reg__use_context_map(int ctxt);
   snps_reg::use_context_map(ctxt);
endfunction

export "DPI-C" task snps_reg__regRead;
task snps_reg__regRead(int id, output longint val);
   snps_reg::regRead(id, val);
endtask

export "DPI-C" task snps_reg__regReadAtAddr;
task  snps_reg__regReadAtAddr(int reg_addr, output longint val);
   snps_reg::regReadAtAddr(reg_addr, val);
endtask

export "DPI-C" task snps_reg__regWrite;
task snps_reg__regWrite(int id, longint val);
   snps_reg::regWrite(id, val);
endtask

export "DPI-C" task snps_reg__regWriteAtAddr;
task  snps_reg__regWriteAtAddr(int reg_addr, longint val);
   snps_reg::regWriteAtAddr(reg_addr, val);
endtask

`ifdef SNPS_UVMC_ONLY
export "DPI-C" task snps_reg__regGet;
task snps_reg__regGet(int id, output longint val);
   snps_reg::regGet(id, val);
endtask

export "DPI-C" task snps_reg__regGetAtAddr;
task snps_reg__regGetAtAddr(int reg_addr, output longint val);
   snps_reg::regGetAtAddr(reg_addr, val);
endtask

export "DPI-C" task snps_reg__regSet;
task snps_reg__regSet(int id, longint val);
   snps_reg::regSet(id, val);
endtask

export "DPI-C" task snps_reg__regSetAtAddr;
task snps_reg__regSetAtAddr(int reg_addr, longint val);
   snps_reg::regSetAtAddr(reg_addr, val);
endtask
`endif //SNPS_UVMC_ONLY
`endif //SNPS_REG_SVH
