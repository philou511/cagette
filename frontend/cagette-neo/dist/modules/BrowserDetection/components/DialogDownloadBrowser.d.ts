/// <reference types="react" />
export interface DialogDownloadBrowserProps {
    open: boolean;
    onCancel: () => void;
}
declare const DialogDownloadBrowser: ({ open, onCancel }: DialogDownloadBrowserProps) => JSX.Element;
export default DialogDownloadBrowser;
