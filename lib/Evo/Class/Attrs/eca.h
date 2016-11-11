typedef enum {
  ECA_OPTIONAL,
  ECA_DEFAULT,
  ECA_DEFAULT_CODE,
  ECA_REQUIRED,
  ECA_LAZY
} ECAtype;

typedef struct {
  ECAtype type;
  bool is_ro;
  SV *check;
  SV *value;
  SV *inject;
  SV *key;
} ECAslot;
