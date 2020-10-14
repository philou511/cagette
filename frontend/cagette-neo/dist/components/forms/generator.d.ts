import React from 'react';
import { FormikProps } from 'formik';
interface BaseFieldGeneratorProps {
    name: string;
    initialValues: any;
    validator?: any;
}
export declare enum FieldTypes {
    Custom = "custom",
    Default = "default",
    Select = "select",
    Editor = "Editor"
}
interface CustomFieldGeneratorProps extends BaseFieldGeneratorProps {
    type: FieldTypes.Custom;
    render: <T>(name: string, props: FormikProps<T>) => React.ReactNode;
}
interface DefaultFieldGeneratorProps extends BaseFieldGeneratorProps {
    type: FieldTypes.Default;
    label?: string;
    required?: boolean;
    disabled?: boolean;
    component?: any;
}
interface EditorGeneratorProps extends BaseFieldGeneratorProps {
    type: FieldTypes.Editor;
    label?: string;
    required?: boolean;
    disabled?: boolean;
}
interface SelectFieldGeneratorProps extends BaseFieldGeneratorProps {
    type: FieldTypes.Select;
    label?: string;
    required?: boolean;
    disabled?: boolean;
    component?: any;
    selectOptions: {
        value: string;
        label: string;
    }[];
    onSelectOption?: (value: string) => void;
}
export declare type FieldGeneratorProps = CustomFieldGeneratorProps | DefaultFieldGeneratorProps | SelectFieldGeneratorProps | EditorGeneratorProps;
export declare function generateFields<T>(fields: FieldGeneratorProps[], formikProps: FormikProps<T>): ({} | null | undefined)[];
export declare function generateInitialValues<T>(fields: FieldGeneratorProps[]): T;
export declare function generateValidationSchema(fields: FieldGeneratorProps[]): {};
export {};
