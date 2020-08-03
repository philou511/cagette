/// <reference types="react" />
import { ButtonProps, CircularProgressProps } from '@material-ui/core';
export interface ProgressButtonProps extends ButtonProps {
    loading?: boolean;
    circularProgressProps?: CircularProgressProps;
}
declare const ProgressButton: ({ loading, variant, color, disabled, children, circularProgressProps, ...other }: ProgressButtonProps) => JSX.Element;
export default ProgressButton;
