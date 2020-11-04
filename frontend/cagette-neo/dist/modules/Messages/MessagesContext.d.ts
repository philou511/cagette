import { ApolloError } from '@apollo/client';
import React from 'react';
import { UserLists } from 'cagette-common';
import { User } from '../../gql';
interface MessagesContextProviderProps {
    groupId: number;
    whichUser: boolean;
}
export declare type Recipient = Partial<User>;
interface MessagesContextProps extends MessagesContextProviderProps {
    attachments: File[];
    error: ApolloError | undefined;
    setError: (error: ApolloError | undefined) => void;
    addAttachment: (attachment: File) => void;
    removeAttachment: (attachment: File) => void;
    resetAttachments: () => void;
    recipients: Recipient[];
    setRecipients: (recipients: Recipient[]) => void;
    selectedUserList: UserLists | undefined;
    setSelectedUserList: (userList: UserLists | undefined) => void;
}
export declare const MessagesContext: React.Context<MessagesContextProps>;
declare const MessagesContextProvider: ({ children, groupId, whichUser, }: {
    children: React.ReactNode;
} & MessagesContextProviderProps) => JSX.Element;
export default MessagesContextProvider;
