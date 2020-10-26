/// <reference types="react" />
interface MessagingServiceProps {
    onMessageSent: () => void;
}
declare const MessagingService: ({ onMessageSent }: MessagingServiceProps) => JSX.Element;
export default MessagingService;
