import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOCALE from '@salesforce/i18n/locale';
import LANGUAGE from '@salesforce/i18n/lang';
import TIMEZONE from '@salesforce/i18n/timeZone';

import getTimelineData from '@salesforce/apex/TimelineService.getTimelineRecords';
import getTimelineTypes from '@salesforce/apex/TimelineService.getTimelineTypes';
import { refreshApex } from '@salesforce/apex';

import d3JS from '@salesforce/resourceUrl/d3minified';

import APEX from '@salesforce/label/c.Timeline_Error_Apex';
import SETUP from '@salesforce/label/c.Timeline_Error_Setup';
import NO_DATA_HEADER from '@salesforce/label/c.Timeline_Error_NoDataHeader';
import NO_DATA_SUBHEADER from '@salesforce/label/c.Timeline_Error_NoDataSubHeader';
import CONSOLE_HEADER from '@salesforce/label/c.Timeline_Error_ConsoleTab';
import CONSOLE_SUBHEADER from '@salesforce/label/c.Timeline_Error_ConsoleTabSubHeader';
import JAVASCRIPT_LOAD from '@salesforce/label/c.Timeline_Error_JavaScriptResources';
import UNHANDLED from '@salesforce/label/c.Timeline_Error_Unhandled';

import DAYS from '@salesforce/label/c.Timeline_Label_Days';
import SHOWING from '@salesforce/label/c.Timeline_Label_Showing';
import ITEMS from '@salesforce/label/c.Timeline_Label_Items';
import FILTERS from '@salesforce/label/c.Timeline_Label_Filters';
import TYPE_LEGEND from '@salesforce/label/c.Timeline_Label_Filter_Type_Legend';
import DATE_RANGE_LEGEND from '@salesforce/label/c.Timeline_Label_Date_Range_Legend';
import FILE_TYPE from '@salesforce/label/c.Timeline_Label_Files';
import ALL_TYPES from '@salesforce/label/c.Timeline_Label_Filter_All_Types';
import BUTTON_APPLY from '@salesforce/label/c.Timeline_Label_Apply';
import BUTTON_CANCEL from '@salesforce/label/c.Timeline_Label_Cancel';

import NAVIGATION_HEADER from '@salesforce/label/c.Timeline_Navigation_Toast_Header';
import NAVIGATION_BODY from '@salesforce/label/c.Timeline_Navigation_Toast_Body';

export default class timeline extends NavigationMixin(LightningElement) {
    //Adminstrator accessible attributes in app builder
    @api timelineParent; //parent field for the lwc set as design attribute
    @api timelineTitle; //title for the lwc set as design attribute
    @api preferredHeight; //height of the timeline set as design attribute
    @api earliestRange; //How far back in time to go
    @api latestRange; //How far into the future to go
    @api zoomTo; //Zoom to current dat or latest activity
    @api daysToShow; //number of days to plot for the default zoom
    @api showToday; //should today's date be plotted and in what colour

    //Component calculated attributes
    @api recordId; //current record id of lead, case, opportunity, contact or account

    @api flexipageRegionWidth; //SMALL, MEDIUM and LARGE based on where the component is placed in App Builder templates

    isLanguageRightToLeft = false;

    timelineWidth = 'LARGE';
    timelineTypes;
    timelineStart; //Calculated based on the earliestRange
    timelineEnd; //Calculated based on the latestRange

    timelineSummary = '';

    zoomStartDate; //Start date of the current zoom
    zoomEndDate; //End date of the current zoom

    localisedZoomStartDate; //Start date of the current zoom
    localisedZoomEndDate; //End date of the current zoom

    totalTimelineRecords = 0; //Total number of records returned
    totalZoomedRecords = 0; //Total records in zoom

    noData = false; //Boolean when no data is returned
    noFilterData = false; //Boolean when no data is returned after filtering
    isLoaded = false; //Boolean when timeline data is loaded
    isError = false; //Boolean when there is an error

    isMouseOver = false; //Boolean when mouse over is detected
    isTooltipLoading = true;
    mouseOverRecordId; //Current Id of the record being hovered over
    mouseOverObjectAPIName; //API Name for the object being hovered over
    mouseOverDetailLabel;
    mouseOverDetailValue;
    mouseOverFallbackField;
    mouseOverFallbackValue;
    mouseOverPositionLabel;
    mouseOverPositionValue;

    currentParentField;
    filterValues = [];
    startingFilterValues = [];
    allFilterValues = [];
    objectFilter = [];
    isFilter;
    isFilterUpdated;
    isFilterLoaded = false;

    illustrationVisibility = 'illustration-hidden'; //Toggles the class to show and hide the illustration component

    illustrationHeader; //Header to display when an information box displays
    illustrationSubHeader; //Sub Header to display when an info box appears
    illustrationType; //Type of illustration to display, 'error' or 'no data'

    todayColourMap = {
        Blue: "#107cad",
        Green: "#2e844a",
        Black: "#444444",
        Purple: "#9050e9",
        Indigo: "#5867e8",
        Teal: "#0b827c",
        Pink: "#e3066a",
        Red: "#ea001e",
        No: "#107cad"
    };

    label = {
        DAYS,
        SHOWING,
        ITEMS,
        FILTERS,
        TYPE_LEGEND,
        DATE_RANGE_LEGEND,
        FILE_TYPE,
        ALL_TYPES,
        BUTTON_APPLY,
        BUTTON_CANCEL
    };

    error = {
        APEX,
        SETUP,
        CONSOLE_HEADER,
        CONSOLE_SUBHEADER,
        NO_DATA_HEADER,
        NO_DATA_SUBHEADER,
        JAVASCRIPT_LOAD,
        UNHANDLED
    };

    toast = {
        NAVIGATION_HEADER,
        NAVIGATION_BODY
    };

    _timelineData = null;
    _timelineHeight = null;

    heightMap = {
        "1 - Smallest": 125,
        "2 - Small": 200,
        "3 - Default": 275,
        "4 - Big": 350,
        "5 - Biggest": 425,
      };

    //These are the objects holding individual instances of the timeline
    _d3timelineCanvas = null;
    _d3timelineCanvasAxis = null;
    _d3timelineCanvasMap = null;
    _d3timelineCanvasMapAxis = null;
    _d3brush = null;

    //These are the d3 selections that allow us to modify the DOM
    _d3timelineCanvasSVG = null;
    _d3timelineCanvasAxisSVG = null;
    _d3timelineMapSVG = null;
    _d3timelineMapAxisSVG = null;
    _d3timelineCanvasDIV = null;
    _d3timelineCanvasMapDIV = null;

    _d3Rendered = false;

    calculatedLOCALE() {
        let tempLocale;

        switch (LOCALE) {
            case 'is':
            case 'is-IS':
                tempLocale = 'fi-FI';
                break;
            default:
                tempLocale = LOCALE;
                break;
        }

        return tempLocale;
    }

    @wire(getTimelineTypes, { parentObjectId: '$recordId', parentFieldName: '$timelineParent' })
    wiredResult(result) {
        if (result.data) {
            this.timelineTypes = result;
            const timelineTs = result.data;

            for (let key in timelineTs) {
                // eslint-disable-next-line no-prototype-builtins
                if (timelineTs.hasOwnProperty(key)) {
                    this.filterValues.push(key);
                    let tempFilter = [];

                    tempFilter.label = timelineTs[key];
                    tempFilter.value = key;

                    this.objectFilter.push(tempFilter);
                    this.startingFilterValues.push(key);
                    this.allFilterValues.push(key);
                }
            }
            this.isFilterLoaded = true;
        } else if (result.error) {
            let errorType = 'Error';
            let errorHeading,
                errorMessage = '--';

            try {
                errorMessage = result.error.body.message;
                let customError = JSON.parse(errorMessage);
                errorType = customError.type;
                errorMessage = customError.message;
                errorHeading = this.error.SETUP;
            } catch (error2) {
                //fails to parse message so is a generic apex error
                errorHeading = this.error.APEX;
            }

            this.processError(errorType, errorHeading, errorMessage);
        }
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.debounce);
    }

    connectedCallback() {
        this._timelineHeight = this.heightMap[this.preferredHeight];
    }

    renderedCallback() {
        if (
            this.flexipageRegionWidth === 'SMALL' ||
            this.flexipageRegionWidth === 'MEDIUM' ||
            this.flexipageRegionWidth === 'LARGE'
        ) {
            this.timelineWidth = this.flexipageRegionWidth;
        }

        if (!this._d3Rendered) {
            this.todaysColour = this.todayColourMap[this.showToday];
            //set the height of the component as the height is dynamic based on the attributes
            let timelineDIV = this.template.querySelector('div.timeline-canvas');
            this.currentParentField = this.timelineParent;
            timelineDIV.setAttribute('style', 'height:' + this._timelineHeight + 'px');

            Promise.all([loadScript(this, d3JS)])
                .then(() => {
                    //Setup d3 timeline by manipulating the DOM and do it once only as render gets called many times
                    this._d3timelineCanvasDIV = d3.select(this.template.querySelector('div.timeline-canvas'));
                    this._d3timelineCanvasMapDIV = d3.select(this.template.querySelector('div.timeline-canvas-map'));
                    this._d3timelineCanvasSVG = d3
                        .select(this.template.querySelector('div.timeline-canvas'))
                        .append('svg');
                    this._d3timelineCanvasAxisSVG = d3
                        .select(this.template.querySelector('div.timeline-canvas-axis'))
                        .append('svg');
                    this._d3timelineMapSVG = d3.select(this.template.querySelector('div.timeline-map')).append('svg');
                    this._d3timelineMapAxisSVG = d3
                        .select(this.template.querySelector('div.timeline-map-axis'))
                        .append('svg');

                    this.processTimeline();
                })
                .catch((error) => {
                    this.processError('Error', this.error.JAVASCRIPT_LOAD, error);
                });

            this._d3Rendered = true;
        }

        let timelineSummary = this.template.querySelectorAll('span.timeline-summary-verbose');

        if (timelineSummary !== undefined && timelineSummary !== null) {
            for (let i = 0; i < timelineSummary.length; i++) {
                timelineSummary[i].classList.add('timeline-summary-verbose-' + this.timelineWidth);
            }
        }
    }

    processTimeline() {
        const me = this;
        me.isError = false;
        me.isLoaded = false;

        me.illustrationVisibility = 'illustration-hidden';
        me.noData = false;

        //Work out if the language is right to left
        if (
            LANGUAGE.startsWith('ar') ||
            LANGUAGE.startsWith('he') ||
            LANGUAGE.startsWith('ur') ||
            LANGUAGE.startsWith('yi')
        ) {
            this.isLanguageRightToLeft = true;
        }

        const dateTimeFormat = new Intl.DateTimeFormat(me.calculatedLOCALE());
        //Convert earliestRange to months
        me.timelineStart = dateTimeFormat.format(new Date().setMonth(new Date().getMonth() - 12 * me.earliestRange));
        me.timelineEnd = dateTimeFormat.format(new Date().setMonth(new Date().getMonth() + 12 * me.latestRange));

        me._d3timelineCanvasSVG.selectAll('*').remove();
        me._d3timelineCanvasAxisSVG.selectAll('*').remove();
        me._d3timelineMapSVG.selectAll('*').remove();
        me._d3timelineMapAxisSVG.selectAll('*').remove();

        if (me.currentParentField !== me.timelineParent) {
            refreshApex(me.timelineTypes);
            me.currentParentField = me.timelineParent;
        }

        getTimelineData({
            parentObjectId: me.recordId,
            earliestRange: me.earliestRange,
            latestRange: me.latestRange,
            parentFieldName: me.timelineParent
        })
            .then((result) => {
                try {
                    if ( this.template.querySelector('div.timeline-canvas').offsetWidth !== 0 ) {
                        if (result.length > 0) {
                            me.totalTimelineRecords = result.length;

                            //Process timeline records
                            me._timelineData = me.getTimelineRecords(result);

                            //Process timeline canvas
                            me._d3timelineCanvas = me.timelineCanvas();

                            const axisDividerConfig = {
                                innerTickSize: -me._d3timelineCanvas.SVGHeight,
                                translate: [0, me._d3timelineCanvas.SVGHeight],
                                tickPadding: 0,
                                ticks: 6,
                                class: 'axis-ticks'
                            };

                            me._d3timelineCanvasAxis = me.axis(
                                axisDividerConfig,
                                me._d3timelineCanvasSVG,
                                me._d3timelineCanvas
                            );

                            const axisLabelConfig = {
                                innerTickSize: 0,
                                tickPadding: 2,
                                translate: [0, 5],
                                ticks: 6,
                                class: 'axis-label'
                            };

                            me._d3timelineCanvasAxisLabel = me.axis(
                                axisLabelConfig,
                                me._d3timelineCanvasAxisSVG,
                                me._d3timelineCanvas
                            );

                            //Process timeline map
                            me._d3timelineMap = me.timelineMap();
                            me._d3timelineMap.redraw();

                            const mapAxisConfig = {
                                innerTickSize: 4,
                                tickPadding: 4,
                                ticks: 6,
                                class: 'axis-label'
                            };

                            me._d3timelineMapAxis = me.axis(mapAxisConfig, me._d3timelineMapAxisSVG, me._d3timelineMap);

                            me._d3brush = me.brush();

                            window.addEventListener(
                                'resize',
                                me.debounce(() => {
                                    try {
                                        if (me.template.querySelector('div.timeline-canvas').offsetWidth !== 0) {
                                            me._d3timelineCanvas.x.range([
                                                0,
                                                me.template.querySelector('div.timeline-canvas').offsetWidth
                                            ]);
                                            me._d3timelineMap.x.range([
                                                0,
                                                Math.max(me.template.querySelector('div.timeline-map').offsetWidth, 0)
                                            ]);
                                            me._d3timelineCanvasAxis.redraw();
                                            me._d3timelineCanvasAxisLabel.redraw();
                                            me._d3timelineMap.redraw();
                                            me._d3timelineMapAxis.redraw();
                                            me._d3brush.redraw();
                                        }
                                    } catch (error) {
                                        //stay silent
                                    }
                                }, 200)
                            );

                            me.isLoaded = true;
                        } else {
                            me.processError('No-Data', me.error.NO_DATA_HEADER, me.error.NO_DATA_SUBHEADER);
                        }
                    } else {
                        me.processError('Setup-Error', me.error.CONSOLE_HEADER, me.error.CONSOLE_SUBHEADER);
                    }
                } catch (error) {
                    me.processError('Error', me.error.UNHANDLED, error.message);
                }
            })
            .catch((error) => {
                let errorType = 'Error';
                let errorHeading,
                    errorMessage = '--';

                try {
                    errorMessage = error.body.message;
                    let customError = JSON.parse(errorMessage);
                    errorType = customError.type;
                    errorMessage = customError.message;
                    errorHeading = me.error.SETUP;
                } catch (error2) {
                    //fails to parse message so is a generic apex error
                    errorHeading = me.error.APEX;
                }

                me.processError(errorType, errorHeading, errorMessage);
            });
    }

    getTimelineRecords(result) {
        const me = this;
        let timelineRecords = {};
        let timelineResult = [];
        let timelineTimes = [];

        result.forEach(function (record, index) {
            let recordCopy = {};
            let options;

            recordCopy.recordId = record.objectId;
            recordCopy.id = index;
            recordCopy.label =
                record.detailField.length <= 30 ? record.detailField : record.detailField.slice(0, 30) + '...';
            recordCopy.objectName = record.objectName;
            recordCopy.positionDateField = record.positionDateField;

            if (record.positionDateType === 'DATE') {
                options = {
                    year: 'numeric',
                    month: 'numeric',
                    day: 'numeric'
                };
            }      
            else {
                options = {
                    hour: 'numeric',
                    minute: 'numeric',
                    year: 'numeric',
                    month: 'numeric',
                    day: 'numeric',
                    timeZone: TIMEZONE
                };
            }  

            let dateFormatter = new Intl.DateTimeFormat(me.calculatedLOCALE(), options);

            let convertDate = record.positionDateValue;
            

            if (record.positionDateType === 'DATETIME') {
                convertDate = record.positionDateValue.replace(' ', 'T');
                convertDate = convertDate + '.000Z';
            }
            
            let localDate = new Date(convertDate);
            let localPositionDate = dateFormatter.format(localDate);

            recordCopy.positionDateValue = localPositionDate;
            recordCopy.time = localDate;

            recordCopy.detailField = record.detailField;
            recordCopy.detailFieldLabel = record.detailFieldLabel;
            recordCopy.fallbackTooltipField = record.fallbackTooltipField;
            recordCopy.fallbackTooltipValue = record.fallbackTooltipValue;
            recordCopy.tooltipId = record.tooltipId;
            recordCopy.tooltipObject = record.tooltipObject;
            recordCopy.drilldownId = record.drilldownId;

            recordCopy.type = record.type;
            recordCopy.icon = record.icon;
            recordCopy.iconBackground = record.iconBackground;

            timelineResult.push(recordCopy);
            timelineTimes.push(recordCopy.time);
        });

        timelineRecords.data = timelineResult;
        timelineRecords.minTime = d3.min(timelineTimes);
        timelineRecords.maxTime = d3.max(timelineTimes);

        timelineRecords.requestRange = [
            new Date(new Date().setMonth(new Date().getMonth() - 12 * this.earliestRange)),
            new Date(new Date().setMonth(new Date().getMonth() + 12 * this.latestRange))
        ];

        return timelineRecords;
    }

    timelineCanvas() {
        const me = this;
        const timelineCanvasDIV = this.template.querySelector('div.timeline-canvas');
        const timelineCanvas = me._d3timelineCanvasSVG;
        const timelineData = me._timelineData;
        const timelineHeight = me._timelineHeight;

        const width = timelineCanvasDIV.offsetWidth;

        timelineCanvasDIV.setAttribute('style', 'max-height:' + timelineHeight + 'px');
        timelineCanvas.SVGHeight = timelineHeight;

        timelineCanvas.x = d3.scaleTime().domain(timelineData.requestRange).rangeRound([0, width]);

        timelineCanvas.y = function (swimlane) {
            return swimlane * 25 * 1 + (swimlane + 1) * 5;
        };

        timelineCanvas.width = width;
        timelineCanvas.height = timelineHeight;

        timelineCanvas.filter = function (d) {
            if (me.isFilterLoaded === false || me.filterValues.includes(d.objectName)) {
                return true;
            }
            return false;
        };

        let currentDate = new Date();

        if ( this.showToday !== "No" ) {
            let today = timelineCanvas.append('g')
            .attr('class', 'timeline-canvas-current-date')
            .attr('transform', 'translate(' + timelineCanvas.x(currentDate) + ')' );
        
            today.append("line")
                .style("stroke", this.todaysColour)
                .style("stroke-width", "1.5px")
                .style("stroke-dasharray", "7, 7")
                .style("shape-rendering", "crispEdges")
                .attr("y2", timelineHeight);
            
            today.append("rect")
                .style("fill", this.todaysColour)
                .style("width", "8")
                .style("height", "13")
                .style("rx", "3")
                .style("ry", "3")
                .style("x", "-4")
                .style("y", timelineHeight - 8)
        }
    
        timelineCanvas.redraw = function (domain) {
            var i = 0;
            var swimlane = 0;

            if (domain) {
                timelineCanvas.x.domain(domain);
            }

            let swimlanes = [];
            const unitInterval = (timelineCanvas.x.domain()[1] - timelineCanvas.x.domain()[0]) / timelineCanvas.width;

            let data = timelineData.data
                .filter(function (d) {
                    if (me.isLanguageRightToLeft) {
                        d.endTime = new Date(d.time.getTime() - unitInterval * (d.label.length * 6 + 80));
                        return timelineCanvas.x.domain()[0] < d.time && d.endTime < timelineCanvas.x.domain()[1];
                    }

                    d.endTime = new Date(d.time.getTime() + unitInterval * (d.label.length * 6 + 80));
                    return timelineCanvas.x.domain()[0] < d.endTime && d.time < timelineCanvas.x.domain()[1];
                })
                .filter(timelineCanvas.filter);

            me.totalZoomedRecords = data.length;

            timelineCanvas.currentDate = timelineCanvas
                .selectAll('[class~=timeline-canvas-current-date]')
                .attr('transform', 'translate(' + timelineCanvas.x(currentDate) + ')' );

            data.sort(me.sortByValue('time'));

            data.forEach(function (entry) {
                for (i = 0, swimlane = 0; i < swimlanes.length; i++, swimlane++) {
                    if (me.isLanguageRightToLeft) {
                        if (entry.endTime > swimlanes[i]) {
                            break;
                        }
                    } else {
                        if (entry.time > swimlanes[i]) {
                            break;
                        }
                    }
                }

                if (me.isLanguageRightToLeft) {
                    swimlanes[swimlane] = entry.time;
                } else {
                    swimlanes[swimlane] = entry.endTime;
                }
                entry.swimlane = swimlane;
            });

            timelineCanvas.width = timelineCanvas.x.range()[1];
            timelineCanvas.attr('width', timelineCanvas.width);

            const svgHeight = Math.max(timelineCanvas.y(swimlanes.length), timelineHeight);
            timelineCanvas.height = timelineHeight;

            timelineCanvas.attr('height', svgHeight - 1);
            timelineCanvas.SVGHeight = svgHeight;

            timelineCanvas.data = timelineCanvas
                .selectAll('[class~=timeline-canvas-record]')
                .data(data, function (d) {
                    return d.id;
                })
                .attr('transform', function (d) {
                    return 'translate(' + timelineCanvas.x(d.time) + ', ' + timelineCanvas.y(d.swimlane) + ')';
                });

            timelineCanvas.records = timelineCanvas.data
                .enter()
                .append('g')
                .attr('class', 'timeline-canvas-record')
                .attr('transform', function (d) {
                    return 'translate(' + timelineCanvas.x(d.time) + ', ' + timelineCanvas.y(d.swimlane) + ')';
                });

            if (timelineCanvas.records.size() > 0) {
                timelineCanvas.records
                    .append('rect')
                    .attr('class', 'timeline-canvas-icon-wrap')
                    .attr('style', function (d) {
                        let iconColour = '';
                        switch (d.type) {
                            case 'Call':
                                iconColour = '#06a59a';
                                break;
                            case 'Email':
                                iconColour = '#939393';
                                break;
                            case 'Event':
                                iconColour = '#CB65FF';
                                break;
                            case 'SNOTE':
                                iconColour = '#939393';
                                break;
                            default:
                                iconColour = d.iconBackground;
                                break;
                        }
                        return 'fill: ' + iconColour;
                    })
                    .attr('x', 0)
                    .attr('y', 0)
                    .attr('width', 24)
                    .attr('height', 24)
                    .attr('rx', 3)
                    .attr('ry', 3);

                timelineCanvas.records
                    .append('image')
                    .attr('x', 1)
                    .attr('y', 1)
                    .attr('height', 22)
                    .attr('width', 22)
                    .attr('xlink:href', function (d) {
                        let iconImage = '';

                        switch (d.type) {
                            case 'Call':
                                iconImage = '/img/icon/t4v35/standard/log_a_call.svg';
                                break;
                            case 'Email':
                                iconImage = '/img/icon/t4v35/standard/email.svg';
                                break;
                            case 'Event':
                                iconImage = '/img/icon/t4v35/standard/event.svg';
                                break;
                            case 'SNOTE':
                                iconImage = '/img/icon/t4v35/standard/note.svg';
                                break;
                            default:
                                iconImage = d.icon;
                                break;
                        }
                        return iconImage;
                    });

                timelineCanvas.records
                    .append('text')
                    .attr('class', 'timeline-canvas-record-label')
                    .attr('x', function () {
                        let x = 30;
                        switch (me.isLanguageRightToLeft) {
                            case true:
                                x = -6;
                                break;
                            default:
                                x = 30;
                                break;
                        }
                        return x;
                    })
                    .attr('y', 16)
                    .attr('font-size', 12)
                    .on('click', function (event, d) {
                        let drilldownId = d.recordId;
                        if (d.drilldownId !== '') {
                            drilldownId = d.drilldownId;
                        }

                        switch (d.objectName) {
                            case 'ContentDocumentLink': {
                                me[NavigationMixin.Navigate]({
                                    type: 'standard__namedPage',
                                    attributes: {
                                        pageName: 'filePreview'
                                    },
                                    state: {
                                        selectedRecordId: d.recordId
                                    }
                                });
                                break;
                            }
                            case 'CaseComment': {
                                const toastEvent = new ShowToastEvent({
                                    title: me.toast.NAVIGATION_HEADER,
                                    message: me.toast.NAVIGATION_BODY,
                                    messageData: [d.objectName]
                                });
                                this.dispatchEvent(toastEvent);
                                break;
                            }
                            default: {
                                me[NavigationMixin.Navigate]({
                                    type: 'standard__recordPage',
                                    attributes: {
                                        recordId: drilldownId,
                                        actionName: 'view'
                                    }
                                });
                                break;
                            }
                        }
                    })
                    .on('mouseover', function (event, d) {
                        let tooltipId = d.recordId;
                        let tooltipObject = d.objectName;
                        me.isTooltipLoading = true;

                        if (d.tooltipId !== '') {
                            tooltipId = d.tooltipId;
                            tooltipObject = d.tooltipObject;
                        }

                        me.mouseOverObjectAPIName = tooltipObject;
                        me.mouseOverRecordId = tooltipId;

                        me.mouseOverFallbackField = d.fallbackTooltipField;
                        me.mouseOverFallbackValue = d.fallbackTooltipValue;

                        me.mouseOverDetailLabel = d.detailFieldLabel;
                        me.mouseOverDetailValue = d.detailField;

                        me.mouseOverPositionLabel = d.positionDateField;
                        me.mouseOverPositionValue = d.positionDateValue;

                        me.isMouseOver = true;
                        let tooltipDIV = me.template.querySelector('div.tooltip-panel');
                        let tipPosition;

                        switch (me.isLanguageRightToLeft) {
                            case true:
                                tipPosition =
                                    this.getBoundingClientRect().top -
                                    30 +
                                    'px ;left:' +
                                    (this.getBoundingClientRect().left - tooltipDIV.offsetWidth - 15) +
                                    'px ;visibility:visible';
                                break;
                            default:
                                tipPosition =
                                    this.getBoundingClientRect().top -
                                    30 +
                                    'px ;left:' +
                                    (this.getBoundingClientRect().right + 15) +
                                    'px ;visibility:visible';
                                break;
                        }
                        tooltipDIV.setAttribute('style', 'top:' + tipPosition);
                    })
                    .on('mouseout', function () {
                        let tooltipDIV = me.template.querySelector('div.tooltip-panel');
                        tooltipDIV.setAttribute('style', 'visibility: hidden');
                        me.isMouseOver = false;
                        me.isTooltipLoading = true;
                    })
                    .text(function (d) {
                        return d.label;
                    });
            }
            timelineCanvas.data.exit().remove();
        };
        return timelineCanvas;
    }

    axis(axisConfig, targetSVG, target) {
        const me = this;
        const timelineCanvas = me._d3timelineCanvas;

        targetSVG.attr('width', target.width);

        let x_axis = d3
            .axisBottom(target.x)
            .tickSizeInner(axisConfig.innerTickSize)
            .ticks(axisConfig.ticks)
            .tickFormat(function (d) {
                let formattedDate = new Intl.DateTimeFormat(me.calculatedLOCALE(), {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric'
                }).format(d);
                return formattedDate;
            })
            .tickPadding(axisConfig.tickPadding);

        const axis = targetSVG
            .insert('g', ':first-child')
            .attr('class', axisConfig.class + '-' + me.timelineWidth)
            .call(x_axis);

        if (typeof axisConfig.translate === 'object') {
            axis.attr('transform', function () {
                return 'translate(' + axisConfig.translate[0] + ', ' + axisConfig.translate[1] + ')';
            });
        }

        axis.redraw = function () {
            targetSVG.attr('width', target.width);

            if (axisConfig.class === 'axis-ticks') {
                axisConfig.innerTickSize = -timelineCanvas.SVGHeight;
                axisConfig.translate = [0, timelineCanvas.SVGHeight];
            }

            x_axis = x_axis.tickSizeInner(axisConfig.innerTickSize);
            x_axis = x_axis.tickValues(axisConfig.tickValues);

            if (typeof axisConfig.translate === 'object') {
                axis.attr('transform', function () {
                    return 'translate(' + axisConfig.translate[0] + ', ' + axisConfig.translate[1] + ')';
                });
            }
            axis.call(x_axis);
        };

        return axis;
    }

    processError(type, header, message) {
        if (this.illustrationVisibility !== 'illustration') {
            this.isLoaded = true;
            this.illustrationVisibility = 'illustration';
            this.illustrationHeader = header;
            this.illustrationSubHeader = message;

            switch (type) {
                case 'No-Data':
                    this.illustrationType = 'Desert';
                    this.isError = false;
                    this.noData = true;
                    break;
                case 'No-Access':
                    this.illustrationType = 'NoAccess';
                    this.isError = false;
                    this.noData = false;
                    break;
                case 'No-Filter-Data':
                    this.illustrationType = 'Desert';
                    this.isError = false;
                    this.noFilterData = true;
                    break;
                case 'Setup-Error':
                    this.illustrationType = 'Setup';
                    this.isError = true;
                    this.noFilterData = false;
                    this.noData = false;
                    break;
                default:
                    this.illustrationType = 'PageNotAvailable';
                    this.isError = true;
                    break;
            }
        }
    }

    timelineMap() {
        const me = this;

        const timelineData = me._timelineData;
        const timelineMapSVG = me._d3timelineMapSVG;
        const timelineMap = timelineMapSVG;
        const timelineMapDIV = me.template.querySelector('div.timeline-map');

        timelineMap.x = d3.scaleTime().domain(timelineData.requestRange).range([0, timelineMapDIV.offsetWidth]);

        timelineMap.y = function (swimlane) {
            return Math.min(swimlane, 7) * 4 + 4;
        };

        timelineMap.filter = function (d) {
            if (me.isFilterLoaded === false || me.filterValues.includes(d.objectName)) {
                return true;
            }
            return false;
        };

        timelineMap.width = timelineMapDIV.offsetWidth;
        timelineMap.height = timelineMapDIV.offsetHeight;

        let currentDate = new Date();

        if ( this.showToday !== "No" ) {
            let today = timelineMap.append('g')
                .attr('class', 'timeline-map-current-date')
                .attr('transform', 'translate(' + timelineMap.x(currentDate) + ')' );
            
            today.append("line")
                .style("stroke", this.todaysColour)
                .style("stroke-width", "1.5px")
                .style("stroke-dasharray", "2, 2")
                .style("shape-rendering", "crispEdges")
                .attr("y2", timelineMap.height);
        }

        timelineMap.redraw = function () {
            var i = 0;
            var swimlane = 0;
            let swimlanes = [];
            const unitInterval = (timelineMap.x.domain()[1] - timelineMap.x.domain()[0]) / timelineMap.width;

            timelineMap.currentDate = timelineMap
                .selectAll('[class~=timeline-map-current-date]')
                .attr('transform', 'translate(' + timelineMap.x(currentDate) + ')' );

            let data = timelineData.data
                .filter(function (d) {
                    d.endTime = new Date(d.time.getTime() + unitInterval * 10);
                    return true;
                })
                .filter(timelineMap.filter);

            data.sort(me.sortByValue('time'));

            // calculating vertical layout for displaying data
            data.forEach(function (entry) {
                for (i = 0, swimlane = 0; i < swimlanes.length; i++, swimlane++) {
                    if (entry.time > swimlanes[i]) break;
                }
                entry.swimlane = swimlane;
                swimlanes[swimlane] = entry.endTime;
            });

            data = data.filter(function (d) {
                if (d.swimlane < 8) {
                    return true;
                }
                return false;
            });

            timelineMap.width = timelineMap.x.range()[1];
            timelineMapSVG.attr('width', timelineMap.width);

            timelineMap.data = timelineMap
                .selectAll('[class~=timeline-map-record]')
                .data(data, function (d) {
                    return d.id;
                })
                .attr('transform', function (d) {
                    return 'translate(' + timelineMap.x(d.time) + ', ' + timelineMap.y(d.swimlane) + ')';
                });

            timelineMap.records = timelineMap.data
                .enter()
                .append('g')
                .attr('class', 'timeline-map-record')
                .attr('transform', function (d) {
                    return 'translate(' + timelineMap.x(d.time) + ', ' + timelineMap.y(d.swimlane) + ')';
                });

            timelineMap.records
                .append('rect')
                .attr('style', function () {
                    return 'fill: #107cad; stroke: #107cad';
                })
                .attr('width', 3)
                .attr('height', 2)
                .attr('rx', 0.2)
                .attr('ry', 0.2);

            if (data.length <= 0) {
                me.processError('No-Filter-Data', me.error.NO_DATA_HEADER, me.error.NO_DATA_SUBHEADER);
            }
        };
        return timelineMap;
    }

    brush() {
        const me = this;
        const d3timeline = me._d3timelineCanvas;
        const timelineData = me._timelineData;
        const timelineAxis = me._d3timelineCanvasAxis;
        const timelineAxisLabel = me._d3timelineCanvasAxisLabel;
        const timelineMap = me._d3timelineMap;
        const timelineMapSVG = me._d3timelineMapSVG;
        const timelineMapLayoutA = timelineMapSVG.append('g');
        const timelineMapLayoutB = timelineMapLayoutA.append('g');
        let emptySelectionStart;
        let defaultZoomDate;
        let startBrush;
        let endBrush;

        switch (this.zoomTo) {
            //case 'Historical Date':
            //   TODO
            case 'Last Activity':
                defaultZoomDate = new Date(timelineData.maxTime).getTime();
                break;
            case 'First Activity':
                defaultZoomDate = new Date(timelineData.minTime).getTime();
                break;
            default:
                defaultZoomDate = new Date().getTime();
                break;
        }

        if (me.zoomStartDate !== undefined) {
            startBrush = new Date(me.zoomStartDate).toLocaleDateString('en-GB', {
                day: 'numeric',
                month: 'short',
                year: 'numeric'
            });
            endBrush = new Date(me.zoomEndDate).toLocaleDateString('en-GB', {
                day: 'numeric',
                month: 'short',
                year: 'numeric'
            });
        } else {
            startBrush = new Date(defaultZoomDate);
            startBrush.setDate(startBrush.getDate() - me.daysToShow / 2);
            endBrush = new Date(defaultZoomDate);
            endBrush.setDate(endBrush.getDate() + me.daysToShow / 2);
        }

        timelineMapLayoutB.append('g').attr('class', 'brush').attr('transform', 'translate(0, -1)');

        const xBrush = d3.select(this.template.querySelector('div.timeline-map')).select('g.brush');

        let brush = d3
            .brushX()
            .extent([
                [0, 0],
                [timelineMap.width, timelineMap.height]
            ])
            .on('brush', brushed)
            .on('start', brushStart)
            .on('end', brushEnd);

        const handle = xBrush
            .selectAll('.handle--custom')
            .data([{ type: 'w' }, { type: 'e' }])
            .enter()
            .append('path')
            .attr('class', 'handle--custom')
            .attr('fill', '#107cad')
            .attr('fill-opacity', 1)
            .attr('stroke', '#000')
            .attr('height', 40)
            .attr('stroke-width', 1)
            .attr('cursor', 'ew-resize')
            .attr(
                'd',
                'M0,0 L75,0 L75,176 C75,184.284271 68.2842712,191 60,191 L15,191 C6.71572875,191 1.01453063e-15,184.284271 0,176 L0,0 L0,0 Z'
            );
        xBrush.call(brush).call(brush.move, [new Date(startBrush), new Date(endBrush)].map(timelineMap.x));

        brush.redraw = function () {
            brush = d3
                .brushX()
                .extent([
                    [0, 0],
                    [timelineMap.width, timelineMap.height]
                ])
                .on('brush', brushed)
                .on('start', brushStart)
                .on('end', brushEnd);

            startBrush = new Date(me.zoomStartDate).toLocaleDateString('en-GB', {
                day: 'numeric',
                month: 'short',
                year: 'numeric'
            });
            endBrush = new Date(me.zoomEndDate).toLocaleDateString('en-GB', {
                day: 'numeric',
                month: 'short',
                year: 'numeric'
            });

            xBrush.call(brush).call(brush.move, [new Date(startBrush), new Date(endBrush)].map(timelineMap.x));
        };

        function brushed(event) {
            const selection = event.selection;
            const dommy = [];

            if (selection) {
                dommy.push(timelineMap.x.invert(selection[0]));
                dommy.push(timelineMap.x.invert(selection[1]));

                d3timeline.redraw(dommy);
                timelineAxis.redraw();
                timelineAxisLabel.redraw();

                handle.attr('transform', function (d, i) {
                    return 'translate(' + (selection[i] - 2) + ', ' + 0 + ') scale(0.05)';
                });

                let a = d3timeline.x.domain()[1];
                let b = d3timeline.x.domain()[0];

                a = new Date(a);
                b = new Date(b);

                // To calculate the time difference of two dates
                let Difference_In_Time = a.getTime() - b.getTime();

                // To calculate the no. of days between two dates
                let Difference_In_Days = Math.round(Difference_In_Time / (1000 * 3600 * 24));
                me.daysToShow = Difference_In_Days;

                const dateTimeFormat = new Intl.DateTimeFormat(me.calculatedLOCALE(), {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric'
                });

                me.zoomStartDate = timelineMap.x
                    .invert(selection[0])
                    .toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
                me.zoomEndDate = timelineMap.x
                    .invert(selection[1])
                    .toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });

                me.localisedZoomStartDate = dateTimeFormat.format(new Date(timelineMap.x.invert(selection[0])));
                me.localisedZoomEndDate = dateTimeFormat.format(new Date(timelineMap.x.invert(selection[1])));
            }
        }

        function brushStart(event) {
            const selection = event.selection;

            if (selection) {
                emptySelectionStart = timelineMap.x.invert(selection[0]);
                handle.attr('transform', function (d, i) {
                    return 'translate(' + (selection[i] - 2) + ', ' + 0 + ') scale(0.05)';
                });
            }
        }

        function brushEnd(event) {
            const selection = event.selection;

            if (selection === null) {
                me.zoomStartDate = emptySelectionStart.toLocaleDateString('en-GB', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric'
                });

                let eDate = new Date(me.zoomStartDate);
                eDate.setDate(eDate.getDate() + 14);

                me.zoomEndDate = eDate.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
                me._d3brush.redraw();
            }
        }

        return brush;
    }

    debounce = (fn, time) => {
        let timeout;

        return function () {
            const functionCall = () => fn.apply(this, arguments);

            clearTimeout(timeout);
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            timeout = setTimeout(functionCall, time);
        };
    };

    sortByValue(param) {
        return function (a, b) {
            return a[param] < b[param] ? -1 : a[param] > b[param] ? 1 : 0;
        };
    }

    get isLoading() {
        if (!this.isLoaded) {
            return true;
        }
        return false;
    }

    get showSummary() {
        if (this.isError || this.noData || this.noFilterData || !this.isLoaded) {
            return false;
        }
        return true;
    }

    get showFallbackTooltip() {
        if (this.isMouseOver && this.mouseOverFallbackField != null && this.mouseOverFallbackField !== '') {
            return true;
        }
        return false;
    }

    get showRecordTooltip() {
        if (this.isMouseOver && this.showFallbackTooltip === false) {
            return true;
        }
        return false;
    }

    toggleFilter() {
        const filterPopover = this.template.querySelector('div.timeline-filter');
        const filterClasses = String(filterPopover.classList);
        const refreshButton = this.template.querySelector('lightning-button-icon.timeline-refresh');

        if (filterClasses.includes('slds-is-open')) {
            refreshButton.disabled = false;
            filterPopover.classList.remove('slds-is-open');
            this.isFilter = false;
        } else {
            refreshButton.disabled = true;
            filterPopover.classList.add('slds-is-open');
            this.isFilter = true;
        }

        switch (this.isLanguageRightToLeft) {
            case true:
                filterPopover.classList.remove('slds-float_right');
                filterPopover.classList.remove('slds-panel_docked-right');
                filterPopover.classList.add('slds-float_left');
                filterPopover.classList.add('slds-panel_docked-left');
                filterPopover.setAttribute('style', 'left: 0px');
                break;
            default:
                filterPopover.setAttribute('style', 'right: 0px');
                break;
        }
    }

    get filterOptions() {
        this.handleAllTypes();
        return this.objectFilter;
    }

    get selectedFilterValues() {
        return this.filterValues.join(', ');
    }

    handleFilterChange(e) {
        this.filterValues = e.detail.value;
        this.handleAllTypes();
        this.isFilterUpdated = false;
        if (JSON.stringify(this.filterValues) !== JSON.stringify(this.startingFilterValues)) {
            this.isFilterUpdated = true;
        }
    }

    handleAllTypesChange(e) {
        if (e.target.checked === true) {
            this.filterValues = this.allFilterValues;
        } else if (e.target.checked === false) {
            this.filterValues = [];
        }

        this.isFilterUpdated = false;
        if (JSON.stringify(this.filterValues) !== JSON.stringify(this.startingFilterValues)) {
            this.isFilterUpdated = true;
        }
    }

    handleAllTypes() {
        const allTypesCheckbox = this.template.querySelector('input.all-types-checkbox');
        const countAllValues = this.allFilterValues.length;
        const countSelectedValues = this.filterValues.length;

        if (countSelectedValues !== countAllValues && countSelectedValues > 0) {
            allTypesCheckbox.checked = false;
            allTypesCheckbox.indeterminate = true;
        }

        if (countSelectedValues === countAllValues) {
            allTypesCheckbox.indeterminate = false;
            allTypesCheckbox.checked = true;
        }

        if (countSelectedValues < 1) {
            allTypesCheckbox.indeterminate = false;
            allTypesCheckbox.checked = false;
        }
    }

    applyFilter() {
        this.refreshTimeline();
        this.isFilterUpdated = false;
        this.startingFilterValues = this.filterValues;
        this.toggleFilter();
    }

    cancelFilter() {
        this.filterValues = this.startingFilterValues;
        this.isFilterUpdated = false;
        this.toggleFilter();
    }

    refreshTimeline() {
        this.isError = false;
        this.noFilterData = false;

        if (this.totalTimelineRecords > 0) {
            this.illustrationVisibility = 'illustration-hidden';
            this._d3timelineMapSVG.selectAll('[class~=timeline-map-record]').remove();
            this._d3timelineMap.redraw();
            this._d3brush.redraw();
        }
    }

    tooltipLoaded() {
        this.isTooltipLoading = false;
    }

    @api
    get timelineSummaryText() {
        let summary = '';

        if (this.flexipageRegionWidth === 'SMALL') {
            summary = this.localisedZoomStartDate + ' - ' + this.localisedZoomEndDate;
        } else {
            summary =
                this.label.SHOWING +
                ' ' +
                this.localisedZoomStartDate +
                ' - ' +
                this.localisedZoomEndDate +
                ' • ' +
                this.daysToShow +
                ' ' +
                this.label.DAYS +
                ' • ' +
                this.totalZoomedRecords +
                ' ' +
                this.label.ITEMS;
        }
        return summary;
    }
}
