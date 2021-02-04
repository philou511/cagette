/// <reference types="react" />
import Member from '../MemberType';
interface MembersTableToolbarProps {
    selectedIds: number[];
    members: Member[];
}
declare const MembersTableToolbar: ({ selectedIds, members }: MembersTableToolbarProps) => JSX.Element;
export default MembersTableToolbar;
