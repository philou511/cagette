package form;

import sugoi.form.elements.NativeDatePicker;
import sugoi.form.elements.NativeDatePicker.NativeDatePickerType;
// import react.ReactMacro.jsx;
// import react.ReactDOM;

class CagetteDatePicker extends NativeDatePicker {

  public var format: String = "d MMM yyyy";

  override public function render():String {
    var inputName = this.parentForm.name + "_" + this.name;
    var inputType = renderInputType();
    return '
      <div id=$inputName />
      <script>
        document.addEventListener("DOMContentLoaded", function() {
          _.generateDatePicker("#$inputName", "$inputName", "$value", "$inputType");
        });
      </script>
    ';
  }

  override public function populate() {
    var n = parentForm.name + "_" + name;
    var v = App.current.params.get(n);

    switch (type) {
      case NativeDatePickerType.time:
        var parts = v.split(":");
        var now = Date.now();
        value = new Date(now.getFullYear(), now.getMonth(), now.getDay(), Std.parseInt(parts[0]), Std.parseInt(parts[1]), 0);
      case NativeDatePickerType.datetime:
        var parts = v.split(" ");
        var dateParts = parts[0].split("/");
        var timeParts = parts[1].split(":");
        value = new Date(Std.parseInt(dateParts[2]), Std.parseInt(dateParts[1]) - 1, Std.parseInt(dateParts[0]), Std.parseInt(timeParts[0]), Std.parseInt(timeParts[1]), 0);
      default: 
        var parts = v.split("/");
        value = new Date(Std.parseInt(parts[2]), Std.parseInt(parts[1]) - 1, Std.parseInt(parts[0]), 0, 0, 0);
    }
  }
}