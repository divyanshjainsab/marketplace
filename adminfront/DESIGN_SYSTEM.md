# Adminfront Design System (Phase 2)

This admin UI intentionally uses a small, consistent set of primitives to keep spacing/typography stable across screens.

## Spacing scale (px)

Use only these increments (Tailwind mapping in parentheses):
- 4 (`1`)
- 8 (`2`)
- 12 (`3`)
- 16 (`4`)
- 24 (`6`)
- 32 (`8`)

Avoid `*5`, `*7`, and arbitrary spacing values in screen components.

## Typography

Use `adminfront/src/components/ui/typography.tsx`:
- `Heading` (`h1`–`h4`)
- `Text` variants:
  - `kicker` (uppercase section label)
  - `body`, `muted`
  - `label`, `helper`
  - `error`

## Form fields

Use `adminfront/src/components/ui/form-field.tsx`:
- Always render a label.
- Use `hint` and `error` for helper/validation messages.
- Pass `id`, `aria-describedby`, and `aria-invalid` to the actual control via the render-prop API.

## Components

Foundational primitives (reusable only):
- `Button` (`adminfront/src/components/ui/button.tsx`)
- `ButtonLink` (`adminfront/src/components/ui/button-link.tsx`)
- `Input` (`adminfront/src/components/ui/input.tsx`)
- `Select` (`adminfront/src/components/ui/select.tsx`)
- `Textarea` (`adminfront/src/components/ui/textarea.tsx`)
- `Card` (`adminfront/src/components/ui/card.tsx`)
- `Modal` / `ConfirmDialog` (`adminfront/src/components/ui/modal.tsx`)
- `Table` (`adminfront/src/components/ui/table.tsx`)
- `PageHeader` (`adminfront/src/components/ui/page-header.tsx`)

Rule of thumb:
- Screens/pages should assemble these primitives.
- Avoid ad-hoc Tailwind on controls (inputs/buttons/fields). Put styling in the primitives.
