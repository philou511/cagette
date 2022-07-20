package hosted;
import Common;
import db.Group;
import sugoi.plugin.*;
import sugoi.tools.TransactionWrappedTask;

using tools.DateTool;

class HostedPlugIn extends PlugIn implements IPlugIn{
	
	public function new() {
		super();
		name = "hosted";
		file = sugoi.tools.Macros.getFilePath();
		//suscribe to events
		App.eventDispatcher.add(onEvent);
		
	}
	
	public function onEvent(e:Event) {
		
		switch(e) {

			case Page(uri):
				if (uri.substr(0, 7) == "/group/"	){
					
					//update visibility in map and directory
					var gid = Std.parseInt(uri.split("/")[2]);
					if (gid == null || gid == 0) return;					
					if(db.Group.manager.get(gid,false) == null) return;
					var h = hosted.db.GroupStats.getOrCreate(gid, true);
					h.updateStats();

					
				}

			case Nav(nav,name,id) :
				switch(name) {
					case "admin":
						nav.push({id:"hosted",name:"Utilisateurs", link:"/p/hosted/user",icon:"user"});
						if (App.current.getSettings().noCourse!=true) {
							nav.push({id:"courses",name:"Formations", link:"/p/hosted/course",icon:"student"});
						}
						nav.push({id:"ref",name:"Référencement", link:"/p/hosted/seo",icon:"cog"});
				}
			
			case NewMember(u,g) :
				//update members count
				var h = hosted.db.GroupStats.getOrCreate(g.id,true);
				h.membersNum = h.getMembersNum()+1; //+1 because the member is not yet inserted
				h.update();
				
			default :
		}
	}
	
	
	
}