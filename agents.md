# HabitFlow — Agent Context

> Read this file in full before making any changes or running any commands.
> It describes the project architecture, conventions, data model, and important rules.

---

## 1. Project Overview

**HabitFlow** is a full-stack habit tracking and journaling web app. Users can:

- **Track habits** — create daily/weekly habits and mark them complete per day.
- **Journal** — write free-text journal entries with a mood rating (1–5) per day.
- **View statistics** — 30-day completion trend charts and mood-vs-completion correlation.
- **Manage profile** — update display name, toggle dark/light theme.

The app has auth (email/password + Google OAuth), per-user Row Level Security, and is fully responsive (mobile bottom nav + desktop sidebar).

---

## 2. Tech Stack

| Layer          | Technology                                        |
| -------------- | ------------------------------------------------- |
| Framework      | **React 19** (SPA, no SSR)                        |
| Routing        | **React Router v7** (`createBrowserRouter`)       |
| Styling        | **Tailwind CSS v4** (CSS-first config, `@theme`)  |
| Animations     | **Framer Motion v12**                             |
| Icons          | **Lucide React**                                  |
| Charts         | **Recharts v3**                                   |
| Date utils     | **date-fns v4**                                   |
| Backend / DB   | **Supabase** (Auth, PostgreSQL, Row Level Security) |
| Build tool     | **Vite 8** (`@vitejs/plugin-react`)               |
| Package mgr    | **npm** (lockfile: `package-lock.json`)            |
| Font           | **Inter** (loaded via Google Fonts in `index.html`) |

### Key versions (from `package.json`)

```
react              ^19.2.7
react-dom          ^19.2.7
react-router-dom   ^7.18.0
tailwindcss        ^4.3.1
@tailwindcss/vite  ^4.3.1
framer-motion      ^12.42.0
@supabase/supabase-js ^2.108.2
recharts           ^3.9.0
date-fns           ^4.4.0
lucide-react       ^1.21.0
vite               ^8.1.0
```

---

## 3. Project Structure

```
habits-journaling-tracker/
├── index.html                      # HTML entry — loads Inter font, React root
├── vite.config.js                  # Vite + React + Tailwind v4 plugin
├── package.json                    # deps, scripts (dev / build / preview)
├── .env.example                    # required env vars template
├── .env.local                      # actual secrets (gitignored)
│
├── supabase/
│   └── schema.sql                  # full DB schema (tables, RLS, triggers, indexes)
│
├── public/                         # static assets served at root
│
└── src/
    ├── main.jsx                    # React root — wraps App in AuthProvider + DateProvider
    ├── App.jsx                     # Route definitions (createBrowserRouter)
    ├── index.css                   # Tailwind import + @theme tokens + base styles
    │
    ├── lib/
    │   └── supabase.js             # Supabase client singleton (reads env vars)
    │
    ├── contexts/
    │   ├── AuthContext.jsx          # Auth state, signUp/signIn/signOut/updateProfile
    │   └── DateContext.jsx          # Global activeDate state (shared across pages)
    │
    ├── hooks/
    │   ├── useHabits.js            # CRUD habits + completions, streaks, optimistic UI
    │   ├── useJournal.js           # Journal CRUD with debounced auto-save (1.5s)
    │   ├── useStatistics.js        # 30-day trend + mood correlation data
    │   └── useTheme.js             # Dark/light toggle, persisted to localStorage
    │
    ├── components/
    │   ├── Layout.jsx              # Desktop sidebar + mobile bottom nav, theme toggle, sign out
    │   ├── ProtectedRoute.jsx      # Redirects to /login if not authenticated
    │   ├── dashboard/
    │   │   ├── HeatmapGrid.jsx     # 28-day habit completion heatmap
    │   │   ├── JournalWidget.jsx   # Dashboard journal preview/link
    │   │   └── ProgressRing.jsx    # Circular progress indicator
    │   └── habits/
    │       ├── DateBar.jsx         # Horizontal date picker strip
    │       ├── HabitCard.jsx       # Individual habit with completion toggle
    │       └── HabitFormModal.jsx  # Create/edit habit modal
    │
    └── pages/
        ├── LoginPage.jsx           # Email/password + Google OAuth login
        ├── RegisterPage.jsx        # Registration with full_name
        ├── DashboardPage.jsx       # Overview: progress ring, heatmap, habit list, journal widget
        ├── HabitsPage.jsx          # Full habit list with add/edit/delete
        ├── JournalPage.jsx         # Daily journal editor with mood picker
        ├── StatsPage.jsx           # Recharts line/bar charts for trends
        └── ProfilePage.jsx        # Profile editor, theme toggle, sign out
```

---

## 4. Database Schema (Supabase / PostgreSQL)

Full schema in `supabase/schema.sql`. Summary:

### Tables

| Table                | Key Columns                                                            | Notes                                       |
| -------------------- | ---------------------------------------------------------------------- | ------------------------------------------- |
| `profiles`           | `id` (uuid, FK → auth.users), `full_name`, `updated_at`               | Auto-created on signup via trigger           |
| `habits`             | `id`, `user_id`, `title`, `frequency` ('daily'), `color_hint`, `created_at` | User-owned habits                            |
| `habit_completions`  | `id`, `habit_id` (FK → habits), `user_id`, `completed_date`           | Unique constraint on `(habit_id, completed_date)` |
| `journals`           | `id`, `user_id`, `entry_date`, `content`, `mood` (1–5), `updated_at`  | Unique constraint on `(user_id, entry_date)` |

### Row Level Security

All tables have RLS enabled. Every policy restricts access to `auth.uid() = user_id` (or `id` for profiles). Users can only read/write their own data.

### Trigger

`on_auth_user_created` — after a new user signs up, a row is auto-inserted into `profiles`.

### Indexes

- `idx_habits_user_id` on `habits(user_id)`
- `idx_completions_habit_id` on `habit_completions(habit_id)`
- `idx_completions_user_date` on `habit_completions(user_id, completed_date)`
- `idx_journals_user_date` on `journals(user_id, entry_date)`

---

## 5. Environment Variables

Defined in `.env.local` (gitignored). Required:

```
VITE_SUPABASE_URL=<supabase project URL>
VITE_SUPABASE_ANON_KEY=<supabase anon/public key>
```

Accessed via `import.meta.env.VITE_*` (Vite convention).

---

## 6. Routing

Defined in `src/App.jsx` using `createBrowserRouter`:

| Path        | Component        | Auth Required | Notes                |
| ----------- | ---------------- | ------------- | -------------------- |
| `/login`    | `LoginPage`      | No            | Public               |
| `/register` | `RegisterPage`   | No            | Public               |
| `/`         | `DashboardPage`  | Yes           | Index route of Layout |
| `/habits`   | `HabitsPage`     | Yes           | Nested under Layout  |
| `/journal`  | `JournalPage`    | Yes           | Nested under Layout  |
| `/stats`    | `StatsPage`      | Yes           | Nested under Layout  |
| `/profile`  | `ProfilePage`    | Yes           | Nested under Layout  |

All authenticated routes are children of `<ProtectedRoute><Layout /></ProtectedRoute>`, which renders `<Outlet />` for child pages.

---

## 7. State Management

There is **no global state library** (no Redux, Zustand, etc.). State is managed via:

1. **React Context** — `AuthContext` (user/session/profile), `DateContext` (activeDate).
2. **Custom hooks** — `useHabits`, `useJournal`, `useStatistics`, `useTheme`. Each hook manages its own local state and Supabase queries.
3. **Optimistic UI** — `useHabits` uses optimistic updates with rollback on error for toggling completions and deleting habits.
4. **Debounced auto-save** — `useJournal` auto-saves journal content after 1.5 seconds of inactivity.

Provider hierarchy (in `main.jsx`):
```
<StrictMode>
  <AuthProvider>
    <DateProvider>
      <App />
    </DateProvider>
  </AuthProvider>
</StrictMode>
```

---

## 8. Styling Conventions

- **Tailwind CSS v4** with CSS-first configuration (`@theme` block in `index.css`).
- Custom CSS classes: `.bento-card`, `.glass-card`, `.animate-fade-in-up`, `.animate-pulse-soft`, `.hide-scrollbar`.
- **Dark mode** — toggled via `html.dark` class (managed by `useTheme` hook, persisted to `localStorage` key `habitflow-theme`).
- **Color palette** — Emerald (accents for habits), Indigo (primary brand), Slate/Zinc (surfaces).
- **Font** — Inter (300–800 weights, loaded from Google Fonts).
- Framer Motion for page transitions (`AnimatePresence` in Layout) and micro-animations.

---

## 9. Development Commands

```bash
npm run dev       # Start Vite dev server (HMR)
npm run build     # Production build → dist/
npm run preview   # Preview production build locally
```

---

## 10. Conventions & Rules

### Code style
- **Functional components only** — no class components.
- **Named exports** for contexts/hooks (`export function useAuth()`), **default exports** for pages and components.
- **File naming** — PascalCase for components/pages (`.jsx`), camelCase for hooks/utils (`.js`).
- **No TypeScript** — the project uses plain JavaScript (`.js` / `.jsx`).

### Data patterns
- All Supabase queries go through custom hooks, not directly in components.
- Date formatting uses `date-fns` `format()` with `'yyyy-MM-dd'` for DB dates and `'MMM d'` for display.
- User ID is always sourced from `useAuth()` → `user.id`.

### Important gotchas
- `useJournal` uses **upsert** with `onConflict: 'user_id,entry_date'` — this matches the unique constraint on `journals`.
- `habit_completions` has a unique constraint on `(habit_id, completed_date)` — don't try to insert duplicates.
- The Supabase client has a **fallback placeholder URL/key** in `src/lib/supabase.js` to prevent crashes if `.env.local` is missing, but the app won't function without real credentials.
- Tailwind v4 uses `@import "tailwindcss"` and `@theme {}` — **not** the v3 `tailwind.config.js` approach. There is no `tailwind.config.js` file.
- The `@tailwindcss/vite` plugin handles Tailwind processing — it's registered in `vite.config.js`.

### Do NOT
- Do **not** install Tailwind v3 or create `tailwind.config.js` — the project uses Tailwind v4 CSS-first config.
- Do **not** add a separate state management library unless explicitly asked.
- Do **not** modify the Supabase schema without updating `supabase/schema.sql`.
- Do **not** commit `.env.local` — it's gitignored.
- Do **not** use `require()` — the project is ESM (`"type": "module"`).
