package react.user;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.formik.Formik;
import react.formik.Form;
import react.formik.Field;
import react.formikMUI.TextField;
import react.formikMUI.Select;
import react.formikMUI.DatePicker;
import react.mui.pickers.MuiPickersUtilsProvider;
import mui.core.*;
import mui.core.styles.Styles;
import mui.core.styles.Classes;
import react.mui.CagetteTheme;
import react.mui.Box;
import dateIO.DateFnsUtils;

typedef MemberShipFormProps = {
    userId: Int,
    groupId: Int,
    availableYears: Array<{name:String,id:Int}>,
    paymentTypes: Array<{id:String,name:String}>,
    ?onSubmit: () -> Void,
    ?onSubmitComplete: () -> Void,
};

typedef MemberShipFormClasses = Classes<[snack, snackMessage]>;


typedef MemberShipFormPropsWithClasses = {
    >MemberShipFormProps,
    classes:MemberShipFormClasses,
};

typedef FormProps = {
    date: Date,
    year: Int,
    membershipFee: Float,
    paymentType: String,
};

@:publicProps(MemberShipFormProps)
@:wrap(Styles.withStyles(styles))
class MemberShipForm extends ReactComponentOfProps<MemberShipFormPropsWithClasses> {

    public static function styles(theme:Theme):ClassesDef<MemberShipFormClasses> {
        return {
            snack: {
                backgroundColor: "#f44336"
            },
            snackMessage: {
                width: "100%",
                textAlign: "center",
                color: "#FFF",
            }
        }
    }

    override public function render() {
        var res =
            <MuiPickersUtilsProvider utils={DateFnsUtils}>
                <Formik
                    initialValues={{
                        date: new js.lib.Date(),
                        year: props.availableYears[0].id,
                        membershipFee: 0,
                        paymentType: props.paymentTypes[0].id,
                    }}
                    onSubmit=$onSubmit
                >
                    {formikProps -> (
                        <Form>
                            {renderStatus(formikProps.status)}
                            <CardContent>
                                <FormControl fullWidth>
                                    <DatePicker label="Date de cotisaion" name="date" required  />
                                </FormControl>
                                
                                <FormControl fullWidth margin=${mui.core.form.FormControlMargin.Normal}>
                                    <InputLabel id="mb-year">Année</InputLabel>
                                    <Select labelId="mb-year" name="year" fullWidth required>
                                        ${props.availableYears.map(y -> <MenuItem key=${y.id} value=${y.id}>${y.name}</MenuItem>)}
                                    </Select>
                                </FormControl>
                                
                                <FormControl fullWidth margin=${mui.core.form.FormControlMargin.Normal}>
                                    <TextField
                                        fullWidth
                                        required
                                        name="membershipFee"
                                        label="Montant"
                                        type=${mui.core.input.InputType.Number}
                                    />
                                </FormControl>
                                
                                <FormControl fullWidth margin=${mui.core.form.FormControlMargin.Normal}>
                                    <InputLabel id="mb-payment">Paiemnt</InputLabel>
                                    <Select labelId="mb-payment" name="paymentType" fullWidth required>
                                        ${props.paymentTypes.map(p -> <MenuItem key=${p.id} value=${p.id}>${p.name}</MenuItem>)}
                                    </Select>
                                </FormControl>
                                
                            </CardContent>
                            <CardActions>
                                <Box my={2} display="flex" justifyContent="center" width="100%">
                                    <Button
                                        disabled=${formikProps.isSubmitting}
                                        variant=${mui.core.button.ButtonVariant.Contained}
                                        color=$Primary
                                        type=${mui.core.button.ButtonType.Submit}
                                    >
                                        Valider
                                    </Button>
                                </Box>
                            </CardActions>
                            ${renderProgress(formikProps.isSubmitting)}
                        </Form>
                    )}
                </Formik>
            </MuiPickersUtilsProvider>
        ;

        return jsx('$res');
    }

    private function renderStatus(?status: Dynamic) {
        if (status == null) return null;
        return 
            <CardContent>
                <SnackbarContent
                    classes={{ 
                        root: props.classes.snack,
                        message: props.classes.snackMessage
                    }}
                    message=$status />
            </CardContent>
        ;
    }

    private function renderProgress(isSubmitting: Bool) {
        if (!isSubmitting) return null;
        return
            <Box height={4}>
                <LinearProgress />
            </Box>
        ;
    }


    private function onSubmit(values: FormProps, formikBag: Dynamic) {
        formikBag.setStatus(null);
        if (props.onSubmit != null) props.onSubmit();

        var url = '/api/user/membership/${props.userId}/${props.groupId}';

        var data = new js.html.FormData();
        data.append("date", values.date.toString());
        data.append("year", Std.string(values.year));
        data.append("membershipFee", Std.string(values.membershipFee));
        data.append("paymentType", values.paymentType);

        js.Browser.window.fetch(url, {
            method: "POST",
            body: data
        }).then(function(res) {
            formikBag.setSubmitting(false);
            if (props.onSubmitComplete != null) props.onSubmitComplete();

            if (!res.ok) {
                formikBag.setStatus("Un erreur est survenue");
                throw res.statusText;
            }
            
            return true;
        }).catchError(function(err) {
            trace(err);
        });
    }
}