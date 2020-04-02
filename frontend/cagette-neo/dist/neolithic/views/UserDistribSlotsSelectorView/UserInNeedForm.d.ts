/// <reference types="react" />
interface Props {
    onConfirm: (allowed: string[]) => void;
    onCancel: () => void;
}
declare const UserInNeedForm: ({ onConfirm, onCancel }: Props) => JSX.Element;
export default UserInNeedForm;
