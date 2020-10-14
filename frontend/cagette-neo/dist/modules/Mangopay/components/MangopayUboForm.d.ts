/// <reference types="react" />
import { FormikHelpers } from 'formik';
import { MangopayUbo } from 'gql';
export interface MangopayUboFormProps {
    ubo?: MangopayUbo;
    onSubmit: (values: MangopayUboFormValues, bag: MangopayUboFormBag) => void;
}
export interface MangopayUboFormValues {
    FirstName: string;
    LastName: string;
    Address: {
        AddressLine1: string;
        AddressLine2?: string;
        City: string;
        Country: string;
        PostalCode: string;
    };
    Nationality: string;
    Birthday: Date;
    Birthplace: {
        City: string;
        Country: string;
    };
}
export declare type MangopayUboFormBag = FormikHelpers<MangopayUboFormValues>;
declare const MangopayUboForm: ({ ubo, onSubmit }: MangopayUboFormProps) => JSX.Element;
export default MangopayUboForm;
