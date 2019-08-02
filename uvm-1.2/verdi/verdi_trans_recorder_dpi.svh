`ifndef VERDI_TRANS_RECORDER_DPI_SVH
`define VERDI_TRANS_RECORDER_DPI_SVH

// Scope

import "DPI-C" context function void fsdbTransDPI_scope_add_logicvec_attribute(output int state, input string scope_fullname, input string attribute_name, input logic [1023:0] attribute, input int numbit, input string options);

import "DPI-C" context function void fsdbTransDPI_scope_add_int_attribute(output int state, input string scope_fullname, input string attribute_name, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_scope_add_string_attribute(output int state, input string scope_fullname, input string attribute_name, input string attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_scope_add_real_attribute(output int state, input string scope_fullname, input string attribute_name, input real attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_scope_add_enum_int_attribute(output int state, input string scope_fullname, input string attribute_name, input int unsigned enum_id, input int attribute, input string options);


// Stream

import "DPI-C" context function int fsdbTransDPI_create_stream_begin(output int state, input string stream_fullname, input string description, input string options);

import "DPI-C" context function void fsdbTransDPI_define_logicvec_attribute(output int state, input int sid, input string attribute_name, input logic [1023:0] attribute, input int numbit, input string options);

import "DPI-C" context function void fsdbTransDPI_define_int_attribute(output int state, input int sid, input string attribute_name, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_define_string_attribute(output int state, input int sid, input string attribute_name, input string attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_define_real_attribute(output int state, input int sid, input string attribute_name, input real attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_define_enum_int_attribute(output int state, input int sid, input string attribute_name, input int unsigned enum_id, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_stream_add_logicvec_attribute(output int state, input int sid, input string attribute_name, input logic [1023:0] attribute, input int numbit, input string options);

import "DPI-C" context function void fsdbTransDPI_stream_add_int_attribute(output int state, input int sid, input string attribute_name, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_stream_add_string_attribute(output int state, input int sid, input string attribute_name, input string attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_stream_add_real_attribute(output int state, input int sid, input string attribute_name, input real attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_stream_add_enum_int_attribute(output int state, input int sid, input string attribute_name, input int unsigned enum_id, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_create_stream_end(output int state, input int sid, input string options);


// Transaction

import "DPI-C" context function longint fsdbTransDPI_begin(output int state, input int sid, input string trans_type, input string options);

import "DPI-C" context function void fsdbTransDPI_set_label(output int state, input longint tid, input string label, input string options);

import "DPI-C" context function void fsdbTransDPI_add_tag(output int state, input longint tid, input string tag, input string options);

import "DPI-C" context function void fsdbTransDPI_add_logicvec_attribute(output int state, input longint tid, input string attribute_name, input logic [1023:0] attribute, input int numbit, input string options);

import "DPI-C" context function void fsdbTransDPI_add_int_attribute(output int state, input longint tid, input string attribute_name, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_add_string_attribute(output int state, input longint tid, input string attribute_name, input string attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_add_real_attribute(output int state, input longint tid, input string attribute_name, input real attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_add_enum_int_attribute(output int state, input longint tid, input string attribute_name, input int unsigned enum_id, input int attribute, input string options);

import "DPI-C" context function void fsdbTransDPI_add_logicvec_attribute_with_expected_value(output int state, input longint tid, input string attribute_name, input logic [1023:0] attribute, input int numbit, input logic [1023:0] expected_val, input string options);

import "DPI-C" context function void fsdbTransDPI_add_int_attribute_with_expected_value(output int state, input longint tid, input string attribute_name, input int attribute, input int expected_val, input string options);

import "DPI-C" context function void fsdbTransDPI_add_string_attribute_with_expected_value(output int state, input longint tid, input string attribute_name, input string attribute, input string expected_val, input string options);

import "DPI-C" context function void fsdbTransDPI_add_real_attribute_with_expected_value(output int state, input longint tid, input string attribute_name, input real attribute, input real expected_val, input string options);

import "DPI-C" context function void fsdbTransDPI_add_enum_int_attribute_with_expected_value(output int state, input longint tid, input string attribute_name, input int unsigned enum_id, input int attribute, input int expected_val, input string options);

import "DPI-C" context function void fsdbTransDPI_end(output int state, input longint tid, input string options);

import "DPI-C" context function void fsdbTransDPI_add_relation(output int state, input string rel_name, input longint master_tid, input longint slave_tid, input string options);


// Misc

import "DPI-C" context function int unsigned fsdbTransDPI_get_enum_id(output int state, input string enum_var_name);

import "DPI-C" context function string fsdbTransDPI_get_class_str(output int state, input string class_var_name, input string options);


`endif // VERDI_TRANS_RECORDER_DPI_SVH
