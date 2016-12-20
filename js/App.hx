import js.JQuery;
import react.ReactMacro.jsx;
import react.ReactDOM;
import react.ProductInput;

class App {
	
	function new() { }	

	/**
	 * Returns a jquery object like $() in javascript
	 */
	public static inline function j(r:Dynamic) {
		return new JQuery(r);
	}

	/**
	 * The JS App will be available as "_" in the document.
	 */
	public static function main() {		
		untyped js.Browser.window._ = new App();
	}
	
	public function getCart() {
		return new Cart();
	}
	
	public function getTagger(cid:Int ) {
		return new Tagger(cid);
	}
	
	public function getTuto(name:String, step:Int) {	
		return new Tuto(name,step);		
	}
	
	public function getProductComposer(){
		//js.Browser.document.addEventListener("DOMContentLoaded", function(event) {
			//ReactDOM.render(jsx('<$ComposerApp/>'), js.Browser.document.getElementById("app"));	
		//});
	}
	
	public function getProductInput(divId:String, productName:String, txpProductId:Int, formName:String ){
		
		js.Browser.document.addEventListener("DOMContentLoaded", function(event) {
			
			//dirty stuff to remove "real" input, and replace it by the react one
			App.j("form input[name='"+formName+"_name']").parent().parent().remove();
			App.j("form select[name='"+formName+"_txpProductId']").parent().parent().remove();
			
			ReactDOM.render(jsx('<$ProductInput productName="$productName" txpProductId="$txpProductId" formName="$formName"/>'),  js.Browser.document.getElementById(divId));	
		});
	}
	
	public static function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}

	
	/**
	 * Ajax loads a page and display it in a modal window
	 * @param	url
	 * @param	title
	 */
	public function overlay(url:String,?title,?large=true) {
	
		
		var r = new haxe.Http(url);
		r.onData = function(data) {
			
			//setup body and title
			var m = App.j("#myModal");
			m.find(".modal-body").html(data);			
			if (title != null) m.find(".modal-title").html(title);
			
			if (!large) m.find(".modal-dialog").removeClass("modal-lg");
			
			
			untyped App.j('#myModal').modal(); //bootstrap 3 modal window
			
		}
		r.request();
	}
	
	/**
	 * Helper to get values of a bunch of checked checkboxes
	 * @param	formSelector
	 */
	public function getCheckboxesId(formSelector:String):Array<String>{
		var out = [];
		var checkboxes = js.Browser.document.querySelectorAll(formSelector + " input[type=checkbox]");
		for ( input in checkboxes ){
			var input : js.html.InputElement = cast input;
			if ( input.checked ) out.push(input.value);
		}
		return out;
	}

	
	#if plugins
	public function getHostedPlugin(){
		return new hosted.js.App();
	}	
	#end
	
	
}
