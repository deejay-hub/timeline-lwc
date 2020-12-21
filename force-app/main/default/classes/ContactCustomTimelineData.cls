public with sharing class ContactCustomTimelineData implements TimelineDataProviderInterface {
    public List<Map<String,String>> getData(TimelineService.TimelineRecord tr, String parentObjectId, String earliestRange, String latestRange) {
		DateTime beginDate = DateTime.now().addMonths(-Integer.valueOf(earliestRange));
		DateTime endDate = DateTime.now().addMonths(Integer.valueOf(latestRange));

		Map<String,String> mapData1 = new map<String,String>();
		mapData1.put('objectId', parentObjectId);
		mapData1.put('parentObject', tr.parentObject);
		mapData1.put('detailField', 'My custom record description');
		mapData1.put('detailFieldLabel', 'Descriptor"');
		mapData1.put('positionDateField', tr.positionDateField);
		mapData1.put('positionDateValue', DateTime.now().addDays(-3).formatGMT('yyyy-MM-dd HH:mm:ss'));
		mapData1.put('objectName', tr.objectName);
		mapData1.put('fallbackTooltipField', 'More Details');
		mapData1.put('fallbackTooltipValue', 'The details');
		mapData1.put('drilldownId', 'http://www.google.com'); // when clicking on the item
		mapData1.put('tooltipId', null); // to override the id when hovering
		mapData1.put('tooltipObject', null); // to override the object when hovering
		mapData1.put('type', null);
		mapData1.put('icon', tr.icon);
		mapData1.put('iconBackground', tr.iconBackground);
		mapData1.put('iconBadge', '/img/msg_icons/confirm16.png');

		Map<String,String> mapData2 = new map<String,String>();
		mapData2.put('objectId', parentObjectId);
		mapData2.put('parentObject', tr.parentObject);
		mapData2.put('detailField', 'My custom record description');
		mapData2.put('detailFieldLabel', 'Descriptor"');
		mapData2.put('positionDateField', tr.positionDateField);
		mapData2.put('positionDateValue', DateTime.now().addYears(-3).formatGMT('yyyy-MM-dd HH:mm:ss'));
		mapData2.put('objectName', tr.objectName);
		mapData2.put('fallbackTooltipField', 'More Details');
		mapData2.put('fallbackTooltipValue', 'The details');
		mapData2.put('drilldownId', 'http://www.google.com'); // when clicking on the item
		mapData2.put('tooltipId', null); // to override the id when hovering
		mapData2.put('tooltipObject', null); // to override the object when hovering
		mapData2.put('type', null);
		mapData2.put('icon', tr.icon);
		mapData2.put('iconBackground', tr.iconBackground);
		mapData2.put('iconBadge', '/img/msg_icons/error16.png');

		return new List<Map<String,String>> { mapData1, mapData2 };
	}

	public String getLabel() {
		return 'Custom Data';
	}
}
