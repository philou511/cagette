package react;

import dateIO.DateFnsUtils;
import dateFns.DateFnsLocale;
import dateFns.DateFns;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.mui.CagetteTheme;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import react.mui.pickers.MuiPickersUtilsProvider;
import react.mui.pickers.DatePicker;
import react.mui.pickers.TimePicker;
import react.mui.pickers.DateTimePicker;
import classnames.ClassNames.fastNull as classNames;

typedef PublicProps = {
  name: String,
  type: String,
  ?value: String,
  ?required: Bool,
  ?openTo: String,
}

typedef TClasses = Classes<[input, dialog]>;

typedef CagetteDatePickerProps = {
  > PublicProps,
  var classes:TClasses;
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


@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class CagetteDatePicker extends react.ReactComponentOfPropsAndState<CagetteDatePickerProps,{?date:Date}> {

  public static function styles(theme:Theme):ClassesDef<TClasses> {
    return {
      input: {
        textTransform: css.TextTransform.Capitalize
      },
      dialog: {
        "& h3": {
          fontSize: "44px"
        }
      }
    }
  }

	public function new(props:Dynamic) {
        super(props);
        state = {};
        if (props.value) {
            state.date = Date.fromString(props.value);
        }
	}
	
	override public function render() {
    var dateFormat = "EEEE d MMMM yyyy";
    var timeFormat = "HH'h'mm";
    var datetimeFormat = dateFormat + " à " + timeFormat;
    var required = props.required == null ? false : props.required;
    var clearable = !required;
    var openTo = props.openTo == null ? "date" : props.openTo;
    return jsx('
      <MuiPickersUtilsProvider utils=$FrLocalizedUtils locale=${DateFnsLocale.fr}>
        ${
          switch (props.type) {
            case "time": jsx('
              <TimePicker
                InputProps={{
                  classes: {
                    input: ${props.classes.input}
                  }
                }}
                DialogProps={{
                  classes: {
                    dialogRoot: ${props.classes.dialog}
                  }
                }}
                fullWidth
                format=$timeFormat
                ampm={false}
                clearable=$clearable
                clearLabel="Effacer"
                cancelLabel="Annuler"
                invalidDateMessage="Format de date invalide"
                name=${props.name}
                value=${state.date}
                onChange=$onChange  
                />
            ');
            case "datetime-local": jsx('
              <DateTimePicker
                InputProps={{
                  classes: {
                    input: ${props.classes.input}
                  }
                }}
                DialogProps={{
                  classes: {
                    dialogRoot: ${props.classes.dialog}
                  }
                }}
                fullWidth
                format=$datetimeFormat
                name=${props.name}
                ampm={false}
                clearable=$clearable
                clearLabel="Effacer"
                cancelLabel="Annuler"
                invalidDateMessage="Format de date invalide"
                value=${state.date}
                onChange=$onChange />
              ');
            default: jsx('
              <DatePicker
                InputProps={{
                  classes: {
                    input: ${props.classes.input}
                  }
                }}
                DialogProps={{
                  classes: {
                    dialogRoot: ${props.classes.dialog}
                  }
                }}
                fullWidth
                format=$dateFormat
                name=${props.name}
                required=$required
                clearable=$clearable
                clearLabel="Effacer"
                cancelLabel="Annuler"
                openTo=${openTo}
                invalidDateMessage="Format de date invalide"
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
