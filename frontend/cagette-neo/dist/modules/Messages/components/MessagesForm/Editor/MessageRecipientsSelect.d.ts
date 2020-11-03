import { FieldInputProps, FieldMetaProps, FormikProps } from 'formik';
import React from 'react';
import { FormValues } from '../MessagesFormFormikTypes';
interface MessageRecipientsSelectProps {
    field: FieldInputProps<string | string[]>;
    meta: FieldMetaProps<string>;
    form: FormikProps<FormValues>;
    value: string;
    recipientsOptions: RecipientOption[];
    label: string;
}
export interface RecipientOption {
    label: string;
    value: string;
}
declare const _default: React.MemoExoticComponent<({ recipientsOptions, label, field, meta, form }: MessageRecipientsSelectProps) => JSX.Element>;
export default _default;
