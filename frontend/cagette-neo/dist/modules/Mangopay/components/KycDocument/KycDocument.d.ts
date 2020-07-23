/// <reference types="react" />
import { MangopayKycDocumentType, MangopayKycDocument } from 'gql';
import { KycDocumentFormProps } from '../KycDocumentForm';
export interface KycDocumentProps extends KycDocumentFormProps {
    type: MangopayKycDocumentType;
    last?: MangopayKycDocument;
}
declare const KycDocument: ({ type, last, onSubmit }: KycDocumentProps) => JSX.Element;
export default KycDocument;
