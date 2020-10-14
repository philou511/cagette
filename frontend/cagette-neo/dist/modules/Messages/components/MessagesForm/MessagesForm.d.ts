/// <reference types="react" />
import { FormikHelpers } from 'formik';
import { User, UserList } from '../../../../gql';
interface Props {
    user: User;
    isPartnerConnected: boolean;
    userLists: UserList[];
    onSubmit: (values: FormValues, bag: FormikBag) => void;
    onSelectOption?: (value: string) => void;
    isSuccessful: boolean;
}
export interface FormValues {
    firstName: string;
    senderEmail: string;
    recipientsList: string;
    object: string;
    message: string;
}
export declare type FormikBag = FormikHelpers<FormValues>;
declare const MessagesForm: ({ user, isPartnerConnected, userLists, onSubmit, onSelectOption, isSuccessful }: Props) => JSX.Element;
export default MessagesForm;
