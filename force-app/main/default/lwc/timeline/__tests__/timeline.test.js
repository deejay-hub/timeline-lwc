import { createElement } from 'lwc';
import Timeline from 'c/timeline';
import getTimelineData from '@salesforce/apex/TimelineService.getTimelineRecords';

jest.mock('@salesforce/i18n/locale', () => 'en-US', { virtual: true });
jest.mock('@salesforce/i18n/lang', () => 'en', { virtual: true });
jest.mock('@salesforce/i18n/timeZone', () => 'UTC', { virtual: true });

jest.mock('@salesforce/resourceUrl/d3minified', () => 'd3-mock', { virtual: true });
jest.mock('lightning/platformResourceLoader', () => ({ loadScript: jest.fn(() => Promise.resolve()) }), {
    virtual: true
});
jest.mock('@salesforce/apex', () => ({ refreshApex: jest.fn() }), { virtual: true });

jest.mock(
    '@salesforce/apex/TimelineService.getTimelineRecords',
    () => ({
        default: jest.fn(() => Promise.resolve([]))
    }),
    { virtual: true }
);
let mockGetTimelineTypesAdapter;

jest.mock(
    '@salesforce/apex/TimelineService.getTimelineTypes',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        mockGetTimelineTypesAdapter = createApexTestWireAdapter(jest.fn());
        return {
            default: mockGetTimelineTypesAdapter
        };
    },
    { virtual: true }
);

jest.mock('@salesforce/label/c.Timeline_Error_Apex', () => ({ default: 'Apex Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_Setup', () => ({ default: 'Setup Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_NoDataHeader', () => ({ default: 'No data' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_NoDataSubHeader', () => ({ default: 'No data body' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_ConsoleTab', () => ({ default: 'Console Header' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_ConsoleTabSubHeader', () => ({ default: 'Console Body' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_JavaScriptResources', () => ({ default: 'JS Error' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_Unhandled', () => ({ default: 'Unhandled' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Days', () => ({ default: 'Days' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Showing', () => ({ default: 'Showing' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Items', () => ({ default: 'Items' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Filters', () => ({ default: 'Filters' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Filter_Type_Legend', () => ({ default: 'Type Legend' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Label_Date_Range_Legend', () => ({ default: 'Date Range' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Label_Files', () => ({ default: 'Files' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Filter_All_Types', () => ({ default: 'All Types' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Label_Apply', () => ({ default: 'Apply' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Cancel', () => ({ default: 'Cancel' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Navigation_Toast_Header', () => ({ default: 'Navigate' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Navigation_Toast_Body', () => ({ default: 'More info' }), {
    virtual: true
});

const flushPromises = () => Promise.resolve();

const BASE_PROPS = {
    timelineTitle: 'Recent Activity',
    preferredHeight: '3 - Default',
    iconStyle: 'Square',
    showToday: 'Blue',
    earliestRange: 1,
    latestRange: 1,
    zoomTo: 'Latest',
    daysToShow: 14,
    flexipageRegionWidth: 'LARGE',
    localisedZoomStartDate: 'Jan 01',
    localisedZoomEndDate: 'Jan 14',
    totalZoomedRecords: 7
};

const emitDefaultWire = () => {
    if (mockGetTimelineTypesAdapter) {
        mockGetTimelineTypesAdapter.emit({ Case: 'Case' });
    }
};

const buildTimeline = async (props = {}, { wireData = true } = {}) => {
    const element = createElement('c-timeline', { is: Timeline });
    Object.assign(element, BASE_PROPS, props);
    element.filterValues = props.filterValues || ['Case'];
    element.startingFilterValues = props.startingFilterValues || ['Case'];
    element.allFilterValues = props.allFilterValues || ['Case'];
    element._d3Rendered = true;
    document.body.appendChild(element);
    if (wireData) {
        emitDefaultWire();
    }
    await flushPromises();
    return element;
};

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
