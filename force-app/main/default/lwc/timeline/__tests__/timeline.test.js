import { createElement } from '@lwc/engine-dom';
import Timeline from 'c/timeline';
import getTimelineData from '@salesforce/apex/TimelineService.getTimelineRecords';
import getTimelineTypes from '@salesforce/apex/TimelineService.getTimelineTypes';

// Mock the Apex methods
jest.mock(
    '@salesforce/apex/TimelineService.getTimelineRecords',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/TimelineService.getTimelineTypes',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mock static resources
jest.mock('@salesforce/resourceUrl/d3minified', () => {
    return '/mock/d3minified.js';
}, { virtual: true });

// Mock custom labels
jest.mock('@salesforce/label/c.Timeline_Label_Filters', () => ({ default: 'Filters' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Filter_Type_Legend', () => ({ default: 'Type Legend' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Date_Range_Legend', () => ({ default: 'Date Range' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Filter_All_Types', () => ({ default: 'All Types' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Days', () => ({ default: 'days' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Showing', () => ({ default: 'Showing' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Items', () => ({ default: 'items' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Files', () => ({ default: 'Files' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Apply', () => ({ default: 'Apply' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Cancel', () => ({ default: 'Cancel' }), { virtual: true });

// Mock error labels
jest.mock('@salesforce/label/c.Timeline_Error_Apex', () => ({ default: 'Apex Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_Setup', () => ({ default: 'Setup Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_NoDataHeader', () => ({ default: 'No Data' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_NoDataSubHeader', () => ({ default: 'No Data Found' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_ConsoleTab', () => ({ default: 'Console Tab Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_ConsoleTabSubHeader', () => ({ default: 'Console Tab Error Details' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_JavaScriptResources', () => ({ default: 'JavaScript Load Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_Unhandled', () => ({ default: 'Unhandled Error' }), { virtual: true });

// Mock navigation labels
jest.mock('@salesforce/label/c.Timeline_Navigation_Toast_Header', () => ({ default: 'Navigation' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Navigation_Toast_Body', () => ({ default: 'Navigation not available' }), { virtual: true });

// Mock i18n
jest.mock('@salesforce/i18n/locale', () => ({ default: 'en-US' }), { virtual: true });
jest.mock('@salesforce/i18n/lang', () => ({ default: 'en' }), { virtual: true });
jest.mock('@salesforce/i18n/timeZone', () => ({ default: 'America/Los_Angeles' }), { virtual: true });

// Helper function to create timeline component
const buildTimeline = async (props = {}) => {
    const element = createElement('c-timeline', {
        is: Timeline
    });
    
    // Set default properties
    element.recordId = '001XXXXXXXXXXXXXXX';
    element.timelineParent = 'AccountId';
    element.timelineTitle = 'Timeline';
    element.preferredHeight = '3 - Default';
    element.iconStyle = 'Square';
    element.earliestRange = 1;
    element.latestRange = 1;
    element.zoomTo = 'Current Date';
    element.daysToShow = 90;
    element.showToday = 'Blue';
    
    // Override with any provided props
    Object.assign(element, props);
    
    document.body.appendChild(element);
    
    // Wait for any pending promises to resolve
    await flushPromises();
    
    return element;
};

// Helper to flush promises
const flushPromises = () => {
    return new Promise(resolve => setTimeout(resolve, 0));
};

describe('c-timeline', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        getTimelineData.mockResolvedValue([]);
        getTimelineTypes.mockResolvedValue({ data: {}, error: null });
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
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
