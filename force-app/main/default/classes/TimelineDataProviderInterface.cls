public interface TimelineDataProviderInterface {
	List<Map<String,String>> getData(TimelineService.TimelineRecord tr, String parentObjectId, String earliestRange, String latestRange);
	String getLabel();
}
