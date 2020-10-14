/// <reference types="react" />
import { Group } from 'gql';
export interface MangopayUbosCardProps {
    group: Pick<Group, 'id' | 'mangopayGroup'>;
    disabledActions: boolean;
    open: boolean;
    onTogglePanel: (value: boolean) => void;
}
declare const MangopayUbosCard: ({ group, disabledActions, open, onTogglePanel }: MangopayUbosCardProps) => JSX.Element;
export default MangopayUbosCard;
