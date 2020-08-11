import React from 'react';
export interface MangopayConfigCardHeaderProps {
    icon?: React.ReactNode;
    title?: string;
    actions?: React.ReactNode;
}
declare const MangopayConfigCardHeader: ({ icon, title, actions }: MangopayConfigCardHeaderProps) => JSX.Element;
export default MangopayConfigCardHeader;
