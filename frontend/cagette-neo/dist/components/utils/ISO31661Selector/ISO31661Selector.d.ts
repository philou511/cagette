/// <reference types="react" />
import { AutocompleteProps } from '@material-ui/lab/Autocomplete';
import { TextFieldProps } from '@material-ui/core/TextField';
export interface ISO_3166_1 {
    id: number;
    name: string;
    alpha2: string;
    alpha3: string;
}
export declare type ResultFormat = 'full-iso' | keyof ISO_3166_1;
export interface ISO31661SelectorProps {
    defaultValue?: ISO_3166_1 | number | string;
    format?: ResultFormat;
    autocompleteProps?: Omit<AutocompleteProps<ISO_3166_1>, 'defaultValue' | 'options' | 'getOptionLabel' | 'getOptionSelected' | 'renderInput'>;
    textFieldProps?: TextFieldProps;
    onChange: (value: ISO_3166_1 | string | number | null) => void;
}
declare const ISO31661Selector: ({ defaultValue, format, autocompleteProps, textFieldProps, onChange, }: ISO31661SelectorProps) => JSX.Element;
export default ISO31661Selector;
