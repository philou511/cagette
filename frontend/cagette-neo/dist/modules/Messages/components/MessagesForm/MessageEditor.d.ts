/// <reference types="react" />
import { FormikHandlers } from 'formik';
interface Props {
    name: string;
    onChange: FormikHandlers['handleChange'];
    onBlur: FormikHandlers['handleBlur'];
    value: string;
}
declare const MessageEditor: ({ name, onBlur, onChange, value: formikValue }: Props) => JSX.Element;
export default MessageEditor;
