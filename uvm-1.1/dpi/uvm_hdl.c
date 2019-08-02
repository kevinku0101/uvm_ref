//----------------------------------------------------------------------
//   Copyright 2007-2011 Cadence Design Systems, Inc.
//   Copyright 2009-2010 Mentor Graphics Corporation
//   Copyright 2010-2011 Synopsys, Inc.
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

#include "sv_vpi_user.h"
#include "veriuser.h"
#include "svdpi.h"
#include <malloc.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#ifdef VCSMX
#include "svdpi.h"
#include "vcsuser.h"
#include "mhpi_user.h"
#include "vhpi_user.h"
#endif

#ifdef VCSMX
#define RELEASE_HANDLE(h, mhpiH) \
        vpi_release_handle(h); \
        mhpi_release_handle(mhpiH);

#else
#define RELEASE_HANDLE(h, mhpiH) \
        vpi_release_handle(h);   
#endif


#if defined(VCSMX_FAST_UVM) && !defined(MHPI_FAST_UVM)
#error “UVM_ERROR: THIS VERSION OF VCS DOESN’T SUPPORT VCSMX_FAST_UVM. Compile without -DVCSMX_FAST_UVM”
#endif
/*
 * Function to check if target variable is compatible with vector
 */
/* 
 * This code ceccks if the given handle is not of type Array or unpacked
 * struct
 */ 

static int vector_compat_type(vpiHandle obj)
{
    int vector_compatible = 1;
    switch(vpi_get(vpiType, obj)) {
      case vpiArrayVar:
      case vpiArrayNet:
        vector_compatible = 0;
        break;
      case vpiStructVar:
      case vpiUnionVar:
        if (vpi_get(vpiVector, obj) == 0) {
            vector_compatible = 0;
        }
        break;
    }
    if (!vector_compatible) {
        return 0;
    }
    return 1;
}

static int vector_compat_type_stub(vpiHandle obj)
{
    return 1;
}

#ifdef UVM_DPI_DISABLE_DO_TYPE_CHECK
#undef UVM_DPI_DO_TYPE_CHECK
#endif

#ifdef UVM_DPI_DO_TYPE_CHECK
   static int (*check_type)(vpiHandle) = &vector_compat_type;
#else
   static int (*check_type)(vpiHandle) = &vector_compat_type_stub;
#endif



/* 
 * UVM HDL access C code.
 *
 */
static char* get_memory_for_alloc(int need) 
{
    static int alloc_size = 0;
    static char* alloc = NULL;
    if (need > alloc_size) {
        if (alloc_size == 0) alloc_size = need;
        while (alloc_size < need) alloc_size *= 2;
        alloc = (char*)realloc(alloc, alloc_size);
    }
    return alloc;
}    

/*
 * This C code checks to see if there is PLI handle
 * with a value set to define the maximum bit width.
 *
 * If no such variable is found, then the default 
 * width of 1024 is used.
 *
 * This function should only get called once or twice,
 * its return value is cached in the caller.
 *
 */
static int uvm_hdl_max_width()
{
  vpiHandle ms;
  s_vpi_value value_s = { vpiIntVal, { 0 } };
  ms = vpi_handle_by_name(
      (PLI_BYTE8*) "uvm_pkg::UVM_HDL_MAX_WIDTH", 0);
  if(ms == 0) 
    return 1024;  /* If nothing else is defined, 
                     this is the DEFAULT */
  vpi_get_value(ms, &value_s);
  return value_s.value.integer;
}


#ifdef QUESTA
static int uvm_hdl_set_vlog(char *path, p_vpi_vecval value, PLI_INT32 flag);
static int uvm_hdl_get_vlog(char *path, p_vpi_vecval value, PLI_INT32 flag);
static int partsel = 0;

/*
 * Given a path with part-select, break into individual bit accesses 
 * path = pointer to user string
 * value = pointer to logic vector
 * flag = deposit vs force/release options, etc
 */
static int uvm_hdl_set_vlog_partsel(char *path, p_vpi_vecval value, PLI_INT32 flag)
{
  char *path_ptr = path;
  int path_len, idx;
  svLogicVecVal bit_value;

  path_len = strlen(path);
  path_ptr = (char*)(path+path_len-1);

  if (*path_ptr != ']') 
    return 0;

  while(path_ptr != path && *path_ptr != ':' && *path_ptr != '[')
    path_ptr--;

  if (path_ptr == path || *path_ptr != ':') 
    return 0;

  while(path_ptr != path && *path_ptr != '[')
    path_ptr--;

  if (path_ptr == path || *path_ptr != '[') 
    return 0;

  int lhs, rhs, width, incr;

  // extract range from path
  if (sscanf(path_ptr,"[%u:%u]",&lhs, &rhs)) {
    char index_str[20];
    int i;
    path_ptr++;
    path_len = (path_len - (path_ptr - path));
    incr = (lhs>rhs) ? 1 : -1;
    width = (lhs>rhs) ? lhs-rhs+1 : rhs-lhs+1;

    // perform set for each individual bit
    for (i=0; i < width; i++) {
      sprintf(index_str,"%u]",rhs);
      strncpy(path_ptr,index_str,path_len);
      svGetPartselLogic(&bit_value,value,i,1);
      rhs += incr;
      if (!uvm_hdl_set_vlog(path,&bit_value,flag))
        return 0;
    }
    return 1;
  }
}


/*
 * Given a path with part-select, break into individual bit accesses 
 * path = pointer to user string
 * value = pointer to logic vector
 * flag = deposit vs force/release options, etc
 */
static int uvm_hdl_get_vlog_partsel(char *path, p_vpi_vecval value, PLI_INT32 flag)
{
  char *path_ptr = path;
  int path_len, idx;
  svLogicVecVal bit_value;

  path_len = strlen(path);
  path_ptr = (char*)(path+path_len-1);

  if (*path_ptr != ']') 
    return 0;

  while(path_ptr != path && *path_ptr != ':' && *path_ptr != '[')
    path_ptr--;

  if (path_ptr == path || *path_ptr != ':') 
    return 0;

  while(path_ptr != path && *path_ptr != '[')
    path_ptr--;

  if (path_ptr == path || *path_ptr != '[') 
    return 0;

  int lhs, rhs, width, incr;

  // extract range from path
  if (sscanf(path_ptr,"[%u:%u]",&lhs, &rhs)) {
    char index_str[20];
    int i;
    path_ptr++;
    path_len = (path_len - (path_ptr - path));
    incr = (lhs>rhs) ? 1 : -1;
    width = (lhs>rhs) ? lhs-rhs+1 : rhs-lhs+1;
    bit_value.aval = 0;
    bit_value.bval = 0;
    partsel = 1;
    for (i=0; i < width; i++) {
      int result;
      svLogic logic_bit;
      sprintf(index_str,"%u]",rhs);
      strncpy(path_ptr,index_str,path_len);
      result = uvm_hdl_get_vlog(path,&bit_value,flag);
      logic_bit = svGetBitselLogic(&bit_value,0);
      svPutPartselLogic(value,bit_value,i,1);
      rhs += incr;
      if (!result)
        return 0;
    }
    partsel = 0;
    return 1;
  }
}
#endif


/*
 * Given a path, look the path name up using the PLI,
 * and set it to 'value'.
 */
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
static int uvm_hdl_set_vlog(vpiHandle r, char *path, p_vpi_vecval value, PLI_INT32 flag)
{
  s_vpi_error_info err_s;
  static int maxsize = -1;
  s_vpi_value value_s = { vpiIntVal, { 0 } };
  s_vpi_time  time_s = { vpiSimTime, 0, 0, 0.0 };

  //vpi_printf("uvm_hdl_set_vlog(%s,%0x)\n",path,value[0].aval);

  if(r == 0)
  {
      vpi_printf((PLI_BYTE8*) "UVM_ERROR: set: unable to locate hdl path (%s)\n",path);
      vpi_printf((PLI_BYTE8*) " Either the name is incorrect, or you may not have PLI/ACC visibility to that name\n");
      vpi_release_handle(r);
    return 0;
  }
  else
  {
    if(maxsize == -1)
        maxsize = uvm_hdl_max_width();

    value_s.format = vpiVectorVal;
    value_s.value.vector = value;
    if (!check_type(r)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: Object pointed to by path '%s' is not of supported type\n" \
                "(Unpacked Array/Struct/Union type) for reading/writing value.", path);
        vpi_release_handle(r);
        return 0;
    }
    vpi_put_value(r, &value_s, &time_s, flag);
    if (vpi_chk_error(&err_s)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: set: unable to write to hdl path (%s)\n",path);
        vpi_printf((PLI_BYTE8*) "You may not have sufficient PLI/ACC capabilites enabled for that path\n");
        vpi_release_handle(r);
        return 0;
    }

    if (value == NULL) {
      value = value_s.value.vector;
    }
  }
  return 1;
}
#else
static int uvm_hdl_set_vlog(char *path, p_vpi_vecval value, PLI_INT32 flag)
{
  s_vpi_error_info err_s;
  static int maxsize = -1;
  vpiHandle r;
  s_vpi_value value_s = { vpiIntVal, { 0 } };
  s_vpi_time  time_s = { vpiSimTime, 0, 0, 0.0 };

  //vpi_printf("uvm_hdl_set_vlog(%s,%0x)\n",path,value[0].aval);

  #ifdef QUESTA
  int result = 0;
  result = uvm_hdl_set_vlog_partsel(path,value,flag);
  if (result < 0)
    return 0;
  if (result == 1)
    return 1;

  if (!strncmp(path,"$root.",6))
    r = vpi_handle_by_name(path+6, 0);
  else
  #endif

#ifdef VCSMX 
#ifndef USE_DOT_AS_HIER_SEP
  mhpi_initialize('/');
#else
  mhpi_initialize('.');
#endif
  mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
  r = (PLI_UINT32*)mhpi_get_vpi_handle(mhpiH);
#else
  r = vpi_handle_by_name(path, 0);
#endif

  if(r == 0)
  {
      vpi_printf((PLI_BYTE8*) "UVM_ERROR: set: unable to locate hdl path (%s)\n",path);
      vpi_printf((PLI_BYTE8*) " Either the name is incorrect, or you may not have PLI/ACC visibility to that name\n");
#ifdef VCSMX
      mhpi_release_handle(mhpiH);
#endif
    return 0;
  }
  else
  {
    if(maxsize == -1) 
        maxsize = uvm_hdl_max_width();

    value_s.format = vpiVectorVal;
    value_s.value.vector = value;
    if (!check_type(r)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: Object pointed to by path '%s' is not of supported type\n" \
                "(Unpacked Array/Struct/Union type) for reading/writing value.", path);
        RELEASE_HANDLE(r, mhpiH)
        return 0;
    }
    vpi_put_value(r, &value_s, &time_s, flag);  
    if (vpi_chk_error(&err_s)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: set: unable to write to hdl path (%s)\n",path);
        vpi_printf((PLI_BYTE8*) "You may not have sufficient PLI/ACC capabilites enabled for that path\n");
        RELEASE_HANDLE(r, mhpiH)
        return 0;
    }

    if (value == NULL) {
      value = value_s.value.vector;
    }
  } 
  RELEASE_HANDLE(r, mhpiH)
  return 1;
}
#endif

/*
 * Given a path, look the path name up using the PLI
 * and return its 'value'.
 */
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
static int uvm_hdl_get_vlog(vpiHandle r, char *path, p_vpi_vecval value, PLI_INT32 flag)
{
  static int maxsize = -1;
  int i, size, chunks;
  s_vpi_value value_s;
  s_vpi_error_info err_s;

  if(r == 0)
  {
      vpi_printf((PLI_BYTE8*) "UVM_ERROR: get: unable to locate hdl path %s\n", path);
      vpi_printf((PLI_BYTE8*) " Either the name is incorrect, or you may not have PLI/ACC visibility to that name\n");
      vpi_release_handle(r);
       return 0;
  }
  else
  {
    if(maxsize == -1)
        maxsize = uvm_hdl_max_width();

    size = vpi_get(vpiSize, r);
    if(size > maxsize)
    {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: uvm_reg : hdl path '%s' is %0d bits,\n",path,size);
        vpi_printf((PLI_BYTE8*) " but the maximum size is %0d. You can increase the maximum\n",maxsize);
        vpi_printf((PLI_BYTE8*) " via a compile-time flag: +define+UVM_HDL_MAX_WIDTH=<value>\n");
        vpi_release_handle(r);
        return 0;
    }
    chunks = (size-1)/32 + 1;

    value_s.format = vpiVectorVal;
    if (!check_type(r)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: Object pointed to by path '%s' is not of supported type\n" \
                "(Unpacked Array/Struct/Union type) for reading/writing value.", path);
        vpi_release_handle(r);
        return 0;
    }
    vpi_get_value(r, &value_s);
    if (vpi_chk_error(&err_s)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: set: unable to perform read on hdl path (%s)\n",path);
        vpi_printf((PLI_BYTE8*) "You may not have sufficient PLI/ACC capabilites enabled for that path\n");
        vpi_release_handle(r);
        return 0;
    }
    /*dpi and vpi are reversed*/
    for(i=0;i<chunks; ++i)
    {
      value[i].aval = value_s.value.vector[i].aval;
      value[i].bval = value_s.value.vector[i].bval;
    }
  }
  return 1;
}
#else 
static int uvm_hdl_get_vlog(char *path, p_vpi_vecval value, PLI_INT32 flag)
{
  static int maxsize = -1;
  int i, size, chunks;
  vpiHandle r;
  s_vpi_value value_s;
  s_vpi_error_info err_s;

  #ifdef QUESTA
  if (!partsel) {
    maxsize = uvm_hdl_max_width();
    chunks = (maxsize-1)/32 + 1;
    for(i=0;i<chunks-1; ++i) {
      value[i].aval = 0;
      value[i].bval = 0;
    }
  }
  int result = 0;
  result = uvm_hdl_get_vlog_partsel(path,value,flag);
  if (result < 0)
    return 0;
  if (result == 1)
    return 1;

  if (!strncmp(path,"$root.",6))
    r = vpi_handle_by_name(path+6, 0);
  else
  #endif
#ifdef VCSMX 
#ifndef USE_DOT_AS_HIER_SEP
  mhpi_initialize('/');
#else
  mhpi_initialize('.');
#endif
  mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
  r = (PLI_UINT32*)mhpi_get_vpi_handle(mhpiH);
#else
  r = vpi_handle_by_name(path, 0);
#endif
  if(r == 0)
  {
      vpi_printf((PLI_BYTE8*) "UVM_ERROR: get: unable to locate hdl path %s\n", path);
      vpi_printf((PLI_BYTE8*) " Either the name is incorrect, or you may not have PLI/ACC visibility to that name\n");
#ifdef VCSMX      
      mhpi_release_handle(mhpiH);
#endif      
      return 0;
  }
  else
  {
    if(maxsize == -1)
        maxsize = uvm_hdl_max_width();

    size = vpi_get(vpiSize, r);
    if(size > maxsize)
    {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: uvm_reg : hdl path '%s' is %0d bits,\n",path,size);
        vpi_printf((PLI_BYTE8*) " but the maximum size is %0d. You can increase the maximum\n",maxsize);
        vpi_printf((PLI_BYTE8*) " via a compile-time flag: +define+UVM_HDL_MAX_WIDTH=<value>\n");
        RELEASE_HANDLE(r, mhpiH)
        return 0;
    }
    chunks = (size-1)/32 + 1;

    value_s.format = vpiVectorVal;
    if (!check_type(r)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: Object pointed to by path '%s' is not of supported type\n" \
                "(Unpacked Array/Struct/Union type) for reading/writing value.", path);
        RELEASE_HANDLE(r, mhpiH)
        return 0;
    }
    vpi_get_value(r, &value_s);
    if (vpi_chk_error(&err_s)) {
        vpi_printf((PLI_BYTE8*) "UVM_ERROR: set: unable to perform read on hdl path (%s)\n",path);
        vpi_printf((PLI_BYTE8*) "You may not have sufficient PLI/ACC capabilites enabled for that path\n");
        RELEASE_HANDLE(r, mhpiH)
        return 0;
    }
    /*dpi and vpi are reversed*/
    for(i=0;i<chunks; ++i)
    {
      value[i].aval = value_s.value.vector[i].aval;
      value[i].bval = value_s.value.vector[i].bval;
    }
  }
  RELEASE_HANDLE(r, mhpiH)
  return 1;
}
#endif

/*
 * Given a path, look the path name up using the PLI,
 * but don't set or get. Just check.
 *
 * Return 0 if NOT found.
 * Return 1 if found.
 */

int uvm_hdl_check_path(char *path)
{
#ifdef VCSMX
#ifndef USE_DOT_AS_HIER_SEP
  mhpi_initialize('/');
#else
  mhpi_initialize('.');
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
  mhpiHandleT mhpiH = mhpi_uvm_handle_by_name(path, 0);
#else
  mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
#endif
  if (mhpiH == 0) {
      return 0;
  } else  {
     mhpi_release_parent_handle(mhpiH); 
     return 1;
  }
#else  
  vpiHandle r;

  #ifdef QUESTA
  if (!strncmp(path,"$root.",6)) {
    r = vpi_handle_by_name(path+6, 0);
  }
  else
  #endif
  r = vpi_handle_by_name(path, 0);

  if(r == 0)
      return 0;
  else 
    return 1;
#endif
}


#ifdef VCSMX
PLI_UINT32 btoi(char *binVal) {
  PLI_UINT32  remainder, dec=0;
  int  j = 0;
  unsigned long long int bin;
  int i;
  char tmp[2];
  tmp[1] = '\0';
   

  for(i= strlen(binVal) -1 ; i >= 0 ; i--) {
    tmp[0] = binVal[i];
    bin = atoi(tmp);
    dec = dec+(bin*(pow(2,j)));
    j++;
  }
  return(dec);
}

#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
int uvm_hdl_get_mhdl(vhpiHandleT vhpiH, char *path, p_vpi_vecval value) {

  PLI_UINT32 value_int;
  PLI_UINT32 size = 0;

  char *binVal;
  PLI_UINT32 i = 0;
  vhpiValueT value1;
  p_vpi_vecval vecval;
  value1.format=vhpiStrVal;
  size = vhpi_get(vhpiSizeP, vhpiH);
  vhpiHandleT baseTypeH = vhpi_handle (vhpiBaseType, vhpiH);
  value1.bufSize = size + 1;
  value1.value.str = get_memory_for_alloc(size + 1);   

  if (vhpi_get_value(vhpiH, &value1) == 0) {

    int max_i = ((size-1)/(32)) + 1;
    char sub_value[33];
    binVal = value1.value.str;
    for (int i = 0; i < max_i; i++) {
        int bits_to_consider = 32;
        int j = 0;

        if (i == 0) {
            bits_to_consider = size - (max_i-1)*32;
        }

        strncpy(sub_value, binVal+(32*i), bits_to_consider); 
        sub_value[bits_to_consider]= '\0';

        for (int j = 0; j < bits_to_consider; j++) {
            switch(sub_value[j]) {
              case '0':
                value[max_i-i-1].aval = value[max_i-i-1].aval << 1;
                value[max_i-i-1].bval = value[max_i-i-1].bval << 1;
                break;
              case '1':
                value[max_i-i-1].aval = (value[max_i-i-1].aval << 1) + 1;
                value[max_i-i-1].bval = value[max_i-i-1].bval << 1;
                break;
              case 'U':
              case 'X':
                value[max_i-i-1].aval = (value[max_i-i-1].aval << 1) + 1;
                value[max_i-i-1].bval = (value[max_i-i-1].bval << 1) + 1;
                break;
              case 'Z':
                value[max_i-i-1].aval = value[max_i-i-1].aval << 1;
                value[max_i-i-1].bval = (value[max_i-i-1].bval << 1) + 1;
                break;
              default:
                value[max_i-i-1].aval = (value[max_i-i-1].aval << 1) + 1;
                value[max_i-i-1].bval = (value[max_i-i-1].bval << 1) + 1;
            }
        }
        binVal = binVal+32;
    } 

    return(1);    

  } else {
    return (0);
  }
}
#else
int uvm_hdl_get_mhdl(char *path, p_vpi_vecval value) {

  PLI_UINT32 value_int;
  PLI_UINT32 size = 0;

  char *binVal;
  PLI_UINT32 i = 0;
  vhpiValueT value1;
  p_vpi_vecval vecval;
#ifndef USE_DOT_AS_HIER_SEP
  mhpi_initialize('/');
#else
  mhpi_initialize('.');
#endif
  mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
  vhpiHandleT vhpiH = (long unsigned int *)mhpi_get_vhpi_handle(mhpiH);
  value1.format=vhpiStrVal;
  size = vhpi_get(vhpiSizeP, vhpiH);
  value1.bufSize = size + 1;
  value1.value.str = (char*)malloc(value1.bufSize*sizeof(char));  

  if (vhpi_get_value(vhpiH, &value1) == 0) {

    int max_i = ((size-1)/(32)) + 1;
    char sub_value[33];
    binVal = value1.value.str;
    for (int i = 0; i < max_i; i++) {
        int bits_to_consider = 32;
        int j = 0;

        if (i == 0) {
            bits_to_consider = size - (max_i-1)*32;
        }

        strncpy(sub_value, binVal+(32*i), bits_to_consider); 
        sub_value[bits_to_consider]= '\0';

        for (int j = 0; j < bits_to_consider; j++) {
            switch(sub_value[j]) {
              case '0':
                value[max_i-i-1].aval = value[max_i-i-1].aval << 1;
                value[max_i-i-1].bval = value[max_i-i-1].bval << 1;
                break;
              case '1':
                value[max_i-i-1].aval = (value[max_i-i-1].aval << 1) + 1;
                value[max_i-i-1].bval = value[max_i-i-1].bval << 1;
                break;
              case 'U':
              case 'X':
                value[max_i-i-1].aval = (value[max_i-i-1].aval << 1) + 1;
                value[max_i-i-1].bval = (value[max_i-i-1].bval << 1) + 1;
                break;
              case 'Z':
                value[max_i-i-1].aval = value[max_i-i-1].aval << 1;
                value[max_i-i-1].bval = (value[max_i-i-1].bval << 1) + 1;
                break;
              default:
                value[max_i-i-1].aval = (value[max_i-i-1].aval << 1) + 1;
                value[max_i-i-1].bval = (value[max_i-i-1].bval << 1) + 1;
            }
        }
        binVal = binVal+32;
    } 
    mhpi_release_parent_handle(mhpiH);
    free(value1.value.str);

    return(1);    

  } else {
    mhpi_release_parent_handle(mhpiH);
    free(value1.value.str);
    return (0);
  }
}

#endif

#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
static int uvm_hdl_get_vhpi(vhpiHandleT r, char* path, p_vpi_vecval value)
{
  static int maxsize = -1;
  int size, chunks, i, j, rtn , bit, aval, bval;
  vhpiValueT value_s;

  if (r == 0) {
    return 0;
  }
  else {
    if (maxsize == -1) {
      maxsize = uvm_hdl_max_width();
    }

    size = vhpi_get(vhpiSizeP, r);
    if (size > maxsize) {
      return 0;
    }

    chunks = (size - 1)/ 32 + 1;

    memset(value, 0, (maxsize-1)/32+1);

    vhpiHandleT baseTypeH = vhpi_handle (vhpiBaseType, r);
    char *typeName = vhpi_get_str (vhpiNameP, baseTypeH);
    if ((vhpi_get(vhpiIsScalarP, r)) == 1) {
      if (!strcmp(typeName, "INTEGER") ) {
         value_s.format =  vhpiIntVal;
         rtn = vhpi_get_value(r, &value_s); 
         value[0].aval = value_s.value.intg; 
         return 1;
      }

      if (!strcmp(typeName, "BIT")) {
         uvm_hdl_get_mhdl(r, path, value);
         return 1;
      }
      
      if (!strcmp(typeName, "BOOLEAN")) {
         uvm_hdl_get_mhdl(r, path, value);
         return 1;
      }
    } 
  
    if (!strcmp(typeName, "BIT_VECTOR")) {
      uvm_hdl_get_mhdl(r, path, value);
      return 1;
    }
    value_s.format = vhpiEnumVecVal;
    value_s.bufSize = size;
    value_s.value.str = get_memory_for_alloc(size);
    rtn = vhpi_get_value(r, &value_s);
    if (rtn > 0) {
      value_s.value.str = get_memory_for_alloc(rtn);
      value_s.bufSize = rtn;
      vhpi_get_value(r, &value_s);
    }
        

    bit = 0;
    for (i = 0; i < chunks && bit < size; ++i) {
      aval = 0;
      bval = 0;
      for(j=0;(j<32) && (bit<size); ++j)
      {
        aval<<=1; bval<<=1;
        switch(value_s.value.enums[bit])
        {
          case 0:
          case 5:
          case 1:
          {
            aval |= 1;
            bval |= 1;
            break;
          }
          case 4:
          {
            bval |= 1;
            break;
          }
          case 2:
          case 6:
          case 8:
          {
            break;
          }
          case 3:
          case 7:
          {
            aval |= 1;
            break;
          }
        }
        bit++;
      }
      value[i].aval = aval;
      value[i].bval = bval;
    }
  }
  return 1;
}
#endif //VCSMX_FAST_UVM
#endif //end VCSMX

#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
int uvm_memory_load(const char* nid,
                     const char* scope,
                     const char* fileName,
                     const char* radix,
                     const char* startaddr,
                     const char* endaddr,
                     const char* type)
{
    mhpi_uvm_ucli_memory_load(nid, scope, fileName, radix,
                          startaddr, endaddr, type);
    return 1;
}
#else 
int uvm_memory_load(const char* nid,
                     const char* scope,
                     const char* fileName,
                     const char* radix,
                     const char* startaddr,
                     const char* endaddr,
                     const char* type)
{
    //TODO: furture implementation for pure verilog 
    vpi_printf((PLI_BYTE8*) "UVM_ERROR: uvm_memory_load is not supported, please compile with -DVCSMX_FAST_UVM\n");
    return 0;
}
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
char* uvm_hdl_read_string(char* path) 
{
#ifdef VCSMX
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
    mhpiHandleT mhpiH = mhpi_uvm_handle_by_name(path, 0);
    if (mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli) {
       vhpiValueT getValue;
       char* valueStr = (char*)0;
       vhpiIntT strValueSize = 0;
       vhpiHandleT h = (vhpiHandleT)mhpi_get_vhpi_handle(mhpiH);
       mhpi_release_parent_handle(mhpiH);
       if (h) {
           strValueSize = vhpi_value_size(h, vhpiStrVal);
           if (strValueSize) {
               getValue.value.str = get_memory_for_alloc(strValueSize+1);
           } else {
               return valueStr;
           }

           getValue.format = vhpiStrVal;
           getValue.bufSize = strValueSize;
           if (!vhpi_get_value(h, &getValue)) {
               valueStr = getValue.value.str;
               getValue.value.str = (char*)0;
           }
           vhpi_release_handle(h);
       } 
       return valueStr;
    } else if (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli){
       vpiHandle h = (vpiHandle)mhpi_get_vpi_handle(mhpiH);
       mhpi_release_parent_handle(mhpiH);
  
       if (h) {
           s_vpi_value getValue;
           getValue.format = vpiStringVal; 
           if (!check_type(h)) {
               vpi_printf((PLI_BYTE8*) "UVM_ERROR: Object pointed to by path '%s' is not of supported type\n" \
                       "(Unpacked Array/Struct/Union type) for reading/writing value.", path);
               return 0;
           }
           vpi_get_value(h, &getValue);
           vpi_release_handle(h);
           return getValue.value.str; 
       }
       return (char*)0;
    }
#else 
    vpiHandle h = vpi_handle_by_name(path, 0);
    if (h) {
        s_vpi_value getValue;
        getValue.format = vpiStringVal;
        if (!check_type(h)) {
            vpi_printf((PLI_BYTE8*) "UVM_ERROR: Object pointed to by path '%s' is not of supported type\n" \
                    "(Unpacked Array/Struct/Union type) for reading/writing value.", path);
            return 0;
        }
        vpi_get_value(h, &getValue);
        vpi_release_handle(h);
        return getValue.value.str;
    }
    return (char*)0;
#endif
}
#else 
char* uvm_hdl_read_string(char* path)
{
    vpi_printf((PLI_BYTE8*) "UVM_ERROR: uvm_hdl_read_string is not supported, please compile with -DVCSMX_FAST_UVM\n");
    return 0;
}
#endif
/*
 * Given a path, look the path name up using the PLI
 * or the FLI, and return its 'value'.
 */
int uvm_hdl_read(char *path, p_vpi_vecval value)
{
#ifdef VCSMX    
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    mhpiHandleT mhpiH = mhpi_uvm_handle_by_name(path, 0);
    if (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli) {
      vpiHandle h = (vpiHandle)mhpi_get_vpi_handle(mhpiH);
      int res = uvm_hdl_get_vlog(h, path, value, vpiNoDelay);
      mhpi_release_handle(mhpiH);
      return res;
    }
    else if (mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli) {
      vhpiHandleT h = (vhpiHandleT)mhpi_get_vhpi_handle(mhpiH);
      int res =  uvm_hdl_get_vhpi(h, path,value);
      mhpi_release_handle(mhpiH);
      return res;
    }
#else
    mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
    if (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli) {
      mhpi_release_parent_handle(mhpiH);
      return uvm_hdl_get_vlog(path, value, vpiNoDelay);
    }
    else if (mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli) {
      mhpi_release_parent_handle(mhpiH);
      return uvm_hdl_get_mhdl(path,value);
    }
#endif
#else //VCSMX
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    vpiHandle h = vpi_handle_by_name(path, 0);
    int res =  uvm_hdl_get_vlog(h, path, value, vpiNoDelay);
    vpi_release_handle(h);
    return res;
#else
    return uvm_hdl_get_vlog(path, value, vpiNoDelay);
#endif
#endif
}


/*
 *decimal to hex conversion
 */
char *dtob(PLI_UINT32 decimalNumber, PLI_UINT32 msb) {
  PLI_UINT32  quotient;
  int  i=0,j, length;
  int binN[65]; //uvm_hdl_max_width
  static char binaryNumber[65];  //uvm_hdl_max_width

  memset(binN, 0, sizeof(int)*65);

  quotient = decimalNumber;
  do {
    binN[i++] = quotient%2;
    quotient = quotient/2;
  } while (quotient != 0);

  if (!msb)
      length = 32;
  else
      length = i;

  for (i=length-1, j = 0; i>=0; i--) {
    binaryNumber[j++] = binN[i]?'1':'0';
  }
  binaryNumber[j] = '\0';
  return(binaryNumber);
}

/* char* itoa(int val, int base){ */
/*     static char buf[32] = {0}; */
/*     int i = 30; */
/*     do { */
/*         buf[i--] = "0123456789abcdef"[val % base]; */
/*         val = val/base; */
/*     } while (val != 0); */
/*     return &buf[i+1]; */

/* } */


/*
 * Mixed lanaguage API Get calls
 */
#ifdef VCSMX
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
int uvm_hdl_set_mhdl(mhpiHandleT h, char *path, p_vpi_vecval value, mhpiPutValueFlagsT flags) 
{
    mhpiRealT forceDelay = 0;
    mhpiRealT cancelDelay = -1;
    mhpiReturnT ret;
    s_vpi_vecval tempval;

 
    PLI_UINT32 size = mhpi_get(mhpiSizeP, h);
    PLI_UINT32 max_i = (size-1)/32 + 1;
    char* buf = get_memory_for_alloc(size + 1); 
    buf[0] = '\0';

    for (int i = max_i -1; i >= 0; i--) {
      int sz;  
      char* force_value =dtob(value[i].aval, ((max_i - 1) == i));
      sz = ((max_i - 1) == i) ? size - 32*(max_i-1) : 32;
      strncat(buf, force_value, sz);
    }

    ret = mhpi_force_value_by_handle(h, buf, flags, forceDelay, cancelDelay); 
    if (ret == mhpiRetOk) {
      return(1);
    }else {
      return(0);
    }
}
#else //undef VCSMX_FAST_UVM
int uvm_hdl_set_mhdl(char *path, p_vpi_vecval value, mhpiPutValueFlagsT flags) 
{
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
    mhpiRealT forceDelay = 0;
    mhpiRealT cancelDelay = -1;
    mhpiReturnT ret;
    s_vpi_vecval tempval;

    mhpiHandleT h = mhpi_handle_by_name(path, 0);
    mhpiHandleT mhpi_mhRegion = mhpi_handle(mhpiScope, h);
 
    PLI_UINT32 size = mhpi_get(mhpiSizeP, h);
    PLI_UINT32 max_i = (size-1)/32 + 1;
    char* buf = (char *) malloc(sizeof(char)*(size+1));
    buf[0] = '\0';

    for (int i = max_i -1; i >= 0; i--) {
      int sz;  
      char* force_value =dtob(value[i].aval, ((max_i - 1) == i));
      sz = ((max_i - 1) == i) ? size - 32*(max_i-1) : 32;
      strncat(buf, force_value, sz);
    }

    ret = mhpi_force_value(path, mhpi_mhRegion, buf, flags, forceDelay, cancelDelay); 
    free(buf);
    mhpi_release_parent_handle(h);
    if (ret == mhpiRetOk) {
      return(1);
    }else {
      return(0);
    }
}
#endif
#endif

/*
 * Given a path, look the path name up using the PLI
 * or the FLI, and set it to 'value'.
 */
int uvm_hdl_deposit(char *path, p_vpi_vecval value)
{
#ifdef VCSMX
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    mhpiHandleT mhpiH = mhpi_uvm_handle_by_name(path, 0);
    if ( (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli)) {
       vpiHandle h = (vpiHandle)mhpi_get_vpi_handle(mhpiH);
       int res = uvm_hdl_set_vlog(h, path, value, vpiNoDelay);       
       mhpi_release_handle(mhpiH);
       return res;
    } 
    if ( (mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli)) {
      int res = uvm_hdl_set_mhdl(mhpiH, path, value, mhpiNoDelay);
      return res;
    }else {
      return (0);
    }
#else //undef VCSMX_FAST_UVM
    mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);

    if ( (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli)) {
      mhpi_release_parent_handle(mhpiH);
      //return uvm_hdl_set_mhdl(path, value, mhpiNoDelay);
       return uvm_hdl_set_vlog(path, value, vpiNoDelay);       
    } 
    if ( (mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli)) {
      mhpi_release_parent_handle(mhpiH);
      return uvm_hdl_set_mhdl(path, value, mhpiNoDelay);
    }else {
      return (0);
    }
#endif //VCSMX_FAST_UVM
#else //undef VCSMX
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    vpiHandle h = vpi_handle_by_name(path, 0);
    int res = uvm_hdl_set_vlog(h, path, value, vpiNoDelay);       
    vpi_release_handle(h);
    return res;
#else //undef VCSMX_FAST_UVM
    return uvm_hdl_set_vlog(path, value, vpiNoDelay); 
#endif
#endif

}


/*
 * Given a path, look the path name up using the PLI
 * or the FLI, and set it to 'value'.
 */
int uvm_hdl_force(char *path, p_vpi_vecval value)
{
#ifdef VCSMX
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    mhpiHandleT mhpiH= mhpi_uvm_handle_by_name(path, 0);
    if  (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli) {
      vpiHandle h = (vpiHandle)mhpi_get_vpi_handle(mhpiH);
      int res = uvm_hdl_set_vlog(h, path, value, vpiForceFlag);
      mhpi_release_handle(mhpiH);
      return res;
    }
    if ( mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli) {
      int res =  uvm_hdl_set_mhdl(mhpiH, path, value, mhpiForce);
      return res;
    } else {
      return (0);
    }
#else //undef VCSMX_FAST_UVM
    mhpiHandleT mhpiH= mhpi_handle_by_name(path, 0);

    if  (mhpi_get(mhpiPliP, mhpiH) == mhpiVpiPli) {
      mhpi_release_parent_handle(mhpiH);
      return uvm_hdl_set_vlog(path, value, vpiForceFlag);
    }
    if ( mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli) {
      mhpi_release_parent_handle(mhpiH);
      return uvm_hdl_set_mhdl(path, value, mhpiForce);
    } else {
      return (0);
    }
#endif // VCSMX_FAST_UVM
#else
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    vpiHandle h = vpi_handle_by_name(path, 0);
    int res = uvm_hdl_set_vlog(h, path, value, vpiForceFlag);
    vpi_release_handle(h);
    return res;
#else //undef VCSMX_FAST_UVM
    return uvm_hdl_set_vlog(path, value, vpiForceFlag);
#endif  //VCSMX_FAST_UVM
#endif
}


/*
 * Given a path, look the path name up using the PLI
 * or the FLI, and release it.
 */
int uvm_hdl_release_and_read(char *path, p_vpi_vecval value)
{
#ifdef VCSMX
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    mhpiHandleT mhpiH = mhpi_uvm_handle_by_name(path, 0);
#else 
    mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
#endif
    mhpiReturnT ret;
    mhpiHandleT mhpi_mhRegion = mhpi_handle(mhpiScope, mhpiH);
    if ((mhpi_get(mhpiPliP, mhpiH) ==  mhpiVpiPli) ||
	(mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli)) {
      ret = mhpi_release_force(path, mhpi_mhRegion);
      mhpi_release_handle(mhpiH);
      if (ret == mhpiRetOk) {
        return(1);
      }
      else 
        return(0);
      }
    else
      return (0);
#else    
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    vpiHandle h = vpi_handle_by_name(path, 0);
    int res =  uvm_hdl_set_vlog(h, path, value, vpiReleaseFlag);
    vpi_release_handle(h);
    return res;
#else //undef VCSMX_FAST_UVM
    return uvm_hdl_set_vlog(path, value, vpiReleaseFlag);
#endif
#endif
}

/*
 * Given a path, look the path name up using the PLI
 * or the FLI, and release it.
 */
int uvm_hdl_release(char *path)
{
    s_vpi_vecval value;
    p_vpi_vecval valuep = &value;
#ifdef VCSMX
#ifndef USE_DOT_AS_HIER_SEP
    mhpi_initialize('/');
#else
    mhpi_initialize('.');
#endif
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    mhpiHandleT mhpiH = mhpi_uvm_handle_by_name(path, 0);
#else 
    mhpiHandleT mhpiH = mhpi_handle_by_name(path, 0);
#endif
    mhpiReturnT ret;
    mhpiHandleT mhpi_mhRegion = mhpi_handle(mhpiScope, mhpiH);

    if ((mhpi_get(mhpiPliP, mhpiH) ==  mhpiVpiPli) ||
	(mhpi_get(mhpiPliP, mhpiH) == mhpiVhpiPli)) {
#ifdef VCSMX_FORCE_KEEP_VAL
      ret = mhpi_release_force_keep_value(path, mhpi_mhRegion);
#else
      ret = mhpi_release_force(path, mhpi_mhRegion);
#endif
      mhpi_release_handle(mhpiH);
      if (ret == mhpiRetOk) {
        return(1);
      } else {
        return(0);
      }
    } else {
      return (0);
    }
#else
#if defined(VCSMX_FAST_UVM) && !defined(QUESTA)
    vpiHandle h = vpi_handle_by_name(path, 0);
    int res = uvm_hdl_set_vlog(h, path, valuep, vpiReleaseFlag);
    vpi_release_handle(h);
    return res;
#else
    return uvm_hdl_set_vlog(path, valuep, vpiReleaseFlag);
#endif
#endif
}


