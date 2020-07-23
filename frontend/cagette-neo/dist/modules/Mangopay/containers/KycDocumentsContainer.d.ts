/// <reference types="react" />
import { MangopayLegalUser } from 'gql';
export interface KycDocumentsContainerProps {
    groupId: number;
    mangopayLegalUser: MangopayLegalUser;
}
declare const KycDocumentsContainer: ({ groupId, mangopayLegalUser }: KycDocumentsContainerProps) => JSX.Element;
export default KycDocumentsContainer;
