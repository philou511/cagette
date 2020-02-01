

package test;import utest.Assert;
import db.UserGroup;
import Common;

/**
 * Test user rights to view contracts
 * 
 * @author web-wizard
 */
class TestUser extends utest.Test
{
	
	public function new(){
		super();
	}
	
	var contract : db.Catalog;
	var user : db.User;
    var group1 : db.Group;
    var group2 : db.Group;
    var userAmap : db.UserGroup;
	
	/**
	 * get a contract + a user
	 */
	function setup(){
		TestSuite.initDB();
		TestSuite.initDatas();
		
		contract = db.Catalog.manager.get(3);
		user = db.User.manager.get(1);
        group1 = db.Group.manager.get(1);
        group2 = db.Group.manager.get(2);
	}
	
	/**
	 * Check that a user who has admin rights for his/her group can't view a contract from a group
     he/she doesn't belong to
	 */
	function testViewContract(){        
        userAmap = db.UserGroup.getOrCreate(user, group1);
        userAmap.giveRight(Right.GroupAdmin);
        Assert.isFalse(user.canManageContract(contract));
	}

}