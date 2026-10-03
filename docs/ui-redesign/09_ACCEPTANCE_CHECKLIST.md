# UI Redesign Acceptance Checklist

## Pen completeness
- [ ] All 17 worker-facing screen files represented.
- [ ] Main four-tab shell represented.
- [ ] Foundations and reusable components defined.
- [ ] Arabic RTL is primary.
- [ ] Home, Orders and active Order Details approved first.
- [ ] Loading/empty/error/submitting states designed.
- [ ] All Order Details lifecycle states designed.
- [ ] Multi-worker states designed.
- [ ] Multi-day/session states designed.
- [ ] SOS designed.
- [ ] Extension flow designed.
- [ ] Completion/customer-waiting/dispute states designed.
- [ ] Profile completeness/account activation states designed.
- [ ] Wallet, transactions, notifications, reviews, work areas and working time designed.

## Behavior preservation
- [ ] No API endpoint changes required by design.
- [ ] No request/response changes required.
- [ ] Existing lifecycle policy can drive every CTA.
- [ ] Customer data remains hidden until existing rules allow it.
- [ ] Team completion remains server-authoritative.
- [ ] Start-travel timing rule remains valid.
- [ ] Arrival/start verification remains valid.
- [ ] Realtime/Pusher/FCM remains compatible.
- [ ] Location tracking remains compatible.
- [ ] SOS remains compatible.
- [ ] Financial calculations remain unchanged.

## Flutter implementation
- [ ] Pen is visual source of truth.
- [ ] Existing code is behavioral source of truth.
- [ ] Presentation refactor separated from business changes.
- [ ] One dominant primary action per lifecycle state.
- [ ] Buttons have loading/disabled states.
- [ ] Interactive Pen components map to existing Flutter actions.
- [ ] No raw backend statuses exposed.
- [ ] RTL/mixed content verified.
- [ ] Small screens/text scaling verified.
- [ ] Existing tests pass.
- [ ] New presentation regressions covered where useful.

## Final review
- [ ] Client understands each screen without technical explanation.
- [ ] Developers can determine each button's behavior from annotations.
- [ ] Components are consistent throughout.
- [ ] Operational state is recognizable at a glance.
- [ ] Waiting states clearly indicate no worker action is needed.
- [ ] Emergency/support actions are discoverable but safe.
- [ ] No placeholder/wireframe-only content remains.
