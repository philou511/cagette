/// <reference types="react" />
export interface MangopayKycFileFieldProps {
    label?: string;
    value: File[];
    disabled: boolean;
    onChange: (value: File[]) => void;
}
declare const MangopayKycFileField: ({ label, value, disabled, onChange }: MangopayKycFileFieldProps) => JSX.Element;
export default MangopayKycFileField;
