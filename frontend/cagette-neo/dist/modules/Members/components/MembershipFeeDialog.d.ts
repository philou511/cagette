/// <reference types="react" />
export interface MembershipFeeDialogProps {
    open: boolean;
    onCancel: () => void;
    onConfirm: (amount: number) => void;
}
declare const MembershipFeeDialog: ({ open, onCancel, onConfirm }: MembershipFeeDialogProps) => JSX.Element;
export default MembershipFeeDialog;
