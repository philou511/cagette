/// <reference types="react" />
import { SlotVo } from './interfaces';
interface Props {
    slots: SlotVo[];
    isLastStep: boolean;
    onSelect: (slotIds: number[]) => void;
    onCancel: () => void;
}
declare const SlotsSelector: ({ slots, isLastStep, onSelect, onCancel }: Props) => JSX.Element;
export default SlotsSelector;
