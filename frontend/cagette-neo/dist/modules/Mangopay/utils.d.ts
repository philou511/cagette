import { MangopayLegalUser, MangopayKycDocumentType, MangopayKycDocument, MangopayUboDeclaration } from 'gql';
export declare const getCurrentKycDocumentOfType: (kycDocuments: MangopayKycDocument[], type: MangopayKycDocumentType) => MangopayKycDocument | undefined;
export declare const getCurrentUboDeclaration: (uboDeclarations?: MangopayUboDeclaration[] | null | undefined) => MangopayUboDeclaration | undefined;
export declare const allMangopayDocumentStatusesArePending: ({ LegalPersonType, KycDocuments, UboDeclarations, }: MangopayLegalUser) => boolean;
