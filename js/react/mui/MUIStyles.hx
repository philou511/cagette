package react.mui;


@:jsRequire('@material-ui/core/styles')
extern class MUIStyles {
  static public function makeStyles(style: Dynamic): Dynamic;
  static public function createStyles(style: Dynamic): Dynamic;
  static public function withStyles(style: Dynamic): (component: Dynamic) -> Dynamic;
}