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
export interface DistribVo {
    id: number;
    date?: Date;
    end?: Date;
}
/** */
export declare const parseUserVo: (data: any) => UserVo;
export declare const parseGroupVo: (data: any) => GroupVo;
