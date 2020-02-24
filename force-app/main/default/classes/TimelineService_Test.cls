/*
1 - Can create a valid record in Timeline_Config__mdt
2 - Cannot create an invalid record in Timeline_Config__mdt
3 - Does the filter get the correct types for display
4 - Does the timelineService get active Timeline Types from Timeline_Config__mdt
5 - Is an exception thrown when an unexpected things happen 
*/
@isTest(seeAllData = false)
private with sharing class TimelineService_Test {
    
    private static User currentUser;

    @isTest
    static void testValidTimelineConfiguration() {

        System.runAs(currentUser) {
            Timeline_Configuration__mdt timelineConfiguration  = new Timeline_Configuration__mdt(
                Name = 'Contact_Cases',
                Active__c = true,
                Detail_Field__c = 'Subject',
                Icon__c = '/img/icon/t4v35/standard/case.svg',
                Icon_Background_Colour__c  = '#f2cf5b',
                Object_Name__c  = 'Case',
                Parent_Object__c  =  'Contact',
                Position_Date_Field__c = 'CreatedDate',
                Sequence__c = 10
            );
            
            Test.startTest();
            insert timelineConfiguration;
            Test.stopTest();
        }
        
        //Assert that one record was created successfully
        Timeline_Configuration__mdt[] timelineConfig = [Select Id from Timeline_Configuration__mdt where id=:timelineConfiguration.id];
        system.assertEquals( 1, timelineConfig.size(), 'Timeline configuration metadata type record could not be created successfully' );
 
    }

    @isTest
    static void testInvalidTimelineConfiguration() {

        System.runAs(currentUser) {
            Timeline_Configuration__mdt timelineConfiguration  = new Timeline_Configuration__mdt(
                Name = 'SAP_Cases',
                Active__c = true,
                Detail_Field__c = 'Subject',
                Icon__c = '/img/icon/t4v35/standard/case.svg',
                Icon_Background_Colour__c  = '#f2cf5b',
                Object_Name__c  = 'Case',
                Parent_Object__c  =  'SAP__e',
                Position_Date_Field__c = 'CreatedDate',
                Sequence__c = 10

                
            );

            Test.startTest();
            insert timelineConfiguration;
            Test.stopTest();
      
        }
        
        //Assert that no record was created successfully as external objects are not permitted (validation rule)
        Timeline_Configuration__mdt[] timelineConfig = [Select Id from Timeline_Configuration__mdt where id=:timelineConfiguration.id];
        system.assertEquals( 0, timelineConfig.size(), 'Timeline configuration metadata type record could be created successfully when an error was expected' );
    }

    @isTest
    static void testTimelineTypesForFilter() {

        List<Timeline_Configuration__mdt> timelineConfigurations = new List<Timeline_Configuration__mdt>();

         System.runAs(currentUser) {
            Timeline_Configuration__mdt contactCasesConfig  = new Timeline_Configuration__mdt(
                Name = 'Contact_Cases',
                Active__c = true,
                Detail_Field__c = 'Subject',
                Icon__c = '/img/icon/t4v35/standard/case.svg',
                Icon_Background_Colour__c  = '#f2cf5b',
                Object_Name__c  = 'Case',
                Parent_Object__c  =  'Contact',
                Position_Date_Field__c = 'CreatedDate',
                Sequence__c = 10
            );

            timelineConfigurations.add(contactCasesConfig);

            Timeline_Configuration__mdt contactTasksConfig  = new Timeline_Configuration__mdt(
                Name = 'Contact_Tasks',
                Active__c = true,
                Detail_Field__c = 'Subject',
                Icon__c = '/img/icon/t4v35/standard/task.svg',
                Icon_Background_Colour__c  = '#f2cf5b',
                Object_Name__c  = 'Task',
                Parent_Object__c  =  'Contact',
                Position_Date_Field__c = 'ActivityDate',
                Sequence__c = 20
            );
           
            timelineConfigurations.add(contactTasksConfig);

            insert timelineConfigurations;

            timelineService = new TimelineService();

            Test.startTest();
            timelineService.getTimelineTypes(parentObjectId);
            Test.stopTest();

        }

        System.assertEquals('1','1', 'false');
    }

    @isTest
    static void testActiveTimelineRecords() {

        Test.startTest();
        Test.stopTest();

        System.assertEquals('1','1', 'false');
    }

    private static void createTimelineConfiguration() {

       

    }

    private static void createContactTimelineData() {

        System.runAs(currentUser) {
            Contact janeLo = new Contact();

            janeLo.FirstName = 'Jane';
            janeLo.LastName = 'Lo';

            //Save Contact

            //Create Task

            //Create Case

        }

    }
}
