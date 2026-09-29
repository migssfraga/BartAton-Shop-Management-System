# Implementation Plan - Admin Reports Page

Create a new "Reports" page for the Admin side that matches the design of existing pages, using the dark navy theme and gold accents.

## Proposed Changes

### [Admin Reports Component]

#### [NEW] [admin_reports_screen.dart](file:///C:/Users/Miguel Fraga/AndroidStudioProjects/bartaton_shop_system/lib/screens/admin_reports_screen.dart)
- Implement `AdminReportsScreen` with a layout consistent with other admin screens.
- Include summary statistics for revenue, appointments, and rentals.
- Add visual reports using `fl_chart` (e.g., bar charts for monthly sales and line charts for growth).
- Use `AppHeader` and `AppDrawer` for consistent navigation.

#### [MODIFY] [main.dart](file:///C:/Users/Miguel Fraga/AndroidStudioProjects/bartaton_shop_system/lib/main.dart)
- Import `AdminReportsScreen`.
- Register the `/admin/reports` route.

## Verification Plan

### Manual Verification
- Navigate to the Admin Dashboard.
- Open the sidebar (Drawer).
- Tap on "Reports".
- Verify that the Reports page opens with the correct design (dark theme, gold accents, header, and drawer).
- Check that the charts and cards are displayed correctly.
