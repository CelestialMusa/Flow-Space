# Cypress E2E Testing for Flutter Web

This directory contains end-to-end tests for the Flutter Web application using Cypress.

## Prerequisites

- Node.js and npm installed
- Flutter Web app running locally

## Setup

1. Install dependencies (already done):
   ```bash
   npm install
   ```

## Running Tests

### Step 1: Start Your Flutter Web App

Run your Flutter app with the web server:

```bash
flutter run -d web-server
```

**Important:** Note the localhost URL displayed in the terminal. It will look something like:
```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
...
Serving at http://localhost:5000
```

### Step 2: Update Base URL (if needed)

The default base URL is set to `http://localhost:5000` in `cypress.config.js`.

If your Flutter app is running on a different port:

**Option A:** Update `cypress.config.js`:
```javascript
baseUrl: 'http://localhost:YOUR_PORT',
```

**Option B:** Use environment variable:
```bash
CYPRESS_BASE_URL=http://localhost:YOUR_PORT npm run cypress:open
```

### Step 3: Run Cypress

**Interactive Mode (Recommended for development):**
```bash
npm run cypress:open
```

This opens the Cypress Test Runner where you can:
- Select and run individual tests
- See tests execute in real-time
- Debug tests interactively

**Headless Mode (for CI/CD):**
```bash
npm run cypress:run
```

This runs all tests in headless mode and outputs results to the terminal.

## Test Structure

- `cypress/e2e/` - Test files (`.cy.js`)
- `cypress/support/` - Support files and custom commands
- `cypress/fixtures/` - Test data fixtures

## Current Tests

### Smoke Test (`smoke.cy.js`)
- Verifies app loads successfully
- Checks login screen is accessible
- Validates interactive elements

## Configuration

The main configuration is in `cypress.config.js`:
- `baseUrl`: Base URL for your Flutter Web app (default: `http://localhost:5000`)
- `viewportWidth/Height`: Browser viewport size
- `defaultCommandTimeout`: Timeout for commands (10 seconds)

## Troubleshooting

### App not loading
- Ensure Flutter app is running: `flutter run -d web-server`
- Check the port matches `baseUrl` in `cypress.config.js`
- Verify the app is accessible in a regular browser

### Tests timing out
- Increase `defaultCommandTimeout` in `cypress.config.js`
- Add `cy.wait()` for Flutter app initialization (Flutter Web may take time to load)

### Selectors not found
- Flutter Web renders differently than React/Vue
- Use text-based selectors or data attributes
- Inspect the rendered HTML to find appropriate selectors
- Consider adding `data-testid` attributes in your Flutter app for better test reliability

## Adding New Tests

Create new test files in `cypress/e2e/` with the pattern `*.cy.js`:

```javascript
describe('Feature Name', () => {
  it('should do something', () => {
    cy.visit('/');
    // Your test code here
  });
});
```

## Flutter Web Considerations

Flutter Web apps:
- May take time to initialize (add appropriate waits)
- Render differently than traditional web apps
- Use shadow DOM for some components
- May require different selector strategies

## Resources

- [Cypress Documentation](https://docs.cypress.io/)
- [Cypress Best Practices](https://docs.cypress.io/guides/references/best-practices)
- [Flutter Web](https://docs.flutter.dev/platform-integration/web)

