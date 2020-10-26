declare const ImageUploader: {
    getBase64FromFile(file: Blob): Promise<string | ArrayBuffer | null>;
};
export default ImageUploader;
