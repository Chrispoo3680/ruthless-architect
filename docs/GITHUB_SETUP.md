# Publishing this repository to GitHub

The release ZIP is already laid out as a repository root.

## New repository

1. Create an empty GitHub repository. Do not ask GitHub to pre-create a README, `.gitignore`, or license because this package already contains them.
2. Unzip the release locally.
3. Review `LICENSE`. It intentionally grants no open-source license. Replace it before public release if you want an open-source project.
4. Initialize and push:

```bash
cd ruthless-architect-v1.4
git init
git branch -M main
git add .
git commit -m "Initial Ruthless Architect v1.4"
git remote add origin <your-github-repo-url>
git push -u origin main
```

## Install from the clone

```bash
./scripts/install.sh
./scripts/doctor.sh
```

The default installer symlinks the clone into `~/.claude/skills/ruthless-architect`, which is convenient while developing the skill. Use `./scripts/install.sh --copy` if you prefer a detached installed copy.

## Before making the repository public

- choose a real license;
- remove any private runtime details, usernames, tokens, repository names, or organization-specific commands you may have added locally;
- verify `references/local-worker.md` does not contain secrets;
- run `make check` and `./scripts/doctor.sh`;
- review `SECURITY.md` and enable GitHub private vulnerability reporting if desired.
