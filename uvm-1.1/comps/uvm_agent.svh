//
//------------------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc. 
//   Copyright 2010 Synopsys, Inc.
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
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: uvm_agent
//
// The uvm_agent virtual class should be used as the base class for the user-
// defined agents. Deriving from uvm_agent will allow you to distinguish agents
// from other component types also using its inheritance. Such agents will
// automatically inherit features that may be added to uvm_agent in the future.
// 
// While an agent's build function, inherited from <uvm_component>, can be
// implemented to define any agent topology, an agent typically contains three
// subcomponents: a driver, sequencer, and monitor. If the agent is active,
// subtypes should contain all three subcomponents. If the agent is passive,
// subtypes should contain only the monitor.
//------------------------------------------------------------------------------

virtual class uvm_agent extends uvm_component;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Function: new
  //
  // Creates and initializes an instance of this class using the normal
  // constructor arguments for <uvm_component>: ~name~ is the name of the
  // instance, and ~parent~ is the handle to the hierarchical parent, if any.
  //
  // The int configuration parameter is_active is used to identify whether this
  // agent should be acting in active or passive mode. This parameter can
  // be set by doing:
  //
  //| set_config_int("<path_to_agent>", "is_active", UVM_ACTIVE);

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
       uvm_bitstream_t active_bs;      
       if(uvm_config_db #(uvm_bitstream_t)::get(this, "", "is_active", active_bs))
         is_active = uvm_active_passive_enum'(active_bs);
       else begin
         bit active_b;
         if(uvm_config_db #(bit)::get(this, "", "is_active", active_b))
           is_active = uvm_active_passive_enum'(active_b);
         else begin
           int active_i;
           if (uvm_config_db #(int)::get(this, "", "is_active", active_i))
              is_active = uvm_active_passive_enum'(active_i);
         end
       end
    end
  endfunction

  const static string type_name = "uvm_agent";

  virtual function string get_type_name ();
    return type_name;
  endfunction

  // Function: get_is_active
  //
  // Returns UVM_ACTIVE is the agent is acting as an active agent and 
  // UVM_PASSIVE if it is acting as a passive agent. The default implementation
  // is to just return the is_active flag, but the component developer may
  // override this behavior if a more complex algorithm is needed to determine
  // the active/passive nature of the agent.

  virtual function uvm_active_passive_enum get_is_active();
    return is_active;
  endfunction
endclass

