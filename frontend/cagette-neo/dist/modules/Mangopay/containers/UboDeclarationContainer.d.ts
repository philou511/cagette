/// <reference types="react" />
import { MangopayUboDeclaration } from 'gql';
export interface UboDeclarationContainerProps {
    groupId: number;
    uboDeclaration: MangopayUboDeclaration;
}
declare const UboDeclarationContainer: ({ groupId, uboDeclaration }: UboDeclarationContainerProps) => JSX.Element;
export default UboDeclarationContainer;
