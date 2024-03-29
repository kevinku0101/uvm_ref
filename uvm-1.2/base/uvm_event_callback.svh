//
//------------------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
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
//------------------------------------------------------------------------------

typedef class uvm_object;
typedef class uvm_event;

//------------------------------------------------------------------------------
//
// CLASS: uvm_event_callback
//
// The uvm_event_callback class is an abstract class that is used to create
// callback objects which may be attached to <uvm_event#(T)>s. To use, you
// derive a new class and override any or both <pre_trigger> and <post_trigger>.
//
// Callbacks are an alternative to using processes that wait on events. When a
// callback is attached to an event, that callback object's callback function
// is called each time the event is triggered.
//
//------------------------------------------------------------------------------

virtual class uvm_event_callback#(type T=uvm_object) extends uvm_object;

  // Function: new
  //
  // Creates a new callback object.

  function new (string name=""); 
    super.new(name);
  endfunction


  // Function: pre_trigger
  //
  // This callback is called just before triggering the associated event.
  // In a derived class, override this method to implement any pre-trigger
  // functionality.
  //
  // If your callback returns 1, then the event will not trigger and the
  // post-trigger callback is not called. This provides a way for a callback
  // to prevent the event from triggering.
  //
  // In the function, ~e~ is the <uvm_event#(T)> that is being triggered, and ~data~
  // is the optional data associated with the event trigger.

  virtual function bit pre_trigger (uvm_event#(T) e, T data);
    return 0;
  endfunction


  // Function: post_trigger
  //
  // This callback is called after triggering the associated event.
  // In a derived class, override this method to implement any post-trigger
  // functionality.
  //
  //
  // In the function, ~e~ is the <uvm_event#(T)> that is being triggered, and ~data~
  // is the optional data associated with the event trigger.

  virtual function void post_trigger (uvm_event#(T) e, T data);
    return;
  endfunction

`ifndef UVM_CREATE_OPT
  virtual function uvm_object create (string name=""); 
    return null;
  endfunction
`endif

endclass


