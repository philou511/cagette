declare enum FormatTypes {
    bold = "bold",
    italic = "italic",
    underline = "underline",
    headingOne = "heading-one",
    headingTwo = "heading-two",
    blockQuote = "block-quote",
    numberedList = "numbered-list",
    bulletedList = "bulleted-list",
    listItem = "list-item",
    paragraph = "paragraph",
    alignCenter = "align-center",
    alignLeft = "align-left",
    alignRight = "align-right",
    hyperlink = "hyperlink",
    image = "image"
}
export declare const isFormatList: (format: string) => boolean;
export declare const isFormatListItem: (format: string) => boolean;
export declare const isFormatAlignment: (format: string) => boolean;
export declare const isFormatHeading: (format: string) => boolean;
export default FormatTypes;
