#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef DEBUGGING
#undef assert
#define assert(expr)                                                           \
  ((expr) ? (void)0 : croak("XS Assertion: %s failed (%s:%d)", #expr,          \
                            __FILE__, __LINE__))
#endif


#include "eca.h"
#include "helpers.c"
#include "eca.c"
#include "xs.c"

MODULE = Evo::Class::Attrs::XS				PACKAGE = Evo::Class::Attrs::XS

PROTOTYPES: DISABLE

SV * _reg_attr(self, name, type, value, check, is_ro, inject)
  SV *self;
  char *name;
  int type;
  SV *value;
  SV *check;
  bool is_ro;
  SV *inject;
CODE: 
  SV *slot_sv = eca_new_sv(name, type, value, check, is_ro, inject);
  _reg_attr(self, slot_sv);
  RETVAL = newRV(slot_sv);
OUTPUT:
  RETVAL

SV *_gen_attr(self, slot_ref)
  SV *self;
  SV *slot_ref;
CODE: 
  if(!SvROK(slot_ref)) croak("Not a ref");

  PERL_UNUSED_VAR(self);
  SV *slot_sv = SvRV(slot_ref);
  CV *xsub = newXS(NULL, (XSUBADDR_t)xs_attr, __FILE__);
  sv_magicext((SV *)xsub, slot_sv, PERL_MAGIC_ext, &ATTRS_TBL, NULL, 0);
#ifndef MULTIPLICITY
  CvXSUBANY(xsub).any_ptr = sv2slot(slot_sv);
#endif
  RETVAL = newRV_noinc((SV *)xsub);
OUTPUT:
  RETVAL

SV *gen_new(self)
  SV *self;
CODE: 
  AV *av = sv2av(self);
  CV *xsub = newXS(NULL, (XSUBADDR_t)xs_new, __FILE__);
  sv_magicext((SV *)xsub, (SV *)av, PERL_MAGIC_ext, &ATTRS_TBL, NULL, 0);
#ifndef MULTIPLICITY
  CvXSUBANY(xsub).any_ptr = av;
#endif
  RETVAL = newRV_noinc((SV *)xsub);
OUTPUT:
  RETVAL

void slots(self)
  SV *self;
PPCODE:
  AV *av = sv2av(self);
  int i, last = av_top_index(av), size = last + 1;

  for (i = 0; i < size; i++) {
    SV **tmp = av_fetch(av, i, 0);
    if (!tmp) croak("Broken attr %d", i);
    mXPUSHs(psv_to_slotsv(*tmp));
  }

bool exists(self, name)
  SV *self;
  SV *name;
CODE:
  RETVAL = attrs_exists(self, name);
OUTPUT:
  RETVAL
