//----------------------------------------------------------------------
//   Copyright 2011 Cypress Semiconductor
//   Copyright 2010-2011 Mentor Graphics Corporation
//   Copyright 2014 NVIDIA Corporation
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
//----------------------------------------------------------------------

typedef class uvm_phase;

//----------------------------------------------------------------------
// Title: UVM Configuration Database
//
// Topic: Intro
//
// The <uvm_config_db> class provides a convenience interface 
// on top of the <uvm_resource_db> to simplify the basic interface
// that is used for configuring <uvm_component> instances.
//
// If the run-time ~+UVM_CONFIG_DB_TRACE~ command line option is specified,
// all configuration DB accesses (read and write) are displayed.
//----------------------------------------------------------------------

//Internal class for config waiters
class m_uvm_waiter;
  string inst_name;
  string field_name;
  event trigger;
  function new (string inst_name, string field_name);
    this.inst_name = inst_name;
    this.field_name = field_name;
  endfunction
endclass

typedef class uvm_root;
typedef class uvm_config_db_options;

//----------------------------------------------------------------------
// class: uvm_config_db
//
// All of the functions in uvm_config_db#(T) are static, so they
// must be called using the :: operator.  For example:
//
//|  uvm_config_db#(int)::set(this, "*", "A");
//
// The parameter value "int" identifies the configuration type as
// an int property.  
//
// The <set> and <get> methods provide the same API and
// semantics as the set/get_config_* functions in <uvm_component>.
//----------------------------------------------------------------------
class uvm_config_db#(type T=int) extends uvm_resource_db#(T);

  // Internal lookup of config settings so they can be reused
  // The context has a pool that is keyed by the inst/field name.
  static uvm_pool#(string,uvm_resource#(T)) m_rsc[uvm_component];

  // Internal waiter list for wait_modified
  static local uvm_queue#(m_uvm_waiter) m_waiters[string];

  // function: get
  //
  // Get the value for ~field_name~ in ~inst_name~, using component ~cntxt~ as 
  // the starting search point. ~inst_name~ is an explicit instance name 
  // relative to ~cntxt~ and may be an empty string if the ~cntxt~ is the
  // instance that the configuration object applies to. ~field_name~
  // is the specific field in the scope that is being searched for.
  //
  // The basic ~get_config_*~ methods from <uvm_component> are mapped to
  // this function as:
  //
  //| get_config_int(...) => uvm_config_db#(uvm_bitstream_t)::get(cntxt,...)
  //| get_config_string(...) => uvm_config_db#(string)::get(cntxt,...)
  //| get_config_object(...) => uvm_config_db#(uvm_object)::get(cntxt,...)

  static function bit get(uvm_component cntxt,
                          string inst_name,
                          string field_name,
                          inout T value);
//TBD: add file/line
    int unsigned p;
    uvm_resource#(T) r, rt;
    uvm_resource_pool rp = uvm_resource_pool::get();
    uvm_resource_types::rsrc_q_t rq;
    uvm_coreservice_t cs = uvm_coreservice_t::get();

    if(cntxt == null) 
      cntxt = cs.get_root();
    if(inst_name == "") 
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "") 
      inst_name = {cntxt.get_full_name(), ".", inst_name};
 
    rq = rp.lookup_regex_names(inst_name, field_name, uvm_resource#(T)::get_type());
    r = uvm_resource#(T)::get_highest_precedence(rq);
    
    if(uvm_config_db_options::is_tracing())
      m_show_msg("CFGDB/GET", "Configuration","read", inst_name, field_name, cntxt, r);

    if(r == null)
      return 0;

    value = r.read(cntxt);

    return 1;
  endfunction

  // function: set 
  //
  // Create a new or update an existing configuration setting for
  // ~field_name~ in ~inst_name~ from ~cntxt~.
  // The setting is made at ~cntxt~, with the full scope of the set 
  // being {~cntxt~,".",~inst_name~}. If ~cntxt~ is ~null~ then ~inst_name~
  // provides the complete scope information of the setting.
  // ~field_name~ is the target field. Both ~inst_name~ and ~field_name~
  // may be glob style or regular expression style expressions.
  //
  // If a setting is made at build time, the ~cntxt~ hierarchy is
  // used to determine the setting's precedence in the database.
  // Settings from hierarchically higher levels have higher
  // precedence. Settings from the same level of hierarchy have
  // a last setting wins semantic. A precedence setting of 
  // <uvm_resource_base::default_precedence>  is used for uvm_top, and 
  // each hierarchical level below the top is decremented by 1.
  //
  // After build time, all settings use the default precedence and thus
  // have a last wins semantic. So, if at run time, a low level 
  // component makes a runtime setting of some field, that setting 
  // will have precedence over a setting from the test level that was 
  // made earlier in the simulation.
  //
  // The basic ~set_config_*~ methods from <uvm_component> are mapped to
  // this function as:
  //
  //| set_config_int(...) => uvm_config_db#(uvm_bitstream_t)::set(cntxt,...)
  //| set_config_string(...) => uvm_config_db#(string)::set(cntxt,...)
  //| set_config_object(...) => uvm_config_db#(uvm_object)::set(cntxt,...)

  static function void set(uvm_component cntxt,
                           string inst_name,
                           string field_name,
                           T value);

    uvm_root top;
    uvm_phase curr_phase;
    uvm_resource#(T) r;
    bit exists;
    string lookup;
    uvm_pool#(string,uvm_resource#(T)) pool;
    string rstate;
    uvm_coreservice_t cs = uvm_coreservice_t::get();
     
    //take care of random stability during allocation
    process p = process::self();
    if(p != null) 
  		rstate = p.get_randstate();
  		
    top = cs.get_root();

    curr_phase = top.m_current_phase;

    if(cntxt == null) 
      cntxt = top;
    if(inst_name == "") 
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "") 
      inst_name = {cntxt.get_full_name(), ".", inst_name};

    if(!m_rsc.exists(cntxt)) begin
      m_rsc[cntxt] = new;
    end
    pool = m_rsc[cntxt];

    // Insert the token in the middle to prevent cache
    // oddities like i=foobar,f=xyz and i=foo,f=barxyz.
    // Can't just use '.', because '.' isn't illegal
    // in field names
    lookup = {inst_name, "__M_UVM__", field_name};

    if(!pool.exists(lookup)) begin
       r = new(field_name, inst_name);
       pool.add(lookup, r);
    end
    else begin
      r = pool.get(lookup);
      exists = 1;
    end
      
    if(curr_phase != null && curr_phase.get_name() == "build")
      r.precedence = uvm_resource_base::default_precedence - (cntxt.get_depth());
    else
      r.precedence = uvm_resource_base::default_precedence;

    r.write(value, cntxt);

    if(exists) begin
      uvm_resource_pool rp = uvm_resource_pool::get();
      rp.set_priority_name(r, uvm_resource_types::PRI_HIGH);
    end
    else begin
      //Doesn't exist yet, so put it in resource db at the head.
      r.set_override();
    end

    //trigger any waiters
    if(m_waiters.exists(field_name)) begin
      m_uvm_waiter w;
      for(int i=0; i<m_waiters[field_name].size(); ++i) begin
        w = m_waiters[field_name].get(i);
        if(uvm_re_match(uvm_glob_to_re(inst_name),w.inst_name) == 0)
           ->w.trigger;  
      end
    end

    if(p != null)
    	p.set_randstate(rstate);

    if(uvm_config_db_options::is_tracing())
      m_show_msg("CFGDB/SET", "Configuration","set", inst_name, field_name, cntxt, r);
  endfunction


  // function: exists
  //
  // Check if a value for ~field_name~ is available in ~inst_name~, using
  // component ~cntxt~ as the starting search point. ~inst_name~ is an explicit
  // instance name relative to ~cntxt~ and may be an empty string if the
  // ~cntxt~ is the instance that the configuration object applies to.
  // ~field_name~ is the specific field in the scope that is being searched for.
  // The ~spell_chk~ arg can be set to 1 to turn spell checking on if it
  // is expected that the field should exist in the database. The function
  // returns 1 if a config parameter exists and 0 if it doesn't exist.
  //

  static function bit exists(uvm_component cntxt, string inst_name,
    string field_name, bit spell_chk=0);
    uvm_coreservice_t cs = uvm_coreservice_t::get();

    if(cntxt == null)
      cntxt = cs.get_root();
    if(inst_name == "")
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "")
      inst_name = {cntxt.get_full_name(), ".", inst_name};

    return (uvm_resource_db#(T)::get_by_name(inst_name,field_name,spell_chk) != null);
  endfunction


  // Function: wait_modified
  //
  // Wait for a configuration setting to be set for ~field_name~
  // in ~cntxt~ and ~inst_name~. The task blocks until a new configuration
  // setting is applied that effects the specified field.

  static task wait_modified(uvm_component cntxt, string inst_name,
      string field_name);
    process p = process::self();
    string rstate = p.get_randstate();
    m_uvm_waiter waiter;
    uvm_coreservice_t cs = uvm_coreservice_t::get();

    if(cntxt == null)
      cntxt = cs.get_root();
    if(cntxt != cs.get_root()) begin
      if(inst_name != "")
        inst_name = {cntxt.get_full_name(),".",inst_name};
      else
        inst_name = cntxt.get_full_name();
    end

    waiter = new(inst_name, field_name);

    if(!m_waiters.exists(field_name))
      m_waiters[field_name] = new;
    m_waiters[field_name].push_back(waiter);

    p.set_randstate(rstate);

    // wait on the waiter to trigger
    @waiter.trigger;
  
    // Remove the waiter from the waiter list 
    for(int i=0; i<m_waiters[field_name].size(); ++i) begin
      if(m_waiters[field_name].get(i) == waiter) begin
        m_waiters[field_name].delete(i);
        break;
      end
    end 
  endtask


endclass

// Section: Types
   
//----------------------------------------------------------------------
// Topic: uvm_config_int
//
// Convenience type for uvm_config_db#(uvm_bitstream_t)
//
//| typedef uvm_config_db#(uvm_bitstream_t) uvm_config_int;
typedef uvm_config_db#(uvm_bitstream_t) uvm_config_int;

//----------------------------------------------------------------------
// Topic: uvm_config_string
//
// Convenience type for uvm_config_db#(string)
//
//| typedef uvm_config_db#(string) uvm_config_string;
typedef uvm_config_db#(string) uvm_config_string;

//----------------------------------------------------------------------
// Topic: uvm_config_object
//
// Convenience type for uvm_config_db#(uvm_object)
//
//| typedef uvm_config_db#(uvm_object) uvm_config_object;
typedef uvm_config_db#(uvm_object) uvm_config_object;

//----------------------------------------------------------------------
// Topic: uvm_config_wrapper
//
// Convenience type for uvm_config_db#(uvm_object_wrapper)
//
//| typedef uvm_config_db#(uvm_object_wrapper) uvm_config_wrapper;   
typedef uvm_config_db#(uvm_object_wrapper) uvm_config_wrapper;


//----------------------------------------------------------------------
// Class: uvm_config_db_options
//
// Provides a namespace for managing options for the
// configuration DB facility.  The only thing allowed in this class is static
// local data members and static functions for manipulating and
// retrieving the value of the data members.  The static local data
// members represent options and settings that control the behavior of
// the configuration DB facility.

// Options include:
//
//  * tracing:  on/off
//
//    The default for tracing is off.
//
//----------------------------------------------------------------------
class uvm_config_db_options;
   
  static local bit ready;
  static local bit tracing;

  // Function: turn_on_tracing
  //
  // Turn tracing on for the configuration database. This causes all
  // reads and writes to the database to display information about
  // the accesses. Tracing is off by default.
  //
  // This method is implicitly called by the ~+UVM_CONFIG_DB_TRACE~.

  static function void turn_on_tracing();
     if (!ready) init();
    tracing = 1;
  endfunction

  // Function: turn_off_tracing
  //
  // Turn tracing off for the configuration database.

  static function void turn_off_tracing();
     if (!ready) init();
    tracing = 0;
  endfunction

  // Function: is_tracing
  //
  // Returns 1 if the tracing facility is on and 0 if it is off.

  static function bit is_tracing();
    if (!ready) init();
    return tracing;
  endfunction


  static local function void init();
     uvm_cmdline_processor clp;
     string trace_args[$];
     
     clp = uvm_cmdline_processor::get_inst();

`ifndef UVM_VERDI_NO_VERDI_TRACE
     if (clp.get_arg_matches("+UVM_CONFIG_DB_TRACE", trace_args)||is_verdi_trace_aware_used()) begin //Verdi 9001155572
`else
     if (clp.get_arg_matches("+UVM_CONFIG_DB_TRACE", trace_args)) begin
`endif
        tracing = 1;
     end

     ready = 1;
  endfunction

endclass
