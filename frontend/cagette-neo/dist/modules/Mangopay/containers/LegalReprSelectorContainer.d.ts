/// <reference types="react" />
import { User } from 'gql';
export interface LegalReprSelectorContainerProps {
    groupId: number;
    users: User[];
    currentLegalRepr?: User;
    onSelect: (user: User) => void;
}
declare const LegalReprSelectorContainer: ({ groupId, users, currentLegalRepr, onSelect, }: LegalReprSelectorContainerProps) => JSX.Element;
export default LegalReprSelectorContainer;
