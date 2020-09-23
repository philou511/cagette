/// <reference types="react" />
export interface MessagesProps {
    groupId: number;
    whichUser: boolean;
}
declare const MessagingService: ({ groupId, whichUser }: MessagesProps) => JSX.Element;
export default MessagingService;
