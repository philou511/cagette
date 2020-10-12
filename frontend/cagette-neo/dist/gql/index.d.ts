import * as ApolloReactCommon from '@apollo/react-common';
import * as ApolloReactHooks from '@apollo/client';
export declare type Maybe<T> = T | null;
/** All built-in and custom scalars, mapped to their actual values */
export declare type Scalars = {
    ID: string;
    String: string;
    Boolean: boolean;
    Int: number;
    Float: number;
    /** Date custom scalar type */
    Date: any;
    Upload: any;
};
export declare type AttachmentFileInput = {
    contentType: Scalars['String'];
    filename: Scalars['String'];
    content: Scalars['String'];
    encoding: Scalars['String'];
};
export declare type Catalog = {
    __typename?: 'Catalog';
    id: Scalars['Int'];
    name: Scalars['String'];
    groupId: Scalars['Int'];
    startDate: Scalars['Date'];
    endDate: Scalars['Date'];
    vendorId: Scalars['Int'];
    vendor: Vendor;
};
export declare type CreateMangopayAddress = {
    AddressLine1: Scalars['String'];
    AddressLine2?: Maybe<Scalars['String']>;
    City: Scalars['String'];
    Region?: Maybe<Scalars['String']>;
    PostalCode: Scalars['String'];
    Country: Scalars['String'];
};
export declare type CreateMangopayBirthplace = {
    City: Scalars['String'];
    Country: Scalars['String'];
};
export declare type CreateMangopayIbanBankAccountInput = {
    groupId: Scalars['Int'];
    Type: MangopayBankAccountType;
    OwnerAddress: CreateMangopayAddress;
    OwnerName: Scalars['String'];
    IBAN?: Maybe<Scalars['String']>;
    BIC?: Maybe<Scalars['String']>;
};
export declare type CreateMangopayKycDocumentsInput = {
    groupId: Scalars['Int'];
    documents: Array<MangopayKycDocumentFilesTypeInput>;
};
export declare type CreateMangopayLegalUserInput = {
    groupId: Scalars['Int'];
    legalReprId: Scalars['Int'];
    Name: Scalars['String'];
    Email: Scalars['String'];
    LegalPersonType: MangopayLegalPersonType;
    CompanyNumber: Scalars['String'];
    LegalRepresentativeFirstName: Scalars['String'];
    LegalRepresentativeLastName: Scalars['String'];
    LegalRepresentativeEmail: Scalars['String'];
    LegalRepresentativeBirthday: Scalars['Date'];
    LegalRepresentativeNationality: Scalars['String'];
    LegalRepresentativeCountryOfResidence: Scalars['String'];
    LegalRepresentativeAddress: CreateMangopayAddress;
    HeadquartersAddress: CreateMangopayAddress;
};
export declare type CreateMangopayUboDeclarationInput = {
    groupId: Scalars['Int'];
};
export declare type CreateMembershipInput = {
    userId: Scalars['Int'];
    groupId: Scalars['Int'];
    year: Scalars['Int'];
    date: Scalars['Date'];
    distributionId?: Maybe<Scalars['Int']>;
    membershipFee: Scalars['Float'];
};
export declare type CreateMessageInput = {
    title: Scalars['String'];
    htmlBody: Scalars['String'];
    replyToHeader: Scalars['String'];
    whichUser: Scalars['Boolean'];
    recipients: Array<MailUserInput>;
    group: MailGroupInput;
    list?: Maybe<MailListInput>;
    attachments?: Maybe<Array<AttachmentFileInput>>;
};
export declare type CreateOrUpdateMangopayUboInput = {
    id?: Maybe<Scalars['Int']>;
    declarationId: Scalars['Int'];
    groupId: Scalars['Int'];
    FirstName: Scalars['String'];
    LastName: Scalars['String'];
    Address: CreateMangopayAddress;
    Nationality: Scalars['String'];
    Birthday: Scalars['Date'];
    Birthplace: CreateMangopayBirthplace;
};
export declare type DeactivateMangopayBankAccountInput = {
    groupId: Scalars['Int'];
    bankAccountId: Scalars['String'];
};
export declare type File = {
    __typename?: 'File';
    id: Scalars['Int'];
    name: Scalars['String'];
    data: Scalars['String'];
    cDate?: Maybe<Scalars['Date']>;
};
export declare type GetMangopayLegalUserByLegalRepr = {
    legalReprId: Scalars['Int'];
    groupId: Scalars['Int'];
};
export declare type Group = {
    __typename?: 'Group';
    id: Scalars['Int'];
    name: Scalars['String'];
    iban?: Maybe<Scalars['String']>;
    users?: Maybe<Array<User>>;
    user?: Maybe<User>;
    mangopayGroup?: Maybe<MangopayGroup>;
    hasMembership?: Maybe<Scalars['Boolean']>;
};
export declare type GroupPreview = {
    __typename?: 'GroupPreview';
    id: Scalars['Int'];
    name: Scalars['String'];
};
export declare type LinkMangopayLegalUserToGroupInput = {
    groupId: Scalars['Int'];
    legalReprId: Scalars['Int'];
};
export declare type LoginInput = {
    email: Scalars['String'];
    password: Scalars['String'];
};
export declare type MailGroupInput = {
    id: Scalars['Int'];
    name: Scalars['String'];
};
export declare type MailListInput = {
    id: Scalars['String'];
    name: Scalars['String'];
};
export declare type MailUserInput = {
    email?: Maybe<Scalars['String']>;
    name?: Maybe<Scalars['String']>;
    userId?: Maybe<Scalars['Int']>;
};
export declare type MangopayAbstractBankAccount = {
    Id: Scalars['String'];
    Type: MangopayBankAccountType;
    OwnerAddress: MangopayAddress;
    OwnerName: Scalars['String'];
    Active: Scalars['Boolean'];
};
export declare type MangopayAddress = {
    __typename?: 'MangopayAddress';
    AddressLine1?: Maybe<Scalars['String']>;
    AddressLine2?: Maybe<Scalars['String']>;
    City?: Maybe<Scalars['String']>;
    Region?: Maybe<Scalars['String']>;
    PostalCode?: Maybe<Scalars['String']>;
    Country?: Maybe<Scalars['String']>;
};
export declare type MangopayBankAccount = MangopayIbanBankAccount | MangopayUsBankAccount | MangopayCaBankAccount | MangopayGbBankAccount | MangopayOtherBankAccount;
export declare enum MangopayBankAccountType {
    IBAN = "IBAN",
    GB = "GB",
    US = "US",
    CA = "CA",
    OTHER = "OTHER"
}
export declare type MangopayBirthplace = {
    __typename?: 'MangopayBirthplace';
    City: Scalars['String'];
    Country: Scalars['String'];
};
export declare type MangopayCaBankAccount = MangopayAbstractBankAccount & {
    __typename?: 'MangopayCaBankAccount';
    Id: Scalars['String'];
    Type: MangopayBankAccountType;
    OwnerAddress: MangopayAddress;
    OwnerName: Scalars['String'];
    Active: Scalars['Boolean'];
    InstitutionNumber: Scalars['String'];
    AccountNumber: Scalars['String'];
    BranchCode: Scalars['String'];
    BankName: Scalars['String'];
};
export declare type MangopayGbBankAccount = MangopayAbstractBankAccount & {
    __typename?: 'MangopayGbBankAccount';
    Id: Scalars['String'];
    Type: MangopayBankAccountType;
    OwnerAddress: MangopayAddress;
    OwnerName: Scalars['String'];
    Active: Scalars['Boolean'];
    SortCode: Scalars['String'];
    AccountNumber: Scalars['String'];
};
export declare type MangopayGroup = {
    __typename?: 'MangopayGroup';
    legalUser?: Maybe<MangopayLegalUser>;
    walletId?: Maybe<Scalars['Int']>;
};
export declare type MangopayIbanBankAccount = MangopayAbstractBankAccount & {
    __typename?: 'MangopayIbanBankAccount';
    Id: Scalars['String'];
    Type: MangopayBankAccountType;
    OwnerAddress: MangopayAddress;
    OwnerName: Scalars['String'];
    Active: Scalars['Boolean'];
    IBAN: Scalars['String'];
    BIC?: Maybe<Scalars['String']>;
};
export declare type MangopayKycDocument = {
    __typename?: 'MangopayKycDocument';
    Id: Scalars['Float'];
    Type: MangopayKycDocumentType;
    Status: MangopayKycDocumentStatus;
    ProcessedDate?: Maybe<Scalars['Date']>;
    RefusedReasonType?: Maybe<MangopayKycDocumentRefusedReasonType>;
    RefusedReasonMessage?: Maybe<Scalars['String']>;
};
export declare type MangopayKycDocumentFilesTypeInput = {
    Type: MangopayKycDocumentType;
    files: Array<Scalars['Upload']>;
};
export declare enum MangopayKycDocumentRefusedReasonType {
    DOCUMENT_UNREADABLE = "DOCUMENT_UNREADABLE",
    DOCUMENT_NOT_ACCEPTED = "DOCUMENT_NOT_ACCEPTED",
    DOCUMENT_HAS_EXPIRED = "DOCUMENT_HAS_EXPIRED",
    DOCUMENT_INCOMPLETE = "DOCUMENT_INCOMPLETE",
    DOCUMENT_MISSING = "DOCUMENT_MISSING",
    DOCUMENT_DO_NOT_MATCH_USER_DATA = "DOCUMENT_DO_NOT_MATCH_USER_DATA",
    DOCUMENT_DO_NOT_MATCH_ACCOUNT_DATA = "DOCUMENT_DO_NOT_MATCH_ACCOUNT_DATA",
    SPECIFIC_CASE = "SPECIFIC_CASE",
    DOCUMENT_FALSIFIED = "DOCUMENT_FALSIFIED",
    UNDERAGE_PERSON = "UNDERAGE_PERSON"
}
export declare enum MangopayKycDocumentStatus {
    CREATED = "CREATED",
    VALIDATION_ASKED = "VALIDATION_ASKED",
    REFUSED = "REFUSED",
    VALIDATED = "VALIDATED"
}
export declare enum MangopayKycDocumentType {
    IDENTITY_PROOF = "IDENTITY_PROOF",
    ARTICLES_OF_ASSOCIATION = "ARTICLES_OF_ASSOCIATION",
    REGISTRATION_PROOF = "REGISTRATION_PROOF",
    SHAREHOLDER_DECLARATION = "SHAREHOLDER_DECLARATION"
}
export declare enum MangopayKycLevel {
    LIGHT = "LIGHT",
    REGULAR = "REGULAR"
}
export declare enum MangopayLegalPersonType {
    ORGANIZATION = "ORGANIZATION",
    BUSINESS = "BUSINESS",
    SOLETRADER = "SOLETRADER"
}
export declare type MangopayLegalUser = {
    __typename?: 'MangopayLegalUser';
    mangopayUserId: Scalars['Float'];
    disabled: Scalars['Boolean'];
    fixedFeeAmount?: Maybe<Scalars['Float']>;
    variableFeeRate?: Maybe<Scalars['Float']>;
    legalRepr?: Maybe<User>;
    bankAccountId?: Maybe<Scalars['Int']>;
    Name: Scalars['String'];
    LegalPersonType: MangopayLegalPersonType;
    LegalRepresentativeFirstName: Scalars['String'];
    LegalRepresentativeLastName: Scalars['String'];
    LegalRepresentativeEmail: Scalars['String'];
    LegalRepresentativeBirthday: Scalars['Date'];
    LegalRepresentativeNationality: Scalars['String'];
    LegalRepresentativeCountryOfResidence: Scalars['String'];
    CompanyNumber: Scalars['String'];
    Email: Scalars['String'];
    KYCLevel: MangopayKycLevel;
    HeadquartersAddress?: Maybe<MangopayAddress>;
    LegalRepresentativeAddress: MangopayAddress;
    KycDocuments?: Maybe<Array<MangopayKycDocument>>;
    UboDeclarations?: Maybe<Array<MangopayUboDeclaration>>;
    BankAccounts?: Maybe<Array<MangopayBankAccount>>;
};
export declare type MangopayOtherBankAccount = MangopayAbstractBankAccount & {
    __typename?: 'MangopayOtherBankAccount';
    Id: Scalars['String'];
    Type: MangopayBankAccountType;
    OwnerAddress: MangopayAddress;
    OwnerName: Scalars['String'];
    Active: Scalars['Boolean'];
    Country: Scalars['String'];
    BIC: Scalars['String'];
    AccountNumber: Scalars['String'];
};
export declare type MangopayUbo = {
    __typename?: 'MangopayUbo';
    Id: Scalars['Int'];
    CreationDate: Scalars['Date'];
    FirstName: Scalars['String'];
    LastName: Scalars['String'];
    Address: MangopayAddress;
    Nationality: Scalars['String'];
    Birthday: Scalars['Date'];
    Birthplace: MangopayBirthplace;
};
export declare type MangopayUboDeclaration = {
    __typename?: 'MangopayUboDeclaration';
    Id: Scalars['Int'];
    CreateDate?: Maybe<Scalars['Date']>;
    ProcessedDate?: Maybe<Scalars['Date']>;
    Status: MangopayUboDeclarationStatus;
    Reason?: Maybe<MangopayUboReasonType>;
    Message?: Maybe<Scalars['String']>;
    Ubos: Array<MangopayUbo>;
};
export declare enum MangopayUboDeclarationStatus {
    CREATED = "CREATED",
    VALIDATION_ASKED = "VALIDATION_ASKED",
    INCOMPLETE = "INCOMPLETE",
    VALIDATED = "VALIDATED",
    REFUSED = "REFUSED"
}
export declare enum MangopayUboReasonType {
    MISSING_UBO = "MISSING_UBO",
    WRONG_UBO_INFORMATION = "WRONG_UBO_INFORMATION",
    UBO_IDENTITY_NEEDED = "UBO_IDENTITY_NEEDED",
    SHAREHOLDERS_DECLARATION_NEEDED = "SHAREHOLDERS_DECLARATION_NEEDED",
    ORGANIZATION_CHART_NEEDED = "ORGANIZATION_CHART_NEEDED",
    DOCUMENTS_NEEDED = "DOCUMENTS_NEEDED",
    DECLARATION_DO_NOT_MATCH_UBO_INFORMATION = "DECLARATION_DO_NOT_MATCH_UBO_INFORMATION",
    SPECIFIC_CASE = "SPECIFIC_CASE"
}
export declare type MangopayUsBankAccount = MangopayAbstractBankAccount & {
    __typename?: 'MangopayUsBankAccount';
    Id: Scalars['String'];
    Type: MangopayBankAccountType;
    OwnerAddress: MangopayAddress;
    OwnerName: Scalars['String'];
    Active: Scalars['Boolean'];
    AccountNumber: Scalars['String'];
    ABA: Scalars['String'];
    DepositAccountType?: Maybe<MangopayUsBankAccountDepositAccountType>;
};
export declare enum MangopayUsBankAccountDepositAccountType {
    CHECKING = "CHECKING",
    SAVINGS = "SAVINGS"
}
export declare type Membership = {
    __typename?: 'Membership';
    user?: Maybe<User>;
    group?: Maybe<Group>;
    date: Scalars['Date'];
    amount: Scalars['Float'];
    distributionId?: Maybe<Scalars['Int']>;
    year: Scalars['Int'];
};
export declare type Message = {
    __typename?: 'Message';
    id: Scalars['Int'];
    title: Scalars['String'];
    body: Scalars['String'];
    date: Scalars['Date'];
    amapId: Scalars['Int'];
    senderId: Scalars['Int'];
    recipients: Array<Scalars['String']>;
    recipientListId?: Maybe<Scalars['String']>;
    attachments?: Maybe<Array<Scalars['String']>>;
    sender: User;
};
export declare type Mutation = {
    __typename?: 'Mutation';
    updateUser: User;
    createMangopayLegalUser: MangopayLegalUser;
    updateMangopayLegalUser: MangopayLegalUser;
    createMangopayKycDocuments: Array<MangopayKycDocument>;
    createMangopayUboDeclaration: MangopayUboDeclaration;
    submitMangopayUboDeclaration: MangopayUboDeclaration;
    createOrUpdateMangopayUbo: MangopayUbo;
    createMangopayIbanBankAccount: MangopayBankAccount;
    deactivateMangopayBankAccount: Scalars['Int'];
    selectMangopayBankAccountId: MangopayLegalUser;
    linkMangopayLegalUserToGroup: MangopayLegalUser;
    login: UserAndToken;
    createMembership: Membership;
    deleteMembership: Array<Membership>;
    createMessage: Message;
};
export declare type MutationUpdateUserArgs = {
    input: UpdateUserInput;
};
export declare type MutationCreateMangopayLegalUserArgs = {
    input: CreateMangopayLegalUserInput;
};
export declare type MutationUpdateMangopayLegalUserArgs = {
    input: UpdateMangopayLegalUserInput;
};
export declare type MutationCreateMangopayKycDocumentsArgs = {
    input: CreateMangopayKycDocumentsInput;
};
export declare type MutationCreateMangopayUboDeclarationArgs = {
    input: CreateMangopayUboDeclarationInput;
};
export declare type MutationSubmitMangopayUboDeclarationArgs = {
    input: SubmitMangopayUboDeclarationInput;
};
export declare type MutationCreateOrUpdateMangopayUboArgs = {
    input: CreateOrUpdateMangopayUboInput;
};
export declare type MutationCreateMangopayIbanBankAccountArgs = {
    input: CreateMangopayIbanBankAccountInput;
};
export declare type MutationDeactivateMangopayBankAccountArgs = {
    input: DeactivateMangopayBankAccountInput;
};
export declare type MutationSelectMangopayBankAccountIdArgs = {
    input: SelectMangopayLegalUserBankAccount;
};
export declare type MutationLinkMangopayLegalUserToGroupArgs = {
    input: LinkMangopayLegalUserToGroupInput;
};
export declare type MutationLoginArgs = {
    input: LoginInput;
};
export declare type MutationCreateMembershipArgs = {
    input: CreateMembershipInput;
};
export declare type MutationDeleteMembershipArgs = {
    year: Scalars['Int'];
    userId: Scalars['Int'];
    groupId: Scalars['Int'];
};
export declare type MutationCreateMessageArgs = {
    input: CreateMessageInput;
};
export declare type Query = {
    __typename?: 'Query';
    me: User;
    user: User;
    isGroupAdmin: Scalars['Boolean'];
    mangopayLegalUser?: Maybe<MangopayLegalUser>;
    mangopayLegalUserByLegalRepr?: Maybe<MangopayLegalUser>;
    mangopayGroup: MangopayGroup;
    group: Group;
    getUserLists: Array<UserList>;
    getUserListInGroupByListType: Array<User>;
    groupPreview: GroupPreview;
    groupPreviews: Array<GroupPreview>;
    groupPreviews2: Array<GroupPreview>;
    getUserMemberships: Array<Membership>;
    catalog: Catalog;
    getActiveContracts: Array<Catalog>;
    getMessagesForGroup: Array<Message>;
    getUserMessagesForGroup: Array<Message>;
    message: Message;
};
export declare type QueryUserArgs = {
    id: Scalars['Int'];
};
export declare type QueryIsGroupAdminArgs = {
    groupId: Scalars['Int'];
};
export declare type QueryMangopayLegalUserArgs = {
    groupId: Scalars['Int'];
};
export declare type QueryMangopayLegalUserByLegalReprArgs = {
    input: GetMangopayLegalUserByLegalRepr;
};
export declare type QueryMangopayGroupArgs = {
    id: Scalars['Int'];
};
export declare type QueryGroupArgs = {
    id: Scalars['Int'];
};
export declare type QueryGetUserListsArgs = {
    groupId: Scalars['Int'];
};
export declare type QueryGetUserListInGroupByListTypeArgs = {
    data?: Maybe<Scalars['String']>;
    groupId: Scalars['Int'];
    listType: Scalars['String'];
};
export declare type QueryGroupPreviewArgs = {
    id: Scalars['Int'];
};
export declare type QueryGetUserMembershipsArgs = {
    userId: Scalars['Int'];
    groupId: Scalars['Int'];
};
export declare type QueryCatalogArgs = {
    id: Scalars['Int'];
};
export declare type QueryGetActiveContractsArgs = {
    groupId: Scalars['Int'];
};
export declare type QueryGetMessagesForGroupArgs = {
    groupId: Scalars['Int'];
};
export declare type QueryGetUserMessagesForGroupArgs = {
    groupId: Scalars['Int'];
};
export declare type QueryMessageArgs = {
    id: Scalars['Int'];
};
export declare type SelectMangopayLegalUserBankAccount = {
    groupId: Scalars['Int'];
    bankAccountId?: Maybe<Scalars['Int']>;
};
export declare type SubmitMangopayUboDeclarationInput = {
    groupId: Scalars['Int'];
    declarationId: Scalars['Int'];
};
export declare type UpdateMangopayLegalUserInput = {
    groupId: Scalars['Int'];
    Name?: Maybe<Scalars['String']>;
    Email?: Maybe<Scalars['String']>;
    LegalPersonType: MangopayLegalPersonType;
    CompanyNumber?: Maybe<Scalars['String']>;
    LegalRepresentativeFirstName?: Maybe<Scalars['String']>;
    LegalRepresentativeLastName?: Maybe<Scalars['String']>;
    LegalRepresentativeEmail?: Maybe<Scalars['String']>;
    LegalRepresentativeBirthday?: Maybe<Scalars['Date']>;
    LegalRepresentativeNationality?: Maybe<Scalars['String']>;
    LegalRepresentativeCountryOfResidence?: Maybe<Scalars['String']>;
    LegalRepresentativeAddress?: Maybe<CreateMangopayAddress>;
    HeadquartersAddress?: Maybe<CreateMangopayAddress>;
};
export declare type UpdateUserInput = {
    id: Scalars['Int'];
    firstName?: Maybe<Scalars['String']>;
    lastName?: Maybe<Scalars['String']>;
};
export declare type User = {
    __typename?: 'User';
    id: Scalars['Int'];
    firstName: Scalars['String'];
    lastName: Scalars['String'];
    email: Scalars['String'];
    address1?: Maybe<Scalars['String']>;
    address2?: Maybe<Scalars['String']>;
    zipCode?: Maybe<Scalars['String']>;
    city?: Maybe<Scalars['String']>;
    nationality?: Maybe<Scalars['String']>;
    countryOfResidence?: Maybe<Scalars['String']>;
    birthDate?: Maybe<Scalars['Date']>;
    email2?: Maybe<Scalars['String']>;
    firstName2?: Maybe<Scalars['String']>;
    lastName2?: Maybe<Scalars['String']>;
};
export declare type UserAndToken = {
    __typename?: 'UserAndToken';
    user: User;
    token: Scalars['String'];
};
export declare type UserList = {
    __typename?: 'UserList';
    type: Scalars['String'];
    count?: Maybe<Scalars['Float']>;
    data?: Maybe<Scalars['String']>;
};
export declare type Vendor = {
    __typename?: 'Vendor';
    id: Scalars['Int'];
    name: Scalars['String'];
    email: Scalars['String'];
    zipCode: Scalars['String'];
    city: Scalars['String'];
    address1?: Maybe<Scalars['String']>;
    address2?: Maybe<Scalars['String']>;
    imageId?: Maybe<Scalars['Int']>;
    image: File;
};
export declare type UserFragment = ({
    __typename?: 'User';
} & Pick<User, 'id' | 'firstName' | 'lastName' | 'address1' | 'address2' | 'zipCode' | 'city' | 'nationality' | 'countryOfResidence' | 'birthDate' | 'email' | 'email2' | 'firstName2' | 'lastName2'>);
export declare type LoginMutationVariables = {
    input: LoginInput;
};
export declare type LoginMutation = ({
    __typename?: 'Mutation';
} & {
    login: ({
        __typename?: 'UserAndToken';
    } & Pick<UserAndToken, 'token'> & {
        user: ({
            __typename?: 'User';
        } & UserFragment);
    });
});
export declare type MeQueryVariables = {};
export declare type MeQuery = ({
    __typename?: 'Query';
} & {
    me: ({
        __typename?: 'User';
    } & UserFragment);
});
export declare type GroupPreviewQueryVariables = {
    id: Scalars['Int'];
};
export declare type GroupPreviewQuery = ({
    __typename?: 'Query';
} & {
    groupPreview: ({
        __typename?: 'GroupPreview';
    } & Pick<GroupPreview, 'id' | 'name'>);
});
export declare type GetUserMembershipsQueryVariables = {
    userId: Scalars['Int'];
    groupId: Scalars['Int'];
};
export declare type GetUserMembershipsQuery = ({
    __typename?: 'Query';
} & {
    getUserMemberships: Array<({
        __typename?: 'Membership';
    } & Pick<Membership, 'year'> & {
        user?: Maybe<({
            __typename?: 'User';
        } & Pick<User, 'id' | 'firstName' | 'lastName' | 'email'>)>;
        group?: Maybe<({
            __typename?: 'Group';
        } & Pick<Group, 'id' | 'name'>)>;
    })>;
});
export declare type IsGroupAdminQueryVariables = {
    groupId: Scalars['Int'];
};
export declare type IsGroupAdminQuery = ({
    __typename?: 'Query';
} & Pick<Query, 'isGroupAdmin'>);
export declare type MangopayAddressFragment = ({
    __typename?: 'MangopayAddress';
} & Pick<MangopayAddress, 'AddressLine1' | 'AddressLine2' | 'City' | 'PostalCode' | 'Country'>);
export declare type MangopayBirthplaceFragment = ({
    __typename?: 'MangopayBirthplace';
} & Pick<MangopayBirthplace, 'City' | 'Country'>);
export declare type MangopayKycDocumentFragment = ({
    __typename?: 'MangopayKycDocument';
} & Pick<MangopayKycDocument, 'Id' | 'Type' | 'ProcessedDate' | 'Status' | 'RefusedReasonType' | 'RefusedReasonMessage'>);
export declare type MangopayUboFragment = ({
    __typename?: 'MangopayUbo';
} & Pick<MangopayUbo, 'Id' | 'CreationDate' | 'FirstName' | 'LastName' | 'Nationality' | 'Birthday'> & {
    Address: ({
        __typename?: 'MangopayAddress';
    } & MangopayAddressFragment);
    Birthplace: ({
        __typename?: 'MangopayBirthplace';
    } & MangopayBirthplaceFragment);
});
export declare type MangopayUboDeclarationFragment = ({
    __typename?: 'MangopayUboDeclaration';
} & Pick<MangopayUboDeclaration, 'Id' | 'Status' | 'Reason' | 'Message'> & {
    Ubos: Array<({
        __typename?: 'MangopayUbo';
    } & MangopayUboFragment)>;
});
export declare type MangopayIbanBankAccountFragment = ({
    __typename?: 'MangopayIbanBankAccount';
} & Pick<MangopayIbanBankAccount, 'Id' | 'Type' | 'OwnerName' | 'Active' | 'IBAN' | 'BIC'> & {
    OwnerAddress: ({
        __typename?: 'MangopayAddress';
    } & MangopayAddressFragment);
});
export declare type MangopayLegalUserFragment = ({
    __typename?: 'MangopayLegalUser';
} & Pick<MangopayLegalUser, 'bankAccountId' | 'KYCLevel' | 'Name' | 'CompanyNumber' | 'Email' | 'LegalPersonType' | 'LegalRepresentativeFirstName' | 'LegalRepresentativeLastName' | 'LegalRepresentativeEmail' | 'LegalRepresentativeBirthday' | 'LegalRepresentativeNationality' | 'LegalRepresentativeCountryOfResidence'> & {
    HeadquartersAddress?: Maybe<({
        __typename?: 'MangopayAddress';
    } & MangopayAddressFragment)>;
    LegalRepresentativeAddress: ({
        __typename?: 'MangopayAddress';
    } & MangopayAddressFragment);
    KycDocuments?: Maybe<Array<({
        __typename?: 'MangopayKycDocument';
    } & MangopayKycDocumentFragment)>>;
    UboDeclarations?: Maybe<Array<({
        __typename?: 'MangopayUboDeclaration';
    } & MangopayUboDeclarationFragment)>>;
    BankAccounts?: Maybe<Array<({
        __typename?: 'MangopayIbanBankAccount';
    } & MangopayIbanBankAccountFragment) | {
        __typename?: 'MangopayUsBankAccount';
    } | {
        __typename?: 'MangopayCaBankAccount';
    } | {
        __typename?: 'MangopayGbBankAccount';
    } | {
        __typename?: 'MangopayOtherBankAccount';
    }>>;
    legalRepr?: Maybe<({
        __typename?: 'User';
    } & Pick<User, 'id' | 'firstName' | 'lastName' | 'email' | 'address1' | 'address2' | 'zipCode' | 'city' | 'nationality' | 'countryOfResidence' | 'birthDate'>)>;
});
export declare type MangopayGroupQueryVariables = {
    id: Scalars['Int'];
};
export declare type MangopayGroupQuery = ({
    __typename?: 'Query';
} & {
    group: ({
        __typename?: 'Group';
    } & Pick<Group, 'id'> & {
        mangopayGroup?: Maybe<({
            __typename?: 'MangopayGroup';
        } & {
            legalUser?: Maybe<({
                __typename?: 'MangopayLegalUser';
            } & Pick<MangopayLegalUser, 'KYCLevel'>)>;
        })>;
    });
});
export declare type MangopayGroupConfigQueryVariables = {
    id: Scalars['Int'];
};
export declare type MangopayGroupConfigQuery = ({
    __typename?: 'Query';
} & {
    group: ({
        __typename?: 'Group';
    } & Pick<Group, 'id'> & {
        users?: Maybe<Array<({
            __typename?: 'User';
        } & Pick<User, 'id' | 'firstName' | 'lastName' | 'email' | 'address1' | 'address2' | 'zipCode' | 'city' | 'nationality' | 'countryOfResidence' | 'birthDate'>)>>;
        mangopayGroup?: Maybe<({
            __typename?: 'MangopayGroup';
        } & {
            legalUser?: Maybe<({
                __typename?: 'MangopayLegalUser';
            } & MangopayLegalUserFragment)>;
        })>;
    });
});
export declare type MangopayLegalUserByLegalReprQueryVariables = {
    input: GetMangopayLegalUserByLegalRepr;
};
export declare type MangopayLegalUserByLegalReprQuery = ({
    __typename?: 'Query';
} & {
    mangopayLegalUserByLegalRepr?: Maybe<({
        __typename?: 'MangopayLegalUser';
    } & MangopayLegalUserFragment)>;
});
export declare type CreateMangopayLegalUserMutationVariables = {
    input: CreateMangopayLegalUserInput;
};
export declare type CreateMangopayLegalUserMutation = ({
    __typename?: 'Mutation';
} & {
    createMangopayLegalUser: ({
        __typename?: 'MangopayLegalUser';
    } & MangopayLegalUserFragment);
});
export declare type UpdateMangopayLegalUserMutationVariables = {
    input: UpdateMangopayLegalUserInput;
};
export declare type UpdateMangopayLegalUserMutation = ({
    __typename?: 'Mutation';
} & {
    updateMangopayLegalUser: ({
        __typename?: 'MangopayLegalUser';
    } & MangopayLegalUserFragment);
});
export declare type LinkMangopayLegalUserToGroupMutationVariables = {
    input: LinkMangopayLegalUserToGroupInput;
};
export declare type LinkMangopayLegalUserToGroupMutation = ({
    __typename?: 'Mutation';
} & {
    linkMangopayLegalUserToGroup: ({
        __typename?: 'MangopayLegalUser';
    } & MangopayLegalUserFragment);
});
export declare type CreateMangopayKycDocumentsMutationVariables = {
    input: CreateMangopayKycDocumentsInput;
};
export declare type CreateMangopayKycDocumentsMutation = ({
    __typename?: 'Mutation';
} & {
    createMangopayKycDocuments: Array<({
        __typename?: 'MangopayKycDocument';
    } & MangopayKycDocumentFragment)>;
});
export declare type CreateMangopayUboDeclarationMutationVariables = {
    input: CreateMangopayUboDeclarationInput;
};
export declare type CreateMangopayUboDeclarationMutation = ({
    __typename?: 'Mutation';
} & {
    createMangopayUboDeclaration: ({
        __typename?: 'MangopayUboDeclaration';
    } & MangopayUboDeclarationFragment);
});
export declare type SubmitMangopayUboDeclarationMutationVariables = {
    input: SubmitMangopayUboDeclarationInput;
};
export declare type SubmitMangopayUboDeclarationMutation = ({
    __typename?: 'Mutation';
} & {
    submitMangopayUboDeclaration: ({
        __typename?: 'MangopayUboDeclaration';
    } & MangopayUboDeclarationFragment);
});
export declare type CreateOrUpdateMangopayUboMutationVariables = {
    input: CreateOrUpdateMangopayUboInput;
};
export declare type CreateOrUpdateMangopayUboMutation = ({
    __typename?: 'Mutation';
} & {
    createOrUpdateMangopayUbo: ({
        __typename?: 'MangopayUbo';
    } & MangopayUboFragment);
});
export declare type CreateMangopayIbanBankAccountMutationVariables = {
    input: CreateMangopayIbanBankAccountInput;
};
export declare type CreateMangopayIbanBankAccountMutation = ({
    __typename?: 'Mutation';
} & {
    createMangopayIbanBankAccount: ({
        __typename?: 'MangopayIbanBankAccount';
    } & MangopayIbanBankAccountFragment) | {
        __typename?: 'MangopayUsBankAccount';
    } | {
        __typename?: 'MangopayCaBankAccount';
    } | {
        __typename?: 'MangopayGbBankAccount';
    } | {
        __typename?: 'MangopayOtherBankAccount';
    };
});
export declare type DeactivateMangopayBankAccountMutationVariables = {
    input: DeactivateMangopayBankAccountInput;
};
export declare type DeactivateMangopayBankAccountMutation = ({
    __typename?: 'Mutation';
} & Pick<Mutation, 'deactivateMangopayBankAccount'>);
export declare type SelectMangopayBankAccountIdMutationVariables = {
    input: SelectMangopayLegalUserBankAccount;
};
export declare type SelectMangopayBankAccountIdMutation = ({
    __typename?: 'Mutation';
} & {
    selectMangopayBankAccountId: ({
        __typename?: 'MangopayLegalUser';
    } & Pick<MangopayLegalUser, 'mangopayUserId' | 'bankAccountId'>);
});
export declare type MessagesGroupQueryVariables = {
    id: Scalars['Int'];
};
export declare type MessagesGroupQuery = ({
    __typename?: 'Query';
} & {
    group: ({
        __typename?: 'Group';
    } & Pick<Group, 'id' | 'name' | 'hasMembership'>);
});
export declare type UserListsQueryVariables = {
    groupId: Scalars['Int'];
};
export declare type UserListsQuery = ({
    __typename?: 'Query';
} & {
    getUserLists: Array<({
        __typename?: 'UserList';
    } & Pick<UserList, 'type' | 'count' | 'data'>)>;
});
export declare type GetUserListInGroupByListTypeQueryVariables = {
    listType: Scalars['String'];
    groupId: Scalars['Int'];
    data?: Maybe<Scalars['String']>;
};
export declare type GetUserListInGroupByListTypeQuery = ({
    __typename?: 'Query';
} & {
    getUserListInGroupByListType: Array<({
        __typename?: 'User';
    } & Pick<User, 'id' | 'firstName' | 'lastName' | 'firstName2' | 'lastName2' | 'email' | 'email2'>)>;
});
export declare type CreateMessageMutationVariables = {
    input: CreateMessageInput;
};
export declare type CreateMessageMutation = ({
    __typename?: 'Mutation';
} & {
    createMessage: ({
        __typename?: 'Message';
    } & Pick<Message, 'id'>);
});
export declare type GetMessagesForGroupQueryVariables = {
    groupId: Scalars['Int'];
};
export declare type GetMessagesForGroupQuery = ({
    __typename?: 'Query';
} & {
    getMessagesForGroup: Array<({
        __typename?: 'Message';
    } & Pick<Message, 'id' | 'title' | 'date'>)>;
});
export declare type GetUserMessagesForGroupQueryVariables = {
    groupId: Scalars['Int'];
};
export declare type GetUserMessagesForGroupQuery = ({
    __typename?: 'Query';
} & {
    getUserMessagesForGroup: Array<({
        __typename?: 'Message';
    } & Pick<Message, 'id' | 'title' | 'date'>)>;
});
export declare type GetMessageByIdQueryVariables = {
    id: Scalars['Int'];
};
export declare type GetMessageByIdQuery = ({
    __typename?: 'Query';
} & {
    message: ({
        __typename?: 'Message';
    } & Pick<Message, 'id' | 'title' | 'date' | 'recipientListId' | 'body' | 'recipients' | 'attachments'> & {
        sender: ({
            __typename?: 'User';
        } & Pick<User, 'id' | 'firstName' | 'lastName'>);
    });
});
export declare type GetActiveContractsQueryVariables = {
    groupId: Scalars['Int'];
};
export declare type GetActiveContractsQuery = ({
    __typename?: 'Query';
} & {
    getActiveContracts: Array<({
        __typename?: 'Catalog';
    } & {
        vendor: ({
            __typename?: 'Vendor';
        } & Pick<Vendor, 'name'> & {
            image: ({
                __typename?: 'File';
            } & Pick<File, 'data'>);
        });
    })>;
});
export declare const UserFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayAddressFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayKycDocumentFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayBirthplaceFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayUboFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayUboDeclarationFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayIbanBankAccountFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const MangopayLegalUserFragmentDoc: ApolloReactHooks.DocumentNode;
export declare const LoginDocument: ApolloReactHooks.DocumentNode;
export declare type LoginMutationFn = ApolloReactCommon.MutationFunction<LoginMutation, LoginMutationVariables>;
/**
 * __useLoginMutation__
 *
 * To run a mutation, you first call `useLoginMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useLoginMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [loginMutation, { data, loading, error }] = useLoginMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useLoginMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<LoginMutation, LoginMutationVariables>): ApolloReactHooks.MutationTuple<LoginMutation, LoginMutationVariables>;
export declare type LoginMutationHookResult = ReturnType<typeof useLoginMutation>;
export declare type LoginMutationResult = ApolloReactCommon.MutationResult<LoginMutation>;
export declare type LoginMutationOptions = ApolloReactCommon.BaseMutationOptions<LoginMutation, LoginMutationVariables>;
export declare const MeDocument: ApolloReactHooks.DocumentNode;
/**
 * __useMeQuery__
 *
 * To run a query within a React component, call `useMeQuery` and pass it any options that fit your needs.
 * When your component renders, `useMeQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useMeQuery({
 *   variables: {
 *   },
 * });
 */
export declare function useMeQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<MeQuery, MeQueryVariables>): ApolloReactHooks.QueryResult<MeQuery, MeQueryVariables>;
export declare function useMeLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<MeQuery, MeQueryVariables>): ApolloReactHooks.QueryTuple<MeQuery, MeQueryVariables>;
export declare type MeQueryHookResult = ReturnType<typeof useMeQuery>;
export declare type MeLazyQueryHookResult = ReturnType<typeof useMeLazyQuery>;
export declare type MeQueryResult = ApolloReactCommon.QueryResult<MeQuery, MeQueryVariables>;
export declare const GroupPreviewDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGroupPreviewQuery__
 *
 * To run a query within a React component, call `useGroupPreviewQuery` and pass it any options that fit your needs.
 * When your component renders, `useGroupPreviewQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGroupPreviewQuery({
 *   variables: {
 *      id: // value for 'id'
 *   },
 * });
 */
export declare function useGroupPreviewQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GroupPreviewQuery, GroupPreviewQueryVariables>): ApolloReactHooks.QueryResult<GroupPreviewQuery, GroupPreviewQueryVariables>;
export declare function useGroupPreviewLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GroupPreviewQuery, GroupPreviewQueryVariables>): ApolloReactHooks.QueryTuple<GroupPreviewQuery, GroupPreviewQueryVariables>;
export declare type GroupPreviewQueryHookResult = ReturnType<typeof useGroupPreviewQuery>;
export declare type GroupPreviewLazyQueryHookResult = ReturnType<typeof useGroupPreviewLazyQuery>;
export declare type GroupPreviewQueryResult = ApolloReactCommon.QueryResult<GroupPreviewQuery, GroupPreviewQueryVariables>;
export declare const GetUserMembershipsDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGetUserMembershipsQuery__
 *
 * To run a query within a React component, call `useGetUserMembershipsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetUserMembershipsQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetUserMembershipsQuery({
 *   variables: {
 *      userId: // value for 'userId'
 *      groupId: // value for 'groupId'
 *   },
 * });
 */
export declare function useGetUserMembershipsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetUserMembershipsQuery, GetUserMembershipsQueryVariables>): ApolloReactHooks.QueryResult<GetUserMembershipsQuery, GetUserMembershipsQueryVariables>;
export declare function useGetUserMembershipsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetUserMembershipsQuery, GetUserMembershipsQueryVariables>): ApolloReactHooks.QueryTuple<GetUserMembershipsQuery, GetUserMembershipsQueryVariables>;
export declare type GetUserMembershipsQueryHookResult = ReturnType<typeof useGetUserMembershipsQuery>;
export declare type GetUserMembershipsLazyQueryHookResult = ReturnType<typeof useGetUserMembershipsLazyQuery>;
export declare type GetUserMembershipsQueryResult = ApolloReactCommon.QueryResult<GetUserMembershipsQuery, GetUserMembershipsQueryVariables>;
export declare const IsGroupAdminDocument: ApolloReactHooks.DocumentNode;
/**
 * __useIsGroupAdminQuery__
 *
 * To run a query within a React component, call `useIsGroupAdminQuery` and pass it any options that fit your needs.
 * When your component renders, `useIsGroupAdminQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useIsGroupAdminQuery({
 *   variables: {
 *      groupId: // value for 'groupId'
 *   },
 * });
 */
export declare function useIsGroupAdminQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<IsGroupAdminQuery, IsGroupAdminQueryVariables>): ApolloReactHooks.QueryResult<IsGroupAdminQuery, IsGroupAdminQueryVariables>;
export declare function useIsGroupAdminLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<IsGroupAdminQuery, IsGroupAdminQueryVariables>): ApolloReactHooks.QueryTuple<IsGroupAdminQuery, IsGroupAdminQueryVariables>;
export declare type IsGroupAdminQueryHookResult = ReturnType<typeof useIsGroupAdminQuery>;
export declare type IsGroupAdminLazyQueryHookResult = ReturnType<typeof useIsGroupAdminLazyQuery>;
export declare type IsGroupAdminQueryResult = ApolloReactCommon.QueryResult<IsGroupAdminQuery, IsGroupAdminQueryVariables>;
export declare const MangopayGroupDocument: ApolloReactHooks.DocumentNode;
/**
 * __useMangopayGroupQuery__
 *
 * To run a query within a React component, call `useMangopayGroupQuery` and pass it any options that fit your needs.
 * When your component renders, `useMangopayGroupQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useMangopayGroupQuery({
 *   variables: {
 *      id: // value for 'id'
 *   },
 * });
 */
export declare function useMangopayGroupQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<MangopayGroupQuery, MangopayGroupQueryVariables>): ApolloReactHooks.QueryResult<MangopayGroupQuery, MangopayGroupQueryVariables>;
export declare function useMangopayGroupLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<MangopayGroupQuery, MangopayGroupQueryVariables>): ApolloReactHooks.QueryTuple<MangopayGroupQuery, MangopayGroupQueryVariables>;
export declare type MangopayGroupQueryHookResult = ReturnType<typeof useMangopayGroupQuery>;
export declare type MangopayGroupLazyQueryHookResult = ReturnType<typeof useMangopayGroupLazyQuery>;
export declare type MangopayGroupQueryResult = ApolloReactCommon.QueryResult<MangopayGroupQuery, MangopayGroupQueryVariables>;
export declare const MangopayGroupConfigDocument: ApolloReactHooks.DocumentNode;
/**
 * __useMangopayGroupConfigQuery__
 *
 * To run a query within a React component, call `useMangopayGroupConfigQuery` and pass it any options that fit your needs.
 * When your component renders, `useMangopayGroupConfigQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useMangopayGroupConfigQuery({
 *   variables: {
 *      id: // value for 'id'
 *   },
 * });
 */
export declare function useMangopayGroupConfigQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<MangopayGroupConfigQuery, MangopayGroupConfigQueryVariables>): ApolloReactHooks.QueryResult<MangopayGroupConfigQuery, MangopayGroupConfigQueryVariables>;
export declare function useMangopayGroupConfigLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<MangopayGroupConfigQuery, MangopayGroupConfigQueryVariables>): ApolloReactHooks.QueryTuple<MangopayGroupConfigQuery, MangopayGroupConfigQueryVariables>;
export declare type MangopayGroupConfigQueryHookResult = ReturnType<typeof useMangopayGroupConfigQuery>;
export declare type MangopayGroupConfigLazyQueryHookResult = ReturnType<typeof useMangopayGroupConfigLazyQuery>;
export declare type MangopayGroupConfigQueryResult = ApolloReactCommon.QueryResult<MangopayGroupConfigQuery, MangopayGroupConfigQueryVariables>;
export declare const MangopayLegalUserByLegalReprDocument: ApolloReactHooks.DocumentNode;
/**
 * __useMangopayLegalUserByLegalReprQuery__
 *
 * To run a query within a React component, call `useMangopayLegalUserByLegalReprQuery` and pass it any options that fit your needs.
 * When your component renders, `useMangopayLegalUserByLegalReprQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useMangopayLegalUserByLegalReprQuery({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useMangopayLegalUserByLegalReprQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<MangopayLegalUserByLegalReprQuery, MangopayLegalUserByLegalReprQueryVariables>): ApolloReactHooks.QueryResult<MangopayLegalUserByLegalReprQuery, MangopayLegalUserByLegalReprQueryVariables>;
export declare function useMangopayLegalUserByLegalReprLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<MangopayLegalUserByLegalReprQuery, MangopayLegalUserByLegalReprQueryVariables>): ApolloReactHooks.QueryTuple<MangopayLegalUserByLegalReprQuery, MangopayLegalUserByLegalReprQueryVariables>;
export declare type MangopayLegalUserByLegalReprQueryHookResult = ReturnType<typeof useMangopayLegalUserByLegalReprQuery>;
export declare type MangopayLegalUserByLegalReprLazyQueryHookResult = ReturnType<typeof useMangopayLegalUserByLegalReprLazyQuery>;
export declare type MangopayLegalUserByLegalReprQueryResult = ApolloReactCommon.QueryResult<MangopayLegalUserByLegalReprQuery, MangopayLegalUserByLegalReprQueryVariables>;
export declare const CreateMangopayLegalUserDocument: ApolloReactHooks.DocumentNode;
export declare type CreateMangopayLegalUserMutationFn = ApolloReactCommon.MutationFunction<CreateMangopayLegalUserMutation, CreateMangopayLegalUserMutationVariables>;
/**
 * __useCreateMangopayLegalUserMutation__
 *
 * To run a mutation, you first call `useCreateMangopayLegalUserMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateMangopayLegalUserMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createMangopayLegalUserMutation, { data, loading, error }] = useCreateMangopayLegalUserMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useCreateMangopayLegalUserMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CreateMangopayLegalUserMutation, CreateMangopayLegalUserMutationVariables>): ApolloReactHooks.MutationTuple<CreateMangopayLegalUserMutation, CreateMangopayLegalUserMutationVariables>;
export declare type CreateMangopayLegalUserMutationHookResult = ReturnType<typeof useCreateMangopayLegalUserMutation>;
export declare type CreateMangopayLegalUserMutationResult = ApolloReactCommon.MutationResult<CreateMangopayLegalUserMutation>;
export declare type CreateMangopayLegalUserMutationOptions = ApolloReactCommon.BaseMutationOptions<CreateMangopayLegalUserMutation, CreateMangopayLegalUserMutationVariables>;
export declare const UpdateMangopayLegalUserDocument: ApolloReactHooks.DocumentNode;
export declare type UpdateMangopayLegalUserMutationFn = ApolloReactCommon.MutationFunction<UpdateMangopayLegalUserMutation, UpdateMangopayLegalUserMutationVariables>;
/**
 * __useUpdateMangopayLegalUserMutation__
 *
 * To run a mutation, you first call `useUpdateMangopayLegalUserMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useUpdateMangopayLegalUserMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [updateMangopayLegalUserMutation, { data, loading, error }] = useUpdateMangopayLegalUserMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useUpdateMangopayLegalUserMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<UpdateMangopayLegalUserMutation, UpdateMangopayLegalUserMutationVariables>): ApolloReactHooks.MutationTuple<UpdateMangopayLegalUserMutation, UpdateMangopayLegalUserMutationVariables>;
export declare type UpdateMangopayLegalUserMutationHookResult = ReturnType<typeof useUpdateMangopayLegalUserMutation>;
export declare type UpdateMangopayLegalUserMutationResult = ApolloReactCommon.MutationResult<UpdateMangopayLegalUserMutation>;
export declare type UpdateMangopayLegalUserMutationOptions = ApolloReactCommon.BaseMutationOptions<UpdateMangopayLegalUserMutation, UpdateMangopayLegalUserMutationVariables>;
export declare const LinkMangopayLegalUserToGroupDocument: ApolloReactHooks.DocumentNode;
export declare type LinkMangopayLegalUserToGroupMutationFn = ApolloReactCommon.MutationFunction<LinkMangopayLegalUserToGroupMutation, LinkMangopayLegalUserToGroupMutationVariables>;
/**
 * __useLinkMangopayLegalUserToGroupMutation__
 *
 * To run a mutation, you first call `useLinkMangopayLegalUserToGroupMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useLinkMangopayLegalUserToGroupMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [linkMangopayLegalUserToGroupMutation, { data, loading, error }] = useLinkMangopayLegalUserToGroupMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useLinkMangopayLegalUserToGroupMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<LinkMangopayLegalUserToGroupMutation, LinkMangopayLegalUserToGroupMutationVariables>): ApolloReactHooks.MutationTuple<LinkMangopayLegalUserToGroupMutation, LinkMangopayLegalUserToGroupMutationVariables>;
export declare type LinkMangopayLegalUserToGroupMutationHookResult = ReturnType<typeof useLinkMangopayLegalUserToGroupMutation>;
export declare type LinkMangopayLegalUserToGroupMutationResult = ApolloReactCommon.MutationResult<LinkMangopayLegalUserToGroupMutation>;
export declare type LinkMangopayLegalUserToGroupMutationOptions = ApolloReactCommon.BaseMutationOptions<LinkMangopayLegalUserToGroupMutation, LinkMangopayLegalUserToGroupMutationVariables>;
export declare const CreateMangopayKycDocumentsDocument: ApolloReactHooks.DocumentNode;
export declare type CreateMangopayKycDocumentsMutationFn = ApolloReactCommon.MutationFunction<CreateMangopayKycDocumentsMutation, CreateMangopayKycDocumentsMutationVariables>;
/**
 * __useCreateMangopayKycDocumentsMutation__
 *
 * To run a mutation, you first call `useCreateMangopayKycDocumentsMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateMangopayKycDocumentsMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createMangopayKycDocumentsMutation, { data, loading, error }] = useCreateMangopayKycDocumentsMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useCreateMangopayKycDocumentsMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CreateMangopayKycDocumentsMutation, CreateMangopayKycDocumentsMutationVariables>): ApolloReactHooks.MutationTuple<CreateMangopayKycDocumentsMutation, CreateMangopayKycDocumentsMutationVariables>;
export declare type CreateMangopayKycDocumentsMutationHookResult = ReturnType<typeof useCreateMangopayKycDocumentsMutation>;
export declare type CreateMangopayKycDocumentsMutationResult = ApolloReactCommon.MutationResult<CreateMangopayKycDocumentsMutation>;
export declare type CreateMangopayKycDocumentsMutationOptions = ApolloReactCommon.BaseMutationOptions<CreateMangopayKycDocumentsMutation, CreateMangopayKycDocumentsMutationVariables>;
export declare const CreateMangopayUboDeclarationDocument: ApolloReactHooks.DocumentNode;
export declare type CreateMangopayUboDeclarationMutationFn = ApolloReactCommon.MutationFunction<CreateMangopayUboDeclarationMutation, CreateMangopayUboDeclarationMutationVariables>;
/**
 * __useCreateMangopayUboDeclarationMutation__
 *
 * To run a mutation, you first call `useCreateMangopayUboDeclarationMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateMangopayUboDeclarationMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createMangopayUboDeclarationMutation, { data, loading, error }] = useCreateMangopayUboDeclarationMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useCreateMangopayUboDeclarationMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CreateMangopayUboDeclarationMutation, CreateMangopayUboDeclarationMutationVariables>): ApolloReactHooks.MutationTuple<CreateMangopayUboDeclarationMutation, CreateMangopayUboDeclarationMutationVariables>;
export declare type CreateMangopayUboDeclarationMutationHookResult = ReturnType<typeof useCreateMangopayUboDeclarationMutation>;
export declare type CreateMangopayUboDeclarationMutationResult = ApolloReactCommon.MutationResult<CreateMangopayUboDeclarationMutation>;
export declare type CreateMangopayUboDeclarationMutationOptions = ApolloReactCommon.BaseMutationOptions<CreateMangopayUboDeclarationMutation, CreateMangopayUboDeclarationMutationVariables>;
export declare const SubmitMangopayUboDeclarationDocument: ApolloReactHooks.DocumentNode;
export declare type SubmitMangopayUboDeclarationMutationFn = ApolloReactCommon.MutationFunction<SubmitMangopayUboDeclarationMutation, SubmitMangopayUboDeclarationMutationVariables>;
/**
 * __useSubmitMangopayUboDeclarationMutation__
 *
 * To run a mutation, you first call `useSubmitMangopayUboDeclarationMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useSubmitMangopayUboDeclarationMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [submitMangopayUboDeclarationMutation, { data, loading, error }] = useSubmitMangopayUboDeclarationMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useSubmitMangopayUboDeclarationMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<SubmitMangopayUboDeclarationMutation, SubmitMangopayUboDeclarationMutationVariables>): ApolloReactHooks.MutationTuple<SubmitMangopayUboDeclarationMutation, SubmitMangopayUboDeclarationMutationVariables>;
export declare type SubmitMangopayUboDeclarationMutationHookResult = ReturnType<typeof useSubmitMangopayUboDeclarationMutation>;
export declare type SubmitMangopayUboDeclarationMutationResult = ApolloReactCommon.MutationResult<SubmitMangopayUboDeclarationMutation>;
export declare type SubmitMangopayUboDeclarationMutationOptions = ApolloReactCommon.BaseMutationOptions<SubmitMangopayUboDeclarationMutation, SubmitMangopayUboDeclarationMutationVariables>;
export declare const CreateOrUpdateMangopayUboDocument: ApolloReactHooks.DocumentNode;
export declare type CreateOrUpdateMangopayUboMutationFn = ApolloReactCommon.MutationFunction<CreateOrUpdateMangopayUboMutation, CreateOrUpdateMangopayUboMutationVariables>;
/**
 * __useCreateOrUpdateMangopayUboMutation__
 *
 * To run a mutation, you first call `useCreateOrUpdateMangopayUboMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateOrUpdateMangopayUboMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createOrUpdateMangopayUboMutation, { data, loading, error }] = useCreateOrUpdateMangopayUboMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useCreateOrUpdateMangopayUboMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CreateOrUpdateMangopayUboMutation, CreateOrUpdateMangopayUboMutationVariables>): ApolloReactHooks.MutationTuple<CreateOrUpdateMangopayUboMutation, CreateOrUpdateMangopayUboMutationVariables>;
export declare type CreateOrUpdateMangopayUboMutationHookResult = ReturnType<typeof useCreateOrUpdateMangopayUboMutation>;
export declare type CreateOrUpdateMangopayUboMutationResult = ApolloReactCommon.MutationResult<CreateOrUpdateMangopayUboMutation>;
export declare type CreateOrUpdateMangopayUboMutationOptions = ApolloReactCommon.BaseMutationOptions<CreateOrUpdateMangopayUboMutation, CreateOrUpdateMangopayUboMutationVariables>;
export declare const CreateMangopayIbanBankAccountDocument: ApolloReactHooks.DocumentNode;
export declare type CreateMangopayIbanBankAccountMutationFn = ApolloReactCommon.MutationFunction<CreateMangopayIbanBankAccountMutation, CreateMangopayIbanBankAccountMutationVariables>;
/**
 * __useCreateMangopayIbanBankAccountMutation__
 *
 * To run a mutation, you first call `useCreateMangopayIbanBankAccountMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateMangopayIbanBankAccountMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createMangopayIbanBankAccountMutation, { data, loading, error }] = useCreateMangopayIbanBankAccountMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useCreateMangopayIbanBankAccountMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CreateMangopayIbanBankAccountMutation, CreateMangopayIbanBankAccountMutationVariables>): ApolloReactHooks.MutationTuple<CreateMangopayIbanBankAccountMutation, CreateMangopayIbanBankAccountMutationVariables>;
export declare type CreateMangopayIbanBankAccountMutationHookResult = ReturnType<typeof useCreateMangopayIbanBankAccountMutation>;
export declare type CreateMangopayIbanBankAccountMutationResult = ApolloReactCommon.MutationResult<CreateMangopayIbanBankAccountMutation>;
export declare type CreateMangopayIbanBankAccountMutationOptions = ApolloReactCommon.BaseMutationOptions<CreateMangopayIbanBankAccountMutation, CreateMangopayIbanBankAccountMutationVariables>;
export declare const DeactivateMangopayBankAccountDocument: ApolloReactHooks.DocumentNode;
export declare type DeactivateMangopayBankAccountMutationFn = ApolloReactCommon.MutationFunction<DeactivateMangopayBankAccountMutation, DeactivateMangopayBankAccountMutationVariables>;
/**
 * __useDeactivateMangopayBankAccountMutation__
 *
 * To run a mutation, you first call `useDeactivateMangopayBankAccountMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useDeactivateMangopayBankAccountMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [deactivateMangopayBankAccountMutation, { data, loading, error }] = useDeactivateMangopayBankAccountMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useDeactivateMangopayBankAccountMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<DeactivateMangopayBankAccountMutation, DeactivateMangopayBankAccountMutationVariables>): ApolloReactHooks.MutationTuple<DeactivateMangopayBankAccountMutation, DeactivateMangopayBankAccountMutationVariables>;
export declare type DeactivateMangopayBankAccountMutationHookResult = ReturnType<typeof useDeactivateMangopayBankAccountMutation>;
export declare type DeactivateMangopayBankAccountMutationResult = ApolloReactCommon.MutationResult<DeactivateMangopayBankAccountMutation>;
export declare type DeactivateMangopayBankAccountMutationOptions = ApolloReactCommon.BaseMutationOptions<DeactivateMangopayBankAccountMutation, DeactivateMangopayBankAccountMutationVariables>;
export declare const SelectMangopayBankAccountIdDocument: ApolloReactHooks.DocumentNode;
export declare type SelectMangopayBankAccountIdMutationFn = ApolloReactCommon.MutationFunction<SelectMangopayBankAccountIdMutation, SelectMangopayBankAccountIdMutationVariables>;
/**
 * __useSelectMangopayBankAccountIdMutation__
 *
 * To run a mutation, you first call `useSelectMangopayBankAccountIdMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useSelectMangopayBankAccountIdMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [selectMangopayBankAccountIdMutation, { data, loading, error }] = useSelectMangopayBankAccountIdMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useSelectMangopayBankAccountIdMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<SelectMangopayBankAccountIdMutation, SelectMangopayBankAccountIdMutationVariables>): ApolloReactHooks.MutationTuple<SelectMangopayBankAccountIdMutation, SelectMangopayBankAccountIdMutationVariables>;
export declare type SelectMangopayBankAccountIdMutationHookResult = ReturnType<typeof useSelectMangopayBankAccountIdMutation>;
export declare type SelectMangopayBankAccountIdMutationResult = ApolloReactCommon.MutationResult<SelectMangopayBankAccountIdMutation>;
export declare type SelectMangopayBankAccountIdMutationOptions = ApolloReactCommon.BaseMutationOptions<SelectMangopayBankAccountIdMutation, SelectMangopayBankAccountIdMutationVariables>;
export declare const MessagesGroupDocument: ApolloReactHooks.DocumentNode;
/**
 * __useMessagesGroupQuery__
 *
 * To run a query within a React component, call `useMessagesGroupQuery` and pass it any options that fit your needs.
 * When your component renders, `useMessagesGroupQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useMessagesGroupQuery({
 *   variables: {
 *      id: // value for 'id'
 *   },
 * });
 */
export declare function useMessagesGroupQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<MessagesGroupQuery, MessagesGroupQueryVariables>): ApolloReactHooks.QueryResult<MessagesGroupQuery, MessagesGroupQueryVariables>;
export declare function useMessagesGroupLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<MessagesGroupQuery, MessagesGroupQueryVariables>): ApolloReactHooks.QueryTuple<MessagesGroupQuery, MessagesGroupQueryVariables>;
export declare type MessagesGroupQueryHookResult = ReturnType<typeof useMessagesGroupQuery>;
export declare type MessagesGroupLazyQueryHookResult = ReturnType<typeof useMessagesGroupLazyQuery>;
export declare type MessagesGroupQueryResult = ApolloReactCommon.QueryResult<MessagesGroupQuery, MessagesGroupQueryVariables>;
export declare const UserListsDocument: ApolloReactHooks.DocumentNode;
/**
 * __useUserListsQuery__
 *
 * To run a query within a React component, call `useUserListsQuery` and pass it any options that fit your needs.
 * When your component renders, `useUserListsQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useUserListsQuery({
 *   variables: {
 *      groupId: // value for 'groupId'
 *   },
 * });
 */
export declare function useUserListsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<UserListsQuery, UserListsQueryVariables>): ApolloReactHooks.QueryResult<UserListsQuery, UserListsQueryVariables>;
export declare function useUserListsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<UserListsQuery, UserListsQueryVariables>): ApolloReactHooks.QueryTuple<UserListsQuery, UserListsQueryVariables>;
export declare type UserListsQueryHookResult = ReturnType<typeof useUserListsQuery>;
export declare type UserListsLazyQueryHookResult = ReturnType<typeof useUserListsLazyQuery>;
export declare type UserListsQueryResult = ApolloReactCommon.QueryResult<UserListsQuery, UserListsQueryVariables>;
export declare const GetUserListInGroupByListTypeDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGetUserListInGroupByListTypeQuery__
 *
 * To run a query within a React component, call `useGetUserListInGroupByListTypeQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetUserListInGroupByListTypeQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetUserListInGroupByListTypeQuery({
 *   variables: {
 *      listType: // value for 'listType'
 *      groupId: // value for 'groupId'
 *      data: // value for 'data'
 *   },
 * });
 */
export declare function useGetUserListInGroupByListTypeQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetUserListInGroupByListTypeQuery, GetUserListInGroupByListTypeQueryVariables>): ApolloReactHooks.QueryResult<GetUserListInGroupByListTypeQuery, GetUserListInGroupByListTypeQueryVariables>;
export declare function useGetUserListInGroupByListTypeLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetUserListInGroupByListTypeQuery, GetUserListInGroupByListTypeQueryVariables>): ApolloReactHooks.QueryTuple<GetUserListInGroupByListTypeQuery, GetUserListInGroupByListTypeQueryVariables>;
export declare type GetUserListInGroupByListTypeQueryHookResult = ReturnType<typeof useGetUserListInGroupByListTypeQuery>;
export declare type GetUserListInGroupByListTypeLazyQueryHookResult = ReturnType<typeof useGetUserListInGroupByListTypeLazyQuery>;
export declare type GetUserListInGroupByListTypeQueryResult = ApolloReactCommon.QueryResult<GetUserListInGroupByListTypeQuery, GetUserListInGroupByListTypeQueryVariables>;
export declare const CreateMessageDocument: ApolloReactHooks.DocumentNode;
export declare type CreateMessageMutationFn = ApolloReactCommon.MutationFunction<CreateMessageMutation, CreateMessageMutationVariables>;
/**
 * __useCreateMessageMutation__
 *
 * To run a mutation, you first call `useCreateMessageMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCreateMessageMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [createMessageMutation, { data, loading, error }] = useCreateMessageMutation({
 *   variables: {
 *      input: // value for 'input'
 *   },
 * });
 */
export declare function useCreateMessageMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CreateMessageMutation, CreateMessageMutationVariables>): ApolloReactHooks.MutationTuple<CreateMessageMutation, CreateMessageMutationVariables>;
export declare type CreateMessageMutationHookResult = ReturnType<typeof useCreateMessageMutation>;
export declare type CreateMessageMutationResult = ApolloReactCommon.MutationResult<CreateMessageMutation>;
export declare type CreateMessageMutationOptions = ApolloReactCommon.BaseMutationOptions<CreateMessageMutation, CreateMessageMutationVariables>;
export declare const GetMessagesForGroupDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGetMessagesForGroupQuery__
 *
 * To run a query within a React component, call `useGetMessagesForGroupQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetMessagesForGroupQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetMessagesForGroupQuery({
 *   variables: {
 *      groupId: // value for 'groupId'
 *   },
 * });
 */
export declare function useGetMessagesForGroupQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetMessagesForGroupQuery, GetMessagesForGroupQueryVariables>): ApolloReactHooks.QueryResult<GetMessagesForGroupQuery, GetMessagesForGroupQueryVariables>;
export declare function useGetMessagesForGroupLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetMessagesForGroupQuery, GetMessagesForGroupQueryVariables>): ApolloReactHooks.QueryTuple<GetMessagesForGroupQuery, GetMessagesForGroupQueryVariables>;
export declare type GetMessagesForGroupQueryHookResult = ReturnType<typeof useGetMessagesForGroupQuery>;
export declare type GetMessagesForGroupLazyQueryHookResult = ReturnType<typeof useGetMessagesForGroupLazyQuery>;
export declare type GetMessagesForGroupQueryResult = ApolloReactCommon.QueryResult<GetMessagesForGroupQuery, GetMessagesForGroupQueryVariables>;
export declare const GetUserMessagesForGroupDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGetUserMessagesForGroupQuery__
 *
 * To run a query within a React component, call `useGetUserMessagesForGroupQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetUserMessagesForGroupQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetUserMessagesForGroupQuery({
 *   variables: {
 *      groupId: // value for 'groupId'
 *   },
 * });
 */
export declare function useGetUserMessagesForGroupQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetUserMessagesForGroupQuery, GetUserMessagesForGroupQueryVariables>): ApolloReactHooks.QueryResult<GetUserMessagesForGroupQuery, GetUserMessagesForGroupQueryVariables>;
export declare function useGetUserMessagesForGroupLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetUserMessagesForGroupQuery, GetUserMessagesForGroupQueryVariables>): ApolloReactHooks.QueryTuple<GetUserMessagesForGroupQuery, GetUserMessagesForGroupQueryVariables>;
export declare type GetUserMessagesForGroupQueryHookResult = ReturnType<typeof useGetUserMessagesForGroupQuery>;
export declare type GetUserMessagesForGroupLazyQueryHookResult = ReturnType<typeof useGetUserMessagesForGroupLazyQuery>;
export declare type GetUserMessagesForGroupQueryResult = ApolloReactCommon.QueryResult<GetUserMessagesForGroupQuery, GetUserMessagesForGroupQueryVariables>;
export declare const GetMessageByIdDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGetMessageByIdQuery__
 *
 * To run a query within a React component, call `useGetMessageByIdQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetMessageByIdQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetMessageByIdQuery({
 *   variables: {
 *      id: // value for 'id'
 *   },
 * });
 */
export declare function useGetMessageByIdQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetMessageByIdQuery, GetMessageByIdQueryVariables>): ApolloReactHooks.QueryResult<GetMessageByIdQuery, GetMessageByIdQueryVariables>;
export declare function useGetMessageByIdLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetMessageByIdQuery, GetMessageByIdQueryVariables>): ApolloReactHooks.QueryTuple<GetMessageByIdQuery, GetMessageByIdQueryVariables>;
export declare type GetMessageByIdQueryHookResult = ReturnType<typeof useGetMessageByIdQuery>;
export declare type GetMessageByIdLazyQueryHookResult = ReturnType<typeof useGetMessageByIdLazyQuery>;
export declare type GetMessageByIdQueryResult = ApolloReactCommon.QueryResult<GetMessageByIdQuery, GetMessageByIdQueryVariables>;
export declare const GetActiveContractsDocument: ApolloReactHooks.DocumentNode;
/**
 * __useGetActiveContractsQuery__
 *
 * To run a query within a React component, call `useGetActiveContractsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetActiveContractsQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetActiveContractsQuery({
 *   variables: {
 *      groupId: // value for 'groupId'
 *   },
 * });
 */
export declare function useGetActiveContractsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetActiveContractsQuery, GetActiveContractsQueryVariables>): ApolloReactHooks.QueryResult<GetActiveContractsQuery, GetActiveContractsQueryVariables>;
export declare function useGetActiveContractsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetActiveContractsQuery, GetActiveContractsQueryVariables>): ApolloReactHooks.QueryTuple<GetActiveContractsQuery, GetActiveContractsQueryVariables>;
export declare type GetActiveContractsQueryHookResult = ReturnType<typeof useGetActiveContractsQuery>;
export declare type GetActiveContractsLazyQueryHookResult = ReturnType<typeof useGetActiveContractsLazyQuery>;
export declare type GetActiveContractsQueryResult = ApolloReactCommon.QueryResult<GetActiveContractsQuery, GetActiveContractsQueryVariables>;
