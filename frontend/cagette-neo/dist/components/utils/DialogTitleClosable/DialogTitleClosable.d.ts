import React from 'react';
interface DialogTitleClosableProps {
    children: React.ReactNode;
    disableTypography?: boolean;
    disableCloseBtn?: boolean;
    onClose?: () => void;
}
declare const DialogTitleClosable: ({ children, disableTypography, disableCloseBtn, onClose, }: DialogTitleClosableProps) => JSX.Element;
export default DialogTitleClosable;
