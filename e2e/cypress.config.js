const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    // Base URL for your Flutter Web app
    // Default: http://localhost:5000
    // To change port, update this value or set CYPRESS_BASE_URL environment variable
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost:5000',
    
    // Viewport settings for web testing
    viewportWidth: 1280,
    viewportHeight: 720,
    
    // Test timeout
    defaultCommandTimeout: 30000,
    pageLoadTimeout: 90000,
    
    // Setup node events
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    
    // Spec pattern for test files
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    
    // Support file location
    supportFile: 'cypress/support/e2e.js',
  },
});

