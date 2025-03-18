<div align="center">
	<img
	width="50"
	src="/force-app/main/default/lwc/timeline/timeline.svg">
	<h1>Time Warp</h1>
</div>

<h4 align="center">
	<a href="#overview">Overview</a> |
	<a href="#installation-instructions">Install Me</a> |
	<a href="#how-it-works">How it Works</a> |
	<a href="#faqs">FAQs</a> |
	<a href="#contributing">Contribute</a>
</h4>
	
<h3 align="center">
	An interactive Lightning Web Component for the Salesforce platform<br><br>
	<a href="https://github.com/deejay-hub/timeline-lwc/network/members">
    		<img alt="forks on github"
		src="https://img.shields.io/github/forks/deejay-hub/timeline-lwc?style=flat-square&logoColor=blue">
  	</a>
  	<a href="https://github.com/deejay-hub/timeline-lwc/stargazers">
    		<img alt="stars on github"
		src="https://img.shields.io/github/stars/deejay-hub/timeline-lwc?style=flat-square">
  	</a>
  	<a href="https://github.com/deejay-hub/timeline-lwc/watchers">
    		<img alt="watchers"
		src="https://img.shields.io/github/watchers/deejay-hub/timeline-lwc?style=flat-square">
  	</a>
  	<a href="https://github.com/deejay-hub/timeline-lwc/issues">
    		<img alt="issues"
		src="https://img.shields.io/github/issues-raw/deejay-hub/timeline-lwc?style=flat-square">
  	</a>
	<a href="https://www.codacy.com/manual/deejay-hub/timeline-lwc?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=deejay-hub/timeline-lwc&amp;utm_campaign=Badge_Grade"><img src="https://app.codacy.com/project/badge/Grade/c03e8f3db45a46dc93a62d61a5a8108f"/>
	</a>
</h3>

<p align="center">
  <img alt="timeline demo" src="images/heroDemo.gif">
</p>

## Overview

A complete custom experience component. Created to allow users to view related records to a parent on an interactive timeline.

-   **Multi Object Support.** Plot related records to any parent object.
-   **Junction Object Support.** Plot junction object records and use simple dot notation.
-   **Multi Language Support.** All labels and error messages as translatable custom labels.
-   **Locale Support for Dates.** Date formats change based on your Salesforce locale setting.
-   **3rd Party JS.** Demonstrates 3rd Party JS and Apex imperative callouts to populate data in an interactive timeline.
-   **Responsive interface.** Uses flexipageRegionWidth to determine where in the page it is located.
-   **Minimises server roundtrips.** Uses Lightning Data Service for tooltips and falls back to queried data when needed.

> This sample application is designed to run on Salesforce Platform. If you want to experience Lightning Web Components on any platform, please visit https://lwc.dev, and try out the Lightning Web Components sample application [LWC Recipes OSS](https://github.com/trailheadapps/lwc-recipes-oss).

## Installation Instructions

Now available as a **free** managed package from the [AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000GXVf4UAH).

Alternatively you can install the component straight from source control into a Scratch Org using the instructions below:

1. Set up your environment. Follow the steps in the [Quick Start: Lightning Web Components](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/) Trailhead project. The steps include:

-   Enable Dev Hub in your Trailhead Playground
-   Install Salesforce CLI
-   Install Visual Studio Code
-   Install the Visual Studio Code Salesforce extensions, including the Lightning Web Components extension

2. If you haven't already done so, authenticate with your hub org and provide it with an alias (**myhuborg** in the command below):

```
sf org login web -d -a myhuborg
```

3. Clone the timeline-lwc repository:

```
gh repo clone https://github.com/deejay-hub/timeline-lwc
cd timeline-lwc
```

4. Overwrite the sfdx-project.json file with the following

```
{
    "packageDirectories": [
        {
            "path": "force-app",
            "default": true
        }
    ],
    "sfdcLoginUrl": "https://login.salesforce.com",
    "sourceApiVersion": "61.0"
}
```

5. Create a scratch org and provide it with an alias (**timewarp-lwc** in the command below):

```
sf org create scratch -d -f config/project-scratch-def.json -a timewarp-lwc -y 30
```

6. Push the app to your scratch org:

```
sf project deploy start
```

7. Assign the Timeline_User permission set to the default user:

```
sf org assign permset --name "Timeline_User" 
```

8. Load sample data:

```
sf data import tree --plan data/timeline-plan.json
```

9. Open the scratch org:

```
sf org open
```

10. Optional: Run npm install to support linting, prettification and test runs

```
npm install
```

11. Navigate to **Sales**, under **App Launcher**, select the **Sales** app.

12. Find the contact **Jane Lo** and drill into her detailed information.

13. Navigate to **Setup**, and select Edit Page

14. Drag the timeline component into the page - found under custom components

<p align="center">
  <img alt="timeline app builder" src="images/appBuilderDemo.gif">
</p>

## How it Works

For full details see the [Configuration Guide](https://quip.com/ahFCA9VBEKtr)

#### Object Support

Timeline is installed as a custom component available in the App Builder component pallette. The component is available on all standard and custom objects but has been designed specifically to see clusters of interactions over time.

#### Component Properties

The component has the following properties that can be set at design time in App Builder by an administrator

| Property                        | Description                      | Validation                             |
| ------------------------------- | -------------------------------- | -------------------------------------- |
| `Parent Record`                 | Adjusts the timeline parent id   | Dynamic Picklist (valid relationships) |
| `Title`                         | Adjusts the label                | String                                 |
| `Height`                        | Adjusts the vertical height      | Picklist (1 - 5)                       |
| `Icon Style`                    | Adjusts the iconography style    | Picklist (Square, Circular)            |
| `Historical Time Range (Years)` | Adjusts the start date           | Picklist (0.25 - 10)                   |
| `Future Time Range (Years)`     | Adjusts the end date             | Picklist (0.25 - 10)                   |
| `Zoom Based On`                 | Adjusts the position of the zoom | Picklist (First Date, Current Date, Last Activity) |
| `Zoom Range (Days)`             | Adjusts the extent of the zoom   | Integer min 15 max 365                 |
| `Show Today`                    | Plots a line for the current date/time   | Picklist (No/Various Colours)  |

#### Custom Labels

Labels can be translated where appropriate. Navigate to Setup -> Custom Labels and add translations for your chosen languages. Note you will need the permission - Manage Transalations.

| Label Name                           | Default translation                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------- |
| `Timeline_Error_Apex`                | Apex error                                                                                     |
| `Timeline_Error_Setup`               | Setup error                                                                                    |
| `Timeline_Error_JavaScriptResources` | Unable to load JavaScript resources                                                            |
| `Timeline_Error_NoDataHeader`        | No data to display                                                                             |
| `Timeline_Error_NoDataSubHeader`     | Related records show up here on an interactive timeline. Check your filter or create a record. |
| `Timeline_Error_ConsoleTab`          | Console tab conflict                                                                           |
| `Timeline_Error_ConsoleTabSubHeader` | Time Warp cannot load on a parent and child sub tab at the same time. Refresh Time Warp to view this timeline.  |
| `Timeline_Error_Unhandled`           | Houston...we've had a problem                                                                  |
| `Timeline_Label_Days`                | day(s)                                                                                         |
| `Timeline_Label_Items`               | item(s)                                                                                        |
| `Timeline_Label_Showing`             | Showing:                                                                                       |
| `Timeline_Label_Filters`             | Filters (Used in filter panel)                                                                 |
| `Timeline_Label_Filter_All_Types`    | All Types (Used in filter panel as select/deselect all checkbox)                               |
| `Timeline_Label_Filter_Type_Legend`  | Types to Show (Used in Filter panel)                                                           |
| `Timeline_Label_Files`               | Files & Notes (used in Filter when sObject is ContentDocumentLink)                             |
| `Timeline_Label_Date_Range_Legend`   | Date Range (Used in Filter panel)                                                              |
| `Timeline_Label_Apply`               | Label for apply button (Used in Filter panel)                                                  |
| `Timeline_Label_Cancel`              | Label for cancel button (Used in Filter panel)                                                 |
| `Timeline_Navigation_Toast_Header`   | Label used in Toast message header when drilling down on CaseComment                           |
| `Timeline_Navigation_Toast_Body`     | Label used in Toast message body when drilling down on CaseComment                             |

#### Configuring Child Records to Plot

Specifying which child records to plot is done using the **Timeline_Configuration_mdt** metadata type. When populating the metadata type the following is a description of the columns and their purpose

| Field Name                  | Description                                                                                                                      |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `Parent_Object__c`          | The API Name of the **parent object** that the child record relates to                                                           |
| `Object_Name__c`            | The API Name of the object that is the **child** to plot                                                                         |
| `Relationship_Name__c`      | The API Name of the **relationship** between Parent and Child                                                                    |
| `Position_Date_Field__c`    | The API Name of the field on the child (Object_Name\_\_c) to use as the date value to use to position the record on the timeline (must be Date or Date/Time)|
| `Detail_Field__c`           | The API Name of the field on the child (Object_Name\_\_c) to use as the description for the record to plot on the timeline       |
| `Inclusion_Field__c`        | The API Name of the field on the child (Object_Name\_\_c) that evaluates to true when a record should be included        	 |
| `Icon__c`                   | A relative url to the image to use for this record                                                                               |
| `Icon_Background_Colour__c` | The background colour to use for the above image (rgb and hex supported)                                                         |
| `Icon_Field__c`                   | The API Name of the formula field to dynamically get the image text                                                        |
| `Icon_Background_Colour_Field__c` | The API Name of the formula field to dynamically get the image background colour                                           |
| `Type_Field__c`             | Reserved for 'Tasks' only. Used to specify the field to distinguish Calls vs Emails. Only used when Object_Name\_\_c is Task     |
| `Fallback_Tooltip_Field__c` | The API Name of the field on the child object to use when the UI API does not support this object. Timeline will use the Detail_Field__c value and the Fallback_Tooltip_Field__c as the tooltip. |
| `Drilldown_Id_Field__c`     | The field containing the Id value that should be used for the drilldown operation. e.g. Which record should the user be navigated to. Important for junction objects. |
| `Tooltip_Id_Field__c`       | The field containing the Id value that should be used for the hover tooltip e.g. Which record should the user see when they hover over a record on the timeline. Important for junction objects. |
| `Tooltip_Object_Name__c`    | The object used by the tooltip. The label is also looked up to use in the filter panel.                                          |
| `Test__c`                   | Protected records used for _Apex testing only_.                                                                                  |

## FAQs

For FAQs and troubleshooting see the [Knowledge Base](https://quip.com/6yvoAcBukqZB)

#### How do I specify the fields for the tooltip?

Use the Compact Layout of the object plotted (for the most part).

#### Does it support multiple languages other than English?

Yes - Supports a users locale, language and has custom labels for translation available. Default translations are available for French, Spanish, Portuguese, Chinese (Simplified), Chinese (Traditional), Thai, German, Hebrew, Arabic and Hindi.

#### Does it support Communities?

Yes. The timeline will work on a record detail page in the community. Sadly we don't support changing Parent Field at this stage.

#### Does it support Mobile?

No. The timeline component is really best suited to the desktop. Long term it is a goal to come up with a mobile version suited to reduced real estate. At the moment the component cannot be dragged into a mobile layout.

#### Does it support Person Accounts?

Yes.

#### Does it support Files / Notes / Attachments?

Yes. Files and Notes (sometimes referred to as enhanced Notes) are supported. We have added any record in the ContentDocumentLink object.

#### Does it support External Objects / Big Objects?

No. We would have to consider scale and performance too so for now the component only supports standard and custom objects.

#### Does it support History Objects?

No. History objects are deliberately removed from the query. They don't make good candidates to plot on the timeline due to the volume of updates.

#### Does it support Junction Objects?

Yes.

## Contributing

Contributions are what make the trailblazer community such an amazing place. I regard this component as a way to inspire and learn from others. Any contributions you make are **greatly appreciated**.

See [contributing.md](/contributing.md) for timeline principles.

## Utilities and Dependencies

#### Dependencies

-   D3.js v 7.8.5

(moment.js v2.29.1) deprecated from v1.10.

#### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

#### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-lwc) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.

#### Code quality

[PMD](https://pmd.github.io/) is a cross-language static code analyser. To use PMD with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=chuckjonas.apex-pmd) from the Visual Studio Code Marketplace. The [.pmdruleset.xml](/.pmdruleset.xml) file is provided as part of this repository to exclude specific files and/or types of code quality checks from the process in the context of Lightning Web Components development.

#### Codacy

Codacy automates code reviews and monitors code quality over time. Static analysis, code coverage and metrics for JavaScript and Apex. Tests for common styling and security issues.
