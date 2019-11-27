public with sharing class timelineService {
   
    @AuraEnabled
    public static List<Map<String, String>> getTimelineRecords( String parentObjectId, String earliestRange, String latestRange ) {
        
        try {
            String parentObjectType = String.valueOf(Id.valueOf(parentObjectId).getSobjectType());
            earliestRange = String.valueOf(Integer.valueOf(earliestRange) * 12);
            latestRange = String.valueOf(Integer.valueOf(latestRange) * 12);

            String queryTimelineConfiguration = 'SELECT Detail_Field__c, '
                                            + 'Active__c, '
                                            + 'Icon__c, '
                                            + 'Icon_Background_Colour__c, '
                                            + 'Position_Date_Field__c, '
                                            + 'Object_Name__c, '
                                            + 'Type_Field__c '
                                        + 'FROM Timeline_Configuration__mdt '
                                        + 'WHERE Active__c = true AND '
                                        + 'Parent_Object__c =:parentObjectType';

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query( queryTimelineConfiguration );

            Map<String, TimelineRecord> mapOfTimelineConfigurationRecords = new Map<String, TimelineRecord>();

            for ( Timeline_Configuration__mdt timelineConfigurationRecord : listOfTimelineConfigurations ) {

                TimelineRecord timelineRecord = new timelineRecord();
                timelineRecord.active = timelineConfigurationRecord.Active__c;
                timelineRecord.icon = timelineConfigurationRecord.Icon__c;
                timelineRecord.iconBackground = timelineConfigurationRecord.Icon_Background_Colour__c;
                timelineRecord.detailField = timelineConfigurationRecord.Detail_Field__c;
                timelineRecord.objectName = timelineConfigurationRecord.Object_Name__c;
                timelineRecord.type = timelineConfigurationRecord.Type_Field__c;
                timelineRecord.positionDateField = timelineConfigurationRecord.Position_Date_Field__c;

                mapOfTimelineConfigurationRecords.put(timelineRecord.objectName, timelineRecord);
            }

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, String> childObjects = getChildObjects(parentObjectType, schemaMap);

            String innerQuery = '';

            for (String eachObject : mapOfTimelineConfigurationRecords.keyset()) {

                TimelineRecord tcr = mapOfTimelineConfigurationRecords.get(eachObject);

                if (childObjects.containsKey(eachObject)) {

                    String objName = String.valueOf(tcr.objectName);
                    String selectStatement = '(SELECT Id, ' 
                                    + tcr.detailField + ', ' 
                                    + tcr.positionDateField + '';

                    if ( objName == 'Task' ) {
                        selectStatement = selectStatement + ', '
                                    + tcr.type + '';
                    }
                  
                    innerQuery = innerQuery + 
                                selectStatement +
                                + ' FROM ' + childObjects.get(eachObject) 
                                + ' WHERE ' + tcr.positionDateField + '>= LAST_N_MONTHS:' + earliestRange
                                + ' AND ' + tcr.positionDateField + ' <= NEXT_N_MONTHS:' + latestRange + '),';
                }
            }

            innerQuery = innerQuery.removeEnd(',');

            String queryRecords = 'SELECT Id, ' 
                                    + innerQuery 
                                + ' FROM ' + parentObjectType 
                                + ' WHERE Id =:parentObjectId';

            List<SObject> listOfTimelineRecords = Database.query( queryRecords );

            List<Sobject> result = new List<Sobject>();

            for (Sobject each : listOfTimelineRecords) {

                for (String eachObj : mapOfTimelineConfigurationRecords.keyset()) {
                    if (childObjects.containsKey(eachObj)) {
                        if (each.getSObjects(childObjects.get(eachObj)) != null && each.getSObjects(childObjects.get(eachObj)).size() != 0)
                            for (Sobject eachCh : (List<SObject>)each.getSObjects(childObjects.get(eachObj))) {
                                result.add(eachCh);
                            }
                    }
                }
            }

            List<Map<String, String>> listOfTimelineData = new List<Map<String, String>>();
            
            for (SObject records : result) {

                Map<String, String> mapData = new Map<String, String>();

                TimelineRecord tr = mapOfTimelineConfigurationRecords.get(String.valueOf(records.getSobjectType()));

                List<Schema.DescribeSObjectResult> describeSobjects = Schema.describeSObjects(new List<String>{String.valueOf(records.getSobjectType())});

                System.debug('@@timeline - sObject Label - ' + describeSobjects[0].getLabel());

                if ( tr != null ) {
                    String displayName = tr.objectName;
                    String detailField = String.valueOf(records.get(tr.detailField));
                    String positionDate = String.valueOf(records.get(tr.positionDateField));
                    String type = '';

                    if ( String.valueOf(tr.objectName) == 'Task' ) {
                        type = String.valueOf(records.get(tr.type));
                    }
                
                    String positionFieldLabel = '';

                    mapData.put('objectId', records.Id);
                    mapData.put('parentObject', parentObjectType);
                    mapData.put('detailField', detailField);
                    mapData.put('positionDateField', tr.positionDateField);
                    mapData.put('positionDateValue', positionDate);
                    mapData.put('objectName', tr.objectName);
                    mapData.put('objectLabel', describeSobjects[0].getLabel());
                    mapData.put('type', type);
                    mapData.put('icon', tr.icon);
                    mapData.put('iconBackground', tr.iconBackground);

                    listOfTimelineData.add(mapData);
                }
            }
            return listOfTimelineData;
        }
        catch(Exception e) {
            System.debug('@@timeline - Error - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Map<String, String> getChildObjects(String Obj, Map<String, Schema.SObjectType> schemaMap) {
		Map<String, String> childRelatedObjects = new Map<String, String>();
		List<Schema.ChildRelationship> objectRelationships = schemaMap.get(Obj).getDescribe().getChildRelationships();
		for (Schema.Childrelationship eachRelationship : objectRelationships) {
			if (eachRelationship.getChildSObject().getDescribe().isAccessible()
			        && !eachRelationship.getChildSObject().getDescribe().getLabel().contains('History')
			        && eachRelationship.getRelationshipName() != null) {
				childRelatedObjects.put(String.valueOf(eachRelationship.getChildSObject()), String.valueOf(eachRelationship.getRelationshipName()));
			}
		}
		return childRelatedObjects;
	}

    private class TimelineRecord {
        @AuraEnabled public Boolean active;
        @AuraEnabled public String parentObject;
        @AuraEnabled public String detailField;
        @AuraEnabled public String icon;
        @AuraEnabled public String iconBackground;
        @AuraEnabled public String positionDateField;
        @AuraEnabled public String positionDateValue;
        @AuraEnabled public String objectName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String type;
        @AuraEnabled public Id recordId;
    }
}