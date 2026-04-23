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
    font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
    background: #eaeaf5;
    min-height: 100vh;
    padding: 24px 28px;
    color: #1a1a6e;
  }

  .page-title {
    text-align: center;
    font-size: 1.45rem;
    font-weight: 800;
    color: #1a1a6e;
    margin-bottom: 32px;
    letter-spacing: 0.3px;
  }

  /* ── Toast ── */
  #toastContainer {
    position: fixed;
    top: 18px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 8px;
    pointer-events: none;
    align-items: center;
  }
  .toast {
    padding: 11px 18px;
    border-radius: 8px;
    font-size: 0.84rem;
    font-weight: 600;
    font-family: inherit;
    box-shadow: 0 4px 18px rgba(26,20,100,0.15);
    opacity: 0;
    transform: translateY(-8px);
    transition: opacity 0.22s, transform 0.22s;
    white-space: nowrap;
    pointer-events: none;
    max-width: 420px;
    display: flex;
    align-items: center;
    gap: 10px;
    min-width: 260px;
  }
  .toast.show    { opacity: 1; transform: translateY(0); }
  .toast.success { background: #e8f8f0; color: #0a6644; border-left: 4px solid #2db87a; }
  .toast.error   { background: #fff2f2; color: #b52020; border-left: 4px solid #e05050; }
  .toast.info    { background: #eef0fc; color: #1a1464; border-left: 4px solid #6870cc; }
  .toast.warning { background: #fffbea; color: #7a5c00; border-left: 4px solid #f0b429; }

  /* ── Section card ── */
  .section-card {
    background: #ffffff;
    border: 1.5px solid #c0c0e0;
    border-radius: 12px;
    padding: 28px 24px 22px;
    margin-bottom: 16px;
    position: relative;
    max-width: 1000px;
    margin-left: auto;
    margin-right: auto;
  }
  .section-card .card-title {
    position: absolute;
    top: -11px;
    left: 18px;
    background: #ffffff;
    padding: 0 8px;
    font-size: 0.88rem;
    font-weight: 700;
    color: #1a1a6e;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .form-row {
    display: grid;
    grid-template-columns: repeat(6, 1fr);
    gap: 14px;
    align-items: end;
  }

  .fg { display: flex; flex-direction: column; gap: 4px; }
  .fg label {
    font-size: 0.78rem;
    font-weight: 600;
    color: #1a1a6e;
    white-space: nowrap;
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }

  input[type="text"],
  input[type="number"],
  input[type="date"] {
    height: 34px;
    padding: 0 10px;
    border: 1px solid #c0c0e0;
    border-radius: 6px;
    font-size: 0.84rem;
    font-family: inherit;
    color: #1a1a6e;
    background: #ffffff;
    outline: none;
    width: 100%;
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  input[type="text"]:focus,
  input[type="number"]:focus,
  input[type="date"]:focus {
    border-color: #5050b0;
    box-shadow: 0 0 0 2px rgba(80,80,176,0.10);
  }
  input[readonly], input[disabled] {
    background: #ebebf5;
    color: #6060a0;
    border-color: #d0d0e8;
    cursor: default;
  }
  input.autofilled {
    background: #f4f4ff;
    border-color: #a0a0d8;
  }

  .input-btn { display: flex; gap: 5px; align-items: center; }
  .input-btn input { flex: 1; min-width: 0; }

  .btn-lookup {
    height: 34px;
    min-width: 38px;
    padding: 0 10px;
    background: #1a1a5e;
    color: #fff;
    border: none;
    border-radius: 6px;
    font-size: 0.85rem;
    font-weight: 700;
    cursor: pointer;
    flex-shrink: 0;
    transition: background 0.12s;
  }
  .btn-lookup:hover { background: #252588; }

  /* ── Action buttons ── */
  .action-wrap {
    max-width: 1000px;
    margin: 0 auto 16px;
    background: #ffffff;
    border: 1.5px solid #c0c0e0;
    border-radius: 12px;
    padding: 14px 20px;
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    justify-content: center;
  }

  .btn-divider {
    width: 1px;
    height: 26px;
    background: #c0c0e0;
    margin: 0 2px;
    flex-shrink: 0;
  }

  .btn {
    height: 34px;
    padding: 0 16px;
    border-radius: 6px;
    font-size: 0.76rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 5px;
    transition: background 0.12s, color 0.12s, opacity 0.12s;
    white-space: nowrap;
    border: 1.5px solid transparent;
  }

  .btn-primary { background: #1a1a5e; color: #fff; border-color: #1a1a5e; }
  .btn-primary:hover { background: #252588; border-color: #252588; }
  .btn-outline { background: #fff; color: #1a1a6e; border-color: #c0c0e0; }
  .btn-outline:hover { background: #ebebf5; border-color: #a0a0d8; }
  .btn-excel { background: #fff; color: #1a6e2a; border-color: #5cb870; }
  .btn-excel:hover { background: #f0fff4; }
  .btn-danger { background: #fff; color: #b52020; border-color: #e08080; }
  .btn-danger:hover { background: #fff2f2; }
  .btn-post { background: #fff; color: #0a6644; border-color: #2db87a; }
  .btn-post:hover { background: #e8f8f0; }

  /* ── Gated buttons (require calculation) ── */
  .btn.needs-calc,
  .btn:disabled {
    opacity: 0.42;
    cursor: not-allowed !important;
    pointer-events: none;
  }

  /* ── Lookup popup ── */
  .popup-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.35);
    z-index: 1000;
    justify-content: center;
    align-items: center;
  }
  .popup-overlay.show { display: flex; }
  .popup-box {
    background: #fff;
    border: 1.5px solid #c0c0e0;
    border-radius: 10px;
    min-width: 340px;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(26,20,100,0.18);
  }
  .popup-header {
    background: #1a1a5e;
    color: #fff;
    padding: 10px 16px;
    font-size: 0.83rem;
    font-weight: 700;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .popup-close {
    cursor: pointer;
    font-size: 1rem;
    font-weight: 700;
    color: #fff;
    background: none;
    border: none;
    line-height: 1;
  }
  .popup-body { padding: 14px; }

  .lookup-tbl {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.82rem;
    background: #fff;
    border-radius: 6px;
    overflow: hidden;
    border: 1.5px solid #c0c0e0;
  }
  .lookup-tbl thead tr { background: #1a1a5e; color: #fff; }
  .lookup-tbl thead th { padding: 8px 16px; text-align: left; font-weight: 700; }
  .lookup-tbl tbody tr { cursor: pointer; }
  .lookup-tbl tbody tr:hover { background: #ebebf5; }
  .lookup-tbl tbody td { padding: 10px 16px; border-bottom: 1px solid #eeeef8; color: #1a1a6e; font-weight: 600; }

  /* ── Result grid ── */
  .result-card {
    background: #ffffff;
    border: 1.5px solid #c0c0e0;
    border-radius: 12px;
    padding: 28px 20px 18px;
    margin-bottom: 18px;
    position: relative;
    max-width: 1200px;
    margin-left: auto;
    margin-right: auto;
  }
  .result-card .card-title {
    position: absolute;
    top: -11px;
    left: 18px;
    background: #ffffff;
    padding: 0 8px;
    font-size: 0.88rem;
    font-weight: 700;
    color: #1a1a6e;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .summary-bar { display: flex; gap: 10px; margin-bottom: 14px; flex-wrap: wrap; }
  .summary-item {
    background: #ebebf5;
    border: 1.5px solid #c0c0e0;
    border-radius: 6px;
    padding: 5px 14px;
    font-size: 0.75rem;
    font-weight: 700;
    color: #1a1a6e;
  }
  .summary-item span { font-weight: 400; color: #5050a0; margin-left: 5px; }

  .table-wrap { overflow-x: auto; border-radius: 8px; border: 1.5px solid #c0c0e0; }
  table.res-tbl { width: 100%; border-collapse: collapse; font-size: 0.78rem; background: #fff; min-width: 900px; }
  table.res-tbl thead tr { background: #38388a; color: #fff; }
  table.res-tbl thead th { padding: 8px 10px; text-align: left; font-weight: 700; white-space: nowrap; border-right: 1px solid #5050a8; }
  table.res-tbl thead th:last-child { border-right: none; }
  table.res-tbl tbody tr:nth-child(even) { background: #f6f6fb; }
  table.res-tbl tbody tr:hover { background: #ebebf5; }
  table.res-tbl tbody td { padding: 6px 10px; border-bottom: 1px solid #e4e4f4; color: #1a1a6e; white-space: nowrap; }
  table.res-tbl tfoot tr { background: #1a1a5e; color: #fff; }
  table.res-tbl tfoot td { padding: 7px 10px; font-weight: 700; }

  /* ── Report Pagination ── */
  .rpt-pagination {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 14px;
    margin-top: 14px;
    padding: 10px 0 2px;
  }
  .rpt-pg-btn {
    height: 32px;
    padding: 0 18px;
    background: #1a1a5e;
    color: #fff;
    border: none;
    border-radius: 6px;
    font-size: 0.78rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    transition: background 0.12s;
  }
  .rpt-pg-btn:hover:not(:disabled) { background: #252588; }
  .rpt-pg-btn:disabled { background: #c0c0d8; cursor: not-allowed; }
  .rpt-pg-info {
    font-size: 0.8rem;
    font-weight: 700;
    color: #1a1a6e;
    min-width: 90px;
    text-align: center;
  }

  /* ── Modals shared ── */
  .modal-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(20, 20, 70, 0.44);
    z-index: 6000;
    align-items: center;
    justify-content: center;
  }
  .modal-overlay.show { display: flex; }

  @keyframes modalIn {
    from { opacity: 0; transform: scale(0.92) translateY(-16px); }
    to   { opacity: 1; transform: scale(1)    translateY(0);     }
  }

  /* ── Confirm modal ── */
  .cm-modal {
    background: #fff;
    border-radius: 20px;
    box-shadow: 0 12px 52px rgba(20,20,100,0.22);
    width: 480px;
    max-width: 92vw;
    padding: 44px 44px 36px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 14px;
    animation: modalIn 0.22s ease;
    font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
  }
  .cm-icon {
    width: 56px; height: 56px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.55rem; font-weight: 900;
  }
  .cm-icon-green { background: #e6f9ee; color: #22aa55; }
  .cm-icon-red   { background: #fff0f0; color: #cc2222; }
  .cm-title { font-size: 1.22rem; font-weight: 800; color: #1a1a6e; text-align: center; }
  .cm-body  { font-size: 0.92rem; color: #444; text-align: center; line-height: 1.95; }
  .cm-body strong { color: #1a1a6e; font-weight: 700; }
  .cm-body .hl    { color: #22aa55; font-weight: 700; }
  .cm-body .warn  { color: #b52020; font-size: 0.82rem; font-style: italic; }
  .cm-btns { display: flex; gap: 12px; margin-top: 8px; }
  .cm-btn-cancel {
    height: 42px; padding: 0 28px;
    background: #ebebf5; color: #555;
    border: none; border-radius: 8px;
    font-size: 0.9rem; font-weight: 700; font-family: inherit;
    cursor: pointer; transition: background 0.12s;
  }
  .cm-btn-cancel:hover { background: #d4d4ea; }
  .cm-btn-ok {
    height: 42px; padding: 0 28px;
    background: #22aa55; color: #fff;
    border: none; border-radius: 8px;
    font-size: 0.9rem; font-weight: 700; font-family: inherit;
    cursor: pointer; transition: background 0.12s;
    white-space: nowrap;
  }
  .cm-btn-ok:hover        { background: #1a8f44; }
  .cm-btn-ok.cm-red       { background: #cc2222; }
  .cm-btn-ok.cm-red:hover { background: #aa1a1a; }

  /* ── Result modal ── */
  .pr-modal {
    background: #fff;
    border-radius: 20px;
    box-shadow: 0 12px 52px rgba(20,20,100,0.22);
    width: 480px;
    max-width: 92vw;
    padding: 44px 44px 36px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 14px;
    animation: modalIn 0.22s ease;
    font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
  }
  .pr-tick {
    width: 58px; height: 58px;
    border-radius: 50%;
    background: #e6f9ee;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.7rem; color: #22aa55; font-weight: 900;
  }
  .pr-title { font-size: 1.18rem; font-weight: 800; color: #1a1a6e; text-align: center; }
  .pr-info {
    font-size: 0.90rem; color: #333; text-align: center; line-height: 2.1;
    background: #f4f4ff; border: 1.5px solid #c8c8ec;
    border-radius: 10px; padding: 16px 28px; width: 100%;
  }
  .pr-info .pi-label { color: #6060a0; font-weight: 600; }
  .pr-info .pi-val   { color: #1a1a6e; font-weight: 800; }
  .pr-ok {
    height: 42px; padding: 0 56px;
    background: #22aa55; color: #fff;
    border: none; border-radius: 8px;
    font-size: 0.9rem; font-weight: 700; font-family: inherit;
    cursor: pointer; margin-top: 4px; transition: background 0.12s;
  }
  .pr-ok:hover { background: #1a8f44; }
</style>
</head>
<body>

<div id="toastContainer"></div>

<div class="page-title">Dividend Calculation</div>

<!-- ══ Lookup Popup ══ -->
<div class="popup-overlay" id="lookupPopup">
  <div class="popup-box">
    <div class="popup-header">
      <span>Select Member Type</span>
      <button class="popup-close" type="button" onclick="closePopup()">&#x2715;</button>
    </div>
    <div class="popup-body">
      <table class="lookup-tbl">
        <thead><tr><th>Product Code</th><th>Member Type</th></tr></thead>
        <tbody id="lookupBody">
          <tr><td colspan="2" style="text-align:center;color:#888;padding:14px;">Loading&#8230;</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- ══ Confirm Modal ══ -->
<div class="modal-overlay" id="cmOverlay">
  <div class="cm-modal">
    <div class="cm-icon cm-icon-green" id="cmIcon">&#10004;</div>
    <div class="cm-title" id="cmTitle">Confirm Action</div>
    <div class="cm-body"  id="cmBody"></div>
    <div class="cm-btns">
      <button class="cm-btn-cancel" id="cmCancelBtn" onclick="cmClose()">Cancel</button>
      <button class="cm-btn-ok"     id="cmOkBtn">Yes, Proceed</button>
    </div>
  </div>
</div>

<!-- ══ Post Result Modal ══ -->
<div class="modal-overlay" id="prOverlay">
  <div class="pr-modal">
    <div class="pr-tick">&#10003;</div>
    <div class="pr-title" id="prTitle">Posted Successfully!</div>
    <div class="pr-info"  id="prInfo"></div>
    <button class="pr-ok" onclick="prClose()">OK</button>
  </div>
</div>

<!-- ══ Form ══ -->
<div class="section-card">
  <span class="card-title">Report Details</span>
  <div class="form-row">

    <div class="fg">
      <label>Product Code</label>
      <div class="input-btn">
        <input type="text" id="productCode" readonly placeholder="&#8212;" />
        <button class="btn-lookup" type="button" onclick="lookupProduct()">&#8230;</button>
      </div>
    </div>

    <div class="fg">
      <label>Member Type</label>
      <input type="text" id="memberType" readonly placeholder="&#8212;" />
    </div>

    <div class="fg">
      <label>Year Begin</label>
      <input type="date" id="yearBegin" />
    </div>

    <div class="fg">
      <label>Year End</label>
      <input type="date" id="yearEnd" />
    </div>

    <div class="fg">
      <label>Div. Balance Date</label>
      <input type="date" id="divBalDate" />
    </div>

    <div class="fg">
      <label>Percentage (%)</label>
      <input type="number" id="percentage" step="0.01" placeholder="0.00" />
    </div>

  </div>
</div>

<!-- ══ Action Buttons ══ -->
<div class="action-wrap">
  <button class="btn btn-primary" type="button" onclick="validateForm()">&#10004; Validate</button>
  <button class="btn btn-outline" type="button" onclick="calculate()">&#9881; Calculate</button>

  <div class="btn-divider"></div>

  <button class="btn btn-outline needs-calc" id="btnReport"      type="button">Report</button>
  <button class="btn btn-outline needs-calc" id="btnSBReport"    type="button">SB Report</button>
  <button class="btn btn-excel   needs-calc" id="btnSBXls"       type="button">
    <svg width="12" height="12" viewBox="0 0 16 16" fill="none"><rect x="1" y="1" width="14" height="14" rx="2" stroke="#1a6e2a" stroke-width="1.4"/><path d="M4 5l2.5 3L4 11M8 11h4" stroke="#1a6e2a" stroke-width="1.2" stroke-linecap="round"/></svg>
    SB XLS
  </button>
  <button class="btn btn-outline needs-calc" id="btnPayable"     type="button">Payable Report</button>
  <button class="btn btn-excel   needs-calc" id="btnPayableXls"  type="button">
    <svg width="12" height="12" viewBox="0 0 16 16" fill="none"><rect x="1" y="1" width="14" height="14" rx="2" stroke="#1a6e2a" stroke-width="1.4"/><path d="M4 5l2.5 3L4 11M8 11h4" stroke="#1a6e2a" stroke-width="1.2" stroke-linecap="round"/></svg>
    Payable XLS
  </button>
  <button class="btn btn-danger  needs-calc" id="btnPDF"         type="button">
    <svg width="13" height="13" viewBox="0 0 16 16" fill="none">
      <rect x="2" y="1" width="9" height="12" rx="1" stroke="#b52020" stroke-width="1.3"/>
      <path d="M11 1l3 3v9a1 1 0 01-1 1H5" stroke="#b52020" stroke-width="1.3" stroke-linecap="round"/>
      <path d="M11 1v3h3" stroke="#b52020" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    PDF
  </button>

  <div class="btn-divider"></div>

  <button class="btn btn-post   needs-calc" id="btnPostPayable" type="button">&#8679; Post Payable</button>
  <button class="btn btn-post   needs-calc" id="btnPostSB"      type="button">&#8679; Post SB</button>

  <div class="btn-divider"></div>

  <button class="btn btn-danger" type="button" onclick="cancelForm()">&#10005; Cancel</button>
</div>

<!-- ══ Result Grid ══ -->
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
  <div class="rpt-pagination">
    <button id="reportPrevBtn" class="rpt-pg-btn" onclick="reportPrevPage()" disabled>&#8592; Previous</button>
    <span   id="reportPageInfo" class="rpt-pg-info">Page 1 of 1</span>
    <button id="reportNextBtn" class="rpt-pg-btn" onclick="reportNextPage()" disabled>Next &#8594;</button>
  </div>
</div>

<script>
  var PAGE_URL = '<%= SERVLET_URL %>';

  /* ── Calculation gate flag ── */
  var _calculationDone = false;

  /* ── Report pagination state ── */
  var _reportData     = null;
  var _reportType     = null;
  var _reportPage     = 1;
  var REPORT_PER_PAGE = 15;

  /* ── IDs of buttons that require a completed calculation ── */
  var GATED_BTN_IDS = [
    'btnReport','btnSBReport','btnSBXls',
    'btnPayable','btnPayableXls','btnPDF',
    'btnPostPayable','btnPostSB'
  ];

  /* ── Enable / disable gated buttons ── */
  function setCalcGate(done) {
    _calculationDone = done;
    GATED_BTN_IDS.forEach(function(id) {
      var el = document.getElementById(id);
      if (!el) return;
      el.disabled = !done;
      if (done) {
        el.classList.remove('needs-calc');
        el.title = '';
      } else {
        el.classList.add('needs-calc');
        el.title = 'Please run Calculate first';
      }
    });
  }

  /* ── Guard inside each gated function ── */
  function requireCalc(actionName) {
    if (_calculationDone) return true;
    showToast('\u26A0 Please run \u201CCalculate\u201D first before ' + (actionName || 'this action') + '.', 'warning', 4000);
    return false;
  }

  /* ── Toast ── */
  function showToast(msg, type, duration) {
    var container = document.getElementById('toastContainer');
    var t = document.createElement('div');
    t.className = 'toast ' + (type || 'info');
    t.textContent = msg;
    container.appendChild(t);
    requestAnimationFrame(function() {
      requestAnimationFrame(function() { t.classList.add('show'); });
    });
    setTimeout(function() {
      t.classList.remove('show');
      setTimeout(function() { if (t.parentNode) t.parentNode.removeChild(t); }, 300);
    }, duration || 3500);
  }

  /* ── AJAX helpers ── */
  function ajaxPost(url, body, onSuccess, onError) {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', url, true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== 4) return;
      if (xhr.status !== 200) { if (onError) onError(); return; }
      try {
        var raw = xhr.responseText;
        var si  = raw.indexOf('['), si2 = raw.indexOf('{');
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

  /* ── Confirm modal ── */
  var _cmCallback = null;

  function cmShow(title, bodyHtml, okLabel, callback, opts) {
    opts = opts || {};
    var icon = document.getElementById('cmIcon');
    icon.className = 'cm-icon ' + (opts.iconClass || 'cm-icon-green');
    icon.innerHTML = opts.iconChar || '&#10004;';
    document.getElementById('cmTitle').textContent     = title;
    document.getElementById('cmBody').innerHTML        = bodyHtml;
    document.getElementById('cmCancelBtn').textContent = opts.cancelLabel || 'Cancel';
    var okBtn = document.getElementById('cmOkBtn');
    okBtn.textContent = okLabel || 'Yes, Proceed';
    okBtn.className   = 'cm-btn-ok' + (opts.okRed ? ' cm-red' : '');
    _cmCallback = callback;
    document.getElementById('cmOverlay').classList.add('show');
  }

  function cmClose() {
    document.getElementById('cmOverlay').classList.remove('show');
    _cmCallback = null;
  }

  /* ── Result modal ── */
  function prShow(title, infoHtml) {
    document.getElementById('prTitle').textContent = title;
    document.getElementById('prInfo').innerHTML    = infoHtml;
    document.getElementById('prOverlay').classList.add('show');
  }
  function prClose() { document.getElementById('prOverlay').classList.remove('show'); }

  document.addEventListener('DOMContentLoaded', function() {
    /* wire confirm OK */
    document.getElementById('cmOkBtn').addEventListener('click', function() {
      cmClose();
      if (_cmCallback) _cmCallback();
    });

    /* wire all gated buttons via JS — NO inline onclick on these */
    var gatedActions = {
      btnReport:      function() { showReport('normal');    },
      btnSBReport:    function() { showReport('sb');         },
      btnSBXls:       function() { showReport('sbXls');      },
      btnPayable:     function() { showReport('payable');    },
      btnPayableXls:  function() { showReport('payableXls'); },
      btnPDF:         function() { openReportPDF();          },
      btnPostPayable: function() { postingPayable();         },
      btnPostSB:      function() { postingSB();              }
    };
    Object.keys(gatedActions).forEach(function(id) {
      var el = document.getElementById(id);
      if (el) el.addEventListener('click', gatedActions[id]);
    });

    /* any field change → invalidate previous calculation */
    ['yearBegin','yearEnd','divBalDate','percentage'].forEach(function(id) {
      document.getElementById(id).addEventListener('change', function() {
        this.classList.remove('autofilled');
        setCalcGate(false);
      });
    });

    /* start locked */
    setCalcGate(false);
  });

  /* ── Lookup popup ── */
  function lookupProduct() {
    document.getElementById('lookupPopup').classList.add('show');
    ajaxPost(PAGE_URL, buildBody({ action: 'getMemberTypes' }), function(data) {
      var html = '';
      if (!Array.isArray(data) || data.length === 0) {
        html = '<tr><td colspan="2" style="text-align:center;color:#888;padding:14px;">No member types found.</td></tr>';
      } else {
        data.forEach(function(row) {
          html += '<tr onclick="selectMemberType(\'' + row.productCode + '\',\'' + row.memberType + '\')">'
                + '<td>' + row.productCode + '</td><td>' + row.memberType + '</td></tr>';
        });
      }
      document.getElementById('lookupBody').innerHTML = html;
    }, function() {
      document.getElementById('lookupBody').innerHTML =
        '<tr><td colspan="2" style="text-align:center;color:#b52020;padding:14px;">Failed to load.</td></tr>';
    });
  }

  function closePopup() { document.getElementById('lookupPopup').classList.remove('show'); }

  function selectMemberType(productCode, memberType) {
    closePopup();
    document.getElementById('productCode').value = productCode;
    document.getElementById('memberType').value  = memberType;
    setCalcGate(false);
    document.getElementById('resultCard').style.display = 'none';
    _reportData = null; _reportType = null; _reportPage = 1;

    ajaxPost(PAGE_URL, buildBody({ action: 'getDefaults' }), function(data) {
      if (data.success) {
        var fields = { yearBegin: data.yearBegin, yearEnd: data.yearEnd,
                       divBalDate: data.divBalDate, percentage: data.percentage };
        Object.keys(fields).forEach(function(id) {
          if (fields[id]) {
            document.getElementById(id).value = fields[id];
            document.getElementById(id).classList.add('autofilled');
          }
        });
      }
      fetchAccountCount(productCode, memberType);
    }, function() { showToast('Network error loading defaults.', 'error'); });
  }

  function fetchAccountCount(productCode, memberType) {
    ajaxPost(PAGE_URL, buildBody({ action: 'getAccounts', memberType: memberType, productCode: productCode }),
    function(data) {
      if (data.success) showToast(data.count + ' active accounts found.', 'success');
    }, function() { });
  }

  /* ── Validate ── */
  function validateForm() {
    var checks = [
      [!document.getElementById('productCode').value.trim(), 'Select a Product Code first.'],
      [!document.getElementById('memberType').value.trim(),  'Member Type is required.'],
      [!document.getElementById('yearBegin').value,          'Year Begin is required.'],
      [!document.getElementById('yearEnd').value,            'Year End is required.'],
      [!document.getElementById('divBalDate').value,         'Div. Balance Date is required.'],
      [!document.getElementById('percentage').value,         'Percentage is required.'],
      [document.getElementById('yearBegin').value >= document.getElementById('yearEnd').value,
       'Year End must be after Year Begin.']
    ];
    for (var i = 0; i < checks.length; i++) {
      if (checks[i][0]) { showToast(checks[i][1], 'error'); return false; }
    }
    return true;
  }

  /* ── Calculate ── */
  function calculate() {
    if (!validateForm()) return;
    showToast('Calculating dividend\u2026', 'info');
    ajaxPost(PAGE_URL, buildBody({
      action:      'calculate',
      productCode: document.getElementById('productCode').value,
      memberType:  document.getElementById('memberType').value,
      yearBegin:   document.getElementById('yearBegin').value,
      yearEnd:     document.getElementById('yearEnd').value,
      divBalDate:  document.getElementById('divBalDate').value,
      percentage:  document.getElementById('percentage').value
    }), function(data) {
      if (data.success) {
        setCalcGate(true);
        showToast(data.message || 'Calculation complete. You may now generate reports.', 'success');
      } else {
        setCalcGate(false);
        showToast(data.message || 'Calculation failed.', 'error');
      }
    }, function() {
      setCalcGate(false);
      showToast('Network error during calculation.', 'error');
    });
  }

  /* ── showReport ── */
  function showReport(type) {
    if (!requireCalc('generating reports')) return;
    if (!validateForm()) return;
    if (type === 'sbXls')      { openExcelDownload('reportSBXls'); return; }
    if (type === 'payableXls') { openExcelDownload('reportCRXls'); return; }
    var actionMap = { normal: 'reportMain', sb: 'reportSB', payable: 'reportCR' };
    showToast('Fetching report\u2026', 'info');
    ajaxPost(PAGE_URL, buildBody({
      action:      actionMap[type] || 'reportMain',
      productCode: document.getElementById('productCode').value,
      memberType:  document.getElementById('memberType').value,
      yearBegin:   document.getElementById('yearBegin').value,
      yearEnd:     document.getElementById('yearEnd').value,
      divBalDate:  document.getElementById('divBalDate').value
    }), function(data) {
      if (!data.success) { showToast(data.message || 'Error loading report.', 'error'); return; }
      if (data.count === 0) { showToast('No records found.', 'error'); return; }
      renderReport(data, type);
      showToast(data.count + ' records loaded.', 'success');
    }, function() { showToast('Network error loading report.', 'error'); });
  }

  function openExcelDownload(action) {
    if (!requireCalc('downloading Excel')) return;
    if (!validateForm()) return;
    showToast('Preparing Excel download\u2026', 'info');
    var params = ['action=' + encodeURIComponent(action),
      'productCode=' + encodeURIComponent(document.getElementById('productCode').value),
      'memberType='  + encodeURIComponent(document.getElementById('memberType').value),
      'yearBegin='   + encodeURIComponent(document.getElementById('yearBegin').value),
      'yearEnd='     + encodeURIComponent(document.getElementById('yearEnd').value),
      'divBalDate='  + encodeURIComponent(document.getElementById('divBalDate').value)
    ].join('&');
    window.location.href = PAGE_URL + '?' + params;
  }

  /* ── renderReport ── */
  function renderReport(data, type) {
    _reportData = data;
    _reportType = type;
    _renderPage(1);
  }

  function _renderPage(page) {
    _reportPage   = page;
    var data      = _reportData;
    var type      = _reportType;
    var isSB      = (type === 'sb');
    var isPayable = (type === 'payable');

    var pc  = document.getElementById('productCode').value;
    var mt  = document.getElementById('memberType').value;
    var yb  = document.getElementById('yearBegin').value;
    var ye  = document.getElementById('yearEnd').value;
    var pct = document.getElementById('percentage').value;

    document.getElementById('resultCard').style.display = 'block';
    document.getElementById('resultTitle').textContent =
      isSB ? 'SB Report' : isPayable ? 'Payable (CR) Report' : 'Dividend Report';

    document.getElementById('summaryBar').innerHTML =
      '<div class="summary-item">Members <span>' + data.count + '</span></div>' +
      '<div class="summary-item">Product <span>' + pc + '</span></div>' +
      '<div class="summary-item">Type <span>' + mt + '</span></div>' +
      '<div class="summary-item">Period <span>' + yb + ' \u2013 ' + ye + '</span></div>' +
      '<div class="summary-item">Rate <span>' + pct + '%</span></div>' +
      '<div class="summary-item">Total Dividend <span>&#8377; ' + parseFloat(data.total).toFixed(2) + '</span></div>';

    var hdr = '<tr><th>#</th><th>Member Code</th><th>Name</th>' +
      '<th>Bal. for Div (&#8377;)</th><th>Rate %</th>' +
      '<th>Div Amount (&#8377;)</th><th>Post Amount (&#8377;)</th>';
    if (!isPayable) hdr += '<th>CR / SB Account</th>';
    if (isSB)       hdr += '<th>Branch</th>';
    hdr += '</tr>';
    document.getElementById('resultHead').innerHTML = hdr;

    var colCount   = isPayable ? 7 : (isSB ? 9 : 8);
    var totalRows  = data.rows.length;
    var totalPages = Math.max(1, Math.ceil(totalRows / REPORT_PER_PAGE));
    var start      = (page - 1) * REPORT_PER_PAGE;
    var end        = Math.min(start + REPORT_PER_PAGE, totalRows);

    var html = '';
    for (var i = start; i < end; i++) {
      var r = data.rows[i];
      html += '<tr>' +
        '<td>' + (i + 1) + '</td>' +
        '<td>' + (r.memberCode   || r.member_code   || '-') + '</td>' +
        '<td>' + (r.name         || '-') + '</td>' +
        '<td style="text-align:right">' + parseFloat(r.balForDiv      || r.bal_shares_for_div || 0).toFixed(2) + '</td>' +
        '<td style="text-align:right">' + (r.divPercentage || r.div_percentage || 0) + '%</td>' +
        '<td style="text-align:right">' + parseFloat(r.divAmount      || r.div_amount         || 0).toFixed(2) + '</td>' +
        '<td style="text-align:right;font-weight:700">' + parseFloat(r.divAmountPost || r.div_amount_post || 0).toFixed(2) + '</td>';
      if (!isPayable) {
        var cr = r.crAccountCode || r.cr_account_code || '';
        html += '<td>' + (cr && cr !== '0' ? cr : '-') + '</td>';
      }
      if (isSB) html += '<td>' + (r.branchCode || r.branch_code || '-') + '</td>';
      html += '</tr>';
    }
    document.getElementById('resultBody').innerHTML = html;

    document.getElementById('resultFoot').innerHTML =
      '<tr><td colspan="' + (colCount - 1) + '" style="text-align:right">Total Dividend to Post :</td>' +
      '<td style="text-align:right">&#8377; ' + parseFloat(data.total).toFixed(2) + '</td></tr>';

    document.getElementById('reportPrevBtn').disabled  = (page <= 1);
    document.getElementById('reportNextBtn').disabled  = (page >= totalPages);
    document.getElementById('reportPageInfo').textContent = 'Page ' + page + ' of ' + totalPages;
    document.getElementById('resultCard').scrollIntoView({ behavior: 'smooth' });
  }

  function reportPrevPage() { if (_reportPage > 1) _renderPage(_reportPage - 1); }
  function reportNextPage() {
    var tp = Math.ceil(_reportData.rows.length / REPORT_PER_PAGE);
    if (_reportPage < tp) _renderPage(_reportPage + 1);
  }

  function openReportPDF() {
    if (!requireCalc('opening PDF')) return;
    if (!validateForm()) return;
    showToast('Opening PDF\u2026', 'info');
    var params = ['action=reportPDF',
      'productCode=' + encodeURIComponent(document.getElementById('productCode').value),
      'memberType='  + encodeURIComponent(document.getElementById('memberType').value),
      'yearBegin='   + encodeURIComponent(document.getElementById('yearBegin').value),
      'yearEnd='     + encodeURIComponent(document.getElementById('yearEnd').value),
      'divBalDate='  + encodeURIComponent(document.getElementById('divBalDate').value),
      'percentage='  + encodeURIComponent(document.getElementById('percentage').value)
    ].join('&');
    window.open(PAGE_URL + '?' + params, '_blank');
  }

  /* ── Post Payable ── */
  function postingPayable() {
    if (!requireCalc('posting payable')) return;
    if (!validateForm()) return;
    var mt = document.getElementById('memberType').value;
    var pc = document.getElementById('productCode').value;
    cmShow(
      'Confirm Post Payable',
      'Are you sure you want to <strong>post dividend</strong> to all payable accounts?'
        + '<br>Member Type &nbsp;: <span class="hl">' + mt + '</span>'
        + '<br>Product Code : <span class="hl">' + pc + '</span>'
        + '<br><span class="warn">&#9888;&nbsp; This action cannot be undone.</span>',
      'Yes, Post Payable',
      function() {
        showToast('Posting to payable accounts\u2026', 'info');
        ajaxPost(PAGE_URL, buildBody({
          action: 'postingPayable', productCode: pc, memberType: mt,
          yearBegin: document.getElementById('yearBegin').value,
          yearEnd:   document.getElementById('yearEnd').value,
          divBalDate: document.getElementById('divBalDate').value
        }), function(data) {
          if (data.success) {
            var cnt = data.count !== undefined ? data.count : data.recordsPosted !== undefined ? data.recordsPosted : '\u2014';
            prShow('Payable Posting Complete!',
              '<span class="pi-label">Member Type &nbsp;&nbsp;&nbsp;</span>: &nbsp;<span class="pi-val">' + mt + '</span><br>'
            + '<span class="pi-label">Product Code &nbsp;&nbsp;</span>: &nbsp;<span class="pi-val">' + pc + '</span><br>'
            + '<span class="pi-label">Records Posted&nbsp;</span>: &nbsp;<span class="pi-val">' + cnt + '</span><br>'
            + '<span class="pi-label">Status &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>: &nbsp;<span class="pi-val" style="color:#22aa55;">&#10003; Success</span>');
            showReport('normal');
          } else { showToast(data.message || 'Payable posting failed.', 'error'); }
        }, function() { showToast('Network error during posting.', 'error'); });
      }
    );
  }

  /* ── Post SB ── */
  function postingSB() {
    if (!requireCalc('posting SB')) return;
    if (!validateForm()) return;
    var mt = document.getElementById('memberType').value;
    var pc = document.getElementById('productCode').value;
    cmShow(
      'Confirm Post SB',
      'Are you sure you want to <strong>post dividend</strong> to all SB accounts?'
        + '<br>Member Type &nbsp;: <span class="hl">' + mt + '</span>'
        + '<br>Product Code : <span class="hl">' + pc + '</span>'
        + '<br><span class="warn">&#9888;&nbsp; This action cannot be undone.</span>',
      'Yes, Post SB',
      function() {
        showToast('Posting to SB accounts\u2026', 'info');
        ajaxPost(PAGE_URL, buildBody({
          action: 'postingSB', productCode: pc, memberType: mt,
          yearBegin: document.getElementById('yearBegin').value,
          yearEnd:   document.getElementById('yearEnd').value,
          divBalDate: document.getElementById('divBalDate').value
        }), function(data) {
          if (data.success) {
            var cnt = data.count !== undefined ? data.count : data.recordsPosted !== undefined ? data.recordsPosted : '\u2014';
            prShow('SB Posting Complete!',
              '<span class="pi-label">Member Type &nbsp;&nbsp;&nbsp;</span>: &nbsp;<span class="pi-val">' + mt + '</span><br>'
            + '<span class="pi-label">Product Code &nbsp;&nbsp;</span>: &nbsp;<span class="pi-val">' + pc + '</span><br>'
            + '<span class="pi-label">Records Posted&nbsp;</span>: &nbsp;<span class="pi-val">' + cnt + '</span><br>'
            + '<span class="pi-label">Status &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>: &nbsp;<span class="pi-val" style="color:#22aa55;">&#10003; Success</span>');
            showReport('sb');
          } else { showToast(data.message || 'SB posting failed.', 'error'); }
        }, function() { showToast('Network error during SB posting.', 'error'); });
      }
    );
  }

  /* ══════════════════════════════════════════════════════
     ── Cancel / Clear — THE FIX ──
     readonly inputs block  el.value = ''  in some browsers.
     Solution: remove readonly → clear → restore readonly.
     Also wipes result card completely.
  ══════════════════════════════════════════════════════ */
  function cancelForm() {
    cmShow(
      'Clear Form?',
      'Are you sure you want to <strong>clear all fields</strong>?'
        + '<br><span class="warn">&#9888;&nbsp; All unsaved data will be lost.</span>',
      'Yes, Clear',
      function() {

        /* 1. Clear readonly fields by temporarily lifting readonly */
        ['productCode', 'memberType'].forEach(function(id) {
          var el = document.getElementById(id);
          el.removeAttribute('readonly');
          el.value = '';
          el.setAttribute('readonly', 'readonly');
          el.classList.remove('autofilled');
        });

        /* 2. Clear normal fields */
        ['yearBegin', 'yearEnd', 'divBalDate', 'percentage'].forEach(function(id) {
          var el = document.getElementById(id);
          el.value = '';
          el.classList.remove('autofilled');
        });

        /* 3. Hide AND empty the result card completely */
        document.getElementById('resultCard').style.display = 'none';
        document.getElementById('resultHead').innerHTML     = '';
        document.getElementById('resultBody').innerHTML     = '';
        document.getElementById('resultFoot').innerHTML     = '';
        document.getElementById('summaryBar').innerHTML     = '';

        /* 4. Reset pagination state */
        _reportData = null;
        _reportType = null;
        _reportPage = 1;

        /* 5. Lock all gated buttons */
        setCalcGate(false);

        showToast('Form cleared successfully.', 'info');
      },
      { iconClass: 'cm-icon-red', iconChar: '&#9888;', okRed: true, cancelLabel: 'No, Keep Data' }
    );
  }
</script>
</body>
</html>
