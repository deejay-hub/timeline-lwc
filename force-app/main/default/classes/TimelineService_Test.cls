/*
1 - Does the filter get the correct types for display
2 - Does the timelineService get active Timeline Types from Timeline_Config__mdt
3 - Is an exception thrown when an unexpected things happen 
*/
@isTest(seeAllData = false)
private with sharing class TimelineService_Test {
    
    private static User currentUser;

    @isTest
    static void testTimelineTypesForFilter() {

        Contact janeLo = new Contact();

        janeLo.FirstName = 'Jane';
        janeLo.LastName = 'Lo';

        insert(janeLo);

        Test.startTest();
        Map<String, String> timelineTypes = TimelineService.getTimelineTypes(janeLo.Id);
        //Boolean moreThanOneTimelineType = ( (timelineTypes.size() > 0) ? true : false );
        Test.stopTest();

        System.assert( timelineTypes.size() > 0, 'At least 1 timeline type in \'Timeline_Configuration_Type__mdt\' is expected for entity \'Contact\'' );
    }

    @isTest
    static void testTimelineRecordsInRange() {

        Contact joeLo = new Contact();

        joeLo.FirstName = 'Joe';
        joeLo.LastName = 'Lo';

        insert(joeLo);

        Task joeTaskInRange = new Task();

        joeTaskInRange.ActivityDate = Date.today();
        joeTaskInRange.Description = 'New activity description for Joe';
        joeTaskInRange.Subject = 'New activity for Joe';
        joeTaskInRange.WhoId = joeLo.Id;

        insert(joeTaskInRange);

        Task joeTaskOutOfRange = new Task();

        joeTaskOutOfRange.ActivityDate = Date.newInstance(1990, 2, 2);
        joeTaskOutOfRange.Description = 'Old activity description for Joe';
        joeTaskOutOfRange.Subject = 'Old activity for Joe';
        joeTaskOutOfRange.WhoId = joeLo.Id;

        insert(joeTaskOutOfRange);

        Test.startTest();
        List<Map<String, String>> timelineRecords = TimelineService.getTimelineRecords(joeLo.Id, '1', '1');
        Test.stopTest();

        System.assertEquals( 1, timelineRecords.size(), 'Incorrect number of Tasks found' );
    }
}
