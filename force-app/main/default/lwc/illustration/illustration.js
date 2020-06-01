import { LightningElement, api } from 'lwc';
import illustrations from '@salesforce/resourceUrl/images';

export default class Illustration extends LightningElement {
    @api header;
    @api subHeader;

    illustration;
    illustrationType;

    @api
    get type() {
        return this.illustrationType;
    }

    set type(value) {
        this.illustrationType = value;

        if (value != null && value !== '') {
            this.illustration = illustrations + '/Illustrations/' + value + '.svg';
        }
    }
}
