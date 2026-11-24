# MicroLedger - Operations Desk UI

Production React & Vite single-page application for Joint Liability Group (JLG) microfinance portfolio operations, loan origination, center meeting bulk collections, and transaction audit desk.

## Technology Stack
- **Framework**: React 18
- **Build Tool**: Vite 6
- **Routing**: React Router DOM 6
- **Icons**: Lucide React
- **Visual Analytics**: Recharts
- **Styling**: Pure modern CSS variables with responsive layouts and dark/light themes

## Development Setup

```bash
# Install dependencies
npm install

# Start local Vite development server
npm run dev

# Build production bundle
npm run build

# Preview production build locally
npm run preview
```

## Environment Configuration
Copy `.env.example` to `.env`:
```env
VITE_API_BASE_URL=http://localhost:5000/api
```
*(Leave blank for unified production deployments where the backend serves both API and static assets).*
