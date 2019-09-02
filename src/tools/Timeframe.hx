package tools;
import tink.core.Error;

class Timeframe {

    var from : Date;
    var to : Date;

    public function new(from:Date,to:Date){
        if(from.getTime()>to.getTime()){
            throw new Error("'from' date should be earlier than 'to' date.");
        }
        this.from = from;
        this.to = to;
    }

    public function next(){
        var time = to.getTime() - from.getTime();
        var from2 = to;
        var to2 = DateTools.delta(from2, time);
        return new Timeframe(from2,to2);
    }

    public function previous(){
        var time = to.getTime() - from.getTime();
        var to2 = from;
        var from2 = DateTools.delta(to2, -time);
        return new Timeframe(from2,to2);
    }

}