/// <reference types="react" />
import { User, MangopayLegalUser } from 'gql';
export interface MangopayLegalUserFormContainerProps {
    groupId: number;
    legalRepr: User;
    legalUser?: MangopayLegalUser;
    disabled?: boolean;
    onSubmit: () => void;
    onSubmitComplete: () => void;
    onSubmitFail: () => void;
}
declare const MangopayLegalUserFormContainer: ({ groupId, legalRepr, legalUser, disabled, onSubmit, onSubmitComplete, onSubmitFail, }: MangopayLegalUserFormContainerProps) => JSX.Element;
export default MangopayLegalUserFormContainer;
