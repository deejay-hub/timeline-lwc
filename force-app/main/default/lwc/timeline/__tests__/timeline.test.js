import { createElement } from 'lwc';
import Timeline from 'c/timeline';
import getTimelineData from '@salesforce/apex/TimelineService.getTimelineRecords';
import getTimelineTypes from '@salesforce/apex/TimelineService.getTimelineTypes';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const APEX_CONTACT_TIMELINE_SUCCESS = require('./data/timelineData.json');
const APEX_TIMELINE_TYPES = require('./data/timelineTypes.json');

// Register as Apex wire adapter. Some tests verify that provisioned values trigger desired behavior.
const getTimelineTypesAdapter = registerApexTestWireAdapter(getTimelineTypes);

// Mocking imperative Apex method call
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
    'lightning/platformResourceLoader',
    () => {
        return {
            loadScript() {
                return new Promise((resolve) => {
                    global.moment = require('../../../staticresources/momentminified.js');
                    global.d3 = require('../../../staticresources/d3minified.js');
                    resolve();
                });
            }
        };
    },
    { virtual: true }
);

describe('c-timeline', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Prevent data saved on mocks from leaking between tests
        jest.clearAllMocks();
    });

    function flushPromises() {
        // eslint-disable-next-line no-undef
        return new Promise((resolve) => setImmediate(resolve));
    }

    it('should render with data', () => {
        getTimelineData.mockResolvedValue(APEX_CONTACT_TIMELINE_SUCCESS);

        // Create element
        const element = createElement('c-timeline', {
            is: Timeline
        });

        element.timelineTitle = 'Sample Title';
        element.earliestRange = '1';
        element.latestRange = '1';
        element.preferredHeight = '3 - Default';
        element.zoomTo = 'Current Date';
        element.daysToShow = '60';

        document.body.appendChild(element);

        return flushPromises().then(() => {
            const toggleButton = element.shadowRoot.querySelector('lightning-button-icon.timeline-refresh');
            toggleButton.click();

            const title = element.shadowRoot.querySelector('h1');
            expect(title.textContent).toBe('Sample Title');
        });
    });

    it('should show filter panel on button click', () => {
        getTimelineData.mockResolvedValue(APEX_CONTACT_TIMELINE_SUCCESS);

        const element = createElement('c-timeline', {
            is: Timeline
        });

        element.timelineTitle = 'Sample Title';
        element.earliestRange = '2';
        element.latestRange = '1';
        element.preferredHeight = '4 - Big';
        element.zoomTo = 'Last Activity';
        element.daysToShow = '60';

        document.body.appendChild(element);

        // Emit data from @wire
        getTimelineTypesAdapter.emit(APEX_TIMELINE_TYPES);

        return flushPromises().then(() => {
            const toggleFilter = element.shadowRoot.querySelector('lightning-button-icon-stateful');
            toggleFilter.click();

            const filterPanel = element.shadowRoot.querySelectorAll('div.slds-checkbox');
            expect(filterPanel.length).toBe(1);

            toggleFilter.click();
        });
    });
});
