/// <reference types="react" />
import Member from '../MemberType';
interface MembersTableProps {
    members: Member[];
    loading: boolean;
}
declare function MembersTable({ members, loading }: MembersTableProps): JSX.Element;
export default MembersTable;
