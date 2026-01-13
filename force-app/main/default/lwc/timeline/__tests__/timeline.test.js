import { createElement } from '@lwc/engine-dom';
import TrafficLight from 'c/timeline';

describe('c-timeline', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        getTimelineData.mockResolvedValue([]);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders a loading spinner while data is not yet loaded', async () => {
        const element = await buildTimeline();

        expect(element.shadowRoot.querySelector('.slds-card__header-title')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
    });

    it('renders the configured label text in the filter panel', async () => {
        const element = await buildTimeline();

        const panelHeading = element.shadowRoot.querySelector('.timeline-filter h2');
        expect(panelHeading.textContent.trim()).toBe('Filters');

        const legends = element.shadowRoot.querySelectorAll('.slds-form-element__label.slds-text-title_caps');
        const typeLegend = legends[0];
        const dateLegend = legends[1];
        expect(typeLegend.textContent).toBe('Type Legend');
        expect(dateLegend.textContent).toBe('Date Range');
    });

    it('shows the “All Types” checkbox label', async () => {
        const element = await buildTimeline();
        const allTypesLabel = element.shadowRoot.querySelector('.slds-checkbox__label .slds-form-element__label');

        expect(allTypesLabel.textContent).toBe('All Types');
    });

    it('toggles the filter panel and refresh button state', async () => {
        const element = await buildTimeline({ isLoaded: true });
        await flushPromises();

        const filterPanel = element.shadowRoot.querySelector('.timeline-filter');
        const refreshButton = element.shadowRoot.querySelector('lightning-button-icon.timeline-refresh');
        const filterToggle = element.shadowRoot.querySelector('lightning-button-icon-stateful');

        filterToggle.dispatchEvent(new MouseEvent('click', { bubbles: true, composed: true }));
        await flushPromises();

        expect(filterPanel.classList.contains('slds-is-open')).toBe(true);
        expect(refreshButton.disabled).toBe(true);

        filterToggle.dispatchEvent(new MouseEvent('click', { bubbles: true, composed: true }));
        await flushPromises();

        expect(filterPanel.classList.contains('slds-is-open')).toBe(false);
        expect(refreshButton.disabled).toBe(false);
    });
});
