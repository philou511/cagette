declare class LegacyLists {
    readonly value: string;
    readonly label: any;
    static readonly ALL: LegacyLists;
    static readonly BOARD: LegacyLists;
    static readonly TEST: LegacyLists;
    static readonly MEMBERS_WITHOUT_ORDER: LegacyLists;
    static readonly MEMBERSHIP_TO_BE_RENEWED: LegacyLists;
    private constructor();
    static getLists(): LegacyLists[];
}
export default LegacyLists;
