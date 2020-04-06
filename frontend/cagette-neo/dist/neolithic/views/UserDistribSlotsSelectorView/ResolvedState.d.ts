/// <reference types="react" />
import { DistribUserStatusVO } from './interfaces';
interface Props {
    status: DistribUserStatusVO;
}
declare const ResolvedState: ({ status }: Props) => JSX.Element;
export default ResolvedState;
