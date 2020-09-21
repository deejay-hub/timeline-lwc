/**
 * @description Supporting test class to check the Timeline service modules
 * 1 - Does the filter get the correct types for display
 * 2 - Does the timelineService get active Timeline Types from Timeline_Config__mdt
 * 3 - Does the timelineService correctly return parent field values using dot notation
 * 4 - Does custom processing for the entity ContentDocumentLink function correctly
 * 5 - Setup error - do we get an exception when there are no timeline types
 * 6 - Different parent - does it query for the correct records when Parent Field is populated
 * 7 - Setup error - do we get an exception when someone chooses the Parent Field but it's value is blank
 */
@isTest(seeAllData=false)
private with sharing class TimelineService_Test {
    private static User currentUser;

    @isTest
    static void testTimelineTypesForFilter() {
        Contact janeLo = new Contact(FirstName = 'Jane', LastName = 'Lo');

        insert janeLo;

        Test.startTest();
        Map<String, String> timelineTypes = TimelineService.getTimelineTypes(janeLo.Id, 'Default_Picklist_Value');
        Test.stopTest();

        System.assertEquals(
            3,
            timelineTypes.size(),
            'Incorrect number of timeline types in \'Timeline_Configuration_Type__mdt\' for entity \'Contact\''
        );
    }

    @isTest
    static void testTimelineRecordsInRange() {
        Account janesHousehold = new Account(Name = 'Jane\'s Household');

        insert janesHousehold;

        Task householdTaskInRange = new Task(
            ActivityDate = Date.today(),
            Description = 'New activity description for Household. This is a really long description that will test the fact that when the value exceeds 255 characters that it will be truncated prior to being returned to the timeline. This is a really really really really really unnecessary sentence',
            Subject = 'New activity for Household',
            WhatId = janesHousehold.Id
        );

        insert householdTaskInRange;

        Task householdTaskOutOfRange = new Task(
            ActivityDate = Date.newInstance(1990, 2, 2),
            Description = 'Old activity description for Joe',
            Subject = 'Old activity for Joe',
            WhatId = janesHousehold.Id
        );

        insert householdTaskOutOfRange;

        Test.startTest();
        List<Map<String, String>> timelineRecords = TimelineService.getTimelineRecords(
            janesHousehold.Id,
            '1',
            '1',
            'Default_Picklist_Value'
        );
        Test.stopTest();

        System.assertEquals(1, timelineRecords.size(), 'Incorrect number of Tasks found');
    }

    @isTest
    static void testDotNotation() {
        Campaign eventCampaign = new Campaign(
            Name = 'Australian of the Year Awards',
            StartDate = Date.today(),
            IsActive = true
        );

        insert eventCampaign;

        Contact juneLo = new Contact(FirstName = 'June', LastName = 'Lo');

        insert juneLo;

        CampaignMember juneAttends = new CampaignMember(CampaignId = eventCampaign.Id, ContactId = juneLo.Id);

        insert juneAttends;

        Test.startTest();
        List<Map<String, String>> timelineRecords = TimelineService.getTimelineRecords(
            juneLo.Id,
            '1',
            '1',
            'Default_Picklist_Value'
        );
        Test.stopTest();

        System.assertEquals(1, timelineRecords.size(), 'Incorrect number of Campaign Members found');
        System.assertEquals(
            eventCampaign.Name,
            timelineRecords[0].get('detailField'),
            'Campaign Name using dot notation not functioning'
        );
    }

    @isTest
    static void testContentDocumentLink() {
        Contact rodLo = new Contact();

        rodLo.FirstName = 'Rod';
        rodLo.LastName = 'Lo';

        insert rodLo;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Puzzle',
            PathOnClient = 'Puzzle.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );

        insert contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink linkedContent = new ContentDocumentLink(
            LinkedEntityId = rodLo.id,
            ContentDocumentId = documents[0].Id,
            ShareType = 'V'
        );

        insert linkedContent;

        Test.startTest();
        List<Map<String, String>> timelineRecords = TimelineService.getTimelineRecords(
            rodLo.Id,
            '1',
            '1',
            'Default_Picklist_Value'
        );
        Test.stopTest();

        System.assertEquals(
            documents[0].Id,
            timelineRecords[0].get('objectId'),
            'Document Id was not returned as attachment record value'
        );
    }

    @isTest
    static void testSetupException() {
        Boolean hasFailed = false;

        Case forgotPassword = new Case(Origin = 'Email', Subject = 'Forgot my Password');

        insert forgotPassword;

        try {
            Test.startTest();
            List<Map<String, String>> timelineRecords = TimelineService.getTimelineRecords(
                forgotPassword.Id,
                '1',
                '1',
                'Default_Picklist_Value'
            );
        } catch (Exception e) {
            hasFailed = true;
        } finally {
            System.assert(
                hasFailed = true,
                'Expected an exception to occur when using entity Case and no Timeline_Configuration__mdt records. Actually got no exception.'
            );
            Test.stopTest();
        }
    }

    @isTest
    static void testDifferentParentProperty() {
        Contact freddyLo = new Contact(FirstName = 'Freddy', LastName = 'Lo');

        insert freddyLo;

        Task freddyTaskInRange = new Task(
            ActivityDate = Date.today(),
            Description = 'New activity description for Freddy.',
            Subject = 'New activity for Freddy',
            WhoId = freddyLo.Id
        );

        insert freddyTaskInRange;

        Case forgotPassword = new Case(Origin = 'Email', Subject = 'Forgot my Password', ContactId = freddyLo.Id);

        insert forgotPassword;

        Test.startTest();
        Map<String, String> timelineTypes = TimelineService.getTimelineTypes(forgotPassword.Id, 'ContactId');

        List<Map<String, String>> timelineRecords = TimelineService.getTimelineRecords(
            forgotPassword.Id,
            '1',
            '1',
            'ContactId'
        );

        Test.stopTest();

        System.assertEquals(
            3,
            timelineTypes.size(),
            'Incorrect number of timeline types in \'Timeline_Configuration_Type__mdt\' for entity \'Contact\''
        );

        System.assertEquals(
            1,
            timelineRecords.size(),
            'Incorrect number of timeline records found based on setting Parent Field'
        );
    }

    @isTest
    static void testNoParentFieldValue() {
        Boolean hasFailed = false;

        Case brokenLift = new Case(Origin = 'Email', Subject = 'My lift broke');

        insert brokenLift;

        try {
            Test.startTest();
            Map<String, String> timelineTypes = TimelineService.getTimelineTypes(brokenLift.Id, 'ContactId');
        } catch (Exception e) {
            hasFailed = true;
        } finally {
            System.assert(
                hasFailed = true,
                'Expected an exception to occur when using entity Case and asking to use the Parent Contact Id field with no value in it.'
            );
            Test.stopTest();
        }
    }
}
