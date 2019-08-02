//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// UVM-AMS Top File
//
//-----------------------------------------------------------------------------

`ifndef __UVM_AMS_SV
`define __UVM_AMS_SV

`ifndef  UVM_PKG_SV
`include "uvm_pkg.sv"  	// DO NOT INLINE
`endif
  
import uvm_pkg::*; 

//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// Description : Math functions
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef _SV_AMS_MATH_SV
`define _SV_AMS_MATH_SV

////////////////////////////////////////////////////////////
// Class: sv_ams_const
//    The <sv_ams_const> class provides pre-defined constant that
// are useful for modeling generators and analog behaviors
class sv_ams_const;
  // Const: PI
  static const real PI=3.14159263;
  // Const: HALF_PI
  static const real HALF_PI=PI/2.0;
  // Const: TWO_PI
  static const real TWO_PI=PI*2.0;
endclass

////////////////////////////////////////////////////////////
// Package: sv_ams_math
//
//    The <sv_ams_math> package provides pre-defined C functions
// that are useful for modeling generators and analog behaviors
package sv_ams_math;
  
  // Function: cos
  //   This function returns the cosine of *a*.
  import "DPI-C" function real cos(input real a);
  // Function: cosh
  //   This function returns the hyperbolic cosine of *a*
  import "DPI-C" function real cosh(input real a);
  // Function: acos
  //   This function returns the inverse cosine (arccosine) of *a*.
  import "DPI-C" function real acos(input real a);
  // Function: acosh
  //   This function returns the inverse hyperbolic cosine of *a*
  import "DPI-C" function real acosh(input real a);

  // Function: sin
  //   This function returns the sine of *a*.
  import "DPI-C" function real sin(input real a);
  // Function: sinh
  //   This function Returns the hyperbolic sine of *a*
  import "DPI-C" function real sinh(input real a);
  // Function: asin
  //   This function returns the inverse sine (arcsine) of *a*.
  import "DPI-C" function real asin(input real a);
  // Function: asinh
  //   This function returns the inverse hyperbolic sine of *a*
  import "DPI-C" function real asinh(input real a);

  // Function: tan
  //   This function returns the tangent of *a*
  import "DPI-C" function real tan(input real a);
  // Function: tanh
  //   This function returns the hyperbolic tangent of *a*
  import "DPI-C" function real tanh(input real a);
  // Function: atan
  //   This function returns the inverse tangent (arctangent) of *a*.
  import "DPI-C" function real atan(input real a);
  // Function: atanh
  //   This function returns the inverse hyperbolic tangent of *a*
  import "DPI-C" function real atanh(input real a);
  // Function: atan2
  //   This function retunrs the inverse tangent (arctangent) of the real parts of *a* and *b*
  import "DPI-C" function real atan2(input real a, input real b);

  // Function: exp
  //   This function returns the base-e exponential function of *a*, which is the e number raised to the power *a* ...
  import "DPI-C" function real exp(input real a);
  // Function: expm1
  //   This function returns exp( *a* ) - 1
  import "DPI-C" function real expm1(input real a);
  // Function: log
  //   This function returns the base-e logarithm of *a*
  import "DPI-C" function real log(input real a);
  // Function: log10
  //   This function returns the base-10 logarithm of *a*
  import "DPI-C" function real log10(input real a);
  // Function: ilogb
  //   This function returns an unbiased exponent
  import "DPI-C" function int  ilogb(input real a);
  // Function: log1p
  //   This function returns log_e(1.0 + *a* )
  import "DPI-C" function real log1p(input real a);
  // Function: logb
  //   This function returns radix-independent exponent
  import "DPI-C" function real logb(input real a);

  // Function: fabs
  //   This function returns the absolute value of *a*
  import "DPI-C" function real fabs(input real a);
  // Function: ceil
  //   This function Returns the smallest integral value that is not less than *a*
  import "DPI-C" function real ceil(input real a);
  // Function: floor
  //   This function returns the largest integral value that is not greater than *a*
  import "DPI-C" function real floor(input real a);
  // Function: fmod
  //   This function Returns the floating-point remainder of numerator/denominator (*a* / *b*).
  //   The remainder of a division operation is the result of subtracting the integral quotient multiplied by the denominator from the numerator:
  //     remainder = numerator - quotient * denominator
  import "DPI-C" function real fmod(input real a, input real b);
  // Function: frexp
  //   This function Breaks the floating point number *a* into its binary significand 
  // (a floating point value between 0.5(included) and 1.0(excluded)) and an integral *b* for 2, such that:
  //     *a* = significand * 2 exponent
  // The exponent is stored in the location pointed by *b*, and the significand is the value returned by the function.
  // If *a* is zero, both parts (significand and exponent) are zero.
  import "DPI-C" function real frexp(input real a, input integer b); // ref for 2nd arg
  // Function: ldexp
  //   This function Returns the resulting floating point value from multiplying *a* (the significand) 
  // by 2 raised to the power of *b* (the exponent).
  import "DPI-C" function real ldexp(input real a, input integer b);

  // Function: modf
  //   This function Break into fractional and integral parts
  //   Breaks *a* into two parts: the integer part (stored in the object pointed by *b*) and the fractional part (returned by the function).
  //   Each part has the same sign as *a*.
  import "DPI-C" function real modf(input real a, input real b); // ref for 2nd arg

  // Function: pow
  //   This function returns *a* raised to the power *b*
  import "DPI-C" function real pow(input real a, input real b);
  // Function: sqrt
  //   This function returns the square root of *a*
  import "DPI-C" function real sqrt(input real a);
  // Function: hypot
  //   This function returns the length of the hypotenuse of a right-angled triangle with sides of length
  //   *a* and *b*.
  import "DPI-C" function real hypot(input real a, input real b);

  // Function: erf
  //   This function returns the error function of x; defined as
  //   erf(x) = 2/sqrt(pi)* integral from 0 to x of exp(-t*t) dt
  //   The erfc() function returns the complementary error function of x, that is 1.0 - erf(x).
  import "DPI-C" function real erf(input real a);
  // Function: erfc
  //   This function returns the complementary error function 1.0 - erf(x).
  import "DPI-C" function real erfc(input real a);

  // Function: gamma
  //   This function returns the gamma function of *a*
  import "DPI-C" function real gamma(input real a);
  // Function: lgamma
  //   This function returns the logarithm gamma function of *a*
  import "DPI-C" function real lgamma(input real a);

  // Function: j0
  //   This function returns the relevant Bessel value of x of the first kind of order 0
  import "DPI-C" function real j0(input real a);
  // Function: j1
  //   This function returns the relevant Bessel value of x of the first kind of order 1
  import "DPI-C" function real j1(input real a);
  // Function: jn
  //   This function returns the relevant Bessel value of x of the first kind of order n
  import "DPI-C" function real jn(input int i, input real a);

  // Function: y0
  //   This function returns the relevant Bessel value of x of the second kind of order 0
  import "DPI-C" function real y0(input real a);
  // Function: y1
  //   This function returns the relevant Bessel value of x of the second kind of order 1
  import "DPI-C" function real y1(input real a);
  // Function: yn
  //   This function returns the relevant Bessel value of x of the second kind of order n
  import "DPI-C" function real yn(input int i, input real a);

  // Function: isnan
  //   This function returns a non-zero value if value *a* is "not-a-number" (NaN), and 0 otherwise.
  import "DPI-C" function int  isnan(input real a);

  // Function: cbrt
  //   This function returns the real cube root of their argument *a*.
  import "DPI-C" function real cbrt(input real a);

  // Function: nextafter
  //   This function returns the next representable floating-point value following x in
  //   the direction of y.  Thus, if y is less than x, nextafter() shall return the largest 
  //   representable floating-point number less than x.
  import "DPI-C" function real nextafter(input real a, input real b);

  // Function: remainder
  //   This function returns the floating-point remainder r= *a*- n*y* when *y* is non-zero. The value n is the integral value nearest the
  //   exact value *a*/ *y*.  When |n-*a*/*y*|=0.5, the value n is chosen to be even.
  import "DPI-C" function real remainder(input real a, input real b);

  // Function: rint
  //   This function returns the integral value (represented as a double) nearest *a* in the direction of the current rounding mode
  import "DPI-C" function real rint(input real a);
  // Function: scalb
  //   This function returns  *a* * r** *b*, where r is the radix of the machine floating-point arithmetic
  import "DPI-C" function real scalb(input real a, input real b);
endpackage  
      
////////////////////////////////////////////////////////////
// Class: sv_ams_units
//   This class defines handy enumerated types for voltage, current, frequency and time.
//   It also provides functions that returns scale factor for a given unit.
//
// Example
//|
//| module top;
//|   real r;
//|   sv_ams_real z=new(0.0);
//|   initial begin
//|      r = z.urandom(0,100) * sv_ams_units::get_current_unit(sv_ams_units::uA);
//|   end
//| endmodule
//|

class sv_ams_units;
  import sv_ams_math::*;

  // const: one_kA 
  // Defines scale factor for 1kA
  static const real one_kA = get_current_unit(kA);
  // const: one_A 
  // Defines scale factor for 1A
  static const real one_A  = get_current_unit(A);
  // const: one_mA 
  // Defines scale factor for 1mA
  static const real one_mA = get_current_unit(mA);
  // const: one_uA 
  // Defines scale factor for 1uA
  static const real one_uA = get_current_unit(uA);
  // const: one_nA 
  // Defines scale factor for 1nA
  static const real one_nA = get_current_unit(nA);

  // const: one_kV 
  // Defines scale factor for 1kV
  static const real one_kV = get_voltage_unit(kV);
  // const: one_V 
  // Defines scale factor for 1V
  static const real one_V  = get_voltage_unit(V);
  // const: one_mV 
  // Defines scale factor for 1mV
  static const real one_mV = get_voltage_unit(mV);
  // const: one_uV 
  // Defines scale factor for 1uV
  static const real one_uV = get_voltage_unit(uV);
  // const: one_nV 
  // Defines scale factor for 1nV
  static const real one_nV = get_voltage_unit(nV);

  // const: one_GHz 
  // Defines scale factor for 1GHz
  static const real one_GHz = get_frequency_unit(GHz);
  // const: one_MHz 
  // Defines scale factor for 1MHz
  static const real one_MHz = get_frequency_unit(MHz);
  // const: one_kHz 
  // Defines scale factor for 1kHz
  static const real one_kHz = get_frequency_unit(kHz);
  // const: one_Hz 
  // Defines scale factor for 1Hz
  static const real one_Hz  = get_frequency_unit(Hz);

  // const: one_ns 
  // Defines scale factor for 1ns
  static const real one_ns = get_time_unit(ns);
  // const: one_us 
  // Defines scale factor for 1us
  static const real one_us = get_time_unit(us);
  // const: one_ms 
  // Defines scale factor for 1ms
  static const real one_ms = get_time_unit(ms);
  // const: one_s 
  // Defines scale factor for 1s
  static const real one_s  = get_time_unit(s);

  // Enum: current_e
  // Defines enumerated types for current
  typedef enum int {
                     kA=+3, 
                      A= 0,
                     mA=-3, 
                     uA=-6, 
                     nA=-9
                    } current_e;

  // Enum: voltage_e
  // Defines enumerated types for voltage
  typedef enum int {
                     kV=+3, 
                      V= 0,
                     mV=-3, 
                     uV=-6, 
                     nV=-9
                    } voltage_e;

  // Enum: frequency_e
  // Defines enumerated types for frequency
  typedef enum int {
                     GHz=+9,
                     MHz=+6,
                     kHz=+3,
                      Hz= 0
                    } frequency_e;

  // Enum: time_e
  // Defines enumerated types for time
  typedef enum int {
                     ns=-9,
                     us=-6,
                     ms=-3,
                      s= 0
                    } time_e;

  // Function: get_current_unit
  //   This function returns the scale factor for a given current unit
  static function real get_current_unit(current_e c);
    return pow(10.0,c);
  endfunction

  // Function: get_voltage_unit
  //   This function returns the scale factor for a given voltage unit
  static function real get_voltage_unit(voltage_e v);
    return pow(10.0,v);
  endfunction

  // Function: get_frequency_unit
  //   This function returns the scale factor for a given frequency unit
  static function real get_frequency_unit(frequency_e f);
    return pow(10.0,f);
  endfunction

  // Function: get_time_unit
  //   This function returns the scale factor for a given time unit
  static function real get_time_unit(time_e t);
    return pow(10.0,t);
  endfunction

endclass

`endif
//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// SV-AMS Source Generators
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef _SV_AMS_IF_SV
`define _SV_AMS_IF_SV

////////////////////////////////////////////////////////////
// Class: ams_src_if
//
//|	interface ams_src_if(input bit clk);
//
// The <ams_src_if> interface contains the <v> real signal
// that can be attached to an analog IP.
//
interface ams_src_if(input bit clk);
   initial 
    uvm_resource_db#(virtual ams_src_if)::set("*", "uvm_ams_src_if", interface::self());

  // real: v 
  //   Real value that can be attached to an analog IP
  real v;

  // Property: dck 
  //	Provides a clocking block with synchronous write-only access to <v>
  clocking dck @(posedge clk);
    default output #0;
    output v;
  endclocking: dck

  // Property: sck 
  //	Provides a clocking block with synchronous read-only access to <v>
  clocking sck @(posedge clk);
    default input #0;
    input v;
  endclocking: sck

  // Property: drive 
  //	Provides a modport with synchronous write-only access to <v>
  modport drive(clocking dck);

  // Property: sample 
  //	Provides a modport with synchronous read-only access to <v>
  modport sample(clocking sck);

  // Property: async_sample 
  //	Provides a modport with asynchronous read/write only access to <v>
  modport async_sample(input clk, input v);

endinterface: ams_src_if

`ifdef __UVM_AMS_SV
////////////////////////////////////////////////////////////
// Class: ams_src_if_wrapper
//
// This class wraps a <ams_src_if> virtual interface to
// an sv_object that can be replaced by factory
//
////////////////////////////////////////////////////////////
class ams_src_if_wrapper extends uvm_object;
  virtual ams_src_if aif;

  // Function: new
  // The <new> function is used to construct <ams_src_if_wrapper> objects.
  //
  // Arguments:
  // - *name* to define the wrapper name
  // - *aif* to pass a handle to the the interface object
  function new(string name, virtual ams_src_if aif);
    super.new(name);
    this.aif = aif;
  endfunction
endclass: ams_src_if_wrapper
`endif

`endif
//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// Description : SV Real Base class
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef _SV_AMS_REAL_SV
`define _SV_AMS_REAL_SV
`ifndef SV_AMS_REAL_DEF_ACCURACY
`define SV_AMS_REAL_DEF_ACCURACY 1.0E3
`endif

`ifdef UVM_POST_VERSION_1_1
`ifdef UVM_OBJECT_DO_NOT_NEED_CONSTRUCTOR
`define UVM_SV_REAL_COMPAT_MODE
`endif
`else
`define UVM_SV_REAL_COMPAT_MODE
`endif
  
////////////////////////////////////////////////////////////
// Class: sv_ams_real
//   This class provides easy conversion from real to integer
//   and integer to real. Using this conversion, it becomes possible
//   to randomize a real and perfom functional coverage of real
//
class sv_ams_real extends uvm_sequence_item;
  rand int i;
  protected real r;
  protected real acc;

  `uvm_object_utils_begin(sv_ams_real)
    `uvm_field_int(i, UVM_ALL_ON)
    `uvm_field_real(r, UVM_ALL_ON)
    `uvm_field_real(acc, UVM_ALL_ON)
  `uvm_object_utils_end
    
  // Function: new
  //
  // The <new> function constructs <sv_ams_real> objects.
  //
  // Arguments:
  // - *r* defines the real value
  // - *acc* determines the internal accuracy used for converting real to 
  //    integer in the underlying <sv_ams_real> objects. 
  // - *name* defines the object instance name
  // - Handle to *parent* allows <sv_ams_real> object to recorded
`ifdef UVM_SV_REAL_COMPAT_MODE
  function new(real r=0.0, 
               real acc=`SV_AMS_REAL_DEF_ACCURACY, 
               string name="");
`else
  function new(string name = "",
               real r=0.0, 
               real acc=`SV_AMS_REAL_DEF_ACCURACY);
`endif
    super.new(name);
    this.r = r;
    this.acc = acc;
    this.update_int();
  endfunction


  // Function: set_real
  //   This function sets <sv_ams_real> object real value.
  //
  // Arguments:
  // - *r* defines the real value
  virtual function void set_real(real r);
    this.r = r;
    this.update_int();
  endfunction

  function void update_real();
    this.r = this.i / this.acc;
  endfunction

  function void update_int();
    this.i = this.r * this.acc;
  endfunction

  // Function: get_real
  //   This function returns the <sv_ams_real> object real value.
  virtual function real get_real();
    return this.r;
  endfunction

  // Function: get_int
  //   This function returns the <sv_ams_real> object integer value.
  virtual function int get_int();
    return this.i;
  endfunction

  // Function: urandom
  //   This function randomize a <sv_ams_real> object.
  //   The random distribution is based upon *min*, *max* values
  //   This function returns the random value.
  virtual function real urandom(real min, real max);
    if(max<=min)
      `uvm_error(get_name(), $psprintf("Argument max=%f is less than min=%f", max, min)) 
    else begin
      int mi, ma;
      mi = min * this.acc;
      ma = max * this.acc;
      this.i = ($urandom() % (ma-mi)) + mi;
      this.update_real();
      return this.r;
    end
  endfunction

  // Function: cmp
  //   This function compares *a* and *b* reals with a given *tolerance* (1% by default).
  //
  //   It returns 1 if these reals are equal, 0 otherwise.   
  //   if *b* == 0.0, it compares *a* vs. *tolerance*
  static function bit cmp(real a, real b, real tolerance=1.0E-2);
    real t;

    if(b==0.0)
      t = a;
    else
      t = (a-b)/b;

    if (fabs(t) > tolerance)
      return 0;
    else
      return 1;
  endfunction
    
  function void post_randomize();
    this.update_real();
  endfunction
    
endclass: sv_ams_real
`endif
  
//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// SV-AMS Source Generators
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef _SV_AMS_VOLTAGE_GEN_SV
`define _SV_AMS_VOLTAGE_GEN_SV

`define _SV_AMS_REPORT(a,b) \
      	`uvm_info(a, b, UVM_HIGH)

import sv_ams_math::*;

////////////////////////////////////////////////////////////
// Class: sv_ams_generic_src
//
//    The <sv_ams_generic_src> virtual class provides the foundation for 
//    implementing AMS source generators, such as voltage of current injectors.
//
//    It is *virtual* and should be *extended*.
//
//    Note that it can be used for implementing custom source generators

virtual class sv_ams_generic_src extends uvm_driver#(sv_ams_real);

  protected virtual ams_src_if /*.drive*/ aif; //AK: modport gives VCS issues
  uvm_seq_item_pull_port #(sv_ams_real) sv_ams_pull_port;

  // Real: v
  //   Holds the analog value of <sv_ams_generic_src> object.
  //   This member is aimed at retaining a  voltage node.
  //   This member is supposed to be updated by the <get_voltage> method
  rand sv_ams_real v;

  // Real: v_min
  //   Holds the minimum voltage of <sv_ams_generic_src> object
  sv_ams_real v_min;

  // Real: v_max
  //   Holds the maximum voltage of <sv_ams_generic_src> object
  sv_ams_real v_max;

  real accuracy;  
  real last_time;
  real half_period=999999999999.9;
  real time_precision=1.0E-9;

  // Function: new
  //
  // The <new> function is used to construct <sv_ams_generic_checker> object derivatives.
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
`ifdef UVM_SV_REAL_COMPAT_MODE
    this.v = new();
`else
    this.v = new("rand_v");
`endif
    sv_ams_pull_port = new("sv_ams_pull_port", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // retrieve a virtual interface from the resource database by name.
    if(!uvm_resource_db#(virtual ams_src_if)::read_by_name(get_full_name(), "uvm_ams_src_if", aif)) 
       `uvm_error("TESTERROR", $sformatf("%s %s", "no bus interface uvm_ams_src_if available at path=", get_full_name()));
  endfunction 
   
  // Function: set_time_precision
  //
  //  This function sets the time precision of the source generator. 
  //  It must be called to ensure the source generator time precision 
  //  is consistent with its enclosing module/class.
  //
  // Arguments:
  // - *p* defines the time precision in second, you should constants as defined in <sv_ams_units>
  //   such as <sv_ams_units::one_us> for 1us, etc.
  //
  //  Following examples shows how to construct a <sv_ams_sawtooth_voltage_gen>
  //  object that extends <sv_ams_generic_src>. Since the module time precision 
  //  is changed to 1us, the <set_time_precision> is called with a value of 1E-6.
  //
  //| `timescale 1us/1ns
  //| module top;
  //|   // Construct a sawtooth generator that ranges between -1.25V to +1.25V at 2.5MHz
  //|   sv_ams_sawtooth_voltage_gen saw_gen = new(-1.25, +1.25, 2.5E3);
  //|   initial begin
  //|      saw_gen.set_time_precision(sv_ams_units::one_us);
  //|   end
  //| endmodule
  //|
  virtual function void set_time_precision(real p);
    this.time_precision = p;
  endfunction
    
  // Function: set_v_range
  //
  //  This function sets the min/max voltages of the source generator. 
  //  It can be called to override the default min/max voltages that are passed during 
  //  the source generator construction
  //
  // Arguments:
  // - *min* defines the min voltage of the source generator. It is expressed in V
  // - *max* defines the max voltage of the source generator. It is expressed in V
  //
  virtual function void set_v_range(real v_min, real v_max);
`ifdef UVM_SV_REAL_COMPAT_MODE
    this.v_min = new(v_min,this.accuracy);
    this.v_max = new(v_max,this.accuracy);
`else
    this.v_min = new("v_min",v_min,this.accuracy);
    this.v_max = new("v_max",v_max,this.accuracy);
`endif
    this.v = new(0);
  endfunction

  // Function: get_v_range
  //
  //  This function returns the min/max voltages of the source generator. 
  //
  // Arguments:
  // - *min* returns the min voltage of the source generator. It is expressed in V
  // - *max* returns the max voltage of the source generator. It is expressed in V
  //
  virtual function void get_v_range(output real min, output real max);
    min = this.v_min.get_real();
    max = this.v_max.get_real();
  endfunction

  // Function: get_time
  //
  //  This function returns the current simulator time (in s).
  //  Note that it is factored with the simulator time precision that 
  //  can be overriden with the <set_time_precision> function
  //
  virtual function real get_time();
    return ($realtime - this.last_time) * this.time_precision;
  endfunction

  // Function: set_half_period
  //
  //  This function sets the source generator half period.
  //  You simply need to pass the source generator frequency 
  //
  // Arguments:
  // - *f* defines the source generator frequency. It is expressed in Hz
  //
  virtual function real set_half_period(real f);
    this.half_period = 0.5 / (f*time_precision);
  endfunction

  // Function: get_half_period
  //  This function returns the source generator half period (in s).
  virtual function real get_half_period();
    return half_period;
  endfunction

  // Function: reset
  //  This function reset the source generator.
  //  This is necessry when the source generator paramenters have been 
  //  modified or when it has been stopped before
  virtual function void reset();
    this.last_time = $realtime;
  endfunction

  // Function: get_voltage
  //
  //  This function returns the source voltage generator (in V).
  //  It should be overwritte with the source generator equation
  virtual function real get_voltage();
    return this.v.get_real();
  endfunction

  virtual task run();
    real v;
    fork
       while(1) begin 
        @(this.aif.dck);
	  v = get_voltage();
        this.aif.dck.v <= v;
        `_SV_AMS_REPORT(get_full_name(), $psprintf("Driving V=%f", this.aif.v))
    end
    join_none
  endtask   
  
endclass


////////////////////////////////////////////////////////////
// Class: sv_ams_rand_voltage_gen
//
//  The <sv_ams_rand_voltage_gen> class provides 
//  constrained random generation
//  of real value that can be used to drive analog signals
//
//  It is a parameterized class with following parameters
//    - VMIN: Min random voltage value (default=0V)
//    - VMAX: Max random voltage value (default=1V)
//    - ACC:  Accuracy (default=1mV)
//      This parameter can be used to determine the internal
//      accuracy used for converting real to integer in the underlying <sv_ams_real>  
//
class sv_ams_rand_voltage_gen #(real VMIN=0.0, 
                                     VMAX=1.0, 
                                     ACC=`SV_AMS_REAL_DEF_ACCURACY) 
                              extends sv_ams_generic_src;

  static string class_name = "Rand";

  //////////////////////////////////////////////////////
  // Function: new
  //
  // The <new> function is used to construct <sv_ams_rand_voltage_gen> objects.
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.v_min = new(VMIN);
    this.v_max = new(VMAX);
    this.accuracy =ACC; 
  endfunction
    
  // Function: get_voltage
  //
  //  This function returns the random voltage generator (in V).
  //  The voltage is randomly generated to provide a value that is
  // comprised betwen *v_min* and *v_max*.
  virtual function real get_voltage();
    this.randomize();
    `_SV_AMS_REPORT(class_name, $psprintf("Driving V=%f", this.v.get_real()))
    return this.v.get_real();
  endfunction

   constraint volt_range {
     this.v.i >= this.v_min.i;
     this.v.i <= this.v_max.i;
   }
endclass

////////////////////////////////////////////////////////////
// Class: sv_ams_sawtooth_voltage_gen
//
//  The <sv_ams_sawtooth_voltage_gen> class provides generation
//  of sawtooth-like real value that can be used to drive analog signals

class sv_ams_sawtooth_voltage_gen #(real VMIN=0.0, 
                                         VMAX=1.0, 
                                         F=1.0E6, 
                                         ACC=`SV_AMS_REAL_DEF_ACCURACY) 
                                  extends sv_ams_generic_src;

  static string class_name = "Sawtooth";

  local real vdd;
  local real delta;


  //////////////////////////////////////////////////////
  // Function: new
  //
  // The <new> function is used to construct <sv_ams_sawtooth_voltage_gen> 
  // objects.
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.v_min = new(VMIN);
    this.v_max = new(VMAX);
    this.accuracy =ACC; 
    this.set_frequency(F);
  endfunction

  // Function: get_voltage
  //
  //  This function returns the voltage of the _sawtooth_ generator (in V).
  //  The voltage is generated to provide a value that is
  //  comprised betwen *v_min* and *v_max* to follow a _sawtooth_ shape
  //  at a given frequency
  virtual function real get_voltage();
    real r = fmod(this.get_time() * delta, vdd) + this.v_min.get_real();
    this.v.set_real(r);
    `_SV_AMS_REPORT(class_name, $psprintf("Driving V=%f", this.v.get_real()))
    return r;
  endfunction

  // Function: set_frequency
  //
  // The <set_frequency> function can 
  // be used to change the sawtooth voltage generator frequency
  //
  // Arguments:
  // - *f* defines the new sawtooth voltage generator frequency
  virtual function void set_frequency(real f);
    this.vdd = this.v_max.get_real() - this.v_min.get_real();
    this.delta = this.vdd * f;
    this.set_half_period(f);
  endfunction


  // Function: set_v_range
  //
  //  This function sets the min/max voltages of the sawtooth source generator. 
  //  It can be called to override the default min/max voltages that are passed during 
  //  the source generator construction
  //
  // Arguments:
  // - *min* defines the min voltage of the source generator. It is expressed in V
  // - *max* defines the max voltage of the source generator. It is expressed in V
  //
  virtual function void set_v_range(real v_min, real v_max);
    super.set_v_range(v_min, v_max);
    this.vdd = this.v_max.get_real() - this.v_min.get_real();
  endfunction

endclass

////////////////////////////////////////////////////////////
// Class: sv_ams_sine_voltage_gen
//
//  The <sv_ams_sine_voltage_gen> class provides generation
//  of _sine-like_ real value that can be used to drive analog signals

class sv_ams_sine_voltage_gen #(real VMIN=0.0, 
                                     VMAX=1.0, 
                                     F=1.0E6, 
                                     ACC=`SV_AMS_REAL_DEF_ACCURACY) 
                                  extends sv_ams_generic_src;
  `uvm_component_param_utils(sv_ams_sine_voltage_gen#(VMIN, VMAX, F, ACC))
  static string class_name = "Sine";
  local real omega;
  local real v_mid;
  local real last_phase;

  //////////////////////////////////////////////////////
  // Function: new
  //
  // The <new> function is used to construct <sv_ams_sine_voltage_gen> 
  // objects.
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.v_min = new;
    this.v_max = new;
    this.accuracy = ACC; 
    this.set_v_range(VMIN, VMAX);
    this.set_frequency(F);
    this.last_phase = 0.0;
  endfunction
    
  function real get_phase();
    return fmod(omega*this.get_time(),sv_ams_const::TWO_PI);
  endfunction
    
  // Function: get_voltage
  //
  //  This function returns the voltage of _sine_ generator (in V).
  //  The voltage is generated to provide a value that is
  // comprised betwen *v_min* and *v_max* with a _sine_ shape at a given frequency *f*
  virtual function real get_voltage();
    real phase = get_phase() - this.last_phase;
    real r = (1+sin(phase))*v_mid+this.v_min.get_real();
    this.v.set_real(r);
    `_SV_AMS_REPORT(class_name, $psprintf("Driving V=%f Ph=%f V=%f-%f", this.v.get_real(), phase, v_min.get_real(), v_mid))
    return r;
  endfunction

  // Function: set_frequency
  //
  // The <set_frequency> function changes the _sine_ generator frequency
  //
  // Arguments:
  // - *f* defines the new _sine_ generator frequency
  virtual function void set_frequency(real f);
    real phase = fmod(get_phase() - this.last_phase, sv_ams_const::TWO_PI);
    this.omega = sv_ams_const::TWO_PI*f;
    this.set_half_period(f);
    this.last_phase = fmod(get_phase() - phase, sv_ams_const::TWO_PI);
  endfunction

  // Function: set_v_range
  //
  //  This function sets the min/max voltages of the _sine_ source generator. 
  //  It can be called to override the default min/max voltages that are passed during 
  //  the source generator construction
  //
  // Arguments:
  // - *min* defines the min voltage of the source generator. It is expressed in V
  // - *max* defines the max voltage of the source generator. It is expressed in V
  //
  virtual function void set_v_range(real v_min, real v_max);
    super.set_v_range(v_min, v_max);
    this.v_mid = (v_max-v_min)/2.0;
  endfunction

endclass

////////////////////////////////////////////////////////////
// Class: sv_ams_square_voltage_gen
//
//  The <sv_ams_square_voltage_gen> class provides generation
//  of _square-like_ real value that can be used to drive analog signals

class sv_ams_square_voltage_gen #(real VMIN=0.0, 
                                       VMAX=1.0, 
                                       F=1.0E6, 
                                       DUTY=0.5,
                                       ACC=`SV_AMS_REAL_DEF_ACCURACY) 
                                   extends sv_ams_generic_src;
  static string class_name = "Square";
  local real omega;
  local real v_mid;
  local real theta;

  //////////////////////////////////////////////////////
  // Function: new
  //
  // The <new> function is used to construct <sv_ams_square_voltage_gen> 
  // objects.
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.v_min = new;
    this.v_max = new;
    this.accuracy = ACC; 
    this.set_v_range(VMIN, VMAX);
    this.set_frequency(F,DUTY);
  endfunction

  function real sgn(real a);
    sgn=(a==0)?0:(a<0)?-1:+1;
  endfunction

  // Function: get_voltage
  //
  //  This function returns the _square_ voltage generator (in V).
  //  The voltage is generated to provide a value that is
  // comprised betwen *v_min* and *v_max* with a _square_ shape at a 
  // given frequency *f* and duty cycle *duty*.
  virtual function real get_voltage();
    real r = (1+sgn(sin(omega*this.get_time())-sin(theta)))*v_mid +
             this.v_min.get_real();
    this.v.set_real(r);
    `_SV_AMS_REPORT(class_name, $psprintf("Driving V=%f V=%f", this.v.get_real(), r))
    return r;
  endfunction

  // Function: set_frequency
  //
  // The <set_frequency> function changes
  // the frequency of the square voltage generator 
  //
  // Arguments:
  // - *f* defines the new _square_ voltage generator frequency
  virtual function void set_frequency(real f, real duty);
    this.omega = sv_ams_const::TWO_PI*f;
    this.theta = (duty == 0.5)? 0 : (duty <0.5)?sv_ams_const::PI*(0.5-duty):sv_ams_const::PI*(0.5+duty);
    this.set_half_period(f);
  endfunction

  // Function: set_v_range
  //
  //  This function sets the min/max voltages of the _square_ voltage generator. 
  //  It can be called to override the default min/max voltages that are passed during 
  //  the source generator construction
  //
  // Arguments:
  // - *min* defines the min voltage of the source generator. It is expressed in V
  // - *max* defines the max voltage of the source generator. It is expressed in V
  //
  virtual function void set_v_range(real v_min, real v_max);
    super.set_v_range(v_min, v_max);
    this.v_mid = (v_max-v_min)/2.0;
  endfunction
endclass

`endif

//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// Description : AMS Checkers
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef _SV_AMS_CHECKERS_SV_
`define _SV_AMS_CHECKERS_SV_

////////////////////////////////////////////////////////////
// Class: sv_ams_generic_types
//   This class defines a generic SV types
//

class sv_ams_generic_types;
   // Enum: mode_e
  // This enumerated type defines available sychronization schemes
  typedef enum {
                SYNCHRONOUS,
                ASYNCHRONOUS_REAL,
                ASYNCHRONOUS_SPICE,
                ASYNCHRONOUS_VAMS
                } mode_e;

  // Enum: type_e
  // This enumerated type defines available checkers
  typedef enum {
                THRESHOLD,
                WINDOW,
                STABLE,
                FRAME,
                SLOPE
                } type_e;
endclass

////////////////////////////////////////////////////////////
// Class: sv_ams_generic_checker
//   This class defines a generic SV checker that should be derived
//   for verifying a given property.
//  The <sv_ams_generic_checker> class allows the checker to become
//  controllable and attached to an <ams_src_if> interface, which
//  can monitor analog signal synchronously or asynchronously.
//
//    It is *virtual* and should be *extended*.

virtual class sv_ams_generic_checker#(sv_ams_generic_types::mode_e MODE = sv_ams_generic_types::SYNCHRONOUS) extends uvm_driver#(sv_ams_real);
  

  protected virtual ams_src_if aif;
  bit started;

  // Function: new
  //
  // The <new> function is used to construct <sv_ams_generic_checker> object derivatives.
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // Function: build_phase
  // Assigns the virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_resource_db#(virtual ams_src_if)::read_by_name(get_full_name(), "uvm_ams_src_if", aif)) 
      `uvm_error("TESTERROR", $sformatf("%s %s", "no bus interface uvm_ams_src_if available at path=", get_full_name()));

    this.aif = aif;
  endfunction 
 
  // Function: dump_msg
  //  The <dump_msg> function dumps messages with a given severity level.
  //  It ignores the message if the severity is below the sv severity.
  //
  // Arguments:
  //  - *msg* contains the message to be issued
  function void dump_msg(string msg);
    `uvm_info(get_full_name(), msg, UVM_LOW);
  endfunction

  // Task: sample
  //   This task should be overriden. It implement the checker sampling scheme
  //   i.e. when to perform the check
  virtual protected task sample();
      if(MODE==sv_ams_generic_types::SYNCHRONOUS)
         @(this.aif.sck);
      else
         @(this.aif.sck.v); // TO DO, Add support for VAMS, SPICE, etc.
  endtask

  // Task: check_assert
  //   This task should be overriden. It implement the checker behavior.
  //   i.e. what to verify
  virtual protected task check_assert();
    `uvm_fatal(get_name(), $psprintf("You need to override %M"));
  endtask

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
    while(1) begin
      wait(started == 1);
      this.sample();
      this.check_assert();
    end
    join_none
  endtask

endclass

////////////////////////////////////////////////////////////
// Class: sv_ams_threshold_checker
//   This transactor checks that a signal as specified
//   in its interface doesn't rise or fall above/below a pre-defined threshold.
//   The signal direction and threshold are defined with
//   the *THR* and *DIR* parameters
//
// _Parameters_:
//  - *THR* defines the <sv_ams_threshold_checker> threshold value (in V) 
//  - *DIR* defines the <sv_ams_threshold_checker> direction value.
//    (+1: rising, -1: falling) 
class sv_ams_threshold_checker #(real THR=0.0, int DIR=1,
                                  sv_ams_generic_types::mode_e MODE=sv_ams_generic_types::SYNCHRONOUS) 
                                extends sv_ams_generic_checker#(MODE);
  local real threshold;
  local int direction;

  // Function: new
  //
  // The <new> function is used to construct <sv_ams_threshold_checker> object;
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.threshold = THR;
    this.direction = DIR;
  endfunction
    
  // Function: set_params
  //
  //  The <set_params> function specifies new *threshold* and *direction* values 
  //
  // Arguments:
  //  - *threshold* defines the <sv_ams_threshold_checker> threshold value (in V) 
  //  - *direction* defines the <sv_ams_threshold_checker> direction value.
  //    (+1: rising, -1: falling) 
  function void set_params(real threshold, int direction);
    this.threshold = threshold;
    this.direction = direction;
  endfunction
    
  task check_assert();
    if(direction == +1 && aif.sck.v > threshold)
      dump_msg($psprintf("Vin=%0.3f is above Thr=%0.3f", 
                                        aif.sck.v, threshold));
    if(direction == -1 && aif.sck.v < threshold)
      dump_msg($psprintf("Vin=%0.3f is below Thr=%0.3f", aif.sck.v, threshold));
  endtask
endclass
  
////////////////////////////////////////////////////////////
// Class: sv_ams_stability_checker
//   This transactor checks that a signal as specified
//   in its interface remains equal to a reference voltage +/- tolerance. 
//   The reference and tolerance are defined with
//   *REF* and *TOL* parameters.
//
// _Parameters_:
//  - real *REF* defines the <sv_ams_stability_checker> reference value (in V) 
//  - real *TOL* defines the <sv_ams_stability_checker> tolerance (default=10%)

class sv_ams_stability_checker #(real REF=0.0, real TOL=0.1,
                                  sv_ams_generic_types::mode_e MODE=sv_ams_generic_types::SYNCHRONOUS) 
                                extends sv_ams_generic_checker#(MODE);
  local real reference;
  local real tolerance;

  // Function: new
  //
  // The <new> function is used to construct <sv_ams_threshold_checker> object;
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.reference = REF;
    this.tolerance = TOL;
  endfunction
    
  // Function: set_params
  //
  //  The <set_params> function specifies new *reference* and *tolerance* values 
  //
  // Arguments:
  //  - *reference* defines the <sv_ams_threshold_checker> reference voltage (in V) 
  //  - *tolerance* defines the <sv_ams_threshold_checker> tolerance (0.1 = 10%)

  function void set_params(real reference, real tolerance);
    this.reference = reference;
    this.tolerance = tolerance;
  endfunction
    
  task check_assert();
    if((aif.sck.v < ((1-tolerance)*reference)) || (aif.sck.v > ((1+tolerance)*reference)))
      dump_msg($psprintf("Vin=%0.3f is out of Vref=%0.3f +/- %0.3f percent", 
                                        aif.sck.v, reference, 100* tolerance));
  endtask
endclass
  
////////////////////////////////////////////////////////////
// Class: sv_ams_slew_checker
//   This transactor checks that a signal as specified
//   in its interface steadily rises or falls above or below a pre-defined slew rate.
//   The slew rate and above/below checks are defined with
//   the *SLEW* and *IN_OUT* parameters
//
// _Parameters_:
//  - *SLEW* defines the <sv_ams_threshold_checker> slew rate (in V/ns) 
//  - *IN_OUT* defines the <sv_ams_threshold_checker> mode. 
// 	0: Indicates that slew rate is always *below* *SLEW*
// 	1: Indicates that slew rate is always *above* *SLEW*

class sv_ams_slew_checker #(real SLEW=0.1, bit IN_OUT=1,
                                  sv_ams_generic_types::mode_e MODE=sv_ams_generic_types::SYNCHRONOUS) 
                                 extends sv_ams_generic_checker#(MODE);

  local real slew;
  local real vref;
  local bit in_out;

  // Function: new
  //
  // The <new> function is used to construct <sv_ams_threshold_checker> object;
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.slew = SLEW;
    this.in_out = IN_OUT;
    this.vref = 0.0;
  endfunction
    
  // Function: set_params
  //
  //  The <set_params> function specifies new *slew* and *in_out* values 
  //
  // Arguments:
  //  - *slew* defines the <sv_ams_threshold_checker> slew rate (in V) 
  //  - *in_out* defines the <sv_ams_threshold_checker> comparison mode.
  // 	0: Indicates that slew rate is *below* *SLEW*
  // 	1: Indicates that slew rate is *above* *SLEW*

  function void set_params(real slew, bit in_out);
    this.slew = slew;
    this.in_out = in_out;
  endfunction
    
  task check_assert();
    if(in_out == 0 && fabs(aif.sck.v-vref) < slew)
      dump_msg($psprintf("Vin=%0.3f slew rate is below slew=%0.3f. It is expected to remain above this value.", 
                                        aif.sck.v, slew));
    if(in_out == 1 && fabs(aif.sck.v-vref) > slew)
      dump_msg($psprintf("Vin=%0.3f slew rate is above slew=%0.3f. It is expected to remain below this value.", 
                                        aif.sck.v, slew));
    vref <= aif.sck.v;
  endtask
endclass
  
////////////////////////////////////////////////////////////
// Class: sv_ams_frequency_checker
//   This transactor checks that a signal frequency as specified
//   in its interface remains stable with a given tolerance.
//   The signal voltage min/max, frequency and tolerance are defined with
//   the *VMIN*, *VMAX, *FREQ* and *TOL* parameters
//   The *TP* parameter specifies the enclosing module time precision
//   (as specified with `timescale prec/unit)
//
// _Parameters_:
//  - *VMIN* defines the <sv_ams_frequency_checker> min voltage (in V) 
//  - *VMAX* defines the <sv_ams_frequency_checker> max voltage (in V) 
//  - *FREQ* defines the <sv_ams_frequency_checker> expected frequency (in Hz) 
//  - *TP* defines the <sv_ams_frequency_checker> enclosing module time precision
//  - *TOL* defines the <sv_ams_threshold_checker> frequency tolerance (0.01=1%)

class sv_ams_frequency_checker #(real VMIN=0.0, 
                                  real VMAX=1.0, 
                                  real FREQ=1.0E6, 
                                  real TP=1.0E-9, 
                                  real TOL=1.0E-2)
                                extends sv_ams_generic_checker;
  local real frequency;
  local real vmin;
  local real vmax;
  local real time_precision;
  local real tolerance;

  // Function: new
  //
  // The <new> function is used to construct <sv_ams_threshold_checker> object;
  //
  // Arguments:
  //  - *name* defines the transactor instance name
  //  - *parent* defines the transactor parent
  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
    this.vmin = VMIN;
    this.vmax = VMAX;
    this.frequency = FREQ;
    this.time_precision = TP;
    this.tolerance = TOL;
  endfunction
    
  // Function: set_params
  //
  //  The <set_params> function specifies new 
  //   min/max voltages, frequency/tolerance and time precision.
  //
  // Arguments:
  //  - *vmin* defines the <sv_ams_frequency_checker> min voltage (in V) 
  //  - *vmax* defines the <sv_ams_frequency_checker> max voltage (in V) 
  //  - *freq* defines the <sv_ams_frequency_checker> expected frequency (in Hz) 
  //  - *time_precision* defines the <sv_ams_frequency_checker> enclosing module time precision
  //  - *tol* defines the <sv_ams_threshold_checker> frequency tolerance (0.01=1%)
  function void set_params(real vmin, real vmax, real freq, real time_precision=1.0E-9, real tol=1.0E-2);
    this.vmin = vmin;
    this.vmax = vmax;
    this.frequency = freq;
    this.time_precision = time_precision;
    this.tolerance = tol;
  endfunction
    
  task sample();
  endtask
    
  task check_assert();
    real t0,t1,act_freq;
    int i=0,j=0;
    fork
      begin: FREQMEAS
        wait (sv_ams_real::cmp(aif.sck.v,vmax,tolerance));
        wait (sv_ams_real::cmp(aif.sck.v,vmin,tolerance));
        t0=$realtime;
  
        wait (sv_ams_real::cmp(aif.sck.v,vmax,tolerance));
        wait (sv_ams_real::cmp(aif.sck.v,vmin,tolerance));
        t1=$realtime;
  
        act_freq=1/(time_precision*(t1-t0));
        disable TIMEOUT;
  
        if (!(sv_ams_real::cmp(act_freq,frequency,tolerance))) 
          dump_msg($psprintf("Expecting freq = %f - got %f with tolerance=%0.3f",
                                          frequency,act_freq,(tolerance*100)));
        else 
          dump_msg($psprintf("Measured freq = %f", frequency));
      end
  
      begin: TIMEOUT
        for (j=0;j<((5/(time_precision*frequency)));j++) #1;
        disable FREQMEAS;
        dump_msg($psprintf("%M timed out!!"));
      end
    join
  endtask
endclass

`endif
 
//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// SV-AMS Versions
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef SV_AMS_VERSION__SV
`define SV_AMS_VERSION__SV

class sv_ams_version;
   extern function int major();
   extern function int minor();
   extern function int patch();
   extern function string vendor();
   extern function string name();
   extern function void display(string prefix = "");
   extern function string psdisplay(string prefix = "");
endclass: sv_ams_version

// protect
function int sv_ams_version::major();
   major = 0;
endfunction: major

function int sv_ams_version::minor();
   minor = 1;
endfunction: minor

function int sv_ams_version::patch();
   patch = 0;
endfunction: patch


function string sv_ams_version::vendor();
   vendor = "Synopsys";
endfunction: vendor

function string sv_ams_version::name();
    return "SV-AMS";
endfunction

function void sv_ams_version::display(string prefix = "");
   $write("%s\n", this.psdisplay(prefix));
endfunction: display

function string sv_ams_version::psdisplay(string prefix = "");
   $sformat(psdisplay, "%s %s Version %0d.%0d.%0d (%s)",
            prefix, this.name(), this.major(), this.minor(), this.patch(), this.vendor());
endfunction: psdisplay
// endprotect

`endif // RVM_LP_VERSION__SV

`ifdef SVA_AMS_CHECKERS
//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2013 SYNOPSYS INC.  ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
//
// Title: SVA AMS Checkers
//
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////
`ifndef _UVM_AMS_CHECKER_SV_
`define _UVM_AMS_CHECKER_SV_

////////////////////////////////////////////////////////////
// Module: ams_sync_threshold_checker
//   This module checks on each positive of *clk* that a given signal
//   *vin* doesn't go above/below a pre-defined threshold.
//   The signal comparison and threshold are defined with
//   the parameters *threshold* and *in_out*
//
// _Definition_
// | 	module ams_sync_threshold_checker(clk,vin);
//
// _Arguments_
//  - input bit *clk*
//  - input real *vin*
//  - parameter real *threshold* = 0.0 (in V)
//  - parameter bit *in_out* = 1 (+1: high, 0: low)
//      0 indicates that the analog signal should always remain 
//        *below* *threshold*
//      1 indicates that the analog signal should always remain 
//        *above* *threshold*
//
// The following example shows how to instantiate two <ams_sync_threshold_checker>
// objects to verify that *vin* doesn't fall below 1.6V or rise above 1.7V.
//   
// (start code)
//module top;
//  logic clk=1'b0;
//  real  vin;
//
//  ams_sync_threshold_checker #(.threshold(1.7), .in_out(0)) 
//          sync_below_chk (.clk(clk), .vin(vin));
//  ams_sync_threshold_checker #(.threshold(1.6), .in_out(1)) 
//         sync_above_chk (.clk(clk), .vin(vin));
//
//  always #10 clk = ~clk;
//
//endmodule
// (end code)

module ams_sync_threshold_checker(clk,vin);
  input bit clk;
  input real vin;
  parameter real threshold = 0.0;
  parameter bit in_out = 1;

  property below;
    @(posedge clk) disable iff(in_out != 0)
      vin <= threshold;
  endproperty

  property above;
    @(posedge clk) disable iff(in_out != 1)
      vin >= threshold;
  endproperty

  check_b: 
     assert property (below) 
     else $display("\tvin=%0.3f is not <= threshold=%0.3f", vin, threshold);

  check_a: 
     assert property (above) 
     else $display("\tvin=%0.3f is not >= threshold=%0.3f", vin, threshold);
endmodule

////////////////////////////////////////////////////////////
// Module: ams_async_threshold_checker
//   This module asynchronously checks that a given signal
//   *vin* doesn't go above/below a pre-defined threshold.
//   The signal comparison and threshold are defined with
//   the parameters *threshold* and *in_out*
//
// _Definition_
// | 	module ams_async_threshold_checker(clk,vin);
//
// _Arguments_
//  - input bit *clk*
//  - input real *vin*
//  - parameter real *threshold* = 0.0 (in V)
//  - parameter bit *in_out* = 1 (+1: high, 0: low)
//      0 indicates that the analog signal should always remain 
//        *below* *threshold*
//      1 indicates that the analog signal should always remain 
//        *above* *threshold*
//
// The following example shows how to instantiate two <ams_async_threshold_checker>
// objects to verify that *vin* doesn't fall below 1.6V or rise above 1.7V.
//   
// (start code)
//module top;
//  logic clk=1'b0;
//  real  vin;
//
//  ams_async_threshold_checker #(.threshold(1.7), .in_out(0)) 
//          async_below_chk (.vin(vin));
//  ams_async_threshold_checker #(.threshold(1.6), .in_out(1)) 
//         async_above_chk (.vin(vin));
//
//endmodule
// (end code)

module ams_async_threshold_checker(vin);
  input real vin;
  parameter real threshold = 0.0;
  parameter bit in_out = 1;

 always @(vin) begin
    if(in_out == 0)
      check_min:assert (vin <= threshold) 
      else $display("\tvin=%0.3f is not <= threshold=%0.3f", vin, threshold);
    else
      check_max:assert (vin >= threshold) 
      else $display("\tvin=%0.3f is not >= threshold=%0.3f", vin, threshold);
    end
endmodule

////////////////////////////////////////////////////////////
// Module: ams_sync_window_checker
//   This module checks on each positive of *clk* that a given signal
//   *vin* remains in or out a given voltage window.
//   The voltage window is defined with *threshold_lo* and *threshold_hi* 
//  parameters.
//   The in/out comparison in_out is defined with *in_out* parameter.
//
// _Definition_
// | 	module ams_sync_window_checker(clk,vin);
//
// _Arguments_
//  - input bit *clk*
//  - input real *vin*
//  - parameter real *threshold_lo* = 0.0 (in V)
//  - parameter real *threshold_hi* = 1.0 (in V)
//  - parameter integer *in_out* = 1 (0: in window, 1: out of window)
//
// The following example shows how to instantiate an <ams_sync_window_checker>
// objects to verify that *vin* remains between 0.0V 1.2V.
//   
// (start code)
//module top;
//  logic clk=1'b0;
//  real  vin;
//
//  ams_sync_window_checker #(.threshold_lo(0.0),
//                            .threshold_hi(+1)) 
//                            .in_out(+1)) 
//          sync_win_chk(.clk(clk), .vin(vin));
//endmodule
// (end code)

module ams_sync_window_checker(clk, vin);
  input bit clk;
  input real vin;
  parameter real threshold_lo = 0.0;
  parameter real threshold_hi = 1.0;
  parameter bit in_out = 1;  // 0: in window, 1: out of window

  property in;
    @(posedge clk) disable iff(in_out != 0)
      vin > threshold_lo && vin < threshold_hi;
  endproperty

  property out;
    @(posedge clk) disable iff(in_out != 1)
      vin < threshold_lo || vin > threshold_hi;
  endproperty

  check_in: 
     assert property (in) 
     else $display("\tvin=%0.3f is not within [%0.3f-%0.3f]", vin, threshold_lo, threshold_hi);
  check_out: 
     assert property (out) 
     else $display("\tvin=%0.3f is within [%0.3f-%0.3f]", vin, threshold_lo, threshold_hi);
endmodule

////////////////////////////////////////////////////////////
// Module: ams_async_window_checker
//   This module asynchonously checks that a given signal
//   *vin* remains in or out a given voltage window.
//   The voltage window is defined with *threshold_lo* and *threshold_hi* 
//  parameters.
//   The in/out comparison in_out is defined with *in_out* parameter.
//
// _Definition_
// | 	module ams_async_window_checker(vin);
//
// _Arguments_
//  - input real *vin*
//  - parameter real *threshold_lo* = 0.0 (in V)
//  - parameter real *threshold_hi* = 1.0 (in V)
//  - parameter integer *in_out* = 1 (0: in window, 1: out of window)
//
// The following example shows how to instantiate an <ams_async_window_checker>
// objects to verify that *vin* remains between 0.0V 1.2V.
//   
// (start code)
//module top;
//  logic clk=1'b0;
//  real  vin;
//
//  ams_async_window_checker #(.threshold_lo(0.0),
//                             .threshold_hi(+1)) 
//                             .in_out(1)) 
//          async_win_chk(.vin(vin));
//endmodule
// (end code)

module ams_async_window_checker(vin);
  input real vin;
  parameter real threshold_lo = 0.0;
  parameter real threshold_hi = 1.0;
  parameter bit in_out = 1;  // 0: in window, 1: out of window

  always @(vin) begin
    if(in_out==0)
       check_in:assert (vin >= threshold_lo && vin <= threshold_hi)
       else $display("\tvin=%0.3f is not within [%0.3f-%0.3f]", vin, threshold_lo, threshold_hi);

    else
       check_out:assert (vin < threshold_lo || vin > threshold_hi)
       else $display("\tvin=%0.3f is within [%0.3f-%0.3f]", vin, threshold_lo, threshold_hi);
  end
endmodule

////////////////////////////////////////
// Module: ams_sync_stability_checker
//   This module checks on each positive of *clk* that a given signal
// *vin* is stable (*vref* +/- *tolerance*) when *enable* is asserted
//
// _Definition_
// | 	module ams_sync_stability_checker(clk, vin, enable)
//
// _Arguments_
//  - input bit  *clk*
//  - input real *vin*
//  - input bit  *enable*
//  - parameter real *tolerance* = 0.01 (1%)
//  - parameter real *vref* = 0.0 (0V)
//
// The following example shows how to instantiate an <ams_sync_stability_checker>
// objects to verify that *vin* remains equal to 1.0V +/- 5%
//   
// (start code)
//module top;
//  logic clk=1'b0;
//  logic ena=1'b1;
//  real  vin;
//
//  ams_sync_stability_checker #(.vref(1.0), .tolerance(0.05))
//          sync_stable(.clk(clk), .ena(ena), .vin(vin));
//endmodule
// (end code)

module ams_sync_stability_checker(clk, vin, enable);
  input bit clk;			// clock
  input real vin;              		// Analog input
  input bit enable;			// enable input comparison
  parameter real tolerance=0.01; 	// default tolerance=1%
  parameter real vref=0.0;		// reference value

  property p;
  @(posedge clk) disable iff (!enable)
                 (vin >= (1-tolerance)*vref && vin <= (1+tolerance)*vref);
  endproperty
  ams_sync_stability_checker: 
     assert property (p) 
     else $display("\tvin=%0.3f vref=%0.3f +/-%0.3f", vin, vref, tolerance);
endmodule

////////////////////////////////////////
// Module: ams_sync_frame_checker
//   This module checks on each positive of *clk* that a given signal
// *vin* is stable (*vref* +/- *tolerance*) during a time window.
//
// _Definition_
// | 	module ams_sync_frame_checker(clk, vin, enable)
//
// _Arguments_
//  - input bit  *clk*
//  - input real *vin*
//  - input bit  *enable*
//  - parameter real *tolerance* = 0.01 (1%)
//  - parameter real *vref* = 0.0 (0V)
//  - parameter time *window_low* = 0  (module time precision)
//  - parameter time *window_high* = 0 (module time precision)
//
// The following example shows how to instantiate an <ams_sync_frame_checker>
// objects to verify that *vin* remains equalt to 1.0V +/- 5% from 10ns to 500ns
//   
// (start code)
//`timescale 1ns/1ps
//module top;
//  logic clk=1'b0;
//  logic ena=1'b1;
//  real  vin;
//
//  ams_sync_frame_checker #(.vref(1.0), .tolerance(0.05))
//                           .window_low(10), .window_hi(500))
//          sync_stable(.clk(clk), .ena(ena), .vin(vin));
//endmodule
// (end code)

module ams_sync_frame_checker(clk, vin, enable);
  input bit clk;			// clock
  input real vin;
  input bit enable;			// enable input comparison
  parameter real vref=0.0;		// reference value
  parameter real tolerance=0.01; 	// default tolerance=1%
  parameter time window_low = 0; 	// Window start time 
  parameter time window_high = 0; 	// Window end time

  bit ena = 1'b0;

  always @(posedge clk) begin
    ena <= enable && ($time >= window_low && $time <= window_high);
  end
  
  property p;
  @(posedge clk) disable iff (!ena)
                 (vin >= (1-tolerance)*vref && vin <= (1+tolerance)*vref);
  endproperty
  ams_sync_frame_checker: 
     assert property (p) 
     else $display("\tvin=%0.3f vref=%0.3f +/-%0.3f", vin, vref, tolerance);
endmodule

////////////////////////////////////////
// Module: ams_async_slew_checker
//   This module asynchronously checks that a given signal
//   steadily rises or falls above or below a pre-defined slew rate.
//   The slew rate and above/below checks are defined with
//   the *SLEW* and *IN_OUT* parameters
//
// _Definition_
// | 	module ams_async_slew_checker(clk, vin)
//
// _Arguments_
//  - input bit  *clk*
//  - input real *vin*
//  - parameter bit in_out 
// 	0: Indicates that slew rate is always *below* *SLEW*
// 	1: Indicates that slew rate is always *above* *SLEW*
//  - parameter real *slew* = 0.1 (100mV/ timescale)
//
// The following example shows how to instantiate an <ams_async_slew_checker>
// object to verify that *vin* rises with a slew rate of more than 10V/ns
//   
// (start code)
//`timescale 1ns/1ps
//module top;
//  logic clk=1'b0;
//  real  vin;
//
//  ams_async_slew_checker #(.in_out(+1), .tolerance(10.0))
//          sync_stable(.clk(clk), .vin(vin));
//endmodule
// (end code)
module ams_async_slew_checker(clk, vin);
  input bit clk;
  input real vin;
  parameter bit in_out = 1; // 0: below, 1: above
  parameter real slew=0.10; // default slew=100mV/timescale

  real vref = 0.0;
  real vref_d = 0.0;

  always @(posedge clk) begin
    vref_d <= vin;
    vref <= vref_d;
  end

  property below;
    @(posedge clk) disable iff (in_out != 0)
      fabs(vin-vref) < slew;
  endproperty

   property above;
    @(posedge clk) disable iff (in_out != 1)
      fabs(vin-vref) > slew;
  endproperty

  check_a:assert property (above)
     else $display("\tvin=%0.3f - vref=%0.3f is not < slew=%0.3f", vin, vref, slew);
  check_b:assert property (below)
     else $display("\tvin=%0.3f - vref=%0.3f is not > slew=%0.3f", vin, vref, slew);

endmodule

////////////////////////////////////////
// Module: ams_async_slew_checker_window
//   This module asynchronously checks that a given signal
// *vin* is steadily rising or falling within a given tolerance.
// It can enabled with *enable* signal.
//
// _Definition_
// | 	module ams_async_slew_checker_window(clk, vin, enable)
//
// _Arguments_
//  - input bit  *clk*
//  - input real *vin*
//  - input bit  *enable*
//  - parameter integer *direction* = 1 (0: falling, +1: rising)
//  - parameter real *tolerance* = 0.01 (1%)
//
// The following example shows how to instantiate an <ams_async_slew_checker_window>
// object to verify that *vin* rises with a slew rate of 10V/ns
//   
// (start code)
//`timescale 1ns/1ps
//module top;
//  logic clk=1'b0;
//  real  vin;
//
//  ams_async_slew_checker_window #(.direction(+1), .tolerance(10.0))
//          sync_stable(.clk(clk), .vin(vin));
//endmodule
// (end code)

module ams_async_slew_checker_window(clk, vin, enable);
  input bit clk;	// synchronous clock
  input real vin;  	// analog input
  input bit enable;	// enable window check when true 
  parameter bit in_out = 1; // 0: below, 1: above
  parameter real slew=0.10; // default slew=100mV/timescale

  real vref = 0.0;
  real vref_d = 0.0;

  always @(posedge clk) begin
    vref_d <= vin;
    vref <= vref_d;
  end

  property below;
    @(posedge clk) disable iff (in_out != 0 && !enable)
      fabs(vin-vref) < slew;
  endproperty

   property above;
    @(posedge clk) disable iff (in_out != 1 && !enable)
      fabs(vin-vref) > slew;
  endproperty

  check_a:assert property (above)
     else $display("\tvin=%0.3f - vref=%0.3f is not < slew=%0.3f", vin, vref, slew);
  check_b:assert property (below)
     else $display("\tvin=%0.3f - vref=%0.3f is not > slew=%0.3f", vin, vref, slew);

endmodule

`endif
`endif

`endif
