/// <reference types="react" />
import { FormikHelpers } from 'formik';
import { MangopayUbo } from 'gql';
export interface UboFormProps {
    ubo?: MangopayUbo;
    onSubmit: (values: UboFormValues, bag: UboFormBag) => void;
}
export declare type UboFormValues = Omit<MangopayUbo, 'Id' | 'declarationId' | 'CreationDate'>;
export declare type UboFormBag = FormikHelpers<UboFormValues>;
declare const UboForm: ({ ubo, onSubmit }: UboFormProps) => JSX.Element;
export default UboForm;
