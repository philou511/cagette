

package test;
import db.UserAmap;
import Common;

/**
 * Test user rights to view contracts
 * 
 * @author web-wizard
 */
class TestUser extends haxe.unit.TestCase
{
	
	public function new(){
		super();
	}
	
	var contract : db.Contract;
	var user : db.User;
    var group1 : db.Amap;
    var group2 : db.Amap;
    var userAmap : db.UserAmap;
	
	/**
	 * get a contract + a user
	 */
	override function setup(){
		TestSuite.initDB();
		TestSuite.initDatas();
		
		contract = db.Contract.manager.get(3);
		user = db.User.manager.get(1);
        group1 = db.Amap.manager.get(1);
        group2 = db.Amap.manager.get(2);
	}
	
	/**
	 * Check that a user who has admin rights for his/her group can't view a contract from a group
     he/she doesn't belong to
	 */
	function testViewContract(){        
        userAmap = db.UserAmap.getOrCreate(user, group1);
        userAmap.giveRight(Right.GroupAdmin);
        assertFalse(user.canManageContract(contract));
	}

}