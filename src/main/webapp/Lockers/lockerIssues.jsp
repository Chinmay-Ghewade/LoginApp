<%@ page import="java.sql.*, db.DBConnection, org.json.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    // ─────────────────────────────────────────────
    // AJAX: Return locker types as JSON
    // ─────────────────────────────────────────────
    if ("getLockerTypes".equals(request.getParameter("action"))) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print("{\"success\":false,\"message\":\"DB connection failed\"}"); return; }

            ps = conn.prepareStatement(
                "SELECT LOCKER_TYPE FROM HEADOFFICE.LOCKERTYPE ORDER BY LOCKER_TYPE"
            );
            rs = ps.executeQuery();

            JSONArray arr = new JSONArray();
            while (rs.next()) {
                JSONObject o = new JSONObject();
                String lt = rs.getString("LOCKER_TYPE");
                o.put("lockerType", lt != null ? lt.trim() : "");
                arr.put(o);
            }
            JSONObject result = new JSONObject();
            result.put("success", true);
            result.put("lockerTypes", arr);
            out.print(result.toString());
        } catch (Exception e) {
            out.print("{\"success\":false,\"message\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
        } finally {
            try { if (rs!=null) rs.close(); } catch(Exception i){}
            try { if (ps!=null) ps.close(); } catch(Exception i){}
            try { if (conn!=null) conn.close(); } catch(Exception i){}
        }
        return;
    }

    // ─────────────────────────────────────────────
    // AJAX: Return available locker numbers as JSON
    // ─────────────────────────────────────────────
    if ("getLockerNumbers".equals(request.getParameter("action"))) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

        String sessionBranch = (String) session.getAttribute("branchCode");
        String lockerType    = request.getParameter("lockerType");

        System.out.println("DEBUG >>> branch='" + sessionBranch + "' | lockerType='" + lockerType + "'");

        if (sessionBranch == null) {
            out.print("{\"success\":false,\"message\":\"Session expired\"}");
            return;
        }

        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print("{\"success\":false,\"message\":\"DB connection failed\"}"); return; }

            String sql = "SELECT LOCKER_NUMBER, LOCKER_TYPE, CUPBORD_NO, KEY_NO " +
                         "FROM BRANCH.BRANCHLOCKER " +
                         "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                         "AND TRIM(LOCKER_STATUS) = 'A'";

            if (lockerType != null && !lockerType.trim().isEmpty()) {
                sql += " AND TRIM(LOCKER_TYPE) = TRIM(?)";
            }
            sql += " ORDER BY LOCKER_NUMBER";

            ps = conn.prepareStatement(sql);
            ps.setString(1, sessionBranch.trim());
            if (lockerType != null && !lockerType.trim().isEmpty()) {
                ps.setString(2, lockerType.trim());
            }
            rs = ps.executeQuery();

            JSONArray arr = new JSONArray();
            while (rs.next()) {
                JSONObject o = new JSONObject();
                o.put("lockerNumber", rs.getString("LOCKER_NUMBER") != null ? rs.getString("LOCKER_NUMBER") : "");
                o.put("lockerType",   rs.getString("LOCKER_TYPE")   != null ? rs.getString("LOCKER_TYPE").trim() : "");
                o.put("cupbordNo",    rs.getObject("CUPBORD_NO")    != null ? rs.getString("CUPBORD_NO") : "");
                o.put("keyNo",        rs.getObject("KEY_NO")        != null ? rs.getString("KEY_NO") : "");
                arr.put(o);
            }

            JSONObject result = new JSONObject();
            result.put("success", true);
            result.put("lockers", arr);
            out.print(result.toString());

        } catch (Exception e) {
            out.print("{\"success\":false,\"message\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
        } finally {
            try { if (rs!=null) rs.close(); } catch(Exception i){}
            try { if (ps!=null) ps.close(); } catch(Exception i){}
            try { if (conn!=null) conn.close(); } catch(Exception i){}
        }
        return;
    }

    // ─────────────────────────────────────────────
    // Normal page load — session check
    // ─────────────────────────────────────────────
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
  <title>Locker Issue</title>
  <link rel="stylesheet" href="../css/locker.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <link rel="stylesheet" href="../css/lookup-modal.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    select.dd-loading { color: #999; background-color: #f9f9f9; font-style: italic; }
    .dd-spinner {
      display: inline-block; width: 8px; height: 8px; border-radius: 50%;
      background: #373279; margin-left: 4px;
      animation: ddPulse 0.8s ease-in-out infinite alternate; vertical-align: middle;
    }
    @keyframes ddPulse {
      from { opacity: 0.2; transform: scale(0.8); }
      to   { opacity: 1;   transform: scale(1.1); }
    }
    .dd-spinner.done { display: none; }

    .input-icon-box { position: relative; width: 90%; }
    .input-icon-box input {
      width: 100%; padding-right: 40px; height: 30px;
      cursor: pointer; box-sizing: border-box;
    }
    .input-icon-box .inside-icon-btn {
      position: absolute; right: 5px; top: 50%; transform: translateY(-50%);
      background: none; border: none; font-size: 16px; cursor: pointer; color: #373279;
    }
    .icon-btn:disabled {
      background-color: #aaa !important;
      cursor: not-allowed !important;
      opacity: 0.6;
    }
    .form-buttons { display: flex !important; }
    
    #checkAvailabilityBtn:hover  { background-color: #2b0d73; transform: scale(1.05); }
    #checkAvailabilityBtn:active { transform: scale(0.97); }
    form { padding: 0 20px; }

    /* ── Customer lookup styling ── */
    #issueCustomerLookupContent .lookup-title {
      font-size: 1.05rem; font-weight: 700; color: var(--lk-primary);
      padding: 16px 18px 12px 18px; border-bottom: 1px solid var(--lk-border-light);
      display: flex; align-items: center; gap: 10px;
    }
    #issueCustomerLookupContent .search-box {
      padding: 14px 18px 8px 18px; background: var(--lk-primary-light);
      border-bottom: 1px solid var(--lk-border-light);
    }
    #issueCustomerLookupContent #customerSearch {
      width: 100%; height: 40px; padding: 0 14px 0 42px;
      border: 1.5px solid var(--lk-border); border-radius: var(--lk-radius-md);
      font-size: 0.875rem; font-family: var(--lk-font); color: var(--lk-text);
      box-sizing: border-box; outline: none;
      background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='15' height='15' fill='%238066E8' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11'/%3E%3C/svg%3E") no-repeat 13px center;
      transition: border-color 0.18s ease, box-shadow 0.18s ease;
    }
    #issueCustomerLookupContent #customerSearch::placeholder { color: #a090cc; }
    #issueCustomerLookupContent #customerSearch:focus {
      border-color: var(--lk-primary); box-shadow: 0 0 0 3px rgba(55,50,121,0.10);
    }
    #issueCustomerLookupContent .customer-count {
      font-size: 0.75rem; color: var(--lk-text-muted); text-align: right;
      padding: 6px 18px; border-bottom: 1px solid var(--lk-border-light);
    }
    #issueCustomerLookupContent .customer-count strong { color: var(--lk-primary); }
    #issueCustomerLookupContent .table-container { flex: 1; overflow-y: auto; overflow-x: auto; min-height: 0; }
    #issueCustomerLookupContent .table-container::-webkit-scrollbar { width: 7px; }
    #issueCustomerLookupContent .table-container::-webkit-scrollbar-track { background: var(--lk-primary-light); }
    #issueCustomerLookupContent .table-container::-webkit-scrollbar-thumb { background: var(--lk-border); border-radius: 10px; }
    #issueCustomerLookupContent #customerTable { width: 100%; border-collapse: collapse; font-family: var(--lk-font); }
    #issueCustomerLookupContent #customerTable thead tr {
      background: linear-gradient(90deg, var(--lk-primary) 0%, var(--lk-accent) 100%);
      position: sticky; top: 0; z-index: 2;
    }
    #issueCustomerLookupContent #customerTable thead th {
      padding: 11px 16px; text-align: left; font-size: 0.77rem; font-weight: 700;
      color: rgba(255,255,255,0.95); letter-spacing: 0.06em; text-transform: uppercase;
      border-right: 1px solid rgba(255,255,255,0.12); white-space: nowrap;
    }
    #issueCustomerLookupContent #customerTable thead th:last-child { border-right: none; }
    #issueCustomerLookupContent #customerTable tbody tr {
      border-bottom: 1px solid var(--lk-border-light); cursor: pointer;
      transition: background 0.18s ease, transform 0.1s ease; border-left: 3px solid transparent;
    }
    #issueCustomerLookupContent #customerTable tbody tr:nth-child(even) { background: var(--lk-row-stripe); }
    #issueCustomerLookupContent #customerTable tbody tr:hover {
      background: var(--lk-row-hover); border-left-color: var(--lk-primary-mid); transform: translateX(2px);
    }
    #issueCustomerLookupContent #customerTable tbody td {
      padding: 11px 16px; font-size: 0.875rem; color: var(--lk-text);
      vertical-align: middle; border-right: 1px solid var(--lk-border-light);
    }
    #issueCustomerLookupContent #customerTable tbody td:last-child { border-right: none; }
    #issueCustomerLookupContent #customerTable tbody td:first-child {
      font-weight: 700; color: var(--lk-primary); font-size: 0.84rem; white-space: nowrap;
    }

    /* ── Simple list item ── */
    .simple-lookup-item {
      padding: 13px 20px; cursor: pointer; font-size: 14px; font-weight: 600;
      color: #373279; border-bottom: 1px solid #ece8f8;
      border-left: 3px solid transparent; transition: all 0.15s ease;
      display: flex; align-items: center; justify-content: space-between;
    }
    .simple-lookup-item:hover { background: #f0eefb; border-left-color: #373279; }

    /* ── Success Modal ── */
    #lockerSuccessModal {
      display: none; position: fixed; inset: 0; z-index: 9999;
      background: rgba(0,0,0,0.45);
      align-items: center; justify-content: center;
    }
    #lockerSuccessModal.open { display: flex; }
    .success-card {
      background: #fff; border-radius: 18px;
      padding: 36px 40px 30px 40px; text-align: center;
      box-shadow: 0 12px 48px rgba(55,50,121,0.22);
      max-width: 420px; width: 90%;
      animation: popIn 0.28s cubic-bezier(.34,1.56,.64,1);
    }
    @keyframes popIn {
      from { transform: scale(0.7); opacity: 0; }
      to   { transform: scale(1);   opacity: 1; }
    }
    .success-icon {
      width: 68px; height: 68px; border-radius: 50%;
      background: linear-gradient(135deg,#373279,#5a3ec8);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 18px auto; font-size: 32px;
    }
    .success-card h2 {
      color: #373279; font-size: 1.25rem; margin: 0 0 8px 0;
      font-family: Arial,sans-serif;
    }
    .success-card p {
      color: #666; font-size: 0.9rem; margin: 5px 0;
      font-family: Arial,sans-serif;
    }
    .success-detail-box {
      background: #f4f2fc; border-radius: 10px;
      padding: 14px 20px; margin: 16px 0;
      text-align: left;
    }
    .success-detail-row {
      display: flex; justify-content: space-between;
      font-family: Arial,sans-serif; font-size: 0.88rem;
      padding: 4px 0; border-bottom: 1px solid #e0daf5;
    }
    .success-detail-row:last-child { border-bottom: none; }
    .success-detail-row span:first-child { color: #888; }
    .success-detail-row span:last-child  { color: #373279; font-weight: 700; }
    .success-ok-btn {
      background: linear-gradient(135deg,#373279,#5a3ec8);
      color: #fff; border: none; border-radius: 8px;
      padding: 11px 48px; font-size: 1rem; font-weight: 700;
      cursor: pointer; font-family: Arial,sans-serif;
      margin-top: 6px; transition: opacity 0.2s;
    }
    .success-ok-btn:hover { opacity: 0.88; }
  </style>
</head>
<body>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOCKER ISSUE SUCCESS MODAL                                     -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lockerSuccessModal">
  <div class="success-card">
    <div class="success-icon">✅</div>
    <h2>Locker Issued Successfully!</h2>
    <p>The locker has been assigned to the customer.</p>
    <div class="success-detail-box">
      <div class="success-detail-row">
        <span>Locker Type</span>
        <span id="successLockerType">—</span>
      </div>
      <div class="success-detail-row">
        <span>Locker Number</span>
        <span id="successLockerNumber">—</span>
      </div>
      <div class="success-detail-row">
        <span>Customer ID</span>
        <span id="successCustomerId">—</span>
      </div>
      <div class="success-detail-row">
        <span>Customer Name</span>
        <span id="successCustomerName">—</span>
      </div>
    </div>
    <button class="success-ok-btn" onclick="closeSuccessModal()">OK</button>
  </div>
</div>


<form id="lockerIssueForm" onsubmit="submitLockerIssue(event)">

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
          <button type="button" class="inside-icon-btn"
                  onclick="openLockerTypeLookup()" title="Search Locker Type">🔍</button>
        </div>
      </div>

      <div>
        <label>Locker Number</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="lockerNumberSearch" id="lockerNumberSearch"
                 class="form-input" readonly>
          <button type="button" id="lockerNumberBtn" class="icon-btn"
                  onclick="openLockerNumberLookup()" disabled
                  title="Select Locker Type first"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
        <small id="lockerNumberHint" style="font-size:11px;color:#888;margin-top:2px;display:block;">
          Select locker type first
        </small>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: LOCKER ACCOUNT DETAILS                -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Account Details</legend>
    <div class="form-grid">

      <div>
        <label>Key No</label>
        <input type="text" name="keyNo" id="keyNo" readonly>
      </div>

      <div>
        <label>Customer Id</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="customerIdLookup" id="customerIdLookup"
                 class="form-input" onclick="openCustomerLookup(this)">
          <button type="button" class="icon-btn" onclick="openCustomerLookup(this)"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
      </div>

      <div>
        <label>Customer Name</label>
        <input type="text" name="customerNameDisplay" id="customerNameDisplay">
      </div>

      <div>
        <label>Name of Hire</label>
        <input type="text" name="nameOfHire" id="nameOfHire">
      </div>

      <div>
        <label>Category</label>
        <input type="text" name="category" id="category" value="PUBLIC">
      </div>

      <div>
        <label>Mobile No.</label>
        <input type="text" name="dispMobile" id="dispMobile">
      </div>

      <div>
        <label>Address 1</label>
        <input type="text" name="dispAddress1" id="dispAddress1">
      </div>

      <div>
        <label>Address 2</label>
        <input type="text" name="dispAddress2" id="dispAddress2">
      </div>

      <div>
        <label>Address 3</label>
        <input type="text" name="dispAddress3" id="dispAddress3">
      </div>

      <div>
        <label>Telephone Res.</label>
        <input type="text" name="dispTelRes" id="dispTelRes">
      </div>

      <div>
        <label>Telephone Office</label>
        <input type="text" name="dispTelOffice" id="dispTelOffice">
      </div>

      <div>
        <label>City <span class="dd-spinner" id="citySpinner"></span></label>
        <select name="dispCity" id="dispCity" class="dd-loading">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Pin</label>
        <input type="text" name="dispPin" id="dispPin">
      </div>

      <div>
        <label>Rent Paid Till Date</label>
        <input type="date" name="rentPaidTillDate" id="rentPaidTillDate">
      </div>

      <div>
        <label>Mode of Operation</label>
        <select name="modeOfOperation" id="modeOfOperation">
          <option value="JOINT">JOINT</option>
          <option value="SINGLE">SINGLE</option>
          <option value="EITHER_OR_SURVIVOR">EITHER OR SURVIVOR</option>
          <option value="ANYONE_OR_SURVIVOR">ANYONE OR SURVIVOR</option>
        </select>
      </div>

      <div>
        <label>Lessor Agre.</label>
        <input type="text" name="lessorAgre" id="lessorAgre">
      </div>

      <div>
        <label>Nominee</label>
        <div style="flex-direction:row;" class="radio-group">
          <label><input type="radio" name="nomineeFlag" value="yes"> Yes</label>
          <label><input type="radio" name="nomineeFlag" value="no" checked> No</label>
        </div>
      </div>

      <div>
        <label>Join Operation</label>
        <div style="flex-direction:row;" class="radio-group">
          <label><input type="radio" name="joinOperation" value="yes"> Yes</label>
          <label><input type="radio" name="joinOperation" value="no" checked> No</label>
        </div>
      </div>

    </div>
  </fieldset>

  <div class="form-buttons">
    <button type="submit" id="issueLockerBtn">Issue Locker</button>
    <button type="button" onclick="resetLockerForm()">Reset</button>
  </div>

</form>


<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOCKER TYPE LOOKUP MODAL                                       -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lockerTypeLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:35%; max-width:380px;
                max-height:70vh; overflow:hidden; display:flex; flex-direction:column;
                box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">

        <div style="display:flex; align-items:center; justify-content:space-between;
                    padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73);
                    border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);
                            border-radius:6px;display:flex;align-items:center;
                            justify-content:center;font-size:17px;">🔒</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;">Select Locker Type</span>
            </div>
            <span onclick="closeLockerTypeLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <div style="padding:12px 18px 8px 18px; background:#f4f2fc; border-bottom:1px solid #e0daf5;">
            <input type="text" id="lockerTypeSearchInput" placeholder="Search locker type..."
                   oninput="filterLockerTypes()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;
                          border-radius:6px;font-size:0.875rem;box-sizing:border-box;
                          outline:none;font-family:Arial,sans-serif;color:#333;">
        </div>

        <div style="font-size:0.75rem;color:#888;text-align:right;padding:5px 18px;border-bottom:1px solid #ece8f8;">
            Total: <strong id="lockerTypeCount" style="color:#373279;">0</strong>
        </div>

        <div id="lockerTypeList" style="flex:1;overflow-y:auto;min-height:0;">
            <div style="text-align:center;padding:24px;color:#888;">Loading...</div>
        </div>
    </div>
</div>


<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOCKER NUMBER LOOKUP MODAL                                     -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lockerNumberLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:50%; max-width:560px;
                max-height:72vh; overflow:hidden; display:flex; flex-direction:column;
                box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">

        <div style="display:flex; align-items:center; justify-content:space-between;
                    padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73);
                    border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);
                            border-radius:6px;display:flex;align-items:center;
                            justify-content:center;font-size:17px;">🗄️</div>
                <div>
                    <div style="font-size:1.05rem;font-weight:700;color:#fff;">Available Lockers</div>
                    <div id="lockerNumberModalSubtitle"
                         style="font-size:0.78rem;color:rgba(255,255,255,0.7);margin-top:1px;"></div>
                </div>
            </div>
            <span onclick="closeLockerNumberLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <div style="padding:12px 18px 8px 18px; background:#f4f2fc; border-bottom:1px solid #e0daf5;">
            <input type="text" id="lockerNumberSearchInput" placeholder="Search locker number..."
                   oninput="filterLockerNumbers()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;
                          border-radius:6px;font-size:0.875rem;box-sizing:border-box;
                          outline:none;font-family:Arial,sans-serif;color:#333;">
        </div>

        <div style="font-size:0.75rem;color:#888;text-align:right;padding:5px 18px;border-bottom:1px solid #ece8f8;">
            Available: <strong id="lockerNumberCount" style="color:#373279;">0</strong>
        </div>

        <div style="flex:1;overflow-y:auto;overflow-x:auto;min-height:0;">
            <table style="width:100%;border-collapse:collapse;font-family:Arial,sans-serif;">
                <thead>
                    <tr style="background:linear-gradient(90deg,#373279,#5a3ec8);position:sticky;top:0;z-index:2;">
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;
                                   color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;
                                   border-right:1px solid rgba(255,255,255,0.12);">Locker No.</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;
                                   color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;
                                   border-right:1px solid rgba(255,255,255,0.12);">Type</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;
                                   color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;
                                   border-right:1px solid rgba(255,255,255,0.12);">Cupboard No.</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;
                                   color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;">Key No.</th>
                    </tr>
                </thead>
                <tbody id="lockerNumberTableBody">
                    <tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>


<!-- ════════════════════════════════════════════════════════════════ -->
<!-- CUSTOMER LOOKUP MODAL                                          -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="issueCustomerLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:85%; max-width:920px;
                max-height:84vh; overflow:hidden; display:flex; flex-direction:column;
                box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">

        <div style="display:flex; align-items:center; justify-content:space-between;
                    padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73);
                    border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);
                            border-radius:6px;display:flex;align-items:center;
                            justify-content:center;font-size:17px;">🔍</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;">Customer Lookup</span>
            </div>
            <span onclick="closeCustomerLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <div id="issueCustomerLookupLoading"
             style="display:flex;align-items:center;justify-content:center;
                    gap:10px;padding:40px 20px;color:#8066E8;font-size:14px;">
            <div style="width:18px;height:18px;border:2.5px solid #e0dcf8;
                        border-top-color:#8066E8;border-radius:50%;
                        animation:lk-spin 0.7s linear infinite;"></div>
            Loading customers...
        </div>

        <div id="issueCustomerLookupContent"
             style="display:flex;flex-direction:column;flex:1;overflow:hidden;"></div>
    </div>
</div>


<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ── Submission guard — prevents double-click / duplicate inserts ────
var _isSubmitting = false;

var _allLockerTypes   = [];
var _allLockerNumbers = [];

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath
                ? window.buildBreadcrumbPath('Lockers/lockerIssues.jsp')
                : 'Locker Issues'
        );
    }
    loadCityDropdown();

    // Close success modal on backdrop click
    document.getElementById('lockerSuccessModal').addEventListener('click', function(e) {
        if (e.target === this) closeSuccessModal();
    });
};


// ══════════════════════════════════════════════════════════════════════
// FORM SUBMIT — calls LockerIssueServlet via fetch, shows success popup
// ══════════════════════════════════════════════════════════════════════
function submitLockerIssue(e) {
    e.preventDefault();

    // ── Block if a submission is already in flight ──────────────────
    if (_isSubmitting) return;

    var btn = document.getElementById('issueLockerBtn');

    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();
    var customerId   = document.getElementById('customerIdLookup').value.trim();

    // Client-side validation — do NOT set _isSubmitting until all checks pass
    if (!lockerType) {
        showToast('Please select a Locker Type.', true); return;
    }
    if (!lockerNumber) {
        showToast('Please select a Locker Number.', true); return;
    }
    if (!customerId) {
        showToast('Please select a Customer.', true); return;
    }

    // ── All validation passed — lock submission ─────────────────────
    _isSubmitting   = true;
    btn.disabled    = true;
    btn.textContent = 'Issuing...';

    var formData = new FormData(document.getElementById('lockerIssueForm'));

    fetch(window.APP_CONTEXT_PATH + '/LockerIssueServlet', {
        method: 'POST',
        body:   formData
    })
    .then(function(res) { return res.json(); })
    .then(function(data) {
        // ── Always unlock after response ────────────────────────────
        _isSubmitting   = false;
        btn.disabled    = false;
        btn.textContent = 'Issue Locker';

        if (data.success) {
            document.getElementById('successLockerType').textContent   = data.lockerType   || '—';
            document.getElementById('successLockerNumber').textContent = data.lockerNumber || '—';
            document.getElementById('successCustomerId').textContent   = data.customerId   || '—';
            document.getElementById('successCustomerName').textContent = data.customerName || '—';
            document.getElementById('lockerSuccessModal').classList.add('open');
            resetLockerForm();
        } else {
            showToast(data.message || 'Failed to issue locker.', true);
        }
    })
    .catch(function(err) {
        // ── Unlock on network error too ─────────────────────────────
        _isSubmitting   = false;
        btn.disabled    = false;
        btn.textContent = 'Issue Locker';
        showToast('Network error: ' + err.message, true);
    });
}

function closeSuccessModal() {
    document.getElementById('lockerSuccessModal').classList.remove('open');
}

// ── Toast helper ────────────────────────────────────────────────────
function showToast(msg, isError) {
    Toastify({
        text:        msg,
        duration:    3500,
        gravity:     'top',
        position:    'right',
        stopOnFocus: true,
        style: {
            background:   isError
                ? 'linear-gradient(to right,#e53935,#b71c1c)'
                : 'linear-gradient(to right,#373279,#5a3ec8)',
            borderRadius: '8px',
            fontFamily:   'Arial,sans-serif',
            fontSize:     '14px'
        }
    }).showToast();
}


// ── City Dropdown ───────────────────────────────────────────────────
function loadCityDropdown() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
        .then(function(res) { if (!res.ok) throw new Error('HTTP ' + res.status); return res.json(); })
        .then(function(data) {
            var citySelect  = document.getElementById('dispCity');
            var citySpinner = document.getElementById('citySpinner');
            var cities      = data.city;
            if (Array.isArray(cities) && cities.length > 0) {
                citySelect.innerHTML = '<option value="">-- Select City --</option>';
                cities.forEach(function(item) {
                    var opt = document.createElement('option');
                    opt.value = item.v; opt.textContent = item.l;
                    citySelect.appendChild(opt);
                });
            } else {
                citySelect.innerHTML = '<option value="">-- Error loading --</option>';
                citySelect.style.borderColor = '#f44336';
            }
            citySelect.classList.remove('dd-loading');
            if (citySpinner) citySpinner.classList.add('done');
        })
        .catch(function(err) {
            var citySelect  = document.getElementById('dispCity');
            var citySpinner = document.getElementById('citySpinner');
            citySelect.innerHTML = '<option value="">-- Error: reload page --</option>';
            citySelect.classList.remove('dd-loading');
            citySelect.style.borderColor = '#f44336';
            if (citySpinner) { citySpinner.style.background = '#f44336'; citySpinner.classList.add('done'); }
        });
}


// ══════════════════════════════════════════════════════════════════════
// LOCKER TYPE LOOKUP
// ══════════════════════════════════════════════════════════════════════
function openLockerTypeLookup() {
    document.getElementById('lockerTypeLookupModal').style.display = 'flex';
    document.getElementById('lockerTypeSearchInput').value = '';

    if (_allLockerTypes.length > 0) { renderLockerTypeList(_allLockerTypes); return; }

    document.getElementById('lockerTypeList').innerHTML =
        '<div style="text-align:center;padding:24px;color:#888;">Loading...</div>';

    fetch('lockerIssues.jsp?action=getLockerTypes')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success && data.lockerTypes) {
                _allLockerTypes = data.lockerTypes;
                renderLockerTypeList(_allLockerTypes);
            } else {
                document.getElementById('lockerTypeList').innerHTML =
                    '<div style="text-align:center;padding:24px;color:red;">'
                    + (data.message || 'Failed to load.') + '</div>';
            }
        })
        .catch(function(err) {
            document.getElementById('lockerTypeList').innerHTML =
                '<div style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</div>';
        });
}

function renderLockerTypeList(items) {
    var list = document.getElementById('lockerTypeList');
    document.getElementById('lockerTypeCount').textContent = items.length;
    if (items.length === 0) {
        list.innerHTML = '<div style="text-align:center;padding:24px;color:#888;">No locker types found.</div>';
        return;
    }
    var html = '';
    items.forEach(function(lt) {
        html += '<div class="simple-lookup-item" onclick="selectLockerType(\'' + lt.lockerType + '\')">'
             + '<span>' + lt.lockerType + '</span>'
             + '</div>';
    });
    list.innerHTML = html;
}

function filterLockerTypes() {
    var query = document.getElementById('lockerTypeSearchInput').value.toUpperCase().trim();
    renderLockerTypeList(!query ? _allLockerTypes : _allLockerTypes.filter(function(lt) {
        return lt.lockerType.toUpperCase().indexOf(query) !== -1;
    }));
}

function selectLockerType(lockerType) {
    document.getElementById('lockerTypeSearch').value = lockerType;
    closeLockerTypeLookup();

    var btn  = document.getElementById('lockerNumberBtn');
    var hint = document.getElementById('lockerNumberHint');
    btn.disabled     = false;
    btn.title        = 'Search available lockers';
    hint.textContent = '';

    document.getElementById('lockerNumberSearch').value = '';
    document.getElementById('keyNo').value              = '';
    _allLockerNumbers = [];
}

function closeLockerTypeLookup() {
    document.getElementById('lockerTypeLookupModal').style.display = 'none';
}

document.getElementById('lockerTypeLookupModal').addEventListener('click', function(e) {
    if (e.target === this) closeLockerTypeLookup();
});


// ══════════════════════════════════════════════════════════════════════
// LOCKER NUMBER LOOKUP
// ══════════════════════════════════════════════════════════════════════
function openLockerNumberLookup() {
    var lockerType = document.getElementById('lockerTypeSearch').value.trim();
    if (!lockerType) { showToast('Please select a Locker Type first.', true); return; }

    document.getElementById('lockerNumberLookupModal').style.display = 'flex';
    document.getElementById('lockerNumberSearchInput').value = '';
    document.getElementById('lockerNumberModalSubtitle').textContent =
        'Type: ' + lockerType + '  •  Status: Available only';

    if (_allLockerNumbers.length > 0) { renderLockerNumberRows(_allLockerNumbers); return; }

    document.getElementById('lockerNumberTableBody').innerHTML =
        '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>';

    fetch('lockerIssues.jsp?action=getLockerNumbers&lockerType=' + encodeURIComponent(lockerType))
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success) {
                _allLockerNumbers = data.lockers || [];
                renderLockerNumberRows(_allLockerNumbers);
            } else {
                document.getElementById('lockerNumberTableBody').innerHTML =
                    '<tr><td colspan="4" style="text-align:center;padding:24px;color:red;">'
                    + (data.message || 'Failed to load.') + '</td></tr>';
            }
        })
        .catch(function(err) {
            document.getElementById('lockerNumberTableBody').innerHTML =
                '<tr><td colspan="4" style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</td></tr>';
        });
}

function renderLockerNumberRows(items) {
    var tbody = document.getElementById('lockerNumberTableBody');
    document.getElementById('lockerNumberCount').textContent = items.length;

    if (items.length === 0) {
        tbody.innerHTML =
            '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">No available lockers found for this type.</td></tr>';
        return;
    }

    var fragment = document.createDocumentFragment();
    items.forEach(function(lk) {
        var tr = document.createElement('tr');
        tr.style.cssText = 'border-bottom:1px solid #ece8f8;cursor:pointer;border-left:3px solid transparent;transition:all 0.15s ease;';
        tr.addEventListener('mouseover', function() { this.style.background='#f0eefb'; this.style.borderLeftColor='#373279'; });
        tr.addEventListener('mouseout',  function() { this.style.background='';       this.style.borderLeftColor='transparent'; });
        tr.addEventListener('click',     function() { selectLockerNumber(lk.lockerNumber, lk.keyNo); });

        var cells = [
            { val: lk.lockerNumber, style: 'padding:11px 16px;font-weight:700;color:#373279;font-size:0.9rem;border-right:1px solid #ece8f8;' },
            { val: lk.lockerType,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;border-right:1px solid #ece8f8;' },
            { val: lk.cupbordNo,    style: 'padding:11px 16px;font-size:0.875rem;color:#333;border-right:1px solid #ece8f8;' },
            { val: lk.keyNo,        style: 'padding:11px 16px;font-size:0.875rem;color:#333;' }
        ];

        cells.forEach(function(c) {
            var td = document.createElement('td');
            td.style.cssText = c.style;
            td.textContent   = c.val || '-';
            tr.appendChild(td);
        });

        fragment.appendChild(tr);
    });

    tbody.innerHTML = '';
    tbody.appendChild(fragment);
}

function filterLockerNumbers() {
    var query = document.getElementById('lockerNumberSearchInput').value.toUpperCase().trim();
    renderLockerNumberRows(!query ? _allLockerNumbers : _allLockerNumbers.filter(function(lk) {
        return String(lk.lockerNumber).toUpperCase().indexOf(query) !== -1;
    }));
}

function selectLockerNumber(lockerNumber, keyNo) {
    document.getElementById('lockerNumberSearch').value = lockerNumber;
    document.getElementById('keyNo').value              = keyNo || '';
    closeLockerNumberLookup();
}

function closeLockerNumberLookup() {
    document.getElementById('lockerNumberLookupModal').style.display = 'none';
}

document.getElementById('lockerNumberLookupModal').addEventListener('click', function(e) {
    if (e.target === this) closeLockerNumberLookup();
});


// ══════════════════════════════════════════════════════════════════════
// CUSTOMER LOOKUP
// ══════════════════════════════════════════════════════════════════════
function openCustomerLookup(triggerEl) {
    document.getElementById('issueCustomerLookupModal').style.display = 'flex';
    document.getElementById('issueCustomerLookupLoading').style.display = 'flex';
    document.getElementById('issueCustomerLookupContent').innerHTML = '';

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/lookupForCustomerId.jsp')
        .then(function(res) { return res.text(); })
        .then(function(html) {
            document.getElementById('issueCustomerLookupLoading').style.display = 'none';
            var content = document.getElementById('issueCustomerLookupContent');
            content.innerHTML = html;
            content.querySelectorAll('script').forEach(function(s) {
                var ns = document.createElement('script');
                ns.textContent = s.textContent;
                document.body.appendChild(ns);
                document.body.removeChild(ns);
            });
        });
}

function closeCustomerLookup() {
    document.getElementById('issueCustomerLookupModal').style.display = 'none';
}

window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
    document.getElementById('customerIdLookup').value    = customerId;
    document.getElementById('customerNameDisplay').value = customerName;
    closeCustomerLookup();

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/getCustomerDetails.jsp?customerId='
            + encodeURIComponent(customerId))
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (!data.success || !data.customer) return;
            var c = data.customer;
            document.getElementById('dispMobile').value    = c.mobileNo  || '';
            document.getElementById('dispAddress1').value  = c.address1  || '';
            document.getElementById('dispAddress2').value  = c.address2  || '';
            document.getElementById('dispAddress3').value  = c.address3  || '';
            document.getElementById('dispTelRes').value    = c.telRes    || '';
            document.getElementById('dispTelOffice').value = c.telOffice || '';
            document.getElementById('dispPin').value       = (c.zip && c.zip !== 0) ? String(c.zip) : '';

            var citySelect = document.getElementById('dispCity');
            if (c.city) {
                for (var i = 0; i < citySelect.options.length; i++) {
                    if (citySelect.options[i].value === c.city || citySelect.options[i].text === c.city) {
                        citySelect.selectedIndex = i; break;
                    }
                }
            }
        })
        .catch(function(err) { console.error('Failed to fetch customer details:', err); });
};

// ── Reset Form ──────────────────────────────────────────────────────
function resetLockerForm() {
    // ── Reset submission guard ──────────────────────────────────────
    _isSubmitting = false;

    document.getElementById('lockerIssueForm').reset();
    ['keyNo','customerNameDisplay','dispAddress1','dispAddress2','dispAddress3',
     'dispMobile','dispTelRes','dispTelOffice','dispPin','rentPaidTillDate'].forEach(function(id) {
        document.getElementById(id).value = '';
    });
    document.getElementById('dispCity').selectedIndex = 0;

    var btn  = document.getElementById('lockerNumberBtn');
    var hint = document.getElementById('lockerNumberHint');
    btn.disabled     = true;
    btn.title        = 'Select Locker Type first';
    hint.textContent = 'Select locker type first';
    _allLockerNumbers = [];
}
</script>
</body>
</html>
