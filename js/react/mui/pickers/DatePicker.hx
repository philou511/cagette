package react.mui.pickers;

import react.ReactComponent;

typedef DatePickerProps = {
  value: Date,
  onChange: (date: Date) -> Void,
  ?format: String,
  ?cancelLabel: String,
  ?name: String
};

@:jsRequire('@material-ui/pickers', 'DatePicker')
extern class DatePicker extends react.ReactComponentOfProps<DatePickerProps> {}

