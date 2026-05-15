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

    .form-buttons { display: flex !important; }
    form { padding: 0 20px; }

    .input-icon-box { position: relative; width: 90%; }
    .input-icon-box input {
      width: 100%; padding-right: 40px; height: 30px;
      cursor: pointer; box-sizing: border-box;
    }
    .input-icon-box .inside-icon-btn {
      position: absolute; right: 5px; top: 50%;
      transform: translateY(-50%); background: none;
      border: none; font-size: 16px; cursor: pointer; color: #373279;
    }

    .inline-radio-row {
      display: flex; align-items: center; gap: 20px; flex-wrap: wrap;
    }
    .inline-radio-row .radio-group { flex-direction: row; }

    .row-hidden { display: none; }

    /* ── IFSC live-search dropdown ── */
    .ifsc-results {
      position: absolute; top: calc(100% + 4px); left: 0;
      min-width: 540px; max-height: 300px; overflow-y: auto;
      background: #fff; border: 2px solid #8066E8;
      border-radius: 8px; box-shadow: 0 4px 14px rgba(0,0,0,0.15);
      z-index: 2000; display: none;
    }
    .ifsc-results.active     { display: block; }
    .ifsc-result-item {
      display: flex; align-items: center; gap: 10px;
      padding: 10px 14px; cursor: pointer;
      border-bottom: 1px solid #f0f0f0;
      transition: background 0.18s, transform 0.15s;
    }
    .ifsc-result-item:last-child { border-bottom: none; }
    .ifsc-result-item:hover  { background: #e8e4fc; transform: translateX(4px); }

    .ifsc-col-code   { font-weight: bold; color: #3D316F; min-width: 130px; font-size: 13px; }
    .ifsc-col-bank   { color: #0306ff; font-weight: bold; flex: 1; font-size: 13px; }
    .ifsc-col-branch { color: #a52323; font-size: 12px; min-width: 130px; }
    .acc-col-code    { font-weight: bold; color: #3D316F; min-width: 140px; font-size: 13px; }
    .acc-col-name    { color: #0306ff; font-weight: bold; flex: 1; font-size: 13px; padding-left: 10px; }
    .acc-col-product { color: #a52323; font-size: 12px; white-space: nowrap; }
    .ifsc-msg        { padding: 12px 15px; text-align: center; color: #999; font-size: 13px; font-style: italic; }
    .ifsc-loading    { padding: 14px; text-align: center; color: #8066E8; font-size: 13px; }
    .ifsc-highlight  { background: #ffeb3b; font-weight: bold; padding: 1px 2px; border-radius: 2px; }
    .ifsc-hint       { font-size: 12px; color: #666; margin-top: 4px; font-style: italic; }
    .ifsc-results::-webkit-scrollbar       { width: 7px; }
    .ifsc-results::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 4px; }
    .ifsc-results::-webkit-scrollbar-thumb { background: #8066E8; border-radius: 4px; }
  </style>
</head>
<body>

<div class="page-header">RTGS OUTWARD ENTRY</div>

<!-- ══════════════════════════════════════════════════════════════════ -->
<!-- SUCCESS MODAL — same style as transactions.jsp                    -->
<!-- ══════════════════════════════════════════════════════════════════ -->
<div id="rtgsSuccessModal" style="
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.5);
    justify-content: center;
    align-items: center;
    z-index: 10000;">
  <div style="
      background: white;
      width: 500px;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
      text-align: center;">

    <!-- Green tick -->
    <div style="color: #2ecc71; font-size: 48px; margin-bottom: 20px;">✓</div>

    <div id="rtgsSuccessMessage" style="
        font-size: 20px;
        font-weight: bold;
        color: #333;
        margin-bottom: 15px;">
      RTGS Entry Saved Successfully!
    </div>

    <div id="rtgsSuccessScrollNumber" style="
        font-size: 25px;
        color: #666;
        margin-bottom: 10px;
        font-weight: bold;">
      Scroll Number: —
    </div>


    <div style="display: flex; gap: 10px; justify-content: center;">
      <button onclick="closeRtgsSuccessModal()" style="
          background: #2ecc71;
          color: white;
          border: none;
          padding: 12px 50px;
          border-radius: 6px;
          font-size: 16px;
          font-weight: bold;
          cursor: pointer;
          transition: background 0.3s;"
          onmouseover="this.style.background='#27ae60'"
          onmouseout="this.style.background='#2ecc71'">
        OK
      </button>
    </div>
  </div>
</div>

<!-- ══════════════════════════════════════════════════════════════════ -->
<!-- ERROR MODAL                                                        -->
<!-- ══════════════════════════════════════════════════════════════════ -->
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

<!-- ══════════════════════════════════════════════════════════════════ -->
<!-- LOOKUP MODAL                                                       -->
<!-- ══════════════════════════════════════════════════════════════════ -->
<div id="lookupModal" class="lookup-modal-wrap" style="display:none;">
    <div class="lookup-modal-box">
        <button class="lookup-modal-box-close" onclick="closeLookup()">&#10006;</button>
        <div id="lookupContent"></div>
    </div>
</div>

<!-- ══════════════════════════════════════════════════════════════════ -->
<!-- MAIN FORM                                                          -->
<!-- ══════════════════════════════════════════════════════════════════ -->
<form id="rtgsForm" onsubmit="submitRtgsForm(event)">

  <!-- RTGS Details -->
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

  <!-- Transfer Details -->
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
        <div style="position:relative;">
          <div class="ifsc-results" id="accResults"></div>
        </div>
        <div class="ifsc-hint">Type last 3+ digits to search</div>
      </div>

      <div>
        <label>Account Name</label>
        <input type="text" name="accountName" id="accountName" readonly>
      </div>

      <div><label>Address 1</label><input type="text" name="address1" id="address1"></div>
      <div><label>Address 2</label><input type="text" name="address2" id="address2"></div>
      <div><label>Address 3</label><input type="text" name="address3" id="address3"></div>

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

  <!-- Cash Details -->
  <fieldset>
    <legend>Cash Details</legend>
    <div class="form-grid">
      <div><label>Name Of Applicant</label><input type="text" name="nameOfApplicant" id="nameOfApplicant"></div>
      <div><label>Address1</label><input type="text" name="cashAddress1" id="cashAddress1"></div>
      <div><label>Address2</label><input type="text" name="cashAddress2" id="cashAddress2"></div>
      <div><label>Address3</label><input type="text" name="cashAddress3" id="cashAddress3"></div>
    </div>
  </fieldset>

  <!-- Remitter Details -->
  <fieldset>
    <legend>Remitter Details</legend>
    <div class="form-grid">
      <div><label>Remitting Banks IFSC CODE</label><input type="text" name="remittingIfscCode" id="remittingIfscCode"></div>
      <div><label>Application contact no(M)</label><input type="text" name="appContactNo" id="appContactNo"></div>
      <div><label>Residence</label><input type="text" name="residenceNo" id="residenceNo"></div>
      <div><label>Office</label><input type="text" name="officeNo" id="officeNo"></div>
      <div><label>Application Email ID</label><input type="email" name="appEmailId" id="appEmailId"></div>
    </div>
  </fieldset>

  <!-- Beneficiary Details -->
  <fieldset>
    <legend>Beneficiary Details</legend>
    <div class="form-grid">
      <div>
        <label>Beneficiary Name</label>
        <input type="text" name="beneficiaryName" id="beneficiaryName">
      </div>
      <div>
        <label>Beneficiary Account Code</label>
        <input type="text" name="beneficiaryAccountCode" id="beneficiaryAccountCode">
      </div>

      <!-- IFSC live search -->
      <div>
        <label>IFSC Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="ifscCode" id="ifscCode"
                 autocomplete="off" placeholder="Enter or search IFSC"
                 oninput="handleIfscLiveSearch(this.value)"
                 onblur="scheduleIfscClose()">
          <button type="button" class="icon-btn" onclick="openIfscLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
        <div style="position:relative;">
          <div class="ifsc-results" id="ifscResults"></div>
        </div>
        <div class="ifsc-hint">Type first 3+ letters to search</div>
      </div>

      <div><label>IFSC Bank Name</label>  <input type="text" name="ifscBankName"   id="ifscBankName"   readonly></div>
      <div><label>IFSC Branch Name</label><input type="text" name="ifscBranchName" id="ifscBranchName" readonly></div>

      <div><label>Beneficiary Contact No (M)</label><input type="text" name="beneficiaryMobile"    id="beneficiaryMobile"></div>
      <div><label>Residence</label>                 <input type="text" name="beneficiaryResidence" id="beneficiaryResidence"></div>
      <div><label>Office</label>                    <input type="text" name="beneficiaryOffice"    id="beneficiaryOffice"></div>
      <div><label>Beneficiary Address 1</label>     <input type="text" name="beneficiaryAddress1"  id="beneficiaryAddress1"></div>
      <div><label>Beneficiary Address 2</label>     <input type="text" name="beneficiaryAddress2"  id="beneficiaryAddress2"></div>

      <div><label>City</label>  <input type="text" name="beneficiaryCity"  id="beneficiaryCity"  readonly></div>
      <div><label>State</label> <input type="text" name="beneficiaryState" id="beneficiaryState" readonly></div>

      <div><label>Sender To Receiver Info</label><input type="text" name="SenderToReceiver" id="SenderToReceiver"></div>
    </div>
  </fieldset>

  <!-- Payment Details -->
  <fieldset>
    <legend>Payment Details</legend>
    <div class="form-grid">
      <div>
        <label>Remitting Amount</label>
        <input type="text" name="remittingAmount" id="remittingAmount" value="0"
               oninput="this.value=this.value.replace(/[^0-9.]/g,''); calculateTotal();">
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

  <!-- Buttons -->
  <div class="form-buttons">
    <button type="button" class="action-btn btn-validate"  onclick="validateRtgsForm()">Validate</button>
    <button type="submit"                class="action-btn btn-save">Save</button>
    <button type="button" class="action-btn btn-vouchers"  onclick="displayVouchers()">Display Vouchers</button>
    <button type="button" class="action-btn btn-signature" onclick="captureSignature()">Display Signature</button>
    <button type="button" class="action-btn btn-cancel"    onclick="resetRtgsForm()">Cancel</button>
  </div>

</form>

<!-- ══════════════════════════════════════════════════════════════════ -->
<!-- JAVASCRIPT                                                         -->
<!-- ══════════════════════════════════════════════════════════════════ -->
<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

let _currentLookupTarget = null;
let _filterTimer  = null;
let _rowCache     = null;
let ifscTimer     = null;
let ifscCloseTimer= null;
let accTimer      = null;
let accCloseTimer = null;

// ── Error modal ─────────────────────────────────────────────────────
function showRtgsError(msg) {
    document.getElementById('rtgsErrorMessage').textContent = msg;
    document.getElementById('rtgsErrorModal').style.display = 'flex';
}
function closeRtgsErrorModal() {
    document.getElementById('rtgsErrorModal').style.display = 'none';
}

// ── Success modal ────────────────────────────────────────────────────
function showRtgsSuccessModal(scrollNumber, beneficiaryName, totalAmount) {
    document.getElementById('rtgsSuccessScrollNumber').textContent =
        'Scroll Number: ' + (scrollNumber || '—');
    document.getElementById('rtgsSuccessModal').style.display = 'flex';
}
function closeRtgsSuccessModal() {
    document.getElementById('rtgsSuccessModal').style.display = 'none';
}

// ── Init ─────────────────────────────────────────────────────────────
window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb('Transactions > RTGS / NEFT > RTGS Outward');
    }
    document.getElementById('lookupModal').addEventListener('click', function(e) {
        if (e.target === this) closeLookup();
    });
    document.getElementById('rtgsErrorModal').addEventListener('click', function(e) {
        if (e.target === this) closeRtgsErrorModal();
    });
    toggleModeSections('Transfer');
};

// ── Lookup modal ─────────────────────────────────────────────────────
function _openLookup(type, extraParams) {
    _currentLookupTarget = type;
    _rowCache = null;
    let url = '../LookupForTransactions.jsp?type=' + type;
    if (extraParams) url += '&' + extraParams;
    fetch(url)
        .then(r => r.text())
        .then(html => {
            document.getElementById('lookupContent').innerHTML = html;
            _rowCache = null;
            buildRowCache();
            document.getElementById('lookupModal').style.display = 'flex';
            setTimeout(() => {
                const sb = document.getElementById('searchBox');
                if (sb) sb.focus();
            }, 100);
        })
        .catch(err => { showRtgsError('Failed to load lookup data.'); console.error(err); });
}
function closeLookup() {
    document.getElementById('lookupModal').style.display = 'none';
    _currentLookupTarget = null;
    _rowCache = null;
}
function openAccountLookup() { _openLookup('account', 'accountCategory=rtgs'); }
function openIfscLookup()    { _openLookup('ifsc', ''); }

// sendBack — called by rows in LookupForTransactions.jsp
function sendBack(a, b, c, d, e, f) {
    if (d === 'ifsc' || c === 'ifsc') {
        setIfscFromLookup(a, b, c, e, f);
    } else {
        setValueFromLookup(a, b, c);
    }
}
function setValueFromLookup(code, desc, type) {
    if (type === 'account') {
        document.getElementById('accountCode').value = code;
        document.getElementById('accountName').value = desc;
        document.getElementById('accResults').classList.remove('active');
        fetchAccountDetails(code);
        setTimeout(() => loadChequeData(), 500);
    }
    closeLookup();
}
function setIfscFromLookup(ifscCode, bankName, branchName, districtName, stateName) {
    document.getElementById('ifscCode').value        = ifscCode   || '';
    document.getElementById('ifscBankName').value    = bankName   || '';
    document.getElementById('ifscBranchName').value  = branchName || '';
    document.getElementById('beneficiaryCity').value = districtName || '';
    document.getElementById('beneficiaryState').value= stateName  || '';
    const d = document.getElementById('ifscResults');
    if (d) d.classList.remove('active');
    closeLookup();
}

// ── IFSC live-search ─────────────────────────────────────────────────
const IFSC_MIN_LEN  = 3;
const IFSC_DELAY_MS = 280;

function handleIfscLiveSearch(value) {
    document.getElementById('ifscBankName').value   = '';
    document.getElementById('ifscBranchName').value = '';
    clearTimeout(ifscTimer);
    const d = document.getElementById('ifscResults');
    if (!value || !value.trim()) { d.classList.remove('active'); return; }
    if (value.trim().length < IFSC_MIN_LEN) {
        d.innerHTML = '<div class="ifsc-msg">Type at least ' + IFSC_MIN_LEN + ' characters…</div>';
        d.classList.add('active'); return;
    }
    d.innerHTML = '<div class="ifsc-loading">🔍 Searching…</div>';
    d.classList.add('active');
    ifscTimer = setTimeout(() => _doIfscSearch(value.trim()), IFSC_DELAY_MS);
}
function _doIfscSearch(term) {
    const d = document.getElementById('ifscResults');
    fetch('../SearchAccounts.jsp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'searchNumber=' + encodeURIComponent(term) + '&category=ifsc'
    })
    .then(r => { if (!r.ok) throw new Error('Network error'); return r.json(); })
    .then(data => {
        if (data.error) { d.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">' + data.error + '</div>'; return; }
        if (data.accounts && data.accounts.length > 0) _renderIfscResults(data.accounts, term);
        else d.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">No IFSC records found for "' + term + '"</div>';
    })
    .catch(err => { console.error(err); d.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">Search failed.</div>'; });
}
function _renderIfscResults(accounts, term) {
    const d = document.getElementById('ifscResults');
    let html = '';
    accounts.forEach(item => {
        const sc = (item.code || '').replace(/'/g, "\\'");
        const sn = (item.name || '').replace(/'/g, "\\'");
        const sb = (item.branchName || '').replace(/'/g, "\\'");
        const sd = (item.districtName || '').replace(/'/g, "\\'");
        const ss = (item.stateName || '').replace(/'/g, "\\'");
        html += '<div class="ifsc-result-item" ' +
                'onmousedown="_selectIfsc(\'' + sc + '\',\'' + sn + '\',\'' + sb + '\',\'' + sd + '\',\'' + ss + '\')">' +
                '<span class="ifsc-col-code">' + _ifscHighlight(item.code || '', term) + '</span>' +
                '<span class="ifsc-col-bank">' + (item.name || '') + '</span>' +
                '<span class="ifsc-col-branch">' + (item.branchName || '') + '</span></div>';
    });
    d.innerHTML = html;
}
function _ifscHighlight(text, search) {
    if (!text || !search) return text;
    const idx = text.toUpperCase().indexOf(search.toUpperCase());
    if (idx === -1) return text;
    return text.substring(0, idx) +
           '<span class="ifsc-highlight">' + text.substring(idx, idx + search.length) + '</span>' +
           text.substring(idx + search.length);
}
function _selectIfsc(ifscCode, bankName, branchName, districtName, stateName) {
    document.getElementById('ifscCode').value        = ifscCode;
    document.getElementById('ifscBankName').value    = bankName;
    document.getElementById('ifscBranchName').value  = branchName;
    document.getElementById('beneficiaryCity').value = districtName || '';
    document.getElementById('beneficiaryState').value= stateName || '';
    document.getElementById('ifscResults').classList.remove('active');
}
function scheduleIfscClose() {
    clearTimeout(ifscCloseTimer);
    ifscCloseTimer = setTimeout(() => document.getElementById('ifscResults').classList.remove('active'), 200);
}

// ── Account live-search ──────────────────────────────────────────────
const ACC_MIN_LEN  = 3;
const ACC_DELAY_MS = 300;

function handleAccLiveSearch(value) {
    document.getElementById('accountName').value      = '';
    document.getElementById('ledgerBalance').value    = '';
    document.getElementById('availableBalance').value = '';
    document.getElementById('newLedgerBalance').value = '';
    clearTimeout(accTimer);
    const d = document.getElementById('accResults');
    const digits = value.replace(/\D/g, '');
    document.getElementById('accountCode').value = digits;
    if (!digits) { d.classList.remove('active'); return; }
    if (digits.length < ACC_MIN_LEN) {
        d.innerHTML = '<div class="ifsc-msg">Type at least ' + ACC_MIN_LEN + ' digits…</div>';
        d.classList.add('active'); return;
    }
    const searchNum = digits.length > 7 ? digits.slice(-7) : digits;
    d.innerHTML = '<div class="ifsc-loading">🔍 Searching…</div>';
    d.classList.add('active');
    accTimer = setTimeout(() => _doAccSearch(searchNum), ACC_DELAY_MS);
}
function _doAccSearch(searchNum) {
    const d = document.getElementById('accResults');
    fetch('../SearchAccounts.jsp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'searchNumber=' + encodeURIComponent(searchNum) + '&category=rtgs'
    })
    .then(r => { if (!r.ok) throw new Error('Network error'); return r.json(); })
    .then(data => {
        if (data.error) { d.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">' + data.error + '</div>'; return; }
        if (data.accounts && data.accounts.length > 0) _renderAccResults(data.accounts, searchNum);
        else d.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">No accounts found for "' + searchNum + '"</div>';
    })
    .catch(err => { console.error(err); d.innerHTML = '<div class="ifsc-msg" style="color:#f44336;">Search failed.</div>'; });
}
function _renderAccResults(accounts, searchNum) {
    const d = document.getElementById('accResults');
    let html = '';
    accounts.forEach(item => {
        const sn = (item.name || '').replace(/'/g, "\\'");
        const sc = (item.code || '').replace(/'/g, "\\'");
        html += '<div class="ifsc-result-item" onmousedown="_selectAcc(\'' + sc + '\',\'' + sn + '\')">' +
                '<span class="acc-col-code">' + _accHighlight(item.code || '', searchNum) + '</span>' +
                '<span class="acc-col-name">' + (item.name || '') + '</span>';
        if ((item.productDesc || '').trim()) {
            html += '<span class="acc-col-product">' + item.productDesc + '</span>';
        }
        html += '</div>';
    });
    d.innerHTML = html;
}
function _accHighlight(text, search) {
    if (!text || !search) return text;
    const last7 = text.slice(-7);
    const idx   = last7.toUpperCase().indexOf(search.toUpperCase());
    if (idx === -1) return text;
    const abs = text.length - 7 + idx;
    return text.substring(0, abs) +
           '<span class="ifsc-highlight">' + text.substring(abs, abs + search.length) + '</span>' +
           text.substring(abs + search.length);
}
function _selectAcc(code, name) {
    document.getElementById('accountCode').value = code;
    document.getElementById('accountName').value = name;
    document.getElementById('accResults').classList.remove('active');
    fetchAccountDetails(code);
    setTimeout(() => loadChequeData(), 400);
}
function scheduleAccClose() {
    clearTimeout(accCloseTimer);
    accCloseTimer = setTimeout(() => document.getElementById('accResults').classList.remove('active'), 200);
}

// Close dropdowns on outside click / ESC
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
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        ['ifscResults','accResults'].forEach(id => {
            const d = document.getElementById(id);
            if (d) d.classList.remove('active');
        });
        closeLookup();
    }
});

// ── Fetch account details ────────────────────────────────────────────
function fetchAccountDetails(accountCode) {
    if (!accountCode || !accountCode.trim()) { showRtgsError('No account code provided.'); return; }
    fetch('../GetAccountDetails.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(r => r.json())
        .then(data => {
            if (data.error) {
                showRtgsError('Error: ' + data.error);
            } else {
                document.getElementById('ledgerBalance').value    = data.ledgerBalance    || '0.00';
                document.getElementById('availableBalance').value = data.availableBalance || '0.00';
                document.getElementById('newLedgerBalance').value = data.ledgerBalance    || '0.00';
                if (data.customerAddress && data.customerAddress.trim()) {
                    populateAddressFields(data.customerAddress);
                }
            }
        })
        .catch(err => { console.error(err); showRtgsError('Failed to fetch account details'); });
}

function populateAddressFields(addr) {
    if (!addr || !addr.trim()) return;
    const words = addr.trim().split(/\s+/);
    if (words.length <= 3) {
        document.getElementById('address1').value = words[0] || '';
        document.getElementById('address2').value = words[1] || '';
        document.getElementById('address3').value = words[2] || '';
    } else {
        const g = Math.ceil(words.length / 3);
        document.getElementById('address1').value = words.slice(0,   g  ).join(' ');
        document.getElementById('address2').value = words.slice(g,   g*2).join(' ');
        document.getElementById('address3').value = words.slice(g*2      ).join(' ');
    }
}

// ── Cheque data ──────────────────────────────────────────────────────
function loadChequeData() {
    const accountCode = document.getElementById('accountCode').value.trim();
    if (!accountCode) { showRtgsError('Please select an account first'); return; }

    ['chequeType','chequeSeries','chequeNumber'].forEach(id =>
        document.getElementById(id).innerHTML = '<option value="">Loading...</option>');

    fetch('../GetChequeData.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(r => r.json())
        .then(data => {
            if (!data.success) { showRtgsError('Cheque data error: ' + (data.error || 'Unknown')); clearChequeDropdowns(); return; }
            if (!data.cheques || !data.cheques.length) { clearChequeDropdowns('No cheques available'); return; }

            const typeS   = document.getElementById('chequeType');
            const seriesS = document.getElementById('chequeSeries');
            const noS     = document.getElementById('chequeNumber');

            typeS.innerHTML   = '<option value="">Select Cheque Type</option>';
            seriesS.innerHTML = '<option value="">Select Cheque Series</option>';
            noS.innerHTML     = '<option value="">Select Cheque No</option>';

            (data.typeList   || []).forEach(t => { const o = document.createElement('option'); o.value = o.textContent = t.trim(); typeS.appendChild(o); });
            (data.seriesList || []).forEach(s => { const o = document.createElement('option'); o.value = o.textContent = s.trim(); seriesS.appendChild(o); });
            data.cheques.forEach(c => { const o = document.createElement('option'); o.value = o.textContent = c.chequeNumber.trim(); noS.appendChild(o); });
        })
        .catch(err => { console.error(err); showRtgsError('Failed to load cheque data'); clearChequeDropdowns(); });
}
function clearChequeDropdowns(msg) {
    msg = msg || 'No cheques available';
    ['chequeType','chequeSeries','chequeNumber'].forEach(id =>
        document.getElementById(id).innerHTML = '<option value="">' + msg + '</option>');
}

// ── Total ────────────────────────────────────────────────────────────
function calculateTotal() {
    const r = parseFloat(document.getElementById('remittingAmount').value) || 0;
    const c = parseFloat(document.getElementById('applicableCharges').value) || 0;
    const t = parseFloat(document.getElementById('serviceTax').value) || 0;
    document.getElementById('totalAmount').value = (r + c + t).toFixed(2);
}

// ── Form submit ──────────────────────────────────────────────────────
function submitRtgsForm(e) {
    e.preventDefault();

    // ── Client-side console debug ──────────────────────────────────
    const fields = {
        'accountCode (Remitter)':        document.getElementById('accountCode').value.trim(),
        'accountName (Remitter Name)':   document.getElementById('accountName').value.trim(),
        'beneficiaryAccountCode':        document.getElementById('beneficiaryAccountCode').value.trim(),
        'beneficiaryName':               document.getElementById('beneficiaryName').value.trim(),
        'ifscCode':                      document.getElementById('ifscCode').value.trim(),
        'remittingAmount':               document.getElementById('remittingAmount').value.trim(),
        'applicableCharges':             document.getElementById('applicableCharges').value.trim(),
        'serviceTax':                    document.getElementById('serviceTax').value.trim(),
        'SenderToReceiver':              document.getElementById('SenderToReceiver').value.trim(),
        'ifscBranchName':               document.getElementById('ifscBranchName').value.trim(),
        'beneficiaryCity':               document.getElementById('beneficiaryCity').value.trim(),
        'beneficiaryState':              document.getElementById('beneficiaryState').value.trim(),
    };

    console.group('🧾 RTGS Form — Field Values before Submit');
    let hasEmpty = false;
    Object.entries(fields).forEach(([key, val]) => {
        if (!val) {
            console.warn('❌ EMPTY  [' + key + '] = ""');
            hasEmpty = true;
        } else {
            console.log('✅ FILLED [' + key + '] = "' + val + '"');
        }
    });
    if (!hasEmpty) console.log('✅ All key fields are filled');
    console.groupEnd();

    // Required field check (mirrors servlet)
    const requiredChecks = [
        { id: 'accountCode',            label: 'Account Code' },
        { id: 'beneficiaryAccountCode', label: 'Beneficiary Account Code' },
        { id: 'beneficiaryName',        label: 'Beneficiary Name' },
        { id: 'ifscCode',               label: 'IFSC Code' },
        { id: 'remittingAmount',        label: 'Remitting Amount' },
    ];
    const missing = requiredChecks.filter(f => !document.getElementById(f.id).value.trim());
    if (missing.length) {
        const msg = 'Please fill: ' + missing.map(f => f.label).join(', ');
        console.error('⛔ Client validation failed: ' + msg);
        showRtgsError(msg);
        return;
    }
    if (parseFloat(document.getElementById('remittingAmount').value) <= 0) {
        showRtgsError('Please enter a valid Remitting Amount (> 0).');
        return;
    }

    const btn = document.querySelector('button[type="submit"]');
    btn.disabled    = true;
    btn.textContent = 'Submitting…';

    const formData = new FormData(document.getElementById('rtgsForm'));

    // Log what FormData is actually sending
    console.group('📤 FormData being sent to RtgsServlet');
    for (let [k, v] of formData.entries()) {
        console.log('  [' + k + '] = [' + v + ']');
    }
    console.groupEnd();

    fetch(window.APP_CONTEXT_PATH + '/RtgsServlet', { method: 'POST', body: formData })
        .then(res => res.json())
        .then(data => {
            btn.disabled    = false;
            btn.textContent = 'Save';
            console.log('🔁 Servlet response:', data);
            if (data.success) {
                showRtgsSuccessModal(data.scrollNumber, data.beneficiaryName, data.totalAmount);
                resetRtgsForm();
            } else {
                showRtgsError(data.message || 'Failed to submit RTGS request.');
            }
        })
        .catch(err => {
            btn.disabled    = false;
            btn.textContent = 'Save';
            console.error('❌ Network error:', err);
            showRtgsError('Network error: ' + err.message);
        });
}

// ── Validate button ──────────────────────────────────────────────────
function validateRtgsForm() {
    const checks = [
        { id: 'accountCode',            label: 'Account Code' },
        { id: 'beneficiaryAccountCode', label: 'Beneficiary Account Code' },
        { id: 'beneficiaryName',        label: 'Beneficiary Name' },
        { id: 'ifscCode',               label: 'IFSC Code' },
        { id: 'remittingAmount',        label: 'Remitting Amount' },
    ];
    for (const c of checks) {
        if (!document.getElementById(c.id).value.trim()) {
            showRtgsError('Please fill: ' + c.label);
            return;
        }
    }
    if (parseFloat(document.getElementById('remittingAmount').value) <= 0) {
        showRtgsError('Please enter a valid Remitting Amount.');
        return;
    }
    closeRtgsErrorModal();
    // Show a simple ok toast if valid
    console.log('✅ Validation passed — all required fields filled');
}

// ── Reset ────────────────────────────────────────────────────────────
function resetRtgsForm() {
    document.getElementById('rtgsForm').reset();
    ['accountName','ledgerBalance','availableBalance','newLedgerBalance',
     'ifscBankName','ifscBranchName','totalAmount','beneficiaryCity','beneficiaryState']
        .forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; });
    clearChequeDropdowns();
    document.getElementById('remittingAmount').value   = '0';
    document.getElementById('applicableCharges').value = '0';
    document.getElementById('serviceTax').value        = '0';
    document.getElementById('totalAmount').value       = '0';
    ['ifscResults','accResults'].forEach(id => {
        const d = document.getElementById(id);
        if (d) d.classList.remove('active');
    });
}

// ── Other button stubs ───────────────────────────────────────────────
function displayVouchers()  { showRtgsError('Vouchers feature — To be implemented'); }
function captureSignature() { showRtgsError('Signature capture feature — To be implemented'); }

// ── Transfer / Cash mode toggle ──────────────────────────────────────
function toggleModeSections(mode) {
    if (mode === 'Cash') {
        document.querySelectorAll('fieldset:nth-of-type(2) input').forEach(el => { el.readOnly = true; el.value = ''; });
        document.querySelectorAll('fieldset:nth-of-type(2) select').forEach(el => { el.disabled = true; el.selectedIndex = 0; });
        clearChequeDropdowns();
        document.querySelectorAll('fieldset:nth-of-type(3) input').forEach(el => el.readOnly = false);
    } else {
        document.querySelectorAll('fieldset:nth-of-type(3) input').forEach(el => { el.readOnly = true; el.value = ''; });
        document.querySelectorAll('fieldset:nth-of-type(2) input').forEach(el => el.readOnly = false);
        document.querySelectorAll('fieldset:nth-of-type(2) select').forEach(el => el.disabled = false);
    }
}

// ── Lookup table filter ──────────────────────────────────────────────
function buildRowCache() {
    const table = document.getElementById('lookupTable');
    if (!table) { _rowCache = []; return; }
    _rowCache = Array.from(table.getElementsByClassName('data-row')).map(row => {
        let text = '';
        row.querySelectorAll('td').forEach(c => text += ' ' + c.textContent);
        return { el: row, text: text.toLowerCase() };
    });
}
function filterTable() {
    clearTimeout(_filterTimer);
    _filterTimer = setTimeout(_applyFilter, 180);
}
function _applyFilter() {
    const sb = document.getElementById('searchBox');
    if (!sb) return;
    const q = sb.value.toLowerCase().trim();
    if (!_rowCache) buildRowCache();
    let visible = 0;
    const hide = q.length >= 2;
    _rowCache.forEach(item => {
        const show = !hide || item.text.includes(q);
        item.el.classList.toggle('row-hidden', !show);
        if (show) visible++;
    });
    let noRow = document.getElementById('noResultsRow');
    if (visible === 0) {
        if (!noRow) {
            const table = document.getElementById('lookupTable');
            noRow = table.insertRow(-1);
            noRow.id = 'noResultsRow';
            noRow.innerHTML = '<td colspan="3" class="no-results">No records found</td>';
        }
        noRow.classList.remove('row-hidden');
    } else if (noRow) {
        noRow.classList.add('row-hidden');
    }
}
</script>

</body>
</html>
