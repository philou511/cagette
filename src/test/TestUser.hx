

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
	
	function setup(){
		TestSuite.initDB();
		TestSuite.initDatas();
	}
	
	/**
	 * Check that a user who has admin rights for his/her group can't view a contract from a group
     he/she doesn't belong to
	 */
	function testViewContract(){        
        var userAmap = db.UserGroup.getOrCreate(TestSuite.FRANCOIS, TestSuite.AMAP_DU_JARDIN);
        userAmap.giveRight(Right.GroupAdmin);
		var catalog = TestSuite.LOCAVORES.getContracts().first();
        Assert.isFalse( TestSuite.FRANCOIS.canManageContract(catalog) );
	}

}