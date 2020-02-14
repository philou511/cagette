package form;

import sugoi.form.elements.NativeDatePicker;
import sugoi.form.elements.NativeDatePicker.NativeDatePickerType;
// import react.ReactMacro.jsx;
// import react.ReactDOM;

class CagetteDatePicker extends NativeDatePicker {

  public var format: String = "EEEE d MMM yyyy";
  
  override public function render():String {
    var inputName = this.parentForm.name + "_" + this.name;
    var inputType = renderInputType();
    var pValue = value != null ? ('"' + value.toString() + '"') : null;
    return '
      <div id="$inputName" ></div>
      <script>
        document.addEventListener("DOMContentLoaded", function() {
          _.generateDatePicker("#$inputName", "$inputName", $pValue, "$inputType", $required);
        });
      </script>
    ';
  }

  override public function getTypedValue(str:String):Date {
    if(str=="") return null;

    var date = Date.now();
    var rDate = ~/([A-zÀ-ÿ]*) ([0-9]*) ([A-zÀ-ÿ]*) ([0-9]*)/;
    var rDatetime = ~/([A-zÀ-ÿ]*) ([0-9]*) ([A-zÀ-ÿ]*) ([0-9]*) à ([0-9]*)h([0-9]*)/;
    var rTime = ~/([0-9]*)h([0-9])*/;

    switch (type) {
      case NativeDatePickerType.time:
        if (rTime.match(str)) {
          date = new Date(
            0, 0, 0,
            Std.parseInt(rTime.matched(1)),
            Std.parseInt(rTime.matched(2)),
            0
          );
        }
      case NativeDatePickerType.datetime:
          if (rDatetime.match(str)) {
            date = new Date(
              Std.parseInt(rDatetime.matched(4)),
              Formatting.MONTHS_LOWERCASE.indexOf(rDatetime.matched(3)),
              Std.parseInt(rDatetime.matched(2)),
              Std.parseInt(rDatetime.matched(5)),
              Std.parseInt(rDatetime.matched(6)),
              0
            );
          }
      default:
        if (rDate.match(str)) {
          date = new Date(
            Std.parseInt(rDate.matched(4)),
            Formatting.MONTHS_LOWERCASE.indexOf(rDate.matched(3)),
            Std.parseInt(rDate.matched(2)),
            0, 0, 0
          );
        }
    }

    return date;
  }
}