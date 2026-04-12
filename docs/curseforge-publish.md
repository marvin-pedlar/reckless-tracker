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

## 3) Configure CurseForge automatic packaging

- In CurseForge project page, get your project ID.
- Create a CurseForge API token.
- Add a GitHub webhook on the repo:

```text
https://www.curseforge.com/api/projects/{projectID}/package?token={token}
```

- Keep default webhook settings.

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

## Notes

- Packaging behavior is configured with `.pkgmeta`.
- The repository includes extra development files, but `.pkgmeta` ignores them in the packaged artifact.
