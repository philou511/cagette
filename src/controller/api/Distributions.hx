package controller.api;
import haxe.Json;
import Common;
import db.MultiDistrib;

/**
 * Groups API
 * @author fbarbut
 */
class Distributions extends Controller {

  private var distrib: db.MultiDistrib;

  public function new(distrib: db.MultiDistrib) {
    super();
    this.distrib = distrib;
  }

  public function doDefault() {
    if (sugoi.Web.getMethod() != "GET") throw new tink.core.Error(405, "Method Not Allowed");

    Sys.print(Json.stringify(this.parse()));
  }

  public function doActivateSlots() {
    if (sugoi.Web.getMethod() != "POST") throw new tink.core.Error(405, "Method Not Allowed");
    if (!App.current.user.isAmapManager()) throw new tink.core.Error(403, "Forbidden");

    if (this.distrib.slots != null) {
      Sys.print(Json.stringify(this.parse()));
      return;
    }

    this.distrib.generateSlots();
    
    Sys.print(Json.stringify(this.parse()));
  }

  public function doRegisterUserVoluntary() {
    // allow only POST method
    if (sugoi.Web.getMethod() != "POST") throw new tink.core.Error(405, "Method Not Allowed");
    // user must be logged
    if (App.current.user == null) throw new tink.core.Error(403, "Forbidden");
    // user must be member of group
    // TODO if (!App.current.user.isMemberOf(this.distrib.getGroup())) throw new tink.core.Error(403, "Forbidden");
    // distrib slots must be activated 
    if (this.distrib.slots == null) throw new tink.core.Error(403, "Forbidden");

    var request = sugoi.tools.Utils.getMultipart( 1024 * 1024 * 10 ); //10Mb	
    if (!request.exists("userIds")) throw new tink.core.Error(400, "Bad Request");

    var strUserIds = request.get("userIds").split(",");
    var userIds = new Array<Int>();
    for (index in 0...strUserIds.length) {
      userIds.push(Std.parseInt(strUserIds[index]));
    }

    this.distrib.registerVoluntary(App.current.user.id, userIds);

    Sys.print(Json.stringify(this.parse()));
 
  }

  public function doRegisterInNeedUser() {
    // allow only POST method
    if (sugoi.Web.getMethod() != "POST") throw new tink.core.Error(405, "Method Not Allowed");
    // user must be logged
    if (App.current.user == null) throw new tink.core.Error(403, "Forbidden");
    // user must be member of group
    // TODO if (!App.current.user.isMemberOf(this.distrib.getGroup())) throw new tink.core.Error(403, "Forbidden");
    // distrib slots must be activated 
    if (this.distrib.slots == null) throw new tink.core.Error(403, "Forbidden");

    this.distrib.registerInNeedUser(App.current.user.id);

    Sys.print(Json.stringify(this.parse()));
  }

  public function doRegisterUserSlots() {
    // allow only POST method
    if (sugoi.Web.getMethod() != "POST") throw new tink.core.Error(405, "Method Not Allowed");

    // TODO : distrib should be opened

    // user must be logged
    if (App.current.user == null) throw new tink.core.Error(403, "Forbidden");
    
    // user must be member of group
    // TODO if (!App.current.user.isMemberOf(this.distrib.getGroup())) throw new tink.core.Error(403, "Forbidden");
    
    // distrib slots must be activated 
    if (this.distrib.slots == null) throw new tink.core.Error(403, "Forbidden");

    var request = sugoi.tools.Utils.getMultipart( 1024 * 1024 * 10 ); //10Mb	
    if (!request.exists("slotIds")) throw new tink.core.Error(400, "Bad Request");
    
    // parse query to slotIds
    var strSlotIds = request.get("slotIds").split(",");
    var slotIds = new Array<Int>();
    for (index in 0...strSlotIds.length) {
      slotIds.push(Std.parseInt(strSlotIds[index]));
    }

    // check slots validity
    if (slotIds.length < 1) throw new tink.core.Error(400, "Bad Request");
    for (slotId in 0...slotIds.length) {
      if (Lambda.find(this.distrib.slots, (slot) -> slot.id == slotId) == null) {
        throw new tink.core.Error(400, "Bad Request");
      }
    }

    this.distrib.registerUserToSlot(App.current.user.id, slotIds);

    Sys.print(Json.stringify(this.parse()));
  }

  // TODO: remove
  public function doDesactivateSlots() {
    this.distrib.lock();
    this.distrib.slots = null;
    this.distrib.inNeedUserIds = null;
    this.distrib.voluntaryUsers = null;
    this.distrib.update();
    Sys.print(Json.stringify(this.parse()));
  }

  // TODO : remove
  public function doGenerateFakeDatas() {
    var fakeUserIds = [1, 2, 6, 8, 9];

    this.distrib.generateSlots(true);

    this.distrib.registerUserToSlot(1, [1, 2]);

    for (userIndex in 1...fakeUserIds.length) {
      var slotIds = new Array<Int>();
      for (slotIndex in 0...this.distrib.slots.length) {
        var slot = this.distrib.slots[slotIndex];
        if (Math.random() > 0.7) {
          slotIds.push(slot.id);
        }
      }
      this.distrib.registerUserToSlot(fakeUserIds[userIndex], slotIds);
    }

    this.distrib.registerInNeedUser(10);
    this.distrib.registerInNeedUser(11);
    this.distrib.registerInNeedUser(12);
    this.distrib.registerInNeedUser(15);
    this.distrib.registerInNeedUser(17);

    this.distrib.registerVoluntary(1, [10, 11]);

    Sys.print(Json.stringify(this.parse()));
  }

  private function parse() {
    var users = null;

    if (this.distrib.inNeedUserIds != null) {
      users = new Array<db.User>();

      var inNeedUserIds = this.distrib.inNeedUserIds;

      if (this.distrib.voluntaryUsers != null) {
        var it = this.distrib.voluntaryUsers.keyValueIterator();
        while (it.hasNext()) {
          var v = it.next();
          inNeedUserIds = inNeedUserIds.filter(uI -> {
            if (v.value.indexOf(uI) != -1) return false;
            return true;
          });
        }
      }

      for (index in 0...inNeedUserIds.length) {
        users.push(
          db.User.manager.select($id == inNeedUserIds[index])
        );
      }
    }

    return {
      id: this.distrib.id,
      start: this.distrib.distribStartDate,
      end: this.distrib.distribEndDate,
      slots: this.distrib.slots,
      inNeedUsers: users == null ? null : users.map(user -> user.infos())
    }
  }
}