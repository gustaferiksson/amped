# Amped - durable context

What this project knows and why it is the way it is. Written for whoever picks
it up next, human or agent.

| Where | What belongs there |
| --- | --- |
| [`adr/`](adr/) | Decisions with a rejected alternative. Immutable; superseded, never rewritten. |
| [`architecture.md`](architecture.md) | Domain knowledge — macOS behaviour and terms the code assumes but does not explain. |
| [`debt.md`](debt.md) | Known compromises, why they were tolerated, what would trigger fixing them. |
| [`working-notes/`](working-notes/) | Dated log of turns with nothing durable to record. Prunable. |
| [`RELEASING.md`](RELEASING.md) | The release procedure. |

The [README](../README.md) is the user-facing explanation of behaviour and is
part of the durable context — it already carries most of the "what". These
files carry the "why".
