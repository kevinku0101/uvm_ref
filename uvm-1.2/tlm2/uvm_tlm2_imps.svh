//----------------------------------------------------------------------
//   Copyright 2010-2011 Mentor Graphics Corporation
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
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Title: TLM2 imps (interface implementations)
//
// This section defines the implementation classes for connecting TLM2
// interfaces.
//
// TLM imps bind a TLM interface with the object that contains the
// interface implementation.
// In addition to the transaction type and the phase type, the imps 
// are parameterized with the type of the object that will provide the
// implementation. Most often this will be the type of the component 
// where the imp resides. The constructor of the imp takes as an argument 
// an object of type IMP and installs it as the implementation object. 
// Most often the imp constructor argument is "this".
//----------------------------------------------------------------------

// Modified by Verdi
`ifndef UVM_VERDI_NO_PORT_RECORDING
`define UVM_IF_METHOD3_BEGIN(method_name,gp,delay,is_nonblocking,phase) \
       uvm_object __req__; \
       int __r_tr_h__; \
       int obj_size = 0; \
       uvm_coreservice_t cs = uvm_coreservice_t::get(); \
       uvm_tr_database verdi_db = cs.get_default_tr_database(); \
       obj_size = this.size(); \
       if (obj_size && $cast(__req__,gp)) \
           verdi_db.tlm2_begin_recording_cb(m_comp,method_name,__req__,delay,is_nonblocking,phase,__r_tr_h__);
`define UVM_IF_METHOD3_END(method_name,gp,delay,is_nonblocking,phase, sync) \
       if (obj_size && $cast(__req__,gp)) \
           verdi_db.tlm2_end_recording_cb(m_comp,method_name,__req__,delay,__r_tr_h__,is_nonblocking,phase,sync);
`endif

//--------------------------
// Group: IMP binding macros
//--------------------------

// Macro: `UVM_TLM_NB_TRANSPORT_FW_IMP
//
// The macro wraps the forward path call function nb_transport_fw()
//
// The first call to this method for a transaction marks the initial timing point.
// Every call to this method may mark a timing point in the execution of the 
// transaction. The timing annotation argument allows the timing points
// to be offset from the simulation times at which the forward path is used.
// The final timing point of a transaction may be marked by a call
// to nb_transport_bw() within <`UVM_TLM_NB_TRANSPORT_BW_IMP> or a return from this 
// or subsequent call to nb_transport_fw().
//
// See <TLM2 Interfaces, Ports, Exports and Transport Interfaces Subset>
// for more details on the semantics and rules of the nonblocking
// transport interface.
   
// Modified by Verdi
`ifndef UVM_VERDI_NO_PORT_RECORDING
`define UVM_TLM_NB_TRANSPORT_FW_IMP(imp, T, P, t, p, delay)              \
  function uvm_tlm_sync_e nb_transport_fw(T t, ref P p, input uvm_tlm_time delay); \
    uvm_tlm_sync_e sync; \
    `UVM_IF_METHOD3_BEGIN("nb_transport_fw",t,delay,1,p) \
    if (delay == null) begin \
       `uvm_error("UVM/TLM/NULLDELAY", \
                  {get_full_name(), \
                   ".nb_transport_fw() called with 'null' delay"}) \
       sync =  UVM_TLM_COMPLETED; \
    end \
    else \
       sync = imp.nb_transport_fw(t, p, delay);                          \
    `UVM_IF_METHOD3_END("nb_transport_fw",t,delay,1,p,sync) \
    return sync; \
  endfunction
`else
`define UVM_TLM_NB_TRANSPORT_FW_IMP(imp, T, P, t, p, delay)              \
  function uvm_tlm_sync_e nb_transport_fw(T t, ref P p, input uvm_tlm_time delay);  \
    if (delay == null) begin \
       `uvm_error("UVM/TLM/NULLDELAY", \
                  {get_full_name(), \
                   ".nb_transport_fw() called with 'null' delay"}) \
       return UVM_TLM_COMPLETED; \
    end \
    return imp.nb_transport_fw(t, p, delay);                          \
  endfunction
`endif

// Macro: `UVM_TLM_NB_TRANSPORT_BW_IMP
//
//
// Implementation of the backward path.
// The macro wraps the function called nb_transport_bw().
// This function MUST be implemented in the INITIATOR component class.
//
// Every call to this method may mark a timing point, including the final
// timing point, in the execution of the transaction.
// The timing annotation argument allows the timing point
// to be offset from the simulation times at which the backward path is used.
// The final timing point of a transaction may be marked by a call
// to nb_transport_fw() within <`UVM_TLM_NB_TRANSPORT_FW_IMP> or a return from 
// this or subsequent call to nb_transport_bw().
//
// See <TLM2 Interfaces, Ports, Exports and Transport Interfaces Subset>
// for more details on the semantics and rules of the nonblocking
// transport interface.
//
// Example:
//
//| class master extends uvm_component;
//|    uvm_tlm_nb_initiator_socket
//|          #(trans, uvm_tlm_phase_e, this_t) initiator_socket;
//|
//|    function void build_phase(uvm_phase phase);
//|       initiator_socket = new("initiator_socket", this, this);
//|    endfunction
//|
//|    function uvm_tlm_sync_e nb_transport_bw(trans t,
//|                                   ref uvm_tlm_phase_e p,
//|                                   input uvm_tlm_time delay);
//|        transaction = t;
//|        state = p;
//|        return UVM_TLM_ACCEPTED;
//|    endfunction
//|
//|    ...
//| endclass

// Modified by Verdi
`ifndef UVM_VERDI_NO_PORT_RECORDING
`define UVM_TLM_NB_TRANSPORT_BW_IMP(imp, T, P, t, p, delay) \
  function uvm_tlm_sync_e nb_transport_bw(T t, ref P p, input uvm_tlm_time delay);  \
    uvm_tlm_sync_e sync; \
    `UVM_IF_METHOD3_BEGIN("nb_transport_bw",t,delay,1,p) \
    if (delay == null) begin \
       `uvm_error("UVM/TLM/NULLDELAY", \
                  {get_full_name(), \
                   ".nb_transport_bw() called with 'null' delay"}) \
       sync = UVM_TLM_COMPLETED; \
    end \
    else \
       sync = imp.nb_transport_bw(t, p, delay); \
    `UVM_IF_METHOD3_END("nb_transport_bw",t,delay,1,p,sync) \
    return sync; \
  endfunction
`else
`define UVM_TLM_NB_TRANSPORT_BW_IMP(imp, T, P, t, p, delay) \
  function uvm_tlm_sync_e nb_transport_bw(T t, ref P p, input uvm_tlm_time delay); \
    if (delay == null) begin \
       `uvm_error("UVM/TLM/NULLDELAY", \
                  {get_full_name(), \
                   ".nb_transport_bw() called with 'null' delay"}) \
       return UVM_TLM_COMPLETED; \
    end \
    return imp.nb_transport_bw(t, p, delay); \
  endfunction
`endif


// Macro: `UVM_TLM_B_TRANSPORT_IMP
//
// The macro wraps the function b_transport()
// Execute a blocking transaction. Once this method returns,
// the transaction is assumed to have been executed. Whether
// that execution is successful or not must be indicated by the
// transaction itself.
//
// The callee may modify or update the transaction object, subject
// to any constraints imposed by the transaction class. The
// initiator may re-use a transaction object from one call to
// the next and across calls to b_transport(). 
//
// The call to b_transport shall mark the first timing point of the
// transaction. The return from b_transport() shall mark the final
// timing point of the transaction. The timing annotation argument
// allows the timing points to be offset from the simulation times
// at which the task call and return are executed.

// Modified by Verdi
`ifndef UVM_VERDI_NO_PORT_RECORDING
`define UVM_TLM_B_TRANSPORT_IMP(imp, T, t, delay)                        \
  task b_transport(T t, uvm_tlm_time delay);                              \
    `UVM_IF_METHOD3_BEGIN("b_transport",t,delay,0,0) \
    if (delay == null) begin \
       `uvm_error("UVM/TLM/NULLDELAY", \
                  {get_full_name(), \
                   ".b_transport() called with 'null' delay"}) \
    end \
    else \
       imp.b_transport(t, delay);                                        \
    `UVM_IF_METHOD3_END("b_transport",t,delay,0,0,0) \
  endtask
`else
`define UVM_TLM_B_TRANSPORT_IMP(imp, T, t, delay)                        \
  task b_transport(T t, uvm_tlm_time delay);                              \
    if (delay == null) begin \
       `uvm_error("UVM/TLM/NULLDELAY", \
                  {get_full_name(), \
                   ".b_transport() called with 'null' delay"}) \
       return; \
    end \
    imp.b_transport(t, delay);                                        \
  endtask
`endif



//---------------------------
// Group: IMP binding classes
//---------------------------

//----------------------------------------------------------------------
// Class: uvm_tlm_b_transport_imp
//
// Used like exports, except an additional class parameter specifies 
// the type of the implementation object.  When the
// imp is instantiated the implementation object is bound.
//----------------------------------------------------------------------

class uvm_tlm_b_transport_imp #(type T=uvm_tlm_generic_payload,
                            type IMP=int)
  extends uvm_port_base #(uvm_tlm_if #(T));
  `UVM_IMP_COMMON(`UVM_TLM_B_MASK, "uvm_tlm_b_transport_imp", IMP)
  `UVM_TLM_B_TRANSPORT_IMP(m_imp, T, t, delay)
endclass

//----------------------------------------------------------------------
// Class: uvm_tlm_nb_transport_fw_imp
//
// Used like exports, except an additional class parameter specifies 
// the type of the implementation object.  When the
// imp is instantiated the implementation object is bound.
//----------------------------------------------------------------------

class uvm_tlm_nb_transport_fw_imp #(type T=uvm_tlm_generic_payload,
                                type P=uvm_tlm_phase_e,
                                type IMP=int)
  extends uvm_port_base #(uvm_tlm_if #(T,P));
  `UVM_IMP_COMMON(`UVM_TLM_NB_FW_MASK, "uvm_tlm_nb_transport_fw_imp", IMP)
  `UVM_TLM_NB_TRANSPORT_FW_IMP(m_imp, T, P, t, p, delay)
endclass

//----------------------------------------------------------------------
// Class: uvm_tlm_nb_transport_bw_imp
//
// Used like exports, except an additional class parameter specifies 
// the type of the implementation object.  When the
// imp is instantiated the implementation object is bound.
//----------------------------------------------------------------------

class uvm_tlm_nb_transport_bw_imp #(type T=uvm_tlm_generic_payload,
                                type P=uvm_tlm_phase_e,
                                type IMP=int)
  extends uvm_port_base #(uvm_tlm_if #(T,P));
  `UVM_IMP_COMMON(`UVM_TLM_NB_BW_MASK, "uvm_tlm_nb_transport_bw_imp", IMP)
  `UVM_TLM_NB_TRANSPORT_BW_IMP(m_imp, T, P, t, p, delay)
endclass
