# Security policy

This repository orchestrates coding agents with filesystem and shell access. Treat runtime configuration as security-sensitive.

## Reporting a security issue

If this repository is public, prefer a private GitHub Security Advisory rather than a public issue for vulnerabilities that could expose credentials, execute unintended commands, escape workspace boundaries, or destroy developer state.

Do not include real API keys, OAuth tokens, SSH keys, customer data, private repository contents, or other secrets in a report.

## Security boundaries

A Git worktree protects repository state; it is **not** an operating-system sandbox. In particular, broad shell permission bypasses may still access home-directory files, environment variables, network resources, and credentials.

The skill therefore defaults to narrow runtime permissions, explicit workspace anchors, bounded scope, diff inspection, finite validation, and fail-closed adapter health checks.
