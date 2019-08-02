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


#ifndef VGCOMMON_RVM_ROOT_SV_UVM_1_2_INCLUDE_PUREC_SNPS_REG_RW_API_H
#define VGCOMMON_RVM_ROOT_SV_UVM_1_2_INCLUDE_PUREC_SNPS_REG_RW_API_H

#include <stdio.h>

#include "uints.h"


namespace snps_reg
{
    inline volatile uint8  regRead(volatile uint8  *addr)
    {
#ifdef SNPS_REG_DEBUG
        printf("Reading uint8 from 0x%08x...\n", addr);
#endif
#ifndef SNPS_REG_NOP
        return *addr;
#endif
    };
    
    inline volatile uint16 regRead(volatile uint16 *addr)
    {
#ifdef SNPS_REG_DEBUG
        printf("Reading uint16 from 0x%08x...\n", addr);
#endif
#ifndef SNPS_REG_NOP
        return *addr;
#endif
    };
    
    inline volatile uint32 regRead(volatile uint32 *addr)
    {
#ifdef SNPS_REG_DEBUG
        printf("Reading uint32 from 0x%08x...\n", addr);
#endif
#ifndef SNPS_REG_NOP
        return *addr;
#endif
    };
    

    inline void regWrite(volatile uint8  *addr, uint8  val)
    {
#ifdef SNPS_REG_DEBUG
        printf("Writing uint8 0x%08x to 0x%08x...\n", val, addr);
#endif
#ifndef SNPS_REG_NOP
        (*addr) = val;
#endif
    };
    
    inline void regWrite(volatile uint16 *addr, uint16 val)
    {
#ifdef SNPS_REG_DEBUG
        printf("Writing uint16 0x%08x to 0x%08x...\n", val, addr);
#endif
#ifndef SNPS_REG_NOP
        (*addr) = val;
#endif
    };

    inline void regWrite(volatile uint32 *addr, uint32 val)
    {
#ifdef SNPS_REG_DEBUG
        printf("Writing uint32 0x%08x to 0x%08x...\n", val, addr);
#endif
#ifndef SNPS_REG_NOP
        (*addr) = val;
#endif
    };


//
// The following are basic list implementations for registering block and register
//
#ifdef SNPS_REG_ENABLE_REG_ITER
template <class T>
class Node {
    private:
    public:
        T _data;
        Node<T> * _next;
        Node<T>(const T& data) : _data(data), _next(0x0) {}
};

template <class T>
class List {
    private:
        Node <T> * _head;
        Node <T> * _current;
        int        _count;
    public:
        List<T>() : _head(0x0), _current(0x0), _count(0) {}
        void insert(T data) {
            Node<T> * newNode = new Node<T>(data);
            if (_head == NULL) {
                _head = newNode;
                _current = newNode;
            } else {
                _current->_next = newNode;
                _current = newNode;
            }
            _count++;
        }

        int getListData(T** data) {
            int index = 0;
            *data = (T *)malloc(_count*sizeof(T));
            Node<T> *temp = _head;
            while (temp) {
                (*data)[index++] = temp->_data;
                temp = temp->_next;
            }
            return _count;
        }
};
#endif

typedef volatile unsigned int * reg_addr;


//
// The following are implementation-specific and should not be used
// directly in user code.
//

    
    class regmodel {

    public:
        regmodel(regmodel *parent,
                 const char* const name,
                 size_t baseAddr)
            : m_baseAddr(baseAddr)
        {}
        
        regmodel(int ctxt)
            : m_baseAddr(0)
        {}

#ifdef SNPS_REG_ENABLE_REG_ITER
        int getRegisters(reg_addr **regs, int hier = 1) {
            int count = m_registers.getListData(regs);
            if (hier) {
                    snps_reg::regmodel** blks;
                    int comp_count = m_blocks.getListData(&blks);
                    for (int i = 0; i < comp_count; i++) {
                        snps_reg::reg_addr *comp_regs;
                        int reg_count = blks[i]->getRegisters(&comp_regs);
                        *regs = (snps_reg::reg_addr *) realloc(*regs, sizeof(snps_reg::reg_addr)*(reg_count+count));
                        for (int j = 0; j < reg_count; j++) {
                           (*regs)[j+count] = comp_regs[j];
                        }
                        free(comp_regs);
                        count = count + reg_count;
                    }
                    free(blks);
            }
            return count;
        }
#endif
        
    protected:
       const size_t m_baseAddr;
#ifdef SNPS_REG_ENABLE_REG_ITER
       List<reg_addr> m_registers;
       List<snps_reg::regmodel *> m_blocks;
#endif
    };
};

#ifdef SNPS_REG_ENABLE_REG_ITER
#define SNPS_REG_ADD_BLK_TO_LIST(_name)    m_blocks.insert(& _name);
#define SNPS_REG_ADD_BLK_ARRAY_TO_LIST(_name, _size) \
    for (int idx = 0; idx <_size; idx++) \
       m_blocks.insert(&_name[idx]);
#endif

#define SNPS_REG_INIT_REG_ARRAY(_name, _index, _start_index)     

#define SNPS_REG_ADDROF_REG_ARRAY(_type, _name, _size, _start_index, _offset, _incr)          \
    public:                                                                     \
    inline volatile _type *_name(int index)                                     \
    {                                                                           \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset + _incr * (index - _start_index)); \
    }
#define SNPS_REG_INIT_2D_REG_ARRAY(_name, _index1, _index2, _start_index1, _start_index2)  

#define SNPS_REG_ADDROF_2D_REG_ARRAY(_type, _name, _size1, _size2, _start_index1, _start_index2, _offset, _incr1, _incr2)          \
    private:                                                                    \
    public:                                                                     \
    inline volatile _type *_name(int index1, int index2)                                     \
    {                                                                           \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset + _incr1 * (index1-_start_index1) +_incr2 * (index2-_start_index2)); \
    }

#define SNPS_REG_INIT_3D_REG_ARRAY(_name, _index1, _index2, _index3, _start_index1, _start_index2, _start_index3) 

#define SNPS_REG_ADDROF_3D_REG_ARRAY(_type, _name, _size1, _size2, _size3, _start_index1, _start_index2, _start_index3, _offset, _incr1, _incr2, _incr3)          \
    private:                                                                    \
    public:                                                                     \
    inline volatile _type *_name(int index1, int index2, int index3)                                     \
    {                                                                           \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset + _incr1 * (index1-_start_index1) +_incr2 * (index2-_start_index2) +_incr3 * (index3-_start_index3)); \
    }

#define SNPS_REG_INIT_REG_ARRAY_FLD(_rg, _name, _index, _start_index) 

#define SNPS_REG_ADDROF_REG_ARRAY_FLD(_type, _reg, _size, _start_index, _name, _offset, _incr) \
    public:                                                                      \
    inline volatile _type *_reg##_##_name(int index)                             \
    {                                                                            \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset + _incr * (index-_start_index)); \
    }

#define SNPS_REG_INIT_2D_REG_ARRAY_FLD(_rg, _name, _index1, _index2, _start_index1, _start_index2)  

#define SNPS_REG_ADDROF_2D_REG_ARRAY_FLD(_type, _reg, _size1, _size2, _start_index1, _start_index2, _name, _offset, _incr1, _incr2) \
    public:                                                                      \
    inline volatile _type *_reg##_##_name(int index1, int index2)                \
    {                                                                            \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset + _incr1 * (index1 - _start_index1) + _incr2 * (index2 - _start_index2)); \
    }


#define SNPS_REG_INIT_3D_REG_ARRAY_FLD(_rg, _name, _index1, _index2, _index3, _start_index1, _start_index2, _start_index3)  

#define SNPS_REG_ADDROF_3D_REG_ARRAY_FLD(_type, _reg, _size1, _size2, _size3, _start_index1, _start_index2, _start_index3, _name, _offset, _incr1, _incr2, _incr3) \
    private:                                                                     \
    public:                                                                      \
    inline volatile _type *_reg##_##_name(int index1, int index2, int index3)    \
    {                                                                            \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset + _incr1 * (index1 - _start_index1) + _incr2 * (index2 - _start_index2) + _incr3* (index3 - _start_index3)); \
    }

#define SNPS_REG_INIT_REG(_name)       __##_name##_id__(0)

#define SNPS_REG_ADDROF_REG(_type, _name, _offset)                      \
    private:                                                            \
    uint32 __##_name##_id__;                                            \
    public:                                                             \
    inline volatile _type *_name()                                      \
    {                                                                   \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset); \
    }

#define SNPS_REG_ADD_REG_TO_LIST(_name)    m_registers.insert((snps_reg::reg_addr)_name());
#define SNPS_REG_ADD_REG_ARRAY_TO_LIST(_name, lsb1, msb1)                     \
for (int index = lsb1; index <= msb1; index++) {                            \
    m_registers.insert((snps_reg::reg_addr)_name(index));                                   \
}

#define SNPS_REG_ADD_2D_REG_ARRAY_TO_LIST(_name, lsb1, msb1, lsb2, msb2)          \
for (int index1 = lsb1; index1 <= msb1; index1++) {                                        \
    for (int index2 = lsb2; index2 <= msb2; index2++) {                                   \
        m_registers.insert((snps_reg::reg_addr)_name(index1,index2));           \
    }                                                                                  \
}

#define SNPS_REG_ADD_3D_REG_ARRAY_TO_LIST(_name, lsb1, msb1, lsb2, msb2, lsb3, msb3)                   \
for (int index1 = lsb1; index1 <= msb1; index1++) {                                        \
    for (int index2 = lsb2; index2 <= msb2; index2++) {                                   \
        for (int index3 = lsb3; index3 <= msb3; index3++) {                               \
            m_registers.insert((snps_reg::reg_addr)_name(index1,index2,index3));           \
        }                                                                              \
    }                                                                                  \
}

#define SNPS_REG_INIT_FLD(_rg, _name)  __##_rg##_##_name##_id__(0)

#define SNPS_REG_ADDROF_FLD(_type, _reg, _name, _offset)                \
    private:                                                            \
    long __##_reg##_##_name##_id__;                                     \
    public:                                                             \
    inline volatile _type *_reg##_##_name()                             \
    {                                                                   \
        return reinterpret_cast<volatile _type*>(m_baseAddr + _offset); \
    }

#endif
