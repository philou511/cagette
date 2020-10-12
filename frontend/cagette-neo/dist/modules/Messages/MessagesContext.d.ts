import React from 'react';
interface MessagesContextProviderProps {
    groupId: number;
    whichUser: boolean;
}
interface MessagesContextProps extends MessagesContextProviderProps {
    attachments: File[];
    addAttachment: (attachment: File) => void;
    removeAttachment: (attachment: File) => void;
    resetAttachments: () => void;
}
export declare const MessagesContext: React.Context<MessagesContextProps>;
declare const MessagesContextProvider: ({ children, groupId, whichUser, }: {
    children: React.ReactNode;
} & MessagesContextProviderProps) => JSX.Element;
export default MessagesContextProvider;
