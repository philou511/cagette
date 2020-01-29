package react.user;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.mui.CagetteTheme;
import mui.core.*;
import dateFns.DateFns;
import mui.icon.Delete;

typedef MembershipHistoryProps = {
    isLocked: Bool,
    userId: Int,
    groupId: Int,
    memberships: Array<{name:String,date:Date,id:Int}>,
    ?onDelete: () -> Void,
    ?onDeleteComplete: () -> Void,
};

class MembershipHistory extends ReactComponentOfPropsAndState<MembershipHistoryProps, { ?yearToDelete: Int }> {

    public function new(props: MembershipHistoryProps) {
        super(props);
        state = cast {};
    }

    override public function render() {
        var dialogIsOpened = state.yearToDelete != null;
        var res =
            <>
                <Table>
                    <TableHead>
                        <TableRow>
                            <TableCell>Année</TableCell>
                            <TableCell>Date de cotis.</TableCell>
                            <TableCell></TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        ${props.memberships.map(row -> renderRow(row))}
                    </TableBody>
                </Table>
                <Dialog open=$dialogIsOpened onClose=$closeDialog>
                    <DialogTitle>{"Supprimer cette adhésion ?"}</DialogTitle>
                    <DialogActions>
                    <Button onClick=$closeDialog>
                        Annuler
                    </Button>
                    <Button color=${mui.Color.Primary} variant={Contained} onClick=$delete>
                        Supprimer
                    </Button>
                    </DialogActions>
                </Dialog>
            </>
        ;

        return jsx('$res');
    }

    private function delete() {
        closeDialog();
        if (props.onDelete != null) props.onDelete();

        var url = '/api/user/deleteMembership/${props.userId}/${props.groupId}/${state.yearToDelete}';
        js.Browser.window.fetch(
            url
        ).then(function(res) {
            if (props.onDeleteComplete != null) props.onDeleteComplete();
        }).catchError(function(err) {
            trace(err);
        });
    }

    private function closeDialog() {
        this.setState({yearToDelete: null});
    }

    private function renderRow(row: Dynamic) {
        var onClick = function(e: js.html.Event) {
            this.setState({yearToDelete: row.id});
        };

        return 
            <TableRow key={row.id}>
                <TableCell>{row.name}</TableCell>
                <TableCell>{DateFns.format(Date.fromString(row.date), "d MMMM yyyy")}</TableCell>
                <TableCell>
                    <IconButton disabled=${props.isLocked} onClick=$onClick>
                        <Delete />
                    </IconButton>
                </TableCell>    
            </TableRow>
        ;
    }
}