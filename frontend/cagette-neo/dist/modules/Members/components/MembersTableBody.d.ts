import { ReactChild } from 'react';
import { Order } from '../../../utils/table';
export interface DefaultFormattedMember {
    names: string | ReactChild;
    id: number;
}
interface MembersTableBodyProps<T> {
    formattedMembers: T[];
    order: Order;
    orderBy: keyof T;
    rowsPerPage: number;
    page: number;
    headCells: (keyof T)[];
    isSelected?: (id: number) => boolean;
    handleRowClick?: (id: number) => void;
}
declare const MembersTableBody: <T extends DefaultFormattedMember>({ formattedMembers, order, orderBy, page, rowsPerPage, headCells, isSelected, handleRowClick, }: MembersTableBodyProps<T>) => JSX.Element;
export default MembersTableBody;
