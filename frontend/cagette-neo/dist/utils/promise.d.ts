export interface PromiseRejectedResult {
    status: 'rejected';
    reason: any;
}
export declare const allSettled: (promises: Promise<any>[]) => Promise<({
    status: string;
    value: any;
} | {
    status: string;
    reason: any;
})[]>;
