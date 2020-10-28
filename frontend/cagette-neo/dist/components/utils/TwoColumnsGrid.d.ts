import React from 'react';
export interface TwoColumnsGridProps {
    left: React.ReactNode;
    right: React.ReactNode;
}
declare const TwoColumnsGrid: ({ left, right }: TwoColumnsGridProps) => JSX.Element;
export default TwoColumnsGrid;
