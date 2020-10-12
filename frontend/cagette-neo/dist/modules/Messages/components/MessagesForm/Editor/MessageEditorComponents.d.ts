import React, { MouseEvent } from 'react';
interface EditorButtonType {
    active: boolean;
    onMouseDown: (event: MouseEvent<HTMLElement>) => void;
    onMouseUp?: (event: MouseEvent<HTMLElement>) => void;
}
export declare const EditorButton: ({ active, onMouseDown, onMouseUp, children }: React.PropsWithChildren<EditorButtonType>) => JSX.Element;
export declare const Menu: ({ children }: {
    children: React.ReactNode;
}) => JSX.Element;
export declare const Toolbar: ({ children }: {
    children: React.ReactNode;
}) => JSX.Element;
export {};
