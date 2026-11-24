import { useEffect, useMemo, useState, createContext, useContext } from 'react'
import { NavLink, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import {
  Activity, ArrowDownLeft, ArrowUpRight, BadgeCheck, Banknote, Bell, BookOpen,
  Building2, CalendarDays, Check, ChevronDown, ChevronLeft, ChevronRight, CircleAlert,
  CircleDollarSign, Clock, CreditCard, Download, Eye, FileCheck2, Filter,
  Fingerprint, HandCoins, HelpCircle, Landmark, LayoutDashboard, LockKeyhole,
  LogOut, Menu, Moon, PanelLeft, PanelLeftClose, Plus, RefreshCw, RotateCcw, Search, Settings as SettingsIcon,
  ShieldAlert, ShieldCheck, Sun, Trash2, Users, Wallet, X, Zap
} from 'lucide-react'
import { api, readSession, saveSession, clearSession } from './services/api'
import PaymentTerminal from './PaymentTerminal'

// Toast Notification Context
const ToastContext = createContext({ showToast: () => {} })

const money = (n) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2,
  }).format(n || 0)

const nav = [
  { label: 'Overview', path: '/', icon: LayoutDashboard },
  { label: 'Borrowers & Groups', path: '/borrowers', icon: Users },
  { label: 'Loan Management', path: '/loans', icon: HandCoins },
  { label: 'Payment Gateway Terminal', path: '/terminal', icon: CreditCard },
  { label: 'Repayment Collection', path: '/collections', icon: Banknote },
  { label: 'Transaction Ledger', path: '/ledger', icon: BookOpen },
  { label: 'Settings & Admin', path: '/settings', icon: SettingsIcon },
]

const titles = {
  '/': ['Portfolio Overview', 'Real-time portfolio metrics, branch health, and credit performance.'],
  '/borrowers': ['Borrowers & Groups', 'Member directory, joint liability groups, and mutual guarantee networks.'],
  '/loans': ['Loan Accounts & Schedules', 'Loan origination, reducing-balance repayment schedules, and disbursements.'],
  '/terminal': ['Payment Terminal', 'Instant cash collection, digital payment gateway, and transaction processing desk.'],
  '/collections': ['Center Collections', 'Field meeting collections, branch cash desk, and automated receipts.'],
  '/ledger': ['Audit & Transaction Journal', 'Permanent double-entry record of all loans, repayments, and portfolio adjustments.'],
  '/settings': ['System & Preferences', 'Branch configuration, workspace preferences, and scheduled settlement tools.'],
}

// -------------------------------------------------------------
// App Shell
// -------------------------------------------------------------
function Shell({ children, user, onLogout, theme, toggleTheme }) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(() => {
    return localStorage.getItem('microledger_sidebar_collapsed') === 'true'
  })
  const location = useLocation()
  const [title, subtitle] = titles[location.pathname] || titles['/']

  const toggleCollapse = () => {
    setCollapsed((prev) => {
      const next = !prev
      localStorage.setItem('microledger_sidebar_collapsed', String(next))
      return next
    })
  }

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileOpen ? 'sidebar-open' : ''} ${collapsed ? 'collapsed' : ''}`}>
        <div className="brand">
          <div
            className="brand-mark"
            onClick={toggleCollapse}
            style={{ cursor: 'pointer' }}
            title={collapsed ? 'Click to expand sidebar' : 'MicroLedger'}
          >
            <Landmark size={20} />
          </div>
          {!collapsed && (
            <div className="brand-text">
              <b>microledger</b>
              <span>FINANCE OPERATIONS</span>
            </div>
          )}
          <button
            className="sidebar-toggle-btn"
            onClick={toggleCollapse}
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            aria-label="Toggle sidebar"
          >
            {collapsed ? <ChevronRight size={15} /> : <ChevronLeft size={15} />}
          </button>
          <button className="mobile-close" onClick={() => setMobileOpen(false)}>
            <X size={18} />
          </button>
        </div>

        {!collapsed && <div className="workspace-label">WORKSPACE</div>}
        <nav className="side-nav">
          {nav.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === '/'}
              onClick={() => setMobileOpen(false)}
              className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              title={collapsed ? item.label : undefined}
            >
              <item.icon size={18} />
              {!collapsed && <span>{item.label}</span>}
              {!collapsed && item.path === '/' && <span className="nav-dot" />}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="branch-switch" title={`Branch #${user?.branchId || 1} - Assigned Branch`}>
            <div className="branch-avatar">B{user?.branchId || 1}</div>
            {!collapsed && (
              <div className="branch-text">
                <b>Branch #{user?.branchId || 1}</b>
                <span>Assigned Branch</span>
              </div>
            )}
          </div>
        </div>
      </aside>

      {mobileOpen && <div className="scrim" onClick={() => setMobileOpen(false)} />}

      <main className={`main-area ${collapsed ? 'sidebar-collapsed' : ''}`}>
        <header className="topbar">
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <button className="menu-button" onClick={() => setMobileOpen(true)}>
              <Menu size={20} />
            </button>
            <button
              className="desktop-collapse-btn"
              onClick={toggleCollapse}
              title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
              aria-label="Toggle sidebar collapse"
            >
              {collapsed ? <PanelLeft size={18} /> : <PanelLeftClose size={18} />}
            </button>
            <div className="breadcrumbs">
              MicroLedger <ChevronRight size={13} /> <b>{title}</b>
            </div>
          </div>
          <div className="top-actions">
            <button
              className="theme-toggle-btn"
              onClick={toggleTheme}
              title={`Switch to ${theme === 'dark' ? 'Light' : 'Dark'} Mode`}
              aria-label="Toggle theme"
            >
              {theme === 'dark' ? <Sun size={17} /> : <Moon size={17} />}
            </button>
            <div className="user-profile">
              <div className="user-avatar">{(user?.name || 'U').slice(0, 1).toUpperCase()}</div>
              <div>
                <b>{user?.name || 'Staff User'}</b>
                <span>{user?.role || 'User'}</span>
              </div>
              <button className="logout-button" onClick={onLogout} title="Sign out" aria-label="Sign out">
                <LogOut size={16} />
              </button>
            </div>
          </div>
        </header>

        <div className="page-wrap">
          <div className="page-heading">
            <div>
              <div className="eyebrow">MICROLEDGER / CORE SYSTEM</div>
              <h1>{title}</h1>
              <p>{subtitle}</p>
            </div>
            <div className="heading-date">
              <CalendarDays size={15} />
              {new Date().toLocaleDateString('en-IN', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
              })}
            </div>
          </div>
          {children}
        </div>

        <footer className="footer" style={{ borderTop: '1px solid var(--border)', padding: '16px 36px', display: 'flex', justifyContent: 'space-between', color: 'var(--text-muted)', fontSize: '11px' }}>
          <span>© 2026 MicroLedger · Real-time Joint Liability Microfinance Platform</span>
          <span>Verified Double-Entry Balancing · Bank-Grade Security</span>
        </footer>
      </main>
    </div>
  )
}

function Button({ children, variant = 'primary', onClick, ...props }) {
  return (
    <button className={`btn ${variant}`} onClick={onClick} {...props}>
      {children}
    </button>
  )
}

function Status({ children }) {
  const v = String(children || '').toLowerCase()
  return <span className={`status status-${v.replaceAll(' ', '-')}`}>{children}</span>
}

function PageActions({ children }) {
  return <div className="page-actions">{children}</div>
}

function MetricCard({ label, value, change, icon: Icon, tone = 'blue', foot }) {
  return (
    <div className="metric-card">
      <div className="metric-top">
        <span>{label}</span>
        <div className={`metric-icon ${tone}`}>
          <Icon size={18} />
        </div>
      </div>
      <div className="metric-value">{value}</div>
      <div className="metric-foot">
        {change && (
          <span className="trend">
            <ArrowUpRight size={13} />
            {change}
          </span>
        )}
        <span>{foot}</span>
      </div>
    </div>
  )
}

function SectionTitle({ title, detail, action }) {
  return (
    <div className="section-title">
      <div>
        <h2>{title}</h2>
        {detail && <p>{detail}</p>}
      </div>
      {action}
    </div>
  )
}

function EmptyState({ text }) {
  return <div style={{ padding: '35px', textAlign: 'center', color: 'var(--text-muted)', fontSize: '12px' }}>{text}</div>
}

function Modal({ title, children, onClose }) {
  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <div className="modal" onMouseDown={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div>
            <span>MICROLEDGER / FORM</span>
            <h2>{title}</h2>
          </div>
          <button onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}

// -------------------------------------------------------------
// 1. Dashboard Component
// -------------------------------------------------------------
function Dashboard() {
  const [data, setData] = useState(null)
  const [recent, setRecent] = useState([])
  const [loading, setLoading] = useState(true)

  const loadData = () => {
    setLoading(true)
    Promise.all([api.dashboard(), api.repayments()])
      .then(([d, r]) => {
        setData(d)
        setRecent(Array.isArray(r) ? r.slice(0, 5) : [])
      })
      .catch((err) => console.error('Dashboard load error:', err))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    loadData()
  }, [])

  if (loading || !data) {
    return <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>Loading portfolio summary…</div>
  }

  const maxCollected = Math.max(...(data.collectionSeries || []).map((x) => x.collected), 1)

  return (
    <>
      <div className="metric-grid">
        <MetricCard
          label="Total Borrowers"
          value={data.borrowers.toLocaleString('en-IN')}
          change="Live"
          foot="Active registered members"
          icon={Users}
          tone="blue"
        />
        <MetricCard
          label="Active Loans"
          value={data.activeLoans.toLocaleString('en-IN')}
          change="Active"
          foot="Currently open"
          icon={Wallet}
          tone="violet"
        />
        <MetricCard
          label="Today's Collections"
          value={money(data.collections)}
          foot="Receipts posted today"
          icon={CircleDollarSign}
          tone="green"
        />
        <MetricCard
          label="Outstanding Portfolio"
          value={money(data.outstanding)}
          foot="Live principal balance"
          icon={Landmark}
          tone="amber"
        />
      </div>

      <div className="metric-grid metric-grid-small">
        <MetricCard
          label="Overdue / Delinquent"
          value={data.overdue}
          foot="Requiring follow-up"
          icon={CircleAlert}
          tone="red"
        />
        <MetricCard
          label="Portfolio at Risk (PAR)"
          value={`${data.par}%`}
          foot="Defaulted / delinquent %"
          icon={Activity}
          tone="teal"
        />
        <MetricCard
          label="Repayment Compliance"
          value={`${Math.max(0, 100 - parseFloat(data.par || 0)).toFixed(1)}%`}
          foot="Healthy account standing"
          icon={BadgeCheck}
          tone="green"
        />
      </div>

      <div className="dashboard-grid">
        <section className="panel chart-panel">
          <SectionTitle title="Weekly Collection Performance" detail="Daily receipts from field and branch collections" />
          <div className="bar-chart">
            {(data.collectionSeries || []).map((x) => (
              <div className="bar-column" key={x.day}>
                <span className="bar-value">₹{Math.round(x.collected)}</span>
                <div className="bar-track">
                  <div
                    className="bar-fill"
                    style={{ height: `${Math.min(100, (x.collected / maxCollected) * 100)}%` }}
                  />
                </div>
                <span className="bar-label">{x.day}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="panel portfolio-panel">
          <SectionTitle title="Waterfall Allocation" detail="Payment distribution by account head" />
          <div className="donut-wrap">
            <div className="donut">
              <div>
                <b>100%</b>
                <span>Waterfall</span>
              </div>
            </div>
          </div>
          <div className="allocation-list">
            <div>
              <i className="dot principal" />
              Principal <b>{data.allocations?.principalPct || 60}%</b>
            </div>
            <div>
              <i className="dot interest" />
              Interest <b>{data.allocations?.interestPct || 30}%</b>
            </div>
            <div>
              <i className="dot fees" />
              Fees <b>{data.allocations?.feesPct || 10}%</b>
            </div>
          </div>
        </section>
      </div>

      <section className="panel table-panel">
        <SectionTitle
          title="Recent Repayment Collections"
          detail="Latest receipts processed across field and branch channels"
          action={
            <NavLink className="text-link" to="/collections" style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--primary)', fontWeight: 700, textDecoration: 'none', fontSize: '11px' }}>
              Open Collection Desk <ChevronRight size={14} />
            </NavLink>
          }
        />
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Repayment ID</th>
                <th>Borrower</th>
                <th>Loan ID</th>
                <th>Amount</th>
                <th>Channel</th>
                <th>Received At</th>
              </tr>
            </thead>
            <tbody>
              {recent.map((r) => (
                <tr key={r.repayment_id}>
                  <td className="mono">#{r.repayment_id}</td>
                  <td className="strong-cell">{r.borrower_name}</td>
                  <td className="mono">Loan #{r.loan_id}</td>
                  <td className="amount credit">{money(r.amount)}</td>
                  <td>
                    <Status>{r.channel}</Status>
                  </td>
                  <td className="mono" style={{ fontSize: '10px' }}>
                    {new Date(r.received_at).toLocaleString('en-IN')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!recent.length && <EmptyState text="No collection activity recorded yet." />}
        </div>
      </section>
    </>
  )
}

// -------------------------------------------------------------
// 2. Borrowers & Groups Component
// -------------------------------------------------------------
function Borrowers() {
  const { showToast } = useContext(ToastContext)
  const [people, setPeople] = useState([])
  const [groupList, setGroupList] = useState([])
  const [centers, setCenters] = useState([])
  const [query, setQuery] = useState('')
  const [tab, setTab] = useState('borrowers')
  const [modal, setModal] = useState(false)
  const [exposureModal, setExposureModal] = useState(null)
  const [membersModal, setMembersModal] = useState(null)
  const [memberForm, setMemberForm] = useState({ borrowerId: '', memberRole: 'MEMBER' })
  const [deleteConfirm, setDeleteConfirm] = useState(null)
  const [form, setForm] = useState({
    fullName: '',
    phone: '',
    centerId: '',
    monthlyHouseholdIncome: '28000',
    idType: 'AADHAAR',
    idNumber: '',
  })
  const [groupForm, setGroupForm] = useState({
    name: '',
    centerId: '',
    maxExposure: '250000',
  })
  const [saving, setSaving] = useState(false)

  const loadData = () => {
    Promise.all([api.borrowers(), api.groups(), api.centers()]).then(([b, g, c]) => {
      setPeople(Array.isArray(b) ? b : [])
      setGroupList(Array.isArray(g) ? g : [])
      setCenters(Array.isArray(c) ? c : [])
      if (c && c.length > 0) {
        setForm((f) => ({ ...f, centerId: f.centerId || String(c[0].center_id) }))
        setGroupForm((gf) => ({ ...gf, centerId: gf.centerId || String(c[0].center_id) }))
      }
    })
  }

  useEffect(() => {
    loadData()
  }, [])

  const filtered = people.filter((p) =>
    `${p.full_name} ${p.borrower_id} ${p.phone}`.toLowerCase().includes(query.toLowerCase())
  )

  // Strict validation rules for borrower registration
  const isNameValid = form.fullName.trim().length >= 2 && form.fullName.trim().length <= 50
  const isPhoneValid = /^\d{10}$/.test(form.phone.trim())
  const isIdValid = form.idNumber.trim().length >= 10
  const isIncomeValid = !isNaN(parseFloat(form.monthlyHouseholdIncome)) && parseFloat(form.monthlyHouseholdIncome) > 0
  const isBorrowerFormValid = isNameValid && isPhoneValid && isIdValid && isIncomeValid && !!form.centerId

  const defaultGroupCode = useMemo(() => {
    const year = new Date().getFullYear()
    const nextNum = groupList.length + 1
    return `JLG-${year}-${String(nextNum).padStart(2, '0')}`
  }, [groupList.length])

  async function handleSaveBorrower(e) {
    e.preventDefault()
    if (!isBorrowerFormValid) {
      showToast('Please correct validation errors before saving.', 'error')
      return
    }
    setSaving(true)
    try {
      await api.createBorrower({
        centerId: parseInt(form.centerId || centers[0]?.center_id, 10),
        fullName: form.fullName.trim(),
        phone: form.phone.trim(),
        monthlyHouseholdIncome: parseFloat(form.monthlyHouseholdIncome),
        idType: form.idType,
        idNumber: form.idNumber.trim(),
      })
      showToast('Borrower registered successfully!', 'success')
      setModal(false)
      setForm({
        fullName: '',
        phone: '',
        centerId: centers[0]?.center_id || '',
        monthlyHouseholdIncome: '28000',
        idType: 'AADHAAR',
        idNumber: '',
      })
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function handleConfirmDeleteBorrower() {
    if (!deleteConfirm) return
    setSaving(true)
    try {
      const res = await api.deleteBorrower(deleteConfirm.borrower_id)
      showToast(res?.message || 'Borrower permanently deleted successfully!', 'success')
      setDeleteConfirm(null)
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function handleSaveGroup(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.createGroup({
        centerId: parseInt(groupForm.centerId || centers[0]?.center_id, 10),
        name: groupForm.name.trim() || defaultGroupCode,
        maxExposure: parseFloat(groupForm.maxExposure),
      })
      showToast('JLG Group created successfully!', 'success')
      setModal(false)
      setGroupForm({ name: '', centerId: centers[0]?.center_id || '', maxExposure: '250000' })
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function openExposureModal(groupId) {
    try {
      const exp = await api.groupExposure(groupId)
      setExposureModal(exp)
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  async function openMembersModal(group) {
    try {
      const members = await api.groupMembers(group.group_id)
      setMembersModal({ group, members: Array.isArray(members) ? members : [] })
      setMemberForm({ borrowerId: '', memberRole: 'MEMBER' })
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  async function handleAddGroupMember(e) {
    e.preventDefault()
    if (!membersModal || !memberForm.borrowerId) return
    setSaving(true)
    try {
      await api.addGroupMember(membersModal.group.group_id, {
        borrowerId: parseInt(memberForm.borrowerId, 10),
        memberRole: memberForm.memberRole,
      })
      showToast('Member added to JLG group successfully!', 'success')
      const updated = await api.groupMembers(membersModal.group.group_id)
      setMembersModal((prev) => ({ ...prev, members: updated }))
      setMemberForm({ borrowerId: '', memberRole: 'MEMBER' })
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function handleRemoveGroupMember(borrowerId) {
    if (!membersModal) return
    if (!window.confirm('Remove this member from the JLG group? Active loan balances must be cleared first.')) return
    setSaving(true)
    try {
      await api.deleteGroupMember(membersModal.group.group_id, borrowerId)
      showToast('Member removed from group successfully.', 'success')
      const updated = await api.groupMembers(membersModal.group.group_id)
      setMembersModal((prev) => ({ ...prev, members: updated }))
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <div className="toolbar">
        <div className="tabs">
          <button className={tab === 'borrowers' ? 'selected' : ''} onClick={() => setTab('borrowers')}>
            Borrowers <span>{people.length}</span>
          </button>
          <button className={tab === 'groups' ? 'selected' : ''} onClick={() => setTab('groups')}>
            JLG Groups <span>{groupList.length}</span>
          </button>
        </div>
        <PageActions>
          <Button
            onClick={() => {
              if (tab === 'groups') {
                setGroupForm((gf) => ({ ...gf, name: defaultGroupCode }))
              }
              setModal(true)
            }}
          >
            <Plus size={16} /> Add {tab === 'borrowers' ? 'Borrower' : 'JLG Group'}
          </Button>
        </PageActions>
      </div>

      {tab === 'borrowers' ? (
        <section className="panel table-panel">
          <div style={{ display: 'flex', gap: '10px', padding: '0 20px 14px' }}>
            <div className="search-box">
              <Search size={16} />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search name, phone, or borrower ID…"
              />
            </div>
          </div>
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Borrower ID</th>
                  <th>Full Name</th>
                  <th>Phone</th>
                  <th>Center ID</th>
                  <th>Monthly Household Income</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((p) => (
                  <tr key={p.borrower_id}>
                    <td className="mono">#{p.borrower_id}</td>
                    <td className="strong-cell">{p.full_name}</td>
                    <td>{p.phone || '—'}</td>
                    <td className="mono">Center #{p.center_id}</td>
                    <td className="amount">{money(p.monthly_household_income)}</td>
                    <td>
                      <Status>{p.status}</Status>
                    </td>
                    <td>
                      <Button
                        variant="secondary"
                        onClick={() => setDeleteConfirm(p)}
                        style={{ padding: '4px 8px', fontSize: '11px', color: '#ef4444' }}
                        title="Permanently delete borrower profile"
                      >
                        <Trash2 size={12} /> Delete
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!filtered.length && <EmptyState text="No borrowers found." />}
          </div>
        </section>
      ) : (
        <div className="group-grid">
          {groupList.map((g) => (
            <div className="panel group-card" key={g.group_id}>
              <div className="group-card-top">
                <div className="group-symbol">
                  <Users size={18} />
                </div>
                <Status>{g.status}</Status>
              </div>
              <h3>{g.name}</h3>
              <p>
                Group #{g.group_id} · Center: {g.center_name || `#${g.center_id}`}
              </p>
              <div className="group-stats">
                <div>
                  <b>{g.member_count || 0}</b>
                  <span>Members</span>
                </div>
                <div>
                  <b>{money(g.max_exposure)}</b>
                  <span>Exposure Cap</span>
                </div>
              </div>
              <div className="group-actions" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                <Button variant="secondary" onClick={() => openExposureModal(g.group_id)} style={{ width: '100%', fontSize: '11px', padding: '6px' }}>
                  <Eye size={13} /> Exposure
                </Button>
                <Button variant="secondary" onClick={() => openMembersModal(g)} style={{ width: '100%', fontSize: '11px', padding: '6px' }}>
                  <Users size={13} /> Members ({g.member_count || 0})
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Register Borrower / Group Modal */}
      {modal && (
        <Modal title={tab === 'borrowers' ? 'Register New Borrower' : 'Create JLG Group'} onClose={() => setModal(false)}>
          {tab === 'borrowers' ? (
            <form onSubmit={handleSaveBorrower} className="form-grid">
              <label className="full-field">
                Full Name (Max 50 Characters)
                <input
                  required
                  maxLength={50}
                  value={form.fullName}
                  onChange={(e) => setForm({ ...form, fullName: e.target.value.slice(0, 50) })}
                  placeholder="Enter full name (2 - 50 characters)"
                />
                {!isNameValid && form.fullName.length > 0 && (
                  <span style={{ fontSize: '10px', color: '#ef4444', marginTop: '3px' }}>
                    Full name must be between 2 and 50 characters.
                  </span>
                )}
              </label>

              <label>
                Mobile Number (Strictly 10 Digits)
                <input
                  required
                  maxLength={10}
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value.replace(/\D/g, '').slice(0, 10) })}
                  placeholder="10-digit mobile number"
                />
                {!isPhoneValid && form.phone.length > 0 && (
                  <span style={{ fontSize: '10px', color: '#ef4444', marginTop: '3px' }}>
                    Must be exactly 10 numeric digits.
                  </span>
                )}
              </label>

              <label>
                Meeting Center
                <select
                  value={form.centerId}
                  onChange={(e) => setForm({ ...form, centerId: e.target.value })}
                >
                  {centers.map((c) => (
                    <option key={c.center_id} value={c.center_id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                National ID Type
                <select
                  value={form.idType}
                  onChange={(e) => setForm({ ...form, idType: e.target.value })}
                >
                  <option value="AADHAAR">Aadhaar Card (12-digit UID)</option>
                  <option value="PAN">PAN Card (10-char Alphanumeric)</option>
                  <option value="VOTER_ID">Voter ID / EPIC Card</option>
                  <option value="DRIVING_LICENSE">Driving Licence (DL)</option>
                  <option value="RATION_CARD">Ration Card (NFSA)</option>
                  <option value="OTHER">Other Official Photo ID</option>
                </select>
              </label>

              <label>
                National ID Reference Number (Min 10 Chars)
                <input
                  required
                  value={form.idNumber}
                  onChange={(e) => setForm({ ...form, idNumber: e.target.value })}
                  placeholder="ID reference number (min 10 characters)"
                />
                {!isIdValid && form.idNumber.length > 0 && (
                  <span style={{ fontSize: '10px', color: '#ef4444', marginTop: '3px' }}>
                    ID reference must be at least 10 characters long.
                  </span>
                )}
              </label>

              <label className="full-field">
                Monthly Household Income (₹)
                <input
                  type="number"
                  min="5000"
                  step="500"
                  required
                  value={form.monthlyHouseholdIncome}
                  onChange={(e) => setForm({ ...form, monthlyHouseholdIncome: e.target.value })}
                />
                {!isIncomeValid && (
                  <span style={{ fontSize: '10px', color: '#ef4444', marginTop: '3px' }}>
                    Valid positive household income required for RBI FOIR limit validation.
                  </span>
                )}
              </label>

              <div className="form-actions">
                <Button variant="secondary" type="button" onClick={() => setModal(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={!isBorrowerFormValid || saving}>
                  <Check size={15} /> {saving ? 'Saving…' : 'Save Borrower'}
                </Button>
              </div>
            </form>
          ) : (
            <form onSubmit={handleSaveGroup} className="form-grid">
              <label className="full-field">
                Standard JLG Group Code / Name
                <input
                  required
                  value={groupForm.name || defaultGroupCode}
                  onChange={(e) => setGroupForm({ ...groupForm, name: e.target.value })}
                  placeholder="Standardized Group Code (e.g. JLG-2026-11)"
                />
                <span style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '3px' }}>
                  Standard system format auto-generated.
                </span>
              </label>
              <label>
                Village Center
                <select
                  value={groupForm.centerId}
                  onChange={(e) => setGroupForm({ ...groupForm, centerId: e.target.value })}
                >
                  {centers.map((c) => (
                    <option key={c.center_id} value={c.center_id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Maximum Exposure Cap (₹)
                <input
                  type="number"
                  min="10000"
                  step="10000"
                  required
                  value={groupForm.maxExposure}
                  onChange={(e) => setGroupForm({ ...groupForm, maxExposure: e.target.value })}
                />
              </label>
              <div className="form-actions">
                <Button variant="secondary" type="button" onClick={() => setModal(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={saving}>
                  <Check size={15} /> {saving ? 'Creating…' : 'Create Group'}
                </Button>
              </div>
            </form>
          )}
        </Modal>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <Modal title="Confirm Permanent Deletion" onClose={() => setDeleteConfirm(null)}>
          <div style={{ padding: '4px 0 16px' }}>
            <p style={{ fontSize: '13px', lineHeight: '1.5', margin: '0 0 12px' }}>
              Are you sure you want to permanently delete borrower <b>{deleteConfirm.full_name}</b> (ID #{deleteConfirm.borrower_id})?
            </p>
            <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: '6px', padding: '10px 12px', fontSize: '11px', color: '#ef4444' }}>
              <b>Permanent Action:</b> This removes the member profile and non-active records. Borrowers with active unpaid loans cannot be deleted until all dues are cleared.
            </div>
          </div>
          <div className="form-actions">
            <Button variant="secondary" onClick={() => setDeleteConfirm(null)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirmDeleteBorrower}
              disabled={saving}
              style={{ background: '#ef4444', borderColor: '#ef4444' }}
            >
              <Trash2 size={14} /> {saving ? 'Deleting…' : 'Permanently Delete'}
            </Button>
          </div>
        </Modal>
      )}

      {/* JLG Group Members Management Modal */}
      {membersModal && (
        <Modal title={`Manage Members: ${membersModal.group.name}`} onClose={() => setMembersModal(null)}>
          <div style={{ marginBottom: '14px', background: 'var(--bg-subtle)', padding: '10px 12px', borderRadius: '6px', fontSize: '11px', color: 'var(--text-muted)' }}>
            <b>JLG Peer Rules:</b> Each borrower may belong to a maximum of 3 groups. Solo borrowers carry zero cross-group liability.
          </div>

          <div className="table-scroll" style={{ maxHeight: '240px', marginBottom: '18px' }}>
            <table>
              <thead>
                <tr>
                  <th>Member Name</th>
                  <th>Mobile</th>
                  <th>Role</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {(membersModal.members || []).map((m) => (
                  <tr key={m.borrower_id}>
                    <td className="strong-cell">
                      {m.full_name}
                      <span className="mono" style={{ fontSize: '10px', display: 'block', color: 'var(--text-muted)' }}>
                        #{m.borrower_id}
                      </span>
                    </td>
                    <td>{m.phone || '—'}</td>
                    <td>
                      <Status>{m.member_role || 'MEMBER'}</Status>
                    </td>
                    <td>
                      <Button
                        variant="secondary"
                        onClick={() => handleRemoveGroupMember(m.borrower_id)}
                        disabled={saving}
                        style={{ padding: '3px 6px', fontSize: '10px', color: '#ef4444' }}
                        title="Remove member from this group"
                      >
                        <Trash2 size={11} /> Remove
                      </Button>
                    </td>
                  </tr>
                ))}
                {(!membersModal.members || membersModal.members.length === 0) && (
                  <tr>
                    <td colSpan={4} style={{ textAlign: 'center', padding: '16px', color: 'var(--text-muted)' }}>
                      No members in this group yet. Add members below.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <form onSubmit={handleAddGroupMember} style={{ borderTop: '1px solid var(--border-color)', paddingTop: '14px' }}>
            <b style={{ fontSize: '12px', display: 'block', marginBottom: '8px' }}>Add Member to Group</b>
            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr auto', gap: '8px', alignItems: 'end' }}>
              <label style={{ fontSize: '11px' }}>
                Select Borrower
                <select
                  required
                  value={memberForm.borrowerId}
                  onChange={(e) => setMemberForm({ ...memberForm, borrowerId: e.target.value })}
                  style={{ height: '34px', fontSize: '11px' }}
                >
                  <option value="">-- Choose Borrower --</option>
                  {people
                    .filter((p) => !membersModal.members.some((m) => String(m.borrower_id) === String(p.borrower_id)))
                    .map((b) => (
                      <option key={b.borrower_id} value={b.borrower_id}>
                        {b.full_name} (#{b.borrower_id})
                      </option>
                    ))}
                </select>
              </label>

              <label style={{ fontSize: '11px' }}>
                Member Role
                <select
                  value={memberForm.memberRole}
                  onChange={(e) => setMemberForm({ ...memberForm, memberRole: e.target.value })}
                  style={{ height: '34px', fontSize: '11px' }}
                >
                  <option value="MEMBER">Group Member</option>
                  <option value="PRESIDENT">President</option>
                  <option value="SECRETARY">Secretary</option>
                </select>
              </label>

              <Button type="submit" disabled={!memberForm.borrowerId || saving} style={{ height: '34px', padding: '0 12px', fontSize: '11px' }}>
                <Plus size={14} /> Add
              </Button>
            </div>
          </form>

          <div className="form-actions" style={{ marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => setMembersModal(null)}>
              Done
            </Button>
          </div>
        </Modal>
      )}

      {/* Group Exposure Modal */}
      {exposureModal && (
        <Modal title={`Guarantee Exposure: ${exposureModal.groupName}`} onClose={() => setExposureModal(null)}>
          <div style={{ marginBottom: '16px', display: 'flex', gap: '20px', background: 'var(--bg-subtle)', padding: '14px', borderRadius: '8px' }}>
            <div>
              <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>Total Group Exposure:</span>
              <b style={{ display: 'block', fontSize: '17px', color: exposureModal.exceedsCap ? 'var(--danger)' : 'var(--text-main)' }}>
                {money(exposureModal.totalGroupExposure ?? exposureModal.totalExposure)}
              </b>
            </div>
            <div>
              <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>Exposure Cap:</span>
              <b style={{ display: 'block', fontSize: '17px' }}>{money(exposureModal.maxExposure)}</b>
            </div>
            {exposureModal.exceedsCap && (
              <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--danger)', fontWeight: 700, fontSize: '11px' }}>
                <ShieldAlert size={18} /> CAP EXCEEDED (Disbursement Blocked)
              </div>
            )}
          </div>
          <table style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Member</th>
                <th>Borrower ID</th>
                <th>Exposure Amount</th>
                <th>Source Loan</th>
                <th>Propagation Depth</th>
              </tr>
            </thead>
            <tbody>
              {(exposureModal.members || []).map((m, idx) => (
                <tr key={idx}>
                  <td className="strong-cell">{m.fullName || m.full_name}</td>
                  <td className="mono">#{m.borrowerId || m.borrower_id}</td>
                  <td className="amount">{money(m.exposureAmount ?? m.exposure_amount)}</td>
                  <td className="mono">{m.sourceLoanId || m.source_loan_id ? `#${m.sourceLoanId || m.source_loan_id}` : '—'}</td>
                  <td>{m.depth ? `Depth ${m.depth}` : '0'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="form-actions" style={{ marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => setExposureModal(null)}>
              Close
            </Button>
          </div>
        </Modal>
      )}
    </>
  )
}

// -------------------------------------------------------------
// 3. Loans Management Component
// -------------------------------------------------------------
function Loans() {
  const { showToast } = useContext(ToastContext)
  const [items, setItems] = useState([])
  const [borrowersList, setBorrowersList] = useState([])
  const [groupsList, setGroupsList] = useState([])
  const [query, setQuery] = useState('')
  const [modal, setModal] = useState(false)
  const [scheduleModal, setScheduleModal] = useState(null)
  const [guaranteeModal, setGuaranteeModal] = useState(null)
  const [addGuaranteeForm, setAddGuaranteeForm] = useState({ guarantorId: '', sharePct: '25' })
  const [form, setForm] = useState({
    borrowerId: '',
    groupId: '',
    cycleNo: '1',
    principal: '30000',
    annualRate: '18',
    tenureWeeks: '25',
  })
  const [busyId, setBusyId] = useState(null)

  const loadData = () => {
    Promise.all([api.loans(), api.borrowers(), api.groups()]).then(([l, b, g]) => {
      setItems(Array.isArray(l) ? l : [])
      setBorrowersList(Array.isArray(b) ? b : [])
      setGroupsList(Array.isArray(g) ? g : [])
      if (b && b.length > 0) setForm((f) => ({ ...f, borrowerId: f.borrowerId || String(b[0].borrower_id) }))
      if (g && g.length > 0) setForm((f) => ({ ...f, groupId: f.groupId || String(g[0].group_id) }))
    })
  }

  useEffect(() => {
    loadData()
  }, [])

  const filtered = items.filter((l) =>
    `${l.loan_id} ${l.borrower_name} ${l.group_name}`.toLowerCase().includes(query.toLowerCase())
  )

  async function handleCreateLoan(e) {
    e.preventDefault()
    try {
      await api.createLoan({
        borrowerId: parseInt(form.borrowerId, 10),
        groupId: parseInt(form.groupId, 10),
        cycleNo: parseInt(form.cycleNo, 10),
        principal: parseFloat(form.principal),
        annualRate: parseFloat(form.annualRate),
        tenureWeeks: parseInt(form.tenureWeeks, 10),
      })
      showToast('Loan originated successfully in PENDING status!', 'success')
      setModal(false)
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  async function handleDisburse(loanId) {
    setBusyId(loanId)
    try {
      await api.disburseLoan(loanId)
      showToast(`Loan #${loanId} disbursed! Repayment schedule generated.`, 'success')
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setBusyId(null)
    }
  }

  async function openInstallments(loanId) {
    try {
      const inst = await api.loanInstallments(loanId)
      setScheduleModal({ loanId, installments: inst })
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  async function openGuarantees(loanId, groupId) {
    try {
      const g = await api.loanGuarantees(loanId)
      const members = await api.groupMembers(groupId)
      setGuaranteeModal({ loanId, groupId, guarantees: g, groupMembers: members })
      if (members && members.length > 0) {
        setAddGuaranteeForm({ guarantorId: String(members[0].borrower_id), sharePct: '25' })
      }
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  async function handleAddGuarantee(e) {
    e.preventDefault()
    try {
      await api.addLoanGuarantee(guaranteeModal.loanId, {
        guarantorId: parseInt(addGuaranteeForm.guarantorId, 10),
        sharePct: parseFloat(addGuaranteeForm.sharePct),
      })
      showToast('Co-guarantor registered successfully!', 'success')
      openGuarantees(guaranteeModal.loanId, guaranteeModal.groupId)
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  return (
    <>
      <div className="summary-strip">
        <div>
          <span>Total Active Accounts</span>
          <b>{items.filter((x) => x.status === 'ACTIVE').length}</b>
        </div>
        <div>
          <span>Pending Disbursals</span>
          <b>{items.filter((x) => x.status === 'PENDING').length}</b>
        </div>
        <div>
          <span>Overdue / Delinquent</span>
          <b>{items.filter((x) => x.status === 'DELINQUENT' || x.status === 'DEFAULTED').length}</b>
        </div>
        <div>
          <span>Total Principal Issued</span>
          <b>{money(items.reduce((s, x) => s + parseFloat(x.principal || 0), 0))}</b>
        </div>
      </div>

      <div className="toolbar">
        <div className="search-box">
          <Search size={16} />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search loan ID, borrower, or JLG group…"
          />
        </div>
        <PageActions>
          <Button onClick={() => setModal(true)}>
            <Plus size={16} /> Originate New Loan
          </Button>
        </PageActions>
      </div>

      <section className="panel table-panel">
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Loan ID</th>
                <th>Borrower & Group</th>
                <th>Principal</th>
                <th>Outstanding</th>
                <th>Dues (Interest/Fees)</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((l) => (
                <tr key={l.loan_id}>
                  <td className="mono">#{l.loan_id}</td>
                  <td>
                    <b>{l.borrower_name}</b>
                    <small className="sub-cell" style={{ display: 'block', color: 'var(--text-muted)' }}>
                      {l.group_name} · Cycle {l.cycle_no}
                    </small>
                  </td>
                  <td className="amount">{money(l.principal)}</td>
                  <td className="amount">{money(l.outstanding_principal)}</td>
                  <td>
                    {money(parseFloat(l.fees_due || 0) + parseFloat(l.overdue_interest_due || 0) + parseFloat(l.current_interest_due || 0))}
                  </td>
                  <td>
                    <Status>{l.status}</Status>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '6px' }}>
                      {l.status === 'PENDING' && (
                        <Button
                          variant="primary"
                          onClick={() => handleDisburse(l.loan_id)}
                          disabled={busyId === l.loan_id}
                          style={{ padding: '5px 9px', fontSize: '10px' }}
                        >
                          <Zap size={13} /> Disburse
                        </Button>
                      )}
                      <Button
                        variant="secondary"
                        onClick={() => openInstallments(l.loan_id)}
                        style={{ padding: '5px 9px', fontSize: '10px' }}
                      >
                        <CalendarDays size={13} /> Schedule
                      </Button>
                      <Button
                        variant="secondary"
                        onClick={() => openGuarantees(l.loan_id, l.group_id)}
                        style={{ padding: '5px 9px', fontSize: '10px' }}
                      >
                        <ShieldCheck size={13} /> Guarantees
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!filtered.length && <EmptyState text="No loans found." />}
        </div>
      </section>

      {/* Originate Loan Modal */}
      {modal && (
        <Modal title="Originate Loan Application" onClose={() => setModal(false)}>
          <form onSubmit={handleCreateLoan} className="form-grid">
            <label className="full-field">
              Borrower
              <select
                required
                value={form.borrowerId}
                onChange={(e) => setForm({ ...form, borrowerId: e.target.value })}
              >
                {borrowersList.map((b) => (
                  <option key={b.borrower_id} value={b.borrower_id}>
                    #{b.borrower_id} - {b.full_name} (Income: ₹{b.monthly_household_income}/mo)
                  </option>
                ))}
              </select>
            </label>
            <label>
              JLG Group
              <select
                required
                value={form.groupId}
                onChange={(e) => setForm({ ...form, groupId: e.target.value })}
              >
                {groupsList.map((g) => (
                  <option key={g.group_id} value={g.group_id}>
                    #{g.group_id} - {g.name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Loan Cycle Number
              <input
                type="number"
                min="1"
                required
                value={form.cycleNo}
                onChange={(e) => setForm({ ...form, cycleNo: e.target.value })}
              />
            </label>
            <label>
              Principal Amount (₹)
              <input
                type="number"
                min="1000"
                step="1000"
                required
                value={form.principal}
                onChange={(e) => setForm({ ...form, principal: e.target.value })}
              />
            </label>
            <label>
              Annual Interest Rate (%)
              <input
                type="number"
                min="0"
                step="0.1"
                required
                value={form.annualRate}
                onChange={(e) => setForm({ ...form, annualRate: e.target.value })}
              />
            </label>
            <label className="full-field">
              Tenure (Weeks)
              <input
                type="number"
                min="4"
                max="104"
                required
                value={form.tenureWeeks}
                onChange={(e) => setForm({ ...form, tenureWeeks: e.target.value })}
              />
            </label>
            <div className="full-field" style={{ background: 'var(--bg-subtle)', padding: '12px', borderRadius: '8px', fontSize: '11px', color: 'var(--text-muted)' }}>
              <CircleAlert size={15} style={{ display: 'inline', marginRight: '6px' }} />
              Disbursement is protected by responsible lending debt ceilings and group exposure limits.
            </div>
            <div className="form-actions">
              <Button variant="secondary" type="button" onClick={() => setModal(false)}>
                Cancel
              </Button>
              <Button type="submit">Originate Loan</Button>
            </div>
          </form>
        </Modal>
      )}

      {/* Installment Schedule Modal */}
      {scheduleModal && (
        <Modal title={`Repayment Schedule: Loan #${scheduleModal.loanId}`} onClose={() => setScheduleModal(null)}>
          <div className="table-scroll" style={{ maxHeight: '420px' }}>
            <table>
              <thead>
                <tr>
                  <th>Seq</th>
                  <th>Due Date</th>
                  <th>Principal</th>
                  <th>Interest</th>
                  <th>Fee</th>
                  <th>Paid Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {scheduleModal.installments.map((i) => (
                  <tr key={i.installment_id}>
                    <td className="mono">#{i.seq_no}</td>
                    <td>{i.due_date}</td>
                    <td className="amount">{money(i.principal_due)}</td>
                    <td className="amount">{money(parseFloat(i.current_interest_due) + parseFloat(i.arrears_interest_due))}</td>
                    <td className="amount">{money(i.fee_due)}</td>
                    <td className="amount credit">{money(i.paid_total)}</td>
                    <td>
                      <Status>{i.status}</Status>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="form-actions" style={{ marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => setScheduleModal(null)}>
              Close
            </Button>
          </div>
        </Modal>
      )}

      {/* Guarantees Modal */}
      {guaranteeModal && (
        <Modal title={`Peer Guarantees: Loan #${guaranteeModal.loanId}`} onClose={() => setGuaranteeModal(null)}>
          <div style={{ marginBottom: '18px' }}>
            <b>Active Cross-Guarantors</b>
            <table style={{ width: '100%', marginTop: '8px' }}>
              <thead>
                <tr>
                  <th>Guarantor</th>
                  <th>Phone</th>
                  <th>Share %</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {guaranteeModal.guarantees.map((g) => (
                  <tr key={g.guarantee_id}>
                    <td className="strong-cell">{g.guarantor_name}</td>
                    <td>{g.phone || '—'}</td>
                    <td className="mono">{g.share_pct}%</td>
                    <td>
                      <Status>{g.active ? 'Active' : 'Inactive'}</Status>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!guaranteeModal.guarantees.length && <EmptyState text="No guarantees currently assigned." />}
          </div>

          <form onSubmit={handleAddGuarantee} className="form-grid" style={{ borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
            <div className="full-field" style={{ fontSize: '12px', fontWeight: 700 }}>
              Add / Update Guarantor (Max Cumulative Share: 100%)
            </div>
            <label>
              Select Group Member
              <select
                value={addGuaranteeForm.guarantorId}
                onChange={(e) => setAddGuaranteeForm({ ...addGuaranteeForm, guarantorId: e.target.value })}
              >
                {guaranteeModal.groupMembers.map((m) => (
                  <option key={m.borrower_id} value={m.borrower_id}>
                    {m.full_name} ({m.member_role})
                  </option>
                ))}
              </select>
            </label>
            <label>
              Guarantee Share (%)
              <input
                type="number"
                min="1"
                max="100"
                step="1"
                value={addGuaranteeForm.sharePct}
                onChange={(e) => setAddGuaranteeForm({ ...addGuaranteeForm, sharePct: e.target.value })}
              />
            </label>
            <div className="form-actions">
              <Button type="submit">Save Guarantee</Button>
            </div>
          </form>
        </Modal>
      )}
    </>
  )
}

// -------------------------------------------------------------
// 4. Repayments & Collections Component
// -------------------------------------------------------------
function Collections() {
  const { showToast } = useContext(ToastContext)
  const [items, setItems] = useState([])
  const [loansData, setLoansData] = useState([])
  const [modal, setModal] = useState(false)
  const [batchModal, setBatchModal] = useState(false)
  const [batchItems, setBatchItems] = useState([])
  const [reversingId, setReversingId] = useState(null)
  const [form, setForm] = useState({
    loanId: '',
    amount: '',
    channel: 'FIELD',
    paidByName: '',
    payerRelation: 'SELF',
  })
  const [saving, setSaving] = useState(false)

  const loadData = () => {
    Promise.all([api.repayments(), api.loans()]).then(([r, l]) => {
      setItems(Array.isArray(r) ? r : [])
      const active = (Array.isArray(l) ? l : []).filter((x) => x.status === 'ACTIVE' || x.status === 'DELINQUENT')
      setLoansData(active)
      if (active.length > 0) {
        setForm((f) => ({
          ...f,
          loanId: f.loanId || String(active[0].loan_id),
          paidByName: f.paidByName || active[0].borrower_name,
        }))
      }
    })
  }

  useEffect(() => {
    loadData()
  }, [])

  const selectedLoan = useMemo(() => {
    return loansData.find((l) => String(l.loan_id) === String(form.loanId)) || loansData[0] || null
  }, [loansData, form.loanId])

  async function handlePostPayment(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.postRepayment({
        loanId: parseInt(form.loanId, 10),
        amount: parseFloat(form.amount),
        channel: form.channel,
        expectedVersion: selectedLoan ? parseInt(selectedLoan.version, 10) : 0,
        paidByName: (form.paidByName || selectedLoan?.borrower_name || '').trim(),
        payerRelation: form.payerRelation || 'SELF',
      })
      showToast('Repayment posted atomically & recorded in ledger!', 'success')
      setModal(false)
      setForm({
        loanId: loansData[0]?.loan_id || '',
        amount: '',
        channel: 'FIELD',
        paidByName: loansData[0]?.borrower_name || '',
        payerRelation: 'SELF',
      })
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function handleReversePayment(repaymentId) {
    if (!window.confirm(`Reverse repayment #${repaymentId}? This will post mirror debit/credit entries to the append-only ledger and restore installment dues.`)) {
      return
    }
    setReversingId(repaymentId)
    try {
      await api.reverseRepayment(repaymentId)
      showToast(`Repayment #${repaymentId} reversed successfully!`, 'success')
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setReversingId(null)
    }
  }

  function openBatchModal() {
    setBatchItems(
      loansData.map((l) => ({
        loanId: l.loan_id,
        borrowerName: l.borrower_name,
        groupName: l.group_name,
        outstanding: l.outstanding_principal,
        version: l.version,
        amount: '600',
        channel: 'FIELD',
        paidByName: l.borrower_name,
        payerRelation: 'SELF',
      }))
    )
    setBatchModal(true)
  }

  async function handleBatchSubmit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      const collections = batchItems
        .filter((item) => parseFloat(item.amount) > 0)
        .map((item, idx) => ({
          loanId: item.loanId,
          amount: parseFloat(item.amount),
          channel: item.channel,
          expectedVersion: parseInt(item.version, 10),
          paidByName: (item.paidByName || item.borrowerName).trim(),
          payerRelation: item.payerRelation || 'SELF',
          idempotencyKey: `batch_${Date.now()}_${idx}_${Math.random().toString(36).substring(2, 7)}`,
        }))

      const res = await api.postBatchRepayments(collections)
      showToast(`Meeting Batch processed: ${res.successful} payments successful (${res.failed} failed).`, 'success')
      setBatchModal(false)
      loadData()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <div className="toolbar">
        <div>
          <b style={{ fontSize: '15px' }}>Collection Desk</b>
          <p style={{ margin: '2px 0 0', fontSize: '12px', color: 'var(--text-muted)' }}>
            Automated waterfall accounting, instant receipt generation, and real-time ledger settlement.
          </p>
        </div>
        <PageActions>
          <Button variant="secondary" onClick={openBatchModal}>
            <Users size={15} /> Center Meeting Bulk Collection
          </Button>
          <Button
            onClick={() => {
              if (loansData.length > 0) {
                setForm((f) => ({
                  ...f,
                  loanId: String(loansData[0].loan_id),
                  paidByName: loansData[0].borrower_name,
                }))
              }
              setModal(true)
            }}
          >
            <Plus size={15} /> Record Single Repayment
          </Button>
        </PageActions>
      </div>

      <div className="summary-strip">
        <div>
          <span>Total Transactions</span>
          <b>{items.length}</b>
        </div>
        <div>
          <span>Field Collections</span>
          <b>{items.filter((x) => x.channel === 'FIELD').length}</b>
        </div>
        <div>
          <span>Branch Collections</span>
          <b>{items.filter((x) => x.channel === 'BRANCH').length}</b>
        </div>
        <div>
          <span>Total Collected (Listed)</span>
          <b>{money(items.reduce((s, x) => s + parseFloat(x.amount || 0), 0))}</b>
        </div>
      </div>

      <section className="panel table-panel">
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Repayment ID</th>
                <th>Beneficiary (Borrower)</th>
                <th>Paid By & Relation</th>
                <th>Loan Account</th>
                <th>Amount</th>
                <th>Channel</th>
                <th>Received At</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {items.map((r) => (
                <tr key={r.repayment_id}>
                  <td className="mono">#{r.repayment_id}</td>
                  <td className="strong-cell">{r.borrower_name}</td>
                  <td>
                    <div style={{ fontSize: '12px', fontWeight: 600 }}>{r.paid_by_name || r.borrower_name}</div>
                    <div style={{ fontSize: '10px', color: 'var(--text-muted)' }}>
                      {r.payer_relation === 'SELF'
                        ? 'Self (Borrower)'
                        : r.payer_relation === 'CO_GUARANTOR'
                        ? 'Co-Guarantor Peer'
                        : r.payer_relation === 'FAMILY_MEMBER'
                        ? 'Family Member'
                        : r.payer_relation === 'REPRESENTATIVE'
                        ? 'Group Leader'
                        : r.payer_relation || 'Self'}
                    </div>
                  </td>
                  <td className="mono">Loan #{r.loan_id}</td>
                  <td className="amount credit">{money(r.amount)}</td>
                  <td>
                    <Status>{r.channel}</Status>
                  </td>
                  <td className="mono" style={{ fontSize: '10px' }}>
                    {new Date(r.received_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}{' '}
                    {new Date(r.received_at).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
                  </td>
                  <td>
                    <Button
                      variant="secondary"
                      onClick={() => handleReversePayment(r.repayment_id)}
                      disabled={reversingId === r.repayment_id}
                      style={{ padding: '4px 8px', fontSize: '10px' }}
                      title="Post reversing mirror entry to restore dues"
                    >
                      <RotateCcw size={12} /> Reverse
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!items.length && <EmptyState text="No repayments posted yet." />}
        </div>
      </section>

      {/* Record Repayment Modal */}
      {modal && (
        <Modal title="Record Single Repayment" onClose={() => setModal(false)}>
          <form onSubmit={handlePostPayment} className="form-grid">
            <label className="full-field">
              Select Loan Account
              <select
                required
                value={form.loanId}
                onChange={(e) => {
                  const newLoanId = e.target.value
                  const found = loansData.find((l) => String(l.loan_id) === String(newLoanId))
                  setForm({
                    ...form,
                    loanId: newLoanId,
                    paidByName: found?.borrower_name || form.paidByName,
                  })
                }}
              >
                {loansData.map((l) => (
                  <option key={l.loan_id} value={l.loan_id}>
                    Loan #{l.loan_id} · {l.borrower_name} · Outstanding: {money(l.outstanding_principal)}
                  </option>
                ))}
              </select>
            </label>

            <div
              className="full-field"
              style={{
                background: 'var(--bg-subtle)',
                padding: '10px 14px',
                borderRadius: '6px',
                fontSize: '11px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <div>
                <span style={{ color: 'var(--text-muted)', display: 'block', fontSize: '10px' }}>
                  On Whose Behalf (Beneficiary):
                </span>
                <b style={{ fontSize: '13px' }}>{selectedLoan?.borrower_name || '—'}</b>
                <span style={{ fontSize: '10px', color: 'var(--text-muted)', marginLeft: '6px' }}>
                  ({selectedLoan?.group_name || 'Individual'})
                </span>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{ color: 'var(--text-muted)', display: 'block', fontSize: '10px' }}>
                  Outstanding Balance:
                </span>
                <b className="amount" style={{ fontSize: '13px' }}>
                  {money(selectedLoan?.outstanding_principal)}
                </b>
              </div>
            </div>

            <label>
              Who Made Payment (Payer Full Name)
              <input
                required
                value={form.paidByName}
                onChange={(e) => setForm({ ...form, paidByName: e.target.value })}
                placeholder="Name of person handing over payment"
              />
            </label>

            <label>
              Payer Relationship to Borrower
              <select
                value={form.payerRelation}
                onChange={(e) => setForm({ ...form, payerRelation: e.target.value })}
              >
                <option value="SELF">Self (Borrower)</option>
                <option value="CO_GUARANTOR">JLG Co-Guarantor Peer</option>
                <option value="FAMILY_MEMBER">Spouse / Family Member</option>
                <option value="REPRESENTATIVE">Center / Group Leader</option>
                <option value="OTHER">Other Authorized Representative</option>
              </select>
            </label>

            <label>
              Payment Amount (₹)
              <input
                type="number"
                min="1"
                step="0.01"
                required
                value={form.amount}
                onChange={(e) => setForm({ ...form, amount: e.target.value })}
                placeholder="Enter amount"
              />
            </label>

            <label>
              Payment Channel
              <select
                value={form.channel}
                onChange={(e) => setForm({ ...form, channel: e.target.value })}
              >
                <option value="FIELD">Field Officer Collection</option>
                <option value="BRANCH">Branch Counter Cashier</option>
                <option value="ONLINE">Online UPI Transfer</option>
              </select>
            </label>

            <div
              className="full-field"
              style={{
                background: 'var(--bg-subtle)',
                padding: '12px',
                borderRadius: '8px',
                fontSize: '11px',
                color: 'var(--text-muted)',
              }}
            >
              <b>Waterfall Allocation Rules:</b> Repayments apply chronologically: Fees &rarr; Overdue Interest &rarr; Current Interest &rarr; Principal.
            </div>

            <div className="form-actions">
              <Button variant="secondary" type="button" onClick={() => setModal(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={saving}>
                {saving ? 'Posting…' : 'Submit & Post Ledger'}
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* Center Meeting Bulk Collection Modal */}
      {batchModal && (
        <Modal title="Center Meeting Bulk Collection" onClose={() => setBatchModal(false)}>
          <form onSubmit={handleBatchSubmit}>
            <p style={{ fontSize: '11px', color: 'var(--text-muted)', marginBottom: '14px' }}>
              Submit multiple member repayments collected during the weekly center meeting in a single batch.
            </p>
            <div className="table-scroll" style={{ maxHeight: '350px' }}>
              <table>
                <thead>
                  <tr>
                    <th>Loan</th>
                    <th>Beneficiary</th>
                    <th>Outstanding</th>
                    <th>Collection (₹)</th>
                    <th>Paid By</th>
                    <th>Relation</th>
                  </tr>
                </thead>
                <tbody>
                  {batchItems.map((item, idx) => (
                    <tr key={item.loanId}>
                      <td className="mono">#{item.loanId}</td>
                      <td className="strong-cell">{item.borrowerName}</td>
                      <td className="amount">{money(item.outstanding)}</td>
                      <td>
                        <input
                          type="number"
                          min="0"
                          step="10"
                          style={{ width: '85px', height: '30px', padding: '0 6px', fontSize: '11px' }}
                          value={item.amount}
                          onChange={(e) => {
                            const val = e.target.value
                            setBatchItems((prev) =>
                              prev.map((it, i) => (i === idx ? { ...it, amount: val } : it))
                            )
                          }}
                        />
                      </td>
                      <td>
                        <input
                          type="text"
                          style={{ width: '110px', height: '30px', padding: '0 6px', fontSize: '11px' }}
                          value={item.paidByName ?? item.borrowerName}
                          onChange={(e) => {
                            const val = e.target.value
                            setBatchItems((prev) =>
                              prev.map((it, i) => (i === idx ? { ...it, paidByName: val } : it))
                            )
                          }}
                          placeholder="Payer Name"
                        />
                      </td>
                      <td>
                        <select
                          style={{ width: '105px', height: '30px', padding: '0 4px', fontSize: '10px' }}
                          value={item.payerRelation || 'SELF'}
                          onChange={(e) => {
                            const val = e.target.value
                            setBatchItems((prev) =>
                              prev.map((it, i) => (i === idx ? { ...it, payerRelation: val } : it))
                            )
                          }}
                        >
                          <option value="SELF">Self</option>
                          <option value="CO_GUARANTOR">Co-Guarantor</option>
                          <option value="FAMILY_MEMBER">Family</option>
                          <option value="REPRESENTATIVE">Group Leader</option>
                          <option value="OTHER">Other</option>
                        </select>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="form-actions" style={{ marginTop: '16px' }}>
              <Button variant="secondary" type="button" onClick={() => setBatchModal(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={saving}>
                {saving ? 'Processing Batch…' : 'Submit All Collections'}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </>
  )
}

// -------------------------------------------------------------
// 5. Transaction Ledger & Integrity Component
// -------------------------------------------------------------
function Ledger() {
  const { showToast } = useContext(ToastContext)
  const [items, setItems] = useState([])
  const [verification, setVerification] = useState(null)
  const [verifying, setVerifying] = useState(false)

  const loadData = () => {
    api.ledger().then((entries) => setItems(Array.isArray(entries) ? entries : []))
  }

  useEffect(() => {
    loadData()
  }, [])

  async function handleVerify() {
    setVerifying(true)
    try {
      const res = await api.verifyLedger()
      setVerification(res)
      if (res.valid) {
        showToast('All journal accounts and transaction balances verified 100% balanced!', 'success')
      } else {
        showToast('Audit reconciliation found a discrepancy.', 'error')
      }
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setVerifying(false)
    }
  }

  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', padding: '20px 24px', marginBottom: '18px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: 'var(--primary-light)', color: 'var(--primary)', display: 'grid', placeItems: 'center' }}>
            <FileCheck2 size={24} />
          </div>
          <div>
            <b style={{ fontSize: '15px' }}>Financial Audit Journal &amp; Reconciliation</b>
            <p style={{ margin: '3px 0 0', fontSize: '12px', color: 'var(--text-muted)' }}>
              Certified double-entry accounting records with automatic tamper detection and permanent audit trail.
            </p>
          </div>
        </div>
        <Button onClick={handleVerify} disabled={verifying}>
          <ShieldCheck size={16} /> {verifying ? 'Reconciling Accounts…' : 'Run Audit Reconciliation'}
        </Button>
      </div>

      {verification && (
        <div style={{ padding: '16px 20px', borderRadius: 'var(--radius-md)', marginBottom: '18px', background: verification.valid ? 'var(--success-bg)' : 'var(--danger-bg)', border: `1px solid ${verification.valid ? 'var(--success)' : 'var(--danger)'}`, display: 'flex', alignItems: 'center', gap: '12px' }}>
          {verification.valid ? <BadgeCheck size={22} color="var(--success)" /> : <CircleAlert size={22} color="var(--danger)" />}
          <div>
            <b>{verification.valid ? 'All Ledger Accounts Fully Reconciled & Balanced' : 'Audit Discrepancy Detected'}</b>
            <p style={{ margin: '3px 0 0', fontSize: '11px', color: 'var(--text-muted)' }}>
              {verification.valid ? 'Every debit and credit transaction has been verified across all branches.' : verification.message}
            </p>
          </div>
          <button onClick={() => setVerification(null)} style={{ marginLeft: 'auto', border: 0, background: 'none', color: 'inherit', cursor: 'pointer' }}>
            <X size={16} />
          </button>
        </div>
      )}

      <div className="summary-strip">
        <div>
          <span>Total Ledger Rows</span>
          <b>{items.length}</b>
        </div>
        <div>
          <span>Total Debit Volume</span>
          <b>{money(items.reduce((s, x) => s + parseFloat(x.debit || 0), 0))}</b>
        </div>
        <div>
          <span>Total Credit Volume</span>
          <b>{money(items.reduce((s, x) => s + parseFloat(x.credit || 0), 0))}</b>
        </div>
        <div>
          <span>Ledger Mode</span>
          <b style={{ fontSize: '14px', color: 'var(--primary)' }}>APPEND-ONLY</b>
        </div>
      </div>

      <section className="panel table-panel">
        <SectionTitle title="Journal Entries" detail="Ordered by latest entry_id" />
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Entry ID</th>
                <th>Repayment / Loan</th>
                <th>Account Head</th>
                <th>Debit (₹)</th>
                <th>Credit (₹)</th>
                <th>Posted At</th>
                <th>Audit Verification Hash</th>
              </tr>
            </thead>
            <tbody>
              {items.map((e) => (
                <tr key={e.entry_id}>
                  <td className="mono">#{e.entry_id}</td>
                  <td>
                    {e.borrower_name}
                    <small className="sub-cell" style={{ display: 'block', color: 'var(--text-muted)' }}>
                      Repayment #{e.repayment_id || '—'} · Loan #{e.loan_id}
                    </small>
                  </td>
                  <td className="strong-cell">{e.account_head}</td>
                  <td className="amount">{parseFloat(e.debit) > 0 ? money(e.debit) : '—'}</td>
                  <td className="amount credit">{parseFloat(e.credit) > 0 ? money(e.credit) : '—'}</td>
                  <td className="mono" style={{ fontSize: '10px' }}>
                    {new Date(e.posted_at).toLocaleString('en-IN')}
                  </td>
                  <td className="mono" style={{ fontSize: '9px', maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis' }} title={e.entry_hash}>
                    {e.entry_hash}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!items.length && <EmptyState text="No ledger entries recorded yet." />}
        </div>
      </section>
    </>
  )
}

// -------------------------------------------------------------
// 6. Settings & Operations Component (Dark Mode & Controls)
// -------------------------------------------------------------
function SettingsTab({ theme, setTheme, user }) {
  const { showToast } = useContext(ToastContext)
  const [eodDate, setEodDate] = useState(() => {
    const d = new Date()
    d.setDate(d.getDate() + 30)
    return d.toISOString().split('T')[0]
  })
  const [runningEod, setRunningEod] = useState(false)
  const [eodResult, setEodResult] = useState(null)
  const [healthStatus, setHealthStatus] = useState(null)
  const [pinging, setPinging] = useState(false)

  const checkHealth = async () => {
    setPinging(true)
    const t0 = Date.now()
    const h = await api.health()
    const latency = Date.now() - t0
    setHealthStatus(h ? { ok: true, latency } : { ok: false })
    setPinging(false)
  }

  useEffect(() => {
    checkHealth()
  }, [])

  async function handleTriggerEod(e) {
    e.preventDefault()
    setRunningEod(true)
    try {
      const res = await api.runEodAccrual(eodDate)
      setEodResult(res)
      showToast('End-of-Day Accrual executed! Installments and exposure updated.', 'success')
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setRunningEod(false)
    }
  }

  return (
    <div className="settings-grid">
      <div>
        {/* Appearance Settings */}
        <div className="settings-card">
          <h3>Appearance & Theme</h3>
          <p>Customize the visual interface for daytime or night operations.</p>
          <div className="theme-options">
            <div
              className={`theme-option ${theme === 'light' ? 'active' : ''}`}
              onClick={() => setTheme('light')}
            >
              <Sun size={20} color={theme === 'light' ? 'var(--primary)' : 'var(--text-muted)'} />
              <b>Light Theme</b>
              <span>Clean high contrast</span>
            </div>
            <div
              className={`theme-option ${theme === 'dark' ? 'active' : ''}`}
              onClick={() => setTheme('dark')}
            >
              <Moon size={20} color={theme === 'dark' ? 'var(--primary)' : 'var(--text-muted)'} />
              <b>Dark Mode</b>
              <span>Fintech night mode</span>
            </div>
          </div>
        </div>

        {/* User Profile Card */}
        <div className="settings-card">
          <h3>Operational Profile</h3>
          <p>Active session identity and permissions.</p>
          <div className="diag-item">
            <div>
              <b>User Name</b>
              <span>{user?.name || 'Administrator'}</span>
            </div>
          </div>
          <div className="diag-item">
            <div>
              <b>Assigned Role</b>
              <span>{user?.role || 'ADMIN'}</span>
            </div>
            <Status>{user?.role || 'ADMIN'}</Status>
          </div>
          <div className="diag-item">
            <div>
              <b>Branch Association</b>
              <span>Branch #{user?.branchId || 1}</span>
            </div>
            <span className="mono">BRANCH SECURE</span>
          </div>
        </div>

        {/* Operational Services Status */}
        <div className="settings-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
            <div>
              <h3 style={{ margin: 0 }}>Operational Services Status</h3>
              <p style={{ margin: '2px 0 0' }}>Availability of banking gateways and branch services.</p>
            </div>
            <Button variant="secondary" onClick={checkHealth} disabled={pinging} style={{ padding: '6px 10px', fontSize: '10px' }}>
              <RefreshCw size={13} /> {pinging ? 'Checking…' : 'Check Status'}
            </Button>
          </div>
          <div className="diag-item">
            <div>
              <b>Core Banking API</b>
              <span>Real-time transaction synchronization</span>
            </div>
            <Status>{healthStatus?.ok ? 'Connected' : 'Offline'}</Status>
          </div>
          <div className="diag-item">
            <div>
              <b>Financial Ledger Engine</b>
              <span>Multi-branch audit separation</span>
            </div>
            <Status>Active</Status>
          </div>
          <div className="diag-item">
            <div>
              <b>Payment Gateway Terminal</b>
              <span>Duplicate charge prevention</span>
            </div>
            <Status>Active</Status>
          </div>
        </div>
      </div>

      <div>
        {/* End of Day Delinquency & Accrual Engine */}
        <div className="settings-card">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'var(--danger-bg)', color: 'var(--danger)', display: 'grid', placeItems: 'center' }}>
              <Clock size={19} />
            </div>
            <div>
              <h3 style={{ margin: 0 }}>End-of-Day (EOD) Settlement &amp; Delinquency Engine</h3>
              <p style={{ margin: '2px 0 0' }}>Automated daily portfolio reconciliation and late fee processing.</p>
            </div>
          </div>
          <p style={{ fontSize: '11px', lineHeight: '1.6' }}>
            Processes daily repayment cut-offs, marks overdue installments, assesses standard late fees, transitions accounts to delinquent status when required, and automatically updates peer-guarantee risk exposures across self-help groups.
          </p>
          <form onSubmit={handleTriggerEod} style={{ marginTop: '16px', display: 'flex', gap: '12px', alignItems: 'flex-end' }}>
            <label style={{ flex: 1, fontSize: '11px', fontWeight: 700 }}>
              As-Of Evaluation Date
              <input
                type="date"
                required
                style={{ width: '100%', height: '40px', marginTop: '6px', padding: '0 10px', border: '1px solid var(--border)', borderRadius: '6px', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                value={eodDate}
                onChange={(e) => setEodDate(e.target.value)}
              />
            </label>
            <Button type="submit" disabled={runningEod} style={{ height: '40px' }}>
              <Zap size={15} /> {runningEod ? 'Running EOD Engine…' : 'Execute EOD Engine'}
            </Button>
          </form>

          {eodResult && (
            <div style={{ marginTop: '18px', padding: '16px', borderRadius: '8px', background: 'var(--bg-subtle)', border: '1px solid var(--border)' }}>
              <b>EOD Execution Results:</b>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '10px', marginTop: '10px', fontSize: '11px' }}>
                <div>Processed Loans: <b>{eodResult.processed_loans}</b></div>
                <div>Overdue Installments: <b>{eodResult.overdue_installments}</b></div>
                <div>Delinquent Loans: <b>{eodResult.delinquent_loans}</b></div>
                <div>Defaulted Loans: <b>{eodResult.defaulted_loans}</b></div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// -------------------------------------------------------------
// Login Component
// -------------------------------------------------------------
function Login({ onLogin }) {
  const [email, setEmail] = useState('admin@microledger.com')
  const [password, setPassword] = useState('Admin@12345')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function submit(e) {
    e.preventDefault()
    setError('')
    setBusy(true)
    try {
      const session = await api.login(email.trim(), password)
      saveSession(session)
      onLogin(session)
    } catch (err) {
      setError(err.message || 'Unable to sign in. Please verify credentials.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <main className="login-page">
      <section className="login-card">
        <div className="login-brand">
          <div className="brand-mark">
            <Landmark size={22} />
          </div>
          <div>
            <b>microledger</b>
            <span>FINANCE OPERATIONS</span>
          </div>
        </div>
        <div className="login-heading">
          <div className="login-icon">
            <LockKeyhole size={20} />
          </div>
          <div className="eyebrow">SECURE PORTAL ACCESS</div>
          <h1>Welcome back</h1>
          <p>Sign in to access your branch operational ledger.</p>
        </div>
        <form className="login-form" onSubmit={submit}>
          <label htmlFor="login-email">Email Address</label>
          <input
            id="login-email"
            type="email"
            autoComplete="username"
            placeholder="admin@microledger.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <label htmlFor="login-password">Password</label>
          <input
            id="login-password"
            type="password"
            autoComplete="current-password"
            placeholder="Admin@12345"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          {error && (
            <div className="login-error">
              <CircleAlert size={16} />
              {error}
            </div>
          )}
          <button className="login-submit" type="submit" disabled={busy}>
            {busy ? 'Authenticating…' : 'Sign In'}
          </button>
        </form>
        <div style={{ marginTop: '20px', padding: '12px', background: 'var(--bg-subtle)', borderRadius: '8px', fontSize: '11px', color: 'var(--text-muted)' }}>
          <b>Demo Admin Credentials:</b>
          <div style={{ marginTop: '4px' }}>Email: <code>admin@microledger.com</code></div>
          <div>Password: <code>Admin@12345</code></div>
        </div>
      </section>
      <div className="login-footer">© 2026 MicroLedger · Enterprise Financial Platform</div>
    </main>
  )
}

// -------------------------------------------------------------
// Root App & Providers
// -------------------------------------------------------------
export default function App() {
  const [session, setSession] = useState(() => readSession())
  const [theme, setTheme] = useState(() => localStorage.getItem('microledger_theme') || 'dark')
  const [toasts, setToasts] = useState([])
  const navigate = useNavigate()

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('microledger_theme', theme)
  }, [theme])

  const toggleTheme = () => {
    setTheme((t) => (t === 'dark' ? 'light' : 'dark'))
  }

  const showToast = (message, type = 'success') => {
    const id = Date.now() + Math.random()
    setToasts((prev) => [...prev, { id, message, type }])
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 4500)
  }

  function logout() {
    clearSession()
    setSession(null)
    navigate('/login')
  }

  if (!session) {
    return (
      <ToastContext.Provider value={{ showToast }}>
        <Routes>
          <Route path="/login" element={<Login onLogin={setSession} />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </ToastContext.Provider>
    )
  }

  return (
    <ToastContext.Provider value={{ showToast }}>
      <Shell user={session.user} onLogout={logout} theme={theme} toggleTheme={toggleTheme}>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/borrowers" element={<Borrowers />} />
          <Route path="/loans" element={<Loans />} />
          <Route path="/terminal" element={<PaymentTerminal showToast={showToast} />} />
          <Route path="/collections" element={<Collections />} />
          <Route path="/ledger" element={<Ledger />} />
          <Route path="/settings" element={<SettingsTab theme={theme} setTheme={setTheme} user={session.user} />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Shell>

      {/* Toast Notification Container */}
      <div className="toast-container">
        {toasts.map((t) => (
          <div key={t.id} className={`toast ${t.type}`}>
            {t.type === 'success' ? <Check size={16} color="var(--success)" /> : <CircleAlert size={16} color="var(--danger)" />}
            <span>{t.message}</span>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}
