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

`ifndef UVM_MSGLOG_REPORT_SERVER 
`define UVM_MSGLOG_REPORT_SERVER
  
// define macros since $msglog does not accept args for msg_type or msg_severity
`define msglog_oneshot(stream, typ, msg_name, sev, hdr, msg) \
  begin \
    $vcdplusmsglog(stream, typ, msg_name, sev, hdr, msg, _vcs_msglog::START); \
    $vcdplusmsglog(stream, typ, msg_name, sev, "", _vcs_msglog::FINISH); \
  end

// decode verbosity and severity
// according to ./base/uvm_object_globals.svh, severity:
//   UVM_INFO=0, UVM_WARNING=1, UVM_ERROR=2, UVM_FATAL=3
// according to ./base/uvm_object_globals.svh, verbosity:
//   UVM_NONE=0, UVM_LOW=100, UVM_MEDIUM=200, UVM_HIGH=300, UVM_FULL=400, UVM_DEBUG=500
`define msglog_decode(stream, typ, msg_name, sev, hdr, msg) \
  case (typ) \
    0   : hdr = {hdr, " [NONE]"}; \
    100 : hdr = {hdr, " [LOW]"}; \
    200 : hdr = {hdr, " [MEDIUM]"}; \
    300 : hdr = {hdr, " [HIGH]"}; \
    400 : hdr = {hdr, " [FULL]"}; \
    500 : hdr = {hdr, " [DEBUG]"}; \
  endcase \
  case (sev) \
    3 : `msglog_oneshot(stream, _vcs_msglog::FAILURE, msg_name, _vcs_msglog::FATAL, hdr, msg) \
    2 : `msglog_oneshot(stream, _vcs_msglog::FAILURE, msg_name, _vcs_msglog::ERROR, hdr, msg) \
    1 : `msglog_oneshot(stream, _vcs_msglog::FAILURE, msg_name, _vcs_msglog::WARNING, hdr, msg) \
    0 : `msglog_oneshot(stream, _vcs_msglog::NOTE, msg_name, _vcs_msglog::NORMAL, hdr, msg) \
    default : `msglog_oneshot(stream, _vcs_msglog::NOTE, msg_name, _vcs_msglog::NORMAL, hdr, msg) \
  endcase

`endif // UVM_MSGLOG_REPORT_SERVER 

