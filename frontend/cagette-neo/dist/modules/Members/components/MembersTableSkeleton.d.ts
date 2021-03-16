/// <reference types="react" />
interface MembersTableSkeletonProps {
    count: number | undefined;
    nbOfColumn: number;
    hasCheckbox?: boolean;
}
declare const MembersTableSkeleton: ({ count, nbOfColumn, hasCheckbox }: MembersTableSkeletonProps) => JSX.Element;
export default MembersTableSkeleton;
