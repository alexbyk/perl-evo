static inline AV *sv2av(SV *self) {
  if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVAV))
    croak("Not an ARRAY ref");
  return (AV *)SvRV(self);
}

static inline SV *av_fetch_or_croak(AV *av, int i) {
  dTHX;
  SV **tmp = av_fetch(av, i, 0);
  if (!tmp) croak("Can't fetch %d", i);
  return *tmp;
}

static inline SV *hv_he_store_or_croak(HV *hv, SV *key, SV *val) {
  dTHX;
  HE *he = hv_fetch_ent(hv, key, TRUE, 0U);
  if (!he) {
    SvREFCNT_dec(val);
    croak("Can't store value");
  }
  SV *sv = HeVAL(he);
  SvSetMagicSV(sv, val);
  return sv;
}

static inline void hv_stores_or_croak(HV *hv, const char *key, SV *val) {
  dTHX;
  if (hv_store(hv, key, strlen(key), val, 0U)) return;
  SvREFCNT_dec(val);
  croak("Can't store value");
}

static inline ECAslot *sv2slot(SV *sv) {
  dTHX;
  return INT2PTR(ECAslot *, SvUV(sv));
}

static SV *psv_to_slotsv(SV *sv) {
  dTHX;
  ECAslot *slot = sv2slot(sv);
  HV *hv = newHV();

  // may be NULL
  hv_stores_or_croak(hv, "value",
                     newSVsv(slot->value ? slot->value : &PL_sv_undef));
  hv_stores_or_croak(hv, "check",
                     newSVsv(slot->check ? slot->check : &PL_sv_undef));
  hv_stores_or_croak(hv, "inject",
                     newSVsv(slot->inject ? slot->inject : &PL_sv_undef));

  hv_stores_or_croak(hv, "name", newSVsv(slot->key)); // always defined

  hv_stores_or_croak(hv, "ro", newSViv(slot->is_ro));
  hv_stores_or_croak(hv, "type", newSViv(slot->type));
  return newRV_noinc((SV *)hv);
}

// it's the fastest way to hanlde arguments as perls (my %hash = @_)
// point uniq to the element of args from which it will be uniq, return
// length of uniq array. Complex, need code review
int args_to_uniq(SV *args[], int len_args, SV ***uniq) {
  dTHX;
  if (len_args % 2) croak("Not even list");

  int end = len_args - 1;
  int offset = end;
  for (int i = end; i >= 0; i -= 2) {
    SV *curkey = args[i - 1];
    SV *curval = args[i];
    int j;
    for (j = end; j > offset; j -= 2)
      if (!strcmp(SvPV_nolen(args[j - 1]), SvPV_nolen(curkey))) break;

    // if j == offset, we've reached the end without a match +
    if (j == offset) {
      // if i!= j, replace value (because if i=j all array may be already
      // uniq and we don't need to overwrite anything)
      if (j != i) {
        args[offset - 1] = curkey;
        args[offset] = curval;
      };
      offset -= 2;
    }
  };

  offset++; // jump to next key index, because can be -1 here
  *uniq = &args[offset];
  return len_args - offset;
}

static inline void do_check(SV *cv, SV *value, SV *key) {
  dTHX;
  SV *ok = &PL_sv_undef, *msg = &PL_sv_undef;

  dSP;
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(sv_mortalcopy(value));
  PUTBACK;

  int count = call_sv(cv, G_ARRAY);
  // could return 0 or 1 or 2 or more
  SPAGAIN;

  if (count) count == 1 ? (ok = POPs) : (msg = POPs, ok = POPs);

  if (!SvTRUE(ok)) {
    croak("Bad value \"%s\" for attribute \"%s\": %s", SvPV_nolen(value),
          SvPV_nolen(key), SvTRUE(msg) ? SvPV_nolen(msg) : "");
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
};

// invoce cv, passing arg, store result of that invocation to hash, return an SV
// from HeVAL
static inline SV *invoke_and_store(SV *arg, SV *cv, HV *hash, SV *key) {
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(sv_mortalcopy(arg));
  PUTBACK;

  int count = call_sv(cv, G_SCALAR);
  if (count != 1) croak("bad count");
  SPAGAIN;
  SV *tmp = POPs;
  SV *result = hv_he_store_or_croak(hash, key, tmp);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}

// returns an SV from HeVAL
static inline SV *invoke_lazy(SV *self, SV *cv) {
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(sv_mortalcopy(self));
  PUTBACK;

  int count = call_sv(cv, G_SCALAR);
  if (count != 1) croak("bad count");
  SPAGAIN;
  SV *res = POPs;
  SV *result = newSVsv(res);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}
