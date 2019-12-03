<h1 align="center">
	<img
	width="50"
	src="/force-app/main/default/lwc/timeline/timeline.svg"></br>
	Timeline<br>     
</h1>

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
  <img alt="timeline demo" src="images/Demo.gif">
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

## How it Works

#### Object Support
Timeline is installed as a custom component available in the App Builder component pallette. Currently the component is available on the following record home pages:
Account
Contact
Lead
Opportunity
Case

Just drag the component onto the page.

<gif drag)

#### Component Attributes
The component has the following attributes that can be set at design time in App Builder

Attribute                        | Description
---------------------------------| -------------
Title	                         | Controls the label that appears in the top left of the components
Height                           | Controls the vertical height of the component
Historical Time Range (Years)	 | How far back in time do you need to plot records?
Future Time Range (Years)	 | How far into the future do you need to see records?
Zoom Based On			 | Always zoom to the current date (even if there are no records) or zoom to the last activity
Zoom Range (Days)		 | How many days to show by default

#### Custom Labels


## Contributing

Contributions are what make the trailblazer community such an amazing place. I regard this component as a way to inspire and learn from others. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit your Changes (`git commit -m 'Add some NewFeature'`)
4. Push to the Branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-lwc) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.
