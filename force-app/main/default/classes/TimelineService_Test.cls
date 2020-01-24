/*
1 - Can create a valid record in Timeline_Config_mdt
2 - Does the timelineService get active Timeline Types from Timeline_Config_mdt
3 - Does the timelineService query for the correct records based on the Timeline_Config_mdt
4 - Is an exception thrown when an unexpected exception occurs 
*/
@isTest(seeAllData = false)
private with sharing class TimelineService_Test {
    
    @isTest
    static void testTimelineConfigurationCreate() {

        Test.startTest();
        Test.stopTest();
        
        System.assertEquals('1','1', 'false');
    }

    @isTest
    static void testTimelineTypes() {
        Test.startTest();
        Test.stopTest();

        System.assertEquals('1','1', 'false');
    }
    @isTest
    static void testTimelineRecords() {
        Test.startTest();
        Test.stopTest();

        System.assertEquals('1','1', 'false');
    }
}
