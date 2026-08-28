# ✨ HabitFlow — Habit Tracker & Journal

A modern, minimalist habit tracker and journaling web app built with **React**, **Tailwind CSS v4**, **Framer Motion**, and **Supabase**. Features a clean Bento Grid aesthetic, dark mode, and a mobile-first responsive layout.

![React](https://img.shields.io/badge/React-19-61dafb?logo=react&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4-06b6d4?logo=tailwindcss&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3fcf8e?logo=supabase&logoColor=white)
![Framer Motion](https://img.shields.io/badge/Framer_Motion-Animations-e042fb?logo=framer&logoColor=white)

---

## 🎯 Features

### Habit Tracking
- **CRUD Habits** — Create, edit, and delete habits with custom colors
- **Daily Check-in** — Scrollable date bar to toggle completions for any day
- **Streak Counter** — Automatic consecutive-day streak calculation per habit
- **Optimistic UI** — Instant visual feedback; syncs to Supabase in the background

### Journaling
- **Distraction-free Editor** — Clean textarea with 1.5s debounced auto-save
- **Mood Tracker** — 5-level emoji selector (😢 😕 😐 🙂 😄) synced per day
- **Date-linked** — Selecting a date loads the corresponding journal entry

### Dashboard (Bento Grid)
- **Progress Ring** — Animated circular progress showing today's completion rate
- **4-Week Heatmap** — GitHub-style contribution grid from completion data
- **Streak Card** — Best current streak with fire indicator
- **Journal Widget** — Today's mood and content preview
- **Quick Toggles** — Check off habits directly from the dashboard

### Design
- **Mobile-first** — Bottom navigation bar optimized for thumb reach
- **Desktop Sidebar** — Full sidebar nav on larger screens
- **Dark Mode** — Toggle between light/dark with system preference detection
- **Micro-animations** — Framer Motion transitions on every interaction

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React 19, React Router v7 |
| **Styling** | Tailwind CSS v4 (CSS-first config) |
| **Animations** | Framer Motion |
| **Icons** | Lucide React |
| **Backend** | Supabase (Auth + PostgreSQL) |
| **Date Utils** | date-fns |
| **Build Tool** | Vite 8 |

---

## 🚀 Getting Started

### Prerequisites
- **Node.js** 18+
- A **Supabase** project ([create one free](https://supabase.com))

### 1. Clone & Install

```bash
git clone https://github.com/your-username/habits-journaling-tracker.git
cd habits-journaling-tracker
npm install
```

### 2. Set Up Supabase Database

1. Go to your Supabase project → **SQL Editor**
2. Paste and run the contents of [`supabase/schema.sql`](supabase/schema.sql)
3. This creates all 4 tables with Row Level Security policies and a profile auto-creation trigger

### 3. Configure Environment Variables

```bash
cp .env.example .env.local
```

Edit `.env.local` with your Supabase credentials (found in **Settings → API**):

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. (Optional) Enable Google OAuth

1. Supabase Dashboard → **Authentication → Providers → Google**
2. Add your Google OAuth client ID and secret
3. Set the redirect URL as shown in the Supabase dashboard

### 5. Run

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser.

---

## 📁 Project Structure

```
habits-journaling-tracker/
├── supabase/
│   └── schema.sql              # Database migration (tables, RLS, triggers)
├── public/
│   └── vite.svg                # App favicon
├── src/
│   ├── lib/
│   │   └── supabase.js         # Supabase client initialization
│   ├── contexts/
│   │   ├── AuthContext.jsx     # Auth state, sign in/up/out, Google OAuth
│   │   └── DateContext.jsx     # Global active date state
│   ├── hooks/
│   │   ├── useTheme.js         # Dark mode toggle + persistence
│   │   ├── useHabits.js        # Habits CRUD, completions, streaks
│   │   └── useJournal.js       # Journal CRUD, auto-save, mood
│   ├── components/
│   │   ├── Layout.jsx          # Responsive shell (sidebar + bottom nav)
│   │   ├── ProtectedRoute.jsx  # Auth route guard
│   │   ├── dashboard/
│   │   │   ├── ProgressRing.jsx
│   │   │   ├── HeatmapGrid.jsx
│   │   │   └── JournalWidget.jsx
│   │   └── habits/
│   │       ├── DateBar.jsx
│   │       ├── HabitCard.jsx
│   │       └── HabitFormModal.jsx
│   ├── pages/
│   │   ├── LoginPage.jsx
│   │   ├── RegisterPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── HabitsPage.jsx
│   │   ├── JournalPage.jsx
│   │   └── ProfilePage.jsx
│   ├── App.jsx                 # Router configuration
│   ├── main.jsx                # Entry point with providers
│   └── index.css               # Tailwind + design tokens + utilities
├── .env.example
├── index.html
├── vite.config.js
└── package.json
```

---

## 🗄 Database Schema

| Table | Description |
|-------|-------------|
| `profiles` | User profile (auto-created on signup via trigger) |
| `habits` | User habits with title, frequency, and color |
| `habit_completions` | Daily completion records (unique per habit+date) |
| `journals` | Daily journal entries with content and mood (1-5) |

All tables have **Row Level Security** enabled — users can only access their own data.

---

## 📜 Available Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |

---

## 🎨 Design System

| Token | Light | Dark |
|-------|-------|------|
| Background | `slate-50` | `zinc-950` |
| Card Surface | `white` | `slate-800` |
| Primary Text | `slate-900` | `slate-50` |
| Success Accent | `emerald-500` | `emerald-400` |
| Primary Accent | `indigo-500` | `indigo-400` |
| Card Radius | `rounded-2xl` | `rounded-2xl` |

**Font:** [Inter](https://fonts.google.com/specimen/Inter) via Google Fonts.

---

## 📄 License

MIT
