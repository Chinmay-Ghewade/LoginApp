<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RTGS Outward Entry</title>
	<link rel="stylesheet" href="../../css/rtgs.css">
	<link rel="stylesheet" href="../../css/tabs-navigation.css">
	<link rel="stylesheet" href="../../css/lookup-modal.css">
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    .page-header {
      text-align: center;
      font-size: 24px;
      font-weight: bold;
      color: #373279;
      margin: 20px 0 30px 0;
      letter-spacing: 1px;
    }

    select.dd-loading {
      color: #999;
      background-color: #f9f9f9;
      font-style: italic;
    }

    .form-buttons { display: flex !important; }
    
    form { padding: 0 20px; }

    .input-icon-box {
      position: relative;
      width: 90%;
    }
    .input-icon-box input {
      width: 100%;
      padding-right: 40px;
      height: 30px;
      cursor: pointer;
      box-sizing: border-box;
    }
    .input-icon-box .inside-icon-btn {
      position: absolute;
      right: 5px;
      top: 50%;
      transform: translateY(-50%);
      background: none;
      border: none;
      font-size: 16px;
      cursor: pointer;
      color: #373279;
    }

    .inline-radio-row {
      display: flex;
      align-items: center;
      gap: 20px;
      flex-wrap: wrap;
    }
    .inline-radio-row .radio-group { flex-direction: row; }

    .rtgs-success-modal {
      display: none;
      position: fixed;
      inset: 0;
      z-index: 9999;
      background: rgba(0,0,0,0.45);
      align-items: center;
      justify-content: center;
    }
    .rtgs-success-modal.open { display: flex; }
    .rtgs-success-card {
      background: #fff;
      border-radius: 18px;
      padding: 36px 40px 30px 40px;
      text-align: center;
      box-shadow: 0 12px 48px rgba(55,50,121,0.22);
      max-width: 420px;
      width: 90%;
      animation: popIn 0.28s cubic-bezier(.34,1.56,.64,1);
    }
    @keyframes popIn {
      from { transform: scale(0.7); opacity: 0; }
      to   { transform: scale(1);   opacity: 1; }
    }
    .rtgs-success-icon {
      width: 68px; height: 68px;
      border-radius: 50%;
      background: linear-gradient(135deg,#373279,#5a3ec8);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 18px auto;
      font-size: 32px;
    }
    .rtgs-success-card h2 {
      color: #373279; font-size: 1.25rem;
      margin: 0 0 8px 0; font-family: Arial,sans-serif;
    }
    .rtgs-success-card p {
      color: #666; font-size: 0.9rem;
      margin: 5px 0; font-family: Arial,sans-serif;
    }
    .rtgs-success-detail-box {
      background: #f4f2fc; border-radius: 10px;
      padding: 14px 20px; margin: 16px 0; text-align: left;
    }
    .rtgs-success-detail-row {
      display: flex; justify-content: space-between;
      font-family: Arial,sans-serif; font-size: 0.88rem;
      padding: 4px 0; border-bottom: 1px solid #e0daf5;
    }
    .rtgs-success-detail-row:last-child { border-bottom: none; }
    .rtgs-success-detail-row span:first-child { color: #888; }
    .rtgs-success-detail-row span:last-child  { color: #373279; font-weight: 700; }
    .rtgs-success-ok-btn {
      background: linear-gradient(135deg,#373279,#5a3ec8);
      color: #fff; border: none; border-radius: 8px;
      padding: 11px 48px; font-size: 1rem; font-weight: 700;
      cursor: pointer; font-family: Arial,sans-serif;
      margin-top: 6px; transition: opacity 0.2s;
    }
    .rtgs-success-ok-btn:hover { opacity: 0.88; }
    
    .row-hidden { display: none; }

    /* ═══════════════════════════════════════════════
       IFSC LIVE-SEARCH DROPDOWN
    ═══════════════════════════════════════════════ */

    .ifsc-results            { position: absolute; top: calc(100% + 4px); left: 0;
                               min-width: 540px; max-height: 300px; overflow-y: auto;
                               background: #fff; border: 2px solid #8066E8;
                               border-radius: 8px;
                               box-shadow: 0 4px 14px rgba(0,0,0,0.15);
                               z-index: 2000; display: none; }
    .ifsc-results.active     { display: block; }

    .ifsc-result-item        { display: flex; align-items: center; gap: 10px;
                               padding: 10px 14px; cursor: pointer;
                               border-bottom: 1px solid #f0f0f0;
                               transition: background 0.18s, transform 0.15s; }
    .ifsc-result-item:last-child { border-bottom: none; }
    .ifsc-result-item:hover  { background: #e8e4fc; transform: translateX(4px); }

    .ifsc-col-code   { font-weight: bold; color: #3D316F; min-width: 130px; font-size: 13px; }
    .ifsc-col-bank   { color: #0306ff; font-weight: bold; flex: 1; font-size: 13px; }
    .ifsc-col-branch { color: #a52323; font-size: 12px; min-width: 130px; }

    /* account search columns (reuses same dropdown) */
    .acc-col-code    { font-weight: bold; color: #3D316F; min-width: 140px; font-size: 13px; }
    .acc-col-name    { color: #0306ff; font-weight: bold; flex: 1; font-size: 13px; padding-left: 10px; }
    .acc-col-product { color: #a52323; font-size: 12px; white-space: nowrap; }

    .ifsc-msg        { padding: 12px 15px; text-align: center;
                       color: #999; font-size: 13px; font-style: italic; }
    .ifsc-loading    { padding: 14px; text-align: center; color: #8066E8; font-size: 13px; }
    .ifsc-highlight  { background: #ffeb3b; font-weight: bold;
                       padding: 1px 2px; border-radius: 2px; }
    .ifsc-hint       { font-size: 12px; color: #666; margin-top: 4px; font-style: italic; }

    .ifsc-results::-webkit-scrollbar       { width: 7px; }
    .ifsc-results::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 4px; }
    .ifsc-results::-webkit-scrollbar-thumb { background: #8066E8; border-radius: 4px; }
  </style>
  
</head>
<body>

<!-- PAGE HEADER -->
<div class="page-header">RTGS OUTWARD ENTRY</div>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- RTGS SUCCESS MODAL                                             -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="rtgsSuccessModal" class="rtgs-success-modal">
  <div class="rtgs-success-card">
    <div class="rtgs-success-icon">✅</div>
    <h2>RTGS Request Submitted Successfully!</h2>
    <p>Your RTGS transaction has been registered.</p>
    <div class="rtgs-success-detail-box">
      <div class="rtgs-success-detail-row">
        <span>Transaction ID</span>
        <span id="successTransactionId">—</span>
      </div>
      <div class="rtgs-success-detail-row">
        <span>Beneficiary Name</span>
        <span id="successBeneficiaryName">—</span>
      </div>
      <div class="rtgs-success-detail-row">
        <span>Amount</span>
        <span id="successAmount">—</span>
      </div>
      <div class="rtgs-success-detail-row">
        <span>Status</span>
        <span id="successStatus">Submitted</span>
      </div>
    </div>
    <button class="rtgs-success-ok-btn" onclick="closeRtgsSuccessModal()">OK</button>
  </div>
</div>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOOKUP MODAL  (shared for Account lookup AND IFSC lookup)       -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lookupModal" class="lookup-modal-wrap" style="display:none;">
    <div class="lookup-modal-box">
        <button class="lookup-modal-box-close" onclick="closeLookup()">&#10006;</button>
        <div id="lookupContent"></div>
    </div>
</div>

<form id="rtgsForm" onsubmit="submitRtgsForm(event)">

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- RTGS Details                                                   -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>RTGS Details</legend>
    <div class="form-grid">

      <div>
        <label>Transaction Mode</label>
        <div class="inline-radio-row radio-group">
          <label><input type="radio" name="transactionMode" value="Transfer" checked onchange="toggleModeSections(this.value)"> Transfer</label>
          <label><input type="radio" name="transactionMode" value="Cash"     onchange="toggleModeSections(this.value)"> Cash</label>
        </div>
      </div>

      <div>
        <label>Transaction Type</label>
        <div class="inline-radio-row radio-group">
          <label><input type="radio" name="transactionType" value="RTGS" checked> RTGS</label>
          <label><input type="radio" name="transactionType" value="NEFT"> NEFT</label>
          <label><input type="radio" name="transactionType" value="ThirdParty"> Third Party</label>
        </div>
      </div>
    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- TRANSFER DETAILS                                               -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Transfer Details</legend>
    <div class="form-grid">

      <div>
        <label>Account Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="accountCode" id="accountCode" class="form-input"
                 autocomplete="off" placeholder="Enter account code"
                 oninput="handleAccLiveSearch(this.value)"
                 onblur="scheduleAccClose()">
          <button type="button" class="icon-btn" onclick="openAccountLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
        <!-- account live-search results -->
        <div style="position:relative;">
          <div class="ifsc-results" id="accResults"></div>
        </div>
        <div class="ifsc-hint">Type last 3+ digits to search</div>
      </div>

      <div>
        <label>Account Name</label>
        <input type="text" name="accountName" id="accountName" readonly>
      </div>

      <div>
        <label>Address 1</label>
        <input type="text" name="address1" id="address1">
      </div>

      <div>
        <label>Address 2</label>
        <input type="text" name="address2" id="address2">
      </div>

      <div>
        <label>Address 3</label>
        <input type="text" name="address3" id="address3">
      </div>

      <div>
        <label>Ledger Balance</label>
        <input type="text" name="ledgerBalance" id="ledgerBalance" readonly>
      </div>

      <div>
        <label>Available Balance</label>
        <input type="text" name="availableBalance" id="availableBalance" readonly>
      </div>

      <div>
        <label>New Ledger Balance</label>
        <input type="text" name="newLedgerBalance" id="newLedgerBalance" readonly>
      </div>

      <div>
        <label>Cheque Type</label>
        <select name="chequeType" id="chequeType" class="form-input">
          <option value="">Select Cheque Type</option>
        </select>
      </div>

      <div>
        <label>Cheque Series</label>
        <select name="chequeSeries" id="chequeSeries" class="form-input">
          <option value="">Select Cheque Series</option>
        </select>
      </div>

      <div>
        <label>Cheque Number</label>
        <select name="chequeNumber" id="chequeNumber" class="form-input">
          <option value="">Select Cheque No</option>
        </select>
      </div>

      <div>
        <label>Cheque Date</label>
        <input type="date" name="chequeDate" id="chequeDate">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- CASH DETAILS                                                   -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Cash Details</legend>
    <div class="form-grid">

      <div>
        <label>Name Of Applicant</label>
        <input type="text" name="nameOfApplicant" id="nameOfApplicant">
      </div>

      <div>
        <label>Address1</label>
        <input type="text" name="cashAddress1" id="cashAddress1">
      </div>

      <div>
        <label>Address2</label>
        <input type="text" name="cashAddress2" id="cashAddress2">
      </div>

      <div>
        <label>Address3</label>
        <input type="text" name="cashAddress3" id="cashAddress3">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- REMITTER DETAILS                                               -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Remitter Details</legend>
    <div class="form-grid">

      <div>
        <label>Remitting Banks IFSC CODE</label>
        <input type="text" name="remittingIfscCode" id="remittingIfscCode">
      </div>

      <div>
        <label>Application contact no(M)</label>
        <input type="text" name="appContactNo" id="appContactNo">
      </div>

      <div>
        <label>Residence</label>
        <input type="text" name="residenceNo" id="residenceNo">
      </div>

      <div>
        <label>Office</label>
        <input type="text" name="officeNo" id="officeNo">
      </div>

      <div>
        <label>Application Email ID</label>
        <input type="email" name="appEmailId" id="appEmailId">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- BENEFICIARY DETAILS                                            -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Beneficiary Details</legend>
    <div class="form-grid">

      <div>
        <label>Beneficiary Name</label>
        <input type="text" name="beneficiaryName" id="beneficiaryName" required>
      </div>

      <div>
        <label>Beneficiary Account Code</label>
        <input type="text" name="beneficiaryAccountCode" id="beneficiaryAccountCode" required>
      </div>

      <!-- ── IFSC Code — live search + lookup button ── -->
      <div>
        <label>IFSC Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text"
                 name="ifscCode"
                 id="ifscCode"
                 required
                 autocomplete="off"
                 placeholder="Enter or search IFSC"
                 oninput="handleIfscLiveSearch(this.value)"
                 onblur="scheduleIfscClose()">
          <button type="button" class="icon-btn" onclick="openIfscLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
        <!-- live-search results dropdown -->
        <div style="position:relative;">
          <div class="ifsc-results" id="ifscResults"></div>
        </div>
        <div class="ifsc-hint">Type first 3+ letters to search</div>
      </div>

      <div>
        <label>IFSC Bank Name</label>
        <input type="text" name="ifscBankName" id="ifscBankName" readonly>
      </div>

      <div>
        <label>IFSC Branch Name</label>
        <input type="text" name="ifscBranchName" id="ifscBranchName" readonly>
      </div>

      <div>
        <label>Beneficiary Contact No (M)</label>
        <input type="text" name="beneficiaryMobile" id="beneficiaryMobile">
      </div>

      <div>
        <label>Residence</label>
        <input type="text" name="beneficiaryResidence" id="beneficiaryResidence">
      </div>

      <div>
        <label>Office</label>
        <input type="text" name="beneficiaryOffice" id="beneficiaryOffice">
      </div>

      <div>
        <label>Beneficiary Address 1</label>
        <input type="text" name="beneficiaryAddress1" id="beneficiaryAddress1">
      </div>

      <div>
        <label>Beneficiary Address 2</label>
        <input type="text" name="beneficiaryAddress2" id="beneficiaryAddress2">
      </div>

      <!-- ✅ CHANGED: City and State are now readonly text inputs -->
      <div>
        <label>City</label>
        <input type="text" name="beneficiaryCity" id="beneficiaryCity" readonly>
      </div>

      <div>
        <label>State</label>
        <input type="text" name="beneficiaryState" id="beneficiaryState" readonly>
      </div>

      <div>
        <label>Sender To Receiver Info</label>
        <input type="text" name="SenderToReceiver" id="SenderToReceiver">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- PAYMENT DETAILS                                                -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Payment Details</legend>
    <div class="form-grid">

      <div>
        <label>Remitting Amount</label>
        <input type="text" name="remittingAmount" id="remittingAmount" value="0"
               oninput="this.value=this.value.replace(/[^0-9.]/g,''); calculateTotal();" required>
      </div>

      <div>
        <label>Applicable Charges</label>
        <input type="text" name="applicableCharges" id="applicableCharges" value="0"
               oninput="this.value=this.value.replace(/[^0-9.]/g,''); calculateTotal();">
      </div>

      <div>
        <label>Service Tax</label>
        <input type="text" name="serviceTax" id="serviceTax" value="0"
               oninput="this.value=this.value.replace(/[^0-9.]/g,''); calculateTotal();">
      </div>

      <div>
        <label>Total Amount</label>
        <input type="text" name="totalAmount" id="totalAmount" value="0" readonly>
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- BUTTONS                                                        -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="button" class="action-btn btn-validate"  onclick="validateRtgsForm()">Validate</button>
    <button type="submit"                class="action-btn btn-save">Save</button>
    <button type="button" class="action-btn btn-vouchers"  onclick="displayVouchers()">Display Vouchers</button>
    <button type="button" class="action-btn btn-signature" onclick="captureSignature()">Display Signature</button>
    <button type="button" class="action-btn btn-cancel"    onclick="resetRtgsForm()">Cancel</button>
  </div>

</form>

<!-- Validation Error Modal -->
<div id="rtgsErrorModal" style="
    display:none; position:fixed; top:0; left:0;
    width:100%; height:100%; background:rgba(0,0,0,0.5);
    justify-content:center; align-items:center; z-index:10001;">
  <div style="background:white; width:480px; padding:40px; border-radius:12px;
              box-shadow:0 4px 20px rgba(0,0,0,0.3); text-align:center;">
    <div style="color:#e53935; font-size:48px; margin-bottom:20px;">✕</div>
    <div id="rtgsErrorMessage" style="font-size:18px; font-weight:bold; color:#333;
                                      margin-bottom:30px; line-height:1.5;"></div>
    <button onclick="closeRtgsErrorModal()"
            style="background:#e53935; color:white; border:none; padding:12px 50px;
                   border-radius:6px; font-size:16px; font-weight:bold; cursor:pointer;"
            onmouseover="this.style.background='#c62828'"
            onmouseout="this.style.background='#e53935'">OK</button>
  </div>
</div>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ── Which lookup is currently open: 'account' | 'ifsc'
let _currentLookupTarget = null;
let _filterTimer = null;
let _rowCache    = null;

// ──────────────────────────────────────────────────────────────────────
// ERROR MODAL
// ──────────────────────────────────────────────────────────────────────
function showRtgsError(message) {
    document.getElementById('rtgsErrorMessage').textContent = message;
    document.getElementById('rtgsErrorModal').style.display = 'flex';
}
function closeRtgsErrorModal() {
    document.getElementById('rtgsErrorModal').style.display = 'none';
}

// ──────────────────────────────────────────────────────────────────────
// INITIALIZATION
// ──────────────────────────────────────────────────────────────────────
window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath
                ? window.buildBreadcrumbPath('Transactions/rtgs.jsp')
                : 'Transactions > RTGS / NEFT > RTGS Outward'
        );
    }

    document.getElementById('rtgsSuccessModal').addEventListener('click', function(e) {
        if (e.target === this) closeRtgsSuccessModal();
    });
    document.getElementById('lookupModal').addEventListener('click', function(e) {
        if (e.target === this) closeLookup();
    });
    document.getElementById('rtgsErrorModal').addEventListener('click', function(e) {
        if (e.target === this) closeRtgsErrorModal();
    });

    toggleModeSections('Transfer');
};

// ──────────────────────────────────────────────────────────────────────
// SHARED LOOKUP MODAL OPEN / CLOSE
// ──────────────────────────────────────────────────────────────────────
function _openLookup(type, extraParams) {
    _currentLookupTarget = type;
    _rowCache = null;

    let url = '../LookupForTransactions.jsp?type=' + type;
    if (extraParams) url += '&' + extraParams;

    fetch(url)
        .then(function(r) { return r.text(); })
        .then(function(html) {
            document.getElementById('lookupContent').innerHTML = html;
            _rowCache = null;
            buildRowCache();
            document.getElementById('lookupModal').style.display = 'flex';
            setTimeout(function() {
                const sb = document.getElementById('searchBox');
                if (sb) sb.focus();
            }, 100);
        })
        .catch(function(err) {
            showRtgsError('Failed to load lookup data.');
            console.error('Lookup error:', err);
        });
}

function closeLookup() {
    document.getElementById('lookupModal').style.display = 'none';
    _currentLookupTarget = null;
    _rowCache = null;
}

// ──────────────────────────────────────────────────────────────────────
// ACCOUNT LOOKUP (modal)
// ──────────────────────────────────────────────────────────────────────
function openAccountLookup() {
    _openLookup('account', 'accountCategory=rtgs');
}

// ──────────────────────────────────────────────────────────────────────
// IFSC LOOKUP (modal — fallback)
// ──────────────────────────────────────────────────────────────────────
function openIfscLookup() {
    _openLookup('ifsc', '');
}

// ──────────────────────────────────────────────────────────────────────
// sendBack — called by rows in LookupForTransactions.jsp
// ──────────────────────────────────────────────────────────────────────
function sendBack(a, b, c, d, e, f) {
    if (d === 'ifsc' || c === 'ifsc') {
        setIfscFromLookup(a, b, c, e, f);
    } else {
        setValueFromLookup(a, b, c);
    }
}

// ──────────────────────────────────────────────────────────────────────
// SET ACCOUNT FROM LOOKUP
// ──────────────────────────────────────────────────────────────────────
function setValueFromLookup(code, desc, type) {
    if (type === 'account') {
        document.getElementById('accountCode').value = code;
        document.getElementById('accountName').value = desc;
        document.getElementById('accResults').classList.remove('active');
        fetchAccountDetails(code);
        setTimeout(function() { loadChequeData(); }, 500);
    }
    closeLookup();
}

// ──────────────────────────────────────────────────────────────────────
// SET IFSC FROM LOOKUP (modal) or live-search selection
// ──────────────────────────────────────────────────────────────────────
// ✅ UPDATED: Now accepts districtName and stateName parameters
function setIfscFromLookup(ifscCode, bankName, branchName, districtName, stateName) {
    document.getElementById('ifscCode').value       = ifscCode   || '';
    document.getElementById('ifscBankName').value   = bankName   || '';
    document.getElementById('ifscBranchName').value = branchName || '';
    
    // ✅ AUTO-POPULATE CITY AND STATE FROM IFSC
    document.getElementById('beneficiaryCity').value = districtName || '';
    document.getElementById('beneficiaryState').value = stateName || '';
    
    // Close live-search dropdown if open
    const d = document.getElementById('ifscResults');
    if (d) d.classList.remove('active');
    closeLookup();
}

// ══════════════════════════════════════════════════════════════════════
// IFSC LIVE-SEARCH
// ══════════════════════════════════════════════════════════════════════
const IFSC_MIN_LEN  = 3;
const IFSC_DELAY_MS = 280;
let   ifscTimer     = null;
let   ifscCloseTimer = null;

function handleIfscLiveSearch(value) {
    // Clear bank/branch on any keystroke
    document.getElementById('ifscBankName').value   = '';
    document.getElementById('ifscBranchName').value = '';

    clearTimeout(ifscTimer);
    const resultsDiv = document.getElementById('ifscResults');

    if (!value || value.trim().length === 0) {
        resultsDiv.classList.remove('active');
        return;
    }

    if (value.trim().length < IFSC_MIN_LEN) {
        resultsDiv.innerHTML = '<div class="ifsc-msg">Type at least ' + IFSC_MIN_LEN + ' characters to search…</div>';
        resultsDiv.classList.add('active');
        return;
    }

    resultsDiv.innerHTML = '<div class="ifsc-loading">🔍 Searching…</div>';
    resultsDiv.classList.add('active');

    ifscTimer = setTimeout(function() {
        _doIfscSearch(value.trim());
    }, IFSC_DELAY_MS);
}

function _doIfscSearch(searchTerm) {
    const resultsDiv = document.getElementById('ifscResults');

    fetch('../SearchAccounts.jsp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'searchNumber=' + encodeURIComponent(searchTerm) + '&category=ifsc'
    })
    .then(function(r) {
        if (!r.ok) throw new Error('Network error');
        return r.json();
    })
    .then(function(data) {
        if (data.error) {
            resultsDiv.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">' + data.error + '</div>';
            return;
        }
        if (data.accounts && data.accounts.length > 0) {
            _renderIfscResults(data.accounts, searchTerm);
        } else {
            resultsDiv.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">No IFSC records found for "' + searchTerm + '"</div>';
        }
    })
    .catch(function(err) {
        console.error('IFSC search error:', err);
        resultsDiv.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">Search failed. Please try again.</div>';
    });
}

// ✅ UPDATED: Include districtName and stateName in rendering
function _renderIfscResults(accounts, searchTerm) {
    const resultsDiv = document.getElementById('ifscResults');
    let html = '';

    accounts.forEach(function(item) {
        // Escape for inline onclick
        const safeCode   = (item.code       || '').replace(/'/g, "\\'");
        const safeName   = (item.name       || '').replace(/'/g, "\\'");
        const safeBranch = (item.branchName || '').replace(/'/g, "\\'");
        const safeDistrict = (item.districtName || '').replace(/'/g, "\\'");  // ✅ NEW
        const safeState  = (item.stateName  || '').replace(/'/g, "\\'");       // ✅ NEW

        const highlightedCode = _ifscHighlight(item.code || '', searchTerm);

        html += '<div class="ifsc-result-item" ' +
                'onmousedown="_selectIfsc(\'' + safeCode + '\',\'' + safeName + '\',\'' + safeBranch + '\',\'' + safeDistrict + '\',\'' + safeState + '\')">' +
                '<span class="ifsc-col-code">'   + highlightedCode        + '</span>' +
                '<span class="ifsc-col-bank">'   + (item.name       || '') + '</span>' +
                '<span class="ifsc-col-branch">' + (item.branchName || '') + '</span>' +
                '</div>';
    });

    resultsDiv.innerHTML = html;
}

function _ifscHighlight(text, search) {
    if (!text || !search) return text;
    const idx = text.toUpperCase().indexOf(search.toUpperCase());
    if (idx === -1) return text;
    return text.substring(0, idx) +
           '<span class="ifsc-highlight">' + text.substring(idx, idx + search.length) + '</span>' +
           text.substring(idx + search.length);
}

// ✅ UPDATED: Called via onmousedown to accept districtName and stateName
function _selectIfsc(ifscCode, bankName, branchName, districtName, stateName) {
    document.getElementById('ifscCode').value       = ifscCode;
    document.getElementById('ifscBankName').value   = bankName;
    document.getElementById('ifscBranchName').value = branchName;
    
    // ✅ AUTO-POPULATE CITY AND STATE FROM IFSC
    document.getElementById('beneficiaryCity').value = districtName || '';
    document.getElementById('beneficiaryState').value = stateName || '';
    
    document.getElementById('ifscResults').classList.remove('active');
}

// Delayed close — lets mousedown on a result fire before blur closes the list
function scheduleIfscClose() {
    clearTimeout(ifscCloseTimer);
    ifscCloseTimer = setTimeout(function() {
        document.getElementById('ifscResults').classList.remove('active');
    }, 200);
}

// Close on outside click
document.addEventListener('click', function(e) {
    if (!e.target.closest('#ifscResults') && e.target.id !== 'ifscCode') {
        const d = document.getElementById('ifscResults');
        if (d) d.classList.remove('active');
    }
    if (!e.target.closest('#accResults') && e.target.id !== 'accountCode') {
        const d = document.getElementById('accResults');
        if (d) d.classList.remove('active');
    }
});

// ESC closes dropdowns
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const di = document.getElementById('ifscResults');
        if (di) di.classList.remove('active');
        const da = document.getElementById('accResults');
        if (da) da.classList.remove('active');
        closeLookup();
    }
});

// ──────────────────────────────────────────────────────────────────────
// FETCH ACCOUNT DETAILS
// ──────────────────────────────────────────────────────────────────────
function fetchAccountDetails(accountCode) {
    if (!accountCode || accountCode.trim() === '') {
        showRtgsError('No account code provided.');
        return;
    }

    fetch('../GetAccountDetails.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.error) {
                showRtgsError('Error: ' + data.error);
            } else {
                document.getElementById('ledgerBalance').value    = data.ledgerBalance    || '0.00';
                document.getElementById('availableBalance').value = data.availableBalance || '0.00';
                document.getElementById('newLedgerBalance').value = data.ledgerBalance    || '0.00';

                if (data.customerAddress && data.customerAddress.trim() !== '') {
                    populateAddressFields(data.customerAddress);
                }
            }
        })
        .catch(function(err) {
            console.error('Error fetching account details:', err);
            showRtgsError('Failed to fetch account details');
        });
}

// ──────────────────────────────────────────────────────────────────────
// PARSE AND POPULATE ADDRESS FIELDS
// ──────────────────────────────────────────────────────────────────────
function populateAddressFields(concatenatedAddress) {
    if (!concatenatedAddress || concatenatedAddress.trim() === '') return;

    var words = concatenatedAddress.trim().split(/\s+/);

    if (words.length <= 3) {
        document.getElementById('address1').value = words[0] || '';
        document.getElementById('address2').value = words[1] || '';
        document.getElementById('address3').value = words[2] || '';
    } else {
        var g = Math.ceil(words.length / 3);
        document.getElementById('address1').value = words.slice(0,   g  ).join(' ');
        document.getElementById('address2').value = words.slice(g,   g*2).join(' ');
        document.getElementById('address3').value = words.slice(g*2      ).join(' ');
    }
}

// ──────────────────────────────────────────────────────────────────────
// LOAD CHEQUE DATA
// ──────────────────────────────────────────────────────────────────────
function loadChequeData() {
    var accountCode = document.getElementById('accountCode').value.trim();
    if (!accountCode) { showRtgsError('Please select an account first'); return; }

    document.getElementById('chequeType').innerHTML   = '<option value="">Loading...</option>';
    document.getElementById('chequeSeries').innerHTML = '<option value="">Loading...</option>';
    document.getElementById('chequeNumber').innerHTML = '<option value="">Loading...</option>';

    fetch('../GetChequeData.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (!data.success) {
                showRtgsError('Cheque data error: ' + (data.error || 'Unknown error'));
                clearChequeDropdowns();
                return;
            }

            if (!data.cheques || data.cheques.length === 0) {
                clearChequeDropdowns('No cheques available');
                return;
            }

            var typeSelect   = document.getElementById('chequeType');
            var seriesSelect = document.getElementById('chequeSeries');
            var noSelect     = document.getElementById('chequeNumber');

            typeSelect.innerHTML   = '<option value="">Select Cheque Type</option>';
            seriesSelect.innerHTML = '<option value="">Select Cheque Series</option>';
            noSelect.innerHTML     = '<option value="">Select Cheque No</option>';

            (data.typeList || []).forEach(function(t) {
                var o = document.createElement('option');
                o.value = o.textContent = t.trim();
                typeSelect.appendChild(o);
            });

            (data.seriesList || []).forEach(function(s) {
                var o = document.createElement('option');
                o.value = o.textContent = s.trim();
                seriesSelect.appendChild(o);
            });

            data.cheques.forEach(function(c) {
                var o = document.createElement('option');
                o.value = o.textContent = c.chequeNumber.trim();
                noSelect.appendChild(o);
            });
        })
        .catch(function(err) {
            console.error('Error loading cheque data:', err);
            showRtgsError('Failed to load cheque data');
            clearChequeDropdowns();
        });
}

function clearChequeDropdowns(message) {
    message = message || 'No cheques available';
    document.getElementById('chequeType').innerHTML   = '<option value="">' + message + '</option>';
    document.getElementById('chequeSeries').innerHTML = '<option value="">' + message + '</option>';
    document.getElementById('chequeNumber').innerHTML = '<option value="">' + message + '</option>';
}

// ──────────────────────────────────────────────────────────────────────
// CALCULATE TOTAL AMOUNT
// ──────────────────────────────────────────────────────────────────────
function calculateTotal() {
    var remitting = parseFloat(document.getElementById('remittingAmount').value) || 0;
    var charges   = parseFloat(document.getElementById('applicableCharges').value) || 0;
    var tax       = parseFloat(document.getElementById('serviceTax').value) || 0;
    document.getElementById('totalAmount').value = (remitting + charges + tax).toFixed(2);
}

// ──────────────────────────────────────────────────────────────────────
// FORM SUBMISSION
// ──────────────────────────────────────────────────────────────────────
function submitRtgsForm(e) {
    e.preventDefault();

    var btn = document.querySelector('button[type="submit"]');
    if (btn.disabled) return;
    btn.disabled = true;
    btn.textContent = 'Submitting…';

    var beneficiaryName = document.getElementById('beneficiaryName').value.trim();
    var accountCode     = document.getElementById('accountCode').value.trim();
    var remittingAmount = document.getElementById('remittingAmount').value.trim();

    if (!beneficiaryName) { btn.disabled=false; btn.textContent='Save'; showRtgsError('Please enter Beneficiary Name.'); return; }
    if (!accountCode)     { btn.disabled=false; btn.textContent='Save'; showRtgsError('Please select Account Code.'); return; }
    if (!remittingAmount || parseFloat(remittingAmount) <= 0) {
        btn.disabled=false; btn.textContent='Save';
        showRtgsError('Please enter a valid Remitting Amount.'); return;
    }

    var formData = new FormData(document.getElementById('rtgsForm'));

    fetch(window.APP_CONTEXT_PATH + '/RtgsServlet', {
        method: 'POST',
        body: formData
    })
    .then(function(res) { return res.json(); })
    .then(function(data) {
        btn.disabled = false;
        btn.textContent = 'Save';
        if (data.success) {
            document.getElementById('successTransactionId').textContent   = data.transactionId   || '—';
            document.getElementById('successBeneficiaryName').textContent = data.beneficiaryName || '—';
            document.getElementById('successAmount').textContent          = '₹ ' + (data.totalAmount || '0.00');
            document.getElementById('rtgsSuccessModal').classList.add('open');
            resetRtgsForm();
        } else {
            showRtgsError(data.message || 'Failed to submit RTGS request.');
        }
    })
    .catch(function(err) {
        btn.disabled = false;
        btn.textContent = 'Save';
        showRtgsError('Network error: ' + err.message);
    });
}

// ──────────────────────────────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────────────────────────────
function closeRtgsSuccessModal() {
    document.getElementById('rtgsSuccessModal').classList.remove('open');
}

function validateRtgsForm() {
    var accountCode     = document.getElementById('accountCode').value.trim();
    var beneficiaryName = document.getElementById('beneficiaryName').value.trim();
    var remittingAmount = document.getElementById('remittingAmount').value.trim();

    if (!accountCode)     { showRtgsError('Please select Account Code.'); return; }
    if (!beneficiaryName) { showRtgsError('Please enter Beneficiary Name.'); return; }
    if (!remittingAmount || parseFloat(remittingAmount) <= 0) {
        showRtgsError('Please enter a valid Remitting Amount.'); return;
    }
    closeRtgsErrorModal();
}

function displayVouchers()  { showRtgsError('Vouchers feature — To be implemented'); }
function captureSignature() { showRtgsError('Signature capture feature — To be implemented'); }

function resetRtgsForm() {
    document.getElementById('rtgsForm').reset();
    ['accountName','ledgerBalance','availableBalance','newLedgerBalance',
    	 'ifscBankName','ifscBranchName','totalAmount'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
    });
    clearChequeDropdowns();
    document.getElementById('remittingAmount').value   = '0';
    document.getElementById('applicableCharges').value = '0';
    document.getElementById('serviceTax').value        = '0';
    document.getElementById('totalAmount').value       = '0';
    // ✅ UPDATED: Clear city/state text fields instead of dropdowns
    document.getElementById('beneficiaryCity').value = '';
    document.getElementById('beneficiaryState').value = '';
    // clear live-search dropdowns
    var di = document.getElementById('ifscResults');
    if (di) di.classList.remove('active');
    var da = document.getElementById('accResults');
    if (da) da.classList.remove('active');
}

// ──────────────────────────────────────────────────────────────────────
// TRANSFER / CASH MODE TOGGLE
// ──────────────────────────────────────────────────────────────────────
function toggleModeSections(mode) {
    document.querySelectorAll('fieldset:nth-of-type(2) input').forEach(function(el) {
        el.readOnly = (mode === 'Cash');
    });
    document.querySelectorAll('fieldset:nth-of-type(3) input').forEach(function(el) {
        el.readOnly = (mode === 'Transfer');
    });
}

// ──────────────────────────────────────────────────────────────────────
// CLIENT-SIDE TABLE FILTER (used by filterTable() in lookup HTML)
// ──────────────────────────────────────────────────────────────────────
function buildRowCache() {
    const table = document.getElementById('lookupTable');
    if (!table) { _rowCache = []; return; }
    _rowCache = Array.from(table.getElementsByClassName('data-row')).map(function(row) {
        var cells = row.querySelectorAll('td');
        var text  = '';
        cells.forEach(function(c) { text += ' ' + c.textContent; });
        return { el: row, text: text.toLowerCase() };
    });
}

function filterTable() {
    clearTimeout(_filterTimer);
    _filterTimer = setTimeout(_applyFilter, 180);
}

function _applyFilter() {
    const searchBox = document.getElementById('searchBox');
    if (!searchBox) return;
    const q = searchBox.value.toLowerCase().trim();

    if (!_rowCache) buildRowCache();

    var visible = 0;
    var hide = q.length >= 2;

    _rowCache.forEach(function(item) {
        var show = !hide || item.text.includes(q);
        item.el.classList.toggle('row-hidden', !show);
        if (show) visible++;
    });

    var noResultsRow = document.getElementById('noResultsRow');
    if (visible === 0) {
        if (!noResultsRow) {
            var table = document.getElementById('lookupTable');
            noResultsRow = table.insertRow(-1);
            noResultsRow.id = 'noResultsRow';
            noResultsRow.innerHTML = '<td colspan="3" class="no-results">No records found</td>';
        }
        noResultsRow.classList.remove('row-hidden');
    } else if (noResultsRow) {
        noResultsRow.classList.add('row-hidden');
    }
}

// ══════════════════════════════════════════════════════════════════════
// ACCOUNT LIVE-SEARCH  (same pattern as IFSC, uses 'rtgs' category)
// ══════════════════════════════════════════════════════════════════════
const ACC_MIN_LEN  = 3;
const ACC_DELAY_MS = 300;
let   accTimer     = null;
let   accCloseTimer = null;

function handleAccLiveSearch(value) {
    // Clear account details on any keystroke
    document.getElementById('accountName').value      = '';
    document.getElementById('ledgerBalance').value    = '';
    document.getElementById('availableBalance').value = '';
    document.getElementById('newLedgerBalance').value = '';

    clearTimeout(accTimer);
    const resultsDiv = document.getElementById('accResults');

    // Only digits allowed — strip non-digits silently
    const digits = value.replace(/\D/g, '');
    document.getElementById('accountCode').value = digits; // keep input digits-only

    if (digits.length === 0) {
        resultsDiv.classList.remove('active');
        return;
    }

    if (digits.length < ACC_MIN_LEN) {
        resultsDiv.innerHTML = '<div class="ifsc-msg">Type at least ' + ACC_MIN_LEN + ' digits to search…</div>';
        resultsDiv.classList.add('active');
        return;
    }

    // Use last 7 digits for search (matches transactions.jsp behaviour)
    const searchNum = digits.length > 7 ? digits.slice(-7) : digits;

    resultsDiv.innerHTML = '<div class="ifsc-loading">🔍 Searching…</div>';
    resultsDiv.classList.add('active');

    accTimer = setTimeout(function() {
        _doAccSearch(searchNum);
    }, ACC_DELAY_MS);
}

function _doAccSearch(searchNum) {
    const resultsDiv = document.getElementById('accResults');

    fetch('../SearchAccounts.jsp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'searchNumber=' + encodeURIComponent(searchNum) + '&category=rtgs'
    })
    .then(function(r) {
        if (!r.ok) throw new Error('Network error');
        return r.json();
    })
    .then(function(data) {
        if (data.error) {
            resultsDiv.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">' + data.error + '</div>';
            return;
        }
        if (data.accounts && data.accounts.length > 0) {
            _renderAccResults(data.accounts, searchNum);
        } else {
            resultsDiv.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">No accounts found for "' + searchNum + '"</div>';
        }
    })
    .catch(function(err) {
        console.error('Account search error:', err);
        resultsDiv.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">Search failed. Please try again.</div>';
    });
}

function _renderAccResults(accounts, searchNum) {
    const resultsDiv = document.getElementById('accResults');
    let html = '';

    accounts.forEach(function(item) {
        const safeName    = (item.name        || '').replace(/'/g, "\\'");
        const safeCode    = (item.code        || '').replace(/'/g, "\\'");
        const productDesc = item.productDesc  || '';
        const highlighted = _accHighlight(item.code || '', searchNum);

        html += '<div class="ifsc-result-item" ' +
                'onmousedown="_selectAcc(\'' + safeCode + '\',\'' + safeName + '\')">' +
                '<span class="acc-col-code">'    + highlighted  + '</span>' +
                '<span class="acc-col-name">'    + (item.name || '') + '</span>';

        if (productDesc.trim() !== '') {
            html += '<span class="acc-col-product">' + productDesc + '</span>';
        }

        html += '</div>';
    });

    resultsDiv.innerHTML = html;
}

function _accHighlight(text, search) {
    if (!text || !search) return text;
    // highlight the last-7-digit area
    const last7   = text.slice(-7);
    const idx     = last7.toUpperCase().indexOf(search.toUpperCase());
    if (idx === -1) return text;
    const absIdx  = text.length - 7 + idx;
    return text.substring(0, absIdx) +
           '<span class="ifsc-highlight">' + text.substring(absIdx, absIdx + search.length) + '</span>' +
           text.substring(absIdx + search.length);
}

// Called via onmousedown — fires before onblur closes the list
function _selectAcc(code, name) {
    document.getElementById('accountCode').value = code;
    document.getElementById('accountName').value = name;
    document.getElementById('accResults').classList.remove('active');

    // Fetch full account details + cheque data
    fetchAccountDetails(code);
    setTimeout(function() { loadChequeData(); }, 400);
}

function scheduleAccClose() {
    clearTimeout(accCloseTimer);
    accCloseTimer = setTimeout(function() {
        document.getElementById('accResults').classList.remove('active');
    }, 200);
}
</script>

</body>
</html>
