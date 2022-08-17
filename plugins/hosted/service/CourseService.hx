package hosted.service;

import pro.db.CagettePro;
import pro.db.PUserCompany;
import pro.db.VendorStats;
import service.BridgeService;

class CourseService {

    public static function attachDiscoveryAccountToCourse(trainingCpro:pro.db.CagettePro,defVendor:db.Vendor, course:hosted.db.Course) {

        if(trainingCpro.offer!=Training) throw "ce compte producteur n'est pas un compte pédagogique !";
        
        // var props = ["name","email","image","phone","address1","address2","zipCode","city","desc","linkText","linkUrl","vatRates"];
		// var v = trainingCpro.vendor;
        
        /*if(defVendor==null){
            //copy vendor
            defVendor = new db.Vendor();
            for( p in props){
                Reflect.setProperty(defVendor,p,Reflect.getProperty(v,p));
            }
            defVendor.name = StringTools.replace(defVendor.name,"(formation)","");//remove "(formation)"
            defVendor.insert();
        } else {*/
           
        //}

        var defCpro = CagettePro.getFromVendor(defVendor);
        if(defCpro!=null) {
            defCpro.lock();
            if(defCpro.offer==Training) throw "Le compte sélectionné est aussi un compte pédagogique";
        }
		/*if(defCpro==null){
            defCpro = new pro.db.CagettePro();
            defCpro.vendor = defVendor;
        }*/		
      
      /*  if(defCpro.id==null) defCpro.insert() else defCpro.update();

        if(v.name.indexOf("(formation)")<0){
            v.lock();
            v.name  = v.name +" (formation)";
            v.update();
        }*/
        
		//cpro access
		var cc = hosted.db.CompanyCourse.find(trainingCpro);
        if( !defCpro.getUsers().exists( u -> u.id==cc.user.id )){
            pro.db.PUserCompany.make(cc.user,defCpro);
        }

        hosted.db.CompanyCourse.make(defCpro, course, cc.user,null,null,null,null);
    }
    
}