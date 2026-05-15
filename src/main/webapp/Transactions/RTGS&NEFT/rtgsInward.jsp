<%@ page import="java.sql.*, db.DBConnection, java.text.SimpleDateFormat, java.util.Date" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String contextPath  = request.getContextPath();
    String bankCode     = (String) session.getAttribute("bankCode");
    String userLogin    = (String) session.getAttribute("userId");
    if (bankCode  == null) bankCode  = "0100";
    if (userLogin == null) userLogin = "admin";
    String branchCodeVal = (branchCode != null) ? branchCode : "0002";
    String today = new SimpleDateFormat("dd-MMM-yyyy").format(new Date()).toUpperCase();
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RTGS Inward Auto</title>
  <link rel="stylesheet" href="../../css/rtgs.css">
  <link rel="stylesheet" href="../../css/tabs-navigation.css">
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    .page-header {
      text-align: center;
      font-size: 24px;
      font-weight: bold;
      color: #373279;
      margin: 20px 0 6px 0;
      letter-spacing: 1px;
    }

    .inward-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }
    .inward-table th {
      background: #d6d6f0;
      color: #373279;
      font-weight: bold;
      padding: 7px 10px;
      border: 1px solid #aaa;
      text-align: left;
      white-space: nowrap;
    }
    .inward-table td {
      padding: 6px 10px;
      border: 1px solid #ccc;
      background: #fff;
      vertical-align: middle;
    }
    .inward-table tr:nth-child(even) td { background: #f0f0fb; }
    .inward-table td input[type="text"] {
      height: 28px;
      border: 1px solid #aaa;
      border-radius: 4px;
      padding: 0 6px;
      font-size: 12px;
      width: 150px;
      box-sizing: border-box;
    }

    .status-tag {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 3px;
      font-size: 11px;
      font-weight: bold;
    }
    .status-c  { background: #ffe0e0; color: #a00; }
    .status-ok { background: #e0ffe0; color: #060; }

    #resultsFieldset { display: none; }

    form { padding: 0 20px; }
    .form-buttons { display: flex !important; flex-wrap: wrap; }
  </style>
</head>
<body>

<div class="page-header">RTGS INWARD ENTRY</div>

<div id="rtgsSuccessModal" style="
    display:none; position:fixed; top:0; left:0;
    width:100%; height:100%; background:rgba(0,0,0,0.5);
    justify-content:center; align-items:center; z-index:10000;">
  <div style="background:white; width:500px; padding:40px; border-radius:12px;
              box-shadow:0 4px 20px rgba(0,0,0,0.3); text-align:center;">
    <div style="color:#2ecc71; font-size:48px; margin-bottom:20px;">✓</div>
    <div id="rtgsSuccessMessage" style="font-size:20px; font-weight:bold; color:#333;
                                        margin-bottom:30px; line-height:1.5;"></div>
    <button onclick="closeSuccessModal()"
            style="background:#2ecc71; color:white; border:none; padding:12px 50px;
                   border-radius:6px; font-size:16px; font-weight:bold; cursor:pointer;"
            onmouseover="this.style.background='#27ae60'"
            onmouseout="this.style.background='#2ecc71'">OK</button>
  </div>
</div>

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

<form id="inwardForm" onsubmit="return false;">

  <fieldset>
    <legend>Rtgs Details</legend>

    <div class="form-grid">

      <div>
        <label>File Name</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <button type="button" class="icon-btn"
                  onclick="document.getElementById('csvFileInput').click()"
                  style="background-color:#2D2B80; color:white; border:none;
                         width:35px; height:35px; border-radius:8px;
                         font-size:16px; cursor:pointer; flex-shrink:0;">…</button>
          <input type="file" id="csvFileInput" accept=".csv" style="display:none;"
                 onchange="handleFileSelect(this)">
          <input type="text" name="fileName" id="fileName" class="form-input"
                 placeholder="Select CSV file…" readonly>
        </div>
      </div>

      <div>
        <label>Total Records</label>
        <input type="text" name="totalRecords" id="totalRecords" readonly>
      </div>
      <div>
        <label>Total Amount</label>
        <input type="text" name="totalAmount" id="totalAmount" readonly>
      </div>

      <div>
        <label>Total Matching Records</label>
        <input type="text" name="totalMatchingRecords" id="totalMatchingRecords" readonly>
      </div>
      <div>
        <label>Total Matching Amount</label>
        <input type="text" name="totalMatchingAmount" id="totalMatchingAmount" readonly>
      </div>

      <div>
        <label>Total Non-Matching Records</label>
        <input type="text" name="totalNonMatchingRecords" id="totalNonMatchingRecords" readonly>
      </div>
      <div>
        <label>Total Non-Matching Amount</label>
        <input type="text" name="totalNonMatchingAmount" id="totalNonMatchingAmount" readonly>
      </div>

    </div>

  </fieldset>

  <div class="form-buttons">
    <button type="button" class="action-btn btn-validate"  onclick="doValidate()">Validate</button>
    <button type="button" class="action-btn btn-vouchers"  onclick="doCheckBalance()">Check Account Balance</button>
    <button type="button" class="action-btn btn-signature" onclick="doDisplayNonMatching()">Display Non-Matching</button>
    <button type="button" class="action-btn btn-save"      onclick="doDisplayMatching()">Display Matching</button>
    <button type="button" class="action-btn btn-save"      onclick="doUpdate()">Update</button>
    <button type="button" class="action-btn btn-cancel"    onclick="doCancel()">Cancel</button>
  </div>

  <fieldset id="resultsFieldset">
    <legend>Rtgs Details</legend>
    <table class="inward-table" id="resultsTable">
      <thead>
        <tr>
          <th></th>
          <th>Check Inward Date</th>
          <th>Account Code</th>
          <th>Account Name</th>
          <th>Account Status</th>
          <th>Amount</th>
          <th>CBS Implemented</th>
          <th>Mod.Account Code</th>
        </tr>
      </thead>
      <tbody id="resultsBody"></tbody>
    </table>
  </fieldset>

</form>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

let _allRows       = [];
let _validatedRows = [];

function showRtgsError(msg) {
    document.getElementById('rtgsErrorMessage').textContent = msg;
    document.getElementById('rtgsErrorModal').style.display = 'flex';
}
function closeRtgsErrorModal() {
    document.getElementById('rtgsErrorModal').style.display = 'none';
}
function showSuccess(msg) {
    document.getElementById('rtgsSuccessMessage').textContent = msg;
    document.getElementById('rtgsSuccessModal').style.display = 'flex';
}
function closeSuccessModal() {
    document.getElementById('rtgsSuccessModal').style.display = 'none';
}

function handleFileSelect(input) {
    const file = input.files[0];
    if (!file) return;
    document.getElementById('fileName').value = file.name;
    clearSummary();
    _allRows = [];
    _validatedRows = [];
    hideResults();
    document.getElementById('messageBox').value = 'File selected. Click Validate to process.';
}

function clearSummary() {
    ['totalRecords','totalAmount','totalMatchingRecords',
     'totalMatchingAmount','totalNonMatchingRecords','totalNonMatchingAmount']
        .forEach(id => document.getElementById(id).value = '');
    document.getElementById('messageBox').value = '';
}

function doValidate() {
    const fileInput = document.getElementById('csvFileInput');
    if (!fileInput.files.length) {
        showRtgsError('Please select a CSV file first.');
        return;
    }
    const formData = new FormData();
    formData.append('csvFile', fileInput.files[0]);
    formData.append('action', 'validate');

    fetch(window.APP_CONTEXT_PATH + '/RTGSInwardAuto', { method: 'POST', body: formData })
        .then(r => r.json())
        .then(data => {
            if (!data.success) { showRtgsError(data.message || 'Validation failed.'); return; }

            _allRows       = data.rows || [];
            _validatedRows = data.rows || [];

            const total    = _allRows.length;
            const matching = _allRows.filter(r => r.matching).length;
            const nonMatch = total - matching;
            const totalAmt = _allRows.reduce((s, r) => s + (parseFloat(r.amount) || 0), 0);
            const matchAmt = _allRows.filter(r => r.matching).reduce((s, r) => s + (parseFloat(r.amount) || 0), 0);
            const nonAmt   = totalAmt - matchAmt;

            document.getElementById('totalRecords').value            = total;
            document.getElementById('totalAmount').value             = totalAmt.toFixed(0);
            document.getElementById('totalMatchingRecords').value    = matching;
            document.getElementById('totalMatchingAmount').value     = matchAmt.toFixed(0);
            document.getElementById('totalNonMatchingRecords').value = nonMatch;
            document.getElementById('totalNonMatchingAmount').value  = nonAmt.toFixed(0);
            document.getElementById('messageBox').value              = data.message || 'Validation complete.';

            renderResults(_allRows);
        })
        .catch(err => showRtgsError('Network error: ' + err.message));
}

function doCheckBalance() {
    if (!_validatedRows.length) { showRtgsError('Please validate a file first.'); return; }
    fetch(window.APP_CONTEXT_PATH + '/RTGSInwardAuto', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'action=checkBalance'
    })
    .then(r => r.json())
    .then(data => {
        document.getElementById('messageBox').value = data.message || '';
        if (data.success) showSuccess(data.message || 'Balance check complete.');
        else showRtgsError(data.message || 'Balance check failed.');
    })
    .catch(err => showRtgsError('Network error: ' + err.message));
}

function doDisplayNonMatching() {
    if (!_validatedRows.length) { showRtgsError('Please validate a file first.'); return; }
    const rows = _validatedRows.filter(r => !r.matching);
    if (!rows.length) { showRtgsError('No non-matching records found.'); return; }
    renderResults(rows);
}

function doDisplayMatching() {
    if (!_validatedRows.length) { showRtgsError('Please validate a file first.'); return; }
    const rows = _validatedRows.filter(r => r.matching);
    if (!rows.length) { showRtgsError('No matching records found.'); return; }
    renderResults(rows);
}

function doUpdate() {
    if (!_validatedRows.length) { showRtgsError('Please validate a file first.'); return; }
    const checked = Array.from(document.querySelectorAll('.row-chk:checked'))
                         .map(cb => cb.dataset.idx);
    if (!checked.length) { showRtgsError('Please select at least one record to update.'); return; }

    fetch(window.APP_CONTEXT_PATH + '/RTGSInwardAuto', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'update', selectedRows: checked })
    })
    .then(r => r.json())
    .then(data => {
        document.getElementById('messageBox').value = data.message || '';
        if (data.success) showSuccess(data.message || 'Records updated successfully.');
        else showRtgsError(data.message || 'Update failed.');
    })
    .catch(err => showRtgsError('Network error: ' + err.message));
}

function doCancel() {
    document.getElementById('inwardForm').reset();
    clearSummary();
    _allRows = [];
    _validatedRows = [];
    hideResults();
    document.getElementById('fileName').value = '';
}

function renderResults(rows) {
    const tbody = document.getElementById('resultsBody');
    tbody.innerHTML = '';
    rows.forEach((row, idx) => {
        const statusClass = row.accountStatus === 'C' ? 'status-c' : 'status-ok';
        const tr = document.createElement('tr');
        tr.innerHTML =
            '<td><input type="checkbox" class="row-chk" data-idx="' + idx + '"></td>' +
            '<td>' + (row.inwardDate     || '') + '</td>' +
            '<td>' + (row.accountCode    || '') + '</td>' +
            '<td>' + (row.accountName    || '') + '</td>' +
            '<td><span class="status-tag ' + statusClass + '">' + (row.accountStatus || '') + '</span></td>' +
            '<td>' + (row.amount         || '') + '</td>' +
            '<td>' + (row.cbsImplemented || 'Y') + '</td>' +
            '<td><input type="text" value="' + (row.modAccountCode || row.accountCode || '') + '"></td>';
        tbody.appendChild(tr);
    });
    document.getElementById('resultsFieldset').style.display = 'block';
}

function hideResults() {
    document.getElementById('resultsFieldset').style.display = 'none';
    document.getElementById('resultsBody').innerHTML = '';
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb('Transactions > RTGS / NEFT > RTGS Inward');
    }
    document.getElementById('rtgsErrorModal').addEventListener('click', function(e) {
        if (e.target === this) closeRtgsErrorModal();
    });
    document.getElementById('rtgsSuccessModal').addEventListener('click', function(e) {
        if (e.target === this) closeSuccessModal();
    });
};
</script>

</body>
</html>
