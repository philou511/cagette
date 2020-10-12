/// <reference types="react" />
interface MessageProps {
    messageId: number;
    onBack: () => void;
}
declare const Message: ({ messageId, onBack }: MessageProps) => JSX.Element;
export default Message;
