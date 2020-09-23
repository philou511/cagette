/// <reference types="react" />
import { User, Group } from 'gql';
export interface MangopayLegalUserCardProps {
    group: Pick<Group, 'id' | 'mangopayGroup'>;
    defaultLegalRepr: User;
    open: boolean;
    disabledActions: boolean;
    onTogglePanel: (open: boolean) => void;
    onSubmit: () => void;
    onSubmitComplete: () => void;
    onSubmitFail: () => void;
}
declare const MangopayLegalUserCard: ({ group, defaultLegalRepr, open, disabledActions, onTogglePanel, onSubmit, onSubmitComplete, onSubmitFail, }: MangopayLegalUserCardProps) => JSX.Element;
export default MangopayLegalUserCard;
