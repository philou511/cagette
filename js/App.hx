//React lib
import react.ReactMacro.jsx;
import react.ReactDOM;
import react.*;
import react.router.*;
//redux

import redux.Redux;
import redux.Store;
import redux.StoreBuilder.*;
import redux.thunk.Thunk;
import redux.thunk.ThunkMiddleware;
import redux.react.Provider as ReduxProvider;

//custom components
import react.order.*;
import react.product.*;
import react.store.CagetteStore;
import react.map.*;
import react.user.*;

//TODO
import react.store.Cart;

import mui.core.CssBaseline;
import mui.core.styles.MuiThemeProvider;


//require bootstrap JS since it's bundled with browserify
//@:jsRequire('bootstrap') extern class Bootstrap{}
//@:jsRequire('jquery') extern class JQ extends js.jquery.JQuery{}

class App {

	public static var instance : App;
	public var LANG : String;
	public var currency : String; //currency symbol like &euro; or $
	public var t : sugoi.i18n.GetText;//gettext translator

	//i dont want to use redux now... saved state from react.OrderBox
	public static var SAVED_ORDER_STATE : Dynamic;

	function new(?lang="fr",?currency="&euro;") {
		//singleton
		instance = this;
		if(lang!=null) this.LANG = lang;
		this.currency = currency;
	}

	/**
	 * Returns a jquery object like $() in javascript
	 * @deprecated
	 */
	public static inline function j(r:Dynamic):js.JQuery {
		return new js.JQuery(r);
	}

	public static inline function jq(r:Dynamic):js.jquery.JQuery{
		return new js.jquery.JQuery(r);
	}

	/**
	 * The JS App will be available as "_" in the document.
	 */
	public static function main() {
		
		//untyped js.Browser.window.$ = js.Lib.require("jQuery");
		untyped js.Browser.window._ = new App();
	}

	public function getCart() {
		return new ShopCart();
	}

	public function getTagger(cid:Int ) {
		return new Tagger(cid);
	}

	public function getTuto(name:String, step:Int) {
		new Tuto(name,step);
	}
	
	/**
	 * remove method for IE compat
	 */
	public function remove(el:js.html.Element){
		if (el == null) return;
		el.parentElement.removeChild(el);
	}
	
	public function getVATBox(ttcprice:Float,currency:String,rates:String,vat:Float,formName:String){
		
		var input = js.Browser.document.querySelector('form input[name="${formName}_price"]');
		
		remove( js.Browser.document.querySelector('form input[name="${formName}_vat"]').parentElement.parentElement );
		
		ReactDOM.render(jsx('<$VATBox ttc=${ttcprice} currency=${currency} vatRates=${rates} vat=${vat} formName=${formName} />'),  input.parentElement);
		
		//remove(input);
		
	}

	/*public function getProductComposer(){
		//js.Browser.document.addEventListener("DOMContentLoaded", function(event) {
			//ReactDOM.render(jsx('<$ComposerApp/>'), js.Browser.document.getElementById("app"));
		//});
	}*/

	/**
	 * Removes the form element and replace it by a react js component
	 * @param	divId
	 * @param	productName
	 * @param	txpProductId
	 * @param	formName
	 */
	public function getProductInput(divId:String, productName:String, txpProductId:Null<Int>, formName:String ){

		js.Browser.document.addEventListener("DOMContentLoaded", function(event) {

			//dirty stuff to remove "real" input, and replace it by the react one
			App.j("form input[name='"+formName+"_name']").parent().parent().remove();
			App.j("form select[name='" + formName+"_txpProductId']").parent().parent().remove();

			//if (txpProductId == null) txpProductId = null;

			ReactDOM.render(jsx('<$ProductInput productName=${productName} txpProductId=${txpProductId} formName=${formName}/>'),  js.Browser.document.getElementById(divId));
		});
	}

	public function initReportHeader(){
		ReactDOM.render(jsx('<$ReportHeader />'),  js.Browser.document.querySelector('div.reportHeaderContainer'));
	}
	
	public function initOrderBox(userId:Int, distributionId:Int, contractId:Int, contractType:Int, date:String, place:String, userName:String, currency:String, hasPayments:Bool,callbackUrl:String){

		untyped App.j("#myModal").modal();
		var onValidate = function() js.Browser.location.href = callbackUrl;
		var node = js.Browser.document.querySelector('#myModal .modal-body');
		ReactDOM.unmountComponentAtNode(node); //the previous modal DOM element is still there, so we need to destroy it
		ReactDOM.render(jsx('<$OrderBox userId=${userId} distributionId=${distributionId} 
			contractId=${contractId} contractType=${contractType} date=${date} place=${place} userName=${userName} 
			onValidate=$onValidate currency=$currency hasPayments=$hasPayments />'),node,postReact);

	}

	function postReact(){
		trace("post react");
		haxe.Timer.delay(function(){
			untyped jq('[data-toggle="tooltip"]').tooltip();
			untyped jq('[data-toggle="popover"]').popover();
		},500);
		
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
		if(title != null) title = StringTools.urlDecode(title);
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
	 * Displays a login box
	 */
	public function loginBox(redirectUrl:String,?message:String,?phoneRequired=false) {
		var m = App.j("#myModal");
		m.find(".modal-title").html("S'identifier");
		m.find(".modal-dialog").removeClass("modal-lg");
		untyped m.modal();
		ReactDOM.render(jsx('<$LoginBox redirectUrl=${redirectUrl} message=$message phoneRequired=${phoneRequired}/>'),  js.Browser.document.querySelector('#myModal .modal-body'));
		return false;
	}

	/**
	 *  Displays a sign up box
	 */
	public function registerBox(redirectUrl:String,?message:String,?phoneRequired=false) {
		var m = App.j("#myModal");
		m.find(".modal-title").html("S'inscrire");
		m.find(".modal-dialog").removeClass("modal-lg");
		untyped m.modal();
		ReactDOM.render(jsx('<$RegisterBox redirectUrl=$redirectUrl message=$message phoneRequired=$phoneRequired />'),  js.Browser.document.querySelector('#myModal .modal-body'));
		return false;
	}

	private function createReactStore() {
		// Store creation
		var rootReducer = Redux.combineReducers({
			cart: mapReducer(react.cagette.action.CartAction, new react.cagette.state.CartState.CartRdcr()),
		});
		// create middleware normally, excepted you must use
		// 'StoreBuilder.mapMiddleware' to wrap the Enum-based middleware
		var middleWare = Redux.applyMiddleware(mapMiddleware(Thunk, new ThunkMiddleware()));
		return createStore(rootReducer, null, middleWare);
	}

	public function shop(place:Int, date:String) {
		// Will be merged with default values from mui
		var theme = mui.core.styles.MuiTheme.createMuiTheme({
			palette: {
				primary: {main: "#a53fa1"},
				secondary: {main:"#84BD55"},
				error: {main:"#FF0000"},       
			},
			typography: {
				fontFamily:['Cabin', 'icons', '"Helvetica Neue"','Arial','sans-serif',],
				fontSize:16,          
			},
			overrides: {
				MuiButton: { // Name of the component ⚛️ / style sheet
					root: { // Name of the rule
						minHeight: 'initial',
						minWidth: 'initial',
					},
				},
			},
		});

		var store = createReactStore();
		ReactDOM.render(jsx('
			<$ReduxProvider store=${store}>
				<$MuiThemeProvider theme=${theme}>
					<>
						<$CssBaseline />
						<$CagetteStore date=$date place=$place />
					</>
				</$MuiThemeProvider>
			</$ReduxProvider>
		'), js.Browser.document.querySelector('#shop'));
	}

	
	public function groupMap(lat:Float,lng:Float,address:String) {
		ReactDOM.render(jsx('<$GroupMapRoot lat=$lat lng=$lng address=$address />'),  js.Browser.document.querySelector('#map'));
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

	/**
	 * set up a warning message when leaving the page
	 */
	public function setWarningOnUnload(active:Bool, ?msg:String){
		if (active){
			js.Browser.window.addEventListener("beforeunload", warn);
		}else{
			js.Browser.window.removeEventListener("beforeunload", warn);
		}

	}

	function warn(e:js.html.Event) {
		var msg = "Voulez vous vraiment quitter cette page ?";
		//js.Browser.window.confirm(msg);
		untyped e.returnValue = msg; //Gecko + IE
		e.preventDefault();
		return msg; //Gecko + Webkit, Safari, Chrome etc.
	}

	/**
	 * Anti Doubleclick with btn elements.
	 * Can be bypassed by adding a .btn-noAntiDoubleClick class
	 */
	public function antiDoubleClick(){

		for( n in js.Browser.document.querySelectorAll(".btn:not(.btn-noAntiDoubleClick)") ){
			n.addEventListener("click",function(e:js.html.MouseEvent){
				var x = untyped e.target;
				x.classList.add("disabled");
				haxe.Timer.delay(function(){
					x.classList.remove("disabled");
				},1000);
			});
		}
		
	}
}


