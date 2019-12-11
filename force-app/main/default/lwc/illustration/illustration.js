import { LightningElement, api, track } from 'lwc';
import illustrations from '@salesforce/resourceUrl/images';

export default class Illustration extends LightningElement {
    @api header;
    @api subHeader;

    @track illustration;
    @track illustrationType;

    @api
    get type() {
        return this.illustrationType;
    }

    set type(value) {
        this.illustrationType = value;

        switch (value) {
            case 'No-Data':
                this.illustration = illustrations + '/Illustrations/Cactus.svg';
                break;
            case 'Error':
                this.illustration = illustrations + '/Illustrations/Balloon.svg';
                break;
            default:
                this.illustration = illustrations + '/Illustrations/Cactus.svg';
                break;
        }
    }
}