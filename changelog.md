# Change Log

## XX xxX 2021 v1.9.0

**WHAT'S NEW**
-   Added support for 4,6,7,8,9 and 10 year future and historical time range values
-   Tweaked layouts to remove unnecessary DOM elements
-   Changed Salesforce API to v52.0 from v51.0

**BUG FIXES**
-   Fixed bug causing missing Tasks and Events when using fields with data type Large Text Area in Timeline_Configuration__mdt
-   Fixed bug causing records to be plotted in UTC date time instead of the users timezone

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
