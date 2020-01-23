package react.user;

import js.html.Console;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.core.CircularProgress;
import react.Error;
import mui.core.Grid;
import mui.core.Table;
import mui.core.TableHead;
import mui.core.TableRow;
import mui.core.TableCell;
import mui.core.TableBody;
import mui.core.Paper;
import mui.core.Button;
import react.mui.CagetteTheme;

typedef MembershipBoxState = {
    loading:Bool,
    error:String,
    userName:String,
    availableYears:Array<{name:String,id:Int}>,
    memberships:Array<{name:String,date:Date,id:Int}>,
    membershipFee:Int,
    distributions:Array<{name:String,id:Int}>,
    paymentTypes:Array<{id:String,name:String}>,
	
};

typedef MembershipBoxProps = {
    userId:Int,
    groupId:Int,
    callbackUrl:String,
	
};

class MembershipBox extends ReactComponentOfPropsAndState<MembershipBoxProps,MembershipBoxState> {

	public function new( props : MembershipBoxProps ) {
        super(props);
        state = cast {loading:true};
    }
      
    override function componentDidMount() {

		//load 
		utils.HttpUtil.fetch('/api/user/membership/${props.userId}/${props.groupId}', GET, null, JSON).then(
			function(data:Dynamic) {
                // Console.log(data);
                for ( m in (data.memberships:Array<Dynamic>)){
                    m.date = Date.fromString(m.date);
                }

                setState({
                    loading : false,
                    userName : data.userName,
                    paymentTypes : data.paymentTypes,
                    availableYears : data.availableYears,
                    memberships : data.memberships,
                    membershipFee : data.membershipFee,
                    distributions : data.distributions,

                });
            }
        ).catchError(
            err -> setState( {error:err} )
        );
    }

  	override public function render() {
        var content = null;
        if(state.loading){
            content = <div><CircularProgress /></div>;
        }else{
            content =  <Grid container>
                <Grid item xs={12}>
                    <h3>Adhésions de ${state.userName}</h3>
                </Grid>
                <Grid item xs={6}>
                    <h4>Historique</h4>
                    <Paper>
                        <Table stickyHeader>
                            <TableHead>
                            <TableRow>
                                <TableCell>Année</TableCell>
                                <TableCell>Date de cotis.</TableCell>
                                <TableCell></TableCell>
                            </TableRow>
                            </TableHead>
                            <TableBody>
                            ${state.memberships.map(row -> return 
                                <TableRow key={row.id}>
                                    <TableCell>{row.name}</TableCell>
                                    <TableCell>${Formatting.hDate(row.date)}</TableCell>
                                    <TableCell>
                                        <Button onClick=${deleteMembership.bind(row.id)} size=$Small variant=$Outlined >
                                            Supprimer
                                        </Button>    
                                    </TableCell>
                                </TableRow>
                            )}
                            </TableBody>
                        </Table>
                    </Paper>
                </Grid>

                <Grid item xs={6}>
                    <h4>Saisir une adhésion</h4>
                </Grid>
                
            </Grid>;
        }

        return jsx('<div>
            <Error error=${state.error}/>
            $content
        </div>');

	}
      
    function deleteMembership(year:Int){
        
    }
  
}