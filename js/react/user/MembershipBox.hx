package react.user;

import js.html.Console;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.Error;
import react.mui.CagetteTheme;
import mui.core.*;

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
            content =  <Grid container spacing=${mui.core.grid.GridSpacing.Spacing_4}>
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
                                            ${CagetteTheme.getIcon("delete",{fontSize:12})} 
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
                    <FormControl>
                        <InputLabel>Année</InputLabel>
                        <Select value={Date.now().getFullYear()} onChange={handleChange}>
                        ${
                            state.availableYears.map( y -> return <MenuItem value=${y.id}>${y.name}</MenuItem> )
                        }
                        </Select>
                    </FormControl>
                </Grid>
                
            </Grid>;
        }

        return jsx('<div>
            <Error error=${state.error}/>
            $content
        </div>');

    }
    
    function handleChange(){

    }
      
    function deleteMembership(year:Int){
        
    }
  
}