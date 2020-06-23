import { createElement } from 'lwc';
import Illustration from 'c/illustration';

describe('c-illustration', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders header and subheader', () => {
        // Create element
        const element = createElement('c-illustration', {
            is: Illustration
        });
        element.header = 'Sample Header';
        element.subHeader = 'Sample Subheader';
        document.body.appendChild(element);

        // Verify label
        const header = element.shadowRoot.querySelector('h3');
        expect(header.textContent).toBe('Sample Header');

        const subHeader = element.shadowRoot.querySelector('p');
        expect(subHeader.textContent).toBe('Sample Subheader');
    });

    it('renders correct image from type', () => {
        // Create element
        const element = createElement('c-illustration', {
            is: Illustration
        });
        element.type = 'Error';
        document.body.appendChild(element);

        // Verify image is correctly derived
        const imageElement = element.shadowRoot.querySelector('img');
        expect(imageElement.src).toContain('Error.svg');
    });
});
