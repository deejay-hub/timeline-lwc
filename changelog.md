# Change Log

## XX Xxx 2024 v1.15.0

**WHAT'S NEW**
-   Changed Salesforce API to v60.0 from v59.0
-   Added EmailMessage drilldown support for ActivityHistory and OpenActivities

**BUG FIXES**
-   Fixed memory leak issue
  
## 30 Jan 2024 v1.14.0

**WHAT'S NEW**
-   Changed Salesforce API to v59.0 from v58.0
-   Added the ability to plot today's date
-   Added the ability to change the colour used for today's date
-   Added the ability to use fields for icon and icon colour
-   Added default label translations for Danish.
-   d3.js updated to v7.8.5

**BUG FIXES**
-   Fixed WCAG colour schemes used in Winter '24
-   Fixed zero width issues in service console
-   Fixed title padding for right to left languages
-   Fixed timezone adjustments for date type fields

## 26 Jun 2023 v1.12.0

**WHAT'S NEW**
-   Changed Salesforce API to v58.0 from v54.0
-   Added default label translations for Swedish and Norweigan.
-   Added support for custom relationships on the Activity object
-   Added the ability to zoom to 'First Activity'
-   Added support for new conditional directives - lwc:if 
-   Added SLDS alignment for WCAG standards for colour contrast
-   Documentation improvements including sfdx to sf install instructions

**BUG FIXES**
-   Fixed bug with linting error for invalid sfdx-project.json
-   Fixed bug formatting dates for the Icelandic locale
-   Fixed bug causing border radii to overlap
-   Fixed bug causing scratch Org creation to fail with invalid sfdx-project.json
-   Fixed node module dependency versions for security

## 20 Jun 2022 v1.11.0

**WHAT'S NEW**
-   Changed Salesforce API to v54.0 from v53.0
-   Added default label translations for Italian and Korean.
-   Performance improvements using SObjectDescribeOptions.DEFERRED to enable lazy initialisation of describe attributes
-   Added default timeline metadata for Incident, Change Request and Problem standard objects
-   Days to Show now allows values up to 365. Allowing for rolling years.
-   Reduced Metadata Type usage by 35%.
-   d3.js updated to v7.4.4

**BUG FIXES**
-   Fixed bug when a null dates are found for OpenActivities and ActivityHistory relationship records causing a runtime error
-   Fixed bug causing ActivityHistory relationships to fail to load for non-admin users
-   Fixed bug causing Parent Picklist design time attribute to be null when an invalid field label is found
-   Fixed bug causing scratch Org creation to fail with invalid sfdx-project.json
-   Fixed bug causing tooltip to be hidden in the Service Cloud Console

## 15 Jan 2022 v1.10.0

**WHAT'S NEW**
-   Changed Salesforce API to v53.0 from v52.0
-   Added support for right-to-left languages. Hebrew, Yiddish, Arabic and Urdu.
-   Added default label translations for Hebrew and Arabic.
-   Modified x axis labels to use date formats based on the user locale
-   Added a loading spinner to the tooltip event to avoid blank screens during loading.
-   BEM notation with double dashes removed in CSS as it's being deprecated in Summer '22
-   Performance improvements removing moment.js as a dependency
-   Modified the tooltip nubbin when hovering on a record to remove border shading
-   Removed moment.js as a dependency and moved to standard JavaScript for date manipulation

**BUG FIXES**
-   Fixed bug when a custom field value is used in the Drilldown Id Field in the custom metadata causing an Apex exception
-   Fixed bug causing Time Warp dates to be null when Lightning Web Security is enabled
-   Fixed bug that assumed all users have access to all metadata objects for the component to load
-   Fixed bug causing ActivityHistory and OpenActivity relationships to fail to load for non-admin users
-   Fixed bug causing the border radius to be square and not round for the bottom left and right corners

## 26 Sep 2021 v1.9.0

**WHAT'S NEW**
-   Added support to filter child records using a boolean value from a nominated field 
-   Added support for 4, 6, 7, 8, 9 and 10 year future and historical time range values
-   Performance improvements by removing unnecessary DOM elements
-   Added the inclusion of Position Dates in the fallback tooltip for objects not supported by the UI API
-   d3.js updated to v7.0.0
-   moment.js updated to v2.29.1
-   Changed Salesforce API to v52.0 from v51.0

**BUG FIXES**
-   Fixed bug causing missing Tasks and Events when using fields with data type Large Text Area in Timeline_Configuration__mdt
-   Fixed bug causing records to be plotted in UTC date time instead of the users timezone
-   Fixed bug causing the label of the position date to be retrieved as a literal instead of the label of the field

## 21 May 2021 v1.8.0

**WHAT'S NEW**
-   Added support for 2, 3 and 5 year future time range values
-   Added support for WorkOrders on the Asset object by default
-   Added default translations for German, Spanish, French, Hindi, Japanese, Portuguese, Thai, Chinese (Simplified), Chinese (Traditional)
-   Added support for OpenActivity and ActivityHistory relationships to support indirect rollups of tasks and events
-   Changed Salesforce API to v51.0 from v50.0

**BUG FIXES**
-   Fixed bug causing error when adding Time Warp to Cases and using CaseComments
-   Fixed bug causing axis bars to be solid instead of dashed when flexipageRegionWidth is not set
-   Fixed bug causing test cases in a Scratch Org to fail when Last Modified By was not populated for the System Admin profile

## 27 Nov 2020 v1.5.0

-   Fixed bug causing error when custom relationship names were used in dot notations
-   Added support for all objects (standard and custom)
-   Added default related records for Asset, WorkOrder, Lead and Opportunity
-   Improved error handling when no matching records are found in the custom metadata
-   Improved help text for the custom metadata type
-   Added better documentation and included a Config Guide and Knowledge Base
-   Changed Salesforce API to v50.0 from v49.0

## 06 Oct 2020 v1.4.0

-   Fixed bug causing test to fail when Contact had been relabelled
-   Removed Work Order as a default record to plot
-   Fixed community support

## 25 Sep 2020 v1.2.0

-   Added support for Person Accounts
-   Added Parent Field property
-   Performance improvements
-   Fixed zoom handle transparency

## 06 Jan 2019 v1.0.0

-   Initial Release
-   Simple related list SOQL sub queries
-   Simple filter on SObject type
-   Support multi language, multi locale
