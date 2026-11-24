const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL !== undefined && import.meta.env.VITE_API_BASE_URL !== ''
    ? import.meta.env.VITE_API_BASE_URL
    : (typeof window !== 'undefined' && window.location.origin ? `${window.location.origin}/api` : 'http://localhost:5000/api')
).replace(/\/$/, '');

export const readSession = () => {
  try {
    const token = localStorage.getItem('microledger_token');
    const user = JSON.parse(localStorage.getItem('microledger_user') || 'null');
    return token && user ? { token, user } : null;
  } catch {
    return null;
  }
};

export function saveSession(session) {
  localStorage.setItem('microledger_token', session.token);
  localStorage.setItem('microledger_user', JSON.stringify(session.user));
}

export function clearSession() {
  localStorage.removeItem('microledger_token');
  localStorage.removeItem('microledger_user');
}

async function request(path, options = {}) {
  const token = localStorage.getItem('microledger_token');
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {}),
  };

  const response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });
  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      message = body.error || body.message || message;
    } catch {
      const body = await response.text();
      if (body) message = body;
    }
    throw new Error(message);
  }
  if (response.status === 204) return null;
  return response.json();
}

export const api = {
  // System Health
  health: async () => {
    try {
      const hostUrl = API_BASE_URL.replace(/\/api$/, '');
      const res = await fetch(`${hostUrl}/health`);
      return res.ok ? await res.json() : null;
    } catch {
      return null;
    }
  },

  // Auth
  login: (email, password) =>
    request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  // Dashboard Overview
  dashboard: () => request('/dashboard/summary'),

  // Village Meeting Centers
  centers: () => request('/centers'),

  // Borrowers
  borrowers: () => request('/borrowers'),
  createBorrower: (payload) =>
    request('/borrowers', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  deleteBorrower: (borrowerId) =>
    request(`/borrowers/${borrowerId}`, {
      method: 'DELETE',
    }),

  // JLG Groups & Guarantees
  groups: () => request('/groups'),
  createGroup: (payload) =>
    request('/groups', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  groupMembers: (groupId) => request(`/groups/${groupId}/members`),
  addGroupMember: (groupId, payload) =>
    request(`/groups/${groupId}/members`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  deleteGroupMember: (groupId, borrowerId) =>
    request(`/groups/${groupId}/members/${borrowerId}`, {
      method: 'DELETE',
    }),
  groupExposure: (groupId) => request(`/groups/${groupId}/exposure`),

  // Loans & Disbursals
  loans: () => request('/loans'),
  createLoan: (payload) =>
    request('/loans', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  disburseLoan: (loanId) =>
    request(`/loans/${loanId}/disburse`, {
      method: 'POST',
    }),
  loanInstallments: (loanId) => request(`/loans/${loanId}/installments`),
  loanGuarantees: (loanId) => request(`/loans/${loanId}/guarantees`),
  addLoanGuarantee: (loanId, payload) =>
    request(`/loans/${loanId}/guarantees`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),

  // Repayments & Collections
  repayments: () => request('/repayments'),
  postRepayment: (payload) => {
    const key = payload.idempotencyKey || `pay_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    return request('/repayments', {
      method: 'POST',
      headers: { 'Idempotency-Key': key },
      body: JSON.stringify({
        loanId: payload.loanId,
        amount: payload.amount,
        channel: payload.channel || 'FIELD',
        expectedVersion: payload.expectedVersion ?? 0,
        paidByName: payload.paidByName || null,
        payerRelation: payload.payerRelation || 'SELF',
      }),
    });
  },
  postBatchRepayments: (collections) =>
    request('/repayments/batch', {
      method: 'POST',
      body: JSON.stringify({ collections }),
    }),
  reverseRepayment: (repaymentId) =>
    request(`/repayments/${repaymentId}/reverse`, {
      method: 'POST',
    }),

  // Transaction Ledger & Integrity
  ledger: () => request('/ledger'),
  verifyLedger: () => request('/ledger/verify', { method: 'POST' }),

  // End-of-Day Delinquency & Accrual Engine
  runEodAccrual: (asOfDate) =>
    request('/admin/eod-accrual', {
      method: 'POST',
      body: JSON.stringify({ asOfDate: asOfDate || null }),
    }),

  // Payment Terminal & Gateway Transactions
  transactions: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/transactions${query ? `?${query}` : ''}`);
  },
  initiateTransaction: (payload) =>
    request('/transactions/initiate', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  completeTransaction: (transactionId, payload = {}) =>
    request(`/transactions/${transactionId}/complete`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  failTransaction: (transactionId, payload = {}) =>
    request(`/transactions/${transactionId}/fail`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  abortTransaction: (transactionId, payload = {}) =>
    request(`/transactions/${transactionId}/abort`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  simulateLoanCreation: (payload) =>
    request('/transactions/loan-create', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
};
