# GTM Template Deployment

Automated deployment of `.tpl` files to GTM via the Tag Manager API, triggered on push to `main`. Two options are documented — choose based on your infrastructure.

---

## How It Works (Both Options)

```
push to main (dist/*.tpl changed)
  → GitHub Actions detects changed files in dist/
  → authenticates with GTM API (differs per option)
  → calls templates.update for each changed .tpl
  → creates a GitHub Release as the "update available" signal
  → GTM workspace now has updated templates, ready to publish

Note: dist/ is generated output. Run `npm run build` locally before pushing to ensure
dist/ reflects the latest changes from src/.
```

The GitHub Release replaces the GTM Community Gallery "Update Available" banner. Team members watching the repo receive a GitHub notification email when a release is created. A GTM user then opens the workspace, reviews, and publishes.

---

## Common Prerequisites

### 1. Locate Your GTM IDs

You will need four IDs from GTM. The easiest way to find them is from the GTM container URL:

```
https://tagmanager.google.com/#/container/accounts/123456789/containers/987654321/workspaces/10
                                                   ↑ accountId              ↑ containerId      ↑ workspaceId
```

To find the **Template ID** for each template:
- GTM → Templates → click a template → note the ID in the URL, or call `GET accounts/{accountId}/containers/{containerId}/workspaces/{workspaceId}/templates` and match by `name`.

Record these four values — they are used in both options:

| Variable | Where to find it |
|---|---|
| `GTM_ACCOUNT_ID` | GTM URL or API |
| `GTM_CONTAINER_ID` | GTM URL or API |
| `GTM_WORKSPACE_ID` | GTM URL or API |
| `GTM_TEMPLATE_ID_{NAME}` | GTM URL or API (one per template) |

### 2. Map Templates to IDs

Each `.tpl` file needs to be mapped to its GTM Template ID. Maintain this mapping in your GitHub Actions workflow environment (or as repository variables):

| File | GitHub Actions Variable |
|---|---|
| `dist/hightouch-track.tpl` | `GTM_TEMPLATE_ID_TRACK` |
| `dist/hightouch-pageview.tpl` | `GTM_TEMPLATE_ID_PAGEVIEW` |
| `dist/hightouch-identify.tpl` | `GTM_TEMPLATE_ID_IDENTIFY` |
| `dist/generic-js-tag.tpl` | `GTM_TEMPLATE_ID_GENERIC` |

### 3. GTM API Endpoint

All updates use the same endpoint shape:

```
PUT https://www.googleapis.com/tagmanager/v2/accounts/{accountId}/containers/{containerId}/workspaces/{workspaceId}/dist/{templateId}
```

Request body:
```json
{
  "templateData": "<raw contents of the .tpl file>",
  "fingerprint": "<current fingerprint from a prior GET — required to prevent conflicts>"
}
```

The `fingerprint` value must match the template's current state in GTM. Always do a `GET` first to retrieve the current fingerprint, then include it in the `PUT`.

---

## Option A — GCP Service Account

**Best for**: Teams comfortable with GCP, or where a GCP project already exists elsewhere in the org.

### Setup Steps

#### 1. Create a GCP Project (if none exists)

A free-tier GCP project is sufficient — no paid services are used.

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (e.g. `gametime-gtm-deploy`)
3. Note the **Project ID**

#### 2. Enable the Tag Manager API

In the GCP project:

1. Navigate to **APIs & Services → Library**
2. Search for **Tag Manager API**
3. Click **Enable**

#### 3. Create a Service Account

1. Navigate to **IAM & Admin → Service Accounts**
2. Click **Create Service Account**
   - Name: `gtm-deployer`
   - Description: `GitHub Actions deployment of GTM templates`
3. Skip the optional role grants at the GCP level — GTM uses its own permission system
4. Click **Done**
5. Open the service account → **Keys → Add Key → Create new key → JSON**
6. Download the JSON key file — this is stored as a GitHub Actions secret

#### 4. Grant the Service Account GTM Access

The service account needs access inside GTM itself (GCP IAM roles do not cover this).

1. In GTM, go to **Admin → Container → User Management**
2. Add the service account's email address (format: `gtm-deployer@your-project.iam.gserviceaccount.com`)
3. Grant **Edit** permission on the container

#### 5. Store Secrets in GitHub

Navigate to the repo → **Settings → Secrets and variables → Actions**:

| Secret name | Value |
|---|---|
| `GCP_SERVICE_ACCOUNT_KEY` | Full contents of the downloaded JSON key file |
| `GTM_ACCOUNT_ID` | Your GTM account ID |
| `GTM_CONTAINER_ID` | Your GTM container ID |
| `GTM_WORKSPACE_ID` | Your GTM workspace ID |
| `GTM_TEMPLATE_ID_TRACK` | Template ID for hightouch-track |
| `GTM_TEMPLATE_ID_PAGEVIEW` | Template ID for hightouch-pageview |
| `GTM_TEMPLATE_ID_IDENTIFY` | Template ID for hightouch-identify |
| `GTM_TEMPLATE_ID_GENERIC` | Template ID for generic-js-tag |

#### 6. GitHub Actions Workflow

Create `.github/workflows/deploy-gtm-templates.yml`:

```yaml
name: Deploy GTM Templates

on:
  push:
    branches: [main]
    paths:
      - 'dist/*.tpl'

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Authenticate with Google
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SERVICE_ACCOUNT_KEY }}

      - name: Get access token
        id: token
        run: |
          TOKEN=$(gcloud auth print-access-token)
          echo "access_token=$TOKEN" >> $GITHUB_OUTPUT

      - name: Update changed templates
        env:
          ACCESS_TOKEN: ${{ steps.token.outputs.access_token }}
          ACCOUNT_ID: ${{ secrets.GTM_ACCOUNT_ID }}
          CONTAINER_ID: ${{ secrets.GTM_CONTAINER_ID }}
          WORKSPACE_ID: ${{ secrets.GTM_WORKSPACE_ID }}
        run: |
          # Map file names to template IDs
          declare -A TEMPLATE_IDS=(
            ["dist/hightouch-track.tpl"]="${{ secrets.GTM_TEMPLATE_ID_TRACK }}"
            ["dist/hightouch-pageview.tpl"]="${{ secrets.GTM_TEMPLATE_ID_PAGEVIEW }}"
            ["dist/hightouch-identify.tpl"]="${{ secrets.GTM_TEMPLATE_ID_IDENTIFY }}"
            ["dist/generic-js-tag.tpl"]="${{ secrets.GTM_TEMPLATE_ID_GENERIC }}"
          )

          BASE="https://www.googleapis.com/tagmanager/v2/accounts/${ACCOUNT_ID}/containers/${CONTAINER_ID}/workspaces/${WORKSPACE_ID}/templates"

          for FILE in dist/*.tpl; do
            TEMPLATE_ID="${TEMPLATE_IDS[$FILE]}"
            if [ -z "$TEMPLATE_ID" ]; then continue; fi

            # Fetch current fingerprint
            FINGERPRINT=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
              "${BASE}/${TEMPLATE_ID}" | jq -r '.fingerprint')

            # Push updated template
            TPL_CONTENT=$(cat "$FILE")
            curl -s -X PUT "${BASE}/${TEMPLATE_ID}" \
              -H "Authorization: Bearer $ACCESS_TOKEN" \
              -H "Content-Type: application/json" \
              -d "{\"templateData\": $(echo "$TPL_CONTENT" | jq -Rs .), \"fingerprint\": \"$FINGERPRINT\"}"

            echo "Updated $FILE"
          done

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: "deploy-${{ github.run_number }}"
          name: "GTM Template Update #${{ github.run_number }}"
          body: |
            Templates updated in GTM workspace.
            Commit: ${{ github.sha }}
            Review and publish in GTM to make changes live.
          generate_release_notes: true
```

---

## Option B — Google Apps Script (no GCP required)

**Best for**: Teams without GCP, or who want to avoid managing service account credentials entirely. Uses the OAuth of a Google account that already has GTM access.

### How It Works

A Google Apps Script project is deployed as a Web App. GitHub Actions calls it via a webhook. The Apps Script fetches the updated `.tpl` files from GitHub and pushes them to the GTM API using its own built-in OAuth — no GCP, no service account, no client credentials.

### Setup Steps

#### 1. Create the Apps Script Project

1. Go to [script.google.com](https://script.google.com) and create a **New project**
2. Name it `GTM Template Deployer`
3. Sign in as the Google account that has GTM Edit access

#### 2. Configure OAuth Scopes

Replace the contents of `appsscript.json` (enable **View → Show manifest file** in the editor):

```json
{
  "timeZone": "America/Los_Angeles",
  "dependencies": {},
  "exceptionLogging": "STACKDRIVER",
  "runtimeVersion": "V8",
  "oauthScopes": [
    "https://www.googleapis.com/auth/tagmanager.edit.containers",
    "https://www.googleapis.com/auth/script.external_request"
  ]
}
```

#### 3. Write the Deployment Script

In `Code.gs`:

```javascript
var CONFIG = {
  accountId:   PropertiesService.getScriptProperties().getProperty('GTM_ACCOUNT_ID'),
  containerId: PropertiesService.getScriptProperties().getProperty('GTM_CONTAINER_ID'),
  workspaceId: PropertiesService.getScriptProperties().getProperty('GTM_WORKSPACE_ID'),
  githubToken: PropertiesService.getScriptProperties().getProperty('GITHUB_TOKEN'),
  webhookSecret: PropertiesService.getScriptProperties().getProperty('WEBHOOK_SECRET'),
  templateIds: {
    'dist/hightouch-track.tpl':    PropertiesService.getScriptProperties().getProperty('GTM_TEMPLATE_ID_TRACK'),
    'dist/hightouch-pageview.tpl': PropertiesService.getScriptProperties().getProperty('GTM_TEMPLATE_ID_PAGEVIEW'),
    'dist/hightouch-identify.tpl': PropertiesService.getScriptProperties().getProperty('GTM_TEMPLATE_ID_IDENTIFY'),
    'dist/generic-js-tag.tpl':     PropertiesService.getScriptProperties().getProperty('GTM_TEMPLATE_ID_GENERIC')
  }
};

function doPost(e) {
  var payload = JSON.parse(e.postData.contents);

  // Validate shared secret
  if (payload.secret !== CONFIG.webhookSecret) {
    return ContentService.createTextOutput('Unauthorized').setMimeType(ContentService.MimeType.TEXT);
  }

  var base = 'https://www.googleapis.com/tagmanager/v2/accounts/' + CONFIG.accountId +
             '/containers/' + CONFIG.containerId +
             '/workspaces/' + CONFIG.workspaceId + '/dist/';
  var token = ScriptApp.getOAuthToken();
  var results = [];

  for (var filePath in CONFIG.templateIds) {
    var templateId = CONFIG.templateIds[filePath];
    if (!templateId) continue;

    // Fetch .tpl content from GitHub
    var githubUrl = 'https://api.github.com/repos/gametimesf/gtm-hightouch/contents/' + filePath;
    var ghResponse = UrlFetchApp.fetch(githubUrl, {
      headers: { 'Authorization': 'token ' + CONFIG.githubToken, 'Accept': 'application/vnd.github.raw' }
    });
    var tplContent = ghResponse.getContentText();

    // Get current fingerprint
    var current = JSON.parse(UrlFetchApp.fetch(base + templateId, {
      headers: { 'Authorization': 'Bearer ' + token }
    }).getContentText());

    // Push update
    UrlFetchApp.fetch(base + templateId, {
      method: 'put',
      headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
      payload: JSON.stringify({ templateData: tplContent, fingerprint: current.fingerprint })
    });

    results.push(filePath + ' updated');
  }

  return ContentService.createTextOutput(results.join('\n')).setMimeType(ContentService.MimeType.TEXT);
}
```

#### 4. Set Script Properties

In the Apps Script editor: **Project Settings → Script Properties → Add property**:

| Property | Value |
|---|---|
| `GTM_ACCOUNT_ID` | Your GTM account ID |
| `GTM_CONTAINER_ID` | Your GTM container ID |
| `GTM_WORKSPACE_ID` | Your GTM workspace ID |
| `GTM_TEMPLATE_ID_TRACK` | Template ID for hightouch-track |
| `GTM_TEMPLATE_ID_PAGEVIEW` | Template ID for hightouch-pageview |
| `GTM_TEMPLATE_ID_IDENTIFY` | Template ID for hightouch-identify |
| `GTM_TEMPLATE_ID_GENERIC` | Template ID for generic-js-tag |
| `GITHUB_TOKEN` | Fine-grained GitHub PAT (read-only, Contents scope on this repo) |
| `WEBHOOK_SECRET` | A randomly generated secret string shared with GitHub Actions |

#### 5. Deploy as Web App

1. In Apps Script: **Deploy → New deployment → Web app**
2. Execute as: **Me**
3. Who has access: **Anyone** (the shared `WEBHOOK_SECRET` is the auth layer)
4. Click **Deploy** → copy the **Web App URL**

#### 6. Store Secrets in GitHub

Navigate to the repo → **Settings → Secrets and variables → Actions**:

| Secret name | Value |
|---|---|
| `APPS_SCRIPT_WEBHOOK_URL` | The Web App URL from step 5 |
| `APPS_SCRIPT_WEBHOOK_SECRET` | The same secret set in Script Properties |

#### 7. GitHub Actions Workflow

Create `.github/workflows/deploy-gtm-templates.yml`:

```yaml
name: Deploy GTM Templates

on:
  push:
    branches: [main]
    paths:
      - 'dist/*.tpl'

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Trigger Apps Script deployment
        run: |
          curl -s -L -X POST "${{ secrets.APPS_SCRIPT_WEBHOOK_URL }}" \
            -H "Content-Type: application/json" \
            -d '{"secret": "${{ secrets.APPS_SCRIPT_WEBHOOK_SECRET }}"}'

      - uses: actions/checkout@v4

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: "deploy-${{ github.run_number }}"
          name: "GTM Template Update #${{ github.run_number }}"
          body: |
            Templates updated in GTM workspace.
            Commit: ${{ github.sha }}
            Review and publish in GTM to make changes live.
          generate_release_notes: true
```

---

## Comparison

| | Option A (GCP) | Option B (Apps Script) |
|---|---|---|
| GCP required | Yes (free tier only) | No |
| Credentials managed in | GitHub Actions secrets | Apps Script Script Properties |
| OAuth handled by | GCP service account | Google account running the script |
| GTM permission grant | Add service account email in GTM | Already has access (your Google account) |
| Setup complexity | Medium | Medium |
| Ongoing maintenance | Rotate JSON key when it expires | Refresh OAuth when token scope changes |
| Failure visibility | GitHub Actions logs | Apps Script execution log |

---

## GitHub Release as Update Notification

Both options create a GitHub Release on every deploy. To receive email notifications:

1. Go to the repo on GitHub
2. Click **Watch → Custom → check Releases → Apply**

Every deploy creates a release with the commit SHA and a changelog generated from commit messages. This is the signal to open GTM, review the workspace changes, and publish.

---

## After Deployment

Templates are updated in the **workspace** — they are not live until published.

1. Open GTM → the workspace will show pending changes
2. Review the updated templates (Templates section)
3. Run **Preview** to validate in Tag Assistant
4. Click **Submit → Publish** to make changes live
