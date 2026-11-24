import { useState, useEffect, useMemo, useContext } from 'react'
import {
  CreditCard, Banknote, ShieldAlert, CheckCircle2, XCircle, AlertTriangle,
  RotateCcw, RefreshCw, Zap, Search, Landmark, Clock, Check, ChevronRight,
  ExternalLink, ArrowDownLeft, ArrowUpRight, DollarSign, UserCheck, ShieldCheck
} from 'lucide-react'
import { api } from './services/api'

const money = (n) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2,
  }).format(n || 0)

export default function PaymentTerminal({ showToast }) {
  const [activeTab, setActiveTab] = useState('collect') // 'collect' | 'originate' | 'history'
  const [loans, setLoans] = useState([])
  const [borrowers, setBorrowers] = useState([])
  const [groups, setGroups] = useState([])
  const [transactions, setTransactions] = useState([])
  const [loading, setLoading] = useState(true)

  // Loan Selector & Collection State
  const [loanSearch, setLoanSearch] = useState('')
  const [selectedLoanId, setSelectedLoanId] = useState('')
  const [amount, setAmount] = useState('')
  const [paymentMethod, setPaymentMethod] = useState('ONLINE_UPI') // 'CASH' | 'ONLINE_UPI' | 'ONLINE_CARD' | 'ONLINE_NETBANKING'
  const [isProcessing, setIsProcessing] = useState(false)
  const [inFlightWarning, setInFlightWarning] = useState(null)

  // Razorpay Gateway Simulator Modal
  const [checkoutModal, setCheckoutModal] = useState(null) // { transactionId, gatewayReference, loan, amount, method, ... }
  const [selectedGatewayMethod, setSelectedGatewayMethod] = useState('UPI') // 'UPI' | 'CARD' | 'NETBANKING'
  const [simFailReason, setSimFailReason] = useState('Bank Server 500: Downtime at issuing bank')

  // Animated Outcome Modals
  const [successModal, setSuccessModal] = useState(null)
  const [failModal, setFailModal] = useState(null)
  const [abortModal, setAbortModal] = useState(null)

  // Loan Creation Gateway Simulation State
  const [newLoan, setNewLoan] = useState({
    borrowerId: '',
    groupId: '',
    principal: '30000',
    cycleNo: '1',
    annualRate: '18.0',
    tenureWeeks: '52',
    simulateOutcome: 'SUCCESS', // 'SUCCESS' | 'FAILED' | 'NETWORK_ABORTED'
    failureReason: 'RBI 50% Household FOIR Limit Breached: Monthly debt service exceeds 50% income'
  })
  const [creatingLoan, setCreatingLoan] = useState(false)

  // History Filter
  const [historyFilter, setHistoryFilter] = useState('ALL') // 'ALL' | 'SUCCESS' | 'FAILED' | 'NETWORK_ABORTED'

  // Load Initial Data
  const loadData = async () => {
    try {
      setLoading(true)
      const [lRes, bRes, gRes, tRes] = await Promise.all([
        api.loans(),
        api.borrowers(),
        api.groups(),
        api.transactions({ limit: 100 })
      ])
      setLoans(lRes || [])
      setBorrowers(bRes || [])
      setGroups(gRes || [])
      setTransactions(tRes || [])
    } catch (err) {
      showToast?.(err.message || 'Error loading terminal data', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  // Page Reload / Abandonment Protection
  // If user reloaded the page while an online checkout was active, fail the in-flight transaction
  useEffect(() => {
    try {
      const activeCheckoutStr = sessionStorage.getItem('microledger_active_checkout')
      if (activeCheckoutStr) {
        const saved = JSON.parse(activeCheckoutStr)
        sessionStorage.removeItem('microledger_active_checkout')
        if (saved && saved.transactionId) {
          api.abortTransaction(saved.transactionId, {
            reason: 'Transaction cancelled / aborted due to browser reload during checkout'
          }).then(() => {
            showToast?.('In-flight payment was safely aborted because browser was reloaded.', 'error')
            loadData()
          }).catch(() => {})
        }
      }
    } catch {}
  }, [])

  // Filter open loans for payment (ACTIVE, DELINQUENT, DEFAULTED)
  const openLoans = useMemo(() => {
    return loans.filter((l) => ['ACTIVE', 'DELINQUENT', 'DEFAULTED'].includes(l.status))
  }, [loans])

  // Filtered loans list based on search
  const filteredLoans = useMemo(() => {
    if (!loanSearch.trim()) return openLoans.slice(0, 8)
    const q = loanSearch.toLowerCase()
    return openLoans.filter((l) =>
      String(l.loan_id).includes(q) ||
      (l.borrower_name && l.borrower_name.toLowerCase().includes(q)) ||
      (l.group_name && l.group_name.toLowerCase().includes(q))
    )
  }, [openLoans, loanSearch])

  // Selected loan object
  const selectedLoan = useMemo(() => {
    return loans.find((l) => String(l.loan_id) === String(selectedLoanId)) || null
  }, [loans, selectedLoanId])

  // Auto-fill estimated weekly EMI when loan is selected
  useEffect(() => {
    if (selectedLoan) {
      // Calculate or estimate weekly EMI: principal / tenure + interest
      const weeklyPrincipal = parseFloat(selectedLoan.principal) / (selectedLoan.tenure_weeks || 52)
      const weeklyInterest = (parseFloat(selectedLoan.outstanding_principal) * (parseFloat(selectedLoan.annual_rate) / 100 / 52))
      const estimatedEmi = Math.round((weeklyPrincipal + weeklyInterest) * 100) / 100
      setAmount(String(estimatedEmi > 0 ? estimatedEmi : 500))
      checkInFlightTransaction(selectedLoan.loan_id)
    } else {
      setInFlightWarning(null)
    }
  }, [selectedLoan])

  // Check if there is an in-flight transaction for this loan
  const checkInFlightTransaction = async (loanId) => {
    try {
      const active = transactions.find(
        (t) => String(t.loan_id) === String(loanId) && t.status === 'PENDING'
      )
      if (active) {
        setInFlightWarning(active)
      } else {
        setInFlightWarning(null)
      }
    } catch {}
  }

  // Handle Cancel in-flight lock
  const handleCancelInFlight = async () => {
    if (!inFlightWarning) return
    try {
      await api.abortTransaction(inFlightWarning.transaction_id, {
        reason: 'Transaction cancelled by operator from terminal'
      })
      showToast?.('In-flight transaction cancelled. Loan unlocked.', 'success')
      setInFlightWarning(null)
      loadData()
    } catch (err) {
      showToast?.(err.message, 'error')
    }
  }

  // Initiate Payment Flow
  const handleInitiatePayment = async (e) => {
    e.preventDefault()
    if (!selectedLoan) {
      showToast?.('Please select a loan account first', 'error')
      return
    }
    const numAmount = parseFloat(amount)
    if (!numAmount || numAmount <= 0) {
      showToast?.('Please enter a valid repayment amount', 'error')
      return
    }

    setIsProcessing(true)
    try {
      // 1. Call Initiate on Backend
      const initRes = await api.initiateTransaction({
        loanId: selectedLoan.loan_id,
        amount: numAmount,
        paymentMethod
      })

      // 2. Handle CASH mode (instant execution)
      if (paymentMethod === 'CASH') {
        const compRes = await api.completeTransaction(initRes.transactionId)
        setSuccessModal({
          title: 'Cash Repayment Confirmed',
          transactionId: initRes.transactionId,
          repaymentId: compRes.repaymentId,
          borrowerName: selectedLoan.borrower_name,
          amount: numAmount,
          method: 'CASH',
          loan: compRes.loan,
          timestamp: new Date().toLocaleTimeString('en-IN')
        })
        showToast?.(`Cash collection of ${money(numAmount)} recorded in ledger!`, 'success')
        loadData()
        setSelectedLoanId('')
        setAmount('')
        return
      }

      // 3. Handle ONLINE / GATEWAY mode (opens simulated Razorpay checkout)
      sessionStorage.setItem('microledger_active_checkout', JSON.stringify({
        transactionId: initRes.transactionId,
        loanId: selectedLoan.loan_id,
        amount: numAmount,
        borrowerName: selectedLoan.borrower_name
      }))

      setCheckoutModal({
        ...initRes,
        borrowerName: selectedLoan.borrower_name,
        groupName: selectedLoan.group_name
      })

    } catch (err) {
      showToast?.(err.message, 'error')
      if (err.message?.includes('already in progress')) {
        checkInFlightTransaction(selectedLoan.loan_id)
      }
    } finally {
      setIsProcessing(false)
    }
  }

  // Razorpay Simulation Handlers:
  // 1. Simulate Success
  const handleSimulateGatewaySuccess = async () => {
    if (!checkoutModal) return
    setIsProcessing(true)
    try {
      const compRes = await api.completeTransaction(checkoutModal.transactionId, {
        paymentDetails: {
          gatewayPaymentId: `pay_sim_${Date.now()}`,
          method: selectedGatewayMethod
        }
      })
      sessionStorage.removeItem('microledger_active_checkout')
      setCheckoutModal(null)

      setSuccessModal({
        title: 'Online Payment Confirmed',
        transactionId: checkoutModal.transactionId,
        repaymentId: compRes.repaymentId,
        borrowerName: checkoutModal.borrowerName,
        amount: checkoutModal.amount,
        method: `ONLINE_${selectedGatewayMethod}`,
        loan: compRes.loan,
        timestamp: new Date().toLocaleTimeString('en-IN')
      })
      showToast?.(`Online payment of ${money(checkoutModal.amount)} verified!`, 'success')
      loadData()
      setSelectedLoanId('')
      setAmount('')
    } catch (err) {
      showToast?.(err.message, 'error')
    } finally {
      setIsProcessing(false)
    }
  }

  // 2. Simulate Failure
  const handleSimulateGatewayFail = async () => {
    if (!checkoutModal) return
    setIsProcessing(true)
    try {
      await api.failTransaction(checkoutModal.transactionId, {
        reason: simFailReason
      })
      sessionStorage.removeItem('microledger_active_checkout')
      setCheckoutModal(null)

      setFailModal({
        title: 'Payment Transaction Failed',
        transactionId: checkoutModal.transactionId,
        borrowerName: checkoutModal.borrowerName,
        amount: checkoutModal.amount,
        reason: simFailReason,
        timestamp: new Date().toLocaleTimeString('en-IN')
      })
      showToast?.('Transaction marked as failed and recorded in audit log.', 'error')
      loadData()
    } catch (err) {
      showToast?.(err.message, 'error')
    } finally {
      setIsProcessing(false)
    }
  }

  // 3. Simulate Network Abort / Timeout
  const handleSimulateGatewayAbort = async () => {
    if (!checkoutModal) return
    setIsProcessing(true)
    try {
      await api.abortTransaction(checkoutModal.transactionId, {
        reason: 'Payment aborted: Network timeout / connection drop during banking authentication'
      })
      sessionStorage.removeItem('microledger_active_checkout')
      setCheckoutModal(null)

      setAbortModal({
        title: 'Transaction Stopped: Network Disconnected',
        transactionId: checkoutModal.transactionId,
        borrowerName: checkoutModal.borrowerName,
        amount: checkoutModal.amount,
        reason: 'Banking network timed out. Loan account was safely unlocked.',
        timestamp: new Date().toLocaleTimeString('en-IN')
      })
      showToast?.('Transaction safely aborted due to network disruption.', 'error')
      loadData()
    } catch (err) {
      showToast?.(err.message, 'error')
    } finally {
      setIsProcessing(false)
    }
  }

  // Loan Creation Simulation Submit
  const handleSimulateLoanCreation = async (e) => {
    e.preventDefault()
    if (!newLoan.borrowerId || !newLoan.groupId || !newLoan.principal) {
      showToast?.('Please fill all required loan parameters', 'error')
      return
    }

    setCreatingLoan(true)
    try {
      const res = await api.simulateLoanCreation({
        borrowerId: newLoan.borrowerId,
        groupId: newLoan.groupId,
        cycleNo: parseInt(newLoan.cycleNo, 10),
        principal: parseFloat(newLoan.principal),
        annualRate: parseFloat(newLoan.annualRate),
        tenureWeeks: parseInt(newLoan.tenureWeeks, 10),
        simulateOutcome: newLoan.simulateOutcome,
        failureReason: newLoan.failureReason
      })

      if (newLoan.simulateOutcome === 'SUCCESS') {
        const borrower = borrowers.find((b) => String(b.borrower_id) === String(newLoan.borrowerId))
        setSuccessModal({
          title: 'Loan Disbursed & Amortized',
          transactionId: res.transactionId,
          borrowerName: borrower?.full_name || 'Borrower',
          amount: parseFloat(newLoan.principal),
          method: 'GATEWAY_SIMULATOR',
          loan: res.loan,
          timestamp: new Date().toLocaleTimeString('en-IN'),
          isLoanOrigination: true
        })
        showToast?.(`Loan of ${money(parseFloat(newLoan.principal))} disbursed!`, 'success')
      } else if (newLoan.simulateOutcome === 'NETWORK_ABORTED') {
        setAbortModal({
          title: 'Loan Disbursement Interrupted',
          transactionId: res.transactionId,
          borrowerName: 'Borrower ID #' + newLoan.borrowerId,
          amount: parseFloat(newLoan.principal),
          reason: res.failureReason,
          timestamp: new Date().toLocaleTimeString('en-IN')
        })
      }
      loadData()
    } catch (err) {
      setFailModal({
        title: 'Loan Origination Failed',
        borrowerName: 'Borrower ID #' + newLoan.borrowerId,
        amount: parseFloat(newLoan.principal),
        reason: err.message,
        timestamp: new Date().toLocaleTimeString('en-IN')
      })
      showToast?.(err.message, 'error')
      loadData()
    } finally {
      setCreatingLoan(false)
    }
  }

  // Filtered transactions for history table
  const filteredTransactions = useMemo(() => {
    if (historyFilter === 'ALL') return transactions
    return transactions.filter((t) => t.status === historyFilter)
  }, [transactions, historyFilter])

  return (
    <div style={{ paddingBottom: '40px' }}>

      {/* Tab Switcher */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px', borderBottom: '1px solid var(--border)', paddingBottom: '12px' }}>
        <button
          className={`btn ${activeTab === 'collect' ? 'btn-primary' : 'btn-secondary'}`}
          onClick={() => setActiveTab('collect')}
        >
          <CreditCard size={16} /> Instant Payment Collection Terminal
        </button>
        <button
          className={`btn ${activeTab === 'originate' ? 'btn-primary' : 'btn-secondary'}`}
          onClick={() => setActiveTab('originate')}
        >
          <Zap size={16} /> Loan Origination Gateway
        </button>
        <button
          className={`btn ${activeTab === 'history' ? 'btn-primary' : 'btn-secondary'}`}
          onClick={() => setActiveTab('history')}
        >
          <Clock size={16} /> Gateway Transaction Audit Log ({transactions.length})
        </button>
      </div>

      {/* TAB 1: REPAYMENT GATEWAY TERMINAL */}
      {activeTab === 'collect' && (
        <div className="grid-2-1" style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '24px' }}>

          {/* Left Column: Loan Selector & Details */}
          <div>
            <div className="card" style={{ marginBottom: '20px' }}>
              <div className="card-header">
                <h3>Select Active Loan for Payment</h3>
                <p>Choose an active or delinquent loan to initiate instant cash or online payment.</p>
              </div>
              <div className="card-body">
                <div style={{ position: 'relative', marginBottom: '16px' }}>
                  <Search size={16} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--text-muted)' }} />
                  <input
                    type="text"
                    placeholder="Search by borrower name, phone, or loan ID..."
                    value={loanSearch}
                    onChange={(e) => setLoanSearch(e.target.value)}
                    style={{ paddingLeft: '38px', width: '100%', height: '42px', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '10px', maxHeight: '350px', overflowY: 'auto' }}>
                  {filteredLoans.map((l) => {
                    const isSelected = String(l.loan_id) === String(selectedLoanId)
                    return (
                      <div
                        key={l.loan_id}
                        onClick={() => setSelectedLoanId(l.loan_id)}
                        style={{
                          padding: '12px 14px',
                          borderRadius: '8px',
                          border: isSelected ? '2px solid var(--primary)' : '1px solid var(--border)',
                          background: isSelected ? 'rgba(14, 165, 233, 0.08)' : 'var(--bg-card)',
                          cursor: 'pointer',
                          transition: 'all 0.15s ease'
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                          <b>{l.borrower_name}</b>
                          <span className={`badge ${l.status === 'ACTIVE' ? 'badge-success' : 'badge-danger'}`} style={{ fontSize: '9px' }}>
                            {l.status}
                          </span>
                        </div>
                        <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginBottom: '4px' }}>
                          Loan #{l.loan_id} · {l.group_name}
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px' }}>
                          <span>Balance: <b style={{ color: 'var(--text-main)' }}>{money(l.outstanding_principal)}</b></span>
                          <span>Cycle: <b>{l.cycle_no}</b></span>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>

            {/* In-Flight Mutex Warning if active on this loan */}
            {inFlightWarning && (
              <div className="mutex-warning-box">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#b45309', fontWeight: 700, fontSize: '13px' }}>
                  <AlertTriangle size={18} /> In-Flight Transaction Lock Active
                </div>
                <p style={{ margin: '6px 0 10px', fontSize: '12px', color: '#92400e' }}>
                  Transaction <code>{inFlightWarning.transaction_id}</code> for <b>{money(inFlightWarning.amount)}</b> is currently in progress.
                  To protect ledger integrity, concurrent transactions are locked.
                </p>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button
                    className="btn btn-secondary"
                    onClick={() => {
                      setCheckoutModal({
                        transactionId: inFlightWarning.transaction_id,
                        loanId: inFlightWarning.loan_id,
                        amount: inFlightWarning.amount,
                        borrowerName: selectedLoan?.borrower_name || 'Borrower'
                      })
                    }}
                    style={{ fontSize: '11px', padding: '6px 12px' }}
                  >
                    Resume Checkout
                  </button>
                  <button
                    className="btn btn-secondary"
                    onClick={handleCancelInFlight}
                    style={{ fontSize: '11px', padding: '6px 12px', color: '#dc2626' }}
                  >
                    Cancel Lock
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Right Column: Collection Form */}
          <div>
            <div className="card" style={{ position: 'sticky', top: '90px' }}>
              <div className="card-header">
                <h3>Payment Collection Terminal</h3>
                <p>Execute payment or transition into simulated Razorpay gateway.</p>
              </div>
              <div className="card-body">
                {!selectedLoan ? (
                  <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-muted)' }}>
                    <CreditCard size={36} style={{ margin: '0 auto 12px', opacity: 0.5 }} />
                    <p style={{ margin: 0 }}>Please select a loan from the left list to proceed.</p>
                  </div>
                ) : (
                  <form onSubmit={handleInitiatePayment}>
                    <div style={{ padding: '12px', background: 'var(--bg-subtle)', borderRadius: '8px', marginBottom: '16px' }}>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Target Borrower</div>
                      <b style={{ fontSize: '14px', display: 'block' }}>{selectedLoan.borrower_name}</b>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '8px', fontSize: '11px' }}>
                        <span>Principal: <b>{money(selectedLoan.principal)}</b></span>
                        <span>Outstanding: <b style={{ color: 'var(--primary)' }}>{money(selectedLoan.outstanding_principal)}</b></span>
                      </div>
                    </div>

                    {/* Amount Input */}
                    <div className="form-group" style={{ marginBottom: '16px' }}>
                      <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '6px' }}>
                        Repayment Collection Amount (₹)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        required
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        placeholder="e.g. 500.00"
                        style={{ width: '100%', height: '44px', fontSize: '18px', fontWeight: 700, padding: '0 12px', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                      />
                      <div style={{ display: 'flex', gap: '6px', marginTop: '8px' }}>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={() => setAmount(String(selectedLoan.outstanding_principal))}
                          style={{ fontSize: '10px', padding: '4px 8px' }}
                        >
                          Full Balance
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={() => setAmount('1000')}
                          style={{ fontSize: '10px', padding: '4px 8px' }}
                        >
                          ₹1,000
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={() => setAmount('500')}
                          style={{ fontSize: '10px', padding: '4px 8px' }}
                        >
                          ₹500
                        </button>
                      </div>
                    </div>

                    {/* Payment Mode Selector */}
                    <div className="form-group" style={{ marginBottom: '20px' }}>
                      <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '8px' }}>
                        Collection Channel & Mode
                      </label>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '10px' }}>
                        <div
                          onClick={() => setPaymentMethod('CASH')}
                          style={{
                            padding: '12px',
                            borderRadius: '8px',
                            border: paymentMethod === 'CASH' ? '2px solid var(--primary)' : '1px solid var(--border)',
                            background: paymentMethod === 'CASH' ? 'rgba(14, 165, 233, 0.08)' : 'var(--bg-card)',
                            cursor: 'pointer',
                            textAlign: 'center'
                          }}
                        >
                          <Banknote size={20} style={{ margin: '0 auto 4px', color: '#10b981' }} />
                          <b style={{ display: 'block', fontSize: '12px' }}>Cash Collection</b>
                          <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>Recorded immediately</span>
                        </div>

                        <div
                          onClick={() => setPaymentMethod('ONLINE_UPI')}
                          style={{
                            padding: '12px',
                            borderRadius: '8px',
                            border: paymentMethod !== 'CASH' ? '2px solid var(--primary)' : '1px solid var(--border)',
                            background: paymentMethod !== 'CASH' ? 'rgba(14, 165, 233, 0.08)' : 'var(--bg-card)',
                            cursor: 'pointer',
                            textAlign: 'center'
                          }}
                        >
                          <CreditCard size={20} style={{ margin: '0 auto 4px', color: '#0284c7' }} />
                          <b style={{ display: 'block', fontSize: '12px' }}>Online Gateway</b>
                          <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>Razorpay Demo simulator</span>
                        </div>
                      </div>
                    </div>

                    {/* Submit Button */}
                    <button
                      type="submit"
                      disabled={isProcessing || inFlightWarning}
                      className="btn btn-primary"
                      style={{ width: '100%', height: '46px', fontSize: '14px', fontWeight: 700 }}
                    >
                      {isProcessing ? 'Processing Transaction…' : paymentMethod === 'CASH' ? 'Record Immediate Cash Payment' : 'Proceed to Razorpay Gateway'}
                    </button>
                  </form>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: LOAN ORIGINATION GATEWAY SIMULATION */}
      {activeTab === 'originate' && (
        <div style={{ maxWidth: '780px', margin: '0 auto' }}>
          <div className="card">
            <div className="card-header">
              <h3>Loan Origination & Disbursement Gateway</h3>
              <p>Simulate instant loan creation, automated disbursement, or test failure handling.</p>
            </div>
            <div className="card-body">
              <form onSubmit={handleSimulateLoanCreation}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px', marginBottom: '16px' }}>
                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '6px' }}>
                      Select Borrower
                    </label>
                    <select
                      required
                      value={newLoan.borrowerId}
                      onChange={(e) => {
                        const bId = e.target.value
                        setNewLoan((prev) => ({ ...prev, borrowerId: bId }))
                      }}
                      style={{ width: '100%', height: '40px', padding: '0 10px', borderRadius: '6px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                    >
                      <option value="">-- Choose Borrower --</option>
                      {borrowers.map((b) => (
                        <option key={b.borrower_id} value={b.borrower_id}>
                          {b.full_name} (#{b.borrower_id}) - Income: {money(b.monthly_household_income)}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '6px' }}>
                      Select JLG Group (SHG)
                    </label>
                    <select
                      required
                      value={newLoan.groupId}
                      onChange={(e) => setNewLoan((prev) => ({ ...prev, groupId: e.target.value }))}
                      style={{ width: '100%', height: '40px', padding: '0 10px', borderRadius: '6px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                    >
                      <option value="">-- Choose JLG Group --</option>
                      {groups.map((g) => (
                        <option key={g.group_id} value={g.group_id}>
                          {g.name} (Cap: {money(g.max_exposure)})
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '20px' }}>
                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '6px' }}>
                      Principal Amount (₹)
                    </label>
                    <input
                      type="number"
                      required
                      value={newLoan.principal}
                      onChange={(e) => setNewLoan((prev) => ({ ...prev, principal: e.target.value }))}
                      style={{ width: '100%', height: '40px', padding: '0 10px', borderRadius: '6px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                    />
                  </div>

                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '6px' }}>
                      Loan Cycle
                    </label>
                    <input
                      type="number"
                      required
                      value={newLoan.cycleNo}
                      onChange={(e) => setNewLoan((prev) => ({ ...prev, cycleNo: e.target.value }))}
                      style={{ width: '100%', height: '40px', padding: '0 10px', borderRadius: '6px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                    />
                  </div>

                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 700, display: 'block', marginBottom: '6px' }}>
                      Tenure (Weeks)
                    </label>
                    <input
                      type="number"
                      required
                      value={newLoan.tenureWeeks}
                      onChange={(e) => setNewLoan((prev) => ({ ...prev, tenureWeeks: e.target.value }))}
                      style={{ width: '100%', height: '40px', padding: '0 10px', borderRadius: '6px', border: '1px solid var(--border)', background: 'var(--bg-subtle)', color: 'var(--text-main)' }}
                    />
                  </div>
                </div>

                {/* Gateway Simulation Options */}
                <div style={{ padding: '16px', borderRadius: '8px', background: 'var(--bg-subtle)', border: '1px solid var(--border)', marginBottom: '20px' }}>
                  <b style={{ fontSize: '12px', display: 'block', marginBottom: '10px' }}>
                    Select Simulation Outcome (Test Mode)
                  </b>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px', marginBottom: '12px' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '12px' }}>
                      <input
                        type="radio"
                        name="simulateOutcome"
                        value="SUCCESS"
                        checked={newLoan.simulateOutcome === 'SUCCESS'}
                        onChange={(e) => setNewLoan((prev) => ({ ...prev, simulateOutcome: e.target.value }))}
                      />
                      <span style={{ color: '#10b981', fontWeight: 700 }}>🟢 Simulate Success</span>
                    </label>

                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '12px' }}>
                      <input
                        type="radio"
                        name="simulateOutcome"
                        value="FAILED"
                        checked={newLoan.simulateOutcome === 'FAILED'}
                        onChange={(e) => setNewLoan((prev) => ({ ...prev, simulateOutcome: e.target.value }))}
                      />
                      <span style={{ color: '#ef4444', fontWeight: 700 }}>🔴 Simulate Failure</span>
                    </label>

                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '12px' }}>
                      <input
                        type="radio"
                        name="simulateOutcome"
                        value="NETWORK_ABORTED"
                        checked={newLoan.simulateOutcome === 'NETWORK_ABORTED'}
                        onChange={(e) => setNewLoan((prev) => ({ ...prev, simulateOutcome: e.target.value }))}
                      />
                      <span style={{ color: '#f59e0b', fontWeight: 700 }}>🟡 Simulate Network Drop</span>
                    </label>
                  </div>

                  {newLoan.simulateOutcome === 'FAILED' && (
                    <div>
                      <label style={{ fontSize: '10px', fontWeight: 700, color: 'var(--text-muted)' }}>Failure Reason to Record</label>
                      <input
                        type="text"
                        value={newLoan.failureReason}
                        onChange={(e) => setNewLoan((prev) => ({ ...prev, failureReason: e.target.value }))}
                        style={{ width: '100%', height: '36px', marginTop: '4px', padding: '0 8px', borderRadius: '4px', border: '1px solid var(--border)', background: 'var(--bg-card)', color: 'var(--text-main)', fontSize: '11px' }}
                      />
                    </div>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={creatingLoan}
                  className="btn btn-primary"
                  style={{ width: '100%', height: '46px', fontSize: '14px', fontWeight: 700 }}
                >
                  {creatingLoan ? 'Executing Origination Gateway…' : 'Execute Loan Origination & Disbursal'}
                </button>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: TRANSACTION AUDIT LOG TABLE */}
      {activeTab === 'history' && (
        <div className="card">
          <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <h3>Payment Gateway &amp; Terminal Transaction Audit History</h3>
              <p>Real-time audit log of all successful, failed, and aborted transaction attempts.</p>
            </div>
            <div style={{ display: 'flex', gap: '8px' }}>
              <div style={{ display: 'flex', gap: '4px', background: 'var(--bg-subtle)', padding: '4px', borderRadius: '8px' }}>
                {['ALL', 'SUCCESS', 'FAILED', 'NETWORK_ABORTED'].map((st) => (
                  <button
                    key={st}
                    onClick={() => setHistoryFilter(st)}
                    style={{
                      border: 0,
                      padding: '4px 10px',
                      borderRadius: '6px',
                      fontSize: '11px',
                      fontWeight: 700,
                      cursor: 'pointer',
                      background: historyFilter === st ? 'var(--primary)' : 'transparent',
                      color: historyFilter === st ? '#fff' : 'var(--text-muted)'
                    }}
                  >
                    {st}
                  </button>
                ))}
              </div>
              <button className="btn btn-secondary" onClick={loadData}>
                <RefreshCw size={14} /> Refresh
              </button>
            </div>
          </div>
          <div className="card-body" style={{ padding: 0 }}>
            <table className="table">
              <thead>
                <tr>
                  <th>Status</th>
                  <th>Transaction ID</th>
                  <th>Timestamp</th>
                  <th>Type</th>
                  <th>Borrower / Loan</th>
                  <th>Amount</th>
                  <th>Method</th>
                  <th>Gateway Ref</th>
                  <th>Status Notes / Reason</th>
                </tr>
              </thead>
              <tbody>
                {filteredTransactions.length === 0 ? (
                  <tr>
                    <td colSpan="9" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                      No transaction records found matching filter.
                    </td>
                  </tr>
                ) : (
                  filteredTransactions.map((t) => (
                    <tr key={t.transaction_id}>
                      <td>
                        <span className={`status-pill ${t.status.toLowerCase()}`}>
                          {t.status === 'SUCCESS' && <CheckCircle2 size={12} />}
                          {t.status === 'FAILED' && <XCircle size={12} />}
                          {t.status === 'NETWORK_ABORTED' && <AlertTriangle size={12} />}
                          {t.status === 'PENDING' && <Clock size={12} />}
                          {t.status}
                        </span>
                      </td>
                      <td style={{ fontFamily: 'monospace', fontSize: '11px', fontWeight: 600 }}>{t.transaction_id}</td>
                      <td style={{ fontSize: '11px' }}>{new Date(t.created_at).toLocaleString('en-IN')}</td>
                      <td>
                        <span style={{ fontSize: '10px', fontWeight: 700, color: 'var(--text-dim)' }}>
                          {t.transaction_type}
                        </span>
                      </td>
                      <td>
                        <b>{t.borrower_name || ('Borrower #' + t.borrower_id)}</b>
                        {t.loan_id && <span style={{ fontSize: '10px', color: 'var(--text-muted)', display: 'block' }}>Loan #{t.loan_id}</span>}
                      </td>
                      <td style={{ fontWeight: 700 }}>{money(t.amount)}</td>
                      <td style={{ fontSize: '11px' }}>{t.payment_method}</td>
                      <td style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--text-muted)' }}>{t.gateway_reference || '—'}</td>
                      <td style={{ fontSize: '11px', color: t.failure_reason ? '#ef4444' : 'var(--text-muted)' }}>
                        {t.failure_reason || (t.status === 'SUCCESS' ? 'Settled and confirmed' : '—')}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* =========================================================================
          RAZORPAY DEMO CHECKOUT SIMULATOR MODAL
         ========================================================================= */}
      {checkoutModal && (
        <div className="scrim" style={{ display: 'grid', placeItems: 'center', zIndex: 100 }}>
          <div className="razorpay-window">
            {/* Blue Razorpay Header */}
            <div className="razorpay-header">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div className="razorpay-tag">
                    <Zap size={10} /> Razorpay Test Gateway Demo
                  </div>
                  <div style={{ fontSize: '13px', opacity: 0.9 }}>MicroLedger Rural Finance</div>
                  <div className="razorpay-amount">{money(checkoutModal.amount)}</div>
                </div>
                <button
                  onClick={() => {
                    handleSimulateGatewayAbort()
                  }}
                  style={{ background: 'rgba(255,255,255,0.2)', border: 0, color: '#fff', borderRadius: '50%', width: '28px', height: '28px', cursor: 'pointer', display: 'grid', placeItems: 'center' }}
                  title="Close / Cancel"
                >
                  ✕
                </button>
              </div>
              <div style={{ fontSize: '11px', opacity: 0.8, marginTop: '8px' }}>
                Borrower: <b>{checkoutModal.borrowerName}</b> · Ref: {checkoutModal.gatewayReference}
              </div>
            </div>

            {/* Modal Body */}
            <div className="razorpay-body">
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '8px' }}>
                SELECT PAYMENT METHOD
              </div>
              <div className="razorpay-methods">
                <button
                  type="button"
                  className={`method-btn ${selectedGatewayMethod === 'UPI' ? 'active' : ''}`}
                  onClick={() => setSelectedGatewayMethod('UPI')}
                >
                  <Zap size={18} />
                  <span>UPI / QR</span>
                </button>
                <button
                  type="button"
                  className={`method-btn ${selectedGatewayMethod === 'CARD' ? 'active' : ''}`}
                  onClick={() => setSelectedGatewayMethod('CARD')}
                >
                  <CreditCard size={18} />
                  <span>Card</span>
                </button>
                <button
                  type="button"
                  className={`method-btn ${selectedGatewayMethod === 'NETBANKING' ? 'active' : ''}`}
                  onClick={() => setSelectedGatewayMethod('NETBANKING')}
                >
                  <Landmark size={18} />
                  <span>NetBanking</span>
                </button>
              </div>

              {/* Concurrency Mutex Notice */}
              <div style={{ padding: '8px 12px', borderRadius: '6px', background: 'rgba(14, 165, 233, 0.08)', border: '1px solid rgba(14, 165, 233, 0.2)', fontSize: '11px', color: '#0369a1', marginBottom: '14px' }}>
                🔒 <b>Payment Protection Active:</b> Loan #{checkoutModal.loanId} is secured against duplicate submissions.
              </div>

              {/* Functional Simulator Controller */}
              <div className="sim-panel">
                <div className="sim-panel-title">
                  <ShieldCheck size={14} /> Interactive Gateway Simulator Triggers
                </div>
                <p style={{ margin: '0 0 10px', fontSize: '11px', color: 'var(--text-muted)' }}>
                  Trigger any of the 3 realistic gateway states to test confirmation workflows and animated status alerts:
                </p>

                <div className="sim-actions-grid">
                  <button
                    type="button"
                    disabled={isProcessing}
                    className="sim-btn-success"
                    onClick={handleSimulateGatewaySuccess}
                  >
                    <CheckCircle2 size={16} />
                    <span>Authorize &amp; Settle</span>
                  </button>

                  <button
                    type="button"
                    disabled={isProcessing}
                    className="sim-btn-fail"
                    onClick={handleSimulateGatewayFail}
                  >
                    <XCircle size={16} />
                    <span>Bank Decline</span>
                  </button>

                  <button
                    type="button"
                    disabled={isProcessing}
                    className="sim-btn-abort"
                    onClick={handleSimulateGatewayAbort}
                  >
                    <AlertTriangle size={16} />
                    <span>Network Drop</span>
                  </button>
                </div>

                <div style={{ marginTop: '10px' }}>
                  <label style={{ fontSize: '10px', fontWeight: 600, color: 'var(--text-muted)' }}>Preset Decline Reason</label>
                  <select
                    value={simFailReason}
                    onChange={(e) => setSimFailReason(e.target.value)}
                    style={{ width: '100%', height: '32px', fontSize: '11px', padding: '0 6px', marginTop: '3px', borderRadius: '4px', border: '1px solid var(--border)', background: 'var(--bg-card)', color: 'var(--text-main)' }}
                  >
                    <option value="Bank Server 500: Downtime at issuing bank">Bank Server 500: Downtime at issuing bank</option>
                    <option value="Card Issuer Declined: Insufficient balance in customer account">Card Issuer Declined: Insufficient balance</option>
                    <option value="Customer Authentication Failed: Incorrect OTP entered">Customer Authentication Failed: Incorrect OTP</option>
                    <option value="UPI Limit Exceeded: Customer daily transfer cap reached">UPI Limit Exceeded: Daily transfer cap reached</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================================
          ANIMATED POPUP 1: TRANSACTION SUCCESSFUL
         ========================================================================= */}
      {successModal && (
        <div className="scrim" style={{ display: 'grid', placeItems: 'center', zIndex: 110 }}>
          <div className="card anim-success-card" style={{ width: '480px', maxWidth: '95vw', textAlign: 'center', padding: '32px 24px' }}>
            <div className="anim-success-badge">
              <Check size={40} strokeWidth={3} />
            </div>
            <h2 style={{ margin: '0 0 6px', fontSize: '20px', color: '#10b981' }}>{successModal.title}</h2>
            <p style={{ margin: '0 0 20px', color: 'var(--text-muted)', fontSize: '12px' }}>
              Transaction successfully processed and confirmed in the account ledger.
            </p>

            <div style={{ background: 'var(--bg-subtle)', borderRadius: '10px', padding: '16px', textAlign: 'left', marginBottom: '24px', fontSize: '12px', border: '1px solid var(--border)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Transaction ID:</span>
                <b style={{ fontFamily: 'monospace' }}>{successModal.transactionId}</b>
              </div>
              {successModal.repaymentId && (
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Repayment ID:</span>
                  <b>#{successModal.repaymentId}</b>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Borrower:</span>
                <b>{successModal.borrowerName}</b>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Amount Paid:</span>
                <b style={{ color: '#10b981', fontSize: '14px' }}>{money(successModal.amount)}</b>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Payment Channel:</span>
                <b>{successModal.method}</b>
              </div>
              {successModal.loan && (
                <div style={{ display: 'flex', justifyContent: 'space-between', paddingTop: '8px', borderTop: '1px dashed var(--border)' }}>
                  <span style={{ color: 'var(--text-muted)' }}>New Loan Balance:</span>
                  <b style={{ color: 'var(--primary)' }}>{money(successModal.loan.outstanding_principal)}</b>
                </div>
              )}
            </div>

            <button
              className="btn btn-primary"
              onClick={() => setSuccessModal(null)}
              style={{ width: '100%', height: '42px', fontWeight: 700 }}
            >
              Done &amp; Return to Terminal
            </button>
          </div>
        </div>
      )}

      {/* =========================================================================
          ANIMATED POPUP 2: TRANSACTION FAILED
         ========================================================================= */}
      {failModal && (
        <div className="scrim" style={{ display: 'grid', placeItems: 'center', zIndex: 110 }}>
          <div className="card anim-fail-card" style={{ width: '480px', maxWidth: '95vw', textAlign: 'center', padding: '32px 24px' }}>
            <div className="anim-fail-badge">
              <XCircle size={42} strokeWidth={2.5} />
            </div>
            <h2 style={{ margin: '0 0 6px', fontSize: '20px', color: '#ef4444' }}>{failModal.title}</h2>
            <p style={{ margin: '0 0 20px', color: 'var(--text-muted)', fontSize: '12px' }}>
              No funds were debited. This failed attempt is recorded in the transaction audit log.
            </p>

            <div style={{ background: 'rgba(239, 68, 68, 0.08)', borderRadius: '10px', padding: '16px', textAlign: 'left', marginBottom: '24px', fontSize: '12px', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Transaction ID:</span>
                <b style={{ fontFamily: 'monospace' }}>{failModal.transactionId}</b>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Customer:</span>
                <b>{failModal.borrowerName}</b>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Attempted Amount:</span>
                <b>{money(failModal.amount)}</b>
              </div>
              <div style={{ paddingTop: '8px', borderTop: '1px dashed rgba(239, 68, 68, 0.2)' }}>
                <span style={{ color: '#dc2626', fontWeight: 700, display: 'block', marginBottom: '2px' }}>Failure Reason:</span>
                <span style={{ color: '#b91c1c' }}>{failModal.reason}</span>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                className="btn btn-secondary"
                onClick={() => {
                  setFailModal(null)
                  setActiveTab('history')
                }}
                style={{ flex: 1, height: '42px', fontWeight: 600 }}
              >
                View in Audit History
              </button>
              <button
                className="btn btn-primary"
                onClick={() => setFailModal(null)}
                style={{ flex: 1, height: '42px', fontWeight: 700 }}
              >
                Dismiss &amp; Retry
              </button>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================================
          ANIMATED POPUP 3: TRANSACTION NETWORK ABORTED
         ========================================================================= */}
      {abortModal && (
        <div className="scrim" style={{ display: 'grid', placeItems: 'center', zIndex: 110 }}>
          <div className="card anim-fail-card" style={{ width: '480px', maxWidth: '95vw', textAlign: 'center', padding: '32px 24px' }}>
            <div className="anim-abort-badge">
              <AlertTriangle size={42} strokeWidth={2.5} />
            </div>
            <h2 style={{ margin: '0 0 6px', fontSize: '20px', color: '#f59e0b' }}>{abortModal.title}</h2>
            <p style={{ margin: '0 0 20px', color: 'var(--text-muted)', fontSize: '12px' }}>
              Transaction was safely aborted to prevent duplicate deductions. Loan account unlocked.
            </p>

            <div style={{ background: 'rgba(245, 158, 11, 0.08)', borderRadius: '10px', padding: '16px', textAlign: 'left', marginBottom: '24px', fontSize: '12px', border: '1px solid rgba(245, 158, 11, 0.25)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Transaction ID:</span>
                <b style={{ fontFamily: 'monospace' }}>{abortModal.transactionId}</b>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Customer:</span>
                <b>{abortModal.borrowerName}</b>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Amount:</span>
                <b>{money(abortModal.amount)}</b>
              </div>
              <div style={{ paddingTop: '8px', borderTop: '1px dashed rgba(245, 158, 11, 0.2)' }}>
                <span style={{ color: '#b45309', fontWeight: 700, display: 'block', marginBottom: '2px' }}>Notice:</span>
                <span style={{ color: '#92400e' }}>{abortModal.reason}</span>
              </div>
            </div>

            <button
              className="btn btn-primary"
              onClick={() => setAbortModal(null)}
              style={{ width: '100%', height: '42px', fontWeight: 700 }}
            >
              Acknowledge &amp; Return
            </button>
          </div>
        </div>
      )}

    </div>
  )
}
