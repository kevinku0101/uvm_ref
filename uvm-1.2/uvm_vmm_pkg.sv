//----------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc. 
//   Copyright 2010 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary derivative
//   work of Synopsys, Inc., and is fully protected under copyright and
//   trade secret laws. You may not view, use, disclose, copy, or
//   distribute this file or any information contained herein except
//   pursuant to a valid written license from Synopsys.
//
//   The Original Work is licensed under the Apache License, Version 2.0.
//
//   You may obtain a copy of the Original Work at
//
//       http://www.accellera.org/activities/vip/
//
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//
//----------------------------------------------------------------------

`ifndef UVM_VMM_PKG_SV
`define UVM_VMM_PKG_SV

`ifndef VMM_12
 `define NO_VMM_12
`endif

`ifndef UVM_PKG_SV
`include "uvm_pkg.sv" // DO NOT INLINE

`endif

`ifndef VMM__SV
`define VMM_IN_PACKAGE
`include "vmm.sv" // DO NOT INLINE

`endif

import uvm_pkg::*;

//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

`ifndef UVM_ON_TOP
  `ifndef VMM_ON_TOP
     "No UVM|VMM_ON_TOP... must define UVM_ON_TOP or VMM_ON_TOP"
  `endif
`endif
  
package uvi_interop_pkg;
  import uvm_pkg::*;
`ifdef VMM_IN_PACKAGE
  import vmm_std_lib::*;
`else 
	"You need to specify +define+VMM_IN_PACKAGE with this library"
`endif
  
// for UVM_ON_TOP
//------------------------------------------------------------------------------
// Copyright 2010 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//
// Redirect VMM messages to UVM with the following mapping
//
//   VMM FATAL   --> UVM FATAL/NONE
//   VMM ERROR   --> UVM ERROR/LOW
//   VMM WARNING --> UVM WARNING/MEDIUM
//   default     --> UVM INFO/MEDIUM
//     TRACE_SEV             /HIGH
//     DEBUG_SEV             /FULL
//     VERBOSE_SEV           /DEBUG
//


class uvi_uvm_vmm_log_fmt extends vmm_log_format;

`ifdef UVM_ON_TOP
   static local uvi_uvm_vmm_log_fmt auto_register = new();
`endif

   local uvm_report_server svr;
   local uvm_report_object client;
   local vmm_log log;

   function new();
      uvm_report_server gs = uvm_report_server::get_server(); //TARUN
      this.svr    = gs.get_server();
      this.log    = new("VMM->UVM", "Redirector");
      void'(this.log.set_format(this));
      // Let UVM abort after too many errors
      this.log.stop_after_n_errors(0);
   endfunction


   virtual function string format_msg(string name,
                                      string inst,
                                      string msg_typ,
                                      string severity,
`ifdef VMM_LOG_FORMAT_FILE_LINE
                                      string fname,
                                      int    line,
`endif
                                      ref string lines[$]);
`ifndef VMM_LOG_FORMAT_FILE_LINE
      string fname = "";
      int    line  = 0;
`endif
      uvm_severity uvm_sev;
      int uvm_verb;
      string msg;
      uvm_report_message l_report_message; // TARUN
      uvm_action uvm_act;

      if (this.client == null) begin
        this.client = new(name);
        // Make sure all messages are issed on the UVM side
        this.client.set_report_verbosity_level(32'h7FFF_FFFF);
      end 

      uvm_sev  = UVM_INFO;
      uvm_verb = UVM_MEDIUM;
      uvm_act = UVM_DISPLAY;

      if (severity == this.log.sev_image(vmm_log::FATAL_SEV))
         uvm_verb = UVM_NONE;
      else if (severity == this.log.sev_image(vmm_log::ERROR_SEV))
         uvm_verb = UVM_LOW;
      else if (severity == this.log.sev_image(vmm_log::TRACE_SEV))
         uvm_verb = UVM_HIGH;
      else if (severity == this.log.sev_image(vmm_log::DEBUG_SEV))
         uvm_verb = UVM_FULL;
      else if (severity == this.log.sev_image(vmm_log::VERBOSE_SEV))
         uvm_verb = UVM_DEBUG;

      if (msg_typ == this.log.typ_image(vmm_log::FAILURE_TYP)) begin
         case (uvm_verb)
            UVM_NONE:   uvm_sev = UVM_FATAL;
            UVM_LOW:    uvm_sev = UVM_ERROR;
            UVM_MEDIUM: uvm_sev = UVM_WARNING;
         endcase
         case (uvm_sev) 
            UVM_ERROR: uvm_act = uvm_act | UVM_COUNT;
            UVM_FATAL: uvm_act = uvm_act | UVM_EXIT;
         endcase
      end

      if (lines.size() > 0) begin
         int i = 1;
         msg = lines[0];
         while (i < lines.size()) begin
            msg = {msg, "\n", lines[i]};
            i++;
         end
      end

      l_report_message = uvm_report_message::new_report_message();
      l_report_message.set_report_message(uvm_sev, inst, msg, uvm_verb, fname, line, "");
      l_report_message.set_report_object(this.client);
      l_report_message.set_report_handler(client.get_report_handler());
      l_report_message.set_report_server(this.svr);
      l_report_message.set_action(uvm_act);

      this.svr.process_report_message(l_report_message);

      return "";
   endfunction: format_msg
   

   virtual function string continue_msg(string name,
                                        string inst,
                                        string msg_typ,
                                        string severity,
`ifdef VMM_LOG_FORMAT_FILE_LINE
                                        string fname,
                                        int    line,
`endif
                                        ref string lines[$]);
      return this.format_msg(name, inst, msg_typ, severity,
`ifdef VMM_LOG_FORMAT_FILE_LINE
                             fname, line,
`endif
                             lines);
   endfunction: continue_msg
endclass
//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//
// Title- Integrated Phase Control - UVM-on-top
//
//------------------------------------------------------------------------------
//
// This class is used to wrap a VMM env for use as an uvm_component in an
// UVM environment. The <uvi_uvm_vmm_env> component provides default implementations
// of the UVM phases that delegate to the underlying VMM env's phases. 
// Any number of vmm_env's may be wrapped and reused using the <uvi_uvm_vmm_env>.
//
// All other VMM components, such as the ~vmm_subenv~ and ~vmm_xactor~, do not
// require integrated phase support; they can be instantiated and initialized
// directly by the parent component using their respective APIs.
//
// Implementation:
//
// New phases are added to UVM's phasing lineup to accommodate VMM env phases
// that do not have a direct UVM mapping. These include ~vmm_gen_cfg~, which
// delegates to the VMM env's ~gen_cfg~ phase, and ~vmm_report~, which delegates
// to the ~report~ phase. (UVM's report phase is a function, whereas VMM's
// report phase is a task.) These extra phases are transparent to UVM
// components.
//
// With VMM_UVM_INTEROP defined, VMM env phasing is controlled by
// the <uvi_uvm_vmm_env> as follows:
//
//|            UVM                  VMM (env)
//|             |                    
//|         vmm_gen_cfg ---------> gen_cfg
//|             |                    
//|           build     --------->  build
//|             |   
//|          connect
//|             |
//|     end_of_elaboration
//|             |
//|     start_of_simulation
//|             |
//|            run --------------> reset_dut
//|             |                  cfg_dut
//|             |                  start
//|             |                  wait_for_end
//|             |  stop
//|             |  request
//|             |   |
//|             |  stop----------> stop
//|             |   |              cleanup
//|             |   |
//|             X<--|   
//|             |    
//|             |
//|          extract
//|             |
//|           check
//|             |
//|           report 
//|             |
//|         vmm_report ----------> report
//|             |
//|             *
//
// Per the UVM use model, the user may customize <uvi_uvm_vmm_env>'s default test
// flow by extending and overriding any or all of the UVM phase callbacks.
// You can add functionality before or after calling super.<phase>, or you
// can completely replace the default implementation by not calling super.
// The new <uvi_uvm_vmm_env> subtype can then be selected on a type or
// instance basis via the ~uvm_factory~.
//
//------------------------------------------------------------------------------
`ifdef UVM_ON_TOP 
`include "uvm_macros.svh"

typedef class uvi_uvm_vmm_env_base;
`uvm_user_topdown_phase(vmm_gen_cfg, uvi_uvm_vmm_env_base, uvi_)
`uvm_user_task_phase(vmm_report, uvi_uvm_vmm_env_base, uvi_)


//------------------------------------------------------------------------------
//
// CLASS- uvi_uvm_vmm_env_base
//
//------------------------------------------------------------------------------
//
// The ~uvi_uvm_vmm_env_base~ class is used to "wrap" an existing ~vmm_env~ subtype
// so that it may be reused as an ordinary UVM component in an UVM-on-top
// environment. If an instance handle to the ~vmm_env~ subtype is not provided
// in the constructor, a new instance will be created and placed in the ~env~
// public property.
//
// When UVM runs through its phasing lineup, the ~uvi_uvm_vmm_env_base~ component
// delegates to the appropriate phase methods in the underlying ~env~ object.
// Thus, the VMM env phasing is sychronized with UVM phasing. Although the
// default mapping between UVM and VMM phases is deemed the best in most
// applications, users may choose to override the phase methods in a subtype
// to this class to implement a different phasing scheme.
//
//------------------------------------------------------------------------------

class uvi_uvm_vmm_env_base extends uvm_component;

  `uvm_component_utils(uvi_uvm_vmm_env_base)

  vmm_env env;

//AK  local static bit m_phases_inserted = insert_vmm_phases();

  // Variable- ok_to_stop
  //
  // When ~ok_to_stop~ is clear (default), the uvi_uvm_vmm_env's <stop> task will
  // wait for the VMM env's ~wait_for_end~ task to return before continuing.
  // This bit is automatically set with the underlying VMM env's ~wait_for_end~
  // task returns, which allows the <stop> <stop> task to call the VMM env's
  // ~stop~ and ~cleanup~ phases.
  // 
  // If ~ok_to_stop~ is set manually, other UVM components will be able to
  // terminate the run phase before the VMM env has returned from ~wait_for_end~.

  bit ok_to_stop = 0;


  // Variable- auto_stop_request
  //
  // When set, this bit enables calling an UVM stop_request after
  // the VMM env's wait_for_end task returns, thus ending UVM's run phase
  // coincident with VMM's wait_for_end. Default is 0.
  //
  // A wrapped VMM env is now a mere subcomponent of a larger-scale UVM
  // environment (that may incorporate multiple wrapped VMM envs).  A VMM envs'
  // end-of-test condition is no longer sufficient for determining the overall
  // end-of-test condition. Thus, the default value for ~auto_stop_request~
  // is 0. Parent components of the VMM env wrapper may choose to wait on the
  // posedge of <ok_to_stop> to indicate the VMM env has reached its end-of-test
  // condition.

  bit auto_stop_request = 0;


  // Function- new
  //
  // Creates the vmm_env proxy class with the given name, parent, and optional
  // vmm_env handle.  If the env handle is null, it is assumed that an extension
  // of this class will be responsible for creating and assigning the m_env
  // internal variable.
  
  function new (string name, uvm_component parent=null,
                vmm_env env=null);
  //   uvm_domain uvm_vmm_domain = new("uvm_vmm_domain");
     super.new(name,parent);
  //   set_domain(uvm_vmm_domain);
      set_domain(uvm_domain::get_uvm_domain());

    //AK if (vmm_report_ph == null) vmm_report_ph = new();
    //AK  uvm_top.insert_phase(vmm_report_ph, report_ph);

    this.env = env;
`ifndef UVM_NO_DEPRECATED
    enable_stop_interrupt = 1;
`endif

  endfunction
  
    function void connect_phase(uvm_phase phase);
      set_domain(uvm_domain::get_uvm_domain());
    endfunction

    // The component needs to override the set_phase_schedule to add
    // the new schedule.
    function void define_domain(uvm_domain domain);       
       uvm_domain common ;
       super.define_domain(domain) ;
       common = uvm_domain::get_common_domain();
      //Add the new phase if needed
      if (common.find(uvi_vmm_gen_cfg_phase::get()) == null)
        common.add(uvi_vmm_gen_cfg_phase::get(), 
		   .before_phase(uvm_build_phase::get()));
//uvm_build_phase::get())); //todo: should be build

      //Add the new phase if needed
      if (common.find(uvi_vmm_report_phase::get()) == null)
        common.add(uvi_vmm_report_phase::get(), 
		   .after_phase(uvm_report_phase::get()));
    endfunction

     
  // Function- vmm_gen_cfg
  //
  // Calls the underlying VMM env's gen_cfg phase.
  
   virtual function void vmm_gen_cfg_phase(uvm_phase phase);
    phase.raise_objection(this);
    if (this.env == null) begin
      uvm_report_fatal("NUVMMENV","The uvi_uvm_vmm_env requires a vmm_env instance");
      return;
    end
//AK    uvm_top.check_verbosity();
    env.gen_cfg();
    phase.drop_objection(this);
   endfunction // void
  
 
//  endclass

  // Function- insert_vmm_phases
  //
  // A static function that registers the ~vmm_gen_cfg~ phase callback with the UVM.
  // It is called as part of static initialization before any env or phasing
  // can begin. This allows the ~vmm_env~ to be created as an UVM component
  // in ~build~ phase.
  
/* -----\/----- EXCLUDED -----\/-----
  local static function bit insert_vmm_phases();
     if (vmm_gen_cfg_ph == null)
      vmm_gen_cfg_ph   = new;
//AK     uvm_top.insert_phase(vmm_gen_cfg_ph, null);
    return 1;
 endfunction 
 -----/\----- EXCLUDED -----/\----- */

  
  // Function- build
  //
  // Calls the underlying VMM env's build phase. Disables the underlying
  // env from manually calling into the UVM's phasing mechanism.
  
  virtual function void build_phase(uvm_phase phase);
     phase.raise_objection(this);
   env.build();
    phase.drop_objection(this);
  endfunction
  

  // Task- vmm_reset_dut
  //
  // Calls the underlying VMM env's reset_dut phase, provided this
  // phase was enabled in the <new> constructor.

  virtual task reset_phase(uvm_phase phase);
     phase.raise_objection(this);
    env.reset_dut();
    phase.drop_objection(this);
//AK    uvm_top.stop_request();
  endtask

  
  // Task- vmm_cfg_dut
  //
  // Calls the underlying VMM env's cfg_dut phase, provided this
  // phase was enabled in the <new> constructor.

  virtual task configure_phase(uvm_phase phase);
    phase.raise_objection(this);
    env.cfg_dut();
    phase.drop_objection(this);
//AK     uvm_top.stop_request();
  endtask

  // Task- main_phase
  //
  // Calls the underlying VMM env's start phase, provided this
  // phase was enabled in the <new> constructor.

  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    env.start();
    phase.drop_objection(this);
  endtask
  
  // Task- shutdown_phase
  //
  // Calls the underlying VMM env's start phase, provided this
  // phase was enabled in the <new> constructor.

  virtual task shutdown_phase(uvm_phase phase);
    phase.raise_objection(this);
    env.wait_for_end();
    phase.drop_objection(this);
  endtask  // Task: run

  // Task- post_shutdown_phase
  //
  // Calls the underlying VMM env's start phase, provided this
  // phase was enabled in the <new> constructor.

  virtual task post_shutdown_phase(uvm_phase phase);
   phase.raise_objection(this);
   env.stop();
   env.cleanup();
   phase.drop_objection(this);
  endtask  // Task: run

  //
  // Calls the underlying VMM env's reset_dut, cfg_dut, start, and
  // wait_for_end phases, returning when the env's end-of-test
  // condition has been reached. Extensions of this method may augment
  // or remove certain end-of-test conditions from the underlying env's
  // consensus object before calling ~super.run()~. When ~super.run()~
  // returns, extensions may choose to call ~uvm_top.stop_request()~ if
  // the underlying env is the only governor of end-of-test.
  // 
  // Extensions may completely override this base implementation by
  // not calling ~super.run()~. In such cases, all four VMM phases must
  // still be executed in the prescribed order.
  
/* -----\/----- EXCLUDED -----\/-----
  virtual task run();
    env.reset_dut();
    env.cfg_dut();
    env.start();
    env.wait_for_end();
    if (auto_stop_request)
      uvm_top.stop_request();
    ok_to_stop = 1;
  endtask
 -----/\----- EXCLUDED -----/\----- */
  
  
  // Task- stop
  //
  // If the ~run~ phase is being stopped, this task waits for the
  // underlying env's ~wait_for_end~ phase to return, then calls the
  // VMM env's stop and cleanup tasks. If the <ok_to_stop> variable
  // is set at the time ~stop~ is called, then ~stop~ will not wait
  // for ~wait_for_end~ to return. This allows UVM components to
  // control when the VMM env and its embedded xactors are stopped.
  
/* -----\/----- EXCLUDED -----\/-----
  virtual task stop(string ph_name); 
    if (ph_name == "run") begin
      if (!ok_to_stop)
        @ok_to_stop;
      env.stop();
      env.cleanup();
    end
  endtask
 -----/\----- EXCLUDED -----/\----- */
  

  // Task- vmm_report
  //
  // Calls the underlying VMM env's report method, then stops the
  // reportvmm phase. This phase is called after UVM's ~report~
  // phase has completed.
  
  virtual task vmm_report_phase(uvm_phase phase);
    phase.raise_objection(this);
    env.report();
    phase.drop_objection(this);
//AK    uvm_top.stop_request();
//AK todo     vmm_report_ph.wait_done();
  endtask

endclass


typedef class uvi_vmm_uvm_env;

//------------------------------------------------------------------------------
//
// CLASS- uvi_uvm_vmm_env
//
// Use this class to wrap (contain) an existing VMM env whose constructor does
// not have a ~name~ argument. See <uvi_uvm_vmm_env_base> for more information.
//
//------------------------------------------------------------------------------

class uvi_uvm_vmm_env #(type ENV=vmm_env) extends uvi_uvm_vmm_env_base;

   typedef uvi_uvm_vmm_env #(ENV) this_type;

  `uvm_component_utils(this_type)

  ENV env;

  // Function- new
  //
  // Creates a VMM env container component with the given ~name~ and ~parent~.
  // A new instance of an env of type ~ENV~ is created if one is not
  // provided in the ~env~ argument. The ~env~ will not be named.

  function new (string name,
                uvm_component parent=null,
                ENV env=null);
    uvi_vmm_uvm_env uvi_env;
    super.new(name,parent,env);
    if (env == null)
      env = new();
    if ($cast(uvi_env,env))
      uvi_env.disable_uvm = 1;
    this.env = env;
    super.env = env;
  endfunction

endclass


//------------------------------------------------------------------------------
//
// CLASS- uvi_uvm_vmm_env_named
//
// Use this class to wrap (contain) an existing VMM env whose constructor
// must have a ~name~ argument. See <uvi_uvm_vmm_env_base> for more information.
//
//------------------------------------------------------------------------------

class uvi_uvm_vmm_env_named #(type ENV=vmm_env) extends uvi_uvm_vmm_env_base;

   typedef uvi_uvm_vmm_env_named #(ENV) this_type;

  `uvm_component_utils(this_type)

  ENV env;

  // Function- new
  //
  // Creates a VMM env container component with the given ~name~ and ~parent~.
  // A new instance of an env of type ~ENV~ is created if one is not
  // provided in the ~env~ argument. The name given the new ~env~ is
  // the full name of this component. 

  function new (string name,
                uvm_component parent=null,
                ENV env=null);
    uvi_vmm_uvm_env uvi_env;
    super.new(name,parent,env);
    if (env == null)
      env = new({parent==null?"":{parent.get_full_name(),"."},name});
    if ($cast(uvi_env,env))
      uvi_env.disable_uvm = 1;
    this.env = env;
    super.env = env;
  endfunction

endclass


`endif
`ifndef NO_VMM_12
//------------------------------------------------------------------------------
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary work of
// Synopsys, Inc., and is fully protected under copyright and trade
// secret laws. You may not view, use, disclose, copy, or distribute this
// file or any information contained herein except pursuant to a valid
// written license from Synopsys.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Title: Implicitly-Phased VMM Components in UVM
//
//------------------------------------------------------------------------------
//
// Implicitly-phased VMM components must first be instantiated
// in an instance of a ~vmm_timeline~.
//
//|
//| class impl_ph_vmm_comps extends vmm_timeline;
//|    my_xactor xact;
//|    my_group  grp;
//|
//|    virtual function void build_ph();
//|       xact = new("xact", this);
//|       grp = new("grp", this);
//|    endfunction
//|
//| endclass
//|
//
// The <uvi_uvm_vmm_timeline> class is then used to wrap a VMM timeline
// for use as an uvm_component in an UVM environment.
// Any number of vmm_timeline's may be wrapped and reused using separate instances
// of the <uvi_uvm_vmm_timeline> class.
//
//|
//| class my_vmm_comps extends uvi_uvm_vmm_timeline;
//|
//|    impl_ph_vmm_comps vip;
//|
//|    virtual function build_phase(uvm_phase phase);
//|       vip = new("vip");
//|       set_vmm_timeline(vip);
//|       super.build_phase(phase);
//|    endfunction
//|
//| endclass
//|
//
// Explicitly-phased VMM components, such as the ~vmm_subenv~ and ~vmm_xactor~, do not
// require that they be wrapped in an instance of the <uvi_uvm_vmm_timeline> class;
// they can be instantiated and initialized
// directly by the parent component using their respective APIs.
// See <Explicitly-Phased VMM Components in UVM> for more details.
//
// Pre-defined Phase Alignments:
//
// The <uvi_uvm_vmm_timeline> component provides default implementations
// of the UVM phases that delegate to the underlying VMM timeline's phases. 
// The VMM phases are aligned with the UVM phases
// as follows:
//
//|            UVM                  VMM (timeline)
//|             |                    
//|           build -----------------> rtl_config
//|             |                      build
//|             |                      configure
//|             |   
//|          connect ----------------> connect
//|             |
//|     end_of_elaboration ----------> configure_test
//|             |
//|     start_of_simulation ---------> start_of_sim
//|             |
//|            run -----+
//|             |       |
//|             |   pre_reset
//|             |       |
//|             |     reset ---------> reset
//|             |       |
//|             |   post_reset
//|             |       |
//|             |  pre_configure ----> training
//|             |       |
//|             |    configure ------> configure_dut
//|             |       |
//|             |  post_configure
//|             |       |
//|             |    pre_main -------> start
//|             |       |
//|             |      main ---------> run
//|             |       |
//|             |    post_main
//|             |       |
//|             |   pre_shutdown
//|             |       |
//|             |     shutdown ------> shutdown
//|             |       |
//|             |   post_shutdown ---> cleanup
//|             |       |
//|             X<------+
//|             |    
//|             |
//|          extract
//|             |
//|           check
//|             |
//|           report ----------> report
//|             |
//|             *
//
// If user-defined phases are inserted in the VMM schedule before the ~start_of_sim~
// phase, they must be function phases and they must be explicitly executed
// by calling <vmm_timeline::run_function_phase()> in extensions of the
// the appropriate UVM phase method.
//
// Although the above mapping between UVM and VMM phases is deemed suitable for most
// applications, an integrator may choose to override the phase implementation
// in an extension of the <uvi_uvm_vmm_timeline> class
// to implement a different phase synchronization scheme.
    
//------------------------------------------------------------------------------

typedef class uvi_uvm_vmm_timeline;
typedef class uvi_vmm_uvm_timeline;


//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm_vmm_timeline
//
//------------------------------------------------------------------------------
//
// The ~uvi_uvm_vmm_timeline~ class is used to "wrap" an existing ~vmm_timeline~ subtype
// so that it may be reused as an ordinary UVM component in an UVM-on-top
// environment. If an instance handle to the ~vmm_timeline~ subtype is not provided
// in the constructor, a new instance will be created and placed in the ~timeline~
// public property.
//
// When UVM runs through its phase schedule, the ~uvi_uvm_vmm_timeline~ component
// delegates to the appropriate phase methods in the underlying ~timeline~ object.
// Thus, the VMM timeline phasing is synchronized with UVM phasing.
//
//------------------------------------------------------------------------------

class uvi_uvm_vmm_timeline extends uvm_component;

  `uvm_component_utils(uvi_uvm_vmm_timeline)

  local vmm_timeline m_timeline;

  // Function: new
  //
  // Creates an instance of this class with the given name and parent.

  function new (string name, uvm_component parent=null);   
     super.new(name,parent);
  endfunction
 
 
  //
  // Function: set_vmm_timeline
  //
  // Identify the VMM timeline instance that is phased by this UVM component
  // Must be called during the ~build_phase~ of this component,
  // before super.build_phase() is called.
  // Can only be called once: once a VMM timeline instance is specified,
  // it cannot be replaced.
  function void set_vmm_timeline(vmm_timeline timeline);
     if (timeline == null || m_timeline != null) return;
     m_timeline = timeline;
  endfunction


  //
  // Function: get_vmm_timeline
  //
  // Get the VMM timeline instance that is phased by this UVM component
  function vmm_timeline get_vmm_timeline();
     return m_timeline;
  endfunction


  // Function- build_phase
  //
  // Execute the underlying VMM timeline's ~rtl_config~, ~build~ and
  // ~connect~ phases.

  virtual function void build_phase(uvm_phase phase);
     phase.raise_objection(this);
     m_timeline.run_function_phase("rtl_config"); 
     m_timeline.run_function_phase("build"); 
     m_timeline.run_function_phase("configure"); 
     phase.drop_objection(this);
  endfunction
  

  // Function- connect_phase
  //
  // Execute the underlying VMM timeline's ~connect~ phase.

  virtual function void connect_phase(uvm_phase phase);
    phase.raise_objection(this);
    m_timeline.run_function_phase("connect");
    phase.drop_objection(this);
  endfunction
   

  // Function- end_of_elaboration_phase
  //
  // Execute the underlying VMM timeline's ~configure_test~ phase.
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    phase.raise_objection(this);
    m_timeline.run_function_phase("configure_test");
    phase.drop_objection(this);
  endfunction
  
  
  // Function- start_of_simulation_phase
  //
  // Execute the underlying VMM timeline's ~start_of_sim~ phase.
  
  virtual function void start_of_simulation_phase(uvm_phase phase);
    phase.raise_objection(this);
    m_timeline.run_function_phase("start_of_sim");
    phase.drop_objection(this);
  endfunction
  
  
  // Function- phase_started
  //
  // Executes the underlying VMM timeline's task phases corresponding to
  // the appropriate UVM task phase.
  // Because threads forked in VMM task phases are not implicitly killed
  // when the phase ends in VMM (which is different from UVM),
  // VMM phases are forked within a raise objection.
  
  virtual function void phase_started(uvm_phase phase);
     string name = phase.get_name();
      
     case (name)
      "reset":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("reset");
               ph.drop_objection(this);
            end
         join_none

      "pre_configure":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("training");
               ph.drop_objection(this);
            end
         join_none

      "configure":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("config_dut");
               ph.drop_objection(this);
            end
         join_none

      "pre_main":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("start");
               ph.drop_objection(this);
            end
         join_none

      "main":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("run");
               ph.drop_objection(this);
            end
         join_none

      "shutdown":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("shutdown");
               ph.drop_objection(this);
            end
         join_none

      "post_shutdown":
         fork
            begin
               uvm_phase ph = phase;
               ph.raise_objection(this);
               m_timeline.run_phase("cleanup");
               ph.drop_objection(this);
            end
         join_none
     endcase
  endfunction

   
  // Function- report_phase
  //
  // Execute the underlying VMM timeline's ~report~ phase.
  
  function void report_phase(uvm_phase phase);
     phase.raise_objection(this);
     m_timeline.run_function_phase("report");
     phase.drop_objection(this);
  endfunction
endclass // uvi_uvm_vmm_timeline
//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

`ifndef uvi_CONVERTER_SV
`define uvi_CONVERTER_SV

//
// Title: Transaction Descriptor Conversion Function
//
// Transaction descriptors must be converted from VMM (~vmm_data~)
// to UVM (<uvm_sequence_item>) or vice-versa.
// That conversion must be implemented as a static method in a conversion class.
// This class does not need to be an extension of any particular type,
// but shall follow the prototype exactly:
//
//| class vmm2uvm;
//|    static function uvm_type convert(vmm_type in,
//|                                     uvm_type to = null);
//|       if (to == null) to = new();
//|       to.data = in.data;
//|       return to;
//|    endfunction
//| endclass
//
// The implementation of the static convert() method does the actual conversion.
// The details of the conversion process are descriptor-specific.
// It may be implemented by explicitly assigning the relevant data members or
// by packing one descriptor into a byte stream and then unpacking the byte
// stream into the other descriptor.
//
// It may also be necessary to map the rand_mode state of data members and
// the constraint_mode state of constraint blocks
// from the original transaction descriptor to the equivalent
// data member or constraint block of the destination descriptor.
//
// The ~in~ argument is a required input argument.
// The ~to~ argument is optional and, if not null, provides a
// reference to the destination descriptor
// and shall be returned by the function.
// If the to argument is null,
// the convert() method allocates a new OUT-type destination object and returns that.
//
// In the UVM-to-VMM case, the convert() method takes
// a <uvm_sequence_item> extension as the ~in~ argument
// and returns the corresponding ~vmm_data~ extension.
// In the VMM-to-UVM case, the ~vmm_data~ extension is the ~in~ argument
// and the method returns a <uvm_sequence_item> extension.
                                          

//
// Section: TLM 2.0 Protocol Phase Conversion Functions
//
// Adapting a VMM TLM 2.0 nonblocking socket with the corresponding
// UVM TLM 2.0 nonblocking socket
// requires that not only the transaction descriptors be converted from VMM
// (~vmm_tlm_generic_payload~) to UVM (<uvm_tlm_generic_payload>),
// but that the VMM protocol phase (~vmm_tlm::phase_e~)
// be converted to the corresponding UVM protocol phase (<uvm_tlm_phase_e>) 
// and vice-versa.
//
// The protocol phase conversion function must be implemented
// as an additional static function in the conversion policy class.
//
// For the VMM-to-UVM direction, it shall follow this prototype
// exactly:
//
//| class vmm2uvm;
//|    static function uvm_type convert(vmm_type in,
//|                                     uvm_type to = null);
//|       ...
//|    endfunction
//|
//|   static function uvm_phase convert_phase(vmm_phase ph);
//|      case (ph)
//|        VMM_PH: return UVM_PH;
//|        ...
//|      endcase
//|   endfunction
//| endclass
//
// For the UVM-to-VMM direction, it shall follow this prototype
// exactly:
//
//| class uvm2vmm;
//|    static function vmm_type convert(uvm_type in,
//|                                     vmm_type to = null);
//|       ...
//|    endfunction
//|
//|   static function vmm_phase convert_phase(uvm_phase ph);
//|      case (ph)
//|        UVM_PH: return VMM_PH;
//|        ...
//|      endcase
//|   endfunction
//| endclass
//
// If the pre-defined TLM 2.0 Base Protocol is used, the pre-defined
// phase conversion functions can be inherited by extending the
// transaction conversion class from the <uvi_vmm2uvm_tlm2_converter> and
// <uvi_uvm2vmm_tlm2_converter> classes.
//

//------------------------------------------------------------------------------
//
// CLASS: uvi_converter
//
// This class is a default policy class that is used to implement
// a default conversion function from a VMM transaction descriptor (based on ~vmm_data~)
// to a UVM transaction descriptor (based on <uvm_sequence_item>),
// or vice-versa.
//
// It is used as the default conversion policy in the UVM/VMM adapters.
//------------------------------------------------------------------------------

class uvi_converter #(type IN=int, OUT=int);

  // Parameter: IN
  //
  // The input class type to convert from.
  
  // Parameter: OUT
  //
  // The output class type to convert to.

  // Function: convert
  //
  // Always returns ~null~.
  //

  static function OUT convert(IN in, OUT to=null);
     return null;
  endfunction

endclass

`endif // uvi_CONVERTER_SV
//------------------------------------------------------------------------------
// Copyright 2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Title: Pre-Defined TLM 2.0 Conversion Policy Classes
//
//------------------------------------------------------------------------------
//
// The following classes implement <Transaction Descriptor Conversion Function>s
// for the pre-defined TLM 2.0 generic payload (<uvm_tlm_generic_payload>) and
// Base Protocol (<uvm_tlm_phase_e>).

//------------------------------------------------------------------------------
//
// CLASS- uvi_ok_to_create_in_connect
//
// Internal class used to allow creation in connect phase.
//
//------------------------------------------------------------------------------

class uvi_ok_to_create_in_connect extends uvm_report_catcher;
   virtual function action_e catch();
      if(get_id() == "ILLCRT" && get_severity() == UVM_FATAL) begin
         return CAUGHT;
      end
      return THROW;
   endfunction
endclass

//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm2vmm_tlm2_converter
//
//------------------------------------------------------------------------------
//
// This class implements a conversion policy class from a
// <uvm_tlm_generic_payload> to a ~vmm_tlm_generic_payload~ transaction descriptor
// and from <uvm_tlm_phase_e> to ~vmm_tlm::phase_e~ protocol phases.
// It is used as the default conversion policy for the TLM 2.0 adaptors.
//
//------------------------------------------------------------------------------

class uvi_uvm2vmm_tlm2_converter;
   
   // Function: convert
   //

   static function vmm_tlm_generic_payload convert(uvm_tlm_generic_payload in,
                                                   vmm_tlm_generic_payload to = null);
      if (in == null) return null;
      if (to == null) to = new();

      to.m_address = in.m_address;
      to.m_command = vmm_tlm_generic_payload::tlm_command'(in.m_command);
      to.m_length = in.m_length;
      to.m_response_status = vmm_tlm_generic_payload::tlm_response_status'(in.m_response_status);
      to.m_dmi_allowed = in.m_dmi;
      to.m_byte_enable_length = in.m_byte_enable_length;
      to.m_streaming_width = in.m_streaming_width;
      
      to.m_data = new [in.m_data.size()];
      foreach (in.m_data[i]) to.m_data[i] = in.m_data[i];

      to.m_byte_enable = new [in.m_byte_enable.size()];
      foreach (in.m_byte_enable[i]) to.m_byte_enable[i] = in.m_byte_enable[i];

      return to;
   endfunction


   // Function: convert_phase

   static function vmm_tlm::phase_e convert_phase(uvm_tlm_phase_e ph);
      case(ph)
       BEGIN_REQ : return vmm_tlm::BEGIN_REQ;
       END_REQ   : return vmm_tlm::END_REQ;
       BEGIN_RESP: return vmm_tlm::BEGIN_RESP;
       END_RESP  : return vmm_tlm::END_RESP;
      endcase
   endfunction
endclass


//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm2uvm_tlm2_converter
//
//------------------------------------------------------------------------------
//
// This class implements a conversion policy class from a
// ~vmm_tlm_generic_payload~ to a <uvm_tlm_generic_payload> transaction descriptor
// and from ~vmm_tlm::phase_e~ to <uvm_tlm_phase_e> protocol phases.
// It is used as the default conversion policy for the TLM 2.0 adaptors.
//
//------------------------------------------------------------------------------


class uvi_vmm2uvm_tlm2_converter;
   
   // Function: convert

   static function uvm_tlm_generic_payload convert(vmm_tlm_generic_payload in,
                                                   uvm_tlm_generic_payload to = null);
      if (in == null) return null;
      if (to == null) to = new;

      to.m_address = in.m_address;
      to.m_command = uvm_tlm_command_e'(in.m_command);
      to.m_length = in.m_length;
      to.m_response_status = uvm_tlm_response_status_e'(in.m_response_status);
      to.m_dmi = in.m_dmi_allowed;
      to.m_byte_enable_length = in.m_byte_enable_length;
      to.m_streaming_width = in.m_streaming_width;
      
      to.m_data = new [in.m_data.size];
      foreach (in.m_data[i]) to.m_data[i] = in.m_data[i];

      to.m_byte_enable = new [in.m_byte_enable.size()];
      foreach (in.m_byte_enable[i]) to.m_byte_enable[i] = in.m_byte_enable[i];

      return to;
   endfunction


   // Function: convert_phase

   static function uvm_tlm_phase_e convert_phase(vmm_tlm::phase_e ph);
      case (ph)
       vmm_tlm::BEGIN_REQ : return BEGIN_REQ;
       vmm_tlm::END_REQ   : return END_REQ;
       vmm_tlm::BEGIN_RESP: return BEGIN_RESP;
       vmm_tlm::END_RESP  : return END_RESP;
      endcase
   endfunction

endclass
//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//
// Title: UVM Analysis Port Adapters
//
// When connecting a UVM analysis port to a VMM interface,
// the correct adapter must be used according to the type of VMM interface.
//
// VMM analysis port   - Use the <uvi_uvm_ap2vmm_ap> adapter.
// VMM notification    - Use the <uvi_uvm_ap2vmm_notify> adapter.
// VMM channel         - Use the <uvi_uvm_ap2vmm_channel> adapter.
//

//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm_ap2vmm_ap
//
// Adapter for connecting a UVM analysis port to a VMM analysis export.
//
// The adapter must be configured using the following
// class parameters:
//
// UVM_TR    - Type of the UVM-side transaction. Defaults to <int>.
// VMM_TR    - Type of the VMM-side transaction. Defaults to <int>.
// UVM2VMM   - UVM-to-VMM conversion policy class. Defaults to <uvi_converter#(UVM_TR,VMM_TR)>.
//
// Although this adapter is a <uvm_component>, it cannot be instantiated directly.
// The UVM analysis port is connected to the corresponding VMM analysis export
// using the <do_connect()> method.
// That method instantiates the adapter internally.
//
//| class my_env extends uvm_env;
//|    uvm_vip mon;
//|    vmm_sb  sb;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon", this);
//|       sb  = new("sb", this);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       uvi_uvm2vmm_ap::do_connect(mon.ap, sb.a_xp);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_uvm_ap2vmm_ap #(type UVM_TR = int,
                          type VMM_TR = int,
                          type UVM2VMM = uvi_converter#(UVM_TR,VMM_TR))
   extends uvm_component;

   typedef uvi_uvm_ap2vmm_ap#(UVM_TR, VMM_TR, UVM2VMM) this_type;
   // UVM import which is used to connect to user's UVM port.
   local uvm_analysis_imp #(UVM_TR, this_type) uvm_targt_analysis_socket;

   // VMM port which is used to connect to user's VMM export.
   local vmm_tlm_analysis_port#(this_type, VMM_TR) vmm_init_analysis_socket;

   // VMM log required to for messages from adapter
   vmm_log log;

   // Function- new
   //
   // Creates a new interop class with the given 3 optional arguments
   // Constructor is local to prevent direct instantiation of this class.

   local function new(string name="", uvm_component parent = null);
      super.new(name,parent);
      log = new($psprintf("%s_log",name), get_full_name());
      uvm_targt_analysis_socket  = new ("uvm_targt_analysis_socket" , this);
      vmm_init_analysis_socket = new(this, "vmm_init_analysis_socket");
   endfunction

   // Function: do_connect
   //
   // Connect the specified UVM analysis port to the specified VMM analysis export.
   
  static function void do_connect(uvm_analysis_port#(UVM_TR) ap,
                                  vmm_tlm_analysis_export_base#(VMM_TR) xp);
      this_type m_adapter;
      static int num_inst = 0;
      uvi_ok_to_create_in_connect cb = new();                          
      uvm_report_cb::add(null,cb,UVM_PREPEND);

      m_adapter = new($psprintf("UVM2VMM_ANALYSIS%d",num_inst));                      
      num_inst = num_inst + 1;

     if(ap == null)
     begin
        `ifdef UVM_ON_TOP
           //`uvm_error("Connection In Progress: ", "First argument to do_connect function is null");
           $display("Connection In Progress: , First argument to do_connect function is null");
        `else
           `vmm_error(m_adapter.log,"Connection In Progress: First argument to do_connect function is null");
        `endif   
     end
     if(xp == null)
     begin
        `ifdef UVM_ON_TOP
           //`uvm_error("Connection In Progress: ", "Second argument to do_connect function is null");
           $display("Connection In Progress: , Second argument to do_connect function is null");
        `else
           `vmm_error(m_adapter.log,"Connection In Progress: Second argument to do_connect function is null");
        `endif   
     end
     
     ap.connect(m_adapter.uvm_targt_analysis_socket);
     m_adapter.vmm_init_analysis_socket.tlm_bind(xp);
     uvm_report_cb::delete(null, cb);
  endfunction

   // Function- write
   //
   // Forward the write() call to VMM

  function void write(UVM_TR item);
     VMM_TR vmm_item;

     vmm_item = UVM2VMM::convert(item, vmm_item);
     vmm_init_analysis_socket.write(vmm_item);
  endfunction
endclass  


//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm_ap2vmm_notify
//
//------------------------------------------------------------------------------
//
// The uvi_uvm_ap2vmm_notify adapter receives UVM data from its <analysis_export>,
// converts it to VMM, then indicates the configured event notification,
// passing the converted data as vmm_data-based status. VMM components that have
// registered a callback for the notification will received the converted data
//
// UVM_TR    - Type of the UVM-side transaction.
// VMM_TR    - Type of the VMM-side transaction.
// UVM2VMM   - UVM-to-VMM conversion policy class.
//
// To connect a UVM analysis port to a VMM notification,
// instantiate the adapter, specifying the instance of the <vmm_notify>
// and notification ID that is indicated whenever a transaction is posted
// on the UVM analysis port. Then connect the analysis export in the adapter
// to the desired analysis port.
//
//| class my_env extends uvm_env;
//|    uvm_vip mon;
//|    vmm_sb  sb;
//|    uvi_uvm_ap2vmm_notify#(uvm_tr, vmm_tr, uvm2vmm_tr) ap2ntfy;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon", this);
//|       sb  = new("sb", this);
//|       ap2ntfy = new("ap2ntfy", this, sb.notify, vmm_sb::OBSERVED);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       mon.ap.connect(ap2ntfy.analysis_export);
//|    endfunction
//|
//| endclass
//
// See also the <uvi_analysis2notify example>.
//
//-----------------------------------------------------------------------------

class uvi_uvm_ap2vmm_notify#(type UVM_TR=int,
                             type VMM_TR=int,
                             type UVM2VMM=int) extends uvm_component;

  typedef uvi_uvm_ap2vmm_notify #(UVM_TR, VMM_TR, UVM2VMM) this_type;

  `uvm_component_param_utils(this_type)


  // Port: analysis_export
  //
  // The adapter receives UVM transactions via this analysis export.
  
  uvm_analysis_imp #(UVM_TR,this_type) analysis_export;


  // Variable: notify
  //
  // The notify object that this adapter uses to indicate the <RECEIVED>
  // event notification.

  vmm_notify notify;


  // Variable: RECEIVED
  //
  // The notification id that this adapter indicates upon receipt of
  // UVM data from its <analysis_export>. 

  int RECEIVED;



  // instance of VMM log to capture messages. This is only constructed 
  // if notify is null.
  local vmm_log log;

  // Function: new
  //
  // Creates a new analysis-to-notify adapter with the given ~name~ and
  // optional ~parent~; the ~notify~ and ~notification_id~ together
  // specify the notification event that this adapter will indicate
  // upon receipt of a transaction on its <analysis_export>.
  //
  // If the ~notify~ handle is not supplied or null, the adapter will
  // create one and assign it to the <notify> property. If the 
  // ~notification_id~ is not provided, the adapter will configure a
  // ONE_SHOT notification and assign it to the <RECEIVED> property. 

  function new(string name, uvm_component parent=null,
               vmm_notify notify=null, int notification_id=-1);
    // All instances will be children of uvm_top, so give each a unique name
    super.new(name,parent);
    
    analysis_export = new("analysis_export",this);
    this.notify        = notify;
    if (notify == null) begin
      log              = new("vmm_log","vmm_notify2analysis_adapter_log");
      notify           = new(log);
    end
    if (notification_id == -1)
      notification_id  = notify.configure(-1,vmm_notify::ONE_SHOT);
    else
      if (notify.is_configured(notification_id) != vmm_notify::ONE_SHOT)
        begin
`ifdef UVM_ON_TOP
          uvm_report_fatal("Bad Notification ID",
                           $psprintf({"Notification id %0d not configured, ",
                                      "or not configured as ONE_SHOT"}, 
                                     notification_id));
`endif
`ifdef VMM_ON_TOP
          `vmm_fatal(log,
                     $psprintf({"Notification id %0d not configured, ",
                                "or not configured as ONE_SHOT"}, 
                               notification_id));
`endif
        end
    RECEIVED  = notification_id;
  endfunction


  // Function- write
  //
  // The write method, called via the <analysis_export>, converts
  // an incoming UVM transaction to its VMM counterpart, then indicates
  // the configured <RECEIVE> notification, passing the converted data
  // as status.

  virtual function void write(UVM_TR t);
    VMM_TR vmm_out;
    UVM_TR uvm_in;
    if (t == null)
      return;

    assert($cast(uvm_in,t));
    vmm_out  = UVM2VMM::convert(uvm_in);
    notify.indicate(RECEIVED,vmm_out);
  endfunction

endclass


//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm_ap2vmm_channel
//
//------------------------------------------------------------------------------
//
// The uvi_uvm_ap2vmm_channel adapter is used to connect a UVM component with an
// analysis port to a VMM component via a vmm_channel.
//
// Connect any UVM component with an analysis
// port to this adapter's <analysis_export>. The adapter will convert all
// incoming UVM transactions to a VMM transaction and ~sneak~ it to the vmm_channel.
// The VMM channel must be drained to avoid data accumulation.
//
// UVM_TR    - Type of the UVM-side transaction.
// VMM_TR    - Type of the VMM-side transaction.
// UVM2VMM   - UVM-to-VMM conversion policy class.
//
// To connect a UVM analysis port to a VMM channel,
// instantiate the adapter, specifying the instance of the <vmm_channel>
// to connect to.
// Then connect the analysis export in the adapter
// to the desired analysis port.
//
//| class my_env extends uvm_env;
//|    uvm_vip mon;
//|    vmm_sb  sb;
//|    uvi_uvm_ap2vmm_channel#(uvm_tr, vmm_tr, uvm2vmm_tr) ap2chan;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon", this);
//|       sb  = new("sb", this);
//|       ap2chan = new("ap2ntfy", this, sb.obs_chan);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       mon.ap.connect(ap2chan.analysis_export);
//|    endfunction
//|
//| endclass
//
// See also the <uvi_analysis_channel example>.
//
//------------------------------------------------------------------------------


class uvi_uvm_ap2vmm_channel#(type UVM_TR=int,
                              type VMM_TR=int,
                              type UVM2VMM=int)
                         extends uvm_component;

  typedef uvi_uvm_ap2vmm_channel #(UVM_TR, VMM_TR, UVM2VMM) this_type;

  // Port: analysis_export
  //
  // The adapter may receive UVM transactions via this analysis export.
  // The 

  uvm_analysis_imp #(UVM_TR, this_type) analysis_export;


  // Function: new
  //
  // Creates a new instance of this adapter with the given ~name~ and
  // optional ~parent~; the optional ~chan~ argument provides the
  // handle to the vmm_channel being adapted. If no channel is given,
  // the adapter will create one.

  function new (string name, uvm_component parent=null,
                vmm_channel_typed #(VMM_TR) chan=null);
    super.new(name, parent);
    if (chan == null)
      chan = new("VMM Analysis Channel",name);
    this.chan = chan;
    analysis_export = new("analysis_export",this);
  endfunction


  // Function- write
  //
  // The write method, called via the <analysis_export>, converts
  // an incoming UVM transaction to its VMM counterpart, then sneaks
  // the converted transaction to the vmm_channel.

  function void write(UVM_TR uvm_t);
    VMM_TR vmm_t;
    if (uvm_t == null)
     return;
    vmm_t = UVM2VMM::convert(uvm_t);
    chan.sneak(vmm_t);
  endfunction


   // Variable: chan
   //
   // The vmm_channel instance being adapted; if not supplied in
   // its <new> constructor, the adapter will create one.
   //
   // Incoming transactions from the <analysis_export> will be converted
   // to VMM and ~sneaked~ to this channel.
   // The channel must be sunk to avoid data accumulation.

   vmm_channel_typed #(VMM_TR) chan;

endclass

//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Title: UVM Sequencer/TLM1 to VMM Channel Adapter
//
//------------------------------------------------------------------------------
//
// The <uvi_uvm_tlm2channel> adapter is used to connect various types of
// UVM TLM1 producers (including sequencers)
// to various VMM channel-based consumers.
//
// UVM TLM1 and VMM channels can implement many different response-delivery
// models:
//
// - does not return a response
//
// - embeds a response in the original request transaction, which is available
//   to a requester that holds a handle to the original request.
//
// - returns a response in a separate channel/port
//
// The adapter can accommodate UVM TLM1 producers and VMM channel-based consumers
// that have similar responses characteristics.
// For example, it is possible to connect a UVM TLM1 producer that expects a
// reponse via a separate port with a VMM channel-based consumer that annotates
// the response in the original request.
// However, it is not possible to connect a UVM producer that expects a response
// with a VMM consumer that does not provide one or provides multiple responses
// for the same request.
//
// Communication is established by connecting the adapter to the
// UVM producer using the appropriate ports and exports on the adapter
// and to the channel(s) of the VMM consumer.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm_tlm2channel
//
// Adapter component between a UVM TLM1 producer (e.g. a sequencer)
// and a VMM channel-based consumer.
//
// To use this adapter, the integrator instantiates an UVM producer, a VMM
// consumer, and an adapter whose parameter values correspond
// to the UVM and VMM data types used by the producer and consumer and the
// converter types used to translate in one or both directions.
//
// The adapter has the following
// parameters:
//
// UVM_REQ     - Type of the UVM transaction request descriptor class (required)
// VMM_REQ     - Type of the VMM transaction request descriptor class (required)
// UVM2VMM_REQ - Conversion policy class from UVM to VMM transaction request (required)
// VMM_RSP     - Type of the VMM transaction response descriptor class. Defaults to VMM_REQ.
// UVM_RSP     - Type of the UVM transaction response descriptor class. Defaults to UVM_REQ.
// VMM2UVM_RSP - Conversion policy class from VMM to UVM transaction response (optional)
//
// The integrator may use the default vmm_channels created by the VMM consumer
// or adapter,
// or explicitly instantiate a request vmm_channel and a
// response vmm_channel, if the VMM consumer uses one, and specify them
// to the adapter constructor and consumer constructors.
//
// Example:
//
//|
//| class uvm2vmm_tr;
//|    static function vmm_tr convert(uvm_tr in, vmm_tr to = null);
//|       ...
//|    endfunction
//| endclass
//|
//| class vmm2uvm_tr;
//|    static function uvm_tr convert(vmm_tr in, uvm_tr to = null);
//|       ...
//|    endfunction
//| endclass
//|
//| class my_env extends uvm_env;
//|   uvm_sequencer#(uvm_tr) sqr;
//|   vmm_driver             drv;
//|   uvi_uvm_tlm2channel#(.UVM_REQ(uvm_tr), .VMM_REQ(vmm_tr),
//|                        .UVM2VMM_REQ(uvm2vmm_tr), .VMM2UVM_RSP(vmm2uvm_tr))
//|                          sqr2drv;
//|   
//|   function void build_phase(uvm_phase phase);
//|      super.build_phase(phase);
//|
//|      sqr = new("sqr", this);
//|      drv = new("drv");
//|      sqr2drv = new("sqr2drv", this, drv.in_chan);
//|   endfunction
//|
//|   function void connect_phase(uvm_phase phase);
//|      super.connect_phase(phase);
//|      sqr2drv.seq_item_port.connect(sqr.seq_item_export);
//|   endfunction
//|endclass
//|
//
// Integrators of VMM-on-top environments need to instantiate the UVM consumer
// and adapter via an UVM container, or wrapper <uvm_component>. This wrapper
// component serves to provide the connect method needed to bind the UVM ports
// and exports.
//
// See also <uvi_uvm_tlm2channel example> and <uvi_uvm_tlm2channel seq_item example>.
//
//------------------------------------------------------------------------------

class uvi_uvm_tlm2channel #(type UVM_REQ     = int,
                            type VMM_REQ     = int,
                            type UVM2VMM_REQ = int,
                            type VMM_RSP     = VMM_REQ,
                            type UVM_RSP     = UVM_REQ,
                            type VMM2UVM_RSP = uvi_converter #(VMM_RSP,UVM_RSP))
   extends uvm_component;

   typedef uvi_uvm_tlm2channel #(UVM_REQ, VMM_REQ, UVM2VMM_REQ,
                             VMM_RSP, UVM_RSP, VMM2UVM_RSP)
                              this_type;

   // Function: new
   //
   // Creates a new instance of the adapter.
   //
   // name     - specifies the instance name. Default is "uvi_uvm_tlm2channel".
   //
   // parent   - specifies the parent uvm_component
   //
   // req_chan - the request vmm_channel instance. If not specified,
   //            a new instance is created and assigned to <req_chan>.
   //
   // req_chan - the request vmm_channel instance. If not specified,
   //            the VMM consumer annotates the response directly in the request.
   //            If a response channel is used by the adapted VMM consumer,
   //            it must be specified or later
   //            assigned directly to the <req_chan> variable before
   //            end_of_elaboration.
   //
   // wait_for_req_ended - Initial value of the <wait_for_req_ended> variable.

   function new (string name="uvi_uvm_tlm2channel",
                 uvm_component parent=null,
                 vmm_channel_typed #(VMM_REQ) req_chan=null,
                 vmm_channel_typed #(VMM_RSP) rsp_chan=null,
                 bit wait_for_req_ended=0);
      super.new(name,parent);

      if (parent == null) begin
         `uvm_fatal("NOUVMWRP", {"The ", $typename(this),
                                 " adaptor must be encapsulated with the adapted UVM producer in a UVM wrapper component"})
      end

      // adapter may be driven by UVM producer via any of these exports
      put_export                = new("put_export",this);
      master_export             = new("master_export",this);
      blocking_transport_export = new("blocking_transport_export",this);

      // adapter may drive the UVM producer via any of these ports.
      seq_item_port             = new("seq_item_port",this,0);
      blocking_get_peek_port    = new("blocking_get_peek_port",this,0);
      blocking_put_port         = new("blocking_put_port",this,0);
      blocking_slave_port       = new("blocking_slave_port",this,0);
      request_ap                = new("request_ap",this);
      response_ap               = new("response_ap",this);

      if (req_chan == null)
        req_chan = new("TLM-to-Channel Adapter Request Channel",name);
      this.req_chan = req_chan;
      this.rsp_chan = rsp_chan;
      this.wait_for_req_ended = wait_for_req_ended;
   endfunction


   //
   // Group: UVM Producer
   //
   // Only one UVM producer may be connected to the adapter,
   // using the appropriate ports for the producer's response model.
   //


   // Port: seq_item_port
   //
   // This bidirectional port is used to connect to an ~uvm_sequencer~ or any
   // other component providing an ~uvm_seq_item_export~.

   uvm_seq_item_pull_port #(UVM_REQ,UVM_RSP) seq_item_port;


   // Port: put_export
   //
   // This export is used to receive transactions from an UVM producer
   // that utilizes a blocking or non-blocking ~put~ interface.
   // No response is provided back to the UVM producer.
   uvm_put_imp #(UVM_REQ,this_type) put_export;


   // Port: master_export
   //
   // This bidirectional export is used to receive requests from and deliver
   // responses to an UVM producer that utilizes a blocking or non-blocking
   // ~master~ interface.
   uvm_master_imp #(UVM_REQ,UVM_RSP,this_type) master_export;


   // Port: blocking_transport_export
   //
   // This bidirectional export is used to receive requests from and deliver
   // responses to an UVM producer that utilizes a blocking transport interface.
   uvm_blocking_transport_imp #(UVM_REQ,UVM_RSP,this_type) blocking_transport_export;


   // Port: blocking_get_peek_port
   //
   // This unidirectional port is used to retrieve requests from a passive
   // UVM producer with a blocking get_peek export.
   // No response is provided back to the UVM producer.
   uvm_blocking_get_peek_port #(UVM_REQ) blocking_get_peek_port;


   task blocking_get_peek_process();
   endtask


   // Port: blocking_put_port
   //
   // This port is used to deliver responses to an UVM producer that
   // expects responses from a blocking put interface.
   uvm_blocking_put_port #(UVM_REQ) blocking_put_port;



   // Port: blocking_slave_port
   //
   // This bidirectional port is used to request transactions from and deliver
   // responses to a passive UVM producer utilizing a blocking slave interface.
   uvm_blocking_slave_port #(UVM_REQ,UVM_RSP) blocking_slave_port;


   // Port: request_ap
   //
   // All transaction requests received from any of the interface ports and
   // exports in this adapter are broadcast out this analysis port to any UVM
   // subscribers. 
   uvm_analysis_port #(UVM_REQ) request_ap;


   // Port: response_ap
   //
   // All transaction responses received from the VMM consumer
   // broadcast out this analysis port to any UVM
   // subscribers.  UVM producers that expect responses from an analysis
   // export may be connected to this port.
   uvm_analysis_port #(UVM_RSP) response_ap;


   //
   // Group: VMM Consumer
   //

   // Variable: req_chan
   //
   // Handle to the request vmm_channel #(VMM) instance being adapted.

   vmm_channel_typed #(VMM_REQ) req_chan;


   // Variable: rsp_chan
   //
   // Handle to the response vmm_channel #(VMM) instance being adapted.
   // The adapter uses a response channel regardless of whether the
   // VMM consumer uses it directly. This keeps the request and response
   // paths on the TLM side separate.

   vmm_channel_typed #(VMM_RSP) rsp_chan;


   // Variable: wait_for_req_ended
   //
   // Nonblocking VMM consumer completion model.
   // When the VMM consumer does not use a separate response channel, this
   // bit specifies whether the response, which is annotated into the
   // original request, is available after a ~put~ in the request
   // channel returns (~wait_for_req_ended=0~) or after the original request's
   // ENDED status is indicated (~wait_for_req_ended=1~). The latter case
   // enables interconnecting with pipelined VMM consumers at the cost
   // of two additional processes for each outstanding request transaction.
   //
   // This variable can be specified in a <new> constructor argument, or set
   // via a uvm_config_db#(bit)::set(..., "wait_for_req_ended", value) call targeting this
   // component.

   protected bit wait_for_req_ended = 0;


   // Indicates if the VMM consumer annotates the response in the request
   // or provides a separate response channel.

   protected bit m_req_is_rsp = 0;


   // Function- build
   //
   // Called as part of a predefined test flow, this function will retrieve
   // the configuration setting for the <wait_for_req_ended> flag.

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      void'(uvm_config_db#(bit)::get(this, "", "wait_for_req_ended",
                                     this.wait_for_req_ended));
   endfunction


   // Function- end_of_elaboration
   //
   // Called as part of a predefined test flow, this function will check that
   // this component's <req_chan> variable has been configured with a non-null
   // instance of a vmm_channel #(VMM).

   virtual function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
     if (this.req_chan == null)
       `uvm_fatal("Connection Error",
          "vmm_uvm_tlm2channel adapter requires a request vmm_channel");
      if (this.rsp_chan == null) begin
         this.rsp_chan = new("TLM-to-Channel Adapter Response Channel","rsp_chan");
         m_req_is_rsp = 1;
      end
   endfunction




   // Task- run
   //
   // Called as part of a predefined test flow, the run task forks a
   // process for getting requests from the <seq_item_port> and sending
   // them to the <req_chan> vmm_channel. If configured, it will also fork
   // an independent process for getting responses from the separate <rsp_chan>
   // vmm_channel and putting them back out the <seq_item_port>.

   virtual task run_phase(uvm_phase phase);

     bit port_is_connected = 0;

     super.run_phase(phase);

     if (this.seq_item_port.size()) begin
       //this.producer_port = seq_item_port;
       this.is_seq_item_port = 1;
       this.is_bidir_port = 1;
       port_is_connected = 1;
     end
     else if (blocking_get_peek_port.size()) begin
       this.producer_port = blocking_get_peek_port;
       port_is_connected = 1;
     end
     else if (blocking_slave_port.size()) begin
       this.producer_port = blocking_slave_port;
       this.is_bidir_port = 1;
       port_is_connected = 1;
     end

     if (port_is_connected) begin
       fork
         this.get_requests();
       join_none

       if (!this.is_bidir_port && !this.blocking_put_port.size() == 0 &&
           this.response_ap.size() == 0)
         this.rsp_chan.sink();
       else
         fork
           this.put_responses();
         join_none
     end

   endtask


   // Task- wait_for_ended
   //
   // Used to support VMM non-blocking completion models that indicate
   // and return response status via each transaction's ENDED notification.
   // For each transaction outstanding, this task is forked to wait for
   // the ENDED status. When that happens, the response is converted
   // and sent into the <rsp_chan>.
   //
   // The <wait_for_req_ended> bit, set in the constructor, determines
   // whether this task is used.

   virtual task wait_for_ended(VMM_REQ v_req);
     string data_id,scen_id;
     VMM_RSP v_rsp;
     assert($cast(v_rsp,v_req));
     fork
       begin : wait_for_ended_process
         v_req.notify.wait_for(vmm_data::ENDED);
         this.rsp_chan.sneak(v_rsp);
       end
       begin
         #this.request_timeout;
         data_id.itoa(v_req.data_id);
         scen_id.itoa(v_req.scenario_id);
         uvm_report_warning("Request Timed Out",
           {"The request with data_id=",data_id,
            " and scenario_id=",scen_id," timeout out."});
         disable wait_for_ended_process;
       end
     join
   endtask


   // Task- get_requests
   //
   // This task continually gets request transactions from the connected
   // sequencer, converts them to an equivalent VMM transaction, and puts
   // to the underlying <req_chan> vmm_channel.
   // 
   // If <wait_for_req_ended> is set and the <req_chan>'s full-level is 1, and
   // no <rsp_chan> is being used, it is assumed the put to <req_chan>
   // will not return until the transaction has been executed and the
   // response contained within the original request descriptor. In
   // this case, the modified VMM request is converted back to the
   // original UVM request object, which is then sent as a response to
   // both the <seq_item_port> and <response_ap> ports.
   //
   // This task is forked as a process from the <run> task.

   virtual task get_requests();
     UVM_REQ o_req;
     forever begin
       if (this.is_seq_item_port) begin
         seq_item_port.peek(o_req);
         this.put(o_req);
         seq_item_port.get(o_req); // pop
       end
       else begin
         producer_port.peek(o_req);
         this.put(o_req);
         producer_port.get(o_req); // pop
       end
     end
   endtask


   // Task- put_responses
   //
   // This task handles getting responses from the <rsp_chan> vmm_channel and
   // putting them to the appropriate UVM response port. The converters will handle
   // the transfer of (data_id,scenario_id) to (transaction_id/sequence_id)
   // information so responses can be matched to their originating requests.
   //
   // This task is forked as a process from the <run> task.

   virtual task put_responses();

     VMM_RSP v_rsp;
     UVM_RSP o_rsp;

     assert(this.rsp_chan != null);

     forever begin
       this.rsp_chan.get(v_rsp);
       o_rsp = VMM2UVM_RSP::convert(v_rsp);
       if (this.is_bidir_port) begin
         if (this.is_seq_item_port)
           this.seq_item_port.put(o_rsp);
	 else
           this.producer_port.put(o_rsp);
       end
       else if (blocking_put_port.size())
         this.blocking_put_port.put(o_rsp);
       this.response_ap.write(o_rsp);
     end

   endtask


   // Task- put
   //
   // Converts an UVM request to a VMM request and puts it into the
   // <req_chan> vmm_channel. Upon return, if <wait_for_req_ended> is set, the
   // VMM request is put to the <rsp_chan> for response-path processing.
   // The original UVM request is also written to the <request_ap>
   // analysis port.

   virtual task put (UVM_REQ o_req);
     VMM_REQ v_req;
     VMM_RSP v_rsp;
     v_req = UVM2VMM_REQ::convert(o_req);
     req_chan.put(v_req);
     request_ap.write(o_req);
     if (m_req_is_rsp) begin
        if (this.wait_for_req_ended)
           this.wait_for_ended(v_req);
        else begin
           assert($cast(v_rsp,v_req));
           this.rsp_chan.sneak(v_rsp);
        end
     end
   endtask

 
   // Function- can_put
   //
   // Returns 1 if the <req_chan> can accept a new request.

   virtual function bit can_put ();
     return !this.req_chan.is_full();
   endfunction

 
   // Function- try_put
   //
   // If the <req_chan> can accept new requests, converts ~o_req~ to
   // its VMM equivalent, injects it into the channel, and returns 1.
   // Otherwise, returns 0.
   virtual function bit try_put (UVM_REQ o_req);
     VMM_REQ v_req;
     if (!this.can_put())
       return 0;
     v_req = UVM2VMM_REQ::convert(o_req);
     req_chan.sneak(v_req);
     request_ap.write(o_req);
     if (this.wait_for_req_ended)
       fork
       this.wait_for_ended(v_req);
       join_none
     else
     return 1;
   endfunction


   // Task- get
   //
   // Gets a response from the <rsp_chan>, converts, and returns in
   // the ~o_rsp~ output argument.

   virtual task get(output UVM_RSP o_rsp);
     VMM_RSP v_rsp;
     this.rsp_chan.get(v_rsp);
     o_rsp = VMM2UVM_RSP::convert(v_rsp);
   endtask

   // Function- can_get
   //
   // Returns 1 if a response is available to get, 0 otherwise.

   virtual function bit can_get();
     return !(this.rsp_chan.size() <= this.rsp_chan.empty_level() ||
              this.rsp_chan.is_locked(vmm_channel::SINK));
   endfunction
  

   // Function- try_get
   //
   // If a response is available in the <rsp_chan>, gets and returns
   // the response in the ~o_rsp~ output argument and returns 1.
   // Returns 0 otherwise.
   virtual function bit try_get(output UVM_RSP o_rsp);
     vmm_data v_base;
     VMM_RSP v_rsp;
     if (!this.can_get())
       return 0;
     rsp_chan.XgetX(v_base);
     assert($cast(v_rsp, v_base));
     o_rsp = VMM2UVM_RSP::convert(v_rsp);
     return 1;
   endfunction


   // Task- peek
   //
   // Peeks (does not consume) and converts a response from the <rsp_chan>.

   virtual task peek(output UVM_RSP o_rsp);
     VMM_RSP v_rsp;
     this.rsp_chan.get(v_rsp);
     o_rsp = VMM2UVM_RSP::convert(v_rsp);
   endtask


   // Function- can_peek
   //
   // Returns 1 if a transaction is available in the <rsp_chan>, 0 otherwise.

   virtual function bit can_peek();
     return this.can_get();
   endfunction


   // Function- try_peek
   //
   // If a response is available to peek from the <rsp_chan>, this function
   // peeks (does not consume) the transaction from the channel, converts,
   // and returns via the ~o_req~ output argument. Otherwise, returns 0.

   virtual function bit try_peek(output UVM_RSP o_rsp);
     vmm_data v_base;
     VMM_RSP v_rsp;
     if (!this.can_peek())
       return 0;
     v_base = rsp_chan.try_peek();
     assert($cast(v_rsp, v_base));
     o_rsp = VMM2UVM_RSP::convert(v_rsp);
     return 1;
   endfunction


  // Task- transport
  //
  // Blocking transport is used to atomically execute the geiven
  // request transaction, ~req~, and return the response in ~rsp~.

  task transport (UVM_REQ o_req, output UVM_RSP o_rsp);
    this.put(o_req);
    this.get(o_rsp);
  endtask



   protected uvm_port_base #(uvm_tlm_if_base #(UVM_REQ,UVM_RSP)) producer_port;

   protected bit is_seq_item_port = 0;

   protected bit is_bidir_port = 0;

   time request_timeout = 100us;

endclass

//------------------------------------------------------------------------------
// Copyright 2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------


//
// Title: UVM Initiator to VMM Target TLM2 Adapters
//
// This page describes how to use the pre-defined
// <uvi_uvm2vmm_tlm2_b> and <uvi_uvm2vmm_tlm2_nb> adaters
// for connecting a UVM TLM 2.0 initiator socket to
// a compatible VMM TLM 2.0 target socket.
//
// If the TLM 2.0 sockets use generic payload extensions or
// a transaction descriptor other than the pre-defined generic payload,
// or protocol phases other than the pre-defined Base Protocol phases,
// suitable <Transaction Descriptor Conversion Function> policy classes
// must first be implemented.
//

//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm2vmm_tlm2_b
//
// Adapter for a UVM blocking initiator and a VMM blocking target.
//
// The adaptor must be configured using the following
// class parameters:
//
// UVM_TR    - Type of the UVM-side transaction. Defaults to <int>.
// VMM_TR    - Type of the VMM-side transaction. Defaults to <int>.
// UVM2VMM   - UVM-to-VMM conversion policy class. Defaults to <uvi_uvm2vmm_tlm2_converter>.
// VMM2UVM   - VMM-to-UVM conversion policy class. Defaults to <uvi_vmm2uvm_tlm2_converter>.
// TIMESCALE - Timescale of the VMM timing annotation. Defaults to ~1ps~.
//
// Although this adapter is a <uvm_component>, it cannot be instantiated directly.
// The UVM initiator socket is connected to the corresponding VMM target socket
// using the <do_connect()> method.
// That method instantiates the adapter internally.
//
//| class my_env extends uvm_env;
//|    uvm_vip init;
//|    vmm_vip trgt;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       init = new("init", this);
//|       trgt = new("trgt", this);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       uvi_uvm2vmm_tlm2_b::do_connect(init.skt, trgt.skt);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_uvm2vmm_tlm2_b #(type UVM_TR = int,
                           type VMM_TR = int,
                           type UVM2VMM = uvi_uvm2vmm_tlm2_converter,
                           type VMM2UVM = uvi_vmm2uvm_tlm2_converter,
                           realtime TIMESCALE = 1ps) extends uvm_component;

   typedef uvi_uvm2vmm_tlm2_b#(UVM_TR, VMM_TR, UVM2VMM, VMM2UVM, TIMESCALE) this_type;
   
   // UVM target socket which is used to connect to user's UVM initiator socket
   local uvm_tlm_b_target_socket #(this_type, UVM_TR) uvm_targt_b_socket;

   // VMM port which is used to connect to user's VMM target socket
   local vmm_tlm_b_transport_port #(this_type, VMM_TR) vmm_init_b_socket;

   // VMM log required to for messages from adapter
   vmm_log log;

   // Constructor is local to prevent direct instantiation
   //
   local function new (string name="", uvm_component parent=null);
      super.new(name, parent);
      log = new($psprintf("%s_log",name), get_full_name());
      uvm_targt_b_socket = new("trgt", this);
      vmm_init_b_socket = new(this, "init");
   endfunction

   // Function: do_connect
   //
   // Connects the specified UVM blocking initiator socket with
   // the specified VMM blocking target socket.
   
   static function void do_connect(uvm_port_base#(uvm_tlm_if#(UVM_TR)) init_socket,
                                vmm_tlm_export_base#(VMM_TR) targt_socket);
      this_type m_adapter;
      static int num_inst = 0;
      uvi_ok_to_create_in_connect cb = new();                          
      uvm_report_cb::add(null,cb,UVM_PREPEND);

      m_adapter = new($psprintf("UVM2VMM_B%d",num_inst));                      
      num_inst = num_inst + 1;

      if (init_socket == null) begin
`ifdef UVM_ON_TOP
         $display("NULL UVM initiator specified to uvi_uvm2vmm_tlm_b::do_connect()");
         //temp fix to aviod SV-IAMC error by `uvm_error("NULLINIT", "NULL UVM initiator specified to uvi_uvm2vmm_tlm_b::do_connect()");
`else
         `vmm_error(m_adapter.log, "NULL UVM initiator specified to uvi_uvm2vmm_tlm_b::do_connect()");
`endif   
      end

      if (targt_socket == null) begin
`ifdef UVM_ON_TOP
         //`uvm_error("NULLTRGT", "NULL VMM target specified to uvi_uvm2vmm_tlm_b::do_connect()");
`else
         `vmm_error(m_adapter.log, "NULL VMM target specified to uvi_uvm2vmm_tlm_b::do_connect()");
`endif   
      end
     
      init_socket.connect(m_adapter.uvm_targt_b_socket);
      m_adapter.vmm_init_b_socket.tlm_bind(targt_socket);
      uvm_report_cb::delete(null, cb);
   endfunction
  
   // Function- b_transport
   //
   // Forward the transport() call to VMM
   // and return the response back to UVM

   task b_transport(UVM_TR item, ref uvm_tlm_time delay);
      VMM_TR vmm_item;
      int v_delay;
      
      // Convert UVM TLM GP to VMM TLM GP
      vmm_item = UVM2VMM::convert(item, vmm_item);
      
      // Convert UVM Delay to VMM delay
      v_delay = delay.get_abstime(TIMESCALE);
      
      // Call VMM b_transport with converted datatypes
      vmm_init_b_socket.b_transport(vmm_item, v_delay);
      
      // Convert the response back to the initiator
      item = VMM2UVM::convert(vmm_item, item);
      delay.set_abstime(v_delay, TIMESCALE);
   endtask
endclass

//------------------------------------------------------------------------------
//
// CLASS: uvi_uvm2vmm_tlm2_nb
//
//------------------------------------------------------------------------------
//
// Adapter for a UVM nonblocking initiator and a VMM nonblocking target.
//
// The adaptor must be configured using the following
// class parameters:
//
// UVM_TR    - Type of the UVM-side transaction. Defaults to <int>.
// UVM_PH    - Type of the UVM-side phases. Defaults to <int>.
// VMM_TR    - Type of the VMM-side transaction. Defaults to <int>.
// VMM_PH    - Type of the VMM-side phases. Defaults to <int>.
// UVM2VMM   - UVM-to-VMM conversion policy class. Defaults to <uvi_uvm2vmm_tlm2_converter>.
// VMM2UVM   - VMM-to-UVM conversion policy class. Defaults to <uvi_vmm2uvm_tlm2_converter>.
// TIMESCALE - Timescale of the VMM timing annotation. Defaults to ~1ps~.
//
// Although this adapter is a <uvm_component>, it cannot be instantiated directly.
// The UVM initiator socket is connected to the corresponding VMM target socket
// using the <do_connect()> method.
// That method instantiates the adapter internally.
//
//| class my_env extends uvm_env;
//|    uvm_vip init;
//|    vmm_vip trgt;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       init = new("init", this);
//|       trgt = new("trgt", this);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       uvi_uvm2vmm_tlm2_nb::do_connect(init.skt, trgt.skt);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_uvm2vmm_tlm2_nb #(type UVM_TR = int,
                            type UVM_PH = int,
                            type VMM_TR = int,
                            type VMM_PH = int,
                            type UVM2VMM = uvi_uvm2vmm_tlm2_converter,
                            type VMM2UVM = uvi_vmm2uvm_tlm2_converter,
                            realtime TIMESCALE = 1ps) extends uvm_component;

   typedef uvi_uvm2vmm_tlm2_nb#(UVM_TR, UVM_PH, VMM_TR, VMM_PH,
                                UVM2VMM, VMM2UVM, TIMESCALE) this_type;
   
   // UVM target socket which is used to connect to user's UVM initiator socket.
   local uvm_tlm_nb_target_socket #(this_type, UVM_TR) uvm_targt_nb_socket;
   
   // VMM port which is used to connect to user's VMM export.
   local vmm_tlm_nb_transport_port#(this_type, VMM_TR) vmm_init_nb_socket;

   // VMM log required to for messages from adapter
   vmm_log log;

   // Constructor is local to prevent direct instantiation
   //
   //local function new(string name="", uvm_component parent = null);
   function new(string name="", uvm_component parent = null);
      super.new(name, parent);
      log = new($psprintf("%s_log",name), get_full_name());
      uvm_targt_nb_socket  = new ("uvm_targt_nb_socket" , this);
      vmm_init_nb_socket = new(this, "vmm_init_nb_socket");
   endfunction

   local function vmm_tlm::sync_e vmm_sync(uvm_tlm_sync_e sync);
      case (sync)
       UVM_TLM_ACCEPTED : return vmm_tlm::TLM_ACCEPTED;
       UVM_TLM_UPDATED  : return vmm_tlm::TLM_UPDATED;
       UVM_TLM_COMPLETED: return vmm_tlm::TLM_COMPLETED;
      endcase
   endfunction

   local function uvm_tlm_sync_e uvm_sync(vmm_tlm::sync_e vsync);
      case (vsync)
       vmm_tlm::TLM_ACCEPTED : return UVM_TLM_ACCEPTED;
       vmm_tlm::TLM_UPDATED  : return UVM_TLM_UPDATED;
       vmm_tlm::TLM_COMPLETED: return UVM_TLM_COMPLETED;
      endcase
   endfunction


   // Function: do_connect
   //
   // Connects the specified UVM non-blocking initiator socket with
   // the specified VMM non-blocking nonblocking target socket.

   //static function void do_connect(uvm_tlm_nb_initiator_socket_base#(UVM_TR, UVM_PH) init_socket,
   static function void do_connect(uvm_port_base#(uvm_tlm_if#(UVM_TR, UVM_PH)) init_socket,
                                vmm_tlm_export_base #(VMM_TR, VMM_PH) targt_socket);
      this_type m_adapter;
      static int num_inst = 0;
      uvi_ok_to_create_in_connect cb = new();                          
      uvm_report_cb::add(null,cb,UVM_PREPEND);

      m_adapter = new($psprintf("UVM2VMM_NB%d",num_inst));                      
      num_inst = num_inst + 1;

      if (init_socket == null) begin
`ifdef UVM_ON_TOP
         // `uvm_error("NULLINIT", "NULL initiator specified to uvi_uvm2vmm_tlm_nb::do_connect()")
         $display("NULL initiator specified to uvi_uvm2vmm_tlm_nb::do_connect");
`else
         `vmm_error(m_adapter.log, "NULL initiator specified to uvi_uvm2vmm_tlm_nb::do_connect()");
`endif   
      end

      if (targt_socket == null) begin
`ifdef UVM_ON_TOP
         // `uvm_error("NULLTRGT", "NULL target specified to uvi_uvm2vmm_tlm_nb::do_connect()")
         $display("NULL target specified to uvi_uvm2vmm_tlm_nb::do_connect");
`else
         `vmm_error(m_adapter.log, "NULL target specified to uvi_uvm2vmm_tlm_nb::do_connect()");
`endif   
      end
      
      init_socket.connect(m_adapter.uvm_targt_nb_socket);
      m_adapter.vmm_init_nb_socket.tlm_bind(targt_socket);
      uvm_report_cb::delete(null, cb);
   endfunction
  

   local VMM_TR vmm_item[UVM_TR]; // Assoc array indexed by uvm_item
   local UVM_TR uvm_item[VMM_TR]; // Assoc array indexed by vmm_item

   
   // Function- nb_transport_fw
   //
   // Forward the FW() call to VMM
   // and return the response back to UVM

   function uvm_tlm_sync_e nb_transport_fw(UVM_TR item, ref UVM_PH phase,
                                           ref uvm_tlm_time delay);
      int v_delay;
      VMM_PH v_phase;
      vmm_tlm::sync_e v_sync;
      VMM_TR v_item;
      
      if(vmm_item.exists(item))
         v_item = vmm_item[item];

      v_item = UVM2VMM::convert(item, v_item);
      vmm_item[item] = v_item;
      uvm_item[v_item] = item;

      v_delay = delay.get_abstime(TIMESCALE);
      v_phase = UVM2VMM::convert_phase(phase);
      
      // Call VMM nb_transport_fw
      //v_sync = vmm_init_nb_socket.nb_transport_fw(vmm_item, v_phase, v_delay);
      v_sync = vmm_init_nb_socket.nb_transport_fw(v_item, v_phase, v_delay);
      
      item = VMM2UVM::convert(v_item, item);
      delay.set_abstime(v_delay, TIMESCALE);
      phase = VMM2UVM::convert_phase(v_phase);

      // Remove from assoc array if COMPLETED
      if(v_sync == vmm_tlm::TLM_COMPLETED) begin
         vmm_item.delete(item);
         uvm_item.delete(v_item);
      end
      
      return uvm_sync(v_sync);
   endfunction

   
   // Function- nb_transport_bw
   //
   // Forward the BW() call to UVM
   // and return the response back to VMM

   function vmm_tlm::sync_e nb_transport_bw(int id,
                                            VMM_TR item,
                                            ref VMM_PH phase,
                                            ref int delay);
      uvm_tlm_time u_delay = new;
      UVM_PH u_phase;
      uvm_tlm_sync_e u_sync;
      UVM_TR u_item;
     
      if(uvm_item.exists(item))
         u_item = uvm_item[item];
      else
`ifdef UVM_ON_TOP
         `uvm_error("NULLTRGT", "Illegal transaction sent to uvi_uvm2vmm_tlm2_nb::nb_transport_bw()")
`else
         `vmm_error(log, "Illegal transaction sent to uvi_uvm2vmm_tlm2_nb::nb_transport_bw()");
`endif   

      u_item = VMM2UVM::convert(item, u_item);
      u_delay.set_abstime(delay, TIMESCALE);
      u_phase = VMM2UVM::convert_phase(phase);

      u_sync = uvm_targt_nb_socket.nb_transport_bw(u_item,u_phase, u_delay);

      item = UVM2VMM::convert(u_item, item);
      delay = u_delay.get_abstime(TIMESCALE);
      phase = UVM2VMM::convert_phase(u_phase);

      // Removed from assoc array if COMPLETEDD
      if(u_sync == UVM_TLM_COMPLETED) begin
         vmm_item.delete(u_item);
         uvm_item.delete(item);
      end
      
      return vmm_sync(u_sync);
   endfunction
endclass
`endif
// for VMM_ON_TOP
//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//
// Redirect UVM messages to VMM with the following mapping
//
//   UVM FATAL   --> VMM FATAL
//   UVM ERROR   --> VMM ERROR
//   UVM WARNING --> VMM WARNING
//   UVM INFO    --> VMM NOTE    if verbosity level < UVM_MEDIUM
//                   VMM DEBUG   if verbosity level == UVM_MEDIUM
//                   VMM VERBOSE if verbosity level > UVM_MEDIUM
//

class uvi_vmm_uvm_report_server extends uvm_default_report_server;

   static local uvi_vmm_uvm_report_server me;
   static function uvi_vmm_uvm_report_server get();
      if (me == null) me = new;
      return me;
   endfunction

   `VMM_LOG log;

   local int vmm_sev;

`ifdef VMM_ON_TOP

   // Replace the UVM message server with one that re-routes
   // UVM messages to a vmm_log instance.
   static local bit m_init = m_override_uvm_report_server();
   static local function bit m_override_uvm_report_server();
      uvm_report_server::set_server(get());
      return 1;
   endfunction
`endif

   local function new();
      super.new();
      this.log = new("UVM", "reporter");
      // Make sure all UVM messages are issued by default
      this.log.set_verbosity(vmm_log::VERBOSE_SEV);
      // Let VMM abort if too many errors
      this.set_max_quit_count(0);
   endfunction
   


   virtual function void execute_report_message(uvm_report_message report_message, 
                                                string             composed_message);
      int typ;
      uvm_severity severity;

      //super.execute_report_message(report_message, composed_message);
      severity = report_message.get_severity();
      this.vmm_sev = vmm_log::NORMAL_SEV;

      case (severity)
        UVM_INFO:    typ = vmm_log::NOTE_TYP;
        UVM_WARNING: typ = vmm_log::FAILURE_TYP;
        UVM_ERROR:   typ = vmm_log::FAILURE_TYP;
        UVM_FATAL:   typ = vmm_log::FAILURE_TYP;
      endcase
      case (severity)
        UVM_WARNING: this.vmm_sev = vmm_log::WARNING_SEV;
        UVM_ERROR:   this.vmm_sev = vmm_log::ERROR_SEV;
        UVM_FATAL:   this.vmm_sev = vmm_log::FATAL_SEV;
      endcase

      if (this.log.start_msg(typ, this.vmm_sev `ifdef VMM_LOG_FORMAT_FILE_LINE , report_message.get_filename(), report_message.get_line() `endif )) begin
         void'(this.log.text(composed_message));
         this.log.end_msg();
      end
   endfunction


   virtual function string compose_report_message(uvm_report_message    report_message,
                                                string                  report_object_name = "");
      // Severity, time, filename and line number
      // will be provided by vmm_log
      $sformat(compose_report_message, "%s(%s): %s",
               report_message.get_context(), report_message.get_id(), 
               report_message.get_message());
   endfunction
endclass
//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Title: UVM Components in Explicitly-Phased VMM Environments
//
//------------------------------------------------------------------------------
//
// UVM components are instantiated in extensions of the ~vmm_env~ or ~vmm_subenv~
// classes, specifying ~null~ as their parent components.
// Logically speaking, the ~vmm_env~ or ~vmm_subenv~ is the parent of the UVM components.
// However, not being a ~uvm_component~, it is not possible to specify either
// as the parent component. Thus, all top-level UVM components instantiated
// in explicitly-phased VMM environments will be physically located
// under <uvm_root>.
//
// The <uvi_vmm_uvm_env> class must be used as the base class of top-level environment
// instead of the ~vmm_env~ class.
//
// The integrator incorporates UVM IP into a VMM environment
// by instantiating the IP in the ~uvi_vmm_ovm_env::build()~ method,
// or in the constructor of a ~vmm_subenv~ ultimately instantiated
// in the ~uvi_vmm_ovm_env::build()~ method.
// The instantiation may be done either directly by calling new() or by creating the
// UVM component via the factory.
// It is then necessary for the VMM build() method to call uvm_build().
//
// Example:
//
//| class my_env extends uvi_vmm_uvm_env;
//|    uvm_comp u1;
//|
//|    function new(string name);
//|       super.new(name);
//|    endfunction
//|
//|    function void build();
//|       super.build();
//|       u1 = uvm_comp::type_id::create("u1");
//|       uvm_build();
//|    endfunction
//| endclass
//
// The UVM components are phased relative to the execution of
// the explicitly-phased VMM environment phase methods as follows:
//
//|            VMM                   UVM
//|             |                    
//|           gen_cfg                
//|             |                    
//|            build
//|             +-----------------> build
//|                  uvm_build()      |
//|                                connect
//|                                   |                      
//|                           end_of_elaboration
//|                                   |
//|                           start_of_simulation
//|             +---------------------+
//|             |
//|             +-------------------------------------> run
//|             |                                        |
//|          reset_dut -----------> pre_reset            |
//|             |                   reset                |
//|             |                   post_reset           |
//|             |                      |                 |
//|          cfg_dut -------------> pre_configure        |
//|             |                   configure            |
//|             |                   post_configure       |
//|             |                      |                 |
//|           start --------------> pre_main             |
//|             |                      |                 |
//|        wait_for_end ----------> main                 |
//|             |                   post_main            |
//|             +<---------------------+                 |
//|             |                      |                 |
//|          stop --------------->  pre_shutdown         |
//|             |                   shutdown             |
//|             |                   post_shutdown        |
//|             +<---------------------+-----------------+
//|             |
//|           report
//|             +-----------------> extract
//|                 uvm_report()    check
//|                                 report 
//|             +---------------------+
//|             |
//|             *
//
// The ~`VMM_ON_TOP~ symbol must also be defined when using this class.
// This this class is automatically used as the base class of the ~vmm_ral_env~
// class.
//
// Rolling back the VMM explicit phases using ~vmm_env::restart()~ is not supported.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_uvm_env
//
// This class is used as a replacement for the ~vmm_env~ class
// to automatically integrate UVM phasing with VMM phasing
// in an explicitly-phased VMM-on-top environment.
//------------------------------------------------------------------------------

class uvi_vmm_uvm_env extends `AVT_VMM_UVM_ENV_BASE;

   // Function: new
   // 
   // Creates a new instance of an <uvi_vmm_uvm_env>.

   function new(string name = "Verif Env"
                `VMM_ENV_BASE_NEW_EXTERN_ARGS);   
      super.new(name
                `VMM_ENV_BASE_NEW_CALL
                );
      log.set_instance(name);
   endfunction // new

   // Function: uvm_build
   //
   // Start the UVM building process
   // This method must be invoked as the last statement
   // in the extension of the ~build()~ method.
   
   protected function void uvm_build();
      uvm_root top = uvm_root::get();
      process uvm_phaser;

      // Pre-raise the objections to gating UVM phases
      begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         uvm_phase ph;

         ph = uvm.find(uvm_post_reset_phase::get()); 
         //ph.raise_objection(top, "VMM-on-top");
         ph = uvm.find(uvm_post_configure_phase::get());
         //ph.raise_objection(top, "VMM-on-top");
         ph = uvm.find(uvm_pre_main_phase::get());
         //ph.raise_objection(top, "VMM-on-top");
         ph = uvm.find(uvm_post_main_phase::get());
         //ph.raise_objection(top, "VMM-on-top");
         ph = uvm.find(uvm_post_shutdown_phase::get());
         //ph.raise_objection(top, "VMM-on-top");
      end
      begin
         uvm_domain common = uvm_domain::get_common_domain();
         uvm_phase ph = common.find(uvm_run_phase::get());
         ph.raise_objection(top, "VMM-on-top");
      end

      // phase runner, isolated from calling process
      uvm_objection::m_init_objections();
      top.m_phase_all_done = 0;
      top.finish_on_completion=0;
      fork
         begin
	    // spawn the phase runner task
	    uvm_phaser = process::self();
	    uvm_phase::m_run_phases();
         end
         begin
            wait (top.m_phase_all_done == 1);
            uvm_phaser.kill();
         end
      join_none
   endfunction
    
   local bit m_built;

   // Task: start_of_simulation
   //
   // Complete the elaboration of the environment.
   // This is an additional simulation phase that ensures
   // that the UVM portion of the environment has been completely
   // built.
   // Should be used instead of calling ~env.build()~.

   task start_of_simulation();
      super.reset_dut();

      begin
         uvm_domain common = uvm_domain::get_common_domain();
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         uvm_phase ph = common.find(uvm_run_phase::get());
         uvm_phase ph1 = uvm.find(uvm_reset_phase::get());
        fork 
         ph.wait_for_state(UVM_PHASE_STARTED, UVM_GTE);
         ph1.wait_for_state(UVM_PHASE_STARTED, UVM_GTE);
        join
      end
      m_built = 1;
   endtask

   virtual task reset_dut();
      if (!m_built) start_of_simulation();
   endtask

   virtual task cfg_dut();
      super.cfg_dut();

      begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         uvm_phase ph = uvm.find(uvm_post_reset_phase::get());
         ph.wait_for_state(UVM_PHASE_STARTED, UVM_GTE);
         ph.drop_objection(uvm_top, "VMM-on-top");
         ph = uvm.find(uvm_pre_configure_phase::get());
         ph.drop_objection(uvm_top, "VMM-on-top");
      end
   endtask
   
   virtual task start();
      super.start();

      begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         uvm_phase ph = uvm.find(uvm_post_configure_phase::get());
         ph.wait_for_state(UVM_PHASE_STARTED, UVM_GTE);

         ph.drop_objection(uvm_top, "VMM-on-top");
      end
   endtask
   
   virtual task wait_for_end();
      super.wait_for_end();

      begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         uvm_phase ph = uvm.find(uvm_pre_main_phase::get());

         ph.drop_objection(uvm_top, "VMM-on-top");
      end
   endtask

   virtual task stop();
      super.stop();

      begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         uvm_phase ph = uvm.find(uvm_post_main_phase::get());

         ph.drop_objection(uvm_top, "VMM-on-top");
         ph = uvm.find(uvm_pre_shutdown_phase::get());
         ph.wait_for_state(UVM_PHASE_STARTED, UVM_GTE);
      end
   endtask

   local bit m_cleaned;
   virtual task cleanup();
      super.cleanup();

      begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         /*uvm_phase ph = uvm.find(uvm_post_main_phase::get());

         ph.drop_objection(uvm_top, "VMM-on-top");*/
         uvm_phase ph = uvm.find(uvm_shutdown_phase::get());
         ph.drop_objection(uvm_top, "VMM-on-top");
      end

      m_cleaned = 1;
   endtask
   
   task run();
      uvm_domain uvm    = uvm_domain::get_uvm_domain();
      uvm_domain common = uvm_domain::get_common_domain();
      uvm_phase  ph;

      if (!m_cleaned) cleanup();

      ph = uvm.find(uvm_post_shutdown_phase::get());
      ph.drop_objection(uvm_top, "VMM-on-top");

      ph = common.find(uvm_run_phase::get());
      ph.drop_objection(uvm_top, "VMM-on-top");

      ph = common.find(uvm_report_phase::get());
      ph.wait_for_state(UVM_PHASE_ENDED, UVM_GTE);
   

      this.report();
   endtask
endclass
typedef uvi_vmm_uvm_env avt_vmm_uvm_env;




`ifndef NO_VMM_12
//------------------------------------------------------------------------------
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// SYNOPSYS CONFIDENTIAL - This is an unpublished, proprietary work of
// Synopsys, Inc., and is fully protected under copyright and trade
// secret laws. You may not view, use, disclose, copy, or distribute this
// file or any information contained herein except pursuant to a valid
// written license from Synopsys.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Title: UVM Components in Implicitly-Phased VMM Environments
//
//------------------------------------------------------------------------------
//
// UVM components are instantiated in extensions of the ~vmm_group~ class
// specifying ~null~ as their parent components. Logically speaking, the
// ~vmm_group~ is the parent of the UVM components.
// However, not being a ~uvm_component~, it is not possible to specify it
// as the parent component. Thus, all top-level UVM components instantiated
// in implicitly-phased VMM environments will be physically located
// under <uvm_top>.
//
// The <uvi_vmm_uvm_timeline> class is a singleton class used to
// coordinate the execution of the phases in the ~common~ and ~uvm~ domains.
// The pre-defined UVM phases are aligned with the pre-defined VMM phases
// in ~vmm_simulation~ as follows:
//
//|            VMM                         UVM
//|
//|          rtl_cfg                
//|             |                    
//|           build
//|             +-----------------> build
//|             |
//|         configure
//|             |                
//|          connect
//|             +-----------------> connect
//|             +-----------------> end_of_elaboration
//|             |
//|       configure_test
//|             |                    
//|        start_of_sim
//|             +-----------------> start_of_simulation
//|             |
//|             +-------------------------------------> run
//|             |                                        |
//|           reset --------------> pre_reset            |
//|             |                   reset                |
//|             |                   post_reset           |
//|             +<---------------------+                 |
//|             |                                        |
//|         training -------------> pre_configure        |
//|             +<---------------------+                 |
//|             |                                        |
//|         config_dut -----------> configure            |
//|             |                   post_configure       |
//|             +<---------------------+                 |
//|             |                                        |
//|        start_of_test                                 |
//|             |                                        |
//|           start --------------> pre_main             |
//|             +<---------------------+                 |
//|             |                                        |
//|         run_test -------------> main                 |
//|             |                   post_main            |
//|             +<---------------------+                 |
//|             |                                        |
//|          shutdown ------------> pre_shutdown         |
//|             |                   shutdown             |
//|             +<---------------------+                 |
//|             |                                        |
//|          cleanup -------------> post_shutdown        |
//|             +<---------------------+-----------------+
//|             |
//|             +-----------------> extract
//|             +-----------------> check
//|             +-----------------> report
//|           report 
//|             |
//|        <final report>
//|             |
//|             *
//|
//
// The <uvi_vmm_uvm_timeline> class singleton is automatically instantiated
// when ~`VMM_ON_TOP~ is defined.
// It phased directly by the top-level ~vmm_simulation~ timeline.
// Thus all UVM components in the ~uvm~ phase domain will be phased together,
// with the top-level timeline.
//
// If UVM components must be phased using a different VMM timeline,
// they must be assigned to a different UVM phase domain,
// and the phase schedule in that domain must be coordinated with
// the VMM phases in the different timeline.
// This is currently outside the scope of this document.
// if this situation arises, please contact Synopsys Support for help.
//


//
// Kick off the UVM simulation
//
class vmm_start_uvm extends vmm_function_phase_def;
   virtual function void run_function_phase(string     name, 
                                            vmm_object obj, 
                                            vmm_log    log);
      uvm_root top = uvm_root::get();
      process uvm_phaser;
      
      uvm_objection::m_init_objections();
      top.m_phase_all_done = 0;
      top.finish_on_completion=0;
      fork
         begin
            // spawn the phase runner task
            uvm_phaser = process::self();
            uvm_phase::m_run_phases();
         end
         begin
            wait (top.m_phase_all_done == 1);
            uvm_phaser.kill();
         end
      join_none
   endfunction
endclass


//
// Wait for a UVM phase to be done
//
class vmm_uvm_sync_phase_def #(type T = int) extends vmm_task_phase_def;

   static bit run_only_once = 0;
   
   virtual task run_task_phase(string     name, 
                               vmm_object obj, 
                               vmm_log    log);
      uvm_domain common;
      uvm_phase  ph;
      vmm_unit   u;

      if (run_only_once) begin
         if ($cast(u, obj)) u.phase_executed[name]=1;
         return;
      end
      run_only_once = 1;
      
      common = uvm_domain::get_common_domain();
      ph = common.find(T::get());
      if (ph.get_state() < UVM_PHASE_ENDED) begin
         ph.wait_for_state(UVM_PHASE_ENDED);
      end

      if ($cast(u, obj)) u.phase_executed[name]=1;
   endtask
endclass


//
// Pre-object to a end-of-phase then drop the objection
//
class vmm_uvm_object_to_phase_def #(type T = int) extends vmm_task_phase_def;

   static bit run_only_once = 0;

   static uvm_phase ph;

   function new();
      if (ph == null) begin
         uvm_domain uvm = uvm_domain::get_uvm_domain();
         ph = uvm.find(T::get());
         ph.raise_objection(null, "VMM has not completed corresponding phase");
      end
   endfunction
   
   virtual task run_task_phase(string     name, 
                               vmm_object obj, 
                               vmm_log    log);
      vmm_unit   u;

      if (run_only_once) begin
         if ($cast(u, obj)) u.phase_executed[name]=1;
         return;
      end
      run_only_once = 1;
      
      ph.drop_objection(null, "VMM completed corresponding phase");
      if ($cast(u, obj)) u.phase_executed[name]=1;
   endtask
endclass


/*
  Class: uvi_vmm_uvm_timeline 
*/
class uvi_vmm_uvm_timeline extends vmm_unit;
   `vmm_typename(uvi_vmm_uvm_timeline)
   static local uvi_vmm_uvm_timeline m_singleton;

   local function new();
      super.new("uvi_vmm_uvm_timeline", "singleton");
   endfunction
   
   static function uvi_vmm_uvm_timeline get();
      if (m_singleton == null) begin
         vmm_timeline   tl;
         
         m_singleton = new();

         tl = vmm_simulation::get_pre_timeline();
         begin
            vmm_start_uvm ph = new();
            tl.insert_phase_internal("uvm", "^", ph);
         end
         begin
            vmm_uvm_sync_phase_def#(uvm_build_phase) ph = new();
            tl.insert_phase_internal("uvm_build", "configure", ph);
         end
         begin
            vmm_uvm_sync_phase_def#(uvm_connect_phase) ph = new();
            tl.insert_phase_internal("uvm_connect", "$", ph);
         end
         begin
            vmm_uvm_sync_phase_def#(uvm_end_of_elaboration_phase) ph = new();
            tl.insert_phase_internal("uvm_eoe", "$", ph);
         end
         
         tl = vmm_simulation::get_top_timeline();
         begin
            vmm_uvm_sync_phase_def#(uvm_start_of_simulation_phase) ph = new();
            tl.insert_phase_internal("uvm_sos", "start_of_sim", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_post_reset_phase) ph = new();
            tl.insert_phase_internal("uvm_post_reset", "training", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_pre_configure_phase) ph = new();
            tl.insert_phase_internal("uvm_pre_configure", "training", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_post_configure_phase) ph = new();
            tl.insert_phase_internal("uvm_post_configure", "start_of_test", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_pre_main_phase) ph = new();
            tl.insert_phase_internal("uvm_pre_main", "run_test", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_post_main_phase) ph = new();
            tl.insert_phase_internal("uvm_post_main", "shutdown", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_shutdown_phase) ph = new();
            tl.insert_phase_internal("uvm_shutdown", "cleanup", ph);
         end
         begin
            vmm_uvm_object_to_phase_def#(uvm_post_shutdown_phase) ph = new();
            tl.insert_phase_internal("uvm_post_shutdown", "report", ph);
         end
         begin
            vmm_uvm_sync_phase_def#(uvm_extract_phase) ph = new();
            tl.insert_phase_internal("uvm_extract", "report", ph);
         end
         begin
            vmm_uvm_sync_phase_def#(uvm_check_phase) ph = new();
            tl.insert_phase_internal("uvm_check", "report", ph);
         end
         begin
            vmm_uvm_sync_phase_def#(uvm_report_phase) ph = new();
            tl.insert_phase_internal("uvm_report", "report", ph);
         end
         
      end
      return m_singleton;
   endfunction
   
`ifdef VMM_ON_TOP
   static local uvi_vmm_uvm_timeline m_auto_init = get();
`endif
endclass
//------------------------------------------------------------------------------
// Copyright 2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------

//
// Title: VMM Analysis Port Adapters
//
// When connecting a VMM analysis port to a UVM interface,
// the correct adapter must be used according to the type of UVM interface.
//
// UVM analysis port   - Use the <uvi_vmm_ap2uvm_ap> adapter.
//
//

//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_ap2uvm_ap
//
//------------------------------------------------------------------------------
//
// Use this adapter to connect a VMM analysis port to an UVM analysis export
// 
// The adapter must be configured using the following
// class parameters:
//
// VMM_TR    - Type of the VMM-side transaction. Defaults to <int>.
// UVM_TR    - Type of the UVM-side transaction. Defaults to <int>.
// VMM2UVM   - VMM-to-UVM conversion policy class. Defaults to <uvi_converter#(VMM_TR,UVM_TR)>.
//
// Although this adapter is a <uvm_component>, it cannot be instantiated directly.
// The VMM analysis port is connected to the corresponding UVM analysis export
// using the <do_connect()> method.
// That method instantiates the adapter internally.
//
//| class my_env extends uvm_env;
//|    vmm_vip mon;
//|    uvm_sb  sb;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon", this);
//|       sb  = new("sb", this);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       uvi_vmm_ap2uvm_ap::do_connect(mon.ap, sb.a_xp);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_vmm_ap2uvm_ap #(type VMM_TR = int,
                          type UVM_TR = int,
                          type VMM2UVM = uvi_converter#(VMM_TR,UVM_TR))
   extends uvm_component;

   typedef uvi_vmm_ap2uvm_ap#(VMM_TR, UVM_TR, VMM2UVM) this_type;
   // UVM port which is used to connect to user's UVM import.
   uvm_analysis_port #(UVM_TR) uvm_init_analysis_socket;

   // VMM export which is used to connect to user's VMM port.
   local vmm_tlm_analysis_export#(this_type, VMM_TR) vmm_targt_analysis_socket;

   // Variable- log
   //
   // VMM log required to for messages from adapter
   vmm_log log;
   
   //local function new(string name="", uvm_component parent = null);
   local function new(string name="", uvm_component parent = null);
      super.new(name,parent);
      log = new($psprintf("%s_log",name), get_full_name());
      uvm_init_analysis_socket  = new ("uvm_init_analysis_socket" , this);
      vmm_targt_analysis_socket = new(this, "vmm_targt_analysis_socket");
   endfunction

   // Function: do_connect
   //
   // Connect the specified UVM analysis port to the specified VMM analysis export.
   
  static function void do_connect(vmm_tlm_analysis_port_base#(VMM_TR) ap,
                        uvm_port_base #(uvm_tlm_if_base#(UVM_TR,UVM_TR)) xp);
      this_type m_adapter;
      static int num_inst = 0;
      uvi_ok_to_create_in_connect cb = new();                          
      uvm_report_cb::add(null,cb,UVM_PREPEND);

      m_adapter = new($psprintf("VMM2UVM_ANALYSIS%d",num_inst));                      
      num_inst = num_inst + 1;

     if(ap == null)
     begin
        `ifdef UVM_ON_TOP
           //`uvm_error("Connection In Progress: ", "First argument to do_connect function is null");
           $display("Connection In Progress: , First argument to do_connect function is null");
        `else
           `vmm_error(m_adapter.log,"Connection In Progress: First argument to do_connect function is null");
        `endif   
     end
     if(xp == null)
     begin
        `ifdef UVM_ON_TOP
           //`uvm_error("Connection In Progress: ", "Second argument to do_connect function is null");
           $display("Connection In Progress: , Second argument to do_connect function is null");
        `else
           `vmm_error(m_adapter.log,"Connection In Progress: Second argument to do_connect function is null");
        `endif   
     end
     
     ap.tlm_bind(m_adapter.vmm_targt_analysis_socket);
     m_adapter.uvm_init_analysis_socket.connect(xp);
     uvm_report_cb::delete(null, cb);
  endfunction

   // Function- write
   //
   // Forward the write() call to UVM

  function void write(int id=-1, VMM_TR item);
     UVM_TR uvm_item;

     uvm_item = VMM2UVM::convert(item, uvm_item);
     uvm_init_analysis_socket.write(uvm_item);
  endfunction
endclass  
//------------------------------------------------------------------------------
// Copyright 2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------


//
// Title: VMM Initiator to UVM Target TLM2 Adapters
//
// This page describes how to use the pre-defined
// <uvi_vmm2uvm_tlm2_b> and <uvi_vmm2uvm_tlm2_nb> adaters
// for connecting a UVM TLM 2.0 initiator socket to
// a compatible VMM TLM 2.0 target socket.
//
// If the TLM 2.0 sockets use generic payload extensions or
// a transaction descriptor other than the pre-defined generic payload,
// or protocol phases other than the pre-defined Base Protocol phases,
// suitable <Transaction Descriptor Conversion Function> policy classes
// must first be implemented.
//



//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm2uvm_tlm2_b
//
// Adapter for a VMM blocking initiator and a UVM blocking target.
//
// The adaptor must be configured using the following
// class parameters:
//
// VMM_TR    - Type of the VMM-side transaction. Defaults to <int>.
// UVM_TR    - Type of the UVM-side transaction. Defaults to <int>.
// VMM2UVM   - VMM-to-UVM conversion policy class. Defaults to <uvi_vmm2uvm_tlm2_converter>.
// UVM2VMM   - UVM-to-VMM conversion policy class. Defaults to <uvi_uvm2vmm_tlm2_converter>.
// TIMESCALE - Timescale of the VMM timing annotation. Defaults to ~1ps~.
//
// Although this adapter is a <uvm_component>, it cannot be instantiated directly.
// The VMM initiator socket is connected to the corresponding UVM target socket
// using the <do_connect()> method.
// That method instantiates the adapter internally.
//
//| class my_env extends uvm_env;
//|    vmm_vip init;
//|    uvm_vip trgt;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       init = new("init", this);
//|       trgt = new("trgt", this);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       uvi_vmm2uvm_tlm2_b::do_connect(init.skt, targt.skt);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_vmm2uvm_tlm2_b #(type VMM_TR = int,
                          type UVM_TR = int,
                          type VMM2UVM = uvi_vmm2uvm_tlm2_converter,
                          type UVM2VMM = uvi_uvm2vmm_tlm2_converter,
                          realtime TIMESCALE = 1ps) extends uvm_component;

   typedef uvi_vmm2uvm_tlm2_b#(VMM_TR, UVM_TR, VMM2UVM, UVM2VMM, TIMESCALE) this_type;
   
   // VMM port which is used to connect to user's VMM initiator port
   local vmm_tlm_b_transport_export #(this_type, VMM_TR) vmm_trgt_b_socket;

   // UVM initiator socket which is used to connect to user's target socket
   local uvm_tlm_b_initiator_socket #(UVM_TR) uvm_init_b_socket;

   // VMM log required to for messages from adapter
   vmm_log log;

   // Constructor is local to prevent direct instantiation
   //
   local function new (string name="", uvm_component parent=null);
      super.new(name, parent);
      log = new($psprintf("%s_log",name), get_full_name());
      vmm_trgt_b_socket = new(this, "trgt");
      uvm_init_b_socket = new("init", this);
   endfunction

   // Function: do_connect
   //
   // Connects the specified VMM blocking initiator socket with
   // the specified UVM blocking target socket.
   
   static function void do_connect(vmm_tlm_port_base#(VMM_TR) init_socket,
                                uvm_port_base#(uvm_tlm_if#(UVM_TR)) trgt_socket);
      this_type m_adapter;
      static int num_inst = 0;
      uvi_ok_to_create_in_connect cb = new();                          
      uvm_report_cb::add(null,cb,UVM_PREPEND);

      m_adapter = new($psprintf("VMM2UVM_B%d",num_inst));                      
      num_inst = num_inst + 1;
      
      if (init_socket == null) begin
`ifdef UVM_ON_TOP
         //`uvm_error("NULLINIT", "NULL VMM initiator specified to uvi_vmm2uvm_tlm2_b::do_connect()");
         $display( "NULL VMM initiator specified to uvi_vmm2uvm_tlm2_b::do_connect()");
`else
         `vmm_error(m_adapter.log, "NULL VMM initiator specified to uvi_vmm2uvm_tlm2_b::do_connect()");
`endif   
      end

      if (trgt_socket == null) begin
`ifdef UVM_ON_TOP
         $display("NULL UVM target specified to uvi_vmm2uvm_tlm2_b::do_connect()");
         //`uvm_error("NULLTRGT", "NULL UVM target specified to uvi_vmm2uvm_tlm2_b::do_connect()");
`else
         `vmm_error(m_adapter.log, "NULL UVM target specified to uvi_vmm2uvm_tlm2_b::do_connect()");
`endif   
      end
     
      init_socket.tlm_bind(m_adapter.vmm_trgt_b_socket);
      m_adapter.uvm_init_b_socket.connect(trgt_socket);
      uvm_report_cb::delete(null, cb);
   endfunction
  
   // Function- b_transport
   //
   // Forward the transport() call to UVM
   // and return the response back to VMM

   task b_transport(int id=-1, VMM_TR item, ref int delay);
      UVM_TR uvm_item;
      uvm_tlm_time u_delay = new();
      
      uvm_item = VMM2UVM::convert(item, uvm_item);
      u_delay.set_abstime(delay, TIMESCALE);
      
      // Call UVM b_transport with converted datatypes
      uvm_init_b_socket.b_transport(uvm_item, u_delay);
      
      // Convert the response back to the initiator
      item = UVM2VMM::convert(uvm_item, item);
      delay = u_delay.get_abstime(TIMESCALE);
   endtask
endclass



//
// CLASS: uvi_vmm2uvm_tlm2_nb
//
//------------------------------------------------------------------------------
//
// Adapter for a VMM nonblocking initiator and a UVM nonblocking target.
//
// The adaptor must be configured using the following
// class parameters:
//
// VMM_TR    - Type of the VMM-side transaction. Defaults to <int>.
// VMM_PH    - Type of the VMM-side phases. Defaults to <int>.
// UVM_TR    - Type of the UVM-side transaction. Defaults to <int>.
// UVM_PH    - Type of the UVM-side phases. Defaults to <int>.
// VMM2UVM   - UVM-to-VMM conversion policy class. Defaults to <uvi_vmm2uvm_tlm2_converter>.
// UVM2VMM   - VMM-to-UVM conversion policy class. Defaults to <uvi_uvm2vmm_tlm2_converter>.
// TIMESCALE - Timescale of the VMM timing annotation. Defaults to ~1ps~.
//
// Although this adapter is a <uvm_component>, it cannot be instantiated directly.
// The VMM initiator socket is connected to the corresponding UVM target socket
// using the <do_connect()> method.
// That method instantiates the adapter internally.
//
//| class my_env extends uvm_env;
//|    vmm_vip init;
//|    uvm_vip trgt;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       init = new("init", this);
//|       trgt = new("trgt", this);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.conect_phase(phase);
//|       uvi_vmm2uvm_tlm2_nb::do_connect(init.skt, trgt.skt);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_vmm2uvm_tlm2_nb #(type VMM_TR = int,
                            type VMM_PH = int,
                            type UVM_TR = int,
                            type UVM_PH = int,
                            type VMM2UVM = uvi_vmm2uvm_tlm2_converter,
                            type UVM2VMM = uvi_uvm2vmm_tlm2_converter,
                            realtime TIMESCALE = 1ps) extends uvm_component;

   typedef uvi_vmm2uvm_tlm2_nb#(VMM_TR, VMM_PH, UVM_TR, UVM_PH,
                                VMM2UVM, UVM2VMM, TIMESCALE) this_type;
   
   // VMM export which is used to connect to user's VMM port.
   local vmm_tlm_nb_transport_export#(this_type, VMM_TR) vmm_trgt_nb_socket;

   // UVM initiator socket which is used to connect to user's UVM target socket.
   local uvm_tlm_nb_initiator_socket #(this_type, UVM_TR) uvm_init_nb_socket;
   
   // VMM log required to for messages from adapter
   vmm_log log;

   // Constructor is local to prevent direct instantiation
   //
   //local function new(string name="", uvm_component parent = null);
   function new(string name="", uvm_component parent = null);
      super.new(name, parent);
      log = new($psprintf("%s_log",name), get_full_name());
      vmm_trgt_nb_socket = new(this, "vmm_trgt_nb_socket");
      uvm_init_nb_socket = new ("uvm_init_nb_socket" , this);
   endfunction

   local function vmm_tlm::sync_e vmm_sync(uvm_tlm_sync_e sync);
      case (sync)
       UVM_TLM_ACCEPTED : return vmm_tlm::TLM_ACCEPTED;
       UVM_TLM_UPDATED  : return vmm_tlm::TLM_UPDATED;
       UVM_TLM_COMPLETED: return vmm_tlm::TLM_COMPLETED;
      endcase
   endfunction

   local function uvm_tlm_sync_e uvm_sync(vmm_tlm::sync_e vsync);
      case (vsync)
       vmm_tlm::TLM_ACCEPTED : return UVM_TLM_ACCEPTED;
       vmm_tlm::TLM_UPDATED  : return UVM_TLM_UPDATED;
       vmm_tlm::TLM_COMPLETED: return UVM_TLM_COMPLETED;
      endcase
   endfunction


   // Function: do_connect
   //
   // Connects the specified VMM non-blocking initiator socket with
   // the specified UVM non-blocking nonblocking target socket.

   static function void do_connect(vmm_tlm_port_base #(VMM_TR, VMM_PH) init_socket,
                                uvm_port_base#(uvm_tlm_if#(UVM_TR, UVM_PH)) trgt_socket);
      this_type m_adapter;
      static int num_inst = 0;
      uvi_ok_to_create_in_connect cb = new();                          
      uvm_report_cb::add(null,cb,UVM_PREPEND);

      m_adapter = new($psprintf("VMM2UVM_NB%d",num_inst));                      
      num_inst = num_inst + 1;
      if (init_socket == null) begin
`ifdef UVM_ON_TOP
         $display( "NULL initiator specified to uvi_vmm2uvm_tlm2_nb::do_connect()");
         //`uvm_error("NULLINIT", "NULL initiator specified to uvi_vmm2uvm_tlm2_nb::do_connect()")
`else
         `vmm_error(m_adapter.log, "NULL initiator specified to uvi_vmm2uvm_tlm2_nb::do_connect()");
`endif   
      end

      if (trgt_socket == null) begin
`ifdef UVM_ON_TOP
         $display("NULL target specified to uvi_vmm2uvm_tlm2_nb::do_connect()");
         //`uvm_error("NULLTRGT", "NULL target specified to uvi_vmm2uvm_tlm2_nb::do_connect()")
`else
         `vmm_error(m_adapter.log, "NULL target specified to uvi_vmm2uvm_tlm2_nb::do_connect()");
`endif   
      end
      
      init_socket.tlm_bind(m_adapter.vmm_trgt_nb_socket);
      m_adapter.uvm_init_nb_socket.connect(trgt_socket);
      uvm_report_cb::delete(null, cb);
   endfunction
  

   local VMM_TR vmm_item[UVM_TR]; // Assoc array indexed by uvm_item
   local UVM_TR uvm_item[VMM_TR]; // Assoc array indexed by vmm_item

   
   // Function- nb_transport_fw
   //
   // Forward the FW() call to UVM
   // and return the response back to VMM

   function vmm_tlm::sync_e nb_transport_fw(int id=-1, VMM_TR item, ref VMM_PH phase,
                                          ref int delay);
      uvm_tlm_time u_delay = new;
      UVM_PH u_phase;
      uvm_tlm_sync_e u_sync;
      UVM_TR u_item;
     
      if(uvm_item.exists(item))
         u_item = uvm_item[item];
      
      u_item = VMM2UVM::convert(item, u_item);
      vmm_item[u_item] = item;
      uvm_item[item] = u_item;
      
      u_delay.set_abstime(delay, TIMESCALE);
      u_phase = VMM2UVM::convert_phase(phase);
      
      // Call VMM nb_transport_fw
      u_sync = uvm_init_nb_socket.nb_transport_fw(u_item,u_phase, u_delay);
      
      item = UVM2VMM::convert(u_item, item);
      delay = u_delay.get_abstime(TIMESCALE);
      phase = UVM2VMM::convert_phase(u_phase);

      // Remove from assoc array if COMPLETEDD
      if(u_sync == UVM_TLM_COMPLETED) begin
         vmm_item.delete(u_item);
         uvm_item.delete(item);
      end
      
      return vmm_sync(u_sync);

   endfunction

   
   // Function- nb_transport_bw
   //
   // Forward the BW() call back to VMM
   // and return the response back to UVM

   function uvm_tlm_sync_e nb_transport_bw(UVM_TR item,
                                            ref UVM_PH phase,
                                            input uvm_tlm_time delay);
      int v_delay;
      VMM_PH v_phase;
      vmm_tlm::sync_e v_sync;
      VMM_TR v_item;
      
      if(vmm_item.exists(item))
         v_item = vmm_item[item];
      else
`ifdef UVM_ON_TOP
         //`uvm_error("ILLTR", "Illegal transaction sent to uvi_vmm2uvm_tlm2_nb::nb_transport_bw()")
         $display("ILLTR, Illegal transaction sent to uvi_vmm2uvm_tlm2_nb::nb_transport_bw()");
`else
         `vmm_error(log, "Illegal transaction sent to uvi_vmm2uvm_tlm2_nb::nb_transport_bw()");
`endif   

      v_item = UVM2VMM::convert(item, v_item);
      v_delay = delay.get_abstime(TIMESCALE);
      v_phase = UVM2VMM::convert_phase(phase);
      
      // Call VMM nb_transport_fw
      v_sync = vmm_trgt_nb_socket.nb_transport_bw(v_item, v_phase, v_delay);
      
      item = VMM2UVM::convert(v_item, item);
      delay.set_abstime(v_delay, TIMESCALE);
      phase = VMM2UVM::convert_phase(v_phase);

      // Remove from assoc array if COMPLETED
      if(v_sync == vmm_tlm::TLM_COMPLETED) begin
         vmm_item.delete(item);
         uvm_item.delete(v_item);
      end
      
      return uvm_sync(v_sync);
   endfunction
endclass
`endif	  
   

//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------


//
// Title: VMM Callback Adapters
//
// When connecting a VMM callback to a UVM interface,
// the correct adapter must be used according to the type of UVM interface.
//
// UVM analysis port   - Use the <uvi_vmm_cb2uvm_ap> adapter.
// UVM event           - Use the <uvi_vmm_cb2uvm_event> adapter.
// UVM calbbacks       - Use the <uvi_vmm_cb2uvm_cb> pattern.
//
//

//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_cb2uvm_ap
//
//------------------------------------------------------------------------------
//
// The uvi_vmm_cb2uvm_ap adapter receives VMM data supplied by a callback method,
// converts it to UVM, then broadcasts it to all components
// connected to its <analysis_port>
//
// VMM_CB    - Type of the VMM callback facade class.
//             Will be used as the base class for the adapter.
// VMM_TR    - Type of the VMM-side transaction.
// UVM_TR    - Type of the UVM-side transaction.
// VMM2UVM   - VMM-to-UVM conversion policy class.
//
// To connect a VMM callback to a UVM analysis port,
// first extend the adapter class,
// specifying the type of the callback class to be extended as the ~VMM_CB~ parameters.
// Implement the desired callback method to call the <write> method in the adapter,
// passing as argument the VMM-side transaction.
//
//| class my_cb extends uvi_vmm_cb2uvm_ap#(vmm_mon_cbs, vmm_tr, uvm_tr, vmm2uvm_tr);
//|    virtual function void post_observed(vmm_mon xactor, vmm_tr tr);
//|       write(tr);
//|    endfunction
//| endclass
//
// In the environment, instantiate the callback extension and register it
// with the relevant transactor instance.
// Then connect the analysis port in the adapter
// to any number of analysis exports.
//
//| class my_env extends uvm_env;
//|    vmm_vip mon;
//|    uvm_sb  sb;
//|    my_cb   cb2ap;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon");
//|       sb  = new("sb", this);
//|       cb2ap = new();
//|       mon.append_callbacks(cb2ap);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       cb2ap.analysys_port.connect(sb.analysis_export);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_vmm_cb2uvm_ap #(type VMM_CB=int, VMM_TR=int, UVM_TR=int, VMM2UVM=int) 
        extends VMM_CB;


  // Port: analysis_port
  //
  // The adapter writes converted VMM data supplied by the <write> method
  //
  // Components connected to this analysis port via an analysis export will
  // receive these transactions in a non-blocking fashion. If a receiver can
  // not immediately accept broadcast transactions, it must buffer them.

  uvm_analysis_port #(UVM_TR) analysis_port;


  // Function: write
  //
  // This method must be called in a callback method extendion.
  // It will convert the VMM data given to its UVM counterpart, then send
  // it out the <analysis_port> to any connected subscribers.

  virtual function void write(VMM_TR vmm_in);
    UVM_TR uvm_out;
    uvm_out = null;
    if (vmm_in != null) uvm_out = VMM2UVM::convert(vmm_in);
    this.analysis_port.write(uvm_out);
  endfunction

endclass


//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_cb2uvm_event
//
//------------------------------------------------------------------------------
//
// The uvi_vmm_cb2uvm_event adapter receives VMM data supplied by a callback method,
// converts it to UVM, then triggers a specified <uvm_event> with the converted UVM data.
//
// VMM_CB    - Type of the VMM callback facade class.
//             Will be used as the base class for the adapter.
//
// The following class parameters must be specified if a VMM transaction
// is forwarded to the UVM event.
//
// VMM_TR    - Type of the VMM-side transaction. Optional.
// UVM_TR    - Type of the UVM-side transaction. Optional.
// VMM2UVM   - VMM-to-UVM conversion policy class. Optional.
//
// To connect a VMM callback to a UVM event,
// first extend the adapter class,
// specifying the type of the callback class to be extended as the ~VMM_CB~ parameters.
// Implement the desired callback method to call the <trigger> method in the adapter,
// optionally passing as argument the VMM-side transaction.
//
//| class my_cb extends uvi_vmm_cb2uvm_event#(vmm_mon_cbs, vmm_tr, uvm_tr, vmm2uvm_tr);
//|    virtual function void post_observed(vmm_mon xactor, vmm_tr tr);
//|       trigger(tr);
//|    endfunction
//| endclass
//
// In the environment, instantiate the callback extension and register it
// with the relevant transactor instance.
// Then connect the <uvm_event> by assigning its handle to the <ev> variable.
//
//| class my_env extends uvm_env;
//|    vmm_vip mon;
//|    uvm_sb  sb;
//|    my_cb   cb2ap;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon");
//|       sb  = new("sb", this);
//|       cb2ap = new();
//|       mon.append_callbacks(cb2ap);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       cb2ap.ev = sb.ev;
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_vmm_cb2uvm_event #(type VMM_CB=int,
                             VMM_TR=vmm_data,
                             UVM_TR=uvm_object,
                             VMM2UVM=uvi_converter#(VMM_TR, UVM_TR)) 
        extends VMM_CB;


  // Variable: ev
  //
  // The event triggered by the callback method.

  uvm_event ev;


  // Function: trigger
  //
  // This method must be called in a callback method extendion.
  // It will convert the VMM data given to its UVM counterpart,
  // then trigger the <ev> event with the converted transaction.

  virtual function void trigger(VMM_TR vmm_in = null);
    UVM_TR uvm_out;
    if (ev == null) return;
    uvm_out = null;
    if (vmm_in != null) uvm_out = VMM2UVM::convert(vmm_in);
    this.ev.trigger(uvm_out);
  endfunction

endclass



//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_cb2uvm_cb
//
//------------------------------------------------------------------------------
//
// The uvi_vmm_cb2uvm_cb pattern is used to create a set of UVM callback methods
// equivalent to the VMM callbacks methods.
// Because it is a ~pattern~, it is not a pre-defined component
// that is simply instantiated, configured and connected.
// Instead, it is a coding pattern that needs to be adapted to the particulars
// of the VMM callback methods that need to be adapted to UVM.
//
// When using an ~interconnected~ interoperability model,
// it is not necessary to adapt the VMM callbacks into corresponding UVM callbacks.
// In such a model, users know they are using a VMM component
// and will extend and register the VMM callbacks directly,
// as shown with the <uvi_vmm_cb2uvm_ap> and <uvi_vmm_cb2uvm_ap> adapters above.
//
// However, if the goal is to encapsulate a VMM component in a UVM layer
// to hide from the user the fact that a VMM component is being used,
// it will be necessary to provide the same callbacks in the UVM wrapper
// to allow users access to the full capabilities of the underlying VMM component.
// In such a model, other adapters would also be used to connect the
// other interfaces of the VMM component to suitable interfaces on the UVM wrapper.
//
// First, a UVM callback facade must be created with the same callback methods
// found in the VMM callback facade.
//
// VMM Callback Facade:
//
//| class vmm_vip_cbs extends vmm_xactor_callbacks;
//|    task pre_tr(vmm_vip xact, vmm_tr tr);
//|    endtask
//|
//|    function void post_tr(vmm_vip xact, vmm_tr tr);
//|    endfunction
//| endclass
//
// Corresponding UVM Callback Facade:
//
//| class uvm_vip_cbs extends uvm_callback;
//|    function new(string name = "uvm_vip_cbs");
//|       new(name);
//|    endfunction
//|
//|    task pre_tr(uvm_vip xact, uvm_tr tr);
//|    endtask
//|
//|    function void post_tr(uvm_vip xact, uvm_tr tr);
//|    endfunction
//| endclass
//
// Associate the UVM callback facade with the UVM wrapper component
// using the <`uvm_register_cb> macro.
// UVM callback extensions will thus be registered with the UVM wrapper component.
// It is also a good idea to ~typedef~ a callback pool class
// to provide a simpler interface for the callback registration API.
//
//| class uvm_vip extends uvm_component;
//|   ...
//|   vmm_vip vip;
//|   `uvm_register_cb(uvm_vip, uvm_vip_cbs)
//|   ...
//| endclass
//|
//| typedef uvm_callbacks#(uvm_vip, uvm_vip_cbs) uvm_vip_cb_pool;
//
// Implement each of the VMM callback method to invoke the corresponding
// UVM callback method, performing the necessary data conversions before
// and after the call.
// It is necessary to have a reference to the UVM vip
// where the UVM callbacks will be called.
// That reference is best supplied via a constructor argument.
//
// Note that it is not possible to use the UVM <Callback Macros>
// as they require that they be used within the UVM component
// associated with the callback calls.
// Therefore, the <uvm_callback_iter> iterator must be used.
//
//| class vmm_vip_cbs2uvm_vip_cbs extends vmm_vip_cbs;
//|    local uvm_vip m_vip;
//|
//|    function new(uvm_vip vip);
//|       m_vip = vip;
//|    endfunction
//|
//|    task pre_tr(vmm_vip xact, vmm_tr tr);
//|       uvm_callback_iter#(uvm_vip, uvm_vip_cbs) iter = new(m_vip);
//|       uvm_tr u_tr = vmm2uvm_tr::convert(tr);
//|       for (uvm_vip_cbs cb = iter.first(); cb != null; cb = iter.next()) begin
//|          cb.pre_tr(m_vip, u_tr);
//|       end
//|       void'(uvm2vmm_tr::convert(u_tr, tr));
//|    endtask
//|
//|    function void post_tr(vmm_vip xact, vmm_tr tr);
//|       uvm_callback_iter#(uvm_vip, uvm_vip_cbs) iter = new(m_vip);
//|       uvm_tr u_tr = vmm2uvm_tr::convert(tr);
//|       for (uvm_vip_cbs cb = iter.first(); cb != null; cb = iter.next()) begin
//|          cb.post_tr(m_vip, u_tr);
//|       end
//|    endfunction
//| endclass
//
// Finally, the UVM wrapper instantiates the VMM-to-UVM callback extension
// and registers it with the VMM component.
//
//| class uvm_vip extends uvm_component;
//|   ...
//|   vmm_vip vip;
//|
//|   function void build_phase(uvm_phase phase);
//|      super.build_phase(phase);
//|      vip = new("vip");
//|      ...
//|   endfunction
//|
//|   function void connect_phase(uvm_phase phase);
//|      super.connect_phase(phase);
//|      vmm_vip_cbs2uvm_vip_cbs v2u = new(this);
//|      vip.append_callbacks(v2u);
//|      ...
//|   endfunction
//|   ...
//| endclass
//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------


//
// Title: VMM Notification Adapter
//
// When connecting a VMM notificiation to a UVM interface,
// the correct adapter must be used according to the type of UVM interface.
//
// UVM analysis port   - Use the <uvi_vmm_notify2uvm_ap> adapter.
// UVM event           - Use the <uvi_vmm_notify2uvm_event> adapter.
//
//

//------------------------------------------------------------------------------
//
// CLASS- vmm_watcher_cb
//
// Receives data via notification status, then forwards data to the configured
// VMM component. The type of the VMM component is specified in the type
// parameter, and the instance of a VMM component of that type is specified
// in the constructor argument.
// 
//------------------------------------------------------------------------------

class vmm_watcher_cb #(type WATCHER=int) extends vmm_notify_callbacks;

  WATCHER watcher;

  // Function- new
  //
  // Creates a new callback instance that forwards transactions to the
  // object specified in the constructor argument.

  function new (WATCHER watcher);
    this.watcher=watcher;
  endfunction

  // Function- indicated
  //
  // When the notification associated with this callback is indicated, this
  // function is called, which forwards the received data to the target
  // component.

  virtual function void indicated(vmm_data status);
    watcher.indicated(status);
  endfunction

endclass


//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_notify2uvm_ap
//
//------------------------------------------------------------------------------
//
// The uvi_vmm_notify2uvm_ap adapter receives VMM data supplied as status by a vmm_notify
// event notification, converts it to UVM, then broadcasts it to all components
// connected to its <analysis_port>
//
// VMM_TR    - Type of the VMM-side transaction.
// UVM_TR    - Type of the UVM-side transaction.
// VMM2UVM   - VMM-to-UVM conversion policy class.
//
// To connect a VMM notification to a UVM analysis port,
// instantiate the adapter, specifying the instance of the <vmm_notify>
// and notification ID that is to be forwarded to the analysis port.
// Then connect the analysis port in the adapter
// to any number of analysis exports.
//
//| class my_env extends uvm_env;
//|    vmm_vip mon;
//|    uvm_sb  sb;
//|    uvi_vmm_notify2uvm_ap#(vmm_tr, uvm_tr, vmm2uvm_tr) ntfy2ap;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon");
//|       sb  = new("sb", this);
//|       ntfy2ap = new("ntfy2ap", this, mon.notify, vmm_mon::OBSERVED);
//|    endfunction
//|
//|    virtual function void connect_phase(uvm_phase phase);
//|       super.connect_phase(phase);
//|       ntfy2ap.analysys_port.connect(sb.analysis_export);
//|    endfunction
//|
//| endclass
//
// See also <uvi_notify2analysis example>.
//
//------------------------------------------------------------------------------

class uvi_vmm_notify2uvm_ap #(type VMM_TR=int, UVM_TR=int, VMM2UVM=int) 
        extends uvm_component;

  typedef uvi_vmm_notify2uvm_ap #(VMM_TR,UVM_TR,VMM2UVM) this_type;

  `uvm_component_param_utils(this_type)


  // Port: analysis_port
  //
  // The adapter writes converted VMM data supplied by a vmm_notify event
  // notification to this analysis_port. 
  //
  // Components connected to this analysis port via an analysis export will
  // receive these transactions in a non-blocking fashion. If a receiver can
  // not immediately accept broadcast transactions, it must buffer them.

  uvm_analysis_port #(UVM_TR) analysis_port;


  // Variable: notify
  //
  // The notify object that this adapter uses to register a callback on the
  // <RECEIVED> event notification.

  vmm_notify notify;


  // Variable: RECEIVED
  //
  // The notification id that, when indicated, will provide data to
  // a callback registered by this adapter. The callback will forward
  // the data to the <indicated> method.

  int RECEIVED;


  // Function: new
  //
  // Creates a new notify-to-analysis adapter with the given ~name~ and
  // optional ~parent~; the ~notify~ and ~notification_id~ together
  // specify the notification instance that this adapter will be
  // sensitive to.
  //
  // If the ~notify~ handle is not supplied or null, the adapter will
  // create one and assign it to the <notify> property. If the 
  // ~notification_id~ is not provided, the adapter will configure a
  // ONE_SHOT notification and assign it to the <RECEIVED> property. 

  function  new (string name, uvm_component parent=null,
                vmm_notify notify=null, int notification_id=-1);

    vmm_watcher_cb #(this_type) cb;

    super.new(name,parent);

    analysis_port = new("analysis_port",this);

    if (notify == null) begin
      vmm_log log;
      log = new("vmm_log","uvi_notify2analysis_log");
      notify = new(log);
    end

    this.notify = notify;

    if (notification_id == -1)
      notification_id = notify.configure(-1,vmm_notify::ONE_SHOT);
    else
      if (notify.is_configured(notification_id) != vmm_notify::ONE_SHOT)
        uvm_report_fatal("Bad Notification ID",
          $psprintf({"Notification id %0d not configured, ",
                    "or not configured as ONE_SHOT"}, notification_id));
    this.RECEIVED = notification_id;

    cb = new(this);
    notify.append_callback(RECEIVED, cb);

  endfunction


  // Function- indicated
  //
  // Called back when the <RECEIVED> notification in the <notify>
  // object is indicated, this method converts the VMM data given
  // in the ~status~ argument to its UVM counterpart, then send
  // it out the <analysis_port> to any connected subscribers.

  virtual function void indicated(vmm_data status);
    UVM_TR uvm_out;
    VMM_TR vmm_in;
    uvm_out = null;
    if (status != null) begin
       assert ($cast(vmm_in,status));
       uvm_out = VMM2UVM::convert(vmm_in);
    end
    analysis_port.write(uvm_out);
  endfunction

endclass


//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_notify2uvm_event
//
//------------------------------------------------------------------------------
//
// The uvi_vmm_notify2uvm_event adapter triggers a <uvm_event> whenever
// a VMM notification is indicated.
// If status information is attached to the notification indication,
// it is translated to UVM and supplied to the event trigger.
// The following class parameters must be specified if a notification status
// is forwarded to the UVM event.
//
// VMM_TR    - Type of the VMM-side transaction. Optional.
// UVM_TR    - Type of the UVM-side transaction. Optional.
// VMM2UVM   - VMM-to-UVM conversion policy class. Optional.
//
// To connect a VMM notification to a UVM event,
// instantiate the adapter, specifying <uvm_event> instance and
// the instance of the <vmm_notify>
// and notification ID that is to be forwarded to the event.
//
//| class my_env extends uvm_env;
//|    vmm_vip mon;
//|    uvm_sb  sb;
//|    uvi_vmm_notify2uvm_event#(vmm_tr, uvm_tr, vmm2uvm_tr) ntfy2ev;
//|
//|    virtual function void build_phase(uvm_phase phase);
//|       super.build_phase(phase);
//|       mon = new("mon");
//|       sb  = new("sb", this);
//|       ntfy2ev = new("ntfy2ev", this, sb.ev, mon.notify, vmm_mon::OBSERVED);
//|    endfunction
//|
//| endclass
//
//------------------------------------------------------------------------------

class uvi_vmm_notify2uvm_event #(type VMM_TR=vmm_data, UVM_TR=uvm_object,
                                 VMM2UVM=uvi_converter#(VMM_TR, UVM_TR)) 
        extends uvm_component;

  typedef uvi_vmm_notify2uvm_event #(VMM_TR,UVM_TR,VMM2UVM) this_type;

  `uvm_component_param_utils(this_type)


  // Variable: ev
  //
  // The <uvm_event> that is triggered whenever the VMM notification is indicated.

  uvm_event ev;


  // Variable: notify
  //
  // The notify object that this adapter uses to register a callback on the
  // <RECEIVED> event notification.

  vmm_notify notify;


  // Variable: RECEIVED
  //
  // The notification id that, when indicated, will provide data to
  // a callback registered by this adapter. The callback will forward
  // the data to the <indicated> method.

  int RECEIVED;


  // Function: new
  //
  // Creates a new notify-to-event adapter with the given ~name~ and
  // optional ~parent~; the ~notify~ and ~notification_id~ together
  // specify the notification instance that this adapter will be
  // sensitive to.
  //
  // If the ~ev~ handle is not supplied or ~null~, the adapter will
  // create one and assign it to the <ev> property.
  // If the ~notify~ handle is not supplied or null, the adapter will
  // create one and assign it to the <notify> property. If the 
  // ~notification_id~ is not provided, the adapter will configure a
  // ONE_SHOT notification and assign it to the <RECEIVED> property. 

  function  new (string name, uvm_component parent=null,
                 uvm_event ev = null,
                vmm_notify notify=null, int notification_id=-1);

    vmm_watcher_cb #(this_type) cb;

    super.new(name, parent);

    if (ev == null) ev = new("uvi_notify2event");
    this.ev = ev;
     
    if (notify == null) begin
      vmm_log log;
      log = new("vmm_log","uvi_notify2analysis_log");
      notify = new(log);
    end

    this.notify = notify;

    if (notification_id == -1)
      notification_id = notify.configure(-1,vmm_notify::ONE_SHOT);
    else
      if (notify.is_configured(notification_id) != vmm_notify::ONE_SHOT)
        uvm_report_fatal("Bad Notification ID",
          $psprintf({"Notification id %0d not configured, ",
                    "or not configured as ONE_SHOT"}, notification_id));
    this.RECEIVED = notification_id;

    cb = new(this);
    notify.append_callback(RECEIVED, cb);

  endfunction


  // Function- indicated
  //
  // Called back when the <RECEIVED> notification in the <notify>
  // object is indicated, this method converts the VMM data given
  // in the ~status~ argument to its UVM counterpart, then send
  // it out the <analysis_port> to any connected subscribers.

  virtual function void indicated(vmm_data status);
    UVM_TR uvm_out;
    VMM_TR vmm_in;
    if (status == null)
      return;
    assert ($cast(vmm_in,status));
    uvm_out = VMM2UVM::convert(vmm_in);
    this.ev.trigger(uvm_out);
  endfunction

endclass


//------------------------------------------------------------------------------
// Copyright 2008 Mentor Graphics Corporation
// Copyright 2010-2011 Synopsys, Inc.
//
// All Rights Reserved Worldwide
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.  You may obtain
// a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//------------------------------------------------------------------------------


//
// Title: VMM Channel Adapters
//
// When connecting a VMM channel to a UVM interface,
// the correct adapter must be used according to the type of UVM interface.
//
// TLM1                - Use the <uvi_vmm_channel2uvm_tlm1> adapter.
// UVM analysis export - Use the <uvi_vmm_channel2uvm_ap> adapter.
//

//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_channel2uvm_tlm1
//
//------------------------------------------------------------------------------
//
// Use this class to connect a VMM channel-based producer to an UVM TLM1 consumer.
//
// UVM TLM1 and VMM channels can implement many different response-delivery
// models:
//
// - does not return a response
//
// - embeds a response in the original request transaction, which is available
//   to a requester that holds a handle to the original request.
//
// - returns a response in a separate channel/port
//
// The adapter can accommodate VMM channel-based producers and UVM TLM1 consumers
// that have similar responses characteristics.
// For example, it is possible to connect a VMM producer that expects a
// reponse via a separate channel with a UVM TLM1 consumer that annotates
// the response in the original request.
// However, it is not possible to connect a VMM producer that expects a response
// with a UVM consumer that does not provide one or provides multiple responses
// for the same request.
//
// Communication is established by connecting the adapter to the
// channel(s) of the VMM producer and
// to the UVM consumer using the appropriate ports and exports on the adapter.
//
// To use this adapter, the integrator instantiates an VMM producer, an UVM
// consumer, and an adapter whose parameter values correspond
// to the VMM and UVM data types used by the producer and consumer and the
// converter types used to translate in one or both directions.
//
// The adapter has the following
// parameters:
//
// VMM_REQ     - Type of the VMM transaction request descriptor class (required)
// UVM_REQ     - Type of the UVM transaction request descriptor class (required)
// VMM2UVM_REQ - Conversion policy class from VMM to UVM transaction request (required)
// UVM_RSP     - Type of the UVM transaction response descriptor class. Defaults to UVM_REQ.
// VMM_RSP     - Type of the VMM transaction response descriptor class. Defaults to VMM_REQ.
// UVM2VMM_RSP - Conversion policy class from UVM to VMM transaction response (optional)
// UVM_MATCH_REQ_RSP - Policy class to match UVM TLM1 responses with requests. Defaults to <uvi_match_uvm_id>.
//
// The integrator may use the default vmm_channels created by the VMM producer
// or adapter,
// or explicitly instantiate a request vmm_channel and a
// response vmm_channel, if the VMM producer uses one, and specify them
// to the adapter constructor and producer constructors.
//
// Example:
//
//|
//| class vmm2uvm_tr;
//|    static function uvm_tr convert(vmm_tr in, uvm_tr to = null);
//|       ...
//|    endfunction
//| endclass
//|
//| class uvm2vmm_tr;
//|    static function vmm_tr convert(uvm_tr in, vmm_tr to = null);
//|       ...
//|    endfunction
//| endclass
//|
//| class my_env extends uvm_env;
//|   vmm_scenario_gen       gen;
//|   uvm_drv                drv;
//|   uvi_vmm_channel2#uvm_tlm1(.VMM_REQ(vmm_tr), .UVM_REQ(uvm_tr),
//|                             .VMM2UVM_REQ(vmm2uvm_tr), .UVM2VMM_RSP(uvm2vmm_tr))
//|                            gen2drv;
//|   
//|   function void build_phase(uvm_phase phase);
//|      super.build_phase(phase);
//|
//|      gen = new("sqr");
//|      drv = new("drv", this);
//|      gen2drv = new("gen2drv", this, gen.out_chan);
//|   endfunction
//|
//|   function void connect_phase(uvm_phase phase);
//|      super.connect_phase(phase);
//|      drv.seq_item_port.connect(gen2drv.seq_item_export);
//|   endfunction
//|endclass
//|
//
// Integrators of VMM-on-top environments need to instantiate the UVM consumer
// and adapter via an UVM container, or wrapper <uvm_component>. This wrapper
// component serves to provide the connect method needed to bind the UVM ports
// and exports.
//
// See also <uvi_channel2uvm_tlm example> and <uvi_channel2uvm_tlm seq_item example>.
//
//------------------------------------------------------------------------------

typedef class uvi_match_uvm_id;
class uvi_vmm_channel2uvm_tlm1 #(type VMM_REQ     = int,
                                 UVM_REQ     = int,
                                 VMM2UVM_REQ = int,
                                 UVM_RSP     = UVM_REQ,
                                 VMM_RSP     = VMM_REQ,
                                 UVM2VMM_RSP = uvi_converter #(UVM_RSP,VMM_RSP),
                                 UVM_MATCH_REQ_RSP=uvi_match_uvm_id)
   extends uvm_component;

   typedef uvi_vmm_channel2uvm_tlm1 #(VMM_REQ, UVM_REQ, VMM2UVM_REQ,
                                      UVM_RSP, VMM_RSP, UVM2VMM_RSP,
                                      UVM_MATCH_REQ_RSP) this_type;

   `uvm_component_param_utils(this_type)


   // Function: new
   //
   // Creates an instance of this adaptor
   //
   // name     - specifies the instance name.
   //
   // parent   - specifies the parent uvm_component, if any.
   //
   // req_chan - the request vmm_channel instance. If not specified,
   //            a channel instance is implciitly created and assigned
   //            to the <req_chan> variable.
   //
   // rsp_chan - the response vmm_channel instance. If not specified
   //            and no channel instance is specified using the <rsp_chan>
   //            variable, it is assumed that the VMM producer does not
   //            use a response channel and that the response is annotated
   //            in the original request.
   //
   // rsp_is_req - Initialize the <rsp_is_req> variable.
   //

   function new (string name="uvi_vmm_channel2uvm_tlm1",
                 uvm_component parent=null,
                 vmm_channel_typed #(VMM_REQ) req_chan=null,
                 vmm_channel_typed #(VMM_RSP) rsp_chan=null,
                 bit rsp_is_req=1,
                 int unsigned max_pending_req=100);
      super.new(name,parent);
      // For active UVM producers
      seq_item_export = new("seq_item_export",this);
      get_peek_export = new("get_peek_export",this);
      response_export = new("response_export",this);
      put_export      = new("put_export",this);
      slave_export    = new("slave_export",this);

      // For passive UVM producers
      blocking_put_port       = new("blocking_put_port",this,0);
      blocking_transport_port = new("blocking_transport_port",this,0);
      blocking_master_port    = new("blocking_master_port",this,0);

      request_ap    = new("request_ap",this);
      response_ap   = new("response_ap",this);

      if (req_chan == null)
        req_chan = new("Channel-to-TLM Adapter Out Channel",name);
      this.req_chan = req_chan;
      this.rsp_chan = rsp_chan;
      this.rsp_is_req = rsp_is_req;
      this.max_pending_req = max_pending_req;
   endfunction

    virtual function void disable_auto_item_recording();
    endfunction

     virtual function bit is_auto_item_recording_enabled();
     endfunction

   //
   // Group: VMM Consumer
   //

   // Variable: req_chan
   //
   // Handle to the request channel instance being adapted.

   vmm_channel_typed #(VMM_REQ) req_chan;


   // Variable: rsp_chan
   //
   // Handle to the response channel instance being adapted.
   // If ~null~, the VMM producer does not use a response channel.

   vmm_channel_typed #(VMM_RSP) rsp_chan;


   // Variable: rsp_is_req
   //
   // When TRUE, indicates that the VMM producer expects that the response
   // is annotated in the same object as the request.
   // This variable is ignored when a response channel is specified.
   //
   // This variable can be specified in a <new> constructor argument, or set
   // via the #(int) configuration variable ~rsp_is_req~.

   protected bit rsp_is_req = 1;


   //
   // Group: UVM Consumer
   //
   // Only one UVM consumer may be connected to the adapter,
   // using the appropriate ports for the producer's response model.
   //

   // Port: seq_item_export
   //
   // This bidirectional port is used to connect to a <uvm_driver> or any
   // other component providing a <uvm_seq_item_port>.
   uvm_seq_item_pull_imp #(UVM_REQ, UVM_RSP, this_type) seq_item_export;

   // Port: get_peek_export
   //
   // This unidirectional port is used to send requests to a passive
   // UVM consumer with a get_peek export.
   // No response is provided back by the UVM consumer.
   uvm_get_peek_imp #(UVM_REQ, this_type) get_peek_export;

   // Port: response_export
   //
   // For UVM consumers returning responses via an analysis port.
   uvm_analysis_imp #(UVM_RSP, this_type) response_export;

   // Port: put_export
   //
   // This port is used to send transactions to a UVM consumer
   // that utilizes a blocking or non-blocking ~put~ interface.
   // No response is provided back by the UVM consumer.
   uvm_put_imp #(UVM_RSP, this_type) put_export;

   // Port: slave_export
   //
   // This bidirectional port is used to send transaction requests to and receive
   // responses from a passive UVM consumer utilizing a blocking slave interface.
   uvm_slave_imp #(UVM_REQ, UVM_RSP, this_type) slave_export;

   // Port: blocking_put_port
   //
   // This port is used to deliver responses from a UVM consumer that
   // provides responses from a blocking put interface.
   uvm_blocking_put_port #(UVM_RSP) blocking_put_port;

   // Port: blocking_transport_port
   //
   // This bidirectional export is used to deliver requests to and receive
   // responses from a UVM consumer that utilizes a blocking transport interface.
   uvm_blocking_transport_port #(UVM_REQ, UVM_RSP) blocking_transport_port;


   // Port: blocking_master_port
   //
   // This bidirectional export is used to deliver requests to and receive
   // responses from an UVM consumer that utilizes a blocking or non-blocking
   // ~master~ interface.
    uvm_blocking_master_port #(UVM_REQ, UVM_RSP) blocking_master_port;


   // Port: request_ap
   //
   // All requests are broadcast out to this analysis port after successful
   // extraction from the request vmm_channel.
   uvm_analysis_port #(UVM_REQ) request_ap;


   // Port: response_ap
   //
   // All responses sent to the response channel are broadcast out on this
   // analysis port.
   uvm_analysis_port #(UVM_RSP) response_ap;


   // Function- build
   //
   // Called as part of a predefined test flow, this function will retrieve
   // the configuration setting for the <rsp_is_req> that
   // this component's <req_chan> variable has been configured with a non-null

   virtual function void build();
      void'(uvm_config_db#(int)::get(this, "", "rsp_is_req", this.rsp_is_req));
   endfunction


   // Function- end_of_elaboration
   //
   // Called as part of a predefined test flow, this function will check that
   // this component's <req_chan> variable has been configured with a non-null
   // instance of a vmm_channel #(VMM).

   virtual function void end_of_elaboration();
     if (this.req_chan == null)
     `ifdef UVM_ON_TOP
       `uvm_fatal("Connection Error",
          "uvi_channel2uvm_tlm requires a request vmm_channel");
      `else
       `vmm_fatal(this.req_chan.log,
          "Connection Error uvi_channel2uvm_tlm requires a request vmm_channel");
      `endif
     if (this.rsp_chan != null && this.rsp_is_req)
      `ifdef UVM_ON_TOP
       `uvm_warning("Ignoring rsp_is_req bit",
          "rsp_is_req bit is ignored when a response channel is in use");
       `else
       `vmm_warning(this.rsp_chan.log, "Ignoring rsp_is_req bit rsp_is_req bit is ignored when a response channel is in use");
       `endif
   endfunction


   // Task- run
   //
   // Called as part of a predefined test flow, the run task forks a
   // process for getting requests from the request channel and sending
   // them to the UVM consumer connection via the blocking put port.

   virtual task run();

     // only if port is connected
     if (blocking_put_port.size()) begin
       fork
         auto_put();
       join_none
     end
     else if (blocking_transport_port.size()) begin
       fork
         auto_transport();
       join_none
     end
     else if (blocking_master_port.size()) begin
       fork
         auto_blocking_master();
       join_none
     end

   endtask


   // Function- get_type_name
   //
   // Returns the type name, i.e. "uvi_channel2uvm_tlm", of this
   // adapter.

   virtual function string get_type_name();
     return this.type_name;
   endfunction

   const static string type_name = "uvi_channel2uvm_tlm";


   local VMM_REQ vmm_req[$];

   local UVM_REQ uvm_req[$];


   local bit item_done_on_get = 1;


   // Variable: max_pending_requests
   //
   // Specifies the maximum number of requests that can be outstanding.
   // The adapter holds all outgoing requests in a queue for later
   // matching with incoming responses. A maximum exists to prevent
   // this queue from growing too large.
   int unsigned max_pending_req = 100;


   // Task- auto_put
   //
   // Used by this adapter to send transactions to passive UVM consumers.

   virtual task auto_put();
     UVM_REQ o_req;
     forever begin
       this.peek(o_req);
       this.blocking_put_port.put(o_req);
       this.item_done();
     end
   endtask


   // Task- auto_transport
   //
   // Used by this adapter to send transactions to passive UVM consumers.

   virtual task auto_transport();
     UVM_REQ o_req;
     UVM_RSP o_rsp;
     forever begin
       this.peek(o_req);
       this.blocking_transport_port.transport(o_req,o_rsp);
       this.item_done(o_rsp);
     end
   endtask


   // Task- auto_blocking_master
   //
   // Used by this adapter to send transactions to passive UVM consumers.

   virtual task auto_blocking_master();
     UVM_REQ o_req;
     UVM_RSP o_rsp;
     fork
       // requests
       forever begin
         this.peek(o_req);
         this.blocking_master_port.put(o_req);
         this.item_done_on_get = 0;
         this.item_done();
       end
       // responses
       forever begin
         this.blocking_master_port.get(o_rsp);
         this.item_done(o_rsp);
       end
     join_none
   endtask


   // Function- convert
   //
   //
   function void convert (VMM_REQ v_req, output UVM_REQ o_req);
     if ((vmm_req.size() > 0) && (vmm_req[$] == v_req)) begin
       // needed only if req data can change between successive calls to peek
       // t = VMM2UVM_REQ::convert(v_req,uvm_req[$]);
       o_req = uvm_req[$];
     end
     else begin
       if (vmm_req.size() >= max_pending_req) begin
         `ifdef UVM_ON_TOP
          `uvm_fatal("Pending Transactions",
                  $psprintf("Exceeded maximum number of %0d pending requests.",
                     max_pending_req));
         `else
         `vmm_fatal(this.req_chan.log, 
                  $psprintf("Pending Transactions","Exceeded maximum number of %0d pending requests.",
                     max_pending_req));
         `endif
         o_req = null;
         return;
       end
       o_req = VMM2UVM_REQ::convert(v_req);
       uvm_req.push_back(o_req);
       vmm_req.push_back(v_req);
     end
   endfunction



   // Task- get
   //
   // Gets and converts a request from the <req_chan> vmm_channel.

   virtual task get(output UVM_REQ o_req);
     vmm_data v_pop;

     this.peek(o_req);
     if (this.item_done_on_get)
       this.item_done();
     else
       req_chan.XgetX(v_pop);

     this.m_last_o_req = null;
   endtask

   local UVM_REQ m_last_o_req;

   // Function- can_get
   //
   // Returns 1 if a transactions is available to get, 0 otherwise.
   virtual function bit can_get();
     return !(this.req_chan.size() <= this.req_chan.empty_level() ||
              this.req_chan.is_locked(vmm_channel::SINK));
   endfunction
  

   // Function- try_get
   //
   // If a transactions is available to get, returns the transaction
   // in the ~o_req~ output argument, else returns 0.
   virtual function bit try_get(output UVM_REQ o_req);
     vmm_data v_base;
     VMM_REQ v_req;
     if (!can_get())
       return 0;
     this.m_last_o_req = null;
     v_base = req_chan.try_peek();
     assert($cast(v_req, v_base));
     if (this.item_done_on_get)
       this.item_done();
     return 1;
   endfunction



   // Task- peek
   //
   // Peeks (does not consume) and converts a request from the <req_chan>
   // vmm_channel.
   //
   // TO DISCUSS- cached transaction can change between peeks.
   virtual task peek(output UVM_REQ o_req);
     VMM_REQ v_req;
     if (this.m_last_o_req != null) begin
       o_req = m_last_o_req;
       return;
     end
     req_chan.peek(v_req);
     convert(v_req,o_req);
     this.m_last_o_req = o_req;
   endtask


   // Function- can_peek
   //
   // Returns 1 if a transaction is available in the <req_chan>, 0 otherwise.
   //
   virtual function bit can_peek();
     return this.can_get();
   endfunction


   // Function- try_peek
   //
   // If a request is available to peek from the <req_chan>, this function
   // peeks (does not consume) the transaction from the channel, converts,
   // and returns via the ~o_req~ output argument. Otherwise, returns 0.
   //
   // TO DISCUSS- cached transaction can change between peeks.
   virtual function bit try_peek(output UVM_REQ o_req);
     vmm_data v_base;
     VMM_REQ v_req;
     if (!can_peek())
       return 0;
     if (this.m_last_o_req != null) begin
       o_req = m_last_o_req;
       return 1;
     end
     v_base = req_chan.try_peek();
     assert($cast(v_req, v_base));
     convert(v_req,o_req);
     this.m_last_o_req = o_req;
     return 1;
   endfunction


   // Task- put
   //
   // Converts and sneaks a response to the <rsp_chan> vmm_channel, if defined.
   // If the <rsp_chan> is null, the response is dropped.

   virtual task put (UVM_RSP o_rsp);
     put_response(o_rsp);
   endtask

 
   // Function- can_put
   //
   // Always returns 1 (true) because responses are sneaked into the channel.

   virtual function bit can_put ();
     return 1;
   endfunction

 
   // Function- try_put
   //
   // Sneak the given response to the response channel, or copy the
   // response to the corresponding request if <rsp_is_req> is set. 

   virtual function bit try_put (UVM_RSP o_rsp);
     this.put_response(o_rsp);
     return 1;
   endfunction

 
   // Function- write
   //
   // Used by active UVM consumers to send back responses.

   virtual function void write(UVM_RSP o_rsp);
     this.put_response(o_rsp); 
   endfunction


   // seq_item_pull_export implementations

   // Task- get_next_item 
   // 
   // Peeks and converts a request from the <req_chan> vmm_channel. This task
   // behaves like a blocking peek operation; it blocks until an item is
   // available in the channel. When available, the transaction is peeked and
   // ~not consumed from the channel~. The request is consumed upon a call
   // <get> or <item_done>.
   //
   // A call to ~get_next_item~ must always be followed by a call to <get> or
   // <item_done> before calling ~get_next_item~ again.

   virtual task get_next_item(output UVM_REQ t);
     VMM_REQ req;
     req_chan.peek(req);
     if ((vmm_req.size() > 0 ) && (vmm_req[$] == req)) begin
       `ifdef UVM_ON_TOP
       `uvm_error("Trans In-Progress",
         "Get_next_item called twice without item_done or get in between");
       `else
       `vmm_error(this.req_chan.log, "Trans In-Progress  Get_next_item called twice without item_done or get in between");
       `endif
       t = null;
       return;
     end
     this.peek(t);
     this.m_last_o_req = null;
   endtask


  // Task- try_next_item
  //
  // Waits a number of delta cycles waiting for a request
  // transaction to arrive in the <req_chan> vmm_channel. If a request is
  // available after this time, it is peeked from the channel, converted,
  // and returned. If after this time a request is not yet available,
  // the task sets ~t~ to null and returns. This behavior is similar to
  // a blocking peek with a variable delta-cycle timeout.

  virtual task try_next_item (output UVM_REQ t);
    wait_for_sequences();
    if (!has_do_available()) begin
      t = null;
      return;
    end
    get_next_item(t);
  endtask


   // Function- put_response
   //
   // A non-blocking version of <put>, this function converts and sneaks 
   // the given response into the <rsp_chan> vmm_channel. If the <rsp_chan>
   // is null, the response is dropped.

   virtual function void put_response (UVM_RSP o_rsp);

     VMM_REQ v_req;
     VMM_RSP v_rsp;

     if (o_rsp == null) begin
       `ifdef UVM_ON_TOP
       `uvm_fatal("SQRPUT", "Driver put a null response");
       `else
       `vmm_fatal(this.req_chan.log, "SQRPUT Driver put a null response");
       `endif
     end
     else if (o_rsp.get_sequence_id() == -1) begin
       `ifdef UVM_ON_TOP
       `uvm_fatal("SQRPUT",
         "Response has invalid sequence_id");
       `else
       `vmm_fatal(this.req_chan.log, "SQRPUT Response has invalid sequence_id");
       `endif
     end

     // Find the request that corresponds to this response
     foreach (vmm_req[i]) begin
       if (UVM_MATCH_REQ_RSP::match(uvm_req[i], o_rsp)) begin
         v_req = vmm_req[i];
         vmm_req.delete(i);
         uvm_req.delete(i);
         break;
       end
     end

     if (v_req == null) begin
        `ifdef UVM_ON_TOP
        `uvm_error("Orphan Response",
                          "A response did not match a pending request");
        `else
        `vmm_error(this.req_chan.log, "Orphan Response A response did not match a pending request");
        `endif                          
        return;
     end

     // If the response is configured to be the request, the response
     // is provided in the original request transaction.

     if (this.rsp_is_req) begin
        void'(UVM2VMM_RSP::convert(o_rsp, v_req));
        v_req.notify.indicate(vmm_data::ENDED, v_req);
        this.response_ap.write(o_rsp);
        return;
     end

     v_rsp = UVM2VMM_RSP::convert(o_rsp);
     v_req.notify.indicate(vmm_data::ENDED, v_rsp);
     this.response_ap.write(o_rsp);

     // dual channel
     if (this.rsp_chan != null) begin
       this.rsp_chan.sneak(v_rsp);
     end

   endfunction


   // Function- item_done
   //
   // A non-blocking function indicating an UVM driver is done with the
   // transaction retrieved with a <get_next_item> or <get>. The item_done
   // method pops the request off the <req_chan> vmm_channel,
   // converts the response argument, if provided, and sneaks converted response
   // into the <rsp_chan> vmm_channel. If the <rsp_chan> is null and
   // <rsp_is_req> is 0, the response, if provided, is dropped. If <rsp_is_req>
   // is 1, then the response is converted back into the original VMM request
   // and the transaction's ENDED notification is indicated.

   virtual function void item_done(UVM_RSP o_rsp=null);
     VMM_REQ v_req;
     UVM_REQ o_req;
     vmm_data v_req_base;

     // pop off the channel (assumes this hasn't already been done)
     req_chan.XgetX(v_req_base);
     $cast(v_req,v_req_base);

     if (v_req != vmm_req[$]) begin
     `ifdef UVM_ON_TOP
       `uvm_fatal("Item Not Started",
         "Item done called without a previous peek or get_next_item");
     `else
       `vmm_fatal(this.req_chan.log, "Item Not Started Item done called without a previous peek or get_next_item");
     `endif
     return;
     end

     o_req = uvm_req[$];

     this.request_ap.write(o_req);

     if (o_rsp != null) begin
       put_response(o_rsp);
       return;
     end

     if (this.rsp_is_req) begin

       o_req = uvm_req.pop_back();
       v_req = vmm_req.pop_back();

       void'(UVM2VMM_RSP::convert(o_req, v_req));
       v_req.notify.indicate(vmm_data::ENDED, v_req);

       if (this.response_ap.size())
         this.response_ap.write(o_req);
     end

   endfunction

 
   // Function- has_do_available
   //
   // Named for its association with UVM sequencer operation, this function
   // will return 1 if there is a transaction available to get from the
   // vmm_channel, <req_chan>.
 
   virtual function bit has_do_available();
     return !(req_chan.size() == 0 || req_chan.is_locked(vmm_channel::SINK));
   endfunction


   // Task- wait_for_sequences
   //
   // Used in the <try_next_item> method, this method waits a variable number
   // of #0 delays. This give the generator, which may not have resumed from
   // waiting for a previous call to <get> or <item_done>, a chance to wake
   // up and generate and put a new request into the <req_chan>. This allows
   // the driver to execute back-to-back tranasctions and the generator to
   // just-in-time request generation.

   virtual task wait_for_sequences();
      uvm_wait_for_nba_region;
   endtask

endclass


//------------------------------------------------------------------------------
//
// CLASS: uvi_match_uvm_id
//
//------------------------------------------------------------------------------
//
// Policy class to match a response received from a UVM TLM1 consumer
// with a request that was previously sent to it by matching
// the sequence and transaction IDs.
//
// This policy class is the default policy class used by the <uvi_vmm_channel2uvm_tlm1>
// adapter.
// If a different response matching policy must be used,
// it must be implemented as a static method that returns TRUE if the specified
// response matches the specified request.
// This class does not need to be an extension of any particular type,
// but shall follow the prototype exactly:
//
//| class match_rsp2req;
//|    static function bit match(uvm_sequence_item req,
//|                              uvm_sequence_item rsp);
//|    endfunction
//| endclass
//------------------------------------------------------------------------------

class uvi_match_uvm_id;

  static function bit match(uvm_sequence_item req,
                            uvm_sequence_item rsp);
     return req.get_sequence_id() == rsp.get_sequence_id() &&
            req.get_transaction_id() == rsp.get_transaction_id();
  endfunction

endclass



//------------------------------------------------------------------------------
//
// CLASS: uvi_vmm_channel2uvm_ap
//
//------------------------------------------------------------------------------
//
// The uvi_vmm_channel2uvm_ap is used to connect a VMM component with an
// channel to a UVM component via an analysis export.
//
// Connect the adapter's <analysis_port> to
// one or more UVM components with an analysis export. The adapter will ~get~
// any transaction put into the vmm_channel, convert them to an UVM transaction,
// and broadcast it out the analysis port.
//
// Example:
//
//|
//| class vmm2uvm_tr;
//|    static function uvm_tr convert(vmm_tr in, uvm_tr to = null);
//|       ...
//|    endfunction
//| endclass
//|
//| class my_env extends uvm_env;
//|   vmm_mon mon;
//|   uvm_sb  sb;
//|   uvi_vmm_channel2#uvm_ap(.VMM_TR(vmm_tr), .UVM_TR(uvm_tr),
//|                           .VMM2UVM(vmm2uvm_tr),
//|                            mon2sb;
//|   
//|   function void build_phase(uvm_phase phase);
//|      super.build_phase(phase);
//|
//|      mon = new("mon");
//|      sb  = new("sb", this);
//|      mon2sb = new("mon2sb", this, mon.out_chan);
//|   endfunction
//|
//|   function void connect_phase(uvm_phase phase);
//|      super.connect_phase(phase);
//|      mon2sb.analysis_port.connect(sb.axp);
//|   endfunction
//|endclass
//|
//
// See also the <uvi_analysis_channel example>.
//
//------------------------------------------------------------------------------


class uvi_vmm_channel2uvm_ap #(type VMM_TR=int, UVM_TR=int,
                               VMM2UVM=int)
                         extends uvm_component;

  typedef uvi_vmm_channel2uvm_ap #(VMM_TR, UVM_TR, VMM2UVM) this_type;

  `uvm_component_param_utils(this_type)

  // Port: analysis_port
  //
  // VMM transactions received from the channel are converted to UVM
  // transactions and broadcast out this analysis port. 

   uvm_analysis_port #(UVM_TR) analysis_port;


  // Function: new
  //
  // Creates a new uvi_analysis_channel with the given ~name~ and
  // optional ~parent~; the optional ~chan~ argument provides the
  // handle to the vmm_channel being adapted. If no channel is given,
  // the adapter will create one.

  function new (string name, uvm_component parent=null,
                vmm_channel_typed #(VMM_TR) chan=null);
    super.new(name, parent);
    if (chan == null)
      chan = new("VMM Analysis Channel",name);
    this.chan = chan;
    analysis_port   = new("analysis_port",this);
  endfunction


  // Task- run
  //
  // Continually get VMM transactions from the vmm_channel and
  // end the converted transactions out the <analysis_port>.

  virtual task run_phase(uvm_phase phase);
     super.run_phase(phase);
     forever begin
        VMM_TR vmm_t;
        UVM_TR uvm_t;
        chan.get(vmm_t);
        uvm_t = VMM2UVM::convert(vmm_t);
        analysis_port.write(uvm_t);
      end
   endtask

   // Variable: chan
   //
   // The vmm_channel instance being adapted; if not supplied in
   // its <new> constructor, the adapter will create one.
   //
   // Transaction injected into
   // the channel are fetched, converted, and sent out the <analysis_port>.
   // The adapter sinks the channel.

   vmm_channel_typed #(VMM_TR) chan;

endclass


endpackage // uvi_interop_pkg
  
import uvi_interop_pkg::*;

`endif // UVM_VMM_PKG_SV
