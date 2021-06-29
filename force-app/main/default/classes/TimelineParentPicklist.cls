/**
 * @description Supporting Apex to get all supported parent object fields for the Timeline Lightning Web Component
 * This allows the component to plot for different fields and contexts (e.g. shows the Contact timeline on a Case)
 */
global with sharing class TimelineParentPicklist extends VisualEditor.DynamicPickList { //NOPMD
    VisualEditor.DesignTimePageContext context;

    /**
     * @description Apex class constructot passing context from the Lightning Web Component
     * @param context The DesignTimePageContext to get Entity Name and Page Type
     */
    global TimelineParentPicklist(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        if (this.context.entityName != null) {
            String objectLabel = ((SObject) (Type.forName('Schema.' + String.valueOf(this.context.entityName))
                    .newInstance()))
                .getSObjectType()
                .getDescribe()
                .getLabel();
            VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(
                'Use This ' + objectLabel,
                'Default_Picklist_Value'
            );
            return defaultValue;
        }

        VisualEditor.DataRow blankValue = new VisualEditor.DataRow('Use Current Record', 'Default_Picklist_Value');
        return blankValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
        myValues.addRow(getDefaultValue());

        if (this.context.entityName != null && this.context.pageType != 'CommRecordPage') {
            Schema.DescribeSObjectResult describeSobjects = ((SObject) (Type.forName(
                        'Schema.' + this.context.entityName
                    )
                    .newInstance()))
                .getSObjectType()
                .getDescribe(SObjectDescribeOptions.DEFERRED);

            Map<String, Schema.SObjectField> myFields = describeSobjects.fields.getMap();

            for (String field : myFields.keySet()) {
                Schema.DescribeFieldResult currentField = myFields.get(field).getDescribe();

                if (
                    currentField.isAccessible() &&
                    currentField.isNamePointing() == false &&
                    currentField.getLabel() != 'Master Record ID' &&
                    (String.valueOf(currentField.getReferenceTo()) != '' &&
                    String.valueOf(currentField.getReferenceTo()) != null &&
                    String.valueOf(currentField.getReferenceTo()) != '()' &&
                    String.valueOf(currentField.getReferenceTo()) != '(User)')
                ) {
                    myValues.addRow(new VisualEditor.DataRow(currentField.getLabel(), field));
                }
            }
            return myValues;
        } else {
            return myValues;
        }
    }
}
