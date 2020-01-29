package dateIO;

@:jsRequire('@date-io/date-fns')
extern class DateFnsUtils {
  public var locale: Dynamic; // TODO

  public function new(props: Dynamic); // TODO

  public function getDatePickerHeaderText(date: Date): String;
  public function getCalendarHeaderText(date: Date): String;
}