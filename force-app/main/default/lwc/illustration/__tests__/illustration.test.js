import { createElement } from '@lwc/engine-dom';
import Illustration from 'c/illustration';

jest.mock('@salesforce/resourceUrl/images', () => ({ default: 'https://static.example.com' }), { virtual: true });

const appendIllustration = async (props = {}) => {
    const element = createElement('c-illustration', { is: Illustration });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
};

describe('c-illustration', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders header and subheader when properties update', async () => {
        const element = await appendIllustration({ header: 'Initial', subHeader: 'First' });

        element.header = 'Sample Header';
        element.subHeader = 'Sample Subheader';
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('h3').textContent).toBe('Sample Header');
        expect(element.shadowRoot.querySelector('p').textContent).toBe('Sample Subheader');
    });

    it('derives the illustration path from the type setter', async () => {
        const element = await appendIllustration({ type: 'Error' });

        const imageElement = element.shadowRoot.querySelector('img');
        expect(imageElement.src).toBe('https://static.example.com/Illustrations/Error.svg');
    });

    it('exposes the type getter', async () => {
        const element = await appendIllustration({ type: 'Success' });
        expect(element.type).toBe('Success');
    });

    it('ignores falsy type values and leaves img src unset', async () => {
        const element = await appendIllustration({ type: '' });
        const imageElement = element.shadowRoot.querySelector('img');
        expect(imageElement.getAttribute('src')).toBeNull();
    });

    it('renders the static alt text for accessibility', async () => {
        const element = await appendIllustration();
        const imageElement = element.shadowRoot.querySelector('img');
        expect(imageElement.getAttribute('alt')).toBe('Illustration');
    });
});
