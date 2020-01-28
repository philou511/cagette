package react;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.mui.pickers.MuiPickersUtilsProvider;
import react.mui.pickers.DatePicker;
import react.mui.pickers.TimePicker;
import react.mui.pickers.DateTimePicker;
import react.mui.MUIStyles;
import dateIO.DateFnsUtils;
import dateFns.DateFnsLocale;
import dateFns.DateFns;

typedef CagetteDatePickerProps = {
  name: String,
  type: String,
  ?value: Date,
  ?required: Bool,
};

class FrLocalizedUtils extends DateFnsUtils {

  public function new(props: Dynamic) {
    super(props);
  }

  override public function getDatePickerHeaderText(date: Date) {
    return DateFns.format(date, "d MMM yyyy", { locale: this.locale });
  }

  override public function getCalendarHeaderText(date: Date) {
    return DateFns.format(date, "d MMM yyyy", { locale: this.locale });
  }
}

class _CagetteDatePicker extends react.ReactComponentOfPropsAndState<CagetteDatePickerProps & {classes: Dynamic},{?date:Date}> {

	public function new(props:Dynamic) {
    super(props);
    state = {
      date: props.value
    };
	}
	
	override public function render() {
    var dateFormat = "EEEE d MMMM yyyy";
    var timeFormat = "HH'h'mm";
    var datetimeFormat = dateFormat + " à " + timeFormat;
    var required = props.required == null ? false : props.required;
    var clearable = !required;
    return jsx('
      <MuiPickersUtilsProvider utils=$FrLocalizedUtils locale=${DateFnsLocale.fr}>
        ${
          switch (props.type) {
            case "time": jsx('
              <TimePicker
                InputProps={{
                  classes: {
                    input: ${props.classes.picker}
                  }
                }}
                fullWidth
                format=$timeFormat
                ampm={false}
                clearable=$clearable
                clearLabel="Effacer"
                cancelLabel="Annuler"
                name=${props.name}
                value=${state.date}
                onChange=$onChange  
                />
            ');
            case "datetime-local": jsx('
              <DateTimePicker
                InputProps={{
                  classes: {
                    input: ${props.classes.picker}
                  }
                }}
                fullWidth
                format=$datetimeFormat
                name=${props.name}
                ampm={false}
                clearable=$clearable
                clearLabel="Effacer"
                cancelLabel="Annuler"
                value=${state.date}
                onChange=$onChange />
              ');
            default: jsx('
              <DatePicker
                InputProps={{
                  classes: {
                    input: ${props.classes.picker}
                  }
                }}
                fullWidth
                format=$dateFormat
                name=${props.name}
                required=$required
                clearable=$clearable
                clearLabel="Effacer"
                cancelLabel="Annuler"
                value=${state.date}
                onChange=$onChange
              />
            ');
          }
        }
      </MuiPickersUtilsProvider>
    ');
  }
  
  private function onChange(date: Date) {
    this.setState({ date: date });
  }
}


class CagetteDatePicker extends react.ReactComponentOfProps<CagetteDatePickerProps> {
  override public function render() {

    var Component = MUIStyles.withStyles({
      picker: {
        textTransform: "capitalize"
      }
    })(_CagetteDatePicker);

    return jsx('<Component name=${props.name} value=${props.value} type=${props.type} required=${props.required} />');
  }
}