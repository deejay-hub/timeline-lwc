public with sharing class TimelineService {
   
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTimelineTypes( String parentObjectId ) {

        try {
            String parentObjectType = String.valueOf(Id.valueOf(parentObjectId).getSobjectType());
            if (parentObjectType == 'Account' && isPersonAccount(parentObjectId)  ) {
                parentObjectType = 'PersonAccount';
            }

            String queryTimelineConfiguration = 'SELECT Active__c, '
                                            + 'Object_Name__c, '
                                            + 'Sequence__c '
                                        + 'FROM Timeline_Configuration__mdt '
                                        + 'WHERE Active__c = true AND '
                                        + 'Parent_Object__c =:parentObjectType '
                                        + 'ORDER BY Sequence__c ASC '; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query( queryTimelineConfiguration ); //NOPMD

            Map<String, String> mapOfTimelineTypes = new Map<String, String>();

            for ( Timeline_Configuration__mdt timelineType : listOfTimelineConfigurations ) {
                
                String objectLabel = ((SObject)(Type.forName('Schema.'+ String.valueOf(timelineType.Object_Name__c)).newInstance())).getSObjectType().getDescribe().getLabelPlural();

                if ( timelineType.Object_Name__c == 'ContentDocumentLink') {
                    objectLabel = System.Label.Timeline_Label_Files;
                }

                mapOfTimelineTypes.put(timelineType.Object_Name__c, objectLabel);
            }

            return mapOfTimelineTypes;
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, String>> getTimelineRecords( String parentObjectId, String earliestRange, String latestRange ) {
        
        try {
            String parentObjectType = String.valueOf(Id.valueOf(parentObjectId).getSobjectType());
            String parentConfigType = parentObjectType;

            if (parentObjectType == 'Account' && isPersonAccount(parentObjectId)  ) {
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
                                            + 'Object_Name__c, '
                                            + 'Type_Field__c, '
                                            + 'Fallback_Tooltip_Field__c '
                                        + 'FROM Timeline_Configuration__mdt '
                                        + 'WHERE Active__c = true AND '
                                        + 'Parent_Object__c =:parentConfigType'; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query( queryTimelineConfiguration ); //NOPMD

            Map<String, TimelineRecord> mapOfTimelineConfigurationRecords = new Map<String, TimelineRecord>();

            for ( Timeline_Configuration__mdt timelineConfigurationRecord : listOfTimelineConfigurations ) {

                TimelineRecord timelineRecord = new timelineRecord();
                timelineRecord.active = timelineConfigurationRecord.Active__c;
                timelineRecord.relationshipName = timelineConfigurationRecord.Relationship_Name__c;
                timelineRecord.icon = timelineConfigurationRecord.Icon__c;
                timelineRecord.iconBackground = timelineConfigurationRecord.Icon_Background_Colour__c;
                timelineRecord.detailField = timelineConfigurationRecord.Detail_Field__c;
                timelineRecord.objectName = timelineConfigurationRecord.Object_Name__c;
                timelineRecord.type = timelineConfigurationRecord.Type_Field__c;
                timelineRecord.positionDateField = timelineConfigurationRecord.Position_Date_Field__c;
                timelineRecord.fallbackTooltipField = timelineConfigurationRecord.Fallback_Tooltip_Field__c;

                mapOfTimelineConfigurationRecords.put(timelineRecord.objectName + timelineRecord.relationshipName, timelineRecord);
            }

            Map<String, String> childObjects = getChildObjects(parentObjectType);

            String innerQuery = '';

            for (String eachObject : mapOfTimelineConfigurationRecords.keyset()) {

                TimelineRecord tcr = mapOfTimelineConfigurationRecords.get(eachObject);

                if (childObjects.containsKey(eachObject)) {

                    String objName = String.valueOf(tcr.objectName);
                    String tooltipField = String.valueOf(tcr.fallbackTooltipField);
                    String typeField = String.valueOf(tcr.type);
        
                    String selectStatement = '(SELECT Id, ' 
                                    + tcr.detailField + ', ' 
                                    + tcr.positionDateField + '';

                    if ( (typeField != null && typeField != '') && (objName == 'Task' || objName == 'ContentDocumentLink')) {
                        selectStatement = selectStatement + ', '
                                    + tcr.type + '';
                    }

                    if ( objName == 'ContentDocumentLink' ) {
                        selectStatement = selectStatement + ', '
                                    + 'ContentDocumentId' + '';
                    }

                    if ( tooltipField != null && tooltipField != '' && tcr.detailField <> tcr.fallbackTooltipField) {
                        selectStatement = selectStatement + ', '
                                    + tcr.fallbackTooltipField + '';
                    }

                    innerQuery = innerQuery + 
                                selectStatement +
                                + ' FROM ' + tcr.relationshipName 
                                + ' WHERE ' + tcr.positionDateField + '>= LAST_N_MONTHS:' + earliestRange
                                + ' AND ' + tcr.positionDateField + ' <= NEXT_N_MONTHS:' + latestRange + '),';
                }
            }

            innerQuery = innerQuery.removeEnd(',');

            String queryRecords = 'SELECT Id, ' 
                                    + innerQuery 
                                + ' FROM ' + parentObjectType 
                                + ' WHERE Id =:parentObjectId'; //NOPMD

            List<SObject> listOfTimelineRecords = Database.query( queryRecords ); //NOPMD

            List<Map<String, String>> listOfTimelineData = new List<Map<String, String>>();

            for (Sobject each : listOfTimelineRecords) {
                for (String eachObj : mapOfTimelineConfigurationRecords.keyset()) {
                    if (childObjects.containsKey(eachObj) && each.getSObjects(childObjects.get(eachObj)) != null && each.getSObjects(childObjects.get(eachObj)).size() != 0)
                        for (Sobject eachCh : (List<SObject>)each.getSObjects(childObjects.get(eachObj))) {

                            Map<String, String> mapData = new Map<String, String>();

                            TimelineRecord tr = mapOfTimelineConfigurationRecords.get(eachObj );

                            String objectLabel  = ((SObject)(Type.forName('Schema.'+ String.valueOf(eachCh.getSobjectType())).newInstance())).getSObjectType().getDescribe().getLabel();

                            if ( tr != null ) {
                                String myId = eachCh.Id;
                                Map<String, String> detailValues = getFieldValues(tr.detailField, eachCh);
                                Map<String, String> positionValues = getFieldValues(tr.positionDateField, eachCh);
                                Map<String, String> fallbackValues = getFieldValues(tr.fallbackTooltipField, eachCh);
                                Map<String, String> typeValues = getFieldValues(tr.type, eachCh);

                                if ( tr.objectName == 'ContentDocumentLink') { //NOPMD
                                    myId = String.valueOf(eachCh.get('ContentDocumentId'));
                                }

                                mapData.put('objectId', myId);
                                mapData.put('parentObject', parentObjectType);
                                mapData.put('detailField', detailValues.get('value'));
                                mapData.put('detailFieldLabel', detailValues.get('label'));
                                mapData.put('positionDateField', tr.positionDateField);
                                mapData.put('positionDateValue', positionValues.get('value'));
                                mapData.put('objectName', tr.objectName);
                                mapData.put('objectLabel', objectLabel);
                                mapData.put('fallbackTooltipField', fallbackValues.get('label'));
                                mapData.put('fallbackTooltipValue', fallbackValues.get('value'));
                                mapData.put('type', typeValues.get('value'));
                                mapData.put('icon', tr.icon);
                                mapData.put('iconBackground', tr.iconBackground);

                                listOfTimelineData.add(mapData);
                            }
                        }
                }
            }
            return listOfTimelineData;
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<String, String> getChildObjects(String Obj) {
		Map<String, String> childRelatedObjects = new Map<String, String>();
       
        List<Schema.ChildRelationship> objectRelationships = ((SObject)(Type.forName('Schema.'+ Obj).newInstance())).getSObjectType().getDescribe().getChildRelationships();
		for (Schema.Childrelationship eachRelationship : objectRelationships) {
			if (eachRelationship.getChildSObject().getDescribe().isAccessible()
			        && !eachRelationship.getChildSObject().getDescribe().getLabel().contains('Histories')
			        && eachRelationship.getRelationshipName() != null) {
                childRelatedObjects.put(String.valueOf(eachRelationship.getChildSObject() + String.valueOf(eachRelationship.getRelationshipName())), String.valueOf(eachRelationship.getRelationshipName()));
			}
		}
		return childRelatedObjects;
	}

    private static Map<String, String> getFieldValues(String field, Sobject records) {

        Map<String, String> fieldDetails = new Map<String, String>();

        String fieldValue = '';
        String fieldLabel = '';
       
        if ( field == null || field == '' ) {
            fieldDetails.put('value' ,'');
            fieldDetails.put('label', '');
            return fieldDetails;
        }

        Boolean isDotNotationUsed = field.contains('.');

        if ( isDotNotationUsed == true ) {
            String splitObject = field.SubStringBefore('.');
            String splitField = field.SubStringAfter('.');

            fieldValue = String.valueOf(records.getSobject(splitObject).get(splitField));

            Schema.DescribeSObjectResult describeParentSobjects = ((SObject)(Type.forName('Schema.'+ String.valueOf(splitObject)).newInstance())).getSObjectType().getDescribe();
            fieldLabel = String.valueOf( describeParentSobjects.fields.getMap().get(splitField).getDescribe().getLabel() );
        }
        else {
            Schema.DescribeSObjectResult describeSobjects = ((SObject)(Type.forName('Schema.'+ String.valueOf(records.getSobjectType())).newInstance())).getSObjectType().getDescribe();

            fieldValue = String.valueOf(records.get(field));
            fieldLabel = String.valueOf( describeSobjects.fields.getMap().get(field).getDescribe().getLabel() );
        }

        if (fieldValue != null && fieldValue.length() > 255) {
            fieldValue = fieldValue.substring(0,251) + '...';
        }

        fieldDetails.put('value', fieldValue);
        fieldDetails.put('label', fieldLabel);

        return fieldDetails;
    }

    private static Boolean isPersonAccount(String recordId)
    {
        if ( Account.SObjectType.getDescribe().hasSubtypes ) {
            String queryPersonAccount = 'SELECT Id, IsPersonAccount FROM Account Where Id =:recordId';
            SObject acc = Database.query( queryPersonAccount );

            if ( acc.get('IsPersonAccount') == true ) {
                return true;
            }
            else {
                return false;
            }
        }

        return false;
    }

    private class TimelineRecord { //NOPMD
        @AuraEnabled public Boolean active;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public String parentObject;
        @AuraEnabled public String detailField;
        @AuraEnabled public String detailFieldLabel;
        @AuraEnabled public String icon;
        @AuraEnabled public String iconBackground;
        @AuraEnabled public String positionDateField;
        @AuraEnabled public String positionDateValue;
        @AuraEnabled public String objectName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String type;
        @AuraEnabled public String fallbackTooltipField;
        @AuraEnabled public String fallbackTooltipValue;
        @AuraEnabled public String fallbackNameField;
        @AuraEnabled public String fallbackNameValue;
        @AuraEnabled public Id recordId;
    }
}