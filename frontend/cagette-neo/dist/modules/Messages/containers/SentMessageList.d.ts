/// <reference types="react" />
export interface SentMessageListProps {
    groupId: number;
    isGroupAdmin: boolean | undefined;
}
declare const SentMessageList: ({ groupId, isGroupAdmin }: SentMessageListProps) => JSX.Element;
export default SentMessageList;
