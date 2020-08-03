/// <reference types="react" />
export interface KycDocumentFormProps {
    onSubmit: (files: File[], bag: KycDocumentFormBag) => void;
}
export interface KycDocumentFormBag {
    setSubmitting: (value: boolean) => void;
    setStatus: (status: string) => void;
}
declare const KycDocumentForm: ({ onSubmit }: KycDocumentFormProps) => JSX.Element;
export default KycDocumentForm;
