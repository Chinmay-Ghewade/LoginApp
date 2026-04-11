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

  /* ── Labels ── */
  .fg label {
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
  .btn-action.active:hover { background: #2a2474; }

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

  /* ── Action bars ── */
  .action-bar {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
    margin-bottom: 10px;
  }
</style>
</head>
<body>

<!-- Title -->
<div class="page-title">Dividend Calculation</div>

<!-- ════════════ REPORT DETAILS ════════════ -->
<div class="section-card">
  <span class="card-title">Report Details</span>

  <!-- Row 1: Product Code | Description -->
  <div class="form-row">
    <div class="fg" style="max-width: 200px;">
      <label>Product Code</label>
      <div class="input-btn">
        <input type="text" id="productCode" name="productCode" />
        <button class="btn-lookup" type="button" onclick="lookupProduct()">...</button>
      </div>
    </div>
    <div class="fg fg-2">
      <label>Description</label>
      <input type="text" id="description" name="description" readonly />
    </div>
  </div>

  <!-- Row 2: Year Begin | Year End -->
  <div class="form-row">
    <div class="fg" style="max-width: 200px;">
      <label>Year Begin</label>
      <input type="date" id="yearBegin" name="yearBegin" />
    </div>
    <div class="fg" style="max-width: 200px;">
      <label>Year End</label>
      <input type="date" id="yearEnd" name="yearEnd" />
    </div>
  </div>

  <!-- Row 3: Div. Balance Date | Percentage -->
  <div class="form-row">
    <div class="fg" style="max-width: 200px;">
      <label>Div. Balance Date</label>
      <input type="date" id="divBalanceDate" name="divBalanceDate" />
    </div>
    <div class="fg" style="max-width: 200px;">
      <label>Percentage</label>
      <input type="number" id="percentage" name="percentage" step="0.01" />
    </div>
  </div>
</div>

<!-- Message -->
<div class="message-bar">
  <span class="msg-label">Message :</span>
  <input type="text" id="messageBox" readonly value="Please logout and login again!" />
</div>

<!-- Action Buttons Row 1 -->
<div class="action-bar">
  <button class="btn-action active" type="button" onclick="validateForm()">Validate</button>
  <button class="btn-action"        type="button" onclick="calculate()">Calculate</button>
  <button class="btn-action"        type="button" onclick="report()">Report</button>
  <button class="btn-action"        type="button" onclick="sbReport()">SB Report</button>
  <button class="btn-action"        type="button" onclick="sbReportXls()">SB Report XLS</button>
  <button class="btn-action"        type="button" onclick="payableReport()">Payable Report</button>
  <button class="btn-action"        type="button" onclick="payableReportXls()">Payable Report XLS</button>
  <button class="btn-cancel"        type="button" onclick="cancelForm()">Cancel</button>
</div>

<!-- Action Buttons Row 2 -->
<div class="action-bar">
  <button class="btn-action" type="button" onclick="postingPayable()">Posting Payable</button>
  <button class="btn-action" type="button" onclick="postingSB()">Posting SB</button>
</div>

<script>
  function setMessage(msg, isError) {
    var b = document.getElementById('messageBox');
    b.value             = msg;
    b.style.color       = isError ? '#c04040' : '#1a7a3a';
    b.style.background  = isError ? '#fff5f5' : '#f0fff4';
    b.style.borderColor = isError ? '#e0a0a0' : '#7ad0a0';
  }

  function lookupProduct()      { setMessage('Looking up product...', false); }
  function validateForm()       { setMessage('Form validated successfully.', false); }
  function calculate()          { setMessage('Calculating dividend...', false); }
  function report()             { setMessage('Generating report...', false); }
  function sbReport()           { setMessage('Generating SB report...', false); }
  function sbReportXls()        { setMessage('Generating SB report XLS...', false); }
  function payableReport()      { setMessage('Generating payable report...', false); }
  function payableReportXls()   { setMessage('Generating payable report XLS...', false); }
  function postingPayable()     { setMessage('Posting payable...', false); }
  function postingSB()          { setMessage('Posting SB...', false); }

  function cancelForm() {
    if (confirm('Cancel and clear the form?')) {
      document.querySelectorAll('input[type="text"], input[type="number"], input[type="date"]').forEach(function(i) {
        if (!i.readOnly && !i.disabled) i.value = '';
      });
      setMessage('Form cleared.', false);
    }
  }
</script>
</body>
</html>
