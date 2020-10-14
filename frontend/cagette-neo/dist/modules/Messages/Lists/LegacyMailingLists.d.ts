declare class LegacyMailingLists {
    readonly value: string;
    readonly label: any;
    static readonly ALL: LegacyMailingLists;
    static readonly BOARD: LegacyMailingLists;
    static readonly TEST: LegacyMailingLists;
    static readonly MEMBERS_WITHOUT_ORDER: LegacyMailingLists;
    static readonly MEMBERSHIP_TO_BE_RENEWED: LegacyMailingLists;
    private constructor();
    static getLists(): LegacyMailingLists[];
}
export default LegacyMailingLists;
