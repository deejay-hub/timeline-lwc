# Timeline

A complete custom experience component. Created to allow users to view related records to a parent on an interactive timeline written with D3.js. Demonstrates a working example of
- Loading third party js libraries (D3.js and moment.js)
- Imperative Apex callout
- Optimising server side resources with fewest db calls and one response
- Use of the UI API via LDS to display tooltips - with fallback for unsupported objects
- Use of locale to display dates in the format specified under a users settings
- Use of custom labels to support multiple languages
- Reducing DOM elements to a minimum

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

### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-lwc) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.
