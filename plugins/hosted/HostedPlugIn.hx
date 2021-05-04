package hosted;
import sugoi.tools.TransactionWrappedTask;
import Common;
import sugoi.plugin.*;
import db.Group;
using tools.DateTool;

class HostedPlugIn extends PlugIn implements IPlugIn{
	
	public function new() {
		super();
		name = "hosted";
		file = sugoi.tools.Macros.getFilePath();
		//suscribe to events
		App.current.eventDispatcher.add(onEvent);
		
	}
	
	public function onEvent(e:Event) {
		
		switch(e) {

			case Page(uri):
				if (uri.substr(0, 7) == "/group/"	){
					
					//update visibility in map and directory
					var gid = Std.parseInt(uri.split("/")[2]);
					if (gid == null || gid == 0) return;
					var h = hosted.db.Hosting.getOrCreate(gid, true);
					h.updateVisible();
				}

			case Nav(nav,name,id) :
				switch(name) {
					case "admin":
						nav.push({id:"hosted",name:"Utilisateurs", link:"/p/hosted/user",icon:"user"});
						nav.push({id:"hosted",name:"Groupes", link:"/p/hosted",icon:"users"});
						nav.push({id:"courses",name:"Formations", link:"/p/hosted/course",icon:"student"});
						nav.push({id:"ref",name:"Référencement", link:"/p/hosted/seo",icon:"cog"});
				}
			
			case NewMember(u,g) :
				//update members count
				var h = hosted.db.Hosting.getOrCreate(g.id,true);
				h.membersNum = h.getMembersNum()+1; //+1 because the member is not yet inserted
				h.update();
				
			default :
		}
	}
	
	/**
	 * check qu'on a le bon stock d'emails
	 * @param	emailNum
	 */
	/*public function checkEmail(emailNum:Int) {
		var u = App.current.user;
		var h = hosted.db.Hosting.get(u.amap.id,true);
		if (emailNum > h.emailStock) throw ErrorAction("/messages", "Vous n'avez pas assez d'emails est stock pour envoyer " + emailNum + " emails. Contactez le coordinateur général pour mettre à jour votre abonnement Cagette.net");
		h.emailStock -= emailNum;
		h.update();
	}*/
	
	/**
	 * check qu'on est dans les limites de l'abonnement souscrit.
	 * 
	 * si oui , ne fait rien.
	 * si non, ajoute un message avec ou sans redirection
	 */
	/*public function checkAbo(?redirect = false, ?plusOne = false, ?group : db.Group) {
		var u = App.current.user;
		if (u == null) {
			//user not logged in
			return;
		}
		
		if (group == null){
			group = u.getAmap();
			if (group == null) return;
		}
		
		var h = hosted.db.Hosting.get(group.id, true);
		
		if (plusOne && !h.isAboOk(true)) {
			//demande si c'est ok avec 1 membre de plus
			throw ErrorAction("/member", "Vous ne pouvez pas ajouter de membre dans votre groupe, car votre abonnement vous limite à " + ABO_MAX_MEMBERS[h.aboType] + " membres.");
				
		}else if (!h.isAboOk()) {
			var s = "Cagette.net est bloqué car votre abonnement n'a pas été renouvellé.<br/>
				Contactez le responsable du groupe afin de renouveler ou mettre à niveau votre abonnement.</p>";
			if (App.current.user.isAmapManager()) {
				s += '<a href="/p/hosted/abo" class="btn btn-default">Renouveler</a>';
			}
			if (redirect) {
				throw RedirectAction("/");//message will be displayed from home controller
			} else {
				App.current.session.addMessage(s, true);	
			}
		}
	}*/
	

	
}