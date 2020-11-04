package bootstrap;

@:jsRequire('bootstrap.native', "Tab")  
extern class Tab {
  public function new (el: js.html.Element);
  public function show(): Void;
  public function hide(): Void;
}
