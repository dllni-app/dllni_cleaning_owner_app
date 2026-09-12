# Cleaning v2 worker UI acceptance

Design source: `design-system/MASTER.md` and page overrides. Review method: `ui-ux-pro-max` local-rule fallback; Python search was unavailable.

- [x] Open-time meter and extension/end decisions use server-authoritative values.
- [x] Material kit can be acknowledged once with visible progress/result.
- [x] Special services start/finish independently and require a reason when unable.
- [x] Equipment acknowledgement/return actions expose status and prevent duplicate taps.
- [x] Recurring schedule proposals expose old/new values and accept/reject actions for the affected worker.
- [x] Realtime aliases accept nested legacy/new booking payloads.
- [x] New controls meet the 48dp target, include semantic labels, support RTL, and do not rely on color alone.
- [x] Operational model/widget and full worker test suites pass.
- [x] The operational action surface is exercised in an explicit dark color scheme at 375px and 200% text scale; existing suites cover the light theme.
