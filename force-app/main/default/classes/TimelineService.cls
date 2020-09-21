/**
 * @description Apex supporting methods for the timeline lightning web component
 */
public with sharing class TimelineService {
    /**
     * @description Return all child record types for the parent record in context
     * @param parentObjectId Id of the parent object used as the basis for the query
     * @return A map of the API name and label or each child record type to plot on the timeline
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTimelineTypes(String parentObjectId) {
        try {
            String parentObjectType = String.valueOf(Id.valueOf(parentObjectId).getSobjectType());
            if (parentObjectType == 'Account' && isPersonAccount(parentObjectId)) {
                parentObjectType = 'PersonAccount';
            }

            String queryTimelineConfiguration =
                'SELECT Active__c, ' +
                'Object_Name__c, ' +
                'Tooltip_Object_Name__c, ' +
                'Sequence__c ' +
                'FROM Timeline_Configuration__mdt ' +
                'WHERE Active__c = true AND ' +
                'Test__c = ' +
                Test.isRunningTest() +
                ' AND ' +
                'Parent_Object__c =:parentObjectType ' +
                'ORDER BY Sequence__c ASC '; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query(queryTimelineConfiguration); //NOPMD

            Map<String, String> mapOfTimelineTypes = new Map<String, String>();

            for (Timeline_Configuration__mdt timelineType : listOfTimelineConfigurations) {
                String objectLabel = ((SObject) (Type.forName('Schema.' + String.valueOf(timelineType.Object_Name__c))
                        .newInstance()))
                    .getSObjectType()
                    .getDescribe()
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
                        .getDescribe()
                        .getLabelPlural();
                }

                mapOfTimelineTypes.put(timelineType.Object_Name__c, objectLabel);
            }

            return mapOfTimelineTypes;
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
     * @return A map of API Object Names and their corresponding translated labels
     */
    public static List<Map<String, String>> getTimelineRecords(
        String parentObjectId,
        String earliestRange,
        String latestRange
    ) {
        try {
            String parentObjectType = String.valueOf(Id.valueOf(parentObjectId).getSobjectType());
            String parentConfigType = parentObjectType;

            if (parentObjectType == 'Account' && isPersonAccount(parentObjectId)) {
                parentConfigType = 'PersonAccount';
            }

            earliestRange = String.ValueOf((Decimal.ValueOf(earliestRange) * 12).intValue());
            latestRange = String.ValueOf((Decimal.ValueOf(latestRange) * 12).intValue());

            String queryTimelineConfiguration = 'SELECT Detail_Field__c, '
                                            + 'Relationship_Name__c, '
                                            + 'Active__c, '
                                            + 'Icon__c, '
                                            + 'Icon_Background_Colour__c, '
                                            + 'Position_Date_Field__c, '
                                            + 'Position_End_Date_Field__c, '
                                            + 'Object_Name__c, '
                                            + 'Type_Field__c, '
                                            + 'Drilldown_Id_Field__c, '
                                            + 'Tooltip_Id_Field__c, '
                                            + 'Tooltip_Object_Name__c, '
                                            + 'Fallback_Tooltip_Field__c '
                                        + 'FROM Timeline_Configuration__mdt '
                                        + 'WHERE Active__c = true AND '
                                        + 'Test__c = ' + Test.isRunningTest() + ' AND '
                                        + 'Parent_Object__c =:parentConfigType'; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query( queryTimelineConfiguration ); //NOPMD

            if ( listofTimelineConfigurations.size() < 1 ) {
                String errorMsg = 'No active records for parent entity  \'' + parentObjectType + '\' have been found in \'Timeline_Configuration__mdt\'. Ask an administrator for help.';
                throw new TimelineSetupException( '{"type": "Setup-Error", "message": "' + errorMsg + '"}' );
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
                timelineRecord.positionEndDateField = timelineConfigurationRecord.Position_End_Date_Field__c;
                timelineRecord.fallbackTooltipField = timelineConfigurationRecord.Fallback_Tooltip_Field__c;
                timelineRecord.tooltipIdField = timelineConfigurationRecord.Tooltip_Id_Field__c;
                timelineRecord.tooltipObject = timelineConfigurationRecord.Tooltip_Object_Name__c;
                timelineRecord.drilldownIdField = timelineConfigurationRecord.Drilldown_Id_Field__c;

                mapOfTimelineConfigurationRecords.put(
                    timelineRecord.objectName + timelineRecord.relationshipName,
                    timelineRecord
                );
                mapOfFields.put(timelineRecord.detailField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.positionDateField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.positionEndDateField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.fallbackTooltipField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.tooltipIdField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.drilldownIdField, timelineRecord.objectName);
                mapOfFields.put(timelineRecord.type, timelineRecord.objectName);
            }

            Map<String, String> childObjects = getChildObjects(parentObjectType);
            Map<String, FieldMetadata> fieldAttributes = getFieldMetadata(mapOfFields, parentObjectType);

            String innerQuery = '';

            for (String eachObject : mapOfTimelineConfigurationRecords.keyset()) {
                TimelineRecord tcr = mapOfTimelineConfigurationRecords.get(eachObject);

                if (childObjects.containsKey(eachObject)) {
                    String objName = String.valueOf(tcr.objectName);
                    String tooltipField = String.valueOf(tcr.fallbackTooltipField);
                    String tooltipIdField = String.valueOf(tcr.tooltipIdField);
                    String drilldownIdField = String.valueOf(tcr.tooltipIdField);
                    String typeField = String.valueOf(tcr.type);
                    
                    String selectStatement = '(SELECT Id, ' 
                                    + tcr.detailField + ', ' 
                                    + tcr.positionDateField + '';

                    if (String.valueOf(tcr.positionEndDateField) != null && String.valueOf(tcr.positionEndDateField) != ''){
                        selectStatement = selectStatement + ', '
                                    + tcr.positionEndDateField + '';
                    }

                    if ( (typeField != null && typeField != '') && (objName == 'Task' || objName == 'TaskRelation' || objName == 'ContentDocumentLink')) {
                        selectStatement = selectStatement + ', '
                                    + tcr.type + '';
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
                    if (tcr.relationshipName.contains('Person') && !tcr.relationshipName.contains('__pr')) {
                        relationship = tcr.relationshipName.substringAfter('Person');
                    }

                    innerQuery =
                        innerQuery +
                        selectStatement +
                        +' FROM ' +
                        relationship +
                        ' WHERE ' +
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

            for (SObject each : listOfTimelineRecords) {
                for (String eachObj : mapOfTimelineConfigurationRecords.keyset()) {
                    if (each.getSObjects(childObjects.get(eachObj)) != null) {
                        for (SObject eachCh : (List<SObject>) each.getSObjects(childObjects.get(eachObj))) {
                            Map<String, String> mapData = new Map<String, String>();

                            TimelineRecord tr = mapOfTimelineConfigurationRecords.get(eachObj);

                            if (tr != null) {
                                String myId = eachCh.Id;

                                Map<String, String> detailValues = getFieldValues(tr.detailField, eachCh, fieldAttributes);
                                Map<String, String> positionValues = getFieldValues(tr.positionDateField, eachCh, fieldAttributes);
                                Map<String, String> positionEndValues = getFieldValues(tr.positionEndDateField, eachCh, fieldAttributes);
                                Map<String, String> fallbackValues = getFieldValues(tr.fallbackTooltipField, eachCh, fieldAttributes);
                                Map<String, String> tooltipIdValues = getFieldValues(tr.tooltipIdField, eachCh, fieldAttributes);
                                Map<String, String> drilldownIdValues = getFieldValues(tr.drilldownIdField, eachCh, fieldAttributes);
                                Map<String, String> typeValues = getFieldValues(tr.type, eachCh, fieldAttributes);

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
                                mapData.put('positionDateField', tr.positionDateField);
                                mapData.put('positionDateValue', positionValues.get('value'));
                                mapData.put('positionEndDateField', tr.positionEndDateField);
                                mapData.put('positionDateEndValue', positionEndValues.get('value'));
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
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
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

    private static Map<String, FieldMetadata> getFieldMetadata(Map<String, String> fields, String baseObject) {
        String fieldLabel;
        Boolean fieldAccess;
        Map<String, FieldMetadata> mapOfFieldMetadata = new Map<String, FieldMetadata>();

        for (String field : fields.keySet()) {
            if (field != null && field != '') {
                String fieldObject = fields.get(field);
                Boolean isDotNotationUsed = field.contains('.');
                FieldMetadata fieldMetadata = new fieldMetadata();

                try {
                    if (isDotNotationUsed == true) {
                        String splitObject = field.SubStringBefore('.');
                        String splitField = field.SubStringAfter('.');

                        Schema.DescribeSObjectResult describeParentSobjects = ((SObject) (Type.forName(
                                    'Schema.' + String.valueOf(splitObject)
                                )
                                .newInstance()))
                            .getSObjectType()
                            .getDescribe();
                        fieldMetadata.label = String.valueOf(
                            describeParentSobjects.fields.getMap().get(splitField).getDescribe().getLabel()
                        );
                        fieldMetadata.canAccess = Boolean.valueOf(
                            describeParentSobjects.fields.getMap().get(splitField).getDescribe().isAccessible()
                        );
                    } else {
                        Schema.DescribeSObjectResult describeSobjects = ((SObject) (Type.forName(
                                    'Schema.' + fieldObject
                                )
                                .newInstance()))
                            .getSObjectType()
                            .getDescribe();

                        fieldMetadata.label = String.valueOf(
                            describeSobjects.fields.getMap().get(field).getDescribe().getLabel()
                        );
                        fieldMetadata.canAccess = Boolean.valueOf(
                            describeSobjects.fields.getMap().get(field).getDescribe().isAccessible()
                        );
                    }
                } catch (Exception e) {
                    String errorMsg =
                        'No such column \'' +
                        field +
                        '\' on entity \'' +
                        fieldObject +
                        '\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. ' +
                        e.getMessage();
                    throw new TimelineSetupException('{"type": "Setup-Error", "message": "' + errorMsg + '"}');
                }

                mapOfFieldMetadata.put(field, fieldMetadata);
            }
        }

        return mapOfFieldMetadata;
    }

    private static Map<String, String> getFieldValues(
        String field,
        Sobject records,
        Map<String, FieldMetadata> fieldAttributes
    ) {
        Map<String, String> fieldDetails = new Map<String, String>();

        String fieldValue = '';
        String fieldLabel = '';

        if (field == null || field == '') {
            fieldDetails.put('value', '');
            fieldDetails.put('label', '');
            return fieldDetails;
        }

        FieldMetadata fm = fieldAttributes.get(field);
        Boolean isDotNotationUsed = field.contains('.');

        fieldLabel = fm.label;

        if (fm.canAccess) {
            if (isDotNotationUsed == true) {
                String splitObject = field.SubStringBefore('.');
                String splitField = field.SubStringAfter('.');
                fieldValue = String.valueOf(records.getSobject(splitObject).get(splitField));
            } else {
                fieldValue = String.valueOf(records.get(field));
            }
        }

        if (fieldValue != null && fieldValue.length() > 255) {
            fieldValue = fieldValue.substring(0, 251) + '...';
        }

        fieldDetails.put('value', fieldValue);
        fieldDetails.put('label', fieldLabel);

        return fieldDetails;
    }

    private static Boolean isPersonAccount(String recordId) {
        if (Account.SObjectType.getDescribe().hasSubtypes) {
            String queryPersonAccount = 'SELECT Id, IsPersonAccount FROM Account Where Id =:recordId';
            SObject acc = Database.query(queryPersonAccount);

            if (acc.get('IsPersonAccount') == true) {
                return true;
            }
        }
        return false;
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
        private String positionEndDateField;
        private String positionDateEndValue;
        private String objectName;
        private String type;
        private String tooltipIdField;
        private String tooltipObject;
        private String drilldownIdField;
        private String fallbackTooltipField;
        private String fallbackTooltipValue;
        private String fallbackNameField;
        private String fallbackNameValue;
        private Id recordId;
    }

    private class FieldMetadata { //NOPMD
        private Boolean canAccess;
        private String label;
    }

    private class TimelineSetupException extends Exception {
    }
}
