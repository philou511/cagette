package controller;
import tink.core.Error;


class Subscriptions extends controller.Controller
{
	public function new()
	{
		super();		
	}

	
	//  View all the subscriptions for a catalog
	@tpl("contractadmin/subscriptions.mtt")
	function doDefault( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var catalogSubscriptions : List<db.Subscription> = db.Subscription.manager.search( $catalogId == catalog.id,false );

		view.catalog = catalog;
		view.c = catalog;
		view.subscriptions = catalogSubscriptions;
		// for( field in Reflect.fields(catalogSubscriptions.first()) ) {
		// 	trace(" obj." + field + " = " + Reflect.field(catalogSubscriptions.first(), field));
		// }
		view.nav.push( 'subscriptions' );

		//generate a token
		checkToken();
	}
	
	// @tpl("form.mtt")
	// public function doEdit( document : sugoi.db.EntityFile, ?catalog : db.Catalog ) {

	// 	var returnPath : String = null;
	// 	if( catalog != null ) {

	// 		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );
	// 		returnPath = '/contractAdmin/documents/' + catalog.id;
	// 	}
	// 	else { // Documents for a group

	// 		if ( !app.user.isAmapManager() ) throw Error( '/', t._('Access forbidden') );
	// 		returnPath = '/amapadmin/documents';
	// 	}
		
	// 	var form = new sugoi.form.Form("documentEdit");
	// 	view.title = "Editer le document ici";		
	// 	view.text = "Vous pouvez changer le nom et la visibilité du document ici.<br/>";
		
	// 	form.addElement( new StringInput( "name","Nom du document", document.file.name, true ) );

	// 	var options = [ { value : "subscribers", label : "Souscripteurs du contrat" },
	// 					  { value : "members", label : "Membres du groupe" },
	// 					  { value : "public", label : "Public" } ];

	// 	//In case of a group or a variable orders catalog
	// 	if ( catalog == null || catalog.type != 0 ) {

	// 		options = [	{ value : "members", label : "Membres du groupe" }, { value : "public", label : "Public" } ];
	// 	}
	// 	form.addElement( new RadioGroup( 'visibility', 'Visibilité', options, document.data != null ? document.data : 'members' ) );
	
	// 	if( form.isValid() ) {
			
	// 		document.lock();
	// 		document.file.lock();
	// 		document.file.name = form.getValueOf("name");
	// 		document.data = form.getValueOf("visibility");
	// 		document.file.update();
	// 		document.update();
				
	// 		throw Ok( returnPath, 'Le document ' + document.file.name + ' a bien été mis à jour.' );
	// 	}
			
	// 	view.form = form;
	// }


	public function doDelete( subscription : db.Subscription ) {
		
		if ( !app.user.canManageContract( subscription.catalog ) ) throw Error( '/', t._('Access forbidden') );
			
		if ( checkToken() ) {

			

			throw Ok( '/contractAdmin/subscriptions/' + subscription.catalog.id, 'La souscription a bien été supprimée.' );
			
		}

		throw Error( '/contractAdmin/subscriptions/' + subscription.catalog.id, t._("Token error") );
	}


	@tpl("form.mtt")
	public function doInsert( catalog : db.Catalog ) {

		if ( !app.user.canManageContract( catalog ) ) throw Error( '/', t._('Access forbidden') );

		var subscription = new db.Subscription();
		var form = sugoi.form.Form.fromSpod(subscription);
		form.removeElementByName( 'catalogId' );
		form.getElement("startDate").value = catalog.startDate;
		form.getElement("endDate").value = catalog.endDate;


		if ( form.isValid() ) {

			try {
				
				form.toSpod( subscription );			
				service.SubscriptionService.create( subscription.user, catalog, subscription.startDate, subscription.endDate );
			}
			catch( error : Error ) {
				
				throw Error( '/contractAdmin/subscriptions/insert/' + catalog.id, error.message );
			}

			throw Ok( '/contractAdmin/subscriptions/' + catalog.id, 'La souscription pour ' + subscription.user.getName() + ' a bien été ajoutée.' );
		}
	
		view.form = form;
		view.title = 'Nouvelle souscription pour ' + catalog.name;
		view.c = catalog;
		view.catalog = catalog;
		view.nav.push( 'subscriptions' );
	}

}
