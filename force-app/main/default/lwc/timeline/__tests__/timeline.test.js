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

jest.mock(
    'lightning/platformWorkspaceApi',
    () => {
        const IsConsoleNavigation = {
            emit: jest.fn()
        };
        return {
            IsConsoleNavigation,
            openTab: jest.fn()
        };
    },
    { virtual: true }
);

// Mock static resources
jest.mock(
    '@salesforce/resourceUrl/d3minified',
    () => {
        return '/mock/d3minified.js';
    },
    { virtual: true }
);

// Mock custom labels
jest.mock('@salesforce/label/c.Timeline_Label_Filters', () => ({ default: 'Filters' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Label_Filter_Type_Legend', () => ({ default: 'Type Legend' }), {
    virtual: true
});
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
jest.mock('@salesforce/label/c.Timeline_Error_NoDataSubHeader', () => ({ default: 'No Data Found' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_ConsoleTab', () => ({ default: 'Console Tab Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Error_ConsoleTabSubHeader', () => ({ default: 'Console Tab Error Details' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_JavaScriptResources', () => ({ default: 'JavaScript Load Error' }), {
    virtual: true
});
jest.mock('@salesforce/label/c.Timeline_Error_Unhandled', () => ({ default: 'Unhandled Error' }), { virtual: true });

// Mock navigation labels
jest.mock('@salesforce/label/c.Timeline_Navigation_Toast_Header', () => ({ default: 'Navigation' }), { virtual: true });
jest.mock('@salesforce/label/c.Timeline_Navigation_Toast_Body', () => ({ default: 'Navigation not available' }), {
    virtual: true
});

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
    return new Promise((resolve) => setTimeout(resolve, 0));
};

// Chainable stub that mimics a d3 selection
function d3Selection() {
    const sel = {
        select: jest.fn(() => d3Selection()),
        selectAll: jest.fn(() => d3Selection()),
        append: jest.fn(() => d3Selection()),
        remove: jest.fn(() => sel),
        attr: jest.fn(() => sel),
        style: jest.fn(() => sel),
        data: jest.fn(() => sel),
        enter: jest.fn(() => d3Selection()),
        exit: jest.fn(() => d3Selection()),
        on: jest.fn(() => sel),
        call: jest.fn(() => sel),
        text: jest.fn(() => sel),
        each: jest.fn(() => sel),
        filter: jest.fn(() => d3Selection()),
        sort: jest.fn(() => sel),
        transition: jest.fn(() => sel),
        duration: jest.fn(() => sel),
        merge: jest.fn(() => sel)
    };
    return sel;
}

describe('c-timeline', () => {
    let intersectionCallback;

    beforeEach(() => {
        jest.clearAllMocks();
        getTimelineData.mockResolvedValue([]);
        getTimelineTypes.mockResolvedValue({ data: {}, error: null });

        global.IntersectionObserver = jest.fn((cb) => {
            intersectionCallback = cb;
            return {
                observe: jest.fn(),
                unobserve: jest.fn(),
                disconnect: jest.fn()
            };
        });

        const mockSelection = d3Selection();
        global.d3 = {
            select: jest.fn(() => mockSelection),
            selectAll: jest.fn(() => mockSelection),
            scaleTime: jest.fn(() => {
                const scale = jest.fn();
                scale.domain = jest.fn(() => scale);
                scale.range = jest.fn(() => scale);
                scale.rangeRound = jest.fn(() => scale);
                return scale;
            }),
            min: jest.fn(),
            max: jest.fn(),
            axisBottom: jest.fn(() => {
                const axis = jest.fn();
                axis.tickSize = jest.fn(() => axis);
                axis.tickPadding = jest.fn(() => axis);
                axis.ticks = jest.fn(() => axis);
                return axis;
            }),
            brushX: jest.fn(() => {
                const brush = jest.fn();
                brush.extent = jest.fn(() => brush);
                brush.on = jest.fn(() => brush);
                return brush;
            })
        };
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        delete global.d3;
        delete global.IntersectionObserver;
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

    it('defers rendering when canvas has zero width (background console tab)', async () => {
        const mockData = [
            {
                objectId: '500xx000000001',
                objectName: 'Task',
                objectLabel: 'Task',
                positionDateField: 'ActivityDate',
                positionDateType: 'DATE',
                positionDateValue: '2025-06-15',
                detailField: 'Test Task',
                detailFieldLabel: 'Subject',
                fallbackTooltipField: '',
                fallbackTooltipValue: '',
                tooltipId: '500xx000000001',
                tooltipObject: 'Task',
                drilldownId: '',
                alternateDetailId: '',
                type: 'Task',
                icon: '/img/icon/t4v35/standard/task.svg',
                iconBackground: '#4BC076'
            }
        ];

        getTimelineData.mockResolvedValue(mockData);

        const element = await buildTimeline();
        await flushPromises();

        const illustration = element.shadowRoot.querySelector('c-illustration');
        const hasSetupError = illustration && illustration.header === 'Console Tab Error';
        expect(hasSetupError).toBe(false);

        expect(global.IntersectionObserver).toHaveBeenCalled();
    });

    it('does not show console tab error after IntersectionObserver fires', async () => {
        const mockData = [
            {
                objectId: '500xx000000001',
                objectName: 'Task',
                objectLabel: 'Task',
                positionDateField: 'ActivityDate',
                positionDateType: 'DATE',
                positionDateValue: '2025-06-15',
                detailField: 'Test Task',
                detailFieldLabel: 'Subject',
                fallbackTooltipField: '',
                fallbackTooltipValue: '',
                tooltipId: '500xx000000001',
                tooltipObject: 'Task',
                drilldownId: '',
                alternateDetailId: '',
                type: 'Task',
                icon: '/img/icon/t4v35/standard/task.svg',
                iconBackground: '#4BC076'
            }
        ];

        getTimelineData.mockResolvedValue(mockData);

        const element = await buildTimeline();
        await flushPromises();

        intersectionCallback([{ isIntersecting: true }]);
        await flushPromises();

        const illustration = element.shadowRoot.querySelector('c-illustration');
        const hasConsoleTabError = illustration && illustration.header === 'Console Tab Error';
        expect(hasConsoleTabError).toBe(false);
    });

    it('cleans up IntersectionObserver on disconnect', async () => {
        const element = await buildTimeline();
        await flushPromises();

        const observerInstance = global.IntersectionObserver.mock.results[0]?.value;

        document.body.removeChild(element);
        await flushPromises();

        if (observerInstance) {
            expect(observerInstance.disconnect).toHaveBeenCalled();
        }
    });
});
