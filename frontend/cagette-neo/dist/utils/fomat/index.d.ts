import { MangopayUbo, User, UserList } from 'gql';
export declare const formatUboNames: (ubo: MangopayUbo) => string;
export declare const formatUserName: (user: User) => string;
export declare const formatUserAndPartnerNames: (user: User) => string;
export declare const formatUserAddress: (user: User) => string | undefined;
export declare const formatAbsoluteDate: (date: Date, withTime?: boolean) => string;
export declare const formatDate: (date: Date, withTime?: boolean) => string;
export declare const formatUserList: (userList: UserList, t: import("i18next").TFunction) => string;
