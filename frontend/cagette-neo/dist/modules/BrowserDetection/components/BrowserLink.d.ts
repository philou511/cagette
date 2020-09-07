/// <reference types="react" />
interface BrowserLinkProps {
    label: string;
    link: string;
    logo: string;
}
declare const BrowserLink: ({ label, link, logo }: BrowserLinkProps) => JSX.Element;
export default BrowserLink;
