# Claude Code Configuration

Configuration for [Claude Code](https://claude.com/claude-code) on the RHDH documentation repository.

## Structure

```
.claude/
  CLAUDE.md              # Project instructions (CQA, PR conventions, CI workflows)
  MEMORY.md              # Persistent cross-session knowledge
  settings.json          # Repository permissions (use wildcards, not individual paths)
  settings.local.json    # Local overrides (not committed)
  resources/             # Style guides and reference materials
  plugins/project-cqa/   # CQA 2.1 plugin (19 checks + resources)
```

## CQA Plugin

The `project-cqa` plugin provides automated Content Quality Assessment:

- **19 skills:** `cqa-00a` through `cqa-17`, plus a main workflow orchestrator
- **Script:** `node build/scripts/cqa/index.js [--fix] [--check NN] titles/<title>/master.adoc`
- **Spec:** `plugins/project-cqa/resources/cqa-spec.md`

See `plugins/project-cqa/skills/` for individual check details.

## Resources

Style guides in `resources/` are synced from upstream Red Hat sources:

| File | Source |
|------|--------|
| `red-hat-ssg.md` | [Supplementary Style Guide](https://redhat-documentation.github.io/supplementary-style-guide/) |
| `red-hat-peer-review.md` | [Peer Review Guide](https://redhat-documentation.github.io/peer-review/) |
| `red-hat-modular-docs.md` | [Modular Docs Reference](https://redhat-documentation.github.io/modular-docs/) |

Update all resources: `./build/scripts/update-cqa-resources.sh`

## Contributing

Update `MEMORY.md` with new patterns or lessons learned. Update `CLAUDE.md` if project conventions change. Commit with a clear explanation.
