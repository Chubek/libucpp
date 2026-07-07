%module ucpp

%{
#include "cpp.h"
%}

%ignore ucpp_ouch;
%ignore ucpp_error;
%ignore ucpp_warning;

%inline %{
typedef struct _IO_FILE FILE;
%}

%include "cpp.h"
