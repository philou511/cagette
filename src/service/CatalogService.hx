package service;
import tools.DateTool;
import db.Catalog;
import tink.core.Error;

class CatalogService{


    public static function getForm(catalog:db.Catalog) : sugoi.form.Form {

		if ( catalog.group == null || catalog.type == null || catalog.vendor == null ) {

			throw new tink.core.Error( "Un des éléments suivants est manquant : le groupe, le type, ou le producteur." );
		}

		var t = sugoi.i18n.Locale.texts;

		var customMap = new form.CagetteForm.FieldTypeToElementMap();
		customMap["DDate"] = form.CagetteForm.renderDDate;
		customMap["DTimeStamp"] = form.CagetteForm.renderDDate;
		customMap["DDateTime"] = form.CagetteForm.renderDDate;

		var form = form.CagetteForm.fromSpod( catalog, customMap );
		
		form.removeElement(form.getElement("groupId") );
		form.removeElement(form.getElement("type"));
		form.removeElement(form.getElement("vendorId"));
		
		if ( catalog.group.hasShopMode() ) {

			form.removeElement(form.getElement("orderStartDaysBeforeDistrib"));
			form.removeElement(form.getElement("orderEndHoursBeforeDistrib"));
			form.removeElement(form.getElement("requiresOrdering"));
			form.removeElement(form.getElement("distribMinOrdersTotal"));
			form.removeElement(form.getElement("catalogMinOrdersTotal"));
			form.removeElement(form.getElement("allowedOverspend"));
			form.removeElement(form.getElement("absentDistribsMaxNb"));
			form.removeElement(form.getElement("absencesStartDate"));
			form.removeElement(form.getElement("absencesEndDate"));
		}
		else {
			//CSA MODE
			form.removeElementByName("percentageValue");
			form.removeElementByName("percentageName");
			untyped form.getElement("flags").excluded = [2];// remove "PercentageOnOrders" flag

			var absencesIndex = 16;
			if ( catalog.type == Catalog.TYPE_VARORDER ) {
				//VAR
				form.addElement( new sugoi.form.elements.Html( 'distribconstraints', '<h4>Engagement par distribution</h4>', '' ), 10 );
				form.addElement( new sugoi.form.elements.Html( 'catalogconstraints', '<h4>Engagement sur la durée du contrat</h4>', '' ), 13 );

				form.getElement("orderStartDaysBeforeDistrib").docLink = "https://wiki.cagette.net/admin:contratsamapvariables#ouverture_et_fermeture_de_commande";
				form.getElement("orderEndHoursBeforeDistrib").docLink = "https://wiki.cagette.net/admin:contratsamapvariables#ouverture_et_fermeture_de_commande";
				
				form.getElement("catalogMinOrdersTotal").docLink = "https://wiki.cagette.net/admin:contratsamapvariables#minimum_de_commandes_sur_la_duree_du_contrat";
				form.getElement("allowedOverspend").docLink = "https://wiki.cagette.net/admin:contratsamapvariables#depassement_autorise";
			}
			else { 
				//CONST
				form.removeElement(form.getElement("orderStartDaysBeforeDistrib"));
				form.removeElement(form.getElement("requiresOrdering"));
				form.removeElement(form.getElement("distribMinOrdersTotal"));
				form.removeElement(form.getElement("catalogMinOrdersTotal"));
				form.removeElement(form.getElement("allowedOverspend"));

				form.getElement("orderEndHoursBeforeDistrib").label = "Délai minimum pour saisir une souscription (nbre d'heures avant prochaine distribution)";
				form.getElement("orderEndHoursBeforeDistrib").docLink = "https://wiki.cagette.net/admin:admin_contratsamap#champs_delai_minimum_pour_saisir_une_souscription";

				absencesIndex = 9;
			}
			
			var html = "<h4>Gestion des absences</h4><div class='alert alert-warning'>";

			//if catalog is new
			if ( catalog.id == null ) {

				if ( catalog.type == Catalog.TYPE_VARORDER ) {

					form.getElement("orderStartDaysBeforeDistrib").value = 365;
					form.getElement("allowedOverspend").value = 500;
				}
				form.getElement("orderEndHoursBeforeDistrib").value = 24;

				form.removeElement(form.getElement("absentDistribsMaxNb"));
				form.removeElement(form.getElement("absencesStartDate"));
				form.removeElement(form.getElement("absencesEndDate"));

				html += "<p><i class='icon icon-info'></i> 
					Vous pourrez définir une période pendant laquelle les membres pourront choisir d'être absent après avoir enregistré ce nouveau contrat et avoir ajouté des distributions.<br/>
					<a href='https://wiki.cagette.net/admin:absences' target='_blank'>Consulter la documentation.</a>
				</p></div>";
			}
			else {

				html += "<p><i class='icon icon-info'></i> 
					Vous pouvez définir une période pendant laquelle les membres pourront choisir d'être absent.<br/>
					<a href='https://wiki.cagette.net/admin:absences' target='_blank'>Consulter la documentation.</a>
				</p></div>";
			}

			form.addElement( new sugoi.form.elements.Html( 'absences', html, '' ), absencesIndex );
		}
		
		//For all types and modes
		if ( catalog.id != null ) {

			form.removeElement(form.getElement("distributorNum"));
		}
		else {

			if ( catalog.group.hasShopMode() ) {

				form.getElement("name").value = "Commande " + catalog.vendor.name;
			}
			else {

				form.getElement("name").value = "Contrat AMAP " + ( catalog.type == Catalog.TYPE_VARORDER ? "variable" : "classique" ) + " - " + catalog.vendor.name;
			}
			form.getElement("startDate").value = Date.now();
			form.getElement("endDate").value = DateTools.delta( Date.now(), 365.25 * 24 * 60 * 60 * 1000 );
		}

		form.addElement( new sugoi.form.elements.Html( "vendorHtml", '<b>${catalog.vendor.name}</b> ( ${catalog.vendor.zipCode} ${catalog.vendor.city} )', t._( "Vendor" ) ), 3 );

		var contact = form.getElement("userId");
		form.removeElement( contact );
		form.addElement( contact, 4 );
		contact.required = true;
			
		return form;
    }
    
    /**
        Check input data when updating a catalog
    **/
    public static function checkFormData( catalog:db.Catalog, form : sugoi.form.Form ) {

        //distributions should always happen between catalog dates
        if(form.getElement("startDate")!=null){
            for( distribution in catalog.getDistribs(false)){
                //accept a distrib on the last day of catalog
                var endDate =  DateTool.setHourMinute(form.getValueOf("endDate"),23,59);

                if(distribution.date.getTime() < form.getValueOf("startDate").getTime()){
                    throw new Error("Il y a des distributions antérieures à la date de début du catalogue");
                }
                if(distribution.date.getTime()> endDate.getTime()){
                    throw new Error("Il y a des distributions postérieures à la date de fin du catalogue");
                }
            }
        }
        
        //CSA checks
        if( !catalog.group.hasShopMode() ) {

			var t = sugoi.i18n.Locale.texts;

			if( catalog.type == Catalog.TYPE_VARORDER ) {

				var orderStartDaysBeforeDistrib = form.getValueOf("orderStartDaysBeforeDistrib");
				if( orderStartDaysBeforeDistrib == 0 ) {

					throw new tink.core.Error( 'L\'ouverture des commandes ne peut pas être à zéro.
					Si vous voulez utiliser l\'ouverture par défaut des distributions laissez le champ vide.');
				}
				
				var distribMinOrdersTotal = form.getValueOf("distribMinOrdersTotal");
				if( distribMinOrdersTotal != null && distribMinOrdersTotal != 0 ) {

					catalog.requiresOrdering = true;
				}

				var catalogMinOrdersTotal = form.getValueOf("catalogMinOrdersTotal");
				var allowedOverspend = form.getValueOf("allowedOverspend");
				if( ( catalogMinOrdersTotal != null && catalogMinOrdersTotal != 0 ) && ( allowedOverspend == null || allowedOverspend == 0 ) ) {

					throw new tink.core.Error( 'Vous devez obligatoirement définir un dépassement autorisé car vous avez rentré un minimum de commandes sur la durée du contrat.');
				}
			}

			if( catalog.type == Catalog.TYPE_CONSTORDERS ) {
				
				var orderEndHoursBeforeDistrib = form.getValueOf("orderEndHoursBeforeDistrib");
				if( orderEndHoursBeforeDistrib == null || orderEndHoursBeforeDistrib == 0 ) {

					throw new tink.core.Error( 'Vous devez obligatoirement définir un nombre d\'heures avant distribution pour la fermeture des commandes.');
				}
			}

			if ( catalog.id != null ) {

				var absentDistribsMaxNb = form.getValueOf('absentDistribsMaxNb');
				var absencesStartDate : Date = form.getValueOf('absencesStartDate');
				var absencesEndDate : Date = form.getValueOf('absencesEndDate');

				if ( ( absentDistribsMaxNb != null && absentDistribsMaxNb != 0 ) && ( absencesStartDate == null || absencesEndDate == null ) ) {

					throw new tink.core.Error( 'Vous avez défini un nombre maximum d\'absences alors vous devez sélectionner des dates pour la période d\'absences.' );
				}

				if ( ( absencesStartDate != null || absencesEndDate != null ) && ( absentDistribsMaxNb == null || absentDistribsMaxNb == 0 ) ) {

					throw new tink.core.Error( 'Vous avez défini des dates pour la période d\'absences alors vous devez entrer un nombre maximum d\'absences.' );
				}
			
				if ( absencesStartDate != null && absencesEndDate != null ) {

					if ( absencesStartDate.getTime() >= absencesEndDate.getTime() ) {

						throw new tink.core.Error( 'La date de début des absences doit être avant la date de fin des absences.' );
					}

					var absencesDistribsNb = service.SubscriptionService.getCatalogAbsencesDistribsNb( catalog, absencesStartDate, absencesEndDate );
					if ( ( absentDistribsMaxNb != null && absentDistribsMaxNb != 0 ) && absentDistribsMaxNb > absencesDistribsNb ) {

						throw new tink.core.Error( 'Le nombre maximum d\'absences que vous avez saisi est trop grand.
						Il doit être inférieur ou égal au nombre de distributions dans la période d\'absences : ' + absencesDistribsNb );
						
					}

					if ( absencesStartDate.getTime() < catalog.startDate.getTime() || absencesEndDate.getTime() > catalog.endDate.getTime() ) {

						throw new tink.core.Error( 'Les dates d\'absences doivent être comprises entre le début et la fin du contrat.' );
					}

					catalog.absencesStartDate = new Date( absencesStartDate.getFullYear(), absencesStartDate.getMonth(), absencesStartDate.getDate(), 0, 0, 0 );
					catalog.absencesEndDate = new Date( absencesEndDate.getFullYear(), absencesEndDate.getMonth(), absencesEndDate.getDate(), 23, 59, 59 );
				}
			
				if ( catalog.hasPercentageOnOrders() && catalog.percentageValue == null ) {

					throw new tink.core.Error( t._("If you would like to add fees to the order, define a rate (%) and a label.") );
				}
				
				if ( catalog.hasStockManagement()) {

					for ( p in catalog.getProducts()) {

						if ( p.stock == null ) {

							App.current.session.addMessage(t._("Warning about management of stock. Please fill the field \"stock\" for all your products"), true );
							break;
						}
					}
				}

			}

		}
	}

	public static function updateFutureDistribsStartEndOrdersDates( catalog : db.Catalog, newOrderStartDays : Int, newOrderEndHours : Int ) : String {

		if ( catalog.group.hasShopMode() ) return '';

		if ( newOrderStartDays != null || newOrderEndHours != null ) {

			var futureDistribs = db.Distribution.manager.search( $catalog == catalog && $date > Date.now(), { orderBy : date }, true );
			for ( distrib in futureDistribs ) {

				distrib.lock();

				if ( newOrderStartDays != null ) {
	
					distrib.orderStartDate = DateTools.delta( distrib.date, -1000.0 * 60 * 60 * 24 * newOrderStartDays );
				}
	
				if ( newOrderEndHours != null ) {
	
					distrib.orderEndDate = DateTools.delta( distrib.date, -1000.0 * 60 * 60 * newOrderEndHours );
				}

				distrib.update();
				
			}

			var message = '<br/>Attention ! ';
			
			if ( newOrderStartDays != null && newOrderEndHours != null ) {

				message += 'Les nouveaux délais d\'ouverture et de fermeture de commande ont été appliqués à toutes les distributions à venir. 
						   Si vous aviez personnalisé des dates d\'ouverture ou de fermeture, ces personnalisations ont été écrasées.';
			}
			else if ( newOrderStartDays != null ) {

				message += 'Le nouveau délai d\'ouverture de commande a été appliqué à toutes les distributions à venir. 
						   Si vous aviez personnalisé des dates d\'ouverture, ces personnalisations ont été écrasées.';
			}
			else {

				message += 'Le nouveau délai de fermeture de commande a été appliqué à toutes les distributions à venir. 
						   Si vous aviez personnalisé des dates de fermeture, ces personnalisations ont été écrasées.';
			}

			return message;

		}

		return '';

	}

}