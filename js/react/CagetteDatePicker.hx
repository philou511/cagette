package react;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.mui.pickers.MuiPickersUtilsProvider;
import react.mui.pickers.DatePicker;
import react.mui.pickers.TimePicker;
import react.mui.pickers.DateTimePicker;
import dateIO.DateFnsUtils;
import dateFns.DateFnsLocale;
import dateFns.DateFns;

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

class CagetteDatePicker extends react.ReactComponentOfPropsAndState<{name: String, value: Date, type: String},{date:Date}> {

	public function new(props:Dynamic) {
    super(props);
    state = {
      date: props.value
    };
	}
	
	override public function render() {
    return jsx('
      <MuiPickersUtilsProvider utils=$FrLocalizedUtils locale=${DateFnsLocale.fr}>
        ${
          switch (props.type) {
            case "time": jsx('<TimePicker name=${props.name} ampm={false} value=${state.date} onChange=$onChange />');
            case "datetime-local": jsx('<DateTimePicker name=${props.name} format="dd/MM/yyyy hh:mm" ampm={false} cancelLabel="Annuler" value=${state.date} onChange=$onChange />');
            default: jsx('<DatePicker name=${props.name} format="dd/MM/yyyy" cancelLabel="Annuler" value=${state.date} onChange=$onChange />');
          }
        }
      </MuiPickersUtilsProvider>
    ');
  }
  
  private function onChange(date: Date) {
    this.setState({ date: date });
  }
}