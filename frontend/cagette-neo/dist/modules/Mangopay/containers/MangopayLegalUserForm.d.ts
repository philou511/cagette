/// <reference types="react" />
import { User } from 'gql';
export interface MangopayLegalUserFormProps {
    groupId: number;
    users: User[];
}
declare const MangopayLegalUserForm: ({ groupId, users }: MangopayLegalUserFormProps) => JSX.Element;
export default MangopayLegalUserForm;
