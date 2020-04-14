export interface UserVo {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    phone?: string;
    address1?: string;
    address2?: string;
    zipCode?: string;
    city?: string;
    nationality?: string;
    countryOfResidence?: string;
    birthDate?: string;
    firstName2?: string;
    lastName2?: string;
    email2?: string;
    phone2?: string;
}
export interface GroupVo {
    id: number;
    name: string;
    iban?: string;
    legalRepr?: UserVo;
}
export interface DistribSlotVo {
    id: number;
    distribId: number;
    selectedUserIds: number[];
    registeredUserIds: number[];
    start: Date;
    end: Date;
}
export interface DistribVo {
    id: number;
    start?: Date;
    end?: Date;
    orderEndDate?: Date;
    mode: 'solo-only' | 'default';
    slots?: DistribSlotVo[];
    inNeedUsers?: UserVo[];
}
/** */
export declare const parseUserVo: (data: any) => UserVo;
export declare const parseGroupVo: (data: any) => GroupVo;
export declare const parseDistribVo: (data: any) => DistribVo;
/** */
export declare const formatUserAddress: (user: UserVo) => string | undefined;
