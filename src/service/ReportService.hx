package service;
import Common;

/**
	Manage various reports on Orders, turnover ...
**/
class ReportService{

	/**
		Get orders grouped by products.	
	 */
	public static function getOrdersByProduct( distribution:db.Distribution, ?csv = false):Array<OrderByProduct>{
		var view = App.current.view;
		var t = sugoi.i18n.Locale.texts;
		var where = "";

		if(distribution==null) throw "distribution should not be null";
		
		var exportName = t._("Delivery ::contractName:: of the ", {contractName:distribution.contract.name}) + distribution.date.toString().substr(0, 10);
		where += ' and p.contractId = ${distribution.contract.id}';
		if (distribution.contract.type == db.Contract.TYPE_VARORDER ) {
			where += ' and up.distributionId = ${distribution.id}';
		}

		//Product price will be an average if price changed
		var sql = 'select 
			SUM(quantity) as quantity,
			MAX(p.id) as pid,
			p.name as pname,
			AVG(up.productPrice) as price,
			AVG(p.vat) as vat,
			p.ref as ref,			
			SUM(quantity*up.productPrice) as totalTTC
			from UserContract up, Product p 
			where up.productId = p.id 
			$where
			group by ref,pname,price 
			order by pname asc;';

		var res = sys.db.Manager.cnx.request(sql).results();	
		var orders = [];

		//populate with full product names
		for ( r in res){

			var o : OrderByProduct = {
				quantity:1.0 * r.quantity,
				smartQt:"",
				pid:r.pid,
				pname:r.pname,
				ref:r.ref,
				priceHT: service.ProductService.getHTPrice(r.price,r.vat),
				priceTTC: r.price,
				vat:r.vat,
				totalTTC : r.totalTTC,
				totalHT  : service.ProductService.getHTPrice( r.totalTTC ,r.vat),
				weightOrVolume:"",
			};

			//smartQt
			var p = db.Product.manager.get(r.pid, false);
			if( p.hasFloatQt || p.variablePrice ){
				o.smartQt = view.smartQt(o.quantity, p.qt, p.unitType);
			}else{
				o.smartQt = Std.string(o.quantity);
			}
			o.weightOrVolume = view.smartQt(o.quantity, p.qt, p.unitType);
			
			if ( /*p.hasFloatQt || p.variablePrice ||*/ p.qt==null || p.unitType==null){
				o.pname = p.name;	
			}else{
				o.pname = p.name + " " + view.formatNum(p.qt) +" " + view.unit(p.unitType, o.quantity > 1);					
			}

			//special case : if product is multiweight, we should count the records number ( and not SUM quantities )
			if (p.multiWeight){
				sql = 'select 
				COUNT(up.id) as quantity 
				from UserContract up, Product p 
				where up.productId = p.id and up.quantity > 0 and p.id=${p.id}
				$where';
				var count = sys.db.Manager.cnx.request(sql).getIntResult(0);					
				o.smartQt = ""+count;
			}			
			
			orders.push(o);
		}
		
		if (csv) {
			var data = new Array<Dynamic>();			
			for (o in orders) {
				data.push({
					"quantity":view.formatNum(o.quantity),
					"pname":o.pname,
					"ref":o.ref,
					"priceHT":view.formatNum(o.priceHT),
					"priceTTC":view.formatNum(o.priceTTC),
					"totalHT":view.formatNum(o.totalHT),					
					"totalTTC":view.formatNum(o.totalTTC),
				});				
			}

			sugoi.tools.Csv.printCsvDataFromObjects(data, ["quantity", "pname","ref", "priceHT","priceTTC","totalHT","totalTTC"],"Export-"+exportName+"-par produits");
			return null;
		}else{
			return orders;		
		}
	}


	public static function getTurnoverFromOrdersByProducts(ordersByProduct:Array<OrderByProduct>):{turnoverHT:Float,turnoverTTC:Float}{
		var out = {turnoverHT:0.0,turnoverTTC:0.0};
		for( o in ordersByProduct){
			out.turnoverHT += o.totalHT;
			out.turnoverTTC += o.totalTTC;
		}
		return out;
	}

	/**
		NEW Mangopay
	 * Returns a map of vendorId and an object made of contract, distrib, productOrders
	 * @param date 
	 * @param place 
	 */
	public static function getMultiDistribVendorOrdersByProduct(date:Date, place:db.Place) {

		var t = sugoi.i18n.Locale.texts;
		
		var multiDistrib = db.MultiDistrib.get(date, place,db.Contract.TYPE_VARORDER);
		if ( multiDistrib.getDistributions().length == 0 ) throw new tink.core.Error(t._("There is no delivery at this date"));
		
		var vendorDataByVendorId = new Map<Int,Dynamic>();//key : vendor id
		
		for (d in multiDistrib.getDistributions()) {

			var vendorId = d.contract.vendor.id;
			var vendorData = vendorDataByVendorId.get(vendorId);
			
			if (vendorData == null) {
				vendorDataByVendorId.set( vendorId, {contract:d.contract, distrib:d, orders:service.ReportService.getOrdersByProduct(d)});	
			}
			else {
				
				//add orders with existing ones
				for ( productOrder in service.ReportService.getOrdersByProduct(d)){
					
					//find record in existing orders
					var vendorProductOrders  : Dynamic = Lambda.find(vendorData.orders, function(a) return a.pid == productOrder.pid);
					if (vendorProductOrders == null){
						//new product order
						vendorData.orders.push(productOrder);						
					}else{
						//increment existing
						vendorProductOrders.quantity += untyped productOrder.quantity;
						vendorProductOrders.total += untyped productOrder.total;
					}
				}
				vendorDataByVendorId.set(vendorId, vendorData);
			}
		}

		return vendorDataByVendorId;
	}

}