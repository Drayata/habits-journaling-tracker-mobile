import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AuthProvider } from './contexts/AuthContext'
import { DateProvider } from './contexts/DateContext'
import App from './App'
import './index.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <AuthProvider>
      <DateProvider>
        <App />
      </DateProvider>
    </AuthProvider>
  </StrictMode>
)
