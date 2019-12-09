<h1 align="center">
	<img
	width="50"
	src="/force-app/main/default/lwc/timeline/timeline.svg"></br>
	Timeline<br>     
</h1>

<h4 align="center">
	<a href="#overview">Overview</a> |
	<a href="#installation-instructions">Install Me</a> |
	<a href="#how-it-works">How it Works</a> |
	<a href="#faqs">FAQs</a> |
	<a href="#contributing">Contribute</a>
</h4>
	
<h3 align="center">
	An interactive Lightning Web Component for the Salesforce platform<br><br>
	<a>
    		<img alt="forks on github"
		src="https://img.shields.io/github/forks/deejay-hub/timeline-lwc?style=flat-square&logoColor=blue">
  	</a>
  	<a>
    		<img alt="stars on github"
		src="https://img.shields.io/github/stars/deejay-hub/timeline-lwc?style=flat-square">
  	</a>
  	<a>
    		<img alt="downloads on github"
		src="https://img.shields.io/github/downloads/deejay-hub/timeline-lwc/total?style=flat-square">
  	</a>
  	<a>
    		<img alt="downloads on github"
		src="https://img.shields.io/bitbucket/issues/deejay/timeline-lwc?label=open%20issues&style=flat-square">
  	</a>
</h3>

<p align="center">
  <img alt="timeline demo" src="images/heroDemo.gif">
</p>


## Overview
A complete custom experience component. Created to allow users to view related records to a parent on an interactive timeline written with D3.js.

- **Multi Object Support.** Plot related records to Lead, Account, Contact, Opportunity and Case.
- **Multi Language Support.** All labels and error messages as translatable custom labels.
- **Locale Support for Dates.** Date formats change based on your Salesforce locale setting.
- **3rd Party JS.** Demonstrates 3rd Party JS and Apex imperative callouts to populate data in an interactive timeline.
- **Responsive interface.** Uses flexiPageInfo to determine where in the page it is located.
- **Minimises server roundtrips.** Uses Lightning Data Service for tooltips and falls back to queried data when needed.

> This sample application is designed to run on Salesforce Platform. If you want to experience Lightning Web Components on any platform, please visit https://lwc.dev, and try out the Lightning Web Components sample application [LWC Recipes OSS](https://github.com/trailheadapps/lwc-recipes-oss).

## Installation Instructions

1. Set up your environment. Follow the steps in the [Quick Start: Lightning Web Components](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/) Trailhead project. The steps include:

-   Enable Dev Hub in your Trailhead Playground
-   Install Salesforce CLI
-   Install Visual Studio Code
-   Install the Visual Studio Code Salesforce extensions, including the Lightning Web Components extension

2. If you haven't already done so, authenticate with your hub org and provide it with an alias (**myhuborg** in the command below):

```
sfdx force:auth:web:login -d -a myhuborg
```

3. Clone the timeline-lwc repository:

```
git clone https://github.com/deejay-hub/timeline-lwc
cd timeline-lwc
```

4. Create a scratch org and provide it with an alias (**timeline-lwc** in the command below):

```
sfdx force:org:create -s -f config/project-scratch-def.json -a timeline-lwc
```

5. Push the app to your scratch org:

```
sfdx force:source:push
```

6. Load sample data:

```
sfdx force:data:tree:import --plan data/timeline-plan.json
```

7. Open the scratch org:

```
sfdx force:org:open
```

8. Navigate to **Sales**, under **App Launcher**, select the **Sales** app.

9. Find the contact **Jane Lo** and drill into her detailed information.

10. Navigate to **Setup**, and select Edit Page

11. Drag the timeline component into the page - found under custom components

<p align="center">
  <img alt="timeline app builder" src="images/appBuilderDemo.gif">
</p>

## How it Works

#### Object Support
Timeline is installed as a custom component available in the App Builder component pallette. Currently the component is available on the following record home pages:
- Account
- Contact
- Lead
- Opportunity
- Case

This is a configuration limit specified in timeline.js-meta.xml. Since the timeline is designed to be driven from data it should be possible to extend the usage to other objects.

```
<targetConfig targets="lightning__RecordPage">
     <objects>
        <object>Contact</object>
        <object>Lead</object>
        <object>Account</object>
        <object>Case</object>
        <object>Opportunity</object>
     </objects>
</targetConfig>
```

#### Component Properties
The component has the following properties that can be set at design time in App Builder by an administrator

Attribute                        | Description                        | Validation       
---------------------------------| -----------------------------------| ---------------------------
Title	                         | Adjusts the label                  | String
Height                           | Adjusts the vertical height        | Picklist (1 - 5)
Historical Time Range (Years)	 | Adjusts the start date	      | Picklist (0.25 - 5)
Future Time Range (Years)	 | Adjusts the end date		      | Picklist (0.25 - 1)
Zoom Based On			 | Adjusts the position of the zoom   | Picklist (Current Date, Last Activity)
Zoom Range (Days)		 | Adjusts the extent of the zoom     | Integer min 15 max 120

#### Custom Labels
Labels can be translated where appropriate. Navigate to Setup -> Custom Labels and add translations for your chosen languages. Note you will need the permission - Manage Transalations.

Label Name                       	 | Default translation                     
---------------------------------------	 | -----------------------------------
Timeline_Error_Apex              	 | Apex error         
Timeline_Error_JavaScriptResources	 | Unable to load JavaScript resources
Timeline_Error_NoDataHeader	 	 | No data to display 
Timeline_Error_NoDataSubHeader   	 | Related records show up here on an interactive timeline. Check your filter or create a record. 
Timeline_Error_Unhandled	 	 | Houston...we've had a problem 
Timeline_Label_Days		 	 | day(s) 
Timeline_Label_Showing		  	 | Showing:

#### Configuring Child Records to Plot
Specifying which child records to plot is done using the Timeline_Configuration metadata type. I have included examples for Contact, Account and Case. Let's take an example - to plot Case Comments on the timeline for Cases I need a row as below:

<insert metadataImageDemo>

## FAQs

#### Does it support multiple languages other than English?
Yes. The users locale setting in Salesforce determines the date formats used. For a list of supported locales see - https://help.salesforce.com/articleView?id=admin_supported_date_time_format.htm&type=5

All fields have their translated labels returned. Any custom labels can be translated (see Custom Labels)

#### Does it support Communities?

#### Does it support Mobile?
No. The timeline component is really best suited to the desktop. Long term it is a goal to come up with a mobile version suited to reduced real estate. At the moment the component cannot be dragged into a mobile layout.

#### Does it support Person Accounts?

#### Does it support Files / Notes / Attachments)?
The goal is to support ContentDocumentLink. This will assume that you are using enhanced Notes and Files. The component does not support classic Attachments or Notes at this stage.

#### Does it support Custom Objects?

## Contributing

Contributions are what make the trailblazer community such an amazing place. I regard this component as a way to inspire and learn from others. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit your Changes (`git commit -m 'Add some NewFeature'`)
4. Push to the Branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

## Utilities and Dependencies

#### Dependencies
- D3.js v 5.7.0
- moment.js v2.2.4

#### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

#### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-lwc) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.
