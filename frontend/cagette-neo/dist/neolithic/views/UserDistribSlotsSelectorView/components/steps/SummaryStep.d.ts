/// <reference types="react" />
import { DistribSlotVo, UserVo } from '../../../../../vo';
import { Mode } from '../../interfaces';
interface Props {
    mode: Mode;
    slots: DistribSlotVo[];
    registeredSlotIds?: number[];
    voluntaryFor?: UserVo[];
    changeSlots: () => void;
    addInNeeds: () => void;
}
declare const SummaryStep: ({ mode, slots, registeredSlotIds, voluntaryFor, changeSlots, addInNeeds, }: Props) => JSX.Element;
export default SummaryStep;
