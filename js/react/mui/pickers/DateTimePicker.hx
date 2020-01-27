package react.mui.pickers;

import react.ReactComponent;

typedef DateTimePickerProps = {
  value: Date,
  onChange: (date: Date) -> Void,
  ?name: String,
  ?format: String,
  ?cancelLabel: String,
  ?ampm: Bool,
  ?fullWidth: Bool,
  ?InputProps: Dynamic,
};

@:jsRequire('@material-ui/pickers', 'DateTimePicker')
extern class DateTimePicker extends react.ReactComponentOfProps<DateTimePickerProps> {}

