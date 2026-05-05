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
  <title>Locker Surrender</title>
  <link rel="stylesheet" href="../css/locker.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    .form-buttons { display: flex !important; }

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
    }
    #checkAvailabilityBtn:hover { background-color: #2b0d73; transform: scale(1.05); }
    #checkAvailabilityBtn:active { transform: scale(0.97); }

    /* Transaction mode radio row */
    .txn-mode-row {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .txn-mode-row .radio-group {
      flex-direction: row;
    }
  </style>
</head>
<body>

<form action="LockerSurrenderServlet" method="post" onsubmit="return validateSurrenderForm()">

  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 1: LOCKER TYPE DETAILS                   -->
  <!-- ══════════════════════════════════════════════════ -->
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
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
      </div>

      <div style="display:flex; align-items:flex-end;">
        <button type="button" id="checkAvailabilityBtn" onclick="loadLockerDetails()">
          Check Availability
        </button>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: SURRENDER DETAILS                     -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Surrender Details</legend>
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
        <label>Customer Id</label>
        <input type="text" name="customerId" id="customerId" readonly>
      </div>

      <div>
        <label>Name</label>
        <input type="text" name="customerName" id="customerName" readonly>
      </div>

      <div>
        <label>Hire Date</label>
        <input type="date" name="hireDate" id="hireDate" readonly>
      </div>

      <div>
        <label>Period</label>
        <input type="text" name="period" id="period" value="12" readonly>
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
        <label>Locker Rent/month</label>
        <input type="text" name="lockerRentPerMonth" id="lockerRentPerMonth" readonly>
      </div>

      <div>
        <label>Locker Rent Due</label>
        <input type="text" name="lockerRentDue" id="lockerRentDue" readonly>
      </div>

      <div>
        <label>Amount</label>
        <input type="text" name="amount" id="amount" value="0"
               oninput="this.value = this.value.replace(/[^0-9.]/g, '');">
      </div>


      <div>
        <label>Transaction Date</label>
        <input type="date" name="transactionDate" id="transactionDate" readonly>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 3: TRANSACTION DETAILS                   -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Transaction Details</legend>
    <div class="form-grid">

      <div>
        <label>Transaction Mode</label>
        <div class="txn-mode-row radio-group">
          <label><input type="radio" name="transactionMode" value="CASH" checked
                        onchange="toggleTransferStatus(this)"> Cash</label>
          <label><input type="radio" name="transactionMode" value="TRANSFER"
                        onchange="toggleTransferStatus(this)"> Transfer</label>
          <label>Status</label>
          <input type="text" name="transferStatus" id="transferStatus"
                 style="width:80px;" readonly>
        </div>
      </div>

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

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════ -->
  <!-- BUTTON SECTION                                    -->
  <!-- ══════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="submit">Surrender Locker</button>
    <button type="button" onclick="resetSurrenderForm()">Reset</button>
  </div>

</form>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// Set today's date on transaction date field
window.onload = function() {
    var today = new Date().toISOString().split('T')[0];
    document.getElementById('transactionDate').value = today;

    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath
                ? window.buildBreadcrumbPath('Lockers/lockerSurrender.jsp')
                : 'Locker Surrender'
        );
    }
};

// Load locker details on Check Availability
function loadLockerDetails() {
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();

    if (!lockerType && !lockerNumber) {
        alert('Please enter Locker Type or Locker Number.');
        return;
    }

    fetch(window.APP_CONTEXT_PATH + '/loaders/LockerSurrenderLoader'
        + '?lockerType='   + encodeURIComponent(lockerType)
        + '&lockerNumber=' + encodeURIComponent(lockerNumber))
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data.found) {
            document.getElementById('scrollNumber').value          = data.scrollNumber          || '';
            document.getElementById('nameOfHire').value            = data.nameOfHire            || '';
            document.getElementById('customerId').value            = data.customerId            || '';
            document.getElementById('customerName').value          = data.customerName          || '';
            document.getElementById('hireDate').value              = data.hireDate              || '';
            document.getElementById('period').value                = data.period                || '12';
            document.getElementById('reviewDate').value            = data.reviewDate            || '';
            document.getElementById('rentFromDate').value          = data.rentFromDate          || '';
            document.getElementById('rentToDate').value            = data.rentToDate            || '';
            document.getElementById('completedPeriodMonths').value = data.completedPeriodMonths || '';
            document.getElementById('lockerRentPerMonth').value    = data.lockerRentPerMonth    || '';
            document.getElementById('lockerRentDue').value         = data.lockerRentDue         || '';
            document.getElementById('amount').value                = data.amount                || '0';
        } else {
            alert('Locker not found or not issued.');
        }
    })
    .catch(function(err) { console.error('Locker load error:', err); });
}

// Show/hide transfer status field
function toggleTransferStatus(radio) {
    var statusField = document.getElementById('transferStatus');
    statusField.readOnly = (radio.value !== 'TRANSFER');
    if (radio.value !== 'TRANSFER') statusField.value = '';
}

// Placeholder lookup openers — wire to your actual lookup modals
function openLockerTypeLookup() { /* TODO */ }
function openLockerLookup()     { /* TODO */ }
function openDebitACLookup()    { /* TODO */ }

// Reset form
function resetSurrenderForm() {
    document.querySelector('form').reset();
    var today = new Date().toISOString().split('T')[0];
    document.getElementById('transactionDate').value = today;
    // Clear all readonly auto-filled fields
    var readonlyIds = [
        'scrollNumber','nameOfHire','customerId','customerName',
        'hireDate','reviewDate','rentFromDate','rentToDate',
        'completedPeriodMonths','lockerRentPerMonth','lockerRentDue',
        'debitACName','transferStatus'
    ];
    readonlyIds.forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
    });
    document.getElementById('period').value  = '12';
    document.getElementById('amount').value  = '0';
}

// Basic form validation
function validateSurrenderForm() {
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerNumber) {
        alert('Please select a Locker Number.');
        return false;
    }
    var amount = parseFloat(document.getElementById('amount').value);
    if (isNaN(amount) || amount < 0) {
        alert('Please enter a valid Amount.');
        return false;
    }
    return true;
}
</script>
</body>
</html>
