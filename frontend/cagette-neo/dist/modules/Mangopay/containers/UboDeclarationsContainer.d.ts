/// <reference types="react" />
import { MangopayLegalUser } from 'gql';
export interface UboDeclarationsContainerProps {
    groupId: number;
    mangopayLegalUser: MangopayLegalUser;
}
/** */
declare const UboDeclarationsContainer: ({ groupId, mangopayLegalUser }: UboDeclarationsContainerProps) => JSX.Element;
export default UboDeclarationsContainer;
