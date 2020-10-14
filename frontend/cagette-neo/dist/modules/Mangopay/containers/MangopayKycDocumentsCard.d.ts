/// <reference types="react" />
import { Group } from 'gql';
export interface MangopayKycDocumentsCardProps {
    group: Pick<Group, 'id' | 'mangopayGroup'>;
    open: boolean;
    disabledActions: boolean;
    onTogglePanel: (open: boolean) => void;
}
declare const MangopayKycDocumentsCard: ({ group, open, disabledActions, onTogglePanel }: MangopayKycDocumentsCardProps) => JSX.Element;
export default MangopayKycDocumentsCard;
