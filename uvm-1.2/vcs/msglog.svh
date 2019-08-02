/******************************************************************
 *   Copyright (c) 2009 by Synopsys Inc. - All Rights Reserved    *
 *                                                                *
 *    CONFIDENTIAL AND PROPRIETARY INFORMATION OF SYNOPSYS INC.   *
 ******************************************************************/

`ifndef _VCS_MSGLOG
`define _VCS_MSGLOG

/*
        This file is intended to be included in user code to get the
        $msglog enum constants.   

        Please contact vcs-support@synopsys.com if you have any questions!
*/

package _vcs_msglog;
// -- Define Enums

// _MSG_T constants have the same encoding as (can be interchanged with) vmm_log::types_e
enum int {
    FAILURE = 'h0001,
    NOTE = 'h0002,
    DEBUG = 'h0004,
    REPORT = 'h0008,
    NOTIFY = 'h0010,
    TIMING = 'h0020,
    XHANDLING = 'h0040,
    XACTION = 'h0080,
    PROTOCOL = 'h0100,
    COMMAND = 'h0200,
    CYCLE = 'h0400
} _MSG_T;

// _MSG_S constants have the same encoding as (can be interchanged with) vmm_log::severities_e
enum int {
    FATAL = 'h0001,
    ERROR = 'h0002,
    WARNING = 'h0004,
    NORMAL = 'h0008,
    TRACE = 'h0010,
    DEBUGS = 'h0020,
    VERBOSE = 'h0040,
    HIDDEN = 'h0080,
    IGNORE = 'h0100
} _MSG_S;

// _MSG_R constants
enum int {
    START = 'h0001, 
    FINISH = 'h0002,
    PRED = 'h0004,
    SUCC = 'h0008,
    SUB = 'h0010,  
    PARENT = 'h0020,
    CHILD = 'h0040,
    XTEND = 'h0080,
    USER = 'h0100  // USER RELATION
} _MSG_R;

endpackage
`endif
