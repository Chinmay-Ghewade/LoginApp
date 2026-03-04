<%@ page import="java.text.SimpleDateFormat" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String branchCode = (String) sess.getAttribute("branchCode");
    String bankCode   = (String) sess.getAttribute("bankCode");
    String user       = (String) sess.getAttribute("userId");
    String today      = new SimpleDateFormat("dd-MM-yyyy").format(new java.util.Date());
    if (bankCode == null) bankCode = "";
    if (user    == null) user     = "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Shares Refund</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: Arial, sans-serif;
    background: #E6E6FA;
    min-height: 100vh;
    padding: 28px 32px;
    color: #1a1464;
  }

  .page-title {
    text-align: center;
    font-size: 1.5rem;
    font-weight: 700;
    color: #1a1464;
    margin-bottom: 6px;
    letter-spacing: 0.3px;
  }

  .meta-bar {
    display: flex;
    justify-content: center;
    gap: 30px;
    font-size: 0.78rem;
    font-weight: 600;
    color: #3a3a7a;
    margin-bottom: 22px;
  }
  .meta-bar b { color: #1a1464; font-weight: 700; }

  /* ── Section card ── */
  .section-card {
    background: #E6E6FA;
    border: 1.5px solid #B8B8E6;
    border-radius: 10px;
    padding: 24px 20px 18px;
    margin-bottom: 18px;
    position: relative;
  }
  .section-card .card-title {
    position: absolute;
    top: -12px;
    left: 16px;
    background: #E6E6FA;
    padding: 0 8px;
    font-size: 0.85rem;
    font-weight: 700;
    color: #1a1464;
  }

  /* ── Form rows ── */
  .form-row {
    display: flex;
    gap: 16px;
    margin-bottom: 14px;
    align-items: flex-end;
    flex-wrap: wrap;
  }
  .form-row:last-child { margin-bottom: 0; }

  .fg      { display: flex; flex-direction: column; gap: 5px; flex: 1; min-width: 100px; }
  .fg-auto { flex: 0 0 auto; }
  .fg-2    { flex: 2; }
  .fg-3    { flex: 3; }
  .fg-180  { flex: 0 0 180px; }
  .fg-220  { flex: 0 0 220px; }

  /* ── Labels ── */
  .fg label, .sub-label {
    font-size: 0.75rem;
    font-weight: 700;
    color: #1a1464;
    white-space: nowrap;
    display: block;
    margin-bottom: 4px;
  }

  /* ── Inputs ── */
  input[type="text"],
  input[type="number"],
  input[type="date"] {
    height: 34px;
    padding: 0 10px;
    border: 1.5px solid #B8B8E6;
    border-radius: 6px;
    font-size: 0.83rem;
    font-family: inherit;
    color: #1a1464;
    background: #ffffff;
    outline: none;
    width: 100%;
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  input[type="text"]:focus,
  input[type="number"]:focus,
  input[type="date"]:focus {
    border-color: #5b5fbf;
    box-shadow: 0 0 0 3px rgba(91,95,191,0.12);
  }
  input[readonly], input[disabled] {
    background: #E0E0E0;
    color: #5a5a90;
    cursor: default;
  }

  /* ── Inline input + button ── */
  .input-btn { display: flex; gap: 5px; align-items: center; }
  .input-btn input { flex: 1; }

  /* ── Radio ── */
  .radio-row {
    display: flex;
    align-items: center;
    gap: 22px;
    height: 34px;
  }
  .radio-row label {
    display: flex;
    align-items: center;
    gap: 7px;
    font-size: 0.83rem;
    font-weight: 600;
    color: #1a1464;
    cursor: pointer;
  }
  input[type="radio"] {
    width: 15px; height: 15px;
    accent-color: #5b5fbf;
    cursor: pointer;
  }

  /* ── Red value ── */
  .red-val { color: #c04040 !important; font-weight: 700 !important; }

  /* ── Share Details table header ── */
  .share-header {
    display: grid;
    grid-template-columns: 40px 1fr 1fr 1fr 1fr 1fr;
    gap: 8px;
    font-size: 0.73rem;
    font-weight: 700;
    color: #1a1464;
    padding: 6px 4px;
    border-bottom: 1.5px solid #B8B8E6;
    margin-bottom: 10px;
  }

  /* ── Totals row ── */
  .totals-row {
    display: flex;
    gap: 16px;
    align-items: flex-end;
    margin-bottom: 14px;
    flex-wrap: wrap;
  }

  /* ── Buttons ── */
  .btn-lookup {
    height: 34px;
    min-width: 40px;
    padding: 0 10px;
    background: #fff;
    color: #1a1464;
    border: 1.5px solid #B8B8E6;
    border-radius: 6px;
    font-size: 0.85rem;
    font-weight: 700;
    cursor: pointer;
    transition: background 0.12s;
  }
  .btn-lookup:hover { background: #eceef8; }

  .btn-check {
    height: 34px;
    padding: 0 18px;
    background: #fff;
    color: #1a1464;
    border: 1.5px solid #B8B8E6;
    border-radius: 6px;
    font-size: 0.78rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    transition: background 0.12s;
  }
  .btn-check:hover { background: #eceef8; }

  .btn-save {
    height: 40px;
    padding: 0 52px;
    background: #3dbb5e;
    color: #fff;
    border: none;
    border-radius: 6px;
    font-size: 0.9rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    transition: background 0.12s;
  }
  .btn-save:hover { background: #2ea84f; }

  .btn-action {
    height: 36px;
    padding: 0 20px;
    background: #fff;
    color: #1a1464;
    border: 1.5px solid #B8B8E6;
    border-radius: 6px;
    font-size: 0.78rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    transition: background 0.12s;
  }
  .btn-action:hover { background: #eceef8; }

  .btn-cancel {
    height: 36px;
    padding: 0 20px;
    background: #fff;
    color: #c04040;
    border: 1.5px solid #c04040;
    border-radius: 6px;
    font-size: 0.78rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    transition: background 0.12s;
  }
  .btn-cancel:hover { background: #fff0f0; }

  /* ── Message bar ── */
  .message-bar {
    display: flex;
    align-items: center;
    gap: 10px;
    margin: 14px 0 18px;
  }
  .message-bar .msg-label {
    font-size: 0.78rem;
    font-weight: 700;
    color: #1a1464;
    white-space: nowrap;
  }
  #messageBox {
    flex: 1;
    height: 34px;
    padding: 0 12px;
    border-radius: 6px;
    border: 1.5px solid #e0a0a0;
    background: #fff5f5;
    color: #c04040;
    font-size: 0.83rem;
    font-weight: 600;
    font-family: inherit;
    outline: none;
  }

  /* ── Action bar ── */
  .action-bar {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
  }
</style>
</head>
<body>

<!-- Title -->
<div class="page-title">Shares Refund</div>

<!-- Meta bar -->
<div class="meta-bar">
  <span>BANK CODE : <b><%= bankCode %></b></span>
  <span>BRANCH CODE : <b><%= branchCode %></b></span>
  <span>USER : <b><%= user %></b></span>
  <span>DATE : <b><%= today %></b></span>
</div>

<!-- ════════════ ACCOUNT INFO ════════════ -->
<div class="section-card">
  <span class="card-title">Account Info</span>

  <!-- Row 1: Account Code | Account Name -->
  <div class="form-row">
    <div class="fg fg-220">
      <label>Account Code</label>
      <div class="input-btn">
        <input type="text" id="accountCode" name="accountCode" />
        <button class="btn-lookup" type="button" onclick="checkAccount()">...</button>
      </div>
    </div>
    <div class="fg fg-3">
      <label>Account Name</label>
      <input type="text" id="accountName" name="accountName" readonly />
    </div>
  </div>

  <!-- Row 2: GL Account Code | GL Account Name -->
  <div class="form-row">
    <div class="fg fg-220">
      <label>GL Account Code</label>
      <input type="text" id="glAccountCode" name="glAccountCode" readonly />
    </div>
    <div class="fg fg-3">
      <label>GL Account Name</label>
      <input type="text" id="glAccountName" name="glAccountName" readonly />
    </div>
  </div>

  <!-- Row 3: Ledger Bal | Available Bal | New Ledger Bal | Check -->
  <div class="form-row">
    <div class="fg">
      <label>Ledger Balance</label>
      <input type="text" id="ledgerBalance" name="ledgerBalance" readonly />
    </div>
    <div class="fg">
      <label>Available Balance</label>
      <input type="text" id="availableBalance" name="availableBalance" readonly />
    </div>
    <div class="fg">
      <label>New Ledger Bal.</label>
      <input type="text" id="newLedgerBal" name="newLedgerBal" readonly />
    </div>
    <div class="fg-auto" style="padding-bottom:0;">
      <button class="btn-check" type="button" onclick="checkAccount()">Check</button>
    </div>
  </div>
</div>

<!-- ════════════ SHARE DETAILS ════════════ -->
<div class="section-card">
  <span class="card-title">Share Details</span>

  <!-- Table Header -->
  <div class="share-header">
    <span>Check</span>
    <span>Certificate No</span>
    <span>Issue Date</span>
    <span>Face Value</span>
    <span>No. of Shares</span>
    <span>Share Amount</span>
  </div>

  <!-- Totals Row -->
  <div class="totals-row">
    <div class="fg fg-220">
      <label>Total No. of Shares</label>
      <input type="text" id="totalNoShares" name="totalNoShares" value="0" readonly class="red-val" />
    </div>
    <div class="fg fg-220">
      <label>Total Face Value</label>
      <input type="text" id="totalFaceValue" name="totalFaceValue" value="0.00" readonly class="red-val" />
    </div>
    <div class="fg fg-220">
      <label>Total Amount</label>
      <input type="text" id="totalAmount" name="totalAmount" value="0.00" readonly class="red-val" />
    </div>
  </div>

  <!-- Remark -->
  <div class="form-row">
    <div class="fg" style="max-width: 660px;">
      <label>Remark</label>
      <input type="text" id="remark" name="remark" />
    </div>
  </div>

  <!-- Meeting Date -->
  <div class="form-row">
    <div class="fg fg-180">
      <label>Meeting Date</label>
      <input type="date" id="meetingDate" name="meetingDate" />
    </div>
  </div>
</div>

<!-- ════════════ TRANSACTION DETAILS ════════════ -->
<div class="section-card">
  <span class="card-title">Transaction Details</span>

  <!-- Mode of Payment -->
  <div class="form-row" style="align-items:flex-end;">
    <div class="fg-auto">
      <span class="sub-label">Mode Of Payment</span>
      <div class="radio-row">
        <label>
          <input type="radio" name="modeOfPayment" value="Cash" id="modeCash" checked onchange="togglePaymentMode()" />
          Cash
        </label>
        <label>
          <input type="radio" name="modeOfPayment" value="Transfer" id="modeTransfer" onchange="togglePaymentMode()" />
          Transfer
        </label>
      </div>
    </div>
  </div>

  <!-- Transfer A/c -->
  <div class="form-row">
    <div class="fg fg-220">
      <label>Transfer A/c. Code</label>
      <div class="input-btn">
        <input type="text" id="transferAcCode" name="transferAcCode" disabled />
        <button class="btn-lookup" id="transferAcBtn" type="button" disabled onclick="lookupTransferAc()">...</button>
      </div>
    </div>
    <div class="fg fg-3">
      <label>Transfer A/c. Name</label>
      <input type="text" id="transferAcName" name="transferAcName" readonly />
    </div>
  </div>
</div>

<!-- Message -->
<div class="message-bar">
  <span class="msg-label">Message :</span>
  <input type="text" id="messageBox" readonly value="Please logout and login again!" />
</div>

<!-- Action Buttons -->
<div class="action-bar">
  <button class="btn-action" type="button" onclick="validateForm()">Validate</button>
  <button class="btn-save"   type="button" onclick="saveForm()">Save</button>
  <button class="btn-action" type="button" onclick="displayVouchers()">Vouchers</button>
  <button class="btn-cancel" type="button" onclick="cancelForm()">Cancel</button>
</div>

<script>
  function togglePaymentMode() {
    var isT = document.getElementById('modeTransfer').checked;
    document.getElementById('transferAcCode').disabled = !isT;
    document.getElementById('transferAcBtn').disabled  = !isT;
  }

  function setMessage(msg, isError) {
    var b = document.getElementById('messageBox');
    b.value             = msg;
    b.style.color       = isError ? '#c04040' : '#1a7a3a';
    b.style.background  = isError ? '#fff5f5' : '#f0fff4';
    b.style.borderColor = isError ? '#e0a0a0' : '#7ad0a0';
  }

  function checkAccount()     { setMessage('Checking account...', false); }
  function lookupTransferAc() { setMessage('Looking up transfer account...', false); }
  function validateForm()     { setMessage('Form validated successfully.', false); }
  function saveForm()         { setMessage('Record saved successfully.', false); }
  function displayVouchers()  { setMessage('Loading vouchers...', false); }

  function cancelForm() {
    if (confirm('Cancel and clear the form?')) {
      document.querySelectorAll('input[type="text"], input[type="number"], input[type="date"]').forEach(function(i) {
        if (!i.readOnly && !i.disabled) i.value = '';
      });
      document.getElementById('totalNoShares').value  = '0';
      document.getElementById('totalFaceValue').value = '0.00';
      document.getElementById('totalAmount').value    = '0.00';
      setMessage('Form cleared.', false);
    }
  }
</script>
</body>
</html>
