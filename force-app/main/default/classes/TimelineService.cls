/**
 * @description Apex supporting methods for the timeline lightning web component
 */
public with sharing class TimelineService {
    /**
     * @description Return all child record types for the parent record in context
     * @param parentObjectId Id of the parent object used as the basis for the query
     * @param parentFieldName maps API name to use if different from current record
     * @return A map of the API name and label or each child record type to plot on the timeline
     */
    private static Map<String, Schema.DescribeFieldResult> fieldDescribeCache = new Map<String, Schema.DescribeFieldResult>();

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTimelineTypes(String parentObjectId, String parentFieldName) {
        try {
            Map<String, String> parentDetails = getParentDetails(parentObjectId, parentFieldName);

            String parentObjectType = parentDetails.get('QueryObjectType');
            String parentConfigType = parentDetails.get('ConfigObjectType');
            parentObjectId = parentDetails.get('Id');

            Map<String, String> childObjects = getChildObjects(parentObjectType);

            String queryTimelineConfiguration =
                'SELECT Active__c, ' +
                'Relationship_Name__c, ' +
                'Object_Name__c, ' +
                'Tooltip_Object_Name__c, ' +
                'Sequence__c ' +
                'FROM Timeline_Configuration__mdt ' +
                'WHERE Active__c = true AND ' +
                'Test__c = ' +
                Test.isRunningTest() +
                ' AND ' +
                'Parent_Object__c =:parentConfigType ' +
                'ORDER BY Sequence__c ASC '; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query(queryTimelineConfiguration); //NOPMD

            Map<String, String> mapOfTimelineTypes = new Map<String, String>();

            for (Timeline_Configuration__mdt timelineType : listOfTimelineConfigurations) {
                if (childObjects.containsKey(timelineType.Object_Name__c + timelineType.Relationship_Name__c)) {
                    String objectLabel = ((SObject) (Type.forName(
                                'Schema.' + String.valueOf(timelineType.Object_Name__c)
                            )
                            .newInstance()))
                        .getSObjectType()
                        .getDescribe(SObjectDescribeOptions.DEFERRED)
                        .getLabelPlural();

                    if (timelineType.Object_Name__c == 'ContentDocumentLink') {
                        objectLabel = System.Label.Timeline_Label_Files;
                    }

                    if (timelineType.Tooltip_Object_Name__c != null && timelineType.Tooltip_Object_Name__c != '') {
                        objectLabel = ((SObject) (Type.forName(
                                    'Schema.' + String.valueOf(timelineType.Tooltip_Object_Name__c)
                                )
                                .newInstance()))
                            .getSObjectType()
                            .getDescribe(SObjectDescribeOptions.DEFERRED)
                            .getLabelPlural();
                    }

                    mapOfTimelineTypes.put(timelineType.Object_Name__c, objectLabel);
                } else {
                    String errorMsg =
                        'You have asked to plot records for  \'' +
                        timelineType.Object_Name__c +
                        '\' but this entity cannot be found. Ask an administrator for help.';
                    throw new TimelineSetupException('{"type": "Setup-Error", "message": "' + errorMsg + '"}');
                }
            }

            return mapOfTimelineTypes;
        } catch (System.QueryException e) {
            throw new AuraHandledException(
                '{"type": "Setup-Error", "message": "' +
                e.getMessage() +
                ' : ' +
                e.getStackTraceString() +
                '"}'
            );
        } catch (TimelineSetupException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' : ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    /**
     * @description Return all child records for the parent record in context based on those active in Timeline_Configuration__mdt
     * @param parentObjectId The id of the parent record
     * @param earliestRange The number of historical years to include in the query
     * @param latestRange The number of years in the future to include in the query
     * @param parentFieldName maps API name to use if different from current record
     * @return A map of API Object Names and their corresponding translated labels
     */
    public static List<Map<String, String>> getTimelineRecords(
        String parentObjectId,
        String earliestRange,
        String latestRange,
        String parentFieldName
    ) {
        try {
            Map<String, String> parentDetails = getParentDetails(parentObjectId, parentFieldName);

            String parentObjectType = parentDetails.get('QueryObjectType');
            String parentConfigType = parentDetails.get('ConfigObjectType');
            parentObjectId = parentDetails.get('Id');

            earliestRange = String.ValueOf((Decimal.ValueOf(earliestRange) * 12).intValue());
            latestRange = String.ValueOf((Decimal.ValueOf(latestRange) * 12).intValue());

            String queryTimelineConfiguration =
                'SELECT Detail_Field__c, ' +
                'Relationship_Name__c, ' +
                'Active__c, ' +
                'Icon__c, ' +
                'Icon_Background_Colour__c, ' +
                'Position_Date_Field__c, ' +
                'Object_Name__c, ' +
                'Type_Field__c, ' +
                'Drilldown_Id_Field__c, ' +
                'Tooltip_Id_Field__c, ' +
                'Tooltip_Object_Name__c, ' +
                'Fallback_Tooltip_Field__c, ' +
                'Inclusion_Field__c ' +
                'FROM Timeline_Configuration__mdt ' +
                'WHERE Active__c = true AND ' +
                'Test__c = ' +
                Test.isRunningTest() +
                ' AND ' +
                'Parent_Object__c =:parentConfigType'; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query(queryTimelineConfiguration); //NOPMD

            if (listofTimelineConfigurations.size() < 1) {
                String errorMsg =
                    'No active records for parent entity  \'' +
                    parentObjectType +
                    '\' have been found in \'Timeline_Configuration__mdt\'. Ask an administrator for help.';
                throw new TimelineSetupException('{"type": "Setup-Error", "message": "' + errorMsg + '"}');
            }

            Map<String, TimelineRecord> mapOfTimelineConfigurationRecords = new Map<String, TimelineRecord>();
            Map<String, String> mapOfFields = new Map<String, String>();

            for (Timeline_Configuration__mdt timelineConfigurationRecord : listOfTimelineConfigurations) {
                TimelineRecord timelineRecord = new timelineRecord();
                timelineRecord.relationshipName = timelineConfigurationRecord.Relationship_Name__c;
                timelineRecord.icon = timelineConfigurationRecord.Icon__c;
                timelineRecord.iconBackground = timelineConfigurationRecord.Icon_Background_Colour__c;
                timelineRecord.detailField = timelineConfigurationRecord.Detail_Field__c;
                timelineRecord.objectName = timelineConfigurationRecord.Object_Name__c;
                timelineRecord.type = timelineConfigurationRecord.Type_Field__c;
                timelineRecord.positionDateField = timelineConfigurationRecord.Position_Date_Field__c;
                timelineRecord.fallbackTooltipField = timelineConfigurationRecord.Fallback_Tooltip_Field__c;
                timelineRecord.tooltipIdField = timelineConfigurationRecord.Tooltip_Id_Field__c;
                timelineRecord.tooltipObject = timelineConfigurationRecord.Tooltip_Object_Name__c;
                timelineRecord.drilldownIdField = timelineConfigurationRecord.Drilldown_Id_Field__c;
                timelineRecord.inclusionField = timelineConfigurationRecord.Inclusion_Field__c;

                mapOfTimelineConfigurationRecords.put(
                    timelineRecord.objectName + timelineRecord.relationshipName,
                    timelineRecord
                );
                mapOfFields.put(timelineRecord.detailField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.positionDateField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.fallbackTooltipField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.tooltipIdField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.drilldownIdField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.type, timelineRecord.objectName);
            }

            Map<String, String> childObjects = getChildObjects(parentObjectType);

            String innerQuery = '';

            for (String eachObject : mapOfTimelineConfigurationRecords.keyset()) {
                TimelineRecord tcr = mapOfTimelineConfigurationRecords.get(eachObject);

                if (childObjects.containsKey(eachObject)) {
                    String objName = String.valueOf(tcr.objectName);
                    String tooltipField = String.valueOf(tcr.fallbackTooltipField);
                    String tooltipIdField = String.valueOf(tcr.tooltipIdField);
                    String drilldownIdField = String.valueOf(tcr.tooltipIdField);
                    String typeField = String.valueOf(tcr.type);

                    String selectStatement = '(SELECT Id, ' + tcr.detailField + ', ' + tcr.positionDateField + '';

                    if (
                        (typeField != null && typeField != '') &&
                        (objName == 'Task' ||
                        objName == 'OpenActivity' ||
                        objName == 'ActivityHistory' ||
                        objName == 'TaskRelation' ||
                        objName == 'ContentDocumentLink')
                    ) {
                        selectStatement = selectStatement + ', ' + tcr.type + '';
                    }

                    if (objName == 'ContentDocumentLink') {
                        selectStatement = selectStatement + ', ' + 'ContentDocumentId' + '';
                    }

                    if (tooltipField != null && tooltipField != '' && tcr.detailField <> tcr.fallbackTooltipField) {
                        selectStatement = selectStatement + ', ' + tcr.fallbackTooltipField + '';
                    }

                    if (drilldownIdField != null && drilldownIdField != '') {
                        selectStatement = selectStatement + ', ' + tcr.drilldownIdField + '';
                    }

                    if (tooltipIdField != null && tooltipIdField != '' && tcr.drilldownIdField <> tcr.tooltipIdField) {
                        selectStatement = selectStatement + ', ' + tcr.tooltipIdField + '';
                    }

                    String relationship = tcr.relationshipName;
                    String optionalFilter = '';

                    if (tcr.inclusionField != '' && tcr.inclusionField != null) {
                        optionalFilter = tcr.inclusionField + ' = true AND ';
                    }

                    innerQuery =
                        innerQuery +
                        selectStatement +
                        +' FROM ' +
                        relationship +
                        ' WHERE ' +
                        optionalFilter +
                        tcr.positionDateField +
                        '>= LAST_N_MONTHS:' +
                        earliestRange +
                        ' AND ' +
                        tcr.positionDateField +
                        ' <= NEXT_N_MONTHS:' +
                        latestRange +
                        '),';
                }
            }

            innerQuery = innerQuery.removeEnd(',');

            String queryRecords =
                'SELECT Id, ' +
                innerQuery +
                ' FROM ' +
                parentObjectType +
                ' WHERE Id =:parentObjectId'; //NOPMD

            List<SObject> listOfTimelineRecords = Database.query(queryRecords); //NOPMD

            List<Map<String, String>> listOfTimelineData = new List<Map<String, String>>();
            Map<String, String> dupeDataCheck = new Map<String, String>();

            for (SObject each : listOfTimelineRecords) {
                Map<String, Object> childRecordsAsMap = each.getPopulatedFieldsAsMap();

                for (String fieldName : childRecordsAsMap.keySet()) {
                    if (childRecordsAsMap.get(fieldName) instanceof List<sObject>) {
                        List<sObject> childRecords = (List<sObject>) childRecordsAsMap.get(fieldName);

                        for (Sobject eachCh : childRecords) {
                            Map<String, String> mapData = new Map<String, String>();

                            TimelineRecord tr = mapOfTimelineConfigurationRecords.get(
                                eachCh.getSObjectType() + fieldName
                            );

                            String myId = eachCh.Id;

                            if (!dupeDataCheck.containsKey(myId)) {
                                dupeDataCheck.put(myId, myId);

                                Map<String, String> detailValues = getFieldValues(
                                    tr.detailField,
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> positionValues = getFieldValues(
                                    tr.positionDateField,
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> fallbackValues = getFieldValues(
                                    tr.fallbackTooltipField,
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> tooltipIdValues = getFieldValues(
                                    tr.tooltipIdField,
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> drilldownIdValues = getFieldValues(
                                    tr.drilldownIdField,
                                    eachCh,
                                    tr.objectName
                                );

                                Map<String, String> typeValues = getFieldValues(tr.type, eachCh, tr.objectName);

                                if (tr.objectName == 'ContentDocumentLink') {
                                    //NOPMD
                                    myId = String.valueOf(eachCh.get('ContentDocumentId'));
                                }

                                mapData.put('objectId', myId);
                                mapData.put('parentObject', parentObjectType);

                                if (detailValues.get('value') == '' || detailValues.get('value') == null) {
                                    //NOPMD
                                    mapData.put('detailField', '[' + detailValues.get('label') + ']');
                                } else {
                                    mapData.put('detailField', detailValues.get('value'));
                                }

                                mapData.put('detailFieldLabel', detailValues.get('label'));
                                mapData.put('positionDateField', positionValues.get('label'));
                                mapData.put('positionDateValue', positionValues.get('value'));
                                mapData.put('objectName', tr.objectName);
                                mapData.put('fallbackTooltipField', fallbackValues.get('label'));
                                mapData.put('fallbackTooltipValue', fallbackValues.get('value'));
                                mapData.put('drilldownId', drilldownIdValues.get('value'));
                                mapData.put('tooltipId', tooltipIdValues.get('value'));
                                mapData.put('tooltipObject', tr.tooltipObject);
                                mapData.put('fallbackTooltipValue', fallbackValues.get('value'));
                                mapData.put('type', typeValues.get('value'));
                                mapData.put('icon', tr.icon);
                                mapData.put('iconBackground', tr.iconBackground);

                                listOfTimelineData.add(mapData);
                            }
                        }
                    }
                }
            }
            return listOfTimelineData;
        } catch (TimelineSetupException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (System.QueryException e) {
            throw new AuraHandledException(
                '{"type": "Setup-Error", "message": "' +
                e.getMessage() +
                ' : ' +
                e.getStackTraceString() +
                '"}'
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' : ' + e.getStackTraceString());
        }
    }

    private static Map<String, String> getChildObjects(String parentObject) {
        Map<String, String> childRelatedObjects = new Map<String, String>();

        List<Schema.ChildRelationship> objectRelationships = ((SObject) (Type.forName('Schema.' + parentObject)
                .newInstance()))
            .getSObjectType()
            .getDescribe()
            .getChildRelationships();
        for (Schema.Childrelationship eachRelationship : objectRelationships) {
            if (
                eachRelationship.getChildSObject().getDescribe().isAccessible() &&
                !eachRelationship.getChildSObject().getDescribe().getLabel().contains('Histories') &&
                eachRelationship.getRelationshipName() != null
            ) {
                childRelatedObjects.put(
                    String.valueOf(
                        eachRelationship.getChildSObject() + String.valueOf(eachRelationship.getRelationshipName())
                    ),
                    String.valueOf(eachRelationship.getRelationshipName())
                );
            }
        }
        return childRelatedObjects;
    }

    private static Map<String, String> getFieldValues(String field, Sobject records, String objectName) {
        Map<String, String> fieldDetails = new Map<String, String>();

        String fieldValue = '';
        String fieldLabel = '';
        String objectCheck = '';
        String fieldCheck = '';
        String fieldStripped = '';
        Boolean fieldCanAccess = true;

        Id recordId;

        if (field == null || field == '') {
            fieldDetails.put('value', '');
            fieldDetails.put('label', '');
            return fieldDetails;
        }

        String[] objectFieldSplit = field.split('\\.');

        if (objectFieldSplit.size() > 1) {
            fieldStripped = objectFieldSplit[objectFieldSplit.size() - 1];
        } else {
            fieldStripped = field;
        }

        switch on objectFieldSplit.size() {
            when 1 {
                fieldValue = String.valueOf(records.get(field));
                recordId = String.valueOf(records.get('Id'));
            }
            when 2 {
                fieldValue = String.valueOf(records.getSobject(objectFieldSplit[0]).get(objectFieldSplit[1]));
                recordId = String.valueOf(records.getSobject(objectFieldSplit[0]).get('Id'));
            }
            when 3 {
                fieldValue = String.valueOf(
                    records.getSobject(objectFieldSplit[0]).getSobject(objectFieldSplit[1]).get(objectFieldSplit[2])
                );
                recordId = String.valueOf(
                    records.getSobject(objectFieldSplit[0]).getSobject(objectFieldSplit[1]).get('Id')
                );
            }
            when 4 {
                fieldValue = String.valueOf(
                    records.getSobject(objectFieldSplit[0])
                        .getSobject(objectFieldSplit[1])
                        .getSobject(objectFieldSplit[2])
                        .get(objectFieldSplit[3])
                );
                recordId = String.valueOf(
                    records.getSobject(objectFieldSplit[0])
                        .getSobject(objectFieldSplit[1])
                        .getSobject(objectFieldSplit[2])
                        .get('Id')
                );
            }
            when 5 {
                fieldValue = String.valueOf(
                    records.getSobject(objectFieldSplit[0])
                        .getSobject(objectFieldSplit[1])
                        .getSobject(objectFieldSplit[2])
                        .getSobject(objectFieldSplit[3])
                        .get(objectFieldSplit[4])
                );
                recordId = String.valueOf(
                    records.getSobject(objectFieldSplit[0])
                        .getSobject(objectFieldSplit[1])
                        .getSobject(objectFieldSplit[2])
                        .getSobject(objectFieldSplit[3])
                        .get('Id')
                );
            }
        }

        //Case comments cannot be translated to an sobjectype from the ID
        if (String.valueOf(recordId).startsWith('00a')) {
            objectCheck = 'CaseComment';
        } else {
            objectCheck = String.valueOf(recordId.getSobjectType());
        }

        //If parent object aggregates activity lists then field names change
        //For activities their sobjecttype is Task and Event
        switch on objectName {
            when 'ActivityHistory', 'OpenActivity' {
                if (objectCheck == 'Task' || objectCheck == 'Event') {
                    objectCheck = objectName;
                }
            }
        }

        Schema.DescribeFieldResult fieldMetadata = getDescribeInfo(objectCheck, fieldStripped);

        fieldLabel = fieldMetadata.getLabel();
        fieldCanAccess = fieldMetadata.isAccessible();

        if (fieldCanAccess == false) {
            fieldValue = '![' + fieldLabel + ']!';
        }

        if (fieldValue != null && fieldValue.length() > 255) {
            fieldValue = fieldValue.substring(0, 251) + '...';
        }

        fieldDetails.put('value', fieldValue);
        fieldDetails.put('label', fieldLabel);

        return fieldDetails;
    }

    private static Schema.DescribeFieldResult getDescribeInfo(String objectName, String fieldName) {
        String key = objectName + fieldName;

        if (!fieldDescribeCache.containsKey(key)) {
            Schema.DescribeSObjectResult describeSobjects = ((SObject) (Type.forName(
                        'Schema.' + String.valueOf(objectName)
                    )
                    .newInstance()))
                .getSObjectType()
                .getDescribe(SObjectDescribeOptions.DEFERRED);

            fieldDescribeCache.put(key, describeSobjects.fields.getMap().get(fieldName).getDescribe());
        }

        return fieldDescribeCache.get(key);
    }

    private static Boolean isPersonAccount(String recordId) {
        if (Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount')) {
            String queryPersonAccount = 'SELECT Id, IsPersonAccount FROM Account Where Id =:recordId';
            SObject acc = Database.query(queryPersonAccount);

            if (acc.get('IsPersonAccount') == true) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, String> getParentDetails(String recordId, String field) {
        Map<String, String> parentDetails = new Map<String, String>();

        String parentObjectType = String.valueOf(Id.valueOf(recordId).getSobjectType());
        String parentConfigType = parentObjectType;
        String fieldValue;

        if (field == 'Default_Picklist_Value') {
            fieldValue = recordId;
        } else {
            String queryParentId = 'SELECT Id, ' + field + ' FROM ' + parentObjectType + ' Where Id =:recordId';

            List<SObject> newDefaultRecord = Database.query(queryParentId); //NOPMD

            Schema.DescribeSObjectResult describeSobjects = ((SObject) (Type.forName('Schema.' + parentObjectType)
                    .newInstance()))
                .getSObjectType()
                .getDescribe();

            String fieldLabel = String.valueOf(describeSobjects.fields.getMap().get(field).getDescribe().getLabel());

            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, newDefaultRecord);

            Set<String> strippedFields = securityDecision.getRemovedFields().get(parentObjectType);

            if (strippedFields != null && strippedFields.contains(field)) {
                String errorMsg =
                    'We can\'t display the timeline. You do not have access to the related field. ' +
                    'Ask your Administrator for help. ' +
                    '(' +
                    fieldLabel +
                    ')';

                throw new TimelineSetupException('{"type": "No-Access", "message": "' + errorMsg + '"}');
            }

            SObject secureObject = securityDecision.getRecords()[0];

            fieldValue = String.valueOf(secureObject.get(field));

            if (fieldValue == null || fieldValue == '') {
                String errorMsg =
                    'We can\'t display the timeline. The field requested has no value. ' +
                    'Populate a value and try again. ' +
                    '(' +
                    fieldLabel +
                    ')';

                throw new TimelineSetupException('{"type": "No-Data", "message": "' + errorMsg + '"}');
            }

            parentObjectType = String.valueOf(Id.valueOf(fieldValue).getSobjectType());
        }

        if (parentObjectType == 'Account' && isPersonAccount(fieldValue)) {
            parentConfigType = 'PersonAccount';
        } else {
            parentConfigType = parentObjectType;
        }

        parentDetails.put('Id', fieldValue);
        parentDetails.put('QueryObjectType', parentObjectType);
        parentDetails.put('ConfigObjectType', parentConfigType);

        return parentDetails;
    }

    private class TimelineRecord { //NOPMD
        private String relationshipName;
        private String parentObject;
        private String detailField;
        private String detailFieldLabel;
        private String icon;
        private String iconBackground;
        private String positionDateField;
        private String positionDateValue;
        private String objectName;
        private String type;
        private String tooltipIdField;
        private String tooltipObject;
        private String drilldownIdField;
        private String fallbackTooltipField;
        private String fallbackTooltipValue;
        private String fallbackNameField;
        private String fallbackNameValue;
        private String inclusionField;
        private Id recordId;
    }

    private class FieldMetadata { //NOPMD
        private Boolean canAccess;
        private String label;
    }

    private class TimelineSetupException extends Exception {
    }
}
