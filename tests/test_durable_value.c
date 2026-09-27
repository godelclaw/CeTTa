#include "durable_value.h"
#include "symbol.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void roundtrip(Arena *a, Atom *value) {
    unsigned char *bytes=NULL,*again=NULL; size_t size=0,n=0; Atom *copy=NULL;
    assert(cetta_durable_value_encode(value,&bytes,&size)==DURABLE_OK);
    assert(cetta_durable_value_decode(a,bytes,size,&copy)==DURABLE_OK);
    assert(cetta_durable_value_encode(copy,&again,&n)==DURABLE_OK);
    assert(size==n && !memcmp(bytes,again,n));
    for (size_t i=0;i<size;++i) {
        Atom *bad=NULL;
        assert(cetta_durable_value_decode(a,bytes,i,&bad)!=DURABLE_OK && !bad);
    }
    bytes=realloc(bytes,size+1); assert(bytes); bytes[size]=0;
    assert(cetta_durable_value_decode(a,bytes,size+1,&copy)==DURABLE_CORRUPT);
    free(bytes); free(again);
}

int main(void) {
    SymbolTable symbols; symbol_table_init(&symbols);
    symbol_table_init_builtins(&symbols,&g_builtin_syms); g_symbols=&symbols;
    Arena a; arena_init(&a);
    Atom *values[]={atom_symbol(&a,"symbol \\\""),atom_int(&a,INT64_MIN),atom_int(&a,INT64_MAX),
        atom_float(&a,-0.0),atom_float(&a,NAN),atom_float(&a,INFINITY),atom_float(&a,1e-310),
        atom_bool(&a,true),atom_bool(&a,false),atom_string(&a,"\nquoted \" 雪\\"),atom_expr(&a,NULL,0)};
    roundtrip(&a,atom_expr(&a,values,sizeof(values)/sizeof(*values)));
#if CETTA_BUILD_WITH_GMP
    roundtrip(&a,atom_bigint(&a,"184467440737095516160"));
    roundtrip(&a,atom_rational(&a,"-184467440737095516160/3"));
#endif
    unsigned char *bytes=NULL; size_t size=0;
    assert(cetta_durable_value_encode(atom_var(&a,"x"),&bytes,&size)==DURABLE_INVALID);
    SymbolId binary_name=symbol_intern_bytes(g_symbols,(const uint8_t *)"x\0y",3);
    assert(cetta_durable_value_encode(atom_symbol_id(&a,binary_name),&bytes,&size)==DURABLE_INVALID);
    Atom *handle=atom_expr3(&a,atom_symbol(&a,"NativeHandle"),atom_string(&a,"x"),atom_int(&a,1));
    assert(cetta_durable_value_encode(handle,&bytes,&size)==DURABLE_INVALID);
    Atom *deep=atom_int(&a,0);
    for (int i=0;i<140;++i) deep=atom_expr(&a,&deep,1);
    assert(cetta_durable_value_encode(deep,&bytes,&size)==DURABLE_LIMIT);
    Atom *dag=atom_int(&a,0);
    for (int i=0;i<40;++i) dag=atom_expr2(&a,dag,dag);
    assert(cetta_durable_value_encode(dag,&bytes,&size)==DURABLE_LIMIT);
    const unsigned char zero_denominator[]={'C','D','V','1','Q',4,0,0,0,'1','/','-','0'};
    Atom *bad=NULL;
    assert(cetta_durable_value_decode(&a,zero_denominator,sizeof(zero_denominator),&bad)==DURABLE_CORRUPT);
    const unsigned char huge_expr[]={'C','D','V','1','E',255,255,255,255};
    assert(cetta_durable_value_decode(&a,huge_expr,sizeof(huge_expr),&bad)==DURABLE_CORRUPT);
    arena_free(&a); symbol_table_free(&symbols); g_symbols=NULL;
    puts("durable values: bit-exact roundtrips, truncation, trailing data, unsafe values, depth and expansion limits passed");
}
