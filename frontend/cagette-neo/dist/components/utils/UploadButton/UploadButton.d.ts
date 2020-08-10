import React from 'react';
import { ButtonProps } from '@material-ui/core';
export interface UploadButtonProps extends Pick<React.InputHTMLAttributes<{}>, 'accept' | 'multiple'>, Omit<ButtonProps, 'component' | 'onChange'> {
    loading?: boolean;
    onChange: (fileList: FileList | null) => void;
}
declare const UploadButton: ({ accept, multiple, loading, onChange, children, ...buttonProps }: UploadButtonProps) => JSX.Element;
export default UploadButton;
