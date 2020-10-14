/// <reference types="react" />
import { User, Group } from 'gql';
export interface MangopayLegalReprCardProps {
    group: Pick<Group, 'id' | 'users' | 'mangopayGroup'>;
    disabledActions: boolean;
    selectedLegalRepr?: User;
    setSelectedLegalRepr: (user: User | undefined) => void;
}
declare const MangopayLegalReprCard: ({ group, disabledActions, selectedLegalRepr, setSelectedLegalRepr, }: MangopayLegalReprCardProps) => JSX.Element;
export default MangopayLegalReprCard;
