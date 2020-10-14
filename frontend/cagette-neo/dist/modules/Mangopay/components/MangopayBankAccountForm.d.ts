/// <reference types="react" />
import { FormikHelpers } from 'formik';
import { MangopayBankAccount, MangopayBankAccountType } from 'gql';
export interface MangopayBankAccountFormProps {
    bankAccount?: MangopayBankAccount;
    disabled?: boolean;
    onSubmit: (values: MangopayBankAccountFormValues, bag: MangopayBankAccountFormBag) => void;
}
export interface MangopayBankAccountFormValues {
    Type: MangopayBankAccountType;
    OwnerAddress: {
        AddressLine1: string;
        AddressLine2?: string;
        City: string;
        Country: string;
        PostalCode: string;
    };
    OwnerName: string;
    /** IBAN */
    IBAN?: string;
    BIC?: string;
}
export declare type MangopayBankAccountFormBag = FormikHelpers<MangopayBankAccountFormValues>;
declare const MangopayBankAccountForm: ({ bankAccount, disabled, onSubmit }: MangopayBankAccountFormProps) => JSX.Element;
export default MangopayBankAccountForm;
