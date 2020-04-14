/// <reference types="react" />
import { DistribSlotVo, UserVo } from '../../../../../vo';
import { Mode } from '../../interfaces';
interface Props {
    mode: Mode;
    slots: DistribSlotVo[];
    registeredSlotIds?: number[];
    voluntaryFor?: UserVo[];
<<<<<<< HEAD
    inNeedUsers?: UserVo[];
    onSalesProcess: boolean;
=======
>>>>>>> c60bb76d678815fe3badec8acdb152ceb33e5c7c
    changeSlots: () => void;
    addInNeeds: () => void;
    close: () => void;
}
<<<<<<< HEAD
declare const SummaryStep: ({ mode, slots, registeredSlotIds, voluntaryFor, inNeedUsers, onSalesProcess, changeSlots, addInNeeds, close, }: Props) => JSX.Element;
=======
declare const SummaryStep: ({ mode, slots, registeredSlotIds, voluntaryFor, changeSlots, addInNeeds, close, }: Props) => JSX.Element;
>>>>>>> c60bb76d678815fe3badec8acdb152ceb33e5c7c
export default SummaryStep;
