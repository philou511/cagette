package service;
import Common;

class ReportService{

	/**
		Get orders grouped by products.	
	 */
	public static function getOrdersByProduct( distribution:db.Distribution, ?csv = false):Array<OrderByProduct>{
		var view = App.current.view;
		var t = sugoi.i18n.Locale.texts;
		var where = "";
		
		var exportName = t._("Delivery ::contractName:: of the ", {contractName:distribution.contract.name}) + distribution.date.toString().substr(0, 10);
		where += ' and p.contractId = ${distribution.contract.id}';
		if (distribution.contract.type == db.Contract.TYPE_VARORDER ) {
			where += ' and up.distributionId = ${distribution.id}';
		}

		//Product price will be an average if price changed
		var sql = '
			select 
			SUM(quantity) as quantity,
			p.id as pid,
			p.name as pname,
			AVG(up.productPrice) as price,
			p.vat as vat,
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

}