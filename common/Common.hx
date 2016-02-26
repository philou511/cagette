/**
 * Shared entities between server and client
 */


//utilisé dans le shop
@:keep
typedef Order = {
	
	products:Array<{productId:Int,quantity:Float}>
}

@:keep
typedef ProductInfo = {
	id : Int,
	name : String,
	type : ProductType,
	image : Null<String>,
	contractId : Int,
	price : Float,
	vat : Float,
	vatValue : Float,			//montant de la TVA inclue dans le prix
	contractTax : Float, 		//pourcentage de commission défini dans le contrat
	contractTaxName : String,	//label pour la commission : ex: "frais divers"
	desc : String,
	categories : Array<Int>,	//tags
	orderable : Bool,			//can be currently ordered
	stock: Null<Float>,			//available stock
	hasFloatQt : Bool
}

@:keep
enum ProductType {
	CTVegetable;
	CTCheese;
	CTChicken;
	CTUnknown;
	CTWine;
	CTMeat;
	CTEggs;
	CTHoney;
	CTFish;
	CTJuice;
	CTApple;
	CTBread;
	CTYahourt;
	
}

/**
 * datas used with the "tagger" ajax class
 */
@:keep
typedef TaggerInfos = {
	products:Array<{product:ProductInfo,categories:Array<Int>}>,
	categories : Array<{id:Int,categoryGroupName:String,color:String,tags:Array<{id:Int,name:String}>}>, //groupe de categories + tags
}

/**
 * Links in navbars for plugin
 */
typedef Link = {
	var link:String;
	var name:String;
}

typedef UserOrder = {
	id:Int,
	userId:Int,
	userName:String,
	
	productId:Int,
	productRef:String,
	productName:String,
	productPrice:Float,
	productImage:String,
	
	quantity:Float,
	subTotal:Float,
	fees:Float,
	percentageName:String,
	percentageValue:Float,
	total:Float,
	paid:Bool,
	canModify:Bool,
	
	contractId:Int,
	contractName:String,
}

/**
	Event enum used for plugins
**/
	
enum Event {

	Page(uri:String);			//a page is displayed
	Nav(nav:Array<Link>,name:String);		//a navigation is displayed
	
	
	#if sys
	SendEmail(message : ufront.mail.Email);		//an email is sent
	#end
	
}


enum TutoAction {
	TAPage(uri:String);
	TANext;
	
}

class Data {

	/**
	 * shared datas for tutorials
	 */
	public static var TUTOS = [
		"intro" => { 
			name:"Visite guidée coordinateur",
			steps:[
				{
					element:null,
					text:"<p>Afin de mieux découvrir Cagette.net, nous vous proposons de faire une visite guidée de l'interface du logiciel.
					<br/> Vous aurez ainsi une vue d'ensemble sur les différents outils qui sont à votre disposition.</p>
					<p>Vous pourrez stopper et reprendre ce tutoriel quand vous le souhaitez.</p>",
					action: TANext
				},
				{
					element:"ul.nav.navbar-left",
					text:"Cette partie de la barre de navigation est visible par tout les adhérents.</br>
					Elle permet d'accéder aux trois rubriques principales :
					<ul>
						<li> La page d'accueil qui permet d'accéder aux commandes et de voir son planning de livraison.</li>
						<li> La page <b>Mon compte</b> pour mettre à jour mes coordonnées et consulter mon historique de commande</li>
						<li> La page <b>Mon groupe</b> pour connaître les différents produits et producteurs de mon groupe
					</ul>",
					action: TANext
					
				},
				{element:"ul.nav.navbar-right", 	text:"Tandis que celle-ci est réservée aux coordinateurs",		action: TAPage("/contractAdmin")},
				{element:"ul.nav #contractadmin", 	text:"Salut c'est l'étape 3",		action: TAPage("/contractAdmin")},
				{element:"ul.nav #contractadmin", 	text:"Salut c'est l'étape 4",		action: TAPage("/contractAdmin")}
			]
		},
		//"AMAP" => [],
		//"BG" => [],
	
	];
}
