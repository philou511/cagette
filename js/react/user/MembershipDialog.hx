package react.user;

import css.TextAlign;
import mui.core.common.Breakpoint;
import react.types.HandlerOrVoid;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.mui.CagetteTheme;
import mui.core.*;
import mui.core.Tabs;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import mui.core.common.Breakpoint;
import react.user.MemberShipForm;
import react.user.MembershipHistory;

typedef TClasses = Classes<[modal, card, cardHeaderTitle, loaderContainer]>;

typedef MembershipDialogProps = {
    userId: Int,
    groupId: Int,
    callbackUrl: String,
};

typedef MembershipDialogPropsWithClasses = {
    >MembershipDialogProps,
    var classes:TClasses;
};

typedef MembershipDialogState = {
    isOpened: Bool,
    isLoading: Bool,
    isLocked: Bool,
    tabIndex: Int,
    canAdd: Bool,

    userName:String,
    availableYears:Array<{name:String,id:Int}>,
    memberships:Array<{name:String,date:Date,id:Int}>,
    membershipFee:Int,
    distributions:Array<{name:String,id:Int}>,
    paymentTypes:Array<{id:String,name:String}>,
}

@:publicProps(MembershipDialogProps)
@:wrap(Styles.withStyles(styles))
class MembershipDialog extends ReactComponentOfPropsAndState<MembershipDialogPropsWithClasses, MembershipDialogState> {

    public static function styles(theme:Theme):ClassesDef<TClasses> {
        return {
            modal: {
                display: 'flex',
                alignItems: css.AlignItems.Center,
                justifyContent: css.JustifyContent.Center,
            },
            card: {
                minWidth: 610  
            },
            cardHeaderTitle: {
                textAlign: TextAlign.Center
            },
            loaderContainer: {
                minWidth: 610,
                minHeight: 300,
                display: "flex",
                alignItems: css.AlignItems.Center,
                justifyContent: css.JustifyContent.Center,
            }
        }
    }

	public function new(props : MembershipDialogPropsWithClasses) {
        super(props);
        state = cast {
            isOpened : true,
            isLoading: true,
            tabIndex: 0,
            canAdd: true,
        };    
    }

    override function componentDidMount() {
        loadData();
    }

  	override public function render() {
        var content;

        if (state.userName == null) {
            content = <CircularProgress />; 
        } else {
            var cardTitle = 'Adhésions de ${state.userName}';
            content = 
                <Card className=${props.classes.card}>
                    <CardHeader
                        title=$cardTitle
                        classes={{
                            title: props.classes.cardHeaderTitle
                        }}
                        />
                    <AppBar position=${mui.core.common.CSSPosition.Static}>
                        <Tabs
                            centered
                            value=${state.tabIndex}
                            onChange=$onTabChange
                        >
                            <Tab label="Historique" disabled=${state.isLocked} />
                            <Tab label="Ajouter" disabled=${state.isLocked || state.availableYears.length == 0} />
                        </Tabs>
                    </AppBar>
                    ${renderTab()}
                    ${renderLoader()}
                </Card>
            ;
        }

        var res =
            <Modal open=${state.isOpened} className=${props.classes.modal} onClose=$onClose>
                $content
            </Modal>
        ;

        return jsx('$res');
    }

    private function loadData() {
        setState({ isLoading: true });

        var url = '/api/user/membership/${props.userId}/${props.groupId}';
        js.Browser.window.fetch(url)
            .then(res -> res.json())
            .then(res -> {
                var availableYears = res.availableYears.filter(y -> {
                    var finded = res.memberships.find(mY -> y.id == mY.id);
                    return finded == null;
                });

                setState({
                    isLoading : false,
                    isLocked: false,
                    tabIndex: availableYears.length == 0 ? 0 : state.tabIndex,

                    userName : res.userName,
                    paymentTypes : res.paymentTypes,
                    availableYears : cast availableYears,
                    memberships : cast res.memberships,
                    membershipFee : res.membershipFee,
                    distributions : res.distributions,
                });
            });
    }

    private function onClose() {
        if (!state.isLocked) setState({ isOpened: false });
    }

    private function onTabChange(e: js.html.Event, newValue: Int) {
        this.setState({ tabIndex: newValue });
    }

    private function renderTab() {
        if (state.isLoading) {
            return <div className=${props.classes.loaderContainer}><CircularProgress /></div>;
        }

        if (state.tabIndex == 0) {
            return 
                <MembershipHistory
                    isLocked=${state.isLocked}
                    userId=${props.userId}
                    groupId=${props.groupId}
                    memberships={state.memberships}
                    onDelete=$lock
                    onDeleteComplete=$loadData
                />;
        }

        if (state.availableYears.length == 0) {
            return null;
        }

        return 
            <MemberShipForm
                userId=${props.userId}
                groupId=${props.groupId}
                availableYears=${state.availableYears}
                paymentTypes=${state.paymentTypes}
                onSubmit=$lock
                onSubmitComplete=$loadData
            />
        ;
    }

    private function renderLoader() {
        if (!state.isLocked) return null;
        return <LinearProgress />;
    }

    private function lock() {
        setState({ isLocked: true });
    }
}