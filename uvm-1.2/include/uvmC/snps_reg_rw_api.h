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


#ifndef VGCOMMON_RVM_ROOT_SV_UVM_1_2_INCLUDE_UVMC_SNPS_REG_RW_API_H
#define VGCOMMON_RVM_ROOT_SV_UVM_1_2_INCLUDE_UVMC_SNPS_REG_RW_API_H

#include <stdio.h>
#include <string.h>

#include "svdpi.h"

#include "uints.h"


namespace snps_reg
{

    extern "C" {
        uint32 snps_reg__regRead(uint32 reg_id, uint64* val);
        uint32 snps_reg__regReadAtAddr(uint32 reg_addr, uint64* val);
        void snps_reg__regWrite(uint32 reg_id, uint64 val);
        void snps_reg__regWriteAtAddr(uint32 reg_addr, uint64 val);
        uint32 snps_reg__regGet(uint32 reg_id, uint64* val);
        uint32 snps_reg__regGetAtAddr(uint32 reg_addr, uint64* val);
        void snps_reg__regSet(uint32 reg_id, uint64 val);
        void snps_reg__regSetAtAddr(uint32 reg_addr, uint64 val);
        const char* snps_reg__get_context_name(int ctxt);
        void snps_reg__use_context_map(int ctxt);
    }

    typedef struct reg_map_id {
        uint32 reg_id;
        uint32 map_id;
    } reg_map_id;
    

    inline volatile uint64 regRead(struct reg_map_id addr)
    {
		uint64 val;
        snps_reg__use_context_map(addr.map_id);
        snps_reg__regRead(addr.reg_id, &val);
		return val;
    };

    inline volatile uint64 regRead(uint32 *addr)
    {
		uint64 val;
        snps_reg__regReadAtAddr((unsigned long long)addr, &val);
		return val;
    };
    
    inline void regWrite(struct reg_map_id addr, uint64 val)
    {
        snps_reg__use_context_map(addr.map_id);
        snps_reg__regWrite(addr.reg_id, val);
    };

    inline void regWrite(uint32 *addr, uint64 val)
    {
        snps_reg__regWriteAtAddr((unsigned long long)addr, val);
    }
    
    inline volatile uint64 regGet(struct reg_map_id addr)
    {
		uint64 val;
        snps_reg__use_context_map(addr.map_id);
        snps_reg__regGet(addr.reg_id, &val);
		return val;
    };

    inline volatile uint64 regGet(uint32 *addr)
    {
		uint64 val;
        snps_reg__regGetAtAddr((unsigned long long)addr, &val);
		return val;
    };
    
    inline void regSet(struct reg_map_id addr, uint64 val)
    {
        snps_reg__use_context_map(addr.map_id);
        snps_reg__regSet(addr.reg_id,  val);
    };
    

    inline void regSet(uint32 *addr, uint64 val)
    {
        snps_reg__regSetAtAddr((unsigned long long)addr, val);
    }

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

typedef reg_map_id reg_addr;


//
// The following are implementation-specific and should not be used
// directly in user code.
//

    class regmodel {

    public:
        regmodel(regmodel *parent,
                 const char* const name,
                 size_t baseAddr)
            : m_parent(parent),
            m_name(strdup(name)),
            m_baseAddr(baseAddr)
        {}

        regmodel(int ctxt)
            : m_parent(0),
            m_name(strdup(m_get_context_name(ctxt))),
            m_baseAddr(ctxt)
        {}

            const char* const get_full_name()
            {
                static char full_name[4096];
                static char *p;
                static const char *p_mname;
                
                if (m_parent == 0) p = full_name;
                else {
                    (void) m_parent->get_full_name();
                    *p++ = '.';
                }
#ifdef SNPS_REG_CONTEXT_BASED_NAME
				p_mname = m_get_context_name(m_baseAddr);
                strcpy(p, p_mname);
                p += strlen(p_mname);
#else
                strcpy(p, m_name); //the previous 2 lines is a WA for when m_name gets corrupted when there is a dleay between accesses to registers in the same block
                p += strlen(m_name);
#endif
                *p = '\0';

                return full_name;
            }

#ifdef SNPS_REG_ENABLE_REG_ITER
            int getRegisters(snps_reg::reg_map_id **regs, int hier = 1) {
                int count = m_registers.getListData(regs);
                if (hier) {
                    snps_reg::regmodel** blks;
                    int comp_count = m_blocks.getListData(&blks);
                    for (int i = 0; i < comp_count; i++) {
                        snps_reg::reg_addr *comp_regs;
                        int reg_count = blks[i]->getRegisters(&comp_regs);
                        *regs = (snps_reg::reg_map_id *) realloc(*regs, sizeof(snps_reg::reg_map_id)*(reg_count+count));
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
        regmodel *m_parent;
        const char* m_name;
        const size_t m_baseAddr;
#ifdef SNPS_REG_ENABLE_REG_ITER
       List<snps_reg::reg_map_id> m_registers;
       List<snps_reg::regmodel*> m_blocks;
#endif

        void set_scope()
        {
            static svScope m_scp = NULL;
            if (m_scp == NULL)
                m_scp = svGetScopeFromName("$unit");
            svSetScope(m_scp);
        }

        const char* m_get_context_name(int ctxt)
        {
            set_scope();
            return snps_reg__get_context_name(ctxt);
        }

        uint32 get_context_id()
        {
            // Only the root has the context ID stored in the base address
            regmodel *rm = this;
            while (rm->m_parent) rm = rm->m_parent;
            return rm->m_baseAddr;
        }
    };

};


extern "C" {
    uint32 snps_reg__get_reg_id(const char* const path,
                                const char* const name);

    uint32 snps_reg__get_fld_id(const char* const path,
                                const char* const reg,
                                const char* const name);

    uint32 snps_reg__get_reg_array_id(const char* const path,
                                const char* const name, int index1,
                                int index2, int index3);

    uint32 snps_reg__get_fld_array_id(const char* const path,
                                const char* const reg,
                                const char* const name, int index1,
                                int index2, int index3);
}
/*
extern "C" {
    uint32 snps_reg__regRead(uint32 reg_id);
    void snps_reg__regWrite(uint32 reg_id, uint32 val);
    uint32 snps_reg__regGet(uint32 reg_id);
    void snps_reg__regSet(uint32 reg_id, uint32 val);
}
*/

#ifdef SNPS_REG_ENABLE_REG_ITER
#define SNPS_REG_ADD_BLK_TO_LIST(_name)    m_blocks.insert(&_name);
#define SNPS_REG_ADD_BLK_ARRAY_TO_LIST(_name, _size) \
    for (int idx = 0; idx <_size; idx++) \
       m_blocks.insert(&_name[idx]);
#endif

#define SNPS_REG_INIT_REG_ARRAY(_name, _index, _start_index)       __##_name##_id__[_index-_start_index] = 0;

#define SNPS_REG_ADDROF_REG_ARRAY(_type, _name, _size, _start_index, _offset, _incr)          \
    private:                                                                    \
    uint32 __##_name##_id__[_size-_start_index];                                             \
    public:                                                                     \
    inline snps_reg::reg_map_id _name(int index)                                     \
    {                                                                           \
                if (__##_name##_id__[index-_start_index] == 0) {                                    \
            set_scope();                                                \
            __##_name##_id__[index-_start_index] = snps_reg__get_reg_array_id(get_full_name(), #_name,index, -1, -1); \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_name##_id__[index-_start_index], get_context_id()};                       \
        return addr; \
    }

#define SNPS_REG_INIT_2D_REG_ARRAY(_name, _index1, _index2, _start_index1, _start_index2)       __##_name##_id__[_index1-_start_index1][_index2-_start_index2] = 0;

#define SNPS_REG_ADDROF_2D_REG_ARRAY(_type, _name, _size1, _size2, _start_index1, _start_index2, _offset, _incr1, _incr2)          \
    private:                                                                    \
    uint32 __##_name##_id__[_size1-_start_index1][_size2-_start_index2];        \
    public:                                                                     \
    inline snps_reg::reg_map_id _name(int index1, int index2)                       \
    {                                                                           \
                if (__##_name##_id__[_size1-_start_index1][_size2-_start_index2] == 0) {                                    \
            set_scope();                                                \
            __##_name##_id__[_size1-_start_index1][_size2-_start_index2] = snps_reg__get_reg_array_id(get_full_name(), #_name,index1, index2, -1); \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_name##_id__[_size1-_start_index1][_size2-_start_index2], get_context_id()};                       \
        return addr; \
    }

#define SNPS_REG_INIT_3D_REG_ARRAY(_name, _index1, _index2, _index3, _start_index1, _start_index2, _start_index3)       __##_name##_id__[_index1-_start_index1][_index2-_start_index2][_index3-_start_index3] = 0;

#define SNPS_REG_ADDROF_3D_REG_ARRAY(_type, _name, _size1, _size2, _size3, _start_index1, _start_index2, _start_index3, _offset, _incr1, _incr2, _incr3)         \
    private:                                                                    \
    uint32 __##_name##_id__[_size1-_start_index1][_size2-_start_index2][_size3-_start_index3];                                             \
    public:                                                                     \
    inline snps_reg::reg_map_id _name(int index1, int index2, int index3)                       \
    {                                                                           \
                if (__##_name##_id__[index1-_start_index1][index2][index3] == 0) {                                    \
            set_scope();                                                \
            __##_name##_id__[index1][index2][index3] = snps_reg__get_reg_array_id(get_full_name(), #_name,index1, index2, index3); \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_name##_id__[index1][index2][index3], get_context_id()};                       \
        return addr; \
    }


#define SNPS_REG_INIT_REG_ARRAY_FLD(_rg, _name, _index, _start_index)  __##_rg##_##_name##_id__[_index-_start_index] = 0;

#define SNPS_REG_ADDROF_REG_ARRAY_FLD(_type, _reg, _size, _start_index, _name, _offset, _incr) \
    private:                                                                     \
    uint32 __##_reg##_##_name##_id__[_size-_start_index];                                       \
    public:                                                                      \
    inline snps_reg::reg_map_id _reg##_##_name(int index)                             \
    {                                                                            \
                 if (__##_reg##_##_name##_id__[index-_start_index] == 0) {                           \
            set_scope();                                                \
            __##_reg##_##_name##_id__[index-_start_index] = snps_reg__get_fld_array_id(get_full_name(), \
                                                             #_reg,     \
                                                             #_name, index, -1, -1);   \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_reg##_##_name##_id__[index-_start_index], get_context_id()};              \
        return addr;                                                    \
    }

#define SNPS_REG_INIT_2D_REG_ARRAY_FLD(_rg, _name, _index1, _index2, _start_index1, _start_index2)  __##_rg##_##_name##_id__[_index1-_start_index1][_index2-_start_index2] = 0;

#define SNPS_REG_ADDROF_2D_REG_ARRAY_FLD(_type, _reg, _size1, _size2, _start_index1, _start_index2, _name, _offset, _incr1, _incr2) \
    private:                                                                     \
    uint32 __##_reg##_##_name##_id__[_size1-_start_index1][_size2-_start_index2];                                       \
    public:                                                                      \
    inline snps_reg::reg_map_id _reg##_##_name(int index1, int index2)                             \
    {                                                                            \
                 if (__##_reg##_##_name##_id__[index1-_start_index1][index2-_start_index2] == 0) {                           \
            set_scope();                                                \
            __##_reg##_##_name##_id__[index1-_start_index1][index2-_start_index2] = snps_reg__get_fld_array_id(get_full_name(), \
                                                             #_reg,     \
                                                             #_name, index1, index2, -1);   \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_reg##_##_name##_id__[index1-_start_index1][index2-_start_index2], get_context_id()};              \
        return addr;                                                    \
    }

#define SNPS_REG_INIT_3D_REG_ARRAY_FLD(_rg, _name, _index1, _index2, _index3, _start_index1, _start_index2, _start_index3)  __##_rg##_##_name##_id__[_index1-_start_index1][_index2-_start_index2][_index3 - _start_index3] = 0;

#define SNPS_REG_ADDROF_3D_REG_ARRAY_FLD(_type, _reg, _size1, _size2, _size3, _start_index1, _start_index2, _start_index3, _name, _offset, _incr1, _incr2, _incr3) \
    private:                                                                     \
    uint32 __##_reg##_##_name##_id__[_size1-_start_index1][_size2-_start_index2][_size3-_start_index3];                                       \
    public:                                                                      \
    inline snps_reg::reg_map_id _reg##_##_name(int index1, int index2, int index3)                             \
    {                                                                            \
                 if (__##_reg##_##_name##_id__[index1-_start_index1][index2-_start_index2][index3-_start_index3] == 0) {                           \
            set_scope();                                                \
            __##_reg##_##_name##_id__[index1-_start_index1][index2-_start_index2][index3-_start_index3] = snps_reg__get_fld_array_id(get_full_name(), \
                                                             #_reg,     \
                                                             #_name, index1, index2, index3);   \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_reg##_##_name##_id__[index1-_start_index1][index2-_start_index2][index3-_start_index3], get_context_id()};              \
        return addr;                                                    \
    }

#define SNPS_REG_INIT_REG(_name)       __##_name##_id__(0)

#define SNPS_REG_ADDROF_REG(_type, _name, _offset)                      \
    private:                                                            \
    uint32 __##_name##_id__;                                            \
    public:                                                             \
    inline snps_reg::reg_map_id _name()                                 \
    {                                                                   \
        if (__##_name##_id__ == 0) {                                    \
            set_scope();                                                \
            __##_name##_id__ = snps_reg__get_reg_id(get_full_name(), #_name); \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_name##_id__, get_context_id()};                       \
        return addr;                                                    \
    }

#ifdef SNPS_REG_ENABLE_REG_ITER
#define SNPS_REG_ADD_REG_TO_LIST(_name)    m_registers.insert(_name());
#define SNPS_REG_ADD_REG_ARRAY_TO_LIST(_name, lsb1, msb1)                     \
for (int index = lsb1; index <= msb1; index++) {                            \
    m_registers.insert(_name(index));                                   \
}

#endif

#define SNPS_REG_ADD_2D_REG_ARRAY_TO_LIST(_name, lsb1, msb1, lsb2, msb2)          \
for (int index1 = lsb1; index1 <= msb1; index1++) {                                        \
    for (int index2 = lsb2; index2 <= msb2; index2++) {                                   \
        m_registers.insert(_name(index1,index2));           \
    }                                                                                  \
}

#define SNPS_REG_ADD_3D_REG_ARRAY_TO_LIST(_name, lsb1, msb1, lsb2, msb2, lsb3, msb3)                   \
for (int index1 = lsb1; index1 <= msb1; index1++) {                                        \
    for (int index2 = lsb2; index2 <= msb2; index2++) {                                   \
        for (int index3 = lsb3; index3 <= msb3; index3++) {                               \
            m_registers.insert(_name(index1,index2,index3));           \
        }                                                                              \
    }                                                                                  \
}

#define SNPS_REG_INIT_FLD(_rg, _name)  __##_rg##_##_name##_id__(0)

#define SNPS_REG_ADDROF_FLD(_type, _reg, _name, _offset)                \
    private:                                                            \
    uint32 __##_reg##_##_name##_id__;                                   \
    public:                                                             \
    inline snps_reg::reg_map_id _reg##_##_name()                        \
    {                                                                   \
        if (__##_reg##_##_name##_id__ == 0) {                           \
            set_scope();                                                \
            __##_reg##_##_name##_id__ = snps_reg__get_fld_id(get_full_name(), \
                                                             #_reg,     \
                                                             #_name);   \
        }                                                               \
        snps_reg::reg_map_id addr =                                     \
            {__##_reg##_##_name##_id__, get_context_id()};              \
        return addr;                                                    \
    }


#endif
