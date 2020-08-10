import React from 'react';
import { DialogTitleProps } from '@material-ui/core';
export interface DialogTitleActionsProps extends DialogTitleProps {
    actions?: React.ReactNode;
}
declare const DialogTitleActions: ({ actions, disableTypography, children, ...otherProps }: DialogTitleActionsProps) => JSX.Element;
export default DialogTitleActions;
