package form;

import sugoi.form.Form;

class CagetteForm extends Form {

  override public static function fromSpod(obj:sys.db.Object) {

    var fieldTypeToElementMap = new Map<String, (String, String, Dynamic) -> Dynamic>();
    fieldTypeToElementMap["DDate"] = CagetteForm.renderDDate;
    fieldTypeToElementMap["DTimeStamp"] = CagetteForm.renderDTimeStamp;
    fieldTypeToElementMap["DDateTime"] = CagetteForm.renderDTimeStamp;

    return sugoi.form.Form.fromSpod(obj, fieldTypeToElementMap);
  }


  private static function renderDDate(name: String, label: String, value: Dynamic) {
    return new form.CagetteDatePicker(name, label, value);
  }

  private static function renderDTimeStamp(name: String, label: String, value: Dynamic) {
    return new form.CagetteDatePicker(name, label, value, sugoi.form.elements.NativeDatePicker.NativeDatePickerType.datetime);
  }
}