import React from 'react';
import { User, UserList } from '../../gql';
interface MembersContextProviderProps {
    groupId: number;
}
export declare type Recipient = Partial<User>;
interface MembersContextProps extends MembersContextProviderProps {
    errors: string[];
    setErrors: (errors: string[]) => void;
    success: string | undefined;
    setSuccess: (success: string | undefined) => void;
    toggleRefetch: boolean | undefined;
    setToggleRefetch: (toggleRefetch: boolean) => void;
    resetAlerts: () => void;
    selectedUserList: UserList;
    onSelectList: (userList: UserList) => void;
}
export declare const MembersContext: React.Context<MembersContextProps>;
declare const MembersContextProvider: ({ children, groupId }: {
    children: React.ReactNode;
} & MembersContextProviderProps) => JSX.Element;
export default MembersContextProvider;
