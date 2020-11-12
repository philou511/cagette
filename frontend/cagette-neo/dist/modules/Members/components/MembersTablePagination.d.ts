import React from 'react';
interface MemberTablePaginationProps {
    count: number;
    rowsPerPage: number;
    handleChangeRowsPerPage: (event: React.ChangeEvent<HTMLInputElement>) => void;
    handleChangePage: (_event: unknown, newPage: number) => void;
    page: number;
}
export declare const DEFAULT_NUMBER_OF_ROW_PER_PAGE = 10;
declare const MembersTablePagination: ({ count, rowsPerPage, handleChangeRowsPerPage, page, handleChangePage, }: MemberTablePaginationProps) => JSX.Element;
export default MembersTablePagination;
