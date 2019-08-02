//
//----------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc.
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

`ifndef UVM_TLM_IMPS_SVH
`define UVM_TLM_IMPS_SVH

//
// These IMP macros define implementations of the uvm_*_port, uvm_*_export,
// and uvm_*_imp ports.
//


//---------------------------------------------------------------
// Macros for implementations of UVM ports and exports

/*
`define UVM_BLOCKING_PUT_IMP(imp, TYPE, arg) \
  task put (TYPE arg); \
    if (m_imp_list.size()) == 0) begin \
      uvm_report_error("Port Not Bound","Blocking put to unbound port will wait forever.", UVM_NONE);
      @imp;
    end
    if (bcast_mode) begin \
      if (m_imp_list.size()) > 1) \
        fork
          begin
            foreach (m_imp_list[index]) \
              fork \
                automatic int i = index; \
                begin m_imp_list[i].put(arg); end \
              join_none \
            wait fork; \
          end \
        join \
      else \
        m_imp_list[0].put(arg); \
    end \
    else  \
      if (imp != null) \
        imp.put(arg); \
  endtask \

`define UVM_NONBLOCKING_PUT_IMP(imp, TYPE, arg) \
  function bit try_put(input TYPE arg); \
    if (bcast_mode) begin \
      if (!can_put()) \
        return 0; \
      foreach (m_imp_list[index]) \
        void'(m_imp_list[index].try_put(arg)); \
      return 1; \
    end  \
    if (imp != null) \
      return imp.try_put(arg)); \
    return 0; \
  endfunction \
  \
  function bit can_put(); \
    if (bcast_mode) begin \
      if (m_imp_list.size()) begin \
        foreach (m_imp_list[index]) begin \
          if (!m_imp_list[index].can_put() \
            return 0; \
        end \
        return 1; \
      end \
      return 0; \
    end \
    if (imp != null) \
      return imp.can_put(); \
    return 0; \
  endfunction

*/

//-----------------------------------------------------------------------
// TLM imp implementations

// Modified by Verdi
`ifndef UVM_VERDI_NO_PORT_RECORDING
`define UVM_IF_METHOD_BEGIN(req_arg,method_name) \
       uvm_object __obj__; \
       int r_tr_h1, r_tr_h2; \
       int obj_size = 0; \
       uvm_coreservice_t cs = uvm_coreservice_t::get(); \
       uvm_tr_database verdi_db = cs.get_default_tr_database(); \
       obj_size = this.size(); \
       if (obj_size && $cast(__obj__,req_arg)) \
           verdi_db.port_begin_recording_cb(m_comp,method_name,__obj__,0,0,0,null,0,0,r_tr_h1,r_tr_h2);
`define UVM_IF_METHOD_END(req_arg,method_name) \
       if (obj_size && $cast(__obj__,req_arg)) \
           verdi_db.port_end_recording_cb(m_comp,method_name,__obj__,r_tr_h1,r_tr_h2);
`define UVM_IF_METHOD2_BEGIN(req_arg,rsp_arg,method_name,has_response,has_return,val) \
       uvm_object __req__, __rsp__; \
       int r_tr_h1, r_tr_h2; \
       int obj_size = 0; \
       uvm_coreservice_t cs = uvm_coreservice_t::get(); \
       uvm_tr_database verdi_db = cs.get_default_tr_database(); \
       obj_size = this.size(); \
       if (obj_size && $cast(__req__,req_arg) && $cast(__rsp__,rsp_arg)) \
           verdi_db.port_begin_recording_cb(m_comp,method_name,__req__,0,0,has_response,__rsp__,has_return,val,r_tr_h1,r_tr_h2);
`define UVM_IF_METHOD2_END(req_arg,rsp_arg,method_name,has_response,has_return,val) \
       if (obj_size && $cast(__req__,req_arg) && $cast(__rsp__,rsp_arg)) \
           verdi_db.port_end_recording_cb(m_comp,method_name,__req__,r_tr_h1,r_tr_h2,0,0,has_response,__rsp__,has_return,val);

`define UVM_BLOCKING_PUT_IMP(imp, TYPE, arg) \
  task put (TYPE arg); \
    `UVM_IF_METHOD2_BEGIN(arg,null,"put",0,0,0); \
    imp.put(arg); \
    `UVM_IF_METHOD2_END(arg,null,"put",0,0,0); \
  endtask

`define UVM_NONBLOCKING_PUT_IMP(imp, TYPE, arg) \
  function bit try_put (TYPE arg); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(arg,null,"try_put",0,1,val); \
    val = imp.try_put(arg); \
    `UVM_IF_METHOD2_END(arg,null,"try_put",0,1,val); \
    return val; \
  endfunction \
  function bit can_put(); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(null,null,"can_put",0,1,val); \
    val = imp.can_put(); \
    `UVM_IF_METHOD2_END(null,null,"can_put",0,1,val); \
    return val; \
  endfunction

`define UVM_BLOCKING_GET_IMP(imp, TYPE, arg) \
  task get (output TYPE arg); \
    `UVM_IF_METHOD2_BEGIN(arg,null,"get",0,0,0); \
    imp.get(arg); \
    `UVM_IF_METHOD2_END(arg,null,"get",0,0,0); \
  endtask

`define UVM_NONBLOCKING_GET_IMP(imp, TYPE, arg) \
  function bit try_get (output TYPE arg); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(arg,null,"try_get",0,1,val); \
    val = imp.try_get(arg); \
    `UVM_IF_METHOD2_END(arg,null,"try_get",0,1,val); \
    return val; \
  endfunction \
  function bit can_get(); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(null,null,"can_get",0,1,val); \
    val = imp.can_get(); \
    `UVM_IF_METHOD2_END(null,null,"can_get",0,1,val); \
    return val; \
  endfunction

`define UVM_BLOCKING_PEEK_IMP(imp, TYPE, arg) \
  task peek (output TYPE arg); \
    `UVM_IF_METHOD2_BEGIN(arg,null,"peek",0,0,0); \
    imp.peek(arg); \
    `UVM_IF_METHOD2_END(arg,null,"peek",0,0,0); \
  endtask

`define UVM_NONBLOCKING_PEEK_IMP(imp, TYPE, arg) \
  function bit try_peek (output TYPE arg); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(arg,null,"try_peek",0,1,val); \
    val = imp.try_peek(arg); \
    `UVM_IF_METHOD2_END(arg,null,"try_peek",0,1,val); \
    return val; \
  endfunction \
  function bit can_peek(); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(null,null,"can_peek",0,1,val); \
    val = imp.can_peek(); \
    `UVM_IF_METHOD2_END(null,null,"can_peek",0,1,val); \
    return val; \
  endfunction

`define UVM_BLOCKING_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg) \
  task transport (REQ req_arg, output RSP rsp_arg); \
    `UVM_IF_METHOD2_BEGIN(req_arg,rsp_arg,"transport",1,0,0); \
    imp.transport(req_arg, rsp_arg); \
    `UVM_IF_METHOD2_END(req_arg,rsp_arg,"transport",1,0,0); \
  endtask

`define UVM_NONBLOCKING_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg) \
  function bit nb_transport (REQ req_arg, output RSP rsp_arg); \
    bit val; \
    `UVM_IF_METHOD2_BEGIN(req_arg,rsp_arg,"nb_transport",1,1,val); \
    val = imp.nb_transport(req_arg, rsp_arg); \
    `UVM_IF_METHOD2_END(req_arg,rsp_arg,"nb_transport",1,1,val); \
    return val; \
  endfunction
// End

`else

`define UVM_BLOCKING_PUT_IMP(imp, TYPE, arg) \
  task put (TYPE arg); \
    imp.put(arg); \
  endtask

`define UVM_NONBLOCKING_PUT_IMP(imp, TYPE, arg) \
  function bit try_put (TYPE arg); \
    return imp.try_put(arg); \
  endfunction \
  function bit can_put(); \
    return imp.can_put(); \
  endfunction

`define UVM_BLOCKING_GET_IMP(imp, TYPE, arg) \
  task get (output TYPE arg); \
    imp.get(arg); \
  endtask

`define UVM_NONBLOCKING_GET_IMP(imp, TYPE, arg) \
  function bit try_get (output TYPE arg); \
    return imp.try_get(arg); \
  endfunction \
  function bit can_get(); \
    return imp.can_get(); \
  endfunction

`define UVM_BLOCKING_PEEK_IMP(imp, TYPE, arg) \
  task peek (output TYPE arg); \
    imp.peek(arg); \
  endtask

`define UVM_NONBLOCKING_PEEK_IMP(imp, TYPE, arg) \
  function bit try_peek (output TYPE arg); \
    return imp.try_peek(arg); \
  endfunction \
  function bit can_peek(); \
    return imp.can_peek(); \
  endfunction

`define UVM_BLOCKING_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg) \
  task transport (REQ req_arg, output RSP rsp_arg); \
    imp.transport(req_arg, rsp_arg); \
  endtask

`define UVM_NONBLOCKING_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg) \
  function bit nb_transport (REQ req_arg, output RSP rsp_arg); \
    return imp.nb_transport(req_arg, rsp_arg); \
  endfunction
`endif

`define UVM_PUT_IMP(imp, TYPE, arg) \
  `UVM_BLOCKING_PUT_IMP(imp, TYPE, arg) \
  `UVM_NONBLOCKING_PUT_IMP(imp, TYPE, arg)

`define UVM_GET_IMP(imp, TYPE, arg) \
  `UVM_BLOCKING_GET_IMP(imp, TYPE, arg) \
  `UVM_NONBLOCKING_GET_IMP(imp, TYPE, arg)

`define UVM_PEEK_IMP(imp, TYPE, arg) \
  `UVM_BLOCKING_PEEK_IMP(imp, TYPE, arg) \
  `UVM_NONBLOCKING_PEEK_IMP(imp, TYPE, arg)

`define UVM_BLOCKING_GET_PEEK_IMP(imp, TYPE, arg) \
  `UVM_BLOCKING_GET_IMP(imp, TYPE, arg) \
  `UVM_BLOCKING_PEEK_IMP(imp, TYPE, arg)

`define UVM_NONBLOCKING_GET_PEEK_IMP(imp, TYPE, arg) \
  `UVM_NONBLOCKING_GET_IMP(imp, TYPE, arg) \
  `UVM_NONBLOCKING_PEEK_IMP(imp, TYPE, arg)

`define UVM_GET_PEEK_IMP(imp, TYPE, arg) \
  `UVM_BLOCKING_GET_PEEK_IMP(imp, TYPE, arg) \
  `UVM_NONBLOCKING_GET_PEEK_IMP(imp, TYPE, arg)

`define UVM_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg) \
  `UVM_BLOCKING_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg) \
  `UVM_NONBLOCKING_TRANSPORT_IMP(imp, REQ, RSP, req_arg, rsp_arg)



`define UVM_TLM_GET_TYPE_NAME(NAME) \
  virtual function string get_type_name(); \
    return NAME; \
  endfunction

`define UVM_PORT_COMMON(MASK,TYPE_NAME) \
  function new (string name, uvm_component parent, \
                int min_size=1, int max_size=1); \
    super.new (name, parent, UVM_PORT, min_size, max_size); \
    m_if_mask = MASK; \
  endfunction \
  `UVM_TLM_GET_TYPE_NAME(TYPE_NAME)

`define UVM_SEQ_PORT(MASK,TYPE_NAME) \
  function new (string name, uvm_component parent, \
                int min_size=0, int max_size=1); \
    super.new (name, parent, UVM_PORT, min_size, max_size); \
    m_if_mask = MASK; \
  endfunction \
  `UVM_TLM_GET_TYPE_NAME(TYPE_NAME)
  
`define UVM_EXPORT_COMMON(MASK,TYPE_NAME) \
  function new (string name, uvm_component parent, \
                int min_size=1, int max_size=1); \
    super.new (name, parent, UVM_EXPORT, min_size, max_size); \
    m_if_mask = MASK; \
  endfunction \
  `UVM_TLM_GET_TYPE_NAME(TYPE_NAME)
  
`define UVM_IMP_COMMON(MASK,TYPE_NAME,IMP) \
  local IMP m_imp; \
  function new (string name, IMP imp); \
    super.new (name, imp, UVM_IMPLEMENTATION, 1, 1); \
    m_imp = imp; \
    m_if_mask = MASK; \
  endfunction \
  `UVM_TLM_GET_TYPE_NAME(TYPE_NAME)

`define UVM_MS_IMP_COMMON(MASK,TYPE_NAME) \
  local this_req_type m_req_imp; \
  local this_rsp_type m_rsp_imp; \
  function new (string name, this_imp_type imp, \
                this_req_type req_imp = null, this_rsp_type rsp_imp = null); \
    super.new (name, imp, UVM_IMPLEMENTATION, 1, 1); \
    if(req_imp==null) $cast(req_imp, imp); \
    if(rsp_imp==null) $cast(rsp_imp, imp); \
    m_req_imp = req_imp; \
    m_rsp_imp = rsp_imp; \
    m_if_mask = MASK; \
  endfunction  \
  `UVM_TLM_GET_TYPE_NAME(TYPE_NAME)

`endif
