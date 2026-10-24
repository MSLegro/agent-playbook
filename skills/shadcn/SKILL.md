---
name: shadcn
description: >-
  shadcn/ui, Radix UI primitives, Tailwind CSS v4, class-variance-authority (cva),
  and accessible React form patterns (react-hook-form + zod).
  Use when building, styling, or composing UI components, dialogs, data tables,
  and forms with shadcn/ui and Tailwind CSS.
  Keywords: shadcn, radix-ui, tailwind, cn, cva, Dialog, Form, DataTable, lucide-react.
  Do not use for server-state caching logic — use tanstack-query-best-practices.
---

# shadcn/ui + Radix + Tailwind CSS Best Practices

## Activation Contract
Activate when building or refactoring React UI components, forms, modals, or dashboards using `shadcn/ui`, `@radix-ui/*`, and Tailwind CSS.

## Hard Rules
1. **Semantic Design Tokens (Never Hardcode Hex/Raw Colors)**:
   - Use semantic CSS variables (`bg-background`, `text-foreground`, `bg-card`, `text-muted-foreground`, `border-border`, `bg-destructive`) so dark/light themes work seamlessly.
2. **Compose with `cn()` (`clsx` + `tailwind-merge`)**:
   - Always accept `className?: string` on custom components and merge classes via `cn('base-classes', className)` so callers can safely override layout utilities.
3. **Accessible Radix Dialogs & Popovers**:
   - Every `DialogContent` / `SheetContent` MUST include a `DialogTitle` and `DialogDescription` (wrap in `sr-only` if visually hidden) to prevent Radix accessibility runtime warnings and ensure screen-reader compliance.
4. **Type-Safe Forms (`react-hook-form` + `@hookform/resolvers/zod`)**:
   - Bind forms to a `zod` schema via `zodResolver(schema)`. Never manage multi-field form validation manually with scattered `useState` booleans.
5. **Preserve Ref and HTML Attributes (`React.ComponentProps`)**:
   - In React 19, type component props with `React.ComponentProps<'button'>` (passing `ref` directly as a prop) and spread `...props` onto the underlying element.

## Execution Pattern

```tsx
import * as React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const statusBadgeVariants = cva(
  'inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      tone: {
        pending: 'border-amber-500/30 bg-amber-500/10 text-amber-700 dark:text-amber-300',
        issued: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-700 dark:text-emerald-300',
        cancelled: 'border-destructive/30 bg-destructive/10 text-destructive',
      },
    },
    defaultVariants: {
      tone: 'pending',
    },
  },
);

export interface StatusBadgeProps
  extends React.ComponentProps<'span'>,
    VariantProps<typeof statusBadgeVariants> {}

export function StatusBadge({ className, tone, ...props }: StatusBadgeProps) {
  return <span className={cn(statusBadgeVariants({ tone }), className)} {...props} />;
}
```

## Output Contract
- Semantic Tailwind classes (`bg-background`, `text-foreground`, etc.).
- Full keyboard and ARIA compliance (`DialogTitle`, `aria-invalid`, `FormLabel`).
- Clean composition via `cn()` and `cva()`.
