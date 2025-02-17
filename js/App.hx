import bootstrap.Modal;
import js.Browser;
import Common;
// import thx.semver.Version;

//React lib
import react.ReactMacro.jsx;
import react.ReactDOM;
import react.*;

//mui
import react.mui.CagetteTheme;
import mui.core.CssBaseline;
import mui.core.styles.MuiThemeProvider;

//redux
import redux.Redux;
import redux.Store;
import redux.StoreBuilder.*;
import redux.thunk.Thunk;
import redux.thunk.ThunkMiddleware;
import redux.react.Provider as ReduxProvider;

//custom components
import react.order.OrdersDialog;
import react.product.*;
import react.map.*;
import react.user.*;
import react.vendor.*;
import react.ReactComponent;


class App {

    public static var instance : App;    
    // public static var VERSION = ([0,14]  : Version).withPre(GitMacros.getGitShortSHA(), GitMacros.getGitCommitDate());
    	
	public var currency : String; //currency symbol like &euro; or $
	public var t : sugoi.i18n.GetText;//gettext translator
	public var Modal = bootstrap.Modal;
    public var lang : String;
    public var userId : Int;
    public var userName : String;
    public var userEmail : String;
    

	function new(?lang="fr",?currency="&euro;") {
		//singleton
		instance = this;
		if(lang!=null) this.lang = lang;
		this.currency = currency;
	}

	/**
	**/
	/*public static inline function jq(r:Dynamic):js.jquery.JQuery{
		trace("CALL JQUERY");
		return new js.jquery.JQuery(r);
	}*/

	/**
	 * The JS App will be available as "_" in the document.
	 */
	public static function main() {
        var app = new App();
        untyped js.Browser.window._ = app;
        untyped js.Browser.window._Cagette = app;//avoid conflicts with lodash
    }
    

	// public function getTuto(name:String, step:Int) {
    
	// 	new Tuto(name,step);
	// }
	
	/**
	 * remove method for IE compat
	 */
	public function remove(el:js.html.Element){
		if (el == null) return;
		el.parentElement.removeChild(el);
	}
	
	public function getVATBox(ttcprice:Float,currency:String,rates:String,vat:Float,formName:String){
        js.Browser.document.addEventListener("DOMContentLoaded", function(event) {
            
            var input = js.Browser.document.querySelector('form input[name="${formName}_price"]');
            remove( js.Browser.document.querySelector('form input[name="${formName}_vat"]').parentElement.parentElement );		
            
            input.parentElement.id = "vat-box-neo-container";

            var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
            neo.createNeoModule(input.parentElement.id, "vatBox", {
                initialTtc: ttcprice,
                currency: currency,
                vatRates: rates,
                initialVat: vat,
                formName: formName
            });
        });
    }

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
			remove(Browser.document.querySelector("form input[name='"+formName+"_name']").parentElement.parentElement);
			remove(Browser.document.querySelector("form select[name='" + formName+"_txpProductId']").parentElement.parentElement);

            var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
            neo.createNeoModule(divId, "productCategorizer", {
                originalProductName: productName,
                originalTxpProductId: txpProductId,
                formName: formName
            });
		});
	}

	public function getVendorPage(divId:String, vendorId:Int, ?catalogId:Int ) {
		js.Browser.document.addEventListener("DOMContentLoaded", function(event) {
            var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
            neo.createNeoModule(divId, "vendorPublicPage", {
                vendorId: vendorId,
                pCatalogId: catalogId
            });
		});
	}

	public function openImageUploader( imageUploaderContext : String, entityId: Int, width:Int, height:Int, ?imageType: String, ?currentCagetteProId: Int ) {
		var nodeId = "image-uploader-container";
        var node = js.Browser.document.getElementById(nodeId);
        if (node == null) {
            node = js.Browser.document.createDivElement();
            node.id = nodeId;
            js.Browser.document.body.appendChild(node);
        }

        var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
        neo.createNeoModule(node.id, "imageUploaderDialog", {
            context: imageUploaderContext,
            entityId: entityId,
            width: width,
            height: height,
            imageType: imageType,
            currentCagetteProId: currentCagetteProId
        });
	}
	
	public function initOrderBox(userId : Int, multiDistribId : Int, catalogId : Int, catalogType : Int, date : String, place : String, userName : String, currency : String, hasPayments : Bool, callbackUrl : String, hasCagette2 : Bool, groupId : Int) {
        var node = js.Browser.document.createDivElement();
        node.id = "ordersdialog-container";
        js.Browser.document.body.appendChild(node);
        ReactDOM.unmountComponentAtNode(node); //the previous modal DOM element is still there, so we need to destroy it
       
        if (!hasCagette2) { 
            var store = createOrderBoxReduxStore();
            ReactDOM.render(jsx('
                <ReduxProvider store=${store}>
                    <MuiThemeProvider theme=${CagetteTheme.get()}>
                        <>
                            <CssBaseline />
                            <OrdersDialog userId=$userId multiDistribId=$multiDistribId catalogId=$catalogId catalogType=$catalogType
                            date=$date place=$place userName=$userName callbackUrl=$callbackUrl currency=$currency hasPayments=$hasPayments />							
                        </>
                    </MuiThemeProvider>
                </ReduxProvider>
            '), node );
        } else {
            var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
            neo.createNeoModule(node.id, "ordersDialog", {
                userId: userId,
                multiDistribId: multiDistribId,
                catalogId: catalogId,
                groupId: groupId,
                date: date,
                place: place,
                userName: userName,
                callbackUrl: callbackUrl,
                currency: currency,
                hasPayments: hasPayments,
            });
        }
	}

	private function createOrderBoxReduxStore() {
        
		// Store creation
		var rootReducer = Redux.combineReducers({ reduxApp : mapReducer(react.order.redux.actions.OrderBoxAction, new react.order.redux.reducers.OrderBoxReducer()) });
		// create middleware normally, excepted you must use
		// 'StoreBuilder.mapMiddleware' to wrap the Enum-based middleware
		var middleWare = Redux.applyMiddleware(mapMiddleware(Thunk, new ThunkMiddleware()));
		return createStore( rootReducer, null, middleWare );
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

			var modalElement = Browser.document.getElementById("myModal");
			var modal = new Modal(modalElement);
			modalElement.querySelector(".modal-body").innerHTML = data;
			if (title != null) modalElement.querySelector(".modal-title").innerHTML = title;
			if (!large) modalElement.querySelector(".modal-dialog").classList.remove("modal-lg");
			modal.show();
		}
		r.request();
	}

    public function modal(divId:String) {		

			var modalElement = Browser.document.getElementById(divId);
			var modal = new Modal(modalElement);
			// modalElement.querySelector(".modal-body").innerHTML = data;
			// if (title != null) modalElement.querySelector(".modal-title").innerHTML = title;
			// if (!large) modalElement.querySelector(".modal-dialog").classList.remove("modal-lg");
			modal.show();
	}

	/**
	 * Displays a login box
	 */
	public function loginBox(redirectUrl:String,sid:String,?message:String,?phoneRequired=false,?addressRequired=false,?openRegistration=false,?invitedUserEmail:String, ?invitedGroupId:Int, ?asDialog:Bool) {	
        var node = js.Browser.document.createDivElement();
		node.id = "login-registration-container";
		js.Browser.document.body.appendChild(node);
		ReactDOM.unmountComponentAtNode(node); //the previous modal DOM element is still there, so we need to destroy it
        
        var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
        neo.createNeoModule(node.id, "loginRegistration", {
            redirectUrl: redirectUrl,
            sid: sid,
            message: message,
            phoneRequired: phoneRequired,
            addressRequired: addressRequired,
            openRegistration: openRegistration,
            invitedUserEmail: invitedUserEmail,
            invitedGroupId: invitedGroupId,
            asDialog: asDialog
        });
	}

	/**
	 *  Displays a sign up box
	 */
	public function registerBox(redirectUrl:String,sid:String,?message:String,?phoneRequired=false,?addressRequired=false, ?invitedUserEmail:String, ?invitedGroupId:Int) {
        loginBox(redirectUrl, sid, message, phoneRequired, addressRequired, true, invitedUserEmail, invitedGroupId);
	}

	public function membershipBox(userId:Int,userName:String,groupId:Int,?callbackUrl:String,?distributionId:Int){
		var node = js.Browser.document.createDivElement();
		node.id = "membershipBox-container";
		js.Browser.document.body.appendChild(node);
		ReactDOM.unmountComponentAtNode(node); //the previous modal DOM element is still there, so we need to destroy it
    
        var neo:Dynamic = Reflect.field(js.Browser.window, 'neo');
        neo.createNeoModule(node.id, "membershipDialog", {
            groupId: groupId,
            userId: userId,
            userName: userName,
            callbackUrl: callbackUrl,
            distributionId: distributionId
        });
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
	/*public function getHostedPlugin(){
		return new hosted.js.App();
	}*/
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
				},3000);
			});
		}
		
	}

	/**
		Anti doubleclick link function
	**/
	public static var linkClicked = false;
	public function goto(url:String){
		
		if(!linkClicked) {
			js.Browser.document.location.href=url;
			linkClicked = true;
		}else{
			js.Browser.console.log("double click detected");
		}
	}

	/**
		Display a notif about new features 3 times
	**/
	/*public function newFeature(selector:String,title:String,message:String,placement:String){
		var element = js.Browser.document.querySelector(selector);
		if(element==null) return;

		//do not show after 3 times
		var storage = js.Browser.getLocalStorage();
		if (storage.getItem("newFeature."+selector) == "3") return;

		//prepare Bootstrap "popover"
		var x = jq(element).first().attr("title",title);
		var text = "<p>" + message + "</p>";
		
		var options = { container:"body", content:text, html:true , placement:placement};
		untyped  x.popover(options).popover('show');
		//click anywhere to hide
		App.jq("html").click(function(_) {
			untyped x.popover('hide');				
		});
		

		var storage = js.Browser.getLocalStorage();
		var i = storage.getItem("newFeature."+selector);
		if(i==null) i = "0";
		storage.setItem("newFeature."+selector, Std.string( Std.parseInt(i)+1 ) );
		
		//highlight
		App.jq(element).first().addClass("highlight");	
	}*/

	public function toggle(selector:String){
		for ( el in js.Browser.document.querySelectorAll(selector)){
			untyped el.classList.toggle("hidden");
		}
	}

	public function show(selector:String){
		for ( el in js.Browser.document.querySelectorAll(selector)){
			untyped el.classList.remove("hidden");
		}
	}

	public function hide(selector:String){
		for ( el in js.Browser.document.querySelectorAll(selector)){
			untyped el.classList.add("hidden");
		}
	}

    // public function showTab(el){
    //     tab(el).show();
    // }

    // public  function modal(el){
    //     var m = new Modal(el);
    //     m.show();

    // }

    public function addTmpBasketIdToSession(tmpBasketId:Int) {
        var req = new haxe.Http("/shop/addTmpBasketId/"+tmpBasketId);
        req.request();
    }

    public function resetGroupInSession(groupId:Int) {
        var req = new haxe.Http("/account/quitGroup/"+groupId);
        req.request();
    }

}


