package react.formik;

import react.ReactComponent;
import react.ReactNode;

typedef FieldProps = {
    name: String,
    ?as: Dynamic,
    ?children: ReactNode,
};

@:jsRequire('formik', 'Field')
extern class Field extends react.ReactComponentOfProps<FieldProps> {}