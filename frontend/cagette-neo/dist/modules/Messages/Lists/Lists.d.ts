declare class Lists {
    readonly value: string;
    static readonly ALL: Lists;
    static readonly TEST: Lists;
    private constructor();
    static getLists(): Lists[];
}
export default Lists;
