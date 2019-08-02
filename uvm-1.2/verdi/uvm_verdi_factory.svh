`ifndef UVM_VERDI_FACTORY_SVH
`define UVM_VERDI_FACTORY_SVH

`ifndef UVM_VERDI_NO_FACTORY_RECORDING
static integer facStreamArrByName [string];

class uvm_verdi_factory extends uvm_default_factory;
  integer verdi_factory_counter = 0;
  local static int fac_file_h = 0;
  uvm_factory delegate;

  function void register (uvm_object_wrapper obj);
          delegate.register(obj);
  endfunction

  function void set_inst_override_by_type (uvm_object_wrapper original_type,
          uvm_object_wrapper override_type,
          string full_inst_path);
          delegate.set_inst_override_by_type(original_type,override_type,full_inst_path);
          log_factory_info("FAC/SET",original_type.get_type_name(),override_type.get_type_name(),full_inst_path);
  endfunction

  virtual function void set_inst_override_by_name (string original_type_name,
          string override_type_name,
          string full_inst_path);
          delegate.set_inst_override_by_name(original_type_name,override_type_name,full_inst_path);
          log_factory_info("FAC/SET",original_type_name,override_type_name,full_inst_path);
  endfunction

  function void set_type_override_by_type (uvm_object_wrapper original_type,
          uvm_object_wrapper override_type,
          bit replace=1);
          delegate.set_type_override_by_type(original_type, override_type, replace);
          log_factory_info("FAC/SET",original_type.get_type_name(),override_type.get_type_name(),"");
  endfunction

  function void set_type_override_by_name (string original_type_name,
          string override_type_name,
          bit replace=1);
          delegate.set_type_override_by_name(original_type_name, override_type_name, replace);
          log_factory_info("FAC/SET",original_type_name,override_type_name,"");
  endfunction

  function uvm_object create_object_by_type    (uvm_object_wrapper requested_type,
          string parent_inst_path="",
          string name="");
          string full_inst_path;
          string original_type_name,override_type_name;
          uvm_object ret_obj;

          ret_obj = delegate.create_object_by_type(requested_type,parent_inst_path,name);
          if (ret_obj != null) begin //9001191446
            if (parent_inst_path == "")
                full_inst_path = name;
            else if (name != "")
                full_inst_path = {parent_inst_path,".",name};
            else
                full_inst_path = parent_inst_path;

            original_type_name = requested_type.get_type_name();
            override_type_name = ret_obj.get_type_name();
            if(original_type_name != override_type_name) begin
               log_factory_info("FAC/CREATE",original_type_name,override_type_name,full_inst_path);
            end
          end
          return ret_obj;
  endfunction

  function uvm_component create_component_by_type (uvm_object_wrapper requested_type,
          string parent_inst_path="",
          string name,
          uvm_component parent);
          string full_inst_path;
          string original_type_name,override_type_name;
          uvm_component ret_component;

          ret_component = delegate.create_component_by_type(requested_type,parent_inst_path,name,parent);
          if (parent_inst_path == "")
              full_inst_path = name;
          else if (name != "")
              full_inst_path = {parent_inst_path,".",name};
          else
              full_inst_path = parent_inst_path;

          original_type_name = requested_type.get_type_name();
          override_type_name = ret_component.get_type_name();
          if(original_type_name != override_type_name) begin
             log_factory_info("FAC/CREATE",original_type_name,override_type_name,full_inst_path);
          end
          return ret_component; 
  endfunction

  function uvm_object create_object_by_name (string requested_type_name,
          string parent_inst_path="",
          string name="");
          uvm_object_wrapper wrapper;
          string inst_path;
          uvm_object ret_obj;

          ret_obj = delegate.create_object_by_name(requested_type_name,parent_inst_path,name);
          if (parent_inst_path == "")
              inst_path = name;
          else if (name != "")
              inst_path = {parent_inst_path,".",name};
          else
              inst_path = parent_inst_path;

          if (ret_obj)
              log_factory_info("FAC/CREATE",requested_type_name,ret_obj.get_full_name(),inst_path);
          return ret_obj; 
  endfunction

  function uvm_component create_component_by_name (string requested_type_name,
     string parent_inst_path="",
     string name,
     uvm_component parent);
     uvm_object_wrapper wrapper;
     string inst_path;
     uvm_component ret_component;

     ret_component = delegate.create_component_by_name(requested_type_name,parent_inst_path,name,parent);

     if (parent_inst_path == "")
         inst_path = name;
     else if (name != "")
         inst_path = {parent_inst_path,".",name};
     else
         inst_path = parent_inst_path;
     if (ret_component)
         log_factory_info("FAC/CREATE",requested_type_name,ret_component.get_full_name(),inst_path); 
     return ret_component;
  endfunction

  function void debug_create_by_type (uvm_object_wrapper requested_type,
     string parent_inst_path="",
     string name="");
     delegate.debug_create_by_type(requested_type, parent_inst_path, name);
  endfunction

  function void debug_create_by_name (string requested_type_name,
     string parent_inst_path="",
     string name="");
     delegate.debug_create_by_name(requested_type_name, parent_inst_path, name);
  endfunction

  function uvm_object_wrapper find_override_by_type (uvm_object_wrapper requested_type, string full_inst_path);
     return delegate.find_override_by_type(requested_type, full_inst_path);
  endfunction

  function uvm_object_wrapper find_override_by_name (string requested_type_name, string full_inst_path);
     return delegate.find_override_by_name(requested_type_name, full_inst_path);
  endfunction

  function uvm_object_wrapper find_wrapper_by_name (string type_name);
     return delegate.find_wrapper_by_name(type_name);
  endfunction

  function void print(int all_types=1);
     delegate.print(all_types);
  endfunction

  function void log_factory_info(string label,string original_type_name,string override_type_name,string full_inst_path);
     string info_id,message;

     if (verdi_factory_counter==0)
         $display("*Verdi* Enable Verdi Factory Dumping.");
     verdi_factory_counter++;
     $sformat(message,"original_type_name=%s override_type_name=%s full_inst_path=%s",original_type_name,override_type_name,full_inst_path);
     `uvm_info(label,message,UVM_LOW)
  endfunction

endclass
`endif
`endif
