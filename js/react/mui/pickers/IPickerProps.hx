package react.mui.pickers;

typedef IPickerProps = {
  value: Date,
  onChange: (date: Date) -> Void,
  ?name: String,
  ?format: String,
  ?InputProps: Dynamic,
  ?DialogProps: Dynamic,
  ?fullWidth: Bool,
  ?cancelLabel: String,
  ?clearable: Bool,
  ?required: Bool,
  ?clearLabel: String,
};