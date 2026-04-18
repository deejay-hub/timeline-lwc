/**
 * @description Supporting test class to check the Timeline picklist
 * 1 - Does the picklist return the correct default values
 * 2 - Does the picklist return at least 1 value for the Contact standard object
 * 3 - Does the picklist handle a null entity name gracefully
 * 4 - Does the picklist skip field iteration for CommRecordPage page type
 */
@isTest(seeAllData=false)
private with sharing class TimelineParentPicklist_Test {
    @isTest
    static void testTimelinePicklistDefaultValue() {
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Contact';

        String objectLabel = ((SObject) (Type.forName('Schema.Contact').newInstance()))
            .getSObjectType()
            .getDescribe()
            .getLabel();

        TimelineParentPicklist timeline = new TimelineParentPicklist(context);

        Test.startTest();
        VisualEditor.DataRow defaultValue = timeline.getDefaultValue();
        Test.stopTest();

        System.assertEquals(
            'Use This ' + objectLabel,
            defaultValue.getLabel(),
            'Timeline Parent Picklist default value incorrect'
        );
    }

    @isTest
    static void testTimelinePicklistValues() {
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Contact';

        TimelineParentPicklist timeline = new TimelineParentPicklist(context);

        Test.startTest();
        VisualEditor.DynamicPickListRows picklistValues = timeline.getValues();
        Test.stopTest();

        System.assert(picklistValues.size() > 0, 'No parent picklist values found for Contact');
    }

    @isTest
    static void testPicklistNullEntity() {
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = null;

        TimelineParentPicklist timeline = new TimelineParentPicklist(context);

        Test.startTest();
        VisualEditor.DataRow defaultValue = timeline.getDefaultValue();
        VisualEditor.DynamicPickListRows picklistValues = timeline.getValues();
        Test.stopTest();

        System.assertEquals(
            'Use Current Record',
            defaultValue.getLabel(),
            'Null entity should return generic default label'
        );
        System.assert(picklistValues.size() > 0, 'Null entity should still return at least the default row');
    }

    @isTest
    static void testPicklistCommRecordPage() {
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Contact';
        context.pageType = 'CommRecordPage';

        TimelineParentPicklist timeline = new TimelineParentPicklist(context);

        Test.startTest();
        VisualEditor.DynamicPickListRows picklistValues = timeline.getValues();
        Test.stopTest();

        System.assertEquals(
            1,
            picklistValues.size(),
            'CommRecordPage should return only the default row without field options'
        );
    }
}
