const lwcRecommended = require('@salesforce/eslint-config-lwc/recommended');

module.exports = [
    {
        ignores: [
            '**/lwc/**/*.css',
            '**/lwc/**/*.html',
            '**/lwc/**/*.json',
            '**/lwc/**/*.svg',
            '**/lwc/**/*.xml',
            '.sfdx',
        ],
    },
    ...lwcRecommended,
    {
        files: ['force-app/main/default/lwc/**/*.js'],
        languageOptions: {
            globals: {
                moment: 'readonly',
                d3: 'readonly',
            },
        },
        rules: {
            'no-console': 'off',
        },
    },
];

