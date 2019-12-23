import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import shortDateFormat from '@salesforce/i18n/dateTime.shortDateFormat';
import LOCALE from '@salesforce/i18n/locale';

import getTimelineData from '@salesforce/apex/timelineService.getTimelineRecords';

import d3JS from '@salesforce/resourceUrl/d3minified';
import momentJS from '@salesforce/resourceUrl/momentminified';  

import APEX from '@salesforce/label/c.Timeline_Error_Apex';
import NO_DATA_HEADER from '@salesforce/label/c.Timeline_Error_NoDataHeader';
import NO_DATA_SUBHEADER from '@salesforce/label/c.Timeline_Error_NoDataSubHeader';
import JAVASCRIPT_LOAD from '@salesforce/label/c.Timeline_Error_JavaScriptResources';
import UNHANDLED from '@salesforce/label/c.Timeline_Error_Unhandled';

import DAYS from '@salesforce/label/c.Timeline_Label_Days';
import SHOWING from '@salesforce/label/c.Timeline_Label_Showing';
import ITEMS from '@salesforce/label/c.Timeline_Label_Items';
import FILTERS from '@salesforce/label/c.Timeline_Label_Filters';
import TYPE_LEGEND from '@salesforce/label/c.Timeline_Label_Filter_Type_Legend';


export default class timeline extends NavigationMixin(LightningElement) {
    //Adminstrator accessible attributes in app builder
    @api timelineTitle;                                             //title for the lwc set as design attribute
    @api preferredHeight;                                           //height of the timeline set as design attribute 
    @api earliestRange;                                             //How far back in time to go
    @api latestRange;                                               //How far into the future to go 
    @api zoomTo;                                                    //Zoom to current dat or latest activity
    @api daysToShow;                                                //number of days to plot for the default zoom

    //Component calculated attributes
    @api recordId;                                                  //current record id of lead, case, opportunity, contact or account

    @api flexipageRegionWidth;                                      //SMALL, MEDIUM and LARGE based on where the component is placed in App Builder templates
    
    @track timelineStart;                                           //Calculated based on the earliestRange 
    @track timelineEnd;                                             //Calculated based on the latestRange 
    
    @track zoomStartDate;                                           //Start date of the current zoom
    @track zoomEndDate;                                             //End date of the current zoom

    @track localisedZoomStartDate;                                  //Start date of the current zoom
    @track localisedZoomEndDate;                                    //End date of the current zoom
    
    @track totalTimelineRecords;                                    //Total number of records returned
    @track totalZoomedRecords;                                      //Total records in zoom
   
    @track noData = false;                                          //Boolean when no data is returned
    @track isLoaded = false;                                        //Boolean when timeline data is loaded
    @track isError = false;                                         //Boolean when there is an error

    @track isMouseOver = false;                                     //Boolean when mouse over is detected                          
    @track mouseOverRecordId;                                       //Current Id of the record being hovered over
    @track mouseOverObjectAPIName;                                  //API Name for the object being hovered over
    @track mouseOverDetailLabel; 
    @track mouseOverDetailValue
    @track mouseOverFallbackField;
    @track mouseOverFallbackValue;

    @track filterValues = [];
    @track isFilter;

    @track timelineVisibility = 'timeline-container'                //Toggles the class to show and hide the timeline

    @track illustrationHeader;                                      //Header to display when an information box displays
    @track illustrationSubHeader;                                   //Sub Header to display when an info box appears
    @track illustrationType;                                        //Type of illustration to display, 'error' or 'no data'

    label = {
        DAYS,
        SHOWING,
        ITEMS,
        FILTERS,
        TYPE_LEGEND,
    };

    error = {
        APEX,
        NO_DATA_HEADER, 
        NO_DATA_SUBHEADER, 
        JAVASCRIPT_LOAD, 
        UNHANDLED,
    };

    _timelineData = null;
    _timelineHeight = null;

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

    _d3LocalisedShortDateFormat = null;
    _d3Rendered = false;
   
    disconnectedCallback() {
        window.removeEventListener('resize', this.debounce);
    }

    connectedCallback() {
        this._timelineHeight = this.getPreferredHeight();
        this._d3LocalisedShortDateFormat = this.userDateFormat();
    }

    renderedCallback() { 

        if ( !this._d3Rendered ) {
            //set the height of the component as the height is dynamic based on the attributes
            let timelineDIV = this.template.querySelector("div.timeline-canvas");
            
            timelineDIV.setAttribute('style', 'height:' + this._timelineHeight + 'px');
            
            Promise.all([
                loadScript(this, d3JS),
                loadScript(this, momentJS),
            ])
            .then(() => {
                //Setup d3 timeline by manipulating the DOM and do it once only as render gets called many times
                this._d3timelineCanvasDIV = d3.select(this.template.querySelector("div.timeline-canvas"));
                this._d3timelineCanvasMapDIV = d3.select(this.template.querySelector("div.timeline-canvas-map"));
                this._d3timelineCanvasSVG = d3.select(this.template.querySelector("div.timeline-canvas")).append("svg");
                this._d3timelineCanvasAxisSVG = d3.select(this.template.querySelector('div.timeline-canvas-axis')).append("svg");
                this._d3timelineMapSVG = d3.select(this.template.querySelector('div.timeline-map')).append("svg");
                this._d3timelineMapAxisSVG = d3.select(this.template.querySelector('div.timeline-map-axis')).append("svg");
                
                this.processTimeline();
            })
            .catch(error => {
                this.processError('Error', this.error.JAVASCRIPT_LOAD, error);
            })
            
            this._d3Rendered = true;
        }

        let timelineIllustrationContainer = this.template.querySelector("div.illustration-container");

        //The timeline container for errors is hidden by default so might not always be valid. But if it's been shown change the height
        if ( timelineIllustrationContainer !== undefined &&  timelineIllustrationContainer !== null ) {
            timelineIllustrationContainer.setAttribute('style', 'height:' + (this._timelineHeight + 175) + 'px')
        }
    }

    processTimeline() {
        const me = this;

        me.isLoaded = false;

        me._d3timelineCanvasSVG.selectAll("*").remove();
        me._d3timelineCanvasAxisSVG.selectAll("*").remove();
        me._d3timelineMapSVG.selectAll("*").remove();
        me._d3timelineMapAxisSVG.selectAll("*").remove();

        getTimelineData({parentObjectId: me.recordId, earliestRange: me.earliestRange, latestRange: me.latestRange})
        .then(result => {
            try {
                if ( result.length > 0 ) {
                    me.totalTimelineRecords = result.length;

                    //Process timeline records
                    me._timelineData = me.getTimelineRecords(result);

                    //Process timeline canvas
                    me._d3timelineCanvas = me.timelineCanvas();

                    const axisDividerConfig = {
                        tickFormat: '%d %b %Y',
                        innerTickSize: -me._d3timelineCanvas.SVGHeight,
                        translate: [0, me._d3timelineCanvas.SVGHeight],
                        tickPadding: 0,
                        ticks: 6,
                        class: 'axis-ticks'
                    };
                
                    me._d3timelineCanvasAxis = me.axis(axisDividerConfig, me._d3timelineCanvasSVG, me._d3timelineCanvas);
 
                    const axisLabelConfig = {
                        //tickFormat: '%d %b %Y',
                        tickFormat: me._d3LocalisedShortDateFormat,
                        innerTickSize: 0,
                        tickPadding: 2,
                        translate: [0, 5],
                        ticks: 6,
                        class: 'axis-label'
                    };
                    
                    me._d3timelineCanvasAxisLabel = me.axis(axisLabelConfig, me._d3timelineCanvasAxisSVG, me._d3timelineCanvas);

                    //Process timeline map
                    me._d3timelineMap = me.timelineMap();
                    me._d3timelineMap.redraw();

                    const mapAxisConfig = {
                        //tickFormat: '%b %Y',
                        tickFormat: me._d3LocalisedShortDateFormat,
                        innerTickSize: 4,
                        tickPadding: 4,
                        ticks: 6,
                        class: 'axis-label'
                    };
                    
                    me._d3timelineMapAxis = me.axis(mapAxisConfig, me._d3timelineMapAxisSVG, me._d3timelineMap);

                    me._d3brush = me.brush();

                    window.addEventListener('resize', me.debounce(() => {
                        try {
                            if ( me.template.querySelector("div.timeline-canvas").offsetWidth !== 0 ) {
                                me._d3timelineCanvas.x.range([0, me.template.querySelector("div.timeline-canvas").offsetWidth]);
                                me._d3timelineMap.x.range([0, Math.max(me.template.querySelector('div.timeline-map').offsetWidth, 0)]);
                                //me._d3timelineCanvas.redraw();
                                me._d3timelineCanvasAxis.redraw();
                                me._d3timelineCanvasAxisLabel.redraw();
                                me._d3timelineMap.redraw();
                                me._d3timelineMapAxis.redraw();
                                me._d3brush.redraw();
                            }
                        }
                        catch(error) {
                            //stay silent
                        }
                      }, 200));

                    me.isLoaded = true;
                }
                else {
                    me.processError('No-Data', me.error.NO_DATA_HEADER, me.error.NO_DATA_SUBHEADER);
                }  
            }
            catch(error) {
                me.processError('Error', me.error.UNHANDLED, error.message);
            }
        })
        .catch(error => {
            me.processError('Error', me.error.APEX, error.body.message);
        })
        
    }

    getTimelineRecords ( result ) {
        let timelineRecords = {};
        let timelineResult = [];
        let timelineTimes = [];

        result.forEach(function(record, index) {
            let recordCopy = {};

            recordCopy.recordId = record.objectId;
            recordCopy.id = index;
            recordCopy.label = record.detailField.length <= 30 ? record.detailField : record.detailField.slice(0, 30) + '...';
            recordCopy.time = moment(record.positionDateValue, 'YYYY-MM-DD HH:mm:ss').toDate(); 
            recordCopy.week =  moment(record.positionDateValue, 'YYYY-MM-DD').startOf('week');
            recordCopy.objectName = record.objectName;
            recordCopy.objectLabel = record.objectLabel;
            recordCopy.positionDateField = record.positionDateField;
            recordCopy.detailField = record.detailField;
            recordCopy.detailFieldLabel = record.detailFieldLabel;

            recordCopy.fallbackTooltipField = record.fallbackTooltipField;
            recordCopy.fallbackTooltipValue = record.fallbackTooltipValue;

            recordCopy.type = record.type;
            recordCopy.icon = record.icon;
            recordCopy.iconBackground = record.iconBackground;

            timelineResult.push(recordCopy);
            timelineTimes.push(recordCopy.time);
        });   

        timelineRecords.data = timelineResult;
        timelineRecords.minTime = d3.min(timelineTimes);
        timelineRecords.maxTime = d3.max(timelineTimes);
        timelineRecords.objectFilters = [...new Set(timelineRecords.data.map(item => item.objectLabel))];
       
        this.timelineStart = moment().subtract(this.earliestRange, 'years').format('DD MMM YYYY');
        this.timelineEnd = moment().add(this.latestRange, 'years').format('DD MMM YYYY');

        timelineRecords.requestRange = [moment().subtract(this.earliestRange, 'years').toDate(), moment().add(this.latestRange, 'years').toDate()];
        
        return timelineRecords;
    }

    timelineCanvas() {
        
        const me = this;
        const timelineCanvasDIV = this.template.querySelector("div.timeline-canvas");
        const timelineCanvas = me._d3timelineCanvasSVG;
        const timelineData = me._timelineData;
        const timelineHeight = me._timelineHeight;

        const width = timelineCanvasDIV.offsetWidth;

        timelineCanvasDIV.setAttribute('style', 'max-height:' + timelineHeight + 'px');
        timelineCanvas.SVGHeight = timelineHeight;

        timelineCanvas.x = d3.scaleTime()
            .domain(timelineData.requestRange)
            .rangeRound([0, width]);

            timelineCanvas.y = function(swimlane) {
            return swimlane * 25 * 1 + (swimlane + 1) * 5;
        };

        timelineCanvas.width = width;

        timelineCanvas.height = timelineHeight;
       
        timelineCanvas.filter = function(d) {
            //TODO - Filter options go here - we just need the list of objects to filter out
            if (d.objectName === 'TODO_FILTER') { return false; }
              
            return true;
        };

        timelineCanvas.redraw = function(domain) {
            var i = 0;
            var swimlane = 0;

            if (domain) {
                timelineCanvas.x.domain(domain);
            }

            let swimlanes = [];
            const unitInterval = (timelineCanvas.x.domain()[1] - timelineCanvas.x.domain()[0]) / timelineCanvas.width;

            let data = timelineData.data.filter(function(d) {
                            d.endTime = new Date(d.time.getTime() + unitInterval * (d.label.length * 5 + 70));
                            return timelineCanvas.x.domain()[0] < d.endTime && d.time < timelineCanvas.x.domain()[1];
                          }).filter(timelineCanvas.filter);

            me.totalZoomedRecords = data.length;

            data.sort(me.sortByValue('time'));

            data.forEach(function(entry) {
                for (i = 0, swimlane = 0; i < swimlanes.length; i++, swimlane++) {
                    if (entry.time > swimlanes[i]) break;
                }
                entry.swimlane = swimlane;
                swimlanes[swimlane] = entry.endTime;
            });

            timelineCanvas.width = timelineCanvas.x.range()[1];
            timelineCanvas.attr('width', timelineCanvas.width);

            const svgHeight = Math.max(timelineCanvas.y(swimlanes.length), timelineHeight);
            timelineCanvas.height = timelineHeight;

            timelineCanvas.attr('height', svgHeight);
            timelineCanvas.SVGHeight = svgHeight;

            timelineCanvas.data = timelineCanvas.selectAll('[class~=timeline-canvas-record]')
                                    .data(data, function(d) {
                                        return d.id
                                    })
                                    .attr('transform', function(d) {
                                        return 'translate(' + timelineCanvas.x(d.time) + ', ' + timelineCanvas.y(d.swimlane) + ')';
                                    });

            timelineCanvas.records = timelineCanvas.data
                                      .enter().append('g')
                                      .attr('class', 'timeline-canvas-record')
                                      .attr('transform', function(d) {
                                          return 'translate(' + timelineCanvas.x(d.time) + ', ' + timelineCanvas.y(d.swimlane) + ')';
                                      });
            
            if ( timelineCanvas.records.size() > 0 ) {
                timelineCanvas.records.append('rect')
                    .attr('class', 'timeline-canvas-icon-wrap')
                    .attr('style', function(d) {
                        let iconColour = '';
                        switch (d.objectName + '-' + d.type) {
                            case 'Task-Call':
                                iconColour = '#48C3CC';
                                break;
                            case 'Task-Email':
                                iconColour = '#95AEC5';
                                break;
                            case 'ContentDocumentLink-SNOTE':
                                iconColour = '#E6D478';
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
            
                timelineCanvas.records.append('image')
                    .attr('x', 1)
                    .attr('y', 1)
                    .attr('height', 22)
                    .attr('width', 22)
                    .attr('xlink:href', function(d) {
                        let iconImage = '';
                        switch (d.objectName + '-' + d.type) {
                            case 'Task-Call':
                                iconImage = '/img/icon/t4v35/standard/log_a_call.svg';
                                break;
                            case 'Task-Email':
                                iconImage = '/img/icon/t4v35/standard/email.svg';
                                break;
                            case 'ContentDocumentLink-SNOTE':
                                iconImage = '/img/icon/t4v35/standard/note.svg';
                                break;
                            default:
                                iconImage = d.icon;
                                break;
                        }
                        return iconImage;
                    });

                timelineCanvas.records.append('rect')
                    .attr('class', 'timeline-canvas-record-wrap')
                    .attr('x', 24 + 8)
                    .attr('y', 0)
                    .attr('height', 24)
                    .attr('rx', 3)
                    .attr('ry', 3);
                timelineCanvas.records.append('line')
                    .attr('class', 'timeline-canvas-record-line')
                    .attr('x1', 24).attr('y1', 12)
                    .attr('x2', 24 + 8).attr('y2', 12);
                timelineCanvas.records.append('text')
                    .attr("class", 'timeline-canvas-record-label')
                    .attr('x', 24 + 10)
                    .attr('y', 16)
                    .attr('font-size', 12)
                    .on('click', function(d) {

                        switch (d.objectName) {
                            case 'ContentDocumentLink':
                                me[NavigationMixin.Navigate]({
                                    type: 'standard__namedPage',
                                    attributes: {
                                        pageName: 'filePreview'
                                    },
                                    state : {
                                        selectedRecordId:d.recordId
                                    }
                                });
                                break
                            default:
                                me[NavigationMixin.Navigate]({
                                    type: 'standard__recordPage',
                                    attributes: {
                                        recordId: d.recordId,
                                        actionName: 'view'
                                    }
                                }); 
                                break;
                        }
                    })
                    .on('mouseover', function(d) {
                        me.mouseOverObjectAPIName = d.objectName;
                        me.mouseOverRecordId = d.recordId;
                        me.mouseOverFallbackField = d.fallbackTooltipField;
                        me.mouseOverFallbackValue = d.fallbackTooltipValue;

                        me.mouseOverDetailLabel = d.detailFieldLabel;
                        me.mouseOverDetailValue = d.detailField;

                        me.isMouseOver = true;
                        let tooltipDIV = me.template.querySelector("div.tooltip-panel");
                        tooltipDIV.setAttribute('style', 'top:' + (this.getBoundingClientRect().top - 30) + 'px ;left:' + (this.getBoundingClientRect().right + 15) + 'px ;visibility:visible');
                    })
                    .on('mouseout', function() {
                        let tooltipDIV = me.template.querySelector("div.tooltip-panel");
                        tooltipDIV.setAttribute('style', 'visibility: hidden');
                        me.isMouseOver = false;
                    })
                    .text(function(d) {
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

        let x_axis = d3.axisBottom(target.x)
                        .tickSizeInner(axisConfig.innerTickSize)
                        .ticks(axisConfig.ticks)
                        .tickFormat(d3.timeFormat(axisConfig.tickFormat))
                        .tickPadding(axisConfig.tickPadding);

        const axis = targetSVG.insert('g', ':first-child')
                        .attr('class', axisConfig.class + '-' + me.flexipageRegionWidth)
                        .call(x_axis);

        if (typeof axisConfig.translate === 'object') {
            axis.attr('transform', function() {
                return 'translate(' + axisConfig.translate[0] + ', ' + axisConfig.translate[1] + ')';
            });
        }

        axis.redraw = function() {
            targetSVG.attr('width', target.width);

            if ( axisConfig.class === 'axis-ticks' ) {
                axisConfig.innerTickSize = -timelineCanvas.SVGHeight;
                axisConfig.translate = [0, timelineCanvas.SVGHeight];
            }

            x_axis = x_axis.tickSizeInner(axisConfig.innerTickSize);
            x_axis = x_axis.tickValues(axisConfig.tickValues);
        
            if ( typeof axisConfig.translate === 'object') {
                axis.attr('transform', function() {
                    return 'translate(' + axisConfig.translate[0] + ', ' + axisConfig.translate[1] + ')';
                });
            }
            axis.call(x_axis);
        };

        return axis;
    }

    processError(type, header, message) {

        this.isLoaded = true;
        this.timelineVisibility = 'timeline-container-hidden';

        if ( type === 'Error' ) {
            this.isError = true;
        }
        else {
            this.isError = false;
            this.noData = true;
        }

        this.illustrationType = type;
        this.illustrationHeader = header;
        this.illustrationSubHeader = message; 
    }

    getPreferredHeight() {
        let height;

        switch (this.preferredHeight) {
            case '1 - Smallest':
                height = 125;
                break;
            case '2 - Small':
                height = 200;
                break;
            case '3 - Default':
                height = 275;
                break;
            case '4 - Big':
                height = 350;
                break;
            case '5 - Biggest':
                height = 425;
                break;   
            default:
                height = 275;
                break;
        }

        return height;
    }

    timelineMap() {
        const me = this;
        
        const timelineData = me._timelineData;
        const timelineMapSVG = me._d3timelineMapSVG;
        const timelineMap = timelineMapSVG;
        const timelineMapDIV = me.template.querySelector('div.timeline-map');

        timelineMap.x = d3.scaleTime()
                        .domain(timelineData.requestRange)
                        .range([0, timelineMapDIV.offsetWidth]);

        timelineMap.y = function(swimlane) {
            return Math.min(swimlane, 7) * 4 + 4;
        };

        timelineMap.filter = function(d) {
           //TODO - Filter options go here - we just need the list of objects to filter out
           if (d.objectName === 'TODO_FILTER') { return false; }
              
           return true;
        };

        timelineMap.width = timelineMapDIV.offsetWidth;
        timelineMap.height = timelineMapDIV.offsetHeight;

        timelineMap.redraw = function() {
            var i = 0;
            var swimlane = 0;
            let swimlanes = [];
            const unitInterval = ( timelineMap.x.domain()[1] - timelineMap.x.domain()[0] ) / timelineMap.width;

            let data = timelineData.data.filter(function(d) {
                          d.endTime = new Date(d.time.getTime() + unitInterval * 10);
                          return true;
                      }).filter(timelineMap.filter);

            data.sort(me.sortByValue('time'));

            // calculating vertical layout for displaying data
            data.forEach(function(entry) {
                for (i = 0, swimlane = 0; i < swimlanes.length; i++, swimlane++) {
                    if (entry.time > swimlanes[i]) break;
                }
                entry.swimlane = swimlane;
                swimlanes[swimlane] = entry.endTime;
            });

            timelineMap.width = timelineMap.x.range()[1];
            timelineMapSVG.attr('width', timelineMap.width);

            timelineMap.data = timelineMap.selectAll('[class~=timeline-map-record]')
                                  .data(data, function(d) {
                                      return d.id
                                  })
                                  .attr('transform', function(d) {
                                      return 'translate(' + timelineMap.x(d.time) + ', ' + timelineMap.y(d.swimlane) + ')';
                                  });

            timelineMap.records = timelineMap.data
                                    .enter().append('g')
                                    .attr('class', 'timeline-map-record')
                                    .attr('transform', function(d) {
                                        return 'translate(' + timelineMap.x(d.time) + ', ' + timelineMap.y(d.swimlane) + ')';
                                    });
            
            timelineMap.records.append('rect')
                    //.attr('class', 'timeline-map-record')
                    .attr('style', function() {
                        return 'fill: #98C3EE; stroke: #4B97E6';
                    })
                    .attr('width', 3)
                    .attr('height', 2)
                    .attr('rx', 0.2)
                    .attr('ry', 0.2);
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
        const timelineMapLayoutA = timelineMapSVG.append("g");
        const timelineMapLayoutB = timelineMapLayoutA.append("g");
        let defaultZoomDate;

        switch (this.zoomTo) {
            case 'Current Date':
                defaultZoomDate = new Date().getTime();
                break;
            case 'Last Activity':
                defaultZoomDate = moment(timelineData.maxTime).toDate();
                break;
            default:
                defaultZoomDate = new Date().getTime();
                break;
        }
  
        timelineMapLayoutB.append("g")
            .attr("class", "brush")
            .attr("transform", 'translate(0, -1)');

        const xBrush = d3.select(this.template.querySelector("div.timeline-map")).select("g.brush");

        let brush = d3.brushX()
            .extent([[0, 0], [timelineMap.width, timelineMap.height]])
            .on('brush', brushed)
            .on('start', brushStart)

        const handle = xBrush.selectAll(".handle--custom")
            .data([{type: "w"}, {type: "e"}])
            .enter().append("path")
              .attr("class", "handle--custom")
              .attr("fill", "#4b97e6")
              .attr("fill-opacity", 0.8)
              .attr("stroke", "#000")
              .attr('height', 40)
              .attr("stroke-width", 1)
              .attr("cursor", "ew-resize")
              .attr("d", 'M0,0 L75,0 L75,176 C75,184.284271 68.2842712,191 60,191 L15,191 C6.71572875,191 1.01453063e-15,184.284271 0,176 L0,0 L0,0 Z');
        xBrush
            .call(brush)
            .call(brush.move, [moment(defaultZoomDate).subtract( (me.daysToShow/2), 'days' ).toDate(), moment(defaultZoomDate).add( (me.daysToShow/2), 'days' ).toDate()].map(timelineMap.x))
 
        brush.redraw = function() {

            brush = d3.brushX()
                .extent([[0, 0], [timelineMap.width, timelineMap.height]])
                .on('brush', brushed)
                .on('start', brushStart)

            const startBrush = moment(me.zoomStartDate).format("DD MMM YYYY");
            const endBrush = moment(me.zoomEndDate).format("DD MMM YYYY");

            xBrush
                .call(brush)
                .call(brush.move, [new Date(startBrush), new Date(endBrush)].map(timelineMap.x))
        };
        
        function brushed() {

            const selection = d3.event.selection;
            const dommy = [];

            if(selection){
                dommy.push(timelineMap.x.invert(selection[0]));
                dommy.push(timelineMap.x.invert(selection[1]));

                //this.d3timelineCanvas = d3timeline.redraw(dommy);
                d3timeline.redraw(dommy);
                timelineAxis.redraw();
                timelineAxisLabel.redraw();
                
                handle.attr("transform", function(d, i) { 
                    return "translate(" + (selection[i] - 2) + ", " + 0  + ") scale(0.05)"; 
                });

                me.daysToShow = moment(d3timeline.x.domain()[1]).diff(moment(d3timeline.x.domain()[0]), 'days');

                const dateTimeFormat = new Intl.DateTimeFormat(LOCALE);
  
                me.zoomStartDate = moment(timelineMap.x.invert(selection[0])).format("DD MMM YYYY");
                me.zoomEndDate = moment(timelineMap.x.invert(selection[1])).format("DD MMM YYYY");
            
                me.localisedZoomStartDate = dateTimeFormat.format(moment(timelineMap.x.invert(selection[0])));
                me.localisedZoomEndDate = dateTimeFormat.format(moment(timelineMap.x.invert(selection[1])));
               
            }
            else {
 
                dommy.push(timelineMap.x.invert(me.zoomStartDate));
                dommy.push(timelineMap.x.invert(me.zoomEndDate));

                //me._d3timelineCanvas = d3timeline.redraw(dommy);
                d3timeline.redraw(dommy);
                timelineAxis.redraw();
                timelineAxisLabel.redraw();

                handle.attr("transform", function() { 
                    return "translate(" + (timelineMap.x.invert(me.zoomStartDate) - 2) + ", " + 0  + ") scale(0.05)"; 
                });
            }
        }

        function brushStart() {
            const selection = d3.event.selection;

            if(selection){
                handle.attr("transform", function(d, i) { 
                    return "translate(" + (selection[i] - 2) + ", " + 0  + ") scale(0.05)"; 
                });
            }
        }
        return brush;
    }

    debounce = (fn, time) => {
        let timeout;
      
        return function() {
          const functionCall = () => fn.apply(this, arguments);
          
          clearTimeout(timeout);
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          timeout = setTimeout(functionCall, time);
        }
      }

    sortByValue(param) {
        return function(a, b) {
            return a[param] < b[param] ? -1 : a[param] > b[param] ? 1 : 0;
        };
    }

    userDateFormat() {
        const userShortDate = shortDateFormat;

        let d3DateFormat = userShortDate.replace(/dd/gi, "d");
        d3DateFormat = d3DateFormat.replace(/d/gi, "d");
        d3DateFormat = d3DateFormat.replace(/M/gi, "m");
        d3DateFormat = d3DateFormat.replace(/MM/gi, "m");
        d3DateFormat = d3DateFormat.replace(/YYYY/gi, "y");
        d3DateFormat = d3DateFormat.replace(/YY/gi, "y");

        d3DateFormat = d3DateFormat.replace(/d/gi, "%d");
        d3DateFormat = d3DateFormat.replace(/m/gi, "%m");
        d3DateFormat = d3DateFormat.replace(/y/gi, "%Y");

        return d3DateFormat;

    }

    get showIllustration() {
        if ( this.isError || this.noData ) {
            return true;
        }
        return false;        
    }

    get showFallbackTooltip() {

        if ( this.mouseOverFallbackField != null && this.mouseOverFallbackField !== '' ) {
            return true;
        }

        return false;        
    }

    toggleFilter() {

        const filterPopover = this.template.querySelector("div.timeline-filter");
        const filterClasses = String(filterPopover.classList);

        if ( filterClasses.includes('slds-is-open') ) {
            filterPopover.classList.remove('slds-is-open');
            this.isFilter = false;
        }
        else {
            filterPopover.classList.add('slds-is-open');
            this.isFilter = true;
        }
    }

    get filterOptions() {
        const timelineData = this._timelineData;
        let objectFilter = [];
       
        /*return [
            { label: 'All types', value: 'All types' },
            { label: 'Case', value: 'Cases' },
            { label: 'Opportunity', value: 'Opportunity' },
            { label: 'Task', value: 'Task' },
            { label: 'Event', value: 'Event' },
            { label: 'Campaign', value: 'Campaign' },
        ];*/
       
        for (const item of timelineData.objectFilters){
            let tempFilter = [];
            console.log(item);
            tempFilter.label = item;
            tempFilter.value = item;
            objectFilter.push(tempFilter);
        }

        return objectFilter;
    }

    get selectedFilterValues() {
        return this.filterValues.join(', ');
    }

    handleFilterChange(e) {

        this.filterValues = e.detail.value;
    }

}