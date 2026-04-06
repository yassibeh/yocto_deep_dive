# Jenkins → GitHub status reporting diagnostic

## Status: RESOLVED

Jenkins now reports commit statuses to GitHub. The confirmed check context is:

```
continuous-integration/jenkins/branch
```

This is the exact value to use for branch protection required status checks.

## Resolution evidence

Commit `ec74dcf` (pushed 2026-04-06):
- `pending` status published at `2026-04-06T10:11:13Z`
- `error` status published at `2026-04-06T10:11:17Z` (build failed due to corrupted repo workspace, not a status reporting issue)
- Creator: `yassibeh` (authenticated)
- Target URL: `https://jenkins.behilil.com/job/yocto-deep-dive-ci/job/feature%252Fjenkins-containerized-st-yocto-build/9/display/redirect`

## Root causes that were fixed

1. **GitHub Server credential** (Manage Jenkins → System → GitHub): needed a "Secret text" credential with the PAT. Fixed first — enabled Test Connection but did not fix status publishing.

2. **Branch Sources credential** (yocto-deep-dive-ci → Configure → Branch Sources): needed a "Username with password" credential (username + PAT as password). Fixed second — enabled the plugin to attempt status publishing.

3. **PAT scope**: the PAT lacked `repo:status` permission. GitHub returned HTTP 403 "Resource not accessible by personal access token". Fixed third — status publishing now works.

## Previous evidence (pre-fix)

Tested commits:
- `91b2364` (pushed 2026-04-05): `statuses: []`, `check_runs: []`
- `049d9f0` (pushed 2026-04-06): `statuses: []`, `check_runs: []`

GitHub API queries used:
```bash
curl -s "https://api.github.com/repos/yassibeh/yocto_deep_dive/commits/<sha>/status"
curl -s "https://api.github.com/repos/yassibeh/yocto_deep_dive/commits/<sha>/check-runs"
```

The `state: pending` with `total_count: 0` is GitHub's default for any commit that has never received a status update. It does NOT mean Jenkins published a pending status.

## Known working

- Jenkins public URL: `https://jenkins.behilil.com/` (returns 403 for anonymous = accessible but auth-gated)
- Webhook endpoint: `https://jenkins.behilil.com/github-webhook/` (returns 405 for GET = correct, endpoint exists)
- Webhook push → Jenkins build trigger: previously proven working
- Multibranch pipeline `yocto-deep-dive-ci`: previously proven to discover `feature/jenkins-containerized-st-yocto-build`

## Root cause analysis

The earlier proven symptom was Jenkins console showing:
```
Connecting to https://api.github.com with no credentials, anonymous access
```

This means the GitHub Branch Source plugin (or GitHub plugin) is not picking up the API credential when making GitHub API calls.

## Exact verification checklist (Jenkins UI required)

### Step 1: Verify the credential exists in the global store

Navigate to: **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**

Verify this credential exists:
- **ID**: `github-yocto-deep-dive-jenkins-api`
- **Kind**: Username with password
- **Username**: your GitHub login (e.g., `yassibeh`)
- **Password**: a GitHub Personal Access Token with at minimum `repo:status` scope (full `repo` scope is safer)
- **Scope**: Global

If the credential is under your user profile instead of the global store, it will NOT be available to the GitHub plugin at the system level.

### Step 2: Verify the Jenkins GitHub server configuration

Navigate to: **Manage Jenkins → System → GitHub → GitHub Servers**

There should be a GitHub server entry with:
- **API URL**: `https://api.github.com`
- **Credentials**: `github-yocto-deep-dive-jenkins-api` (selected from dropdown)
- **Manage hooks**: checked (optional but recommended)

Click **Test connection** — it must succeed and show your GitHub username.

If the Credentials dropdown shows "none" or a different credential, the plugin will use anonymous access.

### Step 3: Verify the multibranch job Branch Sources

Navigate to: **yocto-deep-dive-ci → Configure → Branch Sources**

In the GitHub source configuration:
- **Credentials** (for API / status reporting): must be set to `github-yocto-deep-dive-jenkins-api`
- **Repository HTTPS URL** or **Owner/Repository**: must point to `yassibeh/yocto_deep_dive`

Note: the Branch Sources credential is what the GitHub Branch Source plugin uses for:
1. Discovering branches
2. Publishing commit statuses / check runs

If this credential field is empty or set to "- none -", the plugin discovers branches via anonymous access (which works for public repos) but CANNOT publish statuses (which requires authentication).

### Step 4: Verify the SSH credential is separate

The SSH credential `github-yocto-deep-dive-ssh` should only appear in checkout-related configuration, not in the Branch Sources API credential field.

### Step 5: Trigger a new build

After fixing the configuration:
1. Save the Jenkins configuration
2. Push a commit to `feature/jenkins-containerized-st-yocto-build`
3. Wait 1-2 minutes
4. Check the GitHub API:

```bash
curl -s "https://api.github.com/repos/yassibeh/yocto_deep_dive/commits/<new-sha>/status" | python3 -m json.tool
curl -s "https://api.github.com/repos/yassibeh/yocto_deep_dive/commits/<new-sha>/check-runs" | python3 -m json.tool
```

### Step 6: Verify in Jenkins console log

After a new build starts, check the build console log for:
- **Good**: `Setting GitHub commit status` or `GitHub has been notified`
- **Bad**: `Connecting to https://api.github.com with no credentials, anonymous access`

## Success criteria

1. `statuses` array is non-empty OR `check_runs` count is > 0
2. Jenkins console shows authenticated GitHub API access
3. The exact `context` (for statuses) or `name` (for check runs) is captured — this is needed for branch protection

## Common pitfalls

1. **Credential in user store vs global store**: credentials created under your Jenkins user profile (Manage Jenkins → People → [your user] → Credentials) are NOT visible to system-level plugins. They must be in Manage Jenkins → Credentials → System → Global credentials.

2. **Missing PAT scope**: the GitHub Personal Access Token must have `repo:status` at minimum. For full multibranch functionality, `repo` (full control) is recommended.

3. **Branch Sources credential empty**: for public repos, GitHub Branch Source can discover branches without credentials. This makes it seem like everything works, but status reporting silently fails because it requires authentication.

4. **Multiple GitHub server entries**: if there are multiple GitHub server entries, the plugin may pick the wrong one. Remove duplicates.

5. **Credential ID mismatch**: ensure the credential ID in the dropdown actually matches the one you created. Jenkins may show old/deleted credential IDs that no longer work.
