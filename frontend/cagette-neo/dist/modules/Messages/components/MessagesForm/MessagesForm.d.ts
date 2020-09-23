/// <reference types="react" />
import { FormikHelpers } from 'formik';
import { User } from '../../../../gql';
interface Props {
    user: User;
    isPartnerConnected: boolean;
    userLists: UserList[];
    onSubmit: (values: FormValues, bag: FormikBag) => void;
    onSelectOption?: (value: string) => void;
}
export interface FormValues {
    firstName: string;
    senderEmail: string;
    recipientsList: string;
    object: string;
    message: string;
}
export interface UserList {
    id: string;
    count?: number | null | undefined;
}
export declare type FormikBag = FormikHelpers<FormValues>;
declare const MessagesForm: ({ user, isPartnerConnected, userLists, onSubmit, onSelectOption }: Props) => JSX.Element;
export default MessagesForm;
