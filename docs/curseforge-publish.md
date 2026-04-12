# CurseForge Publish Setup

## 1) Create GitHub repository

- Create a new public repository (recommended name: `reckless-tracker`).
- Do not initialize with README or gitignore.

## 2) Connect local repo to GitHub

```powershell
cd C:\Users\tekau\Documents\Codex\wow-reckless-tracker
git remote add origin https://github.com/<your-user>/reckless-tracker.git
git branch -M main
git push -u origin main
```

## 3) Configure CurseForge automatic packaging (Webhook, optional)

- In CurseForge project page, get your project ID.
- Create a CurseForge API token.
- Add a GitHub webhook on the repo:

```text
https://www.curseforge.com/api/projects/{projectID}/package?token={token}
```

- Keep default webhook settings.
- This repository primarily uses GitHub Actions-based publishing instead of webhook publishing.

## 4) Release by tag

- Push a tag to trigger packaging.
- Tag naming controls release type:
  - `v0.1.1-alpha` => alpha
  - `v0.1.1-beta` => beta
  - `v0.1.1` => release

```powershell
git tag v0.1.1
git push origin v0.1.1
```

## Recommended: GitHub Actions publishing (configured in this repo)

- Workflow file: `.github/workflows/release.yml`
- Set these GitHub Actions repository secrets:
  - `CF_API_KEY` = your CurseForge API token
  - `CF_PROJECT_ID` = your CurseForge project numeric ID

```powershell
gh secret set CF_API_KEY -R marvin-pedlar/reckless-tracker
gh secret set CF_PROJECT_ID -R marvin-pedlar/reckless-tracker
```

- Then push a new tag (e.g. `v0.1.1`) and the workflow uploads automatically.

## Verification gates (current pipeline)

- `.github/workflows/ci.yml` (`Verify`) runs on pushes/PRs:
  - Lua lint (`luacheck`)
  - Pester test suite
  - BigWigs packager dry-run (`-d`) + zip content policy checks
- `.github/workflows/release.yml` (`Release`) runs on `v*` tags:
  - `verify-before-publish` test job must pass first
  - `package-and-publish` runs only after verification passes

## Notes

- Packaging behavior is configured with `.pkgmeta`.
- The repository includes extra development files, but `.pkgmeta` ignores them in the packaged artifact.
- The `package-and-publish` job uses environment `curseforge-production`. Configure environment protection rules/reviewers in GitHub settings if you want manual approval before publish.
