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
    {
        files: ['**/__tests__/**/*.js'],
        rules: {
            'no-undef': 'off', // Allow 'require' which might be flagged if not in globals
        },
        languageOptions: {
            globals: {
                require: 'readonly',
                jest: 'readonly',
                describe: 'readonly',
                it: 'readonly',
                expect: 'readonly',
                beforeEach: 'readonly',
                afterEach: 'readonly',
            },
        },
    },
];
