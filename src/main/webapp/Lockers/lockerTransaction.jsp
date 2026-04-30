<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String contextPath = request.getContextPath();
    String user        = (String) session.getAttribute("username");
    String bankCode    = (String) session.getAttribute("bankCode");
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Locker Transactions</title>
  <link rel="stylesheet" href="../css/addCustomer.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    /* ── Availability button ───────────────────────────────────────── */
    .form-buttons { display: flex !important; gap: 8px; flex-wrap: wrap; }

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

    #checkAvailabilityBtn {
      background-color: #373279;
      color: white;
      border: none;
      padding: 10px 25px;
      border-radius: 6px;
      font-size: 14px;
      font-weight: bold;
      cursor: pointer;
      transition: background-color 0.3s ease, transform 0.2s ease;
      white-space: nowrap;
    }
    #checkAvailabilityBtn:hover  { background-color: #2b0d73; transform: scale(1.05); }
    #checkAvailabilityBtn:active { transform: scale(0.97); }

    /* ── Inline radio row (Transaction Mode, Transfer By Cheque) ───── */
    .inline-radio-row {
      display: flex;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
    }
    .inline-radio-row .radio-group {
      flex-direction: row;
      gap: 12px;
    }
    .inline-radio-row label { white-space: nowrap; }

    /* ── Cheque detail row ─────────────────────────────────────────── */
    .cheque-detail-row {
      display: flex;
      align-items: flex-end;
      gap: 12px;
      flex-wrap: wrap;
    }
    .cheque-detail-row > div {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .cheque-detail-row input,
    .cheque-detail-row select {
      height: 30px;
      box-sizing: border-box;
    }


    /* ── Action buttons (bottom bar) ───────────────────────────────── */
    .action-btn {
      border: none;
      padding: 8px 18px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: opacity 0.2s, transform 0.15s;
    }
    .action-btn:hover  { opacity: 0.88; }
    .action-btn:active { transform: scale(0.97); }

    .btn-validate  { background-color: #373279; color: #fff; }
    .btn-save      { background-color: #28a745; color: #fff; }
    .btn-vouchers  { background-color: #17a2b8; color: #fff; }
    .btn-signature { background-color: #6f42c1; color: #fff; }
    .btn-photo     { background-color: #fd7e14; color: #fff; }
    .btn-cancel    { background-color: #dc3545; color: #fff; }

    /* ── Meta info row ─────────────────────────────────────────────── */
    .meta-row {
      display: flex;
      gap: 24px;
      flex-wrap: wrap;
      margin-bottom: 14px;
      font-size: 13px;
      color: #444;
      font-weight: 500;
    }
    .meta-row span b { color: #373279; }

    /* ── Readonly field visual hint ────────────────────────────────── */
    input[readonly] {
      color: #555;
    }

    /* ── Message textarea ──────────────────────────────────────────── */
    #message {
      width: 98%;
      height: 55px;
      resize: vertical;
      border: 1px solid #c9c5e8;
      border-radius: 4px;
      padding: 6px;
      font-size: 13px;
      font-family: inherit;
      box-sizing: border-box;
    }
    #message:focus { outline: 2px solid #373279; }
  </style>
</head>
<body>

<form action="LockerTransactionServlet" method="post" onsubmit="return validateTxnForm()">

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 1 : LOCKER TYPE DETAILS                              -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Type Details</legend>
    <div class="form-grid">

      <div>
        <label>Locker Type</label>
        <div class="input-icon-box">
          <input type="text" name="lockerTypeSearch" id="lockerTypeSearch"
                 oninput="this.value = this.value.toUpperCase();" readonly>
          <button type="button" class="inside-icon-btn" title="Search Locker Type"
                  onclick="openLockerTypeLookup()">🔍</button>
        </div>
      </div>

      <div>
        <label>Locker Number</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="lockerNumberSearch" id="lockerNumberSearch"
                 class="form-input"
                 oninput="this.value = this.value.replace(/[^A-Za-z0-9]/g,'').toUpperCase();">
          <button type="button" onclick="openLockerLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;" title="Browse Lockers">…</button>
        </div>
      </div>

      <div style="display:flex; align-items:flex-end;">
        <button type="button" id="checkAvailabilityBtn" onclick="loadLockerDetails()">
          Check Availability
        </button>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2 : ACCOUNT DETAILS                                  -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Account Details</legend>
    <div class="form-grid">

      <div>
        <label>Scroll Number</label>
        <input type="text" name="scrollNumber" id="scrollNumber" readonly>
      </div>

      <div>
        <label>Name of Hire</label>
        <input type="text" name="nameOfHire" id="nameOfHire" readonly>
      </div>

      <div>
        <label>Status</label>
        <input type="text" name="lockerStatus" id="lockerStatus" readonly>
      </div>

      <div>
        <label>Customer Id</label>
        <input type="text" name="customerId" id="customerId" readonly>
      </div>

      <div>
        <label>Name</label>
        <input type="text" name="customerName" id="customerName" readonly>
      </div>



      <div>
        <label>Rent Paid Till Date</label>
        <input type="date" name="rentPaidTillDate" id="rentPaidTillDate" readonly>
      </div>

      <div>
        <label>Period</label>
        <input type="text" name="period" id="period" value="12" readonly">
      </div>

      <div>
        <label>Review Date</label>
        <input type="date" name="reviewDate" id="reviewDate" readonly>
      </div>

      <div>
        <label>Rent From Date</label>
        <input type="date" name="rentFromDate" id="rentFromDate" readonly>
      </div>

      <div>
        <label>Rent To Date</label>
        <input type="date" name="rentToDate" id="rentToDate" readonly>
      </div>

      <div>
        <label>Completed Period In Months</label>
        <input type="text" name="completedPeriodMonths" id="completedPeriodMonths" readonly>
      </div>

      <div>
        <label>Locker Rent</label>
        <input type="text" name="lockerRent" id="lockerRent" readonly>
      </div>

      <div>
        <label>Locker Rent Due</label>
        <input type="text" name="lockerRentDue" id="lockerRentDue" readonly>
      </div>

      <div>
        <label>Amount</label>
        <input type="text" name="amount" id="amount" value="0"
               oninput="this.value = this.value.replace(/[^0-9.]/g, ''); computeClosingBalance();">
      </div>

      <div>
        <label>Service Tax</label>
        <input type="text" name="serviceTax" id="serviceTax" value="0"
               oninput="this.value = this.value.replace(/[^0-9.]/g, ''); computeClosingBalance();">
      </div>

      <div>
        <label>Closing Balance</label>
        <input type="text" name="closingBalance" id="closingBalance" readonly>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 3 : TRANSACTION DETAILS                              -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Transaction Details</legend>
    <div class="form-grid">

      <!-- Row 1: Transaction Date + Transaction Mode -->
      <div>
        <label>Transaction Date</label>
        <input type="date" name="transactionDate" id="transactionDate" readonly>
      </div>

      <div>
        <label>Transaction Mode</label>
        <div class="inline-radio-row">
          <div class="radio-group">
            <label>
              <input type="radio" name="transactionMode" value="CASH" checked
                     onchange="onTxnModeChange(this)"> Cash
            </label>
            <label>
              <input type="radio" name="transactionMode" value="TRANSFER"
                     onchange="onTxnModeChange(this)"> Transfer
            </label>
          </div>
        </div>
      </div>

      <!-- Row 2: Debit A/C Code + Name -->
      <div>
        <label>Debit A/C Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <button type="button"
                  style="background-color:#2D2B80; color:white; border:none; width:28px; height:28px;
                         border-radius:5px; font-size:14px; cursor:pointer;"
                  onclick="openDebitACLookup()">…</button>
          <input type="text" name="debitACCode" id="debitACCode"
                 class="form-input"
                 oninput="this.value = this.value.replace(/[^A-Za-z0-9]/g,'').toUpperCase();">
        </div>
      </div>

      <div>
        <label>Name</label>
        <input type="text" name="debitACName" id="debitACName" readonly>
      </div>

      <!-- Row 3: Transfer By Cheque + Cheque details -->
      <div style="grid-column: 1 / -1;">
        <label>Transfer By Cheque</label>
        <div class="cheque-detail-row" style="margin-top:6px;">

          <!-- Yes / No radio -->
          <div>
            <div class="radio-group" style="flex-direction:row; gap:10px;">
              <label>
                <input type="radio" name="transferByCheque" value="yes" id="chequeYes"
                       onchange="toggleChequeFields(this)"> Yes
              </label>
              <label>
                <input type="radio" name="transferByCheque" value="no" id="chequeNo"
                       onchange="toggleChequeFields(this)" checked> No
              </label>
            </div>
          </div>

          <!-- Cheque Type -->
          <div id="chequeTypeWrapper">
            <label>Cheque Type</label>
            <select name="chequeType" id="chequeType" disabled style="min-width:130px;">
              <option value="">-- Select --</option>
              <option value="LOCAL">Local</option>
              <option value="OUTSTATION">Outstation</option>
              <option value="AT_PAR">At Par</option>
            </select>
          </div>

          <!-- Cheque Series -->
          <div id="chequeSeriesWrapper">
            <label>Cheque Series</label>
            <input type="text" name="chequeSeries" id="chequeSeries" disabled
                   style="width:110px;"
                   oninput="this.value = this.value.replace(/[^A-Za-z0-9]/g,'').toUpperCase();">
          </div>

          <!-- Cheque Date -->
          <div id="chequeDateWrapper">
            <label>Cheque Date</label>
            <input type="date" name="chequeDate" id="chequeDate" disabled style="width:145px;">
          </div>

          <!-- Cheque No. -->
          <div id="chequeNoWrapper">
            <label>Cheque No.</label>
            <input type="text" name="chequeNo" id="chequeNo" disabled
                   style="width:120px;"
                   oninput="this.value = this.value.replace(/[^0-9]/g,'');">
          </div>

        </div>
      </div>


    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- ACTION BUTTONS                                                -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <div class="form-buttons" style="justify-content:center; margin-top:10px;">
    <button type="button"   class="action-btn btn-validate"  onclick="validateLockerTxn()">Validate</button>
    <button type="submit"   class="action-btn btn-save">Save</button>
    <button type="button"   class="action-btn btn-vouchers"  onclick="displayVouchers()">Display Vouchers</button>
    <button type="button"   class="action-btn btn-signature" onclick="captureSignature()">Signature</button>
    <button type="button"   class="action-btn btn-photo"     onclick="capturePhoto()">Photo</button>
    <button type="button"   class="action-btn btn-cancel"    onclick="resetTxnForm()">Cancel</button>
  </div>

</form>

<!-- ================================================================ -->
<!-- SCRIPTS                                                           -->
<!-- ================================================================ -->
<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ── Set today's date in meta row and transaction date field ─────────
window.onload = function () {
    var today = new Date();
    var iso   = today.toISOString().split('T')[0];
    document.getElementById('transactionDate').value = iso;

    // Format for display: DD-MM-YYYY
    var dd = String(today.getDate()).padStart(2,'0');
    var mm = String(today.getMonth()+1).padStart(2,'0');
    var yyyy = today.getFullYear();
    document.getElementById('metaDate').textContent = dd + '-' + mm + '-' + yyyy;

    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath
                ? window.buildBreadcrumbPath('Lockers/lockerTransaction.jsp')
                : 'Locker Transaction'
        );
    }
};

// ── Load locker account details on Check Availability ──────────────
function loadLockerDetails() {
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();

    if (!lockerType && !lockerNumber) {
        alert('Please enter Locker Type or Locker Number to check availability.');
        return;
    }

    fetch(window.APP_CONTEXT_PATH + '/loaders/LockerTransactionLoader'
        + '?lockerType='   + encodeURIComponent(lockerType)
        + '&lockerNumber=' + encodeURIComponent(lockerNumber))
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data.found) {
            document.getElementById('scrollNumber').value          = data.scrollNumber          || '';
            document.getElementById('nameOfHire').value            = data.nameOfHire            || '';
            document.getElementById('lockerStatus').value          = data.lockerStatus          || '';
            document.getElementById('customerId').value            = data.customerId            || '';
            document.getElementById('customerName').value          = data.customerName          || '';
            document.getElementById('rentPaidTillDate').value      = data.rentPaidTillDate      || '';
            document.getElementById('period').value                = data.period                || '12';
            document.getElementById('reviewDate').value            = data.reviewDate            || '';
            document.getElementById('rentFromDate').value          = data.rentFromDate          || '';
            document.getElementById('rentToDate').value            = data.rentToDate            || '';
            document.getElementById('completedPeriodMonths').value = data.completedPeriodMonths || '';
            document.getElementById('lockerRent').value            = data.lockerRent            || '';
            document.getElementById('lockerRentDue').value         = data.lockerRentDue         || '';
            document.getElementById('amount').value                = data.amount                || '0';
            document.getElementById('serviceTax').value            = data.serviceTax            || '0';
            computeClosingBalance();
        } else {
            alert('Locker not found or no active issue record.');
        }
    })
    .catch(function(err) { console.error('Locker load error:', err); });
}

// ── Compute Closing Balance = Amount + Service Tax ──────────────────
function computeClosingBalance() {
    var amt = parseFloat(document.getElementById('amount').value)     || 0;
    var tax = parseFloat(document.getElementById('serviceTax').value) || 0;
    document.getElementById('closingBalance').value = (amt + tax).toFixed(2);
}

// ── Transaction mode change ─────────────────────────────────────────
function onTxnModeChange(radio) {
    // If CASH selected, clear and disable cheque fields
    if (radio.value === 'CASH') {
        document.getElementById('chequeNo').checked = false;
        disableChequeFields();
    }
}

// ── Toggle cheque detail fields ─────────────────────────────────────
function toggleChequeFields(radio) {
    var enable = (radio.value === 'yes');
    var ids = ['chequeType','chequeSeries','chequeDate','chequeNo'];
    ids.forEach(function(id) {
        var el = document.getElementById(id);
        el.disabled = !enable;
        if (!enable) el.value = '';
    });
}

function disableChequeFields() {
    document.getElementById('chequeNo').value = false;
    var ids = ['chequeType','chequeSeries','chequeDate','chequeNo'];
    ids.forEach(function(id) {
        var el = document.getElementById(id);
        el.disabled = true;
        el.value = (id === 'chequeType') ? '' : '';
    });
    document.getElementById('chequeNo').checked = false;
}

// ── Placeholder lookup openers ──────────────────────────────────────
function openLockerTypeLookup() { /* TODO: wire to your lookup modal */ }
function openLockerLookup()     { /* TODO: wire to your lookup modal */ }
function openDebitACLookup()    { /* TODO: wire to your lookup modal */ }

// ── Validate (pre-save check) ───────────────────────────────────────
function validateLockerTxn() {
    var lockerNo = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerNo) { alert('Please select a Locker Number first.'); return; }
    var amount   = parseFloat(document.getElementById('amount').value);
    if (isNaN(amount) || amount < 0) { alert('Please enter a valid Amount.'); return; }

    Toastify({
        text: "✔ Validation successful",
        duration: 3000,
        gravity: "top",
        position: "right",
        style: { background: "#373279" }
    }).showToast();
}

// ── Display Vouchers ────────────────────────────────────────────────
function displayVouchers() {
    var lockerNo = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerNo) { alert('Please load a Locker record first.'); return; }
    window.open(window.APP_CONTEXT_PATH + '/Lockers/lockerVouchers.jsp?lockerNumber='
        + encodeURIComponent(lockerNo), '_blank');
}

// ── Placeholder handlers ────────────────────────────────────────────
function captureSignature() { alert('Signature capture: TODO'); }
function capturePhoto()     { alert('Photo capture: TODO'); }

// ── Reset / Cancel ──────────────────────────────────────────────────
function resetTxnForm() {
    document.querySelector('form').reset();
    var today = new Date().toISOString().split('T')[0];
    document.getElementById('transactionDate').value = today;
    document.getElementById('closingBalance').value  = '';

    // Clear auto-filled readonly fields
    [
        'scrollNumber','nameOfHire','lockerStatus','customerId','customerName',
        'rentPaidTillDate','reviewDate','rentFromDate','rentToDate',
        'completedPeriodMonths','lockerRent','lockerRentDue','debitACName'
    ].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
    });
    document.getElementById('period').value     = '12';
    document.getElementById('amount').value     = '0';
    document.getElementById('serviceTax').value = '0';
    disableChequeFields();
}

// ── Form submit validation ──────────────────────────────────────────
function validateTxnForm() {
    var lockerNo = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerNo) {
        alert('Please select a Locker Number before saving.');
        return false;
    }
    var txnDate = document.getElementById('transactionDate').value;
    if (!txnDate) {
        alert('Transaction Date is required.');
        return false;
    }
    var amount = parseFloat(document.getElementById('amount').value);
    if (isNaN(amount) || amount < 0) {
        alert('Please enter a valid Amount.');
        return false;
    }
    // Cheque validation
    if (document.getElementById('chequeYes').checked) {
        if (!document.getElementById('chequeNo').value.trim()) {
            alert('Please enter the Cheque Number.');
            return false;
        }
        if (!document.getElementById('chequeDate').value) {
            alert('Please enter the Cheque Date.');
            return false;
        }
    }
    return true;
}
</script>

</body>
</html>
