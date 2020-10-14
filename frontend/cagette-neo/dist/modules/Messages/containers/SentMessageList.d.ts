/// <reference types="react" />
export interface SentMessageListProps {
    isGroupAdmin: boolean | undefined;
    selectedMessageId: number | undefined;
    onSelectMessage: (messageId: number) => void;
    toggleRefetch: boolean | undefined;
}
declare const SentMessageList: ({ isGroupAdmin, selectedMessageId, onSelectMessage, toggleRefetch }: SentMessageListProps) => JSX.Element;
export default SentMessageList;
