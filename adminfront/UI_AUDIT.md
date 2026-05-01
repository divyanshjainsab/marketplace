# Adminfront UI Audit (Phase 1)

Date: 2026-04-25

Scope scanned:
- `adminfront/src/app/**`
- `adminfront/src/components/**` (layout, ui primitives, modules)
- `adminfront/src/lib/**`

## Layout issues

- **Inconsistent corner radius across the app**
  - `adminfront/src/components/ui/card.tsx` uses `rounded-[1.75rem]` while controls use `rounded-xl`, the shell uses `rounded-[2rem]`, `rounded-[1.5rem]`, and `rounded-3xl`.
  - Result: surfaces don’t feel like one system; visual “wobble” between screens.

- **Shell container uses overflow clipping**
  - `adminfront/src/components/layout/app-shell.tsx` uses `overflow-hidden` on the main shell surface (can clip focus rings, menus, and future modals; also makes “scrollable content area” harder to guarantee).

- **Arbitrary shadows/spacing values are used as one-offs**
  - Multiple `shadow-[...]` and `tracking-[...]` usages (sidebar, shell, not-authorized, hero preview) create inconsistent elevation/typography.

## Responsiveness issues

- **Spacing scale is not enforced**
  - `gap-5`, `space-y-5`, `px-5`, `p-5` appear across screens (20px) which violates the required scale (4/8/12/16/24/32).
  - Examples: `adminfront/src/components/modules/*/*-screen-v2.tsx`, `adminfront/src/components/tour/tour-provider.tsx`.

- **Fixed sizing appears in core layout and overlays**
  - Sidebar width is fixed (`w-72`) and various `max-w-[...]`, `min-w-[...]`, `w-[min(...)]` occur.
  - These aren’t inherently wrong, but need a single, intentional layout system (container rules + responsive behavior).

## UX issues

- **Listings & products are not presented as a true “admin table”**
  - `adminfront/src/components/modules/listings/listings-screen-v2.tsx` and `adminfront/src/components/modules/products/products-screen-v2.tsx` render card lists.
  - For admin workflows (scan/edit), this reduces density and consistency vs. a responsive table pattern.

- **Delete confirmation uses `window.confirm`**
  - `adminfront/src/components/modules/listings/listings-screen-v2.tsx` uses `window.confirm`, which is jarring and inconsistent with a production SaaS admin UX.
  - Root cause: no reusable Modal/Confirm component exists yet.

- **Image upload is single-slot and inconsistent with “multi-image” workflow**
  - `adminfront/src/components/media/media-upload-field.tsx` is a single upload widget; screens need a consistent “image slots” layout (grid) for product/variant/listing images and other surfaces.

## Accessibility issues

- **Missing visible labels for multiple inputs (placeholder-only)**
  - `adminfront/src/components/modules/site-editor/site-editor-screen.tsx` uses several `<Input>` fields with placeholders but no label text (Hero title/subtitle/CTA/link; promotional block title/body/link).

- **Form field semantics are duplicated and not fully wired**
  - Multiple inline `Field` components exist with slightly different props/behavior across screens.
  - Errors/hints are not consistently connected via `aria-describedby`, and `aria-invalid` is not consistently applied across modules.

- **Buttons/links lack consistent focus-visible styling**
  - `adminfront/src/components/ui/button.tsx` does not enforce a system focus ring.
  - Several raw `<button>` / `<Link>` usages bypass the shared Button styling (`LogoutButton`, `not-authorized` page, parts of `AppShell`, Site Editor lists).

## Root causes (what to fix, not patch)

- No enforced design tokens (typography, radius, spacing) in Tailwind theme/components.
- Repeated one-off layout/typography patterns instead of reusable “page header”, “form field”, “table”, “modal”, and “state” components.
- Critical workflows (Listings, Site Editor) mix ad-hoc layout with missing form semantics.

