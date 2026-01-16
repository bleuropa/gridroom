# Design System

> Brand consistency rules for Claude Code to follow when implementing UI.

## Dark Theme (Default)

**All new UI components MUST use dark theme styling:**

- Backgrounds: `bg-zinc-900` (primary), `bg-zinc-800` (elevated/interactive)
- Borders: `border-white/10` (not `border-gray-*`)
- Text: `text-white` (headings), `text-zinc-300` (body), `text-zinc-400`/`text-zinc-500` (muted)
- Inputs: `bg-zinc-800 border-white/10 text-white placeholder-zinc-500`
- Hover states: `hover:bg-zinc-700` or `hover:bg-zinc-800`
- Accent: `violet-500` for primary actions, `amber-500` for highlights

**Never use:** `bg-white`, `bg-gray-50`, `border-gray-200`, `text-gray-900` in new components.

## Customization

Adapt these colors to match your brand:

| Role | Default | Your Brand |
|------|---------|------------|
| Primary accent | `violet-500` | _replace_ |
| Highlight | `amber-500` | _replace_ |
| Success | `green-500` | _replace_ |
| Error | `red-500` | _replace_ |
| Warning | `yellow-500` | _replace_ |

## Component Patterns

### Buttons

```tsx
// Primary
<button className="bg-violet-500 text-white hover:bg-violet-600">

// Secondary
<button className="bg-zinc-800 text-zinc-300 border border-white/10 hover:bg-zinc-700">

// Ghost
<button className="text-zinc-400 hover:text-white hover:bg-zinc-800">
```

### Cards

```tsx
<div className="rounded-lg border border-white/10 bg-zinc-900 p-4">
```

### Inputs

```tsx
<input className="w-full rounded-md border border-white/10 bg-zinc-800 px-3 py-2 text-white placeholder-zinc-500 focus:border-violet-500 focus:ring-1 focus:ring-violet-500" />
```

### Tables

```tsx
<table className="divide-y divide-white/10">
  <thead className="bg-zinc-800">
    <th className="text-zinc-400">
  <tbody className="bg-zinc-900">
    <td className="text-zinc-300">
```

## Related Docs

- [[Product Vision]] - Brand identity context
- Tailwind CSS v4 documentation
