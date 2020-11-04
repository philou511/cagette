import React from 'react';
import { User, UserList } from '../../../../gql';
import { FormValues, FormikBag } from './MessagesFormFormikTypes';
interface Props {
    user: User;
    isPartnerConnected: boolean;
    userLists: UserList[];
    onSubmit: (values: FormValues, bag: FormikBag) => void;
    isSuccessful: boolean;
}
declare const _default: React.MemoExoticComponent<({ user, isPartnerConnected, userLists, onSubmit, isSuccessful }: Props) => JSX.Element>;
export default _default;
