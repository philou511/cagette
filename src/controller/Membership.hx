package controller;
import sugoi.form.elements.NativeDatePicker;
import sugoi.form.elements.IntSelect;
using Std;
/**
 * Membership management
 * 
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Membership extends controller.Controller
{

	@tpl("membership/default.mtt")
	function doDefault(member:db.User) {
		var userAmap = db.UserGroup.get(member, app.user.getGroup(),true);
		if (userAmap == null) throw Error("/member", t._("This person is not a member of your group"));
		
		//formulaire
		var f = new sugoi.form.Form("membership");
		var year = Date.now().getFullYear();
		var data = [];
		var now = Date.now();
		for ( x in 0...5) {
			
			var y = now.getFullYear() - x;
			var yy = DateTools.delta(now, DateTools.days(365) * -x);
			data.push({label:app.user.getGroup().getPeriodName(yy),value:app.user.getGroup().getMembershipYear(yy)});
		}
		f.addElement(new IntSelect("year", t._("Period"), data,app.user.getGroup().getMembershipYear(),true));
		f.addElement(new form.CagetteDatePicker("date", t._("Date of payment of subscription"), null, NativeDatePickerType.date, true));
		if (f.isValid()) {
			var y : Int = f.getValueOf("year");
			
			if (db.Membership.get(member, app.user.getGroup(), y) != null) throw Error("/membership/"+member.id, t._("This subscription has been already keyed-in"));
			
			var cotis = new db.Membership();
			cotis.amap = app.user.getGroup();
			cotis.user = member;
			cotis.year = y;
			cotis.date = f.getElement("date").value;
			cotis.insert();
			throw Ok("/membership/"+member.id, t._("Subscription saved"));
		}
		
		//années de cotisation
		var memberships = db.Membership.manager.search($user == member && $amap == app.user.getGroup(),{orderBy:-year}, false);
		//for ( m in memberships) {
			//Reflect.setField(m, 'yearDate', new Date(m.year, 1, 1, 1, 1, 1));
		//}
		view.memberships = memberships;
		
		//view
		view.form = f;
		view.member = member;
		checkToken();
	}
	
	
	public function doDelete(member:db.User, year:Int,?args:{token:String}) {
		
		if (checkToken()) {
			var cotis = db.Membership.get(member, app.user.getGroup(), year, true);
			if (cotis == null) throw Error("/", t._("This subscription does not exist"));
			
			cotis.delete();
			throw Ok("/membership/" + member.id, t._("Subscription deleted"));
		}else {
			throw Error("/", "Bad Token");
		}
		
	}
	
	
}