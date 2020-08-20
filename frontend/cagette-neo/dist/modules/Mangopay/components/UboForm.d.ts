/// <reference types="react" />
import { FormikHelpers } from 'formik';
import { MangopayUbo } from 'gql';
export interface UboFormProps {
    ubo?: MangopayUbo;
    onSubmit: (values: UboFormValues, bag: UboFormBag) => void;
}
export interface UboFormValues {
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
export declare type UboFormBag = FormikHelpers<UboFormValues>;
declare const UboForm: ({ ubo, onSubmit }: UboFormProps) => JSX.Element;
export default UboForm;
