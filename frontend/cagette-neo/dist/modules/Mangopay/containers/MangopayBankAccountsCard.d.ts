/// <reference types="react" />
import { Group } from 'gql';
export interface MangopayBankAccountsCardProps {
    group: Pick<Group, 'id' | 'mangopayGroup'>;
    open: boolean;
    disabledActions: boolean;
    onTogglePanel: (open: boolean) => void;
}
declare const MangopayBankAccountsCard: ({ group, open, disabledActions, onTogglePanel }: MangopayBankAccountsCardProps) => JSX.Element;
export default MangopayBankAccountsCard;
