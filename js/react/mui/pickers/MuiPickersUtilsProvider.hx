package react.mui.pickers;

import react.ReactComponent;

typedef MuiPickersUtilsProviderProps = {
  utils: Dynamic,
  ?locale: Dynamic
};

@:jsRequire('@material-ui/pickers', 'MuiPickersUtilsProvider')
extern class MuiPickersUtilsProvider extends react.ReactComponentOfProps<MuiPickersUtilsProviderProps> {}
