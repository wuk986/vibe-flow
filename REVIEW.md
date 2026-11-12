# Review checklist

Used by the reviewer role. The item numbers are stable: finding IDs and the fallback review's `Checklist` line refer to them. Each item applies a section of [PRINCIPLES.md](PRINCIPLES.md).

1. **Acceptance**: every acceptance criterion, and every feedback point on resume, is met.
2. **Tests** (Test-first): every criterion has a test; a bug has a regression test that was red before the fix; no test was weakened, skipped, or deleted to reach green.
3. **Scope** (Surgical changes): every changed line traces back to the issue.
4. **Simplicity**: nothing speculative; no single-use abstraction.
5. **Single source** (Single source of truth): nothing duplicates existing code, constants, types, or config.
6. **Consistency** (Surgical changes): style, naming, and idiom match the surroundings; nothing the change orphaned is left behind.
7. **Failure modes**, high risk only: for each high-risk criterion the issue meets (CONVENTIONS.md, Risk), play its failure modes through: attack paths and permission bypass; data loss on abort or a partial migration; races and stale caches; breaking existing callers of a public interface. Each failure mode needs a test that covers it; a missing one is must-fix.
