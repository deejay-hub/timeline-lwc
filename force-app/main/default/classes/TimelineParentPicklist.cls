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
        try {
            if (this.context.entityName != null) {
                List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(
                    new List<String>{ this.context.entityName }
                );
                String objectLabel = describes[0].getLabel();
                return new VisualEditor.DataRow('Use This ' + objectLabel, 'Default_Picklist_Value');
            }
        } catch (Exception e) {
            //NOPMD
            // Suppress error and return fallback value
        }

        return new VisualEditor.DataRow('Use Current Record', 'Default_Picklist_Value');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();

        try {
            myValues.addRow(getDefaultValue());

            if (this.context.entityName != null && this.context.pageType != 'CommRecordPage') {
                List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(
                    new List<String>{ this.context.entityName }
                );
                Schema.DescribeSObjectResult describeSobjects = describes[0];

                Map<String, Schema.SObjectField> myFields = describeSobjects.fields.getMap();

                for (Schema.SObjectField field : myFields.values()) {
                    Schema.DescribeFieldResult currentField = field.getDescribe();

                    List<Schema.SObjectType> referenceTo = currentField.getReferenceTo();

                    // Skip non-reference fields immediately
                    if (referenceTo.isEmpty()) {
                        continue;
                    }

                    if (
                        currentField.isAccessible() &&
                        currentField.isNamePointing() == false &&
                        currentField.getLabel() != 'Master Record ID'
                    ) {
                        myValues.addRow(new VisualEditor.DataRow(currentField.getName(), currentField.getName()));
                    }
                }
            }
        } catch (Exception e) {
            //NOPMD
            //Suppress error
        }

        return myValues;
    }
}
