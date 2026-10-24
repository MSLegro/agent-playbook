---
name: tanstack-query-best-practices
description: >-
  TanStack Query v5 (@tanstack/react-query) architecture, hierarchical queryKey
  factories, queryOptions(), mutations with cache invalidation, and optimistic updates.
  Use when managing server state, data fetching, caching, or mutations in React applications.
  Keywords: tanstack query, react-query, useQuery, useMutation, queryOptions, queryKey, invalidateQueries.
  Do not use for pure UI component styling — use shadcn or vercel-composition-patterns.
---

# TanStack Query v5 Best Practices

## Activation Contract
Activate when implementing or refactoring data fetching, server-state synchronization, pagination, or mutations in React with `@tanstack/react-query` v5.

## Hard Rules
1. **Use `queryOptions()` Factories (Never Inline Raw Arrays)**:
   - Centralize all query keys and `queryFn` definitions per domain module using `queryOptions({ queryKey, queryFn, staleTime })`.
   - Structure keys hierarchically from general to specific: `['invoices', 'list', filters]` and `['invoices', 'detail', invoiceId]`.
2. **Never Copy Server State into `useState` / `useEffect`**:
   - Do not mirror `useQuery().data` into local `useState` via `useEffect`. Derive filtered/sorted view data directly with `useMemo` or the `select` option inside `queryOptions`.
3. **Single Object Signature (v5 Standard)**:
   - Always pass a single options object to `useQuery(invoiceQueries.detail(id))`, `useMutation({...})`, and `queryClient.invalidateQueries({ queryKey: invoiceQueries.lists() })`.
4. **Explicit Cache Invalidation on Mutation**:
   - Every `useMutation` MUST invalidate affected query key prefixes in `onSuccess` (or roll back in `onError` when using optimistic updates) and surface RFC 9457 `ProblemDetails` messages cleanly to the UI.
5. **Respect `AbortSignal`**:
   - Forward the `signal` provided by `queryFn: ({ signal }) => api.fetchInvoices(filters, { signal })` to `fetch` so cancelled requests abort cleanly on unmount or filter change.

## Execution Pattern

```typescript
import { queryOptions, useMutation, useQueryClient } from '@tanstack/react-query';

export interface InvoiceFilter {
  status?: 'PENDING' | 'ISSUED' | 'CANCELLED';
  page?: number;
}

export const invoiceQueries = {
  all: () => ['invoices'] as const,
  lists: () => [...invoiceQueries.all(), 'list'] as const,
  list: (filters: InvoiceFilter) =>
    queryOptions({
      queryKey: [...invoiceQueries.lists(), filters] as const,
      queryFn: ({ signal }) => fetchInvoices(filters, signal),
      staleTime: 30_000,
    }),
  details: () => [...invoiceQueries.all(), 'detail'] as const,
  detail: (id: string) =>
    queryOptions({
      queryKey: [...invoiceQueries.details(), id] as const,
      queryFn: ({ signal }) => fetchInvoiceById(id, signal),
      enabled: Boolean(id),
    }),
};

export function useIssueInvoiceMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: { customerId: string; amountCents: number }) => issueInvoice(payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: invoiceQueries.lists() });
    },
  });
}
```

## Output Contract
- Zero `useEffect` + `fetch` data-loading anti-patterns.
- Typed `queryOptions` factories per feature module.
- Proper `AbortSignal` forwarding and targeted cache invalidation.
