package form;

import sugoi.form.Form;
import sugoi.form.elements.NativeDatePicker.NativeDatePickerType;

class CagetteForm extends Form {

  override public static function fromSpod(obj:sys.db.Object) {
    var fieldTypeToElementMap = new Map<String, (name: String, label: String, value: Dynamic, ?required: Bool) -> Dynamic>();
    fieldTypeToElementMap["DDate"] = CagetteForm.renderDDate;
    fieldTypeToElementMap["DTimeStamp"] = CagetteForm.renderDTimeStamp;
    fieldTypeToElementMap["DDateTime"] = CagetteForm.renderDTimeStamp;

    return sugoi.form.Form.fromSpod(obj, fieldTypeToElementMap);
  }


  private static function renderDDate(name: String, label: String, value: Dynamic, ?required: Bool) {
    return new form.CagetteDatePicker(name, label, value, NativeDatePickerType.date, required);
  }

  private static function renderDTimeStamp(name: String, label: String, value: Dynamic, ?required: Bool) {
    return new form.CagetteDatePicker(name, label, value, NativeDatePickerType.datetime, required);
  }
}