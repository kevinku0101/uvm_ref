// 
//------------------------------------------------------------------------------
// Copyright 2007-2014 Mentor Graphics Corporation
// Copyright 2014 Intel Corporation
// Copyright 2010-2014 Synopsys, Inc.
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2010-2012 AMD
// Copyright 2013-2018 NVIDIA Corporation
// Copyright 2017 Cisco Systems, Inc.
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

typedef class uvm_root;
typedef class uvm_report_object;
typedef class uvm_report_message;
   
// Title -- NODOCS -- Globals

//------------------------------------------------------------------------------
//
// Group -- NODOCS -- Simulation Control
//
//------------------------------------------------------------------------------

// Task -- NODOCS -- run_test
//
// Convenience function for uvm_top.run_test(). See <uvm_root> for more
// information.

// @uvm-ieee 1800.2-2017 auto F.3.1.2
task run_test (string test_name="");
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  // Modified by Verdi 9001092057 9001330016
`ifndef UVM_NO_VERDI_RECORD
`ifdef VCS 
  verdi_set_verbosity(1'b0,1);
`endif
`endif
  // 
  top.run_test(test_name);
endtask

`ifdef UVM_VCS_DTL
//task to support running different test after restore
task refresh_test ;
    uvm_coreservice_t cs;
    string tname;
    uvm_root root;
    tname = ""; 
    cs = uvm_coreservice_t::get();
  root = cs.get_root();

  if($test$plusargs("UVM_TESTNAME")) begin
    if($value$plusargs("UVM_TESTNAME=%s",tname)) begin
        `uvm_info("REFRESH",$sformatf("UVM_TESTNAME provided at command line=%0s",tname),UVM_NONE);
        root.refresh_test(tname);
    end
  end
  else begin 
    `uvm_fatal("REFRESH","NO +UVM_TESTNAME specfied in command line, aborting simulation");
  end


endtask
`endif



//----------------------------------------------------------------------------
//
// Group -- NODOCS -- Reporting
//
//----------------------------------------------------------------------------



// @uvm-ieee 1800.2-2017 auto F.3.2.1
function uvm_report_object uvm_get_report_object();
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  return top;
endfunction


// Function -- NODOCS -- uvm_report_enabled
//
// Returns 1 if the configured verbosity in ~uvm_top~ for this 
// severity/id is greater than or equal to ~verbosity~ else returns 0.
// 
// See also <uvm_report_object::uvm_report_enabled>.
//
// Static methods of an extension of uvm_report_object, e.g. uvm_component-based
// objects, cannot call ~uvm_report_enabled~ because the call will resolve to
// the <uvm_report_object::uvm_report_enabled>, which is non-static.
// Static methods cannot call non-static methods of the same class. 

// @uvm-ieee 1800.2-2017 auto F.3.2.2
function int uvm_report_enabled (int verbosity,
                                 uvm_severity severity=UVM_INFO, string id="");
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  return top.uvm_report_enabled(verbosity,severity,id);
endfunction

// Function -- NODOCS -- uvm_report

// @uvm-ieee 1800.2-2017 auto F.3.2.3
function void uvm_report( uvm_severity severity,
                          string id,
                          string message,
                          int verbosity = (severity == uvm_severity'(UVM_ERROR)) ? UVM_LOW :
                                          (severity == uvm_severity'(UVM_FATAL)) ? UVM_NONE : UVM_MEDIUM,
                          string filename = "",
                          int line = 0,
                          string context_name = "",
                          bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report(severity, id, message, verbosity, filename, line, context_name, report_enabled_checked);
endfunction 

// Undocumented DPI available version of uvm_report
export "DPI-C" function m__uvm_report_dpi;
function void m__uvm_report_dpi(int severity,
                                string id,
                                string message,
                                int    verbosity,
                                string filename,
                                int    line);
   uvm_report(uvm_severity'(severity), id, message, verbosity, filename, line);
endfunction : m__uvm_report_dpi

// Function -- NODOCS -- uvm_report_info

// @uvm-ieee 1800.2-2017 auto F.3.2.3
function void uvm_report_info(string id,
			      string message,
                              int verbosity = UVM_MEDIUM,
			      string filename = "",
			      int line = 0,
                              string context_name = "",
                              bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_info(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_report_warning

// @uvm-ieee 1800.2-2017 auto F.3.2.3
function void uvm_report_warning(string id,
                                 string message,
                                 int verbosity = UVM_MEDIUM,
				 string filename = "",
				 int line = 0,
                                 string context_name = "",
                                 bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_warning(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_report_error

// @uvm-ieee 1800.2-2017 auto F.3.2.3
function void uvm_report_error(string id,
                               string message,
                               int verbosity = UVM_NONE,
			       string filename = "",
			       int line = 0,
                               string context_name = "",
                               bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_error(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_report_fatal
//
// These methods, defined in package scope, are convenience functions that
// delegate to the corresponding component methods in ~uvm_top~. They can be
// used in module-based code to use the same reporting mechanism as class-based
// components. See <uvm_report_object> for details on the reporting mechanism. 
//
// *Note:* Verbosity is ignored for warnings, errors, and fatals to ensure users
// do not inadvertently filter them out. It remains in the methods for backward
// compatibility.

// @uvm-ieee 1800.2-2017 auto F.3.2.3
function void uvm_report_fatal(string id,
	                       string message,
                               int verbosity = UVM_NONE,
			       string filename = "",
			       int line = 0,
                               string context_name = "",
                               bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_fatal(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_process_report_message
//
// This method, defined in package scope, is a convenience function that
// delegate to the corresponding component method in ~uvm_top~. It can be
// used in module-based code to use the same reporting mechanism as class-based
// components. See <uvm_report_object> for details on the reporting mechanism.

// @uvm-ieee 1800.2-2017 auto F.3.2.3
function void uvm_process_report_message(uvm_report_message report_message);
  uvm_root top;
  uvm_coreservice_t cs;
  process p;
  p = process::self();
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_process_report_message(report_message);
endfunction


// TODO merge with uvm_enum_wrapper#(uvm_severity)
function bit uvm_string_to_severity (string sev_str, output uvm_severity sev);
  case (sev_str)
    "UVM_INFO": sev = UVM_INFO;
    "UVM_WARNING": sev = UVM_WARNING;
    "UVM_ERROR": sev = UVM_ERROR;
    "UVM_FATAL": sev = UVM_FATAL;
    default: return 0;
  endcase
  return 1;
endfunction


function automatic bit uvm_string_to_action (string action_str, output uvm_action action);
  string actions[$];
  uvm_split_string(action_str,"|",actions);
  uvm_string_to_action = 1;
  action = 0;
  foreach(actions[i]) begin
    case (actions[i])
      "UVM_NO_ACTION": action |= UVM_NO_ACTION;
      "UVM_DISPLAY":   action |= UVM_DISPLAY;
      "UVM_LOG":       action |= UVM_LOG;
      "UVM_COUNT":     action |= UVM_COUNT;
      "UVM_EXIT":      action |= UVM_EXIT;
      "UVM_CALL_HOOK": action |= UVM_CALL_HOOK;
      "UVM_STOP":      action |= UVM_STOP;
      "UVM_RM_RECORD": action |= UVM_RM_RECORD;
      default: uvm_string_to_action = 0;
    endcase
  end
endfunction

  
//----------------------------------------------------------------------------
//
// Group: Miscellaneous
//
// The library implements the following public API at the package level beyond
// what is documented in IEEE 1800.2.
//----------------------------------------------------------------------------

// @uvm-ieee 1800.2-2017 auto F.3.3.1
function bit uvm_is_match (string expr, string str);
  string s;
  s = uvm_glob_to_re(expr);
  return (uvm_re_match(s, str) == 0);
endfunction


parameter UVM_LINE_WIDTH = `UVM_LINE_WIDTH;
parameter UVM_NUM_LINES = `UVM_NUM_LINES;
parameter UVM_SMALL_STRING = UVM_LINE_WIDTH*8-1;
parameter UVM_LARGE_STRING = UVM_LINE_WIDTH*UVM_NUM_LINES*8-1;


//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_string_to_bits
//
// Converts an input string to its bit-vector equivalent. Max bit-vector
// length is approximately 14000 characters.
//----------------------------------------------------------------------------

function logic[UVM_LARGE_STRING:0] uvm_string_to_bits(string str);
  $swrite(uvm_string_to_bits, "%0s", str);
endfunction

// @uvm-ieee 1800.2-2017 auto F.3.1.1
function uvm_core_state get_core_state();
		return m_uvm_core_state;
endfunction

// Function: uvm_init
// Implementation of uvm_init, as defined in section
// F.3.1.3 in 1800.2-2017.
//
// *Note:* The LRM states that subsequent calls to <uvm_init> after
// the first are silently ignored, however there are scenarios wherein
// the implementation breaks this requirement.
//
// If the core state (see <get_core_state>) is ~UVM_CORE_PRE_INIT~ when <uvm_init>,
// is called, then the library can not determine the appropriate core service.  As
// such, the default core service will be constructed and a fatal message
// shall be generated.
//
// If the core state is past ~UVM_CORE_PRE_INIT~, and ~cs~ is a non-null core 
// service instance different than the value passed to the first <uvm_init> call, 
// then the library will generate a warning message to alert the user that this 
// call to <uvm_init> is being ignored.
//
// @uvm-contrib This API represents a potential contribution to IEEE 1800.2
  
// @uvm-ieee 1800.2-2017 auto F.3.1.3
function void uvm_init(uvm_coreservice_t cs=null);
  uvm_default_coreservice_t dcs;
  
  if(get_core_state()!=UVM_CORE_UNINITIALIZED) begin
    if (get_core_state() == UVM_CORE_PRE_INIT) begin
      // If we're in this state, something very strange has happened.
      // We've called uvm_init, and it is actively assigning the
      // core service, but the core service isn't actually set yet.
      // This means that either the library messed something up, or
      // we have a race occurring between two threads.  Either way, 
      // this is non-recoverable.  We're going to setup using the default
      // core service, and immediately fatal out.
      dcs = new();
      uvm_coreservice_t::set(dcs);
      `uvm_fatal("UVM/INIT/MULTI", "Non-recoverable race during uvm_init")
    end
    else begin
      // After PRE_INIT, we can check to see if this is worth reporting
      // as a warning.  We only report it if the value for ~cs~ is _not_
      // the current core service, and ~cs~ is not null.
      uvm_coreservice_t actual;
      actual = uvm_coreservice_t::get();
      if ((cs != actual) && (cs != null))
        `uvm_warning("UVM/INIT/MULTI", "uvm_init() called after library has already completed initialization, subsequent calls are ignored!")
    end
    return;
  end
  m_uvm_core_state=UVM_CORE_PRE_INIT;

  // We control the implementation of uvm_default_coreservice_t::new
  // and uvm_coreservice_t::set (which is undocumented).  As such,
  // we guarantee that they will not trigger any calls to uvm_init.
  if(cs == null) begin
    dcs = new();
    cs = dcs;
  end
  uvm_coreservice_t::set(cs);

  // After this point, it should be safe to query the
  // corservice for anything.  We're not done with
  // initialization, but the coreservice (and the
  // various elements it controls) are 'stable'.
  //
  // Note that a user could have something silly
  // in their own space, like a specialization of
  // uvm_root with a constructor that relies on a
  // specialization of uvm_factory with a
  // constructor that relies on the specialized
  // root being constructed...  but there's not
  // really anything that can be done about that.
  m_uvm_core_state=UVM_CORE_INITIALIZING;
  
  foreach(uvm_deferred_init[idx]) begin
    uvm_deferred_init[idx].initialize();
  end
  
  uvm_deferred_init.delete();
  
  begin
    uvm_root top;
    top = uvm_root::get();
    // These next calls were moved to uvm_init from uvm_root,
    // because they could emit messages, resulting in the
    // report server being queried, which causes uvm_init.
    top.report_header();
    top.m_check_uvm_field_flag_size();
    // This sets up the global verbosity. Other command line args may
    // change individual component verbosity.
    top.m_check_verbosity();
  end
    
  m_uvm_core_state=UVM_CORE_INITIALIZED;
endfunction

//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_bits_to_string
//
// Converts an input bit-vector to its string equivalent. Max bit-vector
// length is approximately 14000 characters.
//----------------------------------------------------------------------------

function string uvm_bits_to_string(logic [UVM_LARGE_STRING:0] str);
  $swrite(uvm_bits_to_string, "%0s", str);
endfunction


//----------------------------------------------------------------------------
//
// Task: uvm_wait_for_nba_region
//
// This task will block until SystemVerilog's NBA region (or Re-NBA region if 
// called from a program context).  The purpose is to continue the calling 
// process only after allowing other processes any number of delta cycles (#0) 
// to settle out.
//
// @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2
//----------------------------------------------------------------------------

task uvm_wait_for_nba_region;

  int nba;
  int next_nba;

  //If `included directly in a program block, can't use a non-blocking assign,
  //but it isn't needed since program blocks are in a separate region.
`ifndef UVM_NO_WAIT_FOR_NBA
  next_nba++;
  nba <= next_nba;
  @(nba);
`else
  repeat(`UVM_POUND_ZERO_COUNT) #0;
`endif


endtask


//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_split_string
//
// Returns a queue of strings, ~values~, that is the result of the ~str~ split
// based on the ~sep~.  For example:
//
//| uvm_split_string("1,on,false", ",", splits);
//
// Results in the 'splits' queue containing the three elements: 1, on and 
// false.
//----------------------------------------------------------------------------

function automatic void uvm_split_string (string str, byte sep, ref string values[$]);
  int s = 0, e = 0;
  values.delete();
  while(e < str.len()) begin
    for(s=e; e<str.len(); ++e)
      if(str[e] == sep) break;
    if(s != e)
      values.push_back(str.substr(s,e-1));
    e++;
  end
endfunction

// Class -- NODOCS -- uvm_enum_wrapper#(T)
//
// The ~uvm_enum_wrapper#(T)~ class is a utility mechanism provided
// as a convenience to the end user.  It provides a <from_name>
// method which is the logical inverse of the System Verilog ~name~ 
// method which is built into all enumerations.

// @uvm-ieee 1800.2-2017 auto F.3.4.1
class uvm_enum_wrapper#(type T=uvm_active_passive_enum);

    protected static T map[string];


    // @uvm-ieee 1800.2-2017 auto F.3.4.2
    static function bit from_name(string name, ref T value);
        if (map.size() == 0)
          m_init_map();

        if (map.exists(name)) begin
            value = map[name];
            return 1;
        end
        else begin
            return 0;
        end
    endfunction : from_name

    // Function- m_init_map
    // Initializes the name map, only needs to be performed once
    protected static function void m_init_map();
        T e = e.first();
        do 
          begin
            map[e.name()] = e;
            e = e.next();
          end
        while (e != e.first());
    endfunction : m_init_map

    // Function- new
    // Prevents accidental instantiations
    protected function new();
    endfunction : new

endclass : uvm_enum_wrapper

// Modfied by Verdi 9001155572
`ifndef UVM_VERDI_NO_VERDI_TRACE
function bit is_verdi_trace_aware_used_by_sep(byte sep);
    string verdi_trace_values[$], split_values[$];
    static uvm_cmdline_processor clp;
    static bit result = 0;

    clp = uvm_cmdline_processor::get_inst();
    void'(clp.get_arg_values("+UVM_VERDI_TRACE=",verdi_trace_values));
    foreach (verdi_trace_values[i]) begin
      uvm_split_string(verdi_trace_values[i], sep, split_values);
      foreach (split_values[j]) begin
        case (split_values[j])
          "UVM_AWARE": result = 1;
        endcase
      end
    end

    return result;
endfunction

function bit is_verdi_trace_aware_used();
    static bit is_verdi_trace_aware = 0;
    static bit is_verdi_trace_aware_checked = 0;

    if (is_verdi_trace_aware_checked==0) begin
        is_verdi_trace_aware_checked = 1;
        is_verdi_trace_aware = is_verdi_trace_aware_used_by_sep("|") || is_verdi_trace_aware_used_by_sep("+");
    end
    return is_verdi_trace_aware;
endfunction

// Modified by Verdi 9001092057 9001330016 9001487073
`ifndef UVM_NO_VERDI_RECORD
`ifdef VCS

function void verdi_set_report_verbosity_level_hier(int verbosity);
  static uvm_root top = uvm_root::get();

  top.set_report_verbosity_level_hier(verbosity);
endfunction

function void verdi_set_verbosity(logic [115199:0] options_bv,bit first=0);
  // _ALL_ can be used for ids
  // +uvm_set_verbosity=<comp>,<id>,<verbosity>,<phase|time>,<offset>
  // +uvm_set_verbosity=uvm_test_top.env0.agent1.*,_ALL_,UVM_FULL,time,800

  string args[$];
  string options;
  uvm_component list[$];
  static uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
  static uvm_root top = uvm_root::get();

  begin
    if (first)
        return;
    args.delete();
    options = uvm_bits_to_string(options_bv);
    uvm_split_string(options, ",", args);

    begin
      setting_comp = args[0];
      setting_id = args[1];
      void'(clp.m_convert_verb(args[2],setting_verbosity));
      setting_phase = args[3];
      setting_offset = 0;
      if(args.size() == 5) setting_offset = args[4].atoi();
    end

    top = uvm_root::get();
    top.find_all("*",list,top);
    // 9001495454 Top component needs to call uvm_set_verbosity
    top.uvm_set_verbosity(setting_comp,setting_id,setting_verbosity,setting_phase,setting_offset);
    foreach (list[i]) begin
      list[i].uvm_set_verbosity(setting_comp,setting_id,setting_verbosity,setting_phase,setting_offset);
    end
  end
endfunction
`endif
`endif
//
`endif
//

