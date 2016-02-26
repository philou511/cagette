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
enum TutoPlacement {
	TPTop;
	TPBottom;
	TPLeft;
	TPRight;
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
					action: TANext,
					placement : null
				},
				{
					element:"ul.nav.navbar-left",
					text:"Cette partie de la barre de navigation est visible par tout les adhérents.</br>
					Elle permet d'accéder aux trois rubriques principales :
					<ul>
						<li> La <b>page d'accueil</b> qui permet d'accéder aux commandes et de voir son planning de livraison.</li>
						<li> La page <b>Mon compte</b> pour mettre à jour mes coordonnées et consulter mon historique de commande</li>
						<li> La page <b>Mon groupe</b> pour connaître les différents produits, producteurs et coordinateurs de mon groupe
					</ul>",
					action: TANext,
					placement : TPBottom
					
				},
				{
					element:"ul.nav.navbar-right",
					text:"Cette partie est exclusivement réservée <b>aux coordinateurs.</b>
					C'est là que vous allez pouvoir administrer les fiches d'adhérents, les commandes ...etc<br/>
					<p>Cliquez maintenant sur <b>Gestion contrats</b></p>
					",
					action: TAPage("/contractAdmin"),
					placement : TPBottom
					
				},
				{
					element:"#contracts",
					text:"Ici se trouve la liste des <b>contrats</b>. 
					Ils comportent une date de début et date de fin et représentent votre relation avec un producteur. <br/>
					<p>
					C'est ici que vous pourrez gérer :
						<ul>
						<li>la liste de produits de ce producteur</li>
						<li>les commandes des adhérents pour ce producteur</li>
						<li>planifier les livraisons</li>
						</ul>
					</p>",
					action: TANext,
					placement : TPBottom
					
				},
				{
					element:"#vendors",
					text:"Ici vous pouvez gérer la liste des <b>producteurs ou fournisseurs</b> avec lesquels vous collaborez.<br/>
					Remplissez une fiche complète pour chacun d'eux afin d'informer au mieux les adhérents",
					action: TANext,
					placement : TPTop
					
				},
				{
					element:"#places",
					text:"Ici vous pouvez gérer la liste des <b>lieux de livraison/distribution</b>.<br/>
					N'oubliez pas de mettre l'adresse complète car une carte s'affiche à partir de l'adresse du lieu.",
					action: TANext,
					placement : TPTop
					
				},
				{
					element:"ul.nav #messages",
					text:"Explorons maintenant la messagerie.",
					action: TAPage("/messages"),
					placement : TPBottom
					
				},
				{
					element:null,
					text:"<p>La messagerie vous permet d'envoyer des emails à différentes listes d'adhérents.
					Il n'est plus nécéssaire de maintenir de nombreuses listes d'emails en fonction des contrats, toutes ces listes
					sont gérées automatiquement.</p>
					<p>Les emails sont envoyés avec votre adresse email en tant qu'expéditeur, vous recevrez donc les réponses sur votre boite email habituelle.</p<
					",
					action: TANext,
					placement : null
					
				},{
					element:"ul.nav #amapadmin",
					text:"Cliquez maintenant sur cette rubrique",
					action : TAPage("/amapadmin"),
					placement : TPBottom,
				}
			]
		},
	
	
	];
}
