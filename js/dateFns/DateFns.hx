package dateFns;

@:jsRequire('date-fns')
extern class DateFns {
  static public function format(date: Date, format: String, ?options: Dynamic): String;
}