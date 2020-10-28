import { MangopayUbo, User } from 'gql';
export declare const formatUboNames: (ubo: MangopayUbo) => string;
export declare const formatUserName: (user: User) => string;
export declare const formatUserAddress: (user: User) => string | undefined;
export declare const formatDate: (date: Date, withTime?: boolean) => string;
