/// <reference types="react" />
import { DistribUserStatusVO } from './interfaces';
import { DistribVo } from '../../../vo';
interface Props {
    distrib: DistribVo;
    status: DistribUserStatusVO;
}
declare const ResolvedState: ({ distrib, status }: Props) => JSX.Element;
export default ResolvedState;
