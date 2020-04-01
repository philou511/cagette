/// <reference types="react" />
interface Props {
    fetchMeUrl: string;
    postMeUrl: string;
    onConfirm: (allowed: string[]) => void;
    onCancel: () => void;
}
declare const UserInNeedForm: ({ fetchMeUrl, postMeUrl, onConfirm, onCancel, }: Props) => JSX.Element;
export default UserInNeedForm;
