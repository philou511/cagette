import React from 'react';
import { Order } from '../../../utils/table';
interface MembersTableHeaderProps<T> {
    onRequestSort: (event: React.MouseEvent<unknown>, property: keyof T) => void;
    order: Order;
    orderBy: string;
    headCells: (keyof T)[];
    rowCount?: number;
    onSelectAllClick?: (event: React.ChangeEvent<HTMLInputElement>) => void;
    numSelected?: number;
}
export declare const DEFAULT_NUMBER_OF_ROW_PER_PAGE = 10;
declare const MembersTableHeader: <T extends object>({ order, orderBy, onRequestSort, headCells, rowCount, numSelected, onSelectAllClick, }: MembersTableHeaderProps<T>) => JSX.Element;
export default MembersTableHeader;
