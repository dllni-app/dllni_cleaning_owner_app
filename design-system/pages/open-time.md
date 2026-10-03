# Open-time worker override

- The timer and amount use API `serverNow`; worker device time is never authoritative.
- Show expected/hard ceiling and conflict result before accepting an extension.
- Extension/end requests replace action buttons with a pending state. Rejection requires a reason and never triggers automatic replacement.
- At hard ceiling, use an explicit administrative-termination status and recovery/support route.

