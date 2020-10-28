import { MangopayLegalUser, MangopayKycDocumentType, MangopayKycDocument, MangopayUboDeclaration, MangopayAddress, MangopayBankAccount } from 'gql';
export declare const getCurrentKycDocumentOfType: (kycDocuments: MangopayKycDocument[], type: MangopayKycDocumentType) => MangopayKycDocument | undefined;
export declare const getCurrentUboDeclaration: (uboDeclarations?: MangopayUboDeclaration[] | null | undefined) => MangopayUboDeclaration | undefined;
export declare const allMangopayKycDocumentStatusesArePending: ({ LegalPersonType, KycDocuments }: MangopayLegalUser) => boolean;
export declare const formatMangopayBankAccount: (bankAccount: MangopayBankAccount) => string;
export declare const formatMangopayAddress: (address: MangopayAddress) => string;
