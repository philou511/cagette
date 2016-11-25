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
	hasFloatQt : Bool,
	?qt:Float,
	?unitType:UnitType,
	organic:Bool,
	#if js
	element:js.JQuery,
	#end
}

enum UnitType{
	Piece;
	Kilogram;
	Gram;
	Litre;
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

typedef CategoryInfo = {
	id:Int,
	name:String,
	//pinned:Bool,
	//parent:Int,
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
 * Links in navbars for plugins
 */
typedef Link = {
	link:String,
	name:String,
	?icon:String,
}

typedef UserOrder = {
	id:Int,
	userId:Int,
	userName:String,
	
	?userId2:Int,
	?userName2:String,
	
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

enum OrderFlags {
	InvertSharedOrder;
	//Paid;
}

/**
	Event enum used for plugins.
	
	As in most CMS event systems, 
	the events (or "triggers") can be catched by plugins 
	to perform an action or modifiy data carried by the event.
	
**/
	
enum Event {

	Page(uri:String);							//a page is displayed
	Nav(nav:Array<Link>,name:String,?id:Int);	//a navigation is displayed, optionnal object id if needed
	
	#if sys
	SendEmail(message : ufront.mail.Email);		//an email is sent
	NewMember(user:db.User,group:db.Amap);		//a new member is added to a group
	NewGroup(group:db.Amap, author:db.User);	//a new group is created
	
	//Distributions
	PreNewDistrib(contract:db.Contract);		//when displaying the insert distribution form
	NewDistrib(distrib:db.Distribution);		//when a new distrinbution is created
	PreEditDistrib(distrib:db.Distribution);
	EditDistrib(distrib:db.Distribution);
	DeleteDistrib(distrib:db.Distribution);
	PreNewDistribCycle(cycle:db.DistributionCycle);	
	NewDistribCycle(cycle:db.DistributionCycle);
	
	//Products
	PreNewProduct(contract:db.Contract);	//when displaying the insert distribution form
	NewProduct(product:db.Product);			//when a new distrinbution is created
	PreEditProduct(product:db.Product);
	EditProduct(product:db.Product);
	DeleteProduct(product:db.Product);
	BatchEnableProducts(productIds:Array<Int>, enable:Bool);
	
	//Contracts
	DeleteContract(contract:db.Contract);
	
	//crons
	DailyCron;
	HourlyCron;
	MinutelyCron;
	
	#end
	
}


/*
 * Product Taxonomy structure
 */ 
typedef TxpDictionnary = {
	products:Map<Int,{id:Int,name:String,category:Int,subCategory:Int}>,
	categories:Map<Int,{id:Int,name:String}>,
	subCategories:Map<Int,{id:Int,name:String}>,
	
}


/* 
 * Tutorials
 */
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
					text:"Cette partie de la barre de navigation est visible par tous les adhérents.</br>
					Elle permet d'accéder aux trois rubriques principales :
					<ul>
						<li> La <b>page d'accueil</b> qui permet d'accéder aux commandes et de voir son planning de distribution.</li>
						<li> La page <b>Mon compte</b> pour mettre à jour mes coordonnées et consulter mon historique de commande</li>
						<li> La page <b>Mon groupe</b> pour connaître les différents producteurs et coordinateurs de mon groupe
					</ul>",
					action: TANext,
					placement : TPBottom
					
				},
				{
					element:"ul.nav.navbar-right",
					text:"Cette partie est exclusivement réservée <b>aux coordinateurs.</b>
					C'est là que vous allez pouvoir administrer les fiches d'adhérents, les commandes, les produits, etc.<br/>
					<p>Cliquez maintenant sur <b>Gestion adhérents</b></p>
					",
					action: TAPage("/member"),
					placement : TPBottom
					
				},{
					element:".article .table td:first",
					text:"Cette rubrique permet d'administrer la liste des adhérents.<br/>
					À chaque fois que vous saisissez un nouvel adhérent, un compte est créé à son nom. 
					Il pourra donc se connecter à Cagette.net pour faire des commandes ou consulter son planning de distribution.
					<p>Cliquez maintenant sur <b>un adhérent</b></p>",
					action: TAPage("/member/view/*"),
					placement : TPRight
				},{
					element:".article:first",
					text:"Nous sommes maintenant sur la fiche d'un adhérent. Ici vous pourrez :
					<ul>
					<li>voir ou modifier ses coordonnées</li>
					<li>gérer ses cotisations à votre association</li>
					<li>voir un récapitulatif de ses commandes</li>
					</ul>",
					action: TANext,
					placement : TPRight
				},{
					element:"ul.nav #contractadmin",
					text:"Allons voir maintenant la page de gestion des <b>contrats</b> qui est très importante pour les coordinateurs.",
					action: TAPage("/contractAdmin"),
					placement : TPBottom
				},{
					element:"#contracts",
					text:"Ici se trouve la liste des <b>contrats</b>. 
					Ils comportent une date de début, une date de fin, et représentent votre relation avec un producteur. <br/>
					<p>
					C'est ici que vous pourrez gérer :
						<ul>
						<li>la liste de produits de ce producteur</li>
						<li>les commandes des adhérents pour ce producteur</li>
						<li>planifier les distributions</li>
						</ul>
					</p>",
					action: TANext,
					placement : TPBottom
					
				},{
					element:"#vendors",
					text:"Ici vous pouvez gérer la liste des <b>producteurs ou fournisseurs</b> avec lesquels vous collaborez.<br/>
					Remplissez une fiche complète pour chacun d'eux afin d'informer au mieux les adhérents",
					action: TANext,
					placement : TPTop
					
				},{
					element:"#places",
					text:"Ici vous pouvez gérer la liste des <b>lieux de distribution</b>.<br/>
					N'oubliez pas de mettre l'adresse complète car une carte s'affiche à partir de l'adresse du lieu.",
					action: TANext,
					placement : TPTop
					
				},{
					element:"#contracts table .btn:first",
					text:"Allons voir maintenant de plus près comment administrer un contrat. <b>Cliquez sur ce bouton</b>",
					action: TAPage("/contractAdmin/view/*"),
					placement : TPBottom
					
				},{
					element:".table.table-bordered:first",
					text:"Ici vous avez un récapitulatif du contrat.<br/>Il y a deux types de contrats : <ul>
					<li>Les contrats AMAP : l'adhérent s'engage sur toute la durée du contrat avec une commande fixe.</li>
					<li>Les contrats à commande variable : l'adhérent peut commander ce qu'il veut à chaque distribution.</li>
					</ul>",
					action: TANext,
					placement : TPRight
					
				},{
					element:"#subnav #products",
					text:"Allons voir maintenant la page de gestion des <b>Produits</b>",
					action : TAPage("/contractAdmin/products/*"),
					placement:TPRight
				},{
					element:".article .table",
					text:"Sur cette page, vous pouvez gérer la liste des produits proposée par ce producteur.<br/>
					Définissez au minimum le nom et le prix de vente des produits. Il est également possible d'ajouter un descriptif et une photo.",
					action: TANext,
					placement : TPTop
					
				},{
					element:"#subnav #deliveries",
					text:"Allons voir maintenant la page de gestion des <b>distributions</b>",
					action : TAPage("/contractAdmin/distributions/*"),
					placement:TPRight
				},{
					element:".article .table",
					text:"Ici nous pouvons gérer la liste des distributions pour ce producteur.<br/>
					Dans le logiciel, une distribution comporte une date avec une heure de début et heure de fin de distribution. 
					Il faut aussi préciser le lieu de distribution à partir de la liste que nous avons vue précédement.",
					action: TANext,
					placement : TPLeft
					
				},{
					element:"#subnav #orders",
					text:"Allons voir maintenant la page de gestion des <b>commandes</b>",
					action : TAPage("/contractAdmin/orders/*"), //can fail if the contract is variable because the uri is different
					placement:TPRight
				},{
					element:".article .table",
					text:"Ici nous pouvons gérer la liste des commandes relatives à ce producteur.<br/>
					Si vous choisissez d'\"ouvrir les commandes\" aux adhérents, ils pourront eux-mêmes saisir leurs commandes en se connectant à Cagette.net.<br/>
					Cette page centralisera automatiquement les commandes pour ce producteur. 
					Sinon, en tant que coordinateur, vous pouvez saisir les commandes pour les adhérents depuis cette page.",
					action: TANext,
					placement : TPLeft
					
				},{
					element:"ul.nav #messages",
					text:"<p>Nous avons vu l'essentiel en ce qui concerne les contrats.</p><p>Explorons maintenant la messagerie.</p>",
					action: TAPage("/messages"),
					placement : TPBottom
					
				},{
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
				},{
					element:"#subnav",
					text:"<p>Dans cette dernière rubrique, vous pouvez configurer tout ce qui concerne votre groupe en général.</p>
					<p>La rubrique <b>Droits et accès</b> est importante puisque c'est là que vous pourrez nommer d'autres coordinateurs parmi les adhérents. Ils pourront
					ainsi gérer les contrats dont ils s'occupent, utiliser la messagerie, etc.
					</p>",
					action:TANext,
					placement : TPBottom
				},{
					element:"#footer",
					text:"<p>C'est la dernière étape de ce tutoriel, j'espère qu'il vous aura donné une bonne vue d'ensemble du logiciel.<br/>
					Pour aller plus loin, n'hésitez pas à consulter la <b>documentation</b> dont le lien est toujours disponible en bas de l'écran.
					</p>",
					action:TANext,
					placement : TPBottom
				}
			]
		},
	
	
	];
}
