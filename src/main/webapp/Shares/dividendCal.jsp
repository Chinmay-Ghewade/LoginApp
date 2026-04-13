<%@ page trimDirectiveWhitespaces="true" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String branchCode  = (String) sess.getAttribute("branchCode");
    String user        = (String) sess.getAttribute("userId");
    String today       = new SimpleDateFormat("dd-MM-yyyy").format(new java.util.Date());
    String SERVLET_URL = request.getContextPath() + "/dividendCal";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dividend Calculation</title>
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

  .section-card {
    background: #E6E6FA;
    border: 1.5px solid #B8B8E6;
    border-radius: 10px;
    padding: 24px 20px 18px;
    margin-bottom: 18px;
    position: relative;
    max-width: 700px;
    margin-left: auto;
    margin-right: auto;
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

  .form-row {
    display: flex;
    gap: 16px;
    margin-bottom: 14px;
    align-items: flex-end;
    flex-wrap: wrap;
  }
  .form-row:last-child { margin-bottom: 0; }

  .fg      { display: flex; flex-direction: column; gap: 5px; flex: 1; min-width: 100px; }
  .fg-2    { flex: 2; }

  .fg label {
    font-size: 0.75rem;
    font-weight: 700;
    color: #1a1464;
    white-space: nowrap;
    display: block;
    margin-bottom: 4px;
  }

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

  .input-btn { display: flex; gap: 5px; align-items: center; }
  .input-btn input { flex: 1; }

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
  }
  .btn-lookup:hover { background: #eceef8; }

  .btn-action {
    height: 36px;
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
  .btn-action:hover { background: #eceef8; }
  .btn-action.active {
    background: #1a1464;
    color: #fff;
    border-color: #1a1464;
  }

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
  }
  .btn-cancel:hover { background: #fff0f0; }

  .message-bar {
    display: flex;
    align-items: center;
    gap: 10px;
    margin: 14px auto 18px;
    max-width: 700px;
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

  .action-bar {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
    margin-bottom: 10px;
  }

  /* ── Lookup Popup ── */
  .popup-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.4);
    z-index: 1000;
    justify-content: center;
    align-items: center;
  }
  .popup-overlay.show { display: flex; }
  .popup-box {
    background: #E6E6FA;
    border: 2px solid #B8B8E6;
    border-radius: 10px;
    min-width: 320px;
    overflow: hidden;
  }
  .popup-header {
    background: #1a1464;
    color: #fff;
    padding: 10px 16px;
    font-size: 0.85rem;
    font-weight: 700;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .popup-close {
    cursor: pointer;
    font-size: 1.1rem;
    font-weight: 700;
    color: #fff;
    background: none;
    border: none;
  }
  .popup-body { padding: 14px; }

  .lookup-tbl {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.82rem;
    background: #fff;
    border-radius: 6px;
    overflow: hidden;
    border: 1.5px solid #B8B8E6;
  }
  .lookup-tbl thead tr { background: #1a1464; color: #fff; }
  .lookup-tbl thead th { padding: 8px 16px; text-align: left; font-weight: 700; }
  .lookup-tbl tbody tr { cursor: pointer; }
  .lookup-tbl tbody tr:hover { background: #dde0f5; }
  .lookup-tbl tbody td { padding: 10px 16px; border-bottom: 1px solid #E0E0F0; color: #1a1464; font-weight: 600; }

  /* ── Result Table ── */
  .result-card {
    background: #E6E6FA;
    border: 1.5px solid #B8B8E6;
    border-radius: 10px;
    padding: 24px 20px 18px;
    margin-bottom: 18px;
    position: relative;
    max-width: 1100px;
    margin-left: auto;
    margin-right: auto;
  }
  .result-card .card-title {
    position: absolute;
    top: -12px;
    left: 16px;
    background: #E6E6FA;
    padding: 0 8px;
    font-size: 0.85rem;
    font-weight: 700;
    color: #1a1464;
  }
  .summary-bar { display: flex; gap: 14px; margin-bottom: 12px; flex-wrap: wrap; }
  .summary-item {
    background: #fff;
    border: 1.5px solid #B8B8E6;
    border-radius: 6px;
    padding: 6px 14px;
    font-size: 0.78rem;
    font-weight: 700;
    color: #1a1464;
  }
  .summary-item span { font-weight: 400; color: #3a3a7a; margin-left: 5px; }

  .table-wrap { overflow-x: auto; border-radius: 8px; border: 1.5px solid #B8B8E6; }
  table.res-tbl { width: 100%; border-collapse: collapse; font-size: 0.78rem; background: #fff; min-width: 800px; }
  table.res-tbl thead tr { background: #1a1464; color: #fff; }
  table.res-tbl thead th { padding: 8px 10px; text-align: left; font-weight: 700; white-space: nowrap; border-right: 1px solid #2a2474; }
  table.res-tbl thead th:last-child { border-right: none; }
  table.res-tbl tbody tr:nth-child(even) { background: #f0f0fa; }
  table.res-tbl tbody tr:hover { background: #dde0f5; }
  table.res-tbl tbody td { padding: 6px 10px; border-bottom: 1px solid #D8D8F0; color: #1a1464; white-space: nowrap; }
  table.res-tbl tfoot tr { background: #1a1464; color: #fff; }
  table.res-tbl tfoot td { padding: 7px 10px; font-weight: 700; }

  .badge-pending { display: inline-block; background: #fff5e0; color: #854F0B; border: 1px solid #EF9F27; border-radius: 4px; padding: 1px 7px; font-size: 0.72rem; font-weight: 700; }
  .badge-posted  { display: inline-block; background: #e0f5ea; color: #0F6E56; border: 1px solid #5DCAA5; border-radius: 4px; padding: 1px 7px; font-size: 0.72rem; font-weight: 700; }
</style>
</head>
<body>

<div class="page-title">Dividend Calculation</div>
<div class="meta-bar">
  <span>Branch: <b><%= branchCode %></b></span>
  <span>User: <b><%= user %></b></span>
  <span>Date: <b><%= today %></b></span>
</div>

<!-- ── Lookup Popup ── -->
<div class="popup-overlay" id="lookupPopup">
  <div class="popup-box">
    <div class="popup-header">
      <span>Select Member Type</span>
      <button class="popup-close" type="button" onclick="closePopup()">X</button>
    </div>
    <div class="popup-body">
      <table class="lookup-tbl">
        <thead>
          <tr><th>Product Code</th><th>Member Type</th></tr>
        </thead>
        <tbody id="lookupBody">
          <tr><td colspan="2" style="text-align:center;color:#888;padding:14px;">Loading...</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- ── Form ── -->
<div class="section-card">
  <span class="card-title">Report Details</span>

  <div class="form-row">
    <div class="fg" style="max-width:200px;">
      <label>Product Code</label>
      <div class="input-btn">
        <input type="text" id="productCode" readonly />
        <button class="btn-lookup" type="button" onclick="lookupProduct()">...</button>
      </div>
    </div>
    <div class="fg fg-2">
      <label>Member Type</label>
      <input type="text" id="memberType" readonly />
    </div>
  </div>

  <div class="form-row">
    <div class="fg" style="max-width:200px;">
      <label>Year Begin</label>
      <input type="date" id="yearBegin" />
    </div>
    <div class="fg" style="max-width:200px;">
      <label>Year End</label>
      <input type="date" id="yearEnd" />
    </div>
  </div>

  <div class="form-row">
    <div class="fg" style="max-width:200px;">
      <label>Div. Balance Date</label>
      <input type="date" id="divBalDate" />
    </div>
    <div class="fg" style="max-width:200px;">
      <label>Percentage</label>
      <input type="number" id="percentage" step="0.01" />
    </div>
  </div>
</div>

<!-- Message -->
<div class="message-bar">
  <span class="msg-label">Message :</span>
  <input type="text" id="messageBox" readonly value="Please select Product Code to begin." />
</div>

<!-- Action Buttons Row 1 -->
<div class="action-bar">
  <button class="btn-action active"  type="button" onclick="validateForm()">Validate</button>
  <button class="btn-action"         type="button" onclick="calculate()">Calculate</button>
  <button class="btn-action"         type="button" onclick="showReport('normal')">Report</button>
  <button class="btn-action"         type="button" onclick="showReport('sb')">SB Report</button>
  <button class="btn-action"         type="button" onclick="showReport('sbXls')">SB Report XLS</button>
  <button class="btn-action"         type="button" onclick="showReport('payable')">Payable Report</button>
  <button class="btn-action"         type="button" onclick="showReport('payableXls')">Payable Report XLS</button>
  <button class="btn-cancel"         type="button" onclick="cancelForm()">Cancel</button>
</div>

<!-- Action Buttons Row 2 -->
<div class="action-bar">
  <button class="btn-action" type="button" onclick="postingPayable()">Posting Payable</button>
  <button class="btn-action" type="button" onclick="postingSB()">Posting SB</button>
</div>

<!-- Result Grid -->
<div class="result-card" id="resultCard" style="display:none">
  <span class="card-title" id="resultTitle">Dividend Report</span>
  <div class="summary-bar" id="summaryBar"></div>
  <div class="table-wrap">
    <table class="res-tbl">
      <thead id="resultHead"></thead>
      <tbody id="resultBody"></tbody>
      <tfoot id="resultFoot"></tfoot>
    </table>
  </div>
</div>

<script>
  var PAGE_URL = '<%= SERVLET_URL %>';

  // ── Message box ──
  function setMessage(msg, isError) {
    var b = document.getElementById('messageBox');
    b.value             = msg;
    b.style.color       = isError ? '#c04040' : '#1a7a3a';
    b.style.background  = isError ? '#fff5f5' : '#f0fff4';
    b.style.borderColor = isError ? '#e0a0a0' : '#7ad0a0';
  }

  // ── AJAX POST helper ──
  function ajaxPost(url, body, onSuccess, onError) {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', url, true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== 4) return;
      if (xhr.status !== 200) { if (onError) onError(); return; }
      try {
        var raw = xhr.responseText;
        var si  = raw.indexOf('[');
        var si2 = raw.indexOf('{');
        if (si !== -1 && (si2 === -1 || si < si2)) raw = raw.substring(si);
        else if (si2 !== -1) raw = raw.substring(si2);
        onSuccess(JSON.parse(raw.trim()));
      } catch(e) { if (onError) onError(); }
    };
    xhr.send(body);
  }

  function buildBody(params) {
    return Object.keys(params).map(function(k) {
      return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
    }).join('&');
  }

  // ── STEP 1: Open lookup popup and load member types ──
  function lookupProduct() {
    document.getElementById('lookupPopup').classList.add('show');
    ajaxPost(PAGE_URL, buildBody({ action: 'getMemberTypes' }), function(data) {
      var html = '';
      if (!Array.isArray(data) || data.length === 0) {
        html = '<tr><td colspan="2" style="text-align:center;color:#888;padding:14px;">No member types found.</td></tr>';
      } else {
        data.forEach(function(row) {
          html += '<tr onclick="selectMemberType(\'' + row.productCode + '\',\'' + row.memberType + '\')">'
                + '<td>' + row.productCode + '</td>'
                + '<td>' + row.memberType  + '</td>'
                + '</tr>';
        });
      }
      document.getElementById('lookupBody').innerHTML = html;
    }, function() {
      document.getElementById('lookupBody').innerHTML =
        '<tr><td colspan="2" style="text-align:center;color:#c04040;padding:14px;">Failed to load. Check servlet.</td></tr>';
    });
  }

  function closePopup() {
    document.getElementById('lookupPopup').classList.remove('show');
  }

  // ── STEP 2: User selects member type → fetch account count ──
  // Passes both productCode and memberType so servlet filters correctly
  function selectMemberType(productCode, memberType) {
    closePopup();
    document.getElementById('productCode').value = productCode;
    document.getElementById('memberType').value  = memberType;
    setMessage('Fetching active accounts for Member Type ' + memberType + ' (Product: ' + productCode + ')...', false);

    ajaxPost(PAGE_URL, buildBody({
      action:      'getAccounts',
      memberType:  memberType,
      productCode: productCode
    }), function(data) {
      if (data.success) {
        setMessage(data.count + ' active member accounts found for Type '
          + data.memberType + ' (Product: ' + productCode + '). Fill remaining fields and click Calculate.', false);
      } else {
        setMessage('Error: ' + (data.message || 'Could not fetch accounts.'), true);
      }
    }, function() {
      setMessage('Network error fetching accounts.', true);
    });
  }

  // ── Validate ──
  function validateForm() {
    var pc  = document.getElementById('productCode').value.trim();
    var mt  = document.getElementById('memberType').value.trim();
    var yb  = document.getElementById('yearBegin').value;
    var ye  = document.getElementById('yearEnd').value;
    var dbd = document.getElementById('divBalDate').value;
    var pct = document.getElementById('percentage').value;
    if (!pc)       { setMessage('Please select Product Code first.', true);         return false; }
    if (!mt)       { setMessage('Please select Member Type first.', true);          return false; }
    if (!yb)       { setMessage('Year Begin is required.', true);                   return false; }
    if (!ye)       { setMessage('Year End is required.', true);                     return false; }
    if (!dbd)      { setMessage('Div. Balance Date is required.', true);            return false; }
    if (!pct)      { setMessage('Percentage is required.', true);                   return false; }
    if (yb >= ye)  { setMessage('Year End must be after Year Begin.', true);        return false; }
    setMessage('Form validated successfully. You can now click Calculate.', false);
    return true;
  }

  // ── Calculate ──
  function calculate() {
    if (!validateForm()) return;
    setMessage('Calculating dividend... please wait.', false);
    ajaxPost(PAGE_URL, buildBody({
      action:      'calculate',
      productCode: document.getElementById('productCode').value,
      memberType:  document.getElementById('memberType').value,
      yearBegin:   document.getElementById('yearBegin').value,
      yearEnd:     document.getElementById('yearEnd').value,
      divBalDate:  document.getElementById('divBalDate').value,
      percentage:  document.getElementById('percentage').value
    }), function(data) {
      setMessage(data.message || (data.success ? 'Done.' : 'Error.'), !data.success);
    }, function() {
      setMessage('Network error during calculation.', true);
    });
  }

  // ── Report — passes memberType so servlet WHERE clause filters correctly ──
  function showReport(type) {
    if (!validateForm()) return;
    setMessage('Loading report...', false);
    ajaxPost(PAGE_URL, buildBody({
      action:      'report',
      productCode: document.getElementById('productCode').value,
      memberType:  document.getElementById('memberType').value,
      yearBegin:   document.getElementById('yearBegin').value,
      yearEnd:     document.getElementById('yearEnd').value,
      divBalDate:  document.getElementById('divBalDate').value,
      reportType:  type
    }), function(data) {
      if (!data.success) { setMessage(data.message || 'Error loading report.', true); return; }
      if (data.count === 0) { setMessage('No records found in dividend_calc for these parameters.', true); return; }
      renderReport(data, type);
      setMessage(data.count + ' records found. Review before posting.', false);
    }, function() {
      setMessage('Network error loading report.', true);
    });
  }

  function renderReport(data, type) {
    document.getElementById('resultCard').style.display = 'block';
    var pc  = document.getElementById('productCode').value;
    var mt  = document.getElementById('memberType').value;
    var yb  = document.getElementById('yearBegin').value;
    var ye  = document.getElementById('yearEnd').value;
    var pct = document.getElementById('percentage').value;
    var isSB = (type === 'sb' || type === 'sbXls');

    document.getElementById('resultTitle').textContent =
      isSB ? 'SB Report — shares.dividend_calc' :
      (type === 'payable' || type === 'payableXls') ? 'Payable Report — shares.dividend_calc' :
      'Dividend Report — shares.dividend_calc';

    document.getElementById('summaryBar').innerHTML =
      '<div class="summary-item">Total Members <span>' + data.count + '</span></div>' +
      '<div class="summary-item">Product Code <span>' + pc + '</span></div>' +
      '<div class="summary-item">Member Type <span>' + mt + '</span></div>' +
      '<div class="summary-item">Year <span>' + yb + ' to ' + ye + '</span></div>' +
      '<div class="summary-item">Rate <span>' + pct + '%</span></div>' +
      '<div class="summary-item">Total Dividend <span>&#8377; ' + parseFloat(data.total).toFixed(2) + '</span></div>';

    document.getElementById('resultHead').innerHTML =
      '<tr>' +
      '<th>#</th><th>Member Account</th><th>Payable Account</th>' +
      (isSB ? '<th>SB Account</th>' : '') +
      '<th>Bal. for Div (&#8377;)</th><th>Rate %</th>' +
      '<th>Div Amount (&#8377;)</th><th>Post Amount (&#8377;)</th>' +
      '<th>Warrant No</th><th>Status</th><th>Txn Date</th>' +
      '</tr>';

    var html = '';
    data.rows.forEach(function(r, i) {
      var txnNo  = parseInt(r.payableTxnNo) || 0;
      var status = txnNo === 0
        ? '<span class="badge-pending">Pending</span>'
        : '<span class="badge-posted">Posted</span>';
      html += '<tr>' +
        '<td>' + (i+1) + '</td>' +
        '<td>' + (r.memberCode || '-') + '</td>' +
        '<td><b>' + (r.payableAc || '-') + '</b></td>' +
        (isSB ? '<td>' + (r.crAccountCode && r.crAccountCode !== '0' ? r.crAccountCode : '-') + '</td>' : '') +
        '<td style="text-align:right">' + parseFloat(r.balForDiv).toFixed(2) + '</td>' +
        '<td style="text-align:right">' + r.divPercentage + '%</td>' +
        '<td style="text-align:right">' + parseFloat(r.divAmount).toFixed(2) + '</td>' +
        '<td style="text-align:right;font-weight:700">' + parseFloat(r.divAmountPost).toFixed(2) + '</td>' +
        '<td style="text-align:center">' + r.divWarrNo + '</td>' +
        '<td>' + status + '</td>' +
        '<td>' + (r.payableTxnDate || '-') + '</td>' +
        '</tr>';
    });
    document.getElementById('resultBody').innerHTML = html;
    document.getElementById('resultFoot').innerHTML =
      '<tr>' +
      '<td colspan="' + (isSB ? '7' : '6') + '" style="text-align:right">Total Dividend to Post :</td>' +
      '<td style="text-align:right">&#8377; ' + parseFloat(data.total).toFixed(2) + '</td>' +
      '<td colspan="3"></td>' +
      '</tr>';
  }

  // ── Posting Payable ──
  function postingPayable() {
    if (!validateForm()) return;
    if (!confirm('Are you sure you want to post dividend to all payable accounts? This cannot be undone.')) return;
    setMessage('Posting dividend... please wait.', false);
    ajaxPost(PAGE_URL, buildBody({
      action:      'postingPayable',
      productCode: document.getElementById('productCode').value,
      memberType:  document.getElementById('memberType').value,
      yearBegin:   document.getElementById('yearBegin').value,
      yearEnd:     document.getElementById('yearEnd').value,
      divBalDate:  document.getElementById('divBalDate').value
    }), function(data) {
      setMessage(data.message || (data.success ? 'Posted.' : 'Error.'), !data.success);
      if (data.success) showReport('normal');
    }, function() {
      setMessage('Network error during posting.', true);
    });
  }

  // ── Posting SB ──
  function postingSB() {
    if (!validateForm()) return;
    if (!confirm('Are you sure you want to post dividend to SB accounts? This cannot be undone.')) return;
    setMessage('Posting to SB accounts... please wait.', false);
    ajaxPost(PAGE_URL, buildBody({
      action:      'postingSB',
      productCode: document.getElementById('productCode').value,
      memberType:  document.getElementById('memberType').value,
      yearBegin:   document.getElementById('yearBegin').value,
      yearEnd:     document.getElementById('yearEnd').value,
      divBalDate:  document.getElementById('divBalDate').value
    }), function(data) {
      setMessage(data.message || (data.success ? 'Posted.' : 'Error.'), !data.success);
      if (data.success) showReport('sb');
    }, function() {
      setMessage('Network error during SB posting.', true);
    });
  }

  // ── Cancel ──
  function cancelForm() {
    if (confirm('Cancel and clear the form?')) {
      document.getElementById('productCode').value = '';
      document.getElementById('memberType').value  = '';
      document.getElementById('yearBegin').value   = '';
      document.getElementById('yearEnd').value     = '';
      document.getElementById('divBalDate').value  = '';
      document.getElementById('percentage').value  = '';
      document.getElementById('resultCard').style.display = 'none';
      setMessage('Form cleared.', false);
    }
  }
</script>
</body>
</html>
