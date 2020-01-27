package react.mui.pickers;

import react.ReactComponent;

typedef TimePickerProps = {
  value: Date,
  onChange: (date: Date) -> Void,
  ?format: String,
  ?cancelLabel: String,
  ?ampm: Bool,
  ?name: String,
  ?fullWidth: Bool,
  ?InputProps: Dynamic,
};

@:jsRequire('@material-ui/pickers', 'TimePicker')
extern class TimePicker extends react.ReactComponentOfProps<TimePickerProps> {}

