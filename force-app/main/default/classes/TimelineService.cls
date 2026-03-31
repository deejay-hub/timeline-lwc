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
    public static Map<String, String> getTimelineTypes(Id parentObjectId, String parentFieldName) {
        try {
            Map<String, String> parentDetails = getParentDetails(parentObjectId, parentFieldName);

            String parentObjectType = parentDetails.get('QueryObjectType');
            String parentConfigType = parentDetails.get('ConfigObjectType'); //NOPMD
            parentObjectId = parentDetails.get('Id');

            Set<String> allRelationshipKeys = new Set<String>();
            Map<String, String> childObjects = getChildObjects(parentObjectType, allRelationshipKeys);

            String queryTimelineConfiguration =
                'SELECT Active__c, ' +
                'Relationship_Name__c, ' +
                'Object_Name__c, ' +
                'Tooltip_Object_Name__c, ' +
                'DeveloperName, ' +
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
                String configKey = timelineType.Object_Name__c + timelineType.Relationship_Name__c;
                if (!childObjects.containsKey(configKey)) {
                    if (!allRelationshipKeys.contains(configKey)) {
                        throw new TimelineSetupException(
                            JSON.serialize(
                                new Map<String, String>{
                                    'type' => 'Setup-Error',
                                    'code' => 'TLN-403',
                                    'message' => String.format(
                                        System.Label.Timeline_Error_InvalidRelationship,
                                        new List<String>{
                                            timelineType.Relationship_Name__c,
                                            parentObjectType,
                                            timelineType.DeveloperName
                                        }
                                    )
                                }
                            )
                        );
                    }
                    continue;
                }

                String objectLabel = ((SObject) (Type.forName('Schema.' + String.valueOf(timelineType.Object_Name__c))
                        .newInstance()))
                    .getSObjectType()
                    .getDescribe(SObjectDescribeOptions.DEFERRED)
                    .getLabelPlural();

                if (timelineType.Object_Name__c == 'ContentDocumentLink') {
                    objectLabel = System.Label.Timeline_Label_Files;
                }

                if (timelineType.Tooltip_Object_Name__c != null && timelineType.Tooltip_Object_Name__c != '') {
                    Type tooltipType = Type.forName('Schema.' + String.valueOf(timelineType.Tooltip_Object_Name__c));
                    if (tooltipType == null) {
                        throw new TimelineSetupException(
                            JSON.serialize(
                                new Map<String, String>{
                                    'type' => 'Setup-Error',
                                    'code' => 'TLN-402',
                                    'message' => String.format(
                                        System.Label.Timeline_Error_InvalidTooltipObject,
                                        new List<String>{
                                            timelineType.Tooltip_Object_Name__c,
                                            timelineType.DeveloperName
                                        }
                                    )
                                }
                            )
                        );
                    }
                    objectLabel = ((SObject) tooltipType.newInstance())
                        .getSObjectType()
                        .getDescribe(SObjectDescribeOptions.DEFERRED)
                        .getLabelPlural();
                }

                mapOfTimelineTypes.put(timelineType.Object_Name__c, objectLabel);
            }

            return mapOfTimelineTypes;
        } catch (System.QueryException e) {
            throw clientError('Setup-Error', 'TLN-101', System.Label.Timeline_Error_InvalidConfig);
        } catch (TimelineSetupException e) {
            throw timelineSetupErrorOrFallback(
                e,
                'Setup-Error',
                'TLN-102',
                System.Label.Timeline_Error_SetupIncomplete
            );
        } catch (Exception e) {
            throw clientError('Error', 'TLN-199', System.Label.Timeline_Error_UnexpectedTypes);
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
        Id parentObjectId,
        String earliestRange,
        String latestRange,
        String parentFieldName
    ) {
        try {
            Map<String, String> parentDetails = getParentDetails(parentObjectId, parentFieldName);

            String parentObjectType = parentDetails.get('QueryObjectType');
            String parentConfigType = parentDetails.get('ConfigObjectType'); //NOPMD
            parentObjectId = parentDetails.get('Id');

            earliestRange = String.ValueOf((Decimal.ValueOf(earliestRange) * 12).intValue());
            latestRange = String.ValueOf((Decimal.ValueOf(latestRange) * 12).intValue());

            String queryTimelineConfiguration =
                'SELECT Detail_Field__c, ' +
                'Relationship_Name__c, ' +
                'Active__c, ' +
                'Icon__c, ' +
                'Icon_Background_Colour__c, ' +
                'Icon_Field__c, ' +
                'Icon_Background_Colour_Field__c, ' +
                'Position_Date_Field__c, ' +
                'Object_Name__c, ' +
                'Type_Field__c, ' +
                'Drilldown_Id_Field__c, ' +
                'Tooltip_Id_Field__c, ' +
                'Tooltip_Object_Name__c, ' +
                'Fallback_Tooltip_Field__c, ' +
                'Inclusion_Field__c, ' +
                'DeveloperName ' +
                'FROM Timeline_Configuration__mdt ' +
                'WHERE Active__c = true AND ' +
                'Test__c = ' +
                Test.isRunningTest() +
                ' AND ' +
                'Parent_Object__c =:parentConfigType'; //NOPMD

            List<Timeline_Configuration__mdt> listOfTimelineConfigurations = Database.query(queryTimelineConfiguration); //NOPMD

            if (listOfTimelineConfigurations.size() < 1) {
                throw new TimelineSetupException(
                    JSON.serialize(
                        new Map<String, String>{
                            'type' => 'Setup-Error',
                            'code' => 'TLN-203',
                            'message' => String.format(
                                System.Label.Timeline_Error_NoConfigRecords,
                                new List<String>{ parentObjectType }
                            )
                        }
                    )
                );
            }

            Map<String, TimelineRecord> mapOfTimelineConfigurationRecords = new Map<String, TimelineRecord>();

            // Optimization: Cache field paths to avoid repeated string splitting
            Map<String, Map<String, FieldPath>> configFieldPaths = new Map<String, Map<String, FieldPath>>();

            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

            for (Timeline_Configuration__mdt timelineConfigurationRecord : listOfTimelineConfigurations) {
                TimelineRecord timelineRecord = new timelineRecord();
                Schema.SObjectType timelineRecordObjectType = globalDescribe
                    .get(timelineConfigurationRecord.Object_Name__c);
                if (timelineRecordObjectType == null) {
                    throw new TimelineSetupException(
                        JSON.serialize(
                            new Map<String, String>{
                                'type' => 'Setup-Error',
                                'code' => 'TLN-401',
                                'message' => String.format(
                                    System.Label.Timeline_Error_InvalidObjectName,
                                    new List<String>{
                                        timelineConfigurationRecord.Object_Name__c,
                                        timelineConfigurationRecord.DeveloperName
                                    }
                                )
                            }
                        )
                    );
                }
                Schema.DescribeSObjectResult timelineDescribeResult = timelineRecordObjectType.getDescribe();
                Map<String, Schema.SObjectField> childFieldsMap = timelineDescribeResult.fields.getMap();
                timelineRecord.objectLabel = timelineDescribeResult.getLabel();
                timelineRecord.relationshipName = timelineConfigurationRecord.Relationship_Name__c;
                timelineRecord.icon = timelineConfigurationRecord.Icon__c;
                timelineRecord.iconBackground = timelineConfigurationRecord.Icon_Background_Colour__c;
                timelineRecord.iconField = timelineConfigurationRecord.Icon_Field__c;
                timelineRecord.iconBackgroundField = timelineConfigurationRecord.Icon_Background_Colour_Field__c;
                timelineRecord.detailField = timelineConfigurationRecord.Detail_Field__c;
                timelineRecord.objectName = timelineConfigurationRecord.Object_Name__c;
                timelineRecord.type = timelineConfigurationRecord.Type_Field__c;
                timelineRecord.positionDateField = timelineConfigurationRecord.Position_Date_Field__c;
                timelineRecord.fallbackTooltipField = timelineConfigurationRecord.Fallback_Tooltip_Field__c;
                timelineRecord.tooltipIdField = timelineConfigurationRecord.Tooltip_Id_Field__c;
                timelineRecord.tooltipObject = timelineConfigurationRecord.Tooltip_Object_Name__c;
                timelineRecord.drilldownIdField = timelineConfigurationRecord.Drilldown_Id_Field__c;
                timelineRecord.inclusionField = timelineConfigurationRecord.Inclusion_Field__c;
                timelineRecord.developerName = timelineConfigurationRecord.DeveloperName;

                if (!isValidFieldForSoql(timelineRecord.detailField, childFieldsMap)) {
                    throw new TimelineSetupException(
                        JSON.serialize(
                            new Map<String, String>{
                                'type' => 'Setup-Error',
                                'code' => 'TLN-404',
                                'message' => String.format(
                                    System.Label.Timeline_Error_InvalidField,
                                    new List<String>{
                                        timelineRecord.detailField,
                                        timelineConfigurationRecord.Object_Name__c,
                                        timelineConfigurationRecord.DeveloperName
                                    }
                                )
                            }
                        )
                    );
                }
                if (!isValidFieldForSoql(timelineRecord.positionDateField, childFieldsMap)) {
                    throw new TimelineSetupException(
                        JSON.serialize(
                            new Map<String, String>{
                                'type' => 'Setup-Error',
                                'code' => 'TLN-404',
                                'message' => String.format(
                                    System.Label.Timeline_Error_InvalidField,
                                    new List<String>{
                                        timelineRecord.positionDateField,
                                        timelineConfigurationRecord.Object_Name__c,
                                        timelineConfigurationRecord.DeveloperName
                                    }
                                )
                            }
                        )
                    );
                }
                if (
                    String.isNotBlank(timelineRecord.type) && !isValidFieldForSoql(timelineRecord.type, childFieldsMap)
                ) {
                    timelineRecord.type = null;
                }
                if (
                    String.isNotBlank(timelineRecord.fallbackTooltipField) &&
                    !isValidFieldForSoql(timelineRecord.fallbackTooltipField, childFieldsMap)
                ) {
                    timelineRecord.fallbackTooltipField = null;
                }
                if (
                    String.isNotBlank(timelineRecord.tooltipIdField) &&
                    !isValidFieldForSoql(timelineRecord.tooltipIdField, childFieldsMap)
                ) {
                    timelineRecord.tooltipIdField = null;
                }
                if (
                    String.isNotBlank(timelineRecord.drilldownIdField) &&
                    !isValidFieldForSoql(timelineRecord.drilldownIdField, childFieldsMap)
                ) {
                    timelineRecord.drilldownIdField = null;
                }
                if (
                    String.isNotBlank(timelineRecord.iconField) &&
                    !isValidFieldForSoql(timelineRecord.iconField, childFieldsMap)
                ) {
                    timelineRecord.iconField = null;
                }
                if (
                    String.isNotBlank(timelineRecord.iconBackgroundField) &&
                    !isValidFieldForSoql(timelineRecord.iconBackgroundField, childFieldsMap)
                ) {
                    timelineRecord.iconBackgroundField = null;
                }
                if (
                    String.isNotBlank(timelineRecord.inclusionField) &&
                    !isValidFieldForSoql(timelineRecord.inclusionField, childFieldsMap)
                ) {
                    timelineRecord.inclusionField = null;
                }

                String configKey = timelineRecord.objectName + timelineRecord.relationshipName;

                mapOfTimelineConfigurationRecords.put(configKey, timelineRecord);

                // Pre-calculate field paths for this configuration
                Map<String, FieldPath> paths = new Map<String, FieldPath>();
                paths.put('detailField', new FieldPath(timelineRecord.detailField));
                paths.put('positionDateField', new FieldPath(timelineRecord.positionDateField));
                paths.put('fallbackTooltipField', new FieldPath(timelineRecord.fallbackTooltipField));
                paths.put('tooltipIdField', new FieldPath(timelineRecord.tooltipIdField));
                paths.put('drilldownIdField', new FieldPath(timelineRecord.drilldownIdField));
                paths.put('iconField', new FieldPath(timelineRecord.iconField));
                paths.put('iconBackgroundField', new FieldPath(timelineRecord.iconBackgroundField));
                paths.put('type', new FieldPath(timelineRecord.type));

                configFieldPaths.put(configKey, paths);
            }

            Set<String> allRelationshipKeys = new Set<String>();
            Map<String, String> childObjects = getChildObjects(parentObjectType, allRelationshipKeys);

            String innerQuery = '';

            for (String eachObject : mapOfTimelineConfigurationRecords.keyset()) {
                TimelineRecord tcr = mapOfTimelineConfigurationRecords.get(eachObject);

                if (!childObjects.containsKey(eachObject)) {
                    if (!allRelationshipKeys.contains(eachObject)) {
                        throw new TimelineSetupException(
                            JSON.serialize(
                                new Map<String, String>{
                                    'type' => 'Setup-Error',
                                    'code' => 'TLN-403',
                                    'message' => String.format(
                                        System.Label.Timeline_Error_InvalidRelationship,
                                        new List<String>{ tcr.relationshipName, parentObjectType, tcr.developerName }
                                    )
                                }
                            )
                        );
                    }
                    continue;
                }

                if (childObjects.containsKey(eachObject)) {
                    String objName = String.valueOf(tcr.objectName);
                    String tooltipField = String.valueOf(tcr.fallbackTooltipField);
                    String tooltipIdField = String.valueOf(tcr.tooltipIdField);
                    String drilldownIdField = String.valueOf(tcr.drilldownIdField);
                    String typeField = String.valueOf(tcr.type);
                    String iconField = String.valueOf(tcr.iconField);
                    String iconColourField = String.valueOf(tcr.iconBackgroundField);

                    String selectStatement = '(SELECT Id, ' + tcr.detailField + ', ' + tcr.positionDateField + '';

                    if (
                        (typeField != null && typeField != '') &&
                        (objName == 'Task' ||
                        objName == 'OpenActivity' ||
                        objName == 'ActivityHistory' ||
                        objName == 'TaskRelation' ||
                        objName == 'ContentDocumentLink' ||
                        objName == 'TaskWhoRelation' ||
                        objName == 'LookedUpFromActivity')
                    ) {
                        selectStatement = selectStatement + ', ' + tcr.type + '';
                    }

                    if (
                        (objName == 'OpenActivity' || objName == 'ActivityHistory') &&
                        !selectStatement.contains('ActivityDate')
                    ) {
                        selectStatement = selectStatement + ', ActivityDate' + '';
                    }

                    if (
                        (objName == 'OpenActivity' || objName == 'ActivityHistory') &&
                        !selectStatement.contains('AlternateDetailId')
                    ) {
                        selectStatement = selectStatement + ', AlternateDetailId' + '';
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

                    if (iconField != null && iconField != '') {
                        selectStatement = selectStatement + ', ' + tcr.iconField + '';
                    }

                    if (iconColourField != null && iconColourField != '') {
                        selectStatement = selectStatement + ', ' + tcr.iconBackgroundField + '';
                    }

                    String relationship = tcr.relationshipName;
                    String optionalFilter = '';

                    if (tcr.inclusionField != '' && tcr.inclusionField != null) {
                        optionalFilter = tcr.inclusionField + ' = true AND ';
                    }

                    innerQuery = innerQuery + selectStatement + ' FROM ' + relationship;

                    if (objName == 'OpenActivity') {
                        innerQuery =
                            innerQuery +
                            ' ORDER BY ' +
                            'ActivityDate ASC NULLS LAST, LastModifiedDate DESC LIMIT 500),';
                    } else if (objName == 'ActivityHistory' || objName == 'LookedUpFromActivity') {
                        innerQuery =
                            innerQuery +
                            ' ORDER BY ' +
                            'ActivityDate DESC NULLS LAST, LastModifiedDate DESC LIMIT 500),';
                    } else {
                        innerQuery =
                            innerQuery +
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
            }

            innerQuery = innerQuery.removeEnd(',');

            String queryRecords =
                'SELECT Id, ' +
                innerQuery +
                ' FROM ' +
                parentObjectType +
                ' WHERE Id =:parentObjectId'; //NOPMD

            List<SObject> listOfTimelineRecords = Database.query(queryRecords); //NOPMD
            SObjectAccessDecision parentAccessDecision = Security.stripInaccessible(
                AccessType.READABLE,
                listOfTimelineRecords
            );
            List<SObject> secureTimelineRecords = parentAccessDecision.getRecords();

            List<Map<String, String>> listOfTimelineData = new List<Map<String, String>>();
            Map<String, String> dupeDataCheck = new Map<String, String>();

            for (SObject each : secureTimelineRecords) {
                Map<String, Object> childRecordsAsMap = each.getPopulatedFieldsAsMap();

                for (String fieldName : childRecordsAsMap.keySet()) {
                    if (childRecordsAsMap.get(fieldName) instanceof List<sObject>) {
                        List<sObject> childRecords = (List<sObject>) childRecordsAsMap.get(fieldName);
                        if (childRecords.isEmpty()) {
                            continue;
                        }
                        SObjectAccessDecision childAccessDecision = Security.stripInaccessible(
                            AccessType.READABLE,
                            childRecords
                        );
                        List<SObject> secureChildRecords = childAccessDecision.getRecords();

                        for (Sobject eachCh : secureChildRecords) {
                            Map<String, String> mapData = new Map<String, String>();

                            String configKey = eachCh.getSObjectType() + fieldName;
                            TimelineRecord tr = mapOfTimelineConfigurationRecords.get(configKey);
                            Map<String, FieldPath> paths = configFieldPaths.get(configKey);

                            String myId = eachCh.Id;

                            if (!dupeDataCheck.containsKey(myId)) {
                                dupeDataCheck.put(myId, myId);

                                Map<String, String> detailValues = getFieldValues(
                                    paths.get('detailField'),
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> positionValues = getFieldValues(
                                    paths.get('positionDateField'),
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> fallbackValues = getFieldValues(
                                    paths.get('fallbackTooltipField'),
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> tooltipIdValues = getFieldValues(
                                    paths.get('tooltipIdField'),
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> drilldownIdValues = getFieldValues(
                                    paths.get('drilldownIdField'),
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> iconValues = getFieldValues(
                                    paths.get('iconField'),
                                    eachCh,
                                    tr.objectName
                                );
                                Map<String, String> iconColourValues = getFieldValues(
                                    paths.get('iconBackgroundField'),
                                    eachCh,
                                    tr.objectName
                                );

                                Map<String, String> typeValues = getFieldValues(
                                    paths.get('type'),
                                    eachCh,
                                    tr.objectName
                                );

                                String alternateDetailId = '';

                                if (
                                    (tr.objectName == 'OpenActivity' || tr.objectName == 'ActivityHistory') &&
                                    (String.valueOf(eachCh.get('AlternateDetailId')) != '' &&
                                    String.valueOf(eachCh.get('AlternateDetailId')) != null)
                                ) {
                                    alternateDetailId = String.valueOf(eachCh.get('AlternateDetailId'));
                                }

                                mapData.put('alternateDetailId', alternateDetailId);

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
                                mapData.put('positionDateType', positionValues.get('type'));
                                mapData.put('objectName', tr.objectName);
                                mapData.put('objectLabel', tr.objectLabel);
                                mapData.put('fallbackTooltipField', fallbackValues.get('label'));
                                mapData.put('fallbackTooltipValue', fallbackValues.get('value'));
                                mapData.put('drilldownId', drilldownIdValues.get('value'));
                                mapData.put('tooltipId', tooltipIdValues.get('value'));
                                mapData.put('tooltipObject', tr.tooltipObject);
                                mapData.put('fallbackTooltipValue', fallbackValues.get('value'));
                                mapData.put('type', typeValues.get('value'));

                                if (iconValues.get('value') != null && iconValues.get('value') != '') {
                                    mapData.put('icon', iconValues.get('value'));
                                } else {
                                    mapData.put('icon', tr.icon);
                                }

                                if (iconColourValues.get('value') != null && iconColourValues.get('value') != '') {
                                    mapData.put('iconBackground', iconColourValues.get('value'));
                                } else {
                                    mapData.put('iconBackground', tr.iconBackground);
                                }

                                if (positionValues.get('value') != null && positionValues.get('value') != '') {
                                    listOfTimelineData.add(mapData);
                                }
                            }
                        }
                    }
                }
            }
            return listOfTimelineData;
        } catch (TimelineSetupException e) {
            throw timelineSetupErrorOrFallback(
                e,
                'Setup-Error',
                'TLN-201',
                System.Label.Timeline_Error_SetupIncomplete
            );
        } catch (System.QueryException e) {
            throw clientError('Setup-Error', 'TLN-202', System.Label.Timeline_Error_QueryFailed);
        } catch (Exception e) {
            throw clientError('Error', 'TLN-299', System.Label.Timeline_Error_UnexpectedRecords);
        }
    }

    private static AuraHandledException clientError(String type, String code, String message) {
        Map<String, String> payload = new Map<String, String>{ 'type' => type, 'code' => code, 'message' => message };
        return new AuraHandledException(JSON.serialize(payload));
    }

    private static AuraHandledException timelineSetupErrorOrFallback(
        TimelineSetupException e,
        String fallbackType,
        String fallbackCode,
        String fallbackMessage
    ) {
        String rawMessage = e.getMessage();
        if (String.isBlank(rawMessage)) {
            return clientError(fallbackType, fallbackCode, fallbackMessage);
        }

        try {
            Object parsed = JSON.deserializeUntyped(rawMessage);
            if (parsed instanceof Map<String, Object>) {
                Map<String, Object> existingPayload = (Map<String, Object>) parsed;
                String existingType = String.valueOf(existingPayload.get('type'));
                String existingMessage = String.valueOf(existingPayload.get('message'));
                String existingCode = String.valueOf(existingPayload.get('code'));

                if (!String.isBlank(existingType) && !String.isBlank(existingMessage)) {
                    Map<String, String> normalizedPayload = new Map<String, String>{
                        'type' => existingType,
                        'code' => String.isBlank(existingCode) ? fallbackCode : existingCode,
                        'message' => existingMessage
                    };
                    return new AuraHandledException(JSON.serialize(normalizedPayload));
                }
            }
        } catch (Exception ignoreError) {
            // Fall back to a generic client-safe payload when parsing fails.
        }

        return clientError(fallbackType, fallbackCode, fallbackMessage);
    }

    private static Map<String, String> getChildObjects(String parentObject, Set<String> allRelationshipKeys) {
        Map<String, String> childRelatedObjects = new Map<String, String>();

        List<Schema.ChildRelationship> objectRelationships = ((SObject) (Type.forName('Schema.' + parentObject)
                .newInstance()))
            .getSObjectType()
            .getDescribe()
            .getChildRelationships();
        for (Schema.Childrelationship eachRelationship : objectRelationships) {
            if (eachRelationship.getRelationshipName() == null) {
                continue;
            }
            String key = String.valueOf(
                eachRelationship.getChildSObject() + String.valueOf(eachRelationship.getRelationshipName())
            );
            allRelationshipKeys.add(key);

            Schema.DescribeSObjectResult childDescribe = eachRelationship.getChildSObject().getDescribe();
            if (childDescribe.isAccessible() && !childDescribe.getLabel().contains('Histories')) {
                childRelatedObjects.put(key, String.valueOf(eachRelationship.getRelationshipName()));
            }
        }
        return childRelatedObjects;
    }

    private static Map<String, String> getFieldValues(FieldPath path, Sobject records, String objectName) {
        Map<String, String> fieldDetails = new Map<String, String>();

        String fieldValue = '';
        String fieldLabel = '';
        String fieldType = '';
        String objectCheck = '';
        //String fieldCheck = '';
        Boolean fieldCanAccess = true;

        Id recordId;

        if (path == null || !path.isValid) {
            fieldDetails.put('value', '');
            fieldDetails.put('label', '');
            return fieldDetails;
        }

        try {
            switch on path.parts.size() {
                when 1 {
                    fieldValue = String.valueOf(records.get(path.fieldName));
                    recordId = String.valueOf(records.get('Id'));
                }
                when 2 {
                    fieldValue = String.valueOf(records.getSobject(path.parts[0]).get(path.parts[1]));
                    recordId = String.valueOf(records.getSobject(path.parts[0]).get('Id'));
                }
                when 3 {
                    fieldValue = String.valueOf(
                        records.getSobject(path.parts[0]).getSobject(path.parts[1]).get(path.parts[2])
                    );
                    recordId = String.valueOf(records.getSobject(path.parts[0]).getSobject(path.parts[1]).get('Id'));
                }
                when 4 {
                    fieldValue = String.valueOf(
                        records.getSobject(path.parts[0])
                            .getSobject(path.parts[1])
                            .getSobject(path.parts[2])
                            .get(path.parts[3])
                    );
                    recordId = String.valueOf(
                        records.getSobject(path.parts[0]).getSobject(path.parts[1]).getSobject(path.parts[2]).get('Id')
                    );
                }
                when 5 {
                    fieldValue = String.valueOf(
                        records.getSobject(path.parts[0])
                            .getSobject(path.parts[1])
                            .getSobject(path.parts[2])
                            .getSobject(path.parts[3])
                            .get(path.parts[4])
                    );
                    recordId = String.valueOf(
                        records.getSobject(path.parts[0])
                            .getSobject(path.parts[1])
                            .getSobject(path.parts[2])
                            .getSobject(path.parts[3])
                            .get('Id')
                    );
                }
            }
        } catch (SObjectException e) {
            // Field was not queried due to FLS - mark as inaccessible
            fieldCanAccess = false;
            recordId = String.valueOf(records.get('Id'));
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
            when 'ActivityHistory', 'OpenActivity', 'LookedUpFromActivity' {
                if (objectCheck == 'Task' || objectCheck == 'Event') {
                    objectCheck = objectName;
                }
            }
        }

        Schema.DescribeFieldResult fieldMetadata = getDescribeInfo(objectCheck, path.fieldStripped);

        if (fieldMetadata != null) {
            fieldLabel = fieldMetadata.getLabel();

            // Update fieldCanAccess if not already false from the catch block
            if (fieldCanAccess) {
                fieldCanAccess = fieldMetadata.isAccessible();
            }

            fieldType = String.valueOf(fieldMetadata.getType());
        } else {
            // Fallback when metadata cannot be resolved for the target field/object.
            fieldLabel = path.fieldStripped;
            fieldCanAccess = false;
            fieldType = '';
        }

        if (fieldCanAccess == false) {
            fieldValue = '![' + fieldLabel + ']!';
        }

        if (fieldValue != null && fieldValue.length() > 255) {
            fieldValue = fieldValue.substring(0, 251) + '...';
        }

        fieldDetails.put('value', fieldValue);
        fieldDetails.put('label', fieldLabel);
        fieldDetails.put('type', fieldType);

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
            Map<String, Schema.SObjectField> fieldsMap = describeSobjects.fields.getMap();

            if (fieldsMap != null && fieldsMap.containsKey(fieldName)) {
                fieldDescribeCache.put(key, fieldsMap.get(fieldName).getDescribe());
            } else {
                return null;
            }
        }

        return fieldDescribeCache.get(key);
    }

    private static Boolean isPersonAccount(String recordId) {
        if (Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount')) {
            String queryPersonAccount = 'SELECT Id, IsPersonAccount FROM Account Where Id =:recordId WITH USER_MODE LIMIT 1';
            SObject acc = Database.query(queryPersonAccount);

            if (acc.get('IsPersonAccount') == true) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, String> getParentDetails(Id recordId, String field) {
        Map<String, String> parentDetails = new Map<String, String>();

        String parentObjectType = String.valueOf(recordId.getSobjectType());
        String parentConfigType = parentObjectType;
        String fieldValue;

        if (field == 'Default_Picklist_Value') {
            fieldValue = String.valueOf(recordId);
        } else {
            SObjectType parentType = ((SObject) Type.forName('Schema.' + parentObjectType).newInstance())
                .getSObjectType();

            // Database.query is blocked unless field exists in the schema map remediating SOQL injection risks.
            if (!parentType.getDescribe().fields.getMap().containsKey(field)) {
                throw clientError('Setup-Error', 'TLN-301', System.Label.Timeline_Error_InvalidParentField);
            }

            String queryParentId = 'SELECT Id, ' + field + ' FROM ' + parentObjectType + ' Where Id =:recordId';

            List<SObject> newDefaultRecord = Database.query(queryParentId); //NOPMD

            Schema.DescribeSObjectResult describeSobjects = ((SObject) (Type.forName('Schema.' + parentObjectType)
                    .newInstance()))
                .getSObjectType()
                .getDescribe(SObjectDescribeOptions.DEFERRED);

            String fieldLabel = String.valueOf(describeSobjects.fields.getMap().get(field).getDescribe().getLabel());

            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, newDefaultRecord);

            Set<String> strippedFields = securityDecision.getRemovedFields().get(parentObjectType);

            if (strippedFields != null && strippedFields.contains(field)) {
                throw new TimelineSetupException(
                    JSON.serialize(
                        new Map<String, String>{
                            'type' => 'No-Access',
                            'message' => String.format(
                                System.Label.Timeline_Error_NoFieldAccess,
                                new List<String>{ fieldLabel }
                            )
                        }
                    )
                );
            }

            SObject secureObject = securityDecision.getRecords()[0];

            fieldValue = String.valueOf(secureObject.get(field));

            if (fieldValue == null || fieldValue == '') {
                throw new TimelineSetupException(
                    JSON.serialize(
                        new Map<String, String>{
                            'type' => 'No-Data',
                            'message' => String.format(
                                System.Label.Timeline_Error_NoFieldValue,
                                new List<String>{ fieldLabel }
                            )
                        }
                    )
                );
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

    /**
     * @description Validates that a CMDT-sourced field API name is safe for use in dynamic SOQL.
     * Simple fields are verified against the object's schema field map.
     * Dot-notation paths are pattern-checked and the root relationship is verified.
     * @param fieldApiName The field API name from Timeline_Configuration__mdt
     * @param fieldsMap The fields map from the target SObject describe
     * @return True if the field name is valid and safe for SOQL use
     */
    private static Boolean isValidFieldForSoql(String fieldApiName, Map<String, Schema.SObjectField> fieldsMap) {
        if (String.isBlank(fieldApiName)) {
            return false;
        }
        if (!Pattern.matches('[a-zA-Z_][a-zA-Z0-9_]*(\\.[a-zA-Z_][a-zA-Z0-9_]*)*', fieldApiName)) {
            return false;
        }
        if (!fieldApiName.contains('.')) {
            return fieldsMap.containsKey(fieldApiName);
        }
        String rootSegment = fieldApiName.substringBefore('.');
        for (Schema.SObjectField fieldRef : fieldsMap.values()) {
            Schema.DescribeFieldResult fd = fieldRef.getDescribe();
            if (fd.getRelationshipName() != null && fd.getRelationshipName().equalsIgnoreCase(rootSegment)) {
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
        private String iconField;
        private String iconBackgroundField;
        private String positionDateField;
        private String positionDateValue;
        private String positionDateType;
        private String objectName;
        private String objectLabel;
        private String type;
        private String tooltipIdField;
        private String tooltipObject;
        private String drilldownIdField;
        private String fallbackTooltipField;
        private String fallbackTooltipValue;
        private String fallbackNameField;
        private String fallbackNameValue;
        private String inclusionField;
        private String alternateDetailId;
        private String developerName;
        private Id recordId;
    }

    private class FieldMetadata { //NOPMD
        private Boolean canAccess;
        private String label;
    }

    private class FieldPath {
        public String[] parts;
        public String fieldName;
        public String fieldStripped;
        public Boolean isValid = false;

        public FieldPath(String field) {
            if (field != null && field != '') {
                this.fieldName = field;
                this.parts = field.split('\\.');
                if (this.parts.size() > 1) {
                    this.fieldStripped = this.parts[this.parts.size() - 1];
                } else {
                    this.fieldStripped = field;
                }
                this.isValid = true;
            }
        }
    }

    private class TimelineSetupException extends Exception {
    }
}
