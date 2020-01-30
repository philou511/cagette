package react.formikMUI;

import react.ReactComponent;

typedef DatePickerProps = {
    name: String,
    ?label: String,
    ?fullWidth: Bool,
    ?required: Bool,
    ?format: String,
    ?InputProps: Dynamic,
};

@:jsRequire('formik-material-ui-pickers', 'DatePicker')
extern class DatePicker extends react.ReactComponentOfProps<DatePickerProps> {}