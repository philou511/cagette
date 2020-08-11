/// <reference types="react" />
import { ApolloError } from '@apollo/client/core';
interface Props {
    error?: ApolloError;
}
declare const GqlErrorAlert: ({ error }: Props) => JSX.Element;
export default GqlErrorAlert;
