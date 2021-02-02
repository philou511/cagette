export declare type Order = 'asc' | 'desc';
export declare function stableSort<T>(array: T[], order: Order, orderBy: keyof T): T[];
