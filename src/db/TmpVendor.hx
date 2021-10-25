package db;
import Common;
import sys.db.Object;
import sys.db.Types;

/**
 * Temporary Vendor before certification
 */
class TmpVendor extends Object
{
    public var id : SId;
    @:relation(vendorId)  public var vendor  : SNull<db.Vendor>;
}