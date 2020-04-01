export declare type Mode = 'inNeed' | 'solo' | 'voluntary';
export interface SlotVo {
    id: number;
    distribId: number;
    selectedUserIds: number[];
    registeredUserIds: number[];
    start: Date;
    end: Date;
}
export interface InNeedUser {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    address1?: string;
    address2?: string;
    zipCode?: string;
    city?: string;
    phone?: string;
}
export declare const parseSlotVo: (data: any) => SlotVo;
