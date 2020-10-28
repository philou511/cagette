/// <reference types="react" />
export interface MessagesProps {
    groupId: number;
    whichUser: boolean;
}
declare const Messages: ({ groupId, whichUser }: MessagesProps) => JSX.Element;
export default Messages;
