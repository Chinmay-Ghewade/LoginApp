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
            ps = conn.prepareStatement("SELECT LOCKER_TYPE FROM HEADOFFICE.LOCKERTYPE ORDER BY LOCKER_TYPE");
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
    // AJAX: Return ISSUED locker numbers as JSON
    // ─────────────────────────────────────────────
    if ("getIssuedLockers".equals(request.getParameter("action"))) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        String sessionBranch = (String) session.getAttribute("branchCode");
        String lockerType    = request.getParameter("lockerType");
        if (sessionBranch == null) { out.print("{\"success\":false,\"message\":\"Session expired\"}"); return; }
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print("{\"success\":false,\"message\":\"DB connection failed\"}"); return; }
            String sql = "SELECT LA.LOCKER_NUMBER, LA.LOCKER_TYPE, LA.KEY_NO, " +
                         "LA.CUSTOMER_ID, LA.NAME_OF_HIRE " +
                         "FROM ACCOUNT.LOCKERACCOUNT LA " +
                         "WHERE TRIM(LA.BRANCH_CODE) = TRIM(?) " +
                         "AND LA.ACCOUNT_STATUS = 'A' ";
            if (lockerType != null && !lockerType.trim().isEmpty()) sql += " AND TRIM(LA.LOCKER_TYPE) = TRIM(?)";
            sql += " ORDER BY LA.LOCKER_NUMBER";
            ps = conn.prepareStatement(sql);
            ps.setString(1, sessionBranch.trim());
            if (lockerType != null && !lockerType.trim().isEmpty()) ps.setString(2, lockerType.trim());
            rs = ps.executeQuery();
            JSONArray arr = new JSONArray();
            while (rs.next()) {
                JSONObject o = new JSONObject();
                o.put("lockerNumber", rs.getString("LOCKER_NUMBER") != null ? rs.getString("LOCKER_NUMBER") : "");
                o.put("lockerType",   rs.getString("LOCKER_TYPE")   != null ? rs.getString("LOCKER_TYPE").trim() : "");
                o.put("keyNo",        rs.getString("KEY_NO")        != null ? rs.getString("KEY_NO") : "");
                o.put("customerId",   rs.getString("CUSTOMER_ID")   != null ? rs.getString("CUSTOMER_ID") : "");
                o.put("nameOfHire",   rs.getString("NAME_OF_HIRE")  != null ? rs.getString("NAME_OF_HIRE") : "");
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
    // AJAX: Load full locker details for surrender
    // ─────────────────────────────────────────────
    if ("getLockerDetails".equals(request.getParameter("action"))) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        String sessionBranch  = (String) session.getAttribute("branchCode");
        java.sql.Date workingDate = (java.sql.Date) session.getAttribute("workingDate");
        String lockerType     = request.getParameter("lockerType");
        String lockerNumberStr= request.getParameter("lockerNumber");
        if (sessionBranch == null) { out.print("{\"success\":false,\"message\":\"Session expired\"}"); return; }
        if (workingDate   == null) { out.print("{\"success\":false,\"message\":\"Working date not in session\"}"); return; }
        Connection conn = null;
        PreparedStatement ps = null, psRent = null, psScroll = null;
        ResultSet rs = null, rsRent = null, rsScroll = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print("{\"success\":false,\"message\":\"DB connection failed\"}"); return; }

            ps = conn.prepareStatement(
                "SELECT LA.CUSTOMER_ID, LA.NAME_OF_HIRE, " +
                "  TO_CHAR(LA.DATE_OF_HIRE,        'YYYY-MM-DD') AS DATE_OF_HIRE, " +
                "  TO_CHAR(LA.RENT_PAID_TILL_DATE, 'YYYY-MM-DD') AS RENT_PAID_TILL_DATE, " +
                "  Fn_Get_Account_name(LA.CUSTOMER_ID) AS CUSTOMER_NAME " +
                "FROM ACCOUNT.LOCKERACCOUNT LA " +
                "WHERE TRIM(LA.BRANCH_CODE) = TRIM(?) " +
                "AND   TRIM(LA.LOCKER_TYPE) = TRIM(?) " +
                "AND   LA.LOCKER_NUMBER     = ? " +
                "AND   LA.ACCOUNT_STATUS    = 'A' " +
                "AND   ROWNUM = 1"
            );
            ps.setString(1, sessionBranch.trim());
            ps.setString(2, lockerType.trim());
            ps.setInt   (3, Integer.parseInt(lockerNumberStr.trim()));
            rs = ps.executeQuery();
            if (!rs.next()) {
                out.print("{\"success\":false,\"message\":\"Locker not found or not active\"}"); return;
            }
            String customerId      = rs.getString("CUSTOMER_ID")         != null ? rs.getString("CUSTOMER_ID")         : "";
            String nameOfHire      = rs.getString("NAME_OF_HIRE")        != null ? rs.getString("NAME_OF_HIRE")        : "";
            String dateOfHireStr   = rs.getString("DATE_OF_HIRE")        != null ? rs.getString("DATE_OF_HIRE")        : "";
            String rentPaidTillStr = rs.getString("RENT_PAID_TILL_DATE") != null ? rs.getString("RENT_PAID_TILL_DATE") : "";
            String customerName    = rs.getString("CUSTOMER_NAME")       != null ? rs.getString("CUSTOMER_NAME")       : "";
            rs.close(); rs = null; ps.close(); ps = null;

            double rent = 0; int period = 12;
            psRent = conn.prepareStatement(
                "SELECT RENT, PERIOD_IN_MONTHS FROM BRANCH.BRANCHLOCKER_RENTS " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) AND TRIM(LOCKER_TYPE) = TRIM(?) AND ROWNUM = 1"
            );
            psRent.setString(1, sessionBranch.trim());
            psRent.setString(2, lockerType.trim());
            rsRent = psRent.executeQuery();
            if (rsRent.next()) { rent = rsRent.getDouble("RENT"); period = rsRent.getInt("PERIOD_IN_MONTHS"); }
            rsRent.close(); rsRent = null; psRent.close(); psRent = null;

            String scrollNumber = "";
            psScroll = conn.prepareStatement(
                "SELECT TO_CHAR(SCROLL_NUMBER) AS SCROLL_NUMBER FROM TRANSACTION.LOCKERTRANSACTION " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) AND TRIM(LOCKER_TYPE) = TRIM(?) " +
                "AND LOCKER_NUMBER = ? AND ROWNUM = 1"
            );
            psScroll.setString(1, sessionBranch.trim());
            psScroll.setString(2, lockerType.trim());
            psScroll.setInt   (3, Integer.parseInt(lockerNumberStr.trim()));
            rsScroll = psScroll.executeQuery();
            if (rsScroll.next()) scrollNumber = rsScroll.getString("SCROLL_NUMBER") != null ? rsScroll.getString("SCROLL_NUMBER") : "";
            rsScroll.close(); rsScroll = null; psScroll.close(); psScroll = null;

            double completedMonths = 0, rentPerMonth = 0, rentDue = 0;
            String rentToDateStr = "";
            if (!dateOfHireStr.isEmpty()) {
                java.sql.Date dateOfHire = java.sql.Date.valueOf(dateOfHireStr);
                java.util.Calendar calH = java.util.Calendar.getInstance(); calH.setTime(dateOfHire);
                java.util.Calendar calW = java.util.Calendar.getInstance(); calW.setTime(workingDate);
                int diff = (calW.get(java.util.Calendar.YEAR) - calH.get(java.util.Calendar.YEAR)) * 12
                         + (calW.get(java.util.Calendar.MONTH) - calH.get(java.util.Calendar.MONTH));
                completedMonths = diff < 0 ? 0 : diff;
                rentPerMonth    = period > 0 ? (rent / period) : 0;
                rentDue         = completedMonths * rentPerMonth;
                java.util.Calendar calT = java.util.Calendar.getInstance(); calT.setTime(dateOfHire);
                calT.add(java.util.Calendar.MONTH, period);
                rentToDateStr = new java.sql.Date(calT.getTimeInMillis()).toString();
            }

            JSONObject result = new JSONObject();
            result.put("success",               true);
            result.put("found",                 true);
            result.put("scrollNumber",          scrollNumber);
            result.put("customerId",            customerId);
            result.put("nameOfHire",            nameOfHire);
            result.put("customerName",          customerName);
            result.put("hireDate",              dateOfHireStr);
            result.put("period",                period);
            result.put("reviewDate",            rentPaidTillStr);
            result.put("rentFromDate",          dateOfHireStr);
            result.put("rentToDate",            rentToDateStr);
            result.put("completedPeriodMonths", (int) completedMonths);
            result.put("lockerRentPerMonth",    String.format("%.2f", rentPerMonth));
            result.put("lockerRentDue",         String.format("%.2f", rentDue));
            result.put("amount",                String.format("%.2f", rentDue));
            result.put("workingDate",           workingDate.toString());
            out.print(result.toString());

        } catch (Exception e) {
            out.print("{\"success\":false,\"message\":\"" + e.getMessage().replace("\"","\\\"").replace("\n"," ") + "\"}");
        } finally {
            try { if (rs!=null)       rs.close();       } catch(Exception i){}
            try { if (ps!=null)       ps.close();       } catch(Exception i){}
            try { if (rsRent!=null)   rsRent.close();   } catch(Exception i){}
            try { if (psRent!=null)   psRent.close();   } catch(Exception i){}
            try { if (rsScroll!=null) rsScroll.close(); } catch(Exception i){}
            try { if (psScroll!=null) psScroll.close(); } catch(Exception i){}
            try { if (conn!=null)     conn.close();     } catch(Exception i){}
        }
        return;
    }

    // ─────────────────────────────────────────────
    // AJAX: Account lookup from ACCOUNT.ACCOUNT
    // ─────────────────────────────────────────────
    if ("getAccounts".equals(request.getParameter("action"))) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        String sessionBranch = (String) session.getAttribute("branchCode");
        String searchQuery   = request.getParameter("search");
        if (sessionBranch == null) { out.print("{\"success\":false,\"message\":\"Session expired\"}"); return; }
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print("{\"success\":false,\"message\":\"DB connection failed\"}"); return; }
            String sql = "SELECT ACCOUNT_CODE, Fn_Get_Account_name(ACCOUNT_CODE) AS ACCOUNT_NAME " +
                         "FROM ACCOUNT.ACCOUNT WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ? ";
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                sql += "AND (UPPER(ACCOUNT_CODE) LIKE UPPER(?) OR UPPER(Fn_Get_Account_name(ACCOUNT_CODE)) LIKE UPPER(?)) ";
            }
            sql += "AND ROWNUM <= 50 ORDER BY ACCOUNT_CODE";
            ps = conn.prepareStatement(sql);
            ps.setString(1, sessionBranch.trim());
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                String q = "%" + searchQuery.trim() + "%";
                ps.setString(2, q); ps.setString(3, q);
            }
            rs = ps.executeQuery();
            JSONArray arr = new JSONArray();
            while (rs.next()) {
                JSONObject o = new JSONObject();
                o.put("accountCode", rs.getString("ACCOUNT_CODE") != null ? rs.getString("ACCOUNT_CODE") : "");
                o.put("accountName", rs.getString("ACCOUNT_NAME") != null ? rs.getString("ACCOUNT_NAME") : "");
                arr.put(o);
            }
            JSONObject result = new JSONObject();
            result.put("success", true); result.put("accounts", arr);
            out.print(result.toString());
        } catch (Exception e) {
            out.print("{\"success\":false,\"message\":\"" + e.getMessage().replace("\"","\\\"").replace("\n"," ") + "\"}");
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
    if (branchCode == null) { response.sendRedirect("../login.jsp"); return; }

    java.sql.Date workingDate = (java.sql.Date) session.getAttribute("workingDate");
    String workingDateStr = workingDate != null ? workingDate.toString() : new java.sql.Date(System.currentTimeMillis()).toString();
    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Locker Surrender</title>
  <link rel="stylesheet" href="../css/locker.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <link rel="stylesheet" href="../css/lookup-modal.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
  <style>
    .form-buttons { display: flex !important; }
    .input-icon-box { position: relative; width: 90%; }
    .input-icon-box input { width: 100%; padding-right: 40px; height: 30px; cursor: pointer; box-sizing: border-box; }
    .input-icon-box .inside-icon-btn { position: absolute; right: 5px; top: 50%; transform: translateY(-50%); background: none; border: none; font-size: 16px; cursor: pointer; color: #373279; }
    .icon-btn:disabled { background-color: #aaa !important; cursor: not-allowed !important; opacity: 0.6; }
    #checkAvailabilityBtn { background-color: #373279; color: white; border: none; padding: 10px 25px; border-radius: 6px; font-size: 14px; font-weight: bold; cursor: pointer; transition: background-color 0.3s ease, transform 0.2s ease; }
    #checkAvailabilityBtn:hover  { background-color: #2b0d73; transform: scale(1.05); }
    #checkAvailabilityBtn:active { transform: scale(0.97); }
    .txn-mode-row { display: flex; align-items: center; gap: 20px; }
    .txn-mode-row .radio-group { flex-direction: row; }
    form { padding: 0 20px; }
    .simple-lookup-item { padding: 13px 20px; cursor: pointer; font-size: 14px; font-weight: 600; color: #373279; border-bottom: 1px solid #ece8f8; border-left: 3px solid transparent; transition: all 0.15s ease; display: flex; align-items: center; justify-content: space-between; }
    .simple-lookup-item:hover { background: #f0eefb; border-left-color: #373279; }

    /* ══════════════════════════════════════════
       CONFIRMATION POPUP STYLES
    ══════════════════════════════════════════ */
    @keyframes toastSlideIn {
      from { opacity: 0; transform: translateX(-50%) translateY(-12px); }
      to   { opacity: 1; transform: translateX(-50%) translateY(0); }
    }
    @keyframes popIn {
      from { transform: scale(0.80); opacity: 0; }
      to   { transform: scale(1);    opacity: 1; }
    }
    #surrenderSuccessModal {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(20, 18, 60, 0.45);
      z-index: 9999;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(2px);
    }
    #surrenderSuccessModal .popup-card {
      background: #ffffff;
      border-radius: 16px;
      width: 420px;
      padding: 38px 36px 30px 36px;
      text-align: center;
      box-shadow: 0 12px 48px rgba(55, 50, 121, 0.22);
      font-family: Arial, sans-serif;
      animation: popIn 0.28s cubic-bezier(0.34, 1.56, 0.64, 1);
    }
    /* Green check icon */
    #surrenderSuccessModal .check-icon {
      font-size: 52px;
      color: #22c55e;
      margin-bottom: 10px;
      line-height: 1;
    }
    #surrenderSuccessModal .popup-title {
      font-size: 1.35rem;
      font-weight: 800;
      color: #1a1a2e;
      margin-bottom: 6px;
    }
    #surrenderSuccessModal .popup-subtitle {
      font-size: 0.92rem;
      color: #555;
      margin-bottom: 22px;
    }
    #surrenderSuccessModal .popup-subtitle strong {
      color: #1a1a2e;
    }
    /* Details table */
    #surrenderSuccessModal .popup-details {
      background: #f6f7f9;
      border-radius: 10px;
      padding: 4px 0;
      margin-bottom: 28px;
      text-align: left;
      border: 1px solid #e8e8ee;
    }
    #surrenderSuccessModal .detail-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 0.9rem;
      padding: 11px 18px;
    }
    #surrenderSuccessModal .detail-row + .detail-row {
      border-top: 1px solid #e8e8ee;
    }
    #surrenderSuccessModal .detail-label {
      color: #444;
      font-weight: 400;
    }
    #surrenderSuccessModal .detail-value {
      font-weight: 700;
      color: #373279;
      font-size: 0.92rem;
    }
    /* Buttons */
    #surrenderSuccessModal .popup-btn-row {
      display: flex;
      gap: 16px;
      justify-content: center;
    }
    #surrenderSuccessModal .btn-cancel {
      background: #e0e0e0;
      color: #333;
      border: none;
      border-radius: 8px;
      padding: 13px 0;
      width: 150px;
      font-size: 0.97rem;
      font-weight: 700;
      cursor: pointer;
      transition: background 0.2s, transform 0.15s;
    }
    #surrenderSuccessModal .btn-cancel:hover  { background: #cccccc; transform: translateY(-1px); }
    #surrenderSuccessModal .btn-cancel:active { transform: translateY(1px); }
    #surrenderSuccessModal .btn-ok {
      background: #22c55e;
      color: #fff;
      border: none;
      border-radius: 8px;
      padding: 13px 0;
      width: 150px;
      font-size: 0.97rem;
      font-weight: 700;
      cursor: pointer;
      transition: background 0.2s, transform 0.15s;
      box-shadow: 0 4px 14px rgba(34, 197, 94, 0.30);
    }
    #surrenderSuccessModal .btn-ok:hover  { background: #16a34a; transform: translateY(-1px); }
    #surrenderSuccessModal .btn-ok:active { transform: translateY(1px); }
  </style>
</head>
<body>

<form id="surrenderForm" onsubmit="submitSurrenderForm(event)">

  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 1: LOCKER TYPE DETAILS                   -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Type Details</legend>
    <div class="form-grid">
      <div>
        <label>Locker Type</label>
        <div class="input-icon-box">
          <input type="text" name="lockerTypeSearch" id="lockerTypeSearch" oninput="this.value = this.value.toUpperCase();" readonly>
          <button type="button" class="inside-icon-btn" onclick="openLockerTypeLookup()" title="Search Locker Type">🔍</button>
        </div>
      </div>
      <div>
        <label>Locker Number</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="lockerNumberSearch" id="lockerNumberSearch" class="form-input" readonly>
          <button type="button" id="lockerNumberBtn" class="icon-btn" onclick="openLockerNumberLookup()" disabled
                  title="Select Locker Type first"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px; border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
        <small id="lockerNumberHint" style="font-size:11px;color:#888;margin-top:2px;display:block;">Select locker type first</small>
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: SURRENDER DETAILS                     -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Surrender Details</legend>
    <div class="form-grid">
      <div><label>Scroll Number</label><input type="text" name="scrollNumber" id="scrollNumber" readonly></div>
      <div><label>Name of Hire</label><input type="text" name="nameOfHire" id="nameOfHire" readonly></div>
      <div><label>Customer Id</label><input type="text" name="customerId" id="customerId" readonly></div>
      <div><label>Name</label><input type="text" name="customerName" id="customerName" readonly></div>
      <div><label>Hire Date</label><input type="text" name="hireDate" id="hireDate" readonly></div>
      <div><label>Period</label><input type="text" name="period" id="period" value="12" readonly></div>
      <div><label>Review Date</label><input type="text" name="reviewDate" id="reviewDate" readonly></div>
      <div><label>Rent From Date</label><input type="text" name="rentFromDate" id="rentFromDate" readonly></div>
      <div><label>Rent To Date</label><input type="text" name="rentToDate" id="rentToDate" readonly></div>
      <div><label>Completed Period In Months</label><input type="text" name="completedPeriodMonths" id="completedPeriodMonths" readonly></div>
      <div><label>Locker Rent/month</label><input type="text" name="lockerRentPerMonth" id="lockerRentPerMonth" readonly></div>
      <div><label>Locker Rent Due</label><input type="text" name="lockerRentDue" id="lockerRentDue" readonly></div>
      <div><label>Amount</label><input type="text" name="amount" id="amount" value="0" oninput="this.value = this.value.replace(/[^0-9.]/g, '');"></div>
      <div><label>Transaction Date</label><input type="text" name="transactionDate" id="transactionDate" readonly></div>
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
          <label><input type="radio" name="transactionMode" value="CASH" checked onchange="toggleDebitSection(this)"> Cash</label>
          <label><input type="radio" name="transactionMode" value="TRANSFER" onchange="toggleDebitSection(this)"> Transfer</label>
        </div>
      </div>
      <div id="debitACSection" style="display:none;">
        <label>Debit A/C Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <button type="button"
                  style="background-color:#2D2B80; color:white; border:none; width:28px; height:28px; border-radius:5px; font-size:14px; cursor:pointer;"
                  onclick="openDebitACLookup()">…</button>
          <input type="text" name="debitACCode" id="debitACCode" class="form-input"
                 oninput="this.value = this.value.replace(/[^A-Za-z0-9]/g,'').toUpperCase();">
        </div>
      </div>
      <div id="debitACNameSection" style="display:none;">
        <label>Name</label>
        <input type="text" name="debitACName" id="debitACName" readonly>
      </div>
    </div>
  </fieldset>

  <div class="form-buttons">
    <button type="submit">Surrender Locker</button>
    <button type="button" onclick="resetSurrenderForm()">Reset</button>
  </div>

</form>


<!-- ════════════════════════════════════════════════════════════════ -->
<!-- CONFIRMATION POPUP MODAL                                       -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="surrenderSuccessModal">
  <div class="popup-card">

    <!-- Green checkmark -->
    <div class="check-icon">&#10003;</div>

    <div class="popup-title">Confirm Locker Surrender?</div>
    <div class="popup-subtitle">Are you sure you want to <strong>surrender</strong> this locker?</div>

    <!-- Detail rows: Locker Type / Locker No. -->
    <div class="popup-details">
      <div class="detail-row">
        <span class="detail-label">Locker Type</span>
        <span class="detail-value" id="successLockerType">—</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">Locker Number</span>
        <span class="detail-value" id="successLockerNumber">—</span>
      </div>
    </div>

    <!-- Cancel → closes popup, form stays | OK → calls servlet -->
    <div class="popup-btn-row">
      <button class="btn-cancel" onclick="closeSurrenderSuccessModal(false)">Cancel</button>
      <button class="btn-ok"     onclick="closeSurrenderSuccessModal(true)">Yes, Surrender</button>
    </div>

  </div>
</div>


<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOCKER TYPE LOOKUP MODAL                                       -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lockerTypeLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:35%; max-width:380px; max-height:70vh; overflow:hidden; display:flex; flex-direction:column; box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">
        <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73); border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:17px;">🔒</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;">Select Locker Type</span>
            </div>
            <span onclick="closeLockerTypeLookup()" style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;" onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>
        <div style="padding:12px 18px 8px 18px; background:#f4f2fc; border-bottom:1px solid #e0daf5;">
            <input type="text" id="lockerTypeSearchInput" placeholder="Search locker type..." oninput="filterLockerTypes()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;border-radius:6px;font-size:0.875rem;box-sizing:border-box;outline:none;font-family:Arial,sans-serif;color:#333;">
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
    <div style="background:#fff; border-radius:14px; width:60%; max-width:680px; max-height:72vh; overflow:hidden; display:flex; flex-direction:column; box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">
        <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73); border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:17px;">🗄️</div>
                <div>
                    <div style="font-size:1.05rem;font-weight:700;color:#fff;">Issued Lockers</div>
                    <div id="lockerNumberModalSubtitle" style="font-size:0.78rem;color:rgba(255,255,255,0.7);margin-top:1px;"></div>
                </div>
            </div>
            <span onclick="closeLockerNumberLookup()" style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;" onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>
        <div style="padding:12px 18px 8px 18px; background:#f4f2fc; border-bottom:1px solid #e0daf5;">
            <input type="text" id="lockerNumberSearchInput" placeholder="Search locker number or customer..." oninput="filterLockerNumbers()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;border-radius:6px;font-size:0.875rem;box-sizing:border-box;outline:none;font-family:Arial,sans-serif;color:#333;">
        </div>
        <div style="font-size:0.75rem;color:#888;text-align:right;padding:5px 18px;border-bottom:1px solid #ece8f8;">
            Issued: <strong id="lockerNumberCount" style="color:#373279;">0</strong>
        </div>
        <div style="flex:1;overflow-y:auto;overflow-x:auto;min-height:0;">
            <table style="width:100%;border-collapse:collapse;font-family:Arial,sans-serif;">
                <thead>
                    <tr style="background:linear-gradient(90deg,#373279,#5a3ec8);position:sticky;top:0;z-index:2;">
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Locker No.</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Type</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Customer ID</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;">Name of Hire</th>
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
<!-- DEBIT ACCOUNT LOOKUP MODAL                                     -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="debitACLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:60%; max-width:700px; max-height:72vh; overflow:hidden; display:flex; flex-direction:column; box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">
        <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73); border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:17px;">🏦</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;">Select Debit Account</span>
            </div>
            <span onclick="closeDebitACLookup()" style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;" onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>
        <div style="padding:12px 18px 8px 18px; background:#f4f2fc; border-bottom:1px solid #e0daf5;">
            <input type="text" id="debitACSearchInput" placeholder="Search by account code or name..." oninput="searchDebitAccounts()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;border-radius:6px;font-size:0.875rem;box-sizing:border-box;outline:none;font-family:Arial,sans-serif;color:#333;">
        </div>
        <div style="font-size:0.75rem;color:#888;text-align:right;padding:5px 18px;border-bottom:1px solid #ece8f8;">
            Found: <strong id="debitACCount" style="color:#373279;">0</strong>
        </div>
        <div style="flex:1;overflow-y:auto;overflow-x:auto;min-height:0;">
            <table style="width:100%;border-collapse:collapse;font-family:Arial,sans-serif;">
                <thead>
                    <tr style="background:linear-gradient(90deg,#373279,#5a3ec8);position:sticky;top:0;z-index:2;">
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Account Code</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;">Account Name</th>
                    </tr>
                </thead>
                <tbody id="debitACTableBody">
                    <tr><td colspan="2" style="text-align:center;padding:24px;color:#888;">Type to search accounts...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>


<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';
var _allLockerTypes = [], _allLockerNumbers = [];

// Set working date from session on load
window.onload = function() {
    document.getElementById('transactionDate').value = '<%= workingDateStr %>';
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath ? window.buildBreadcrumbPath('Lockers/lockerSurrender.jsp') : 'Locker Surrender'
        );
    }
};

// ══════════════════════════════════════════════════════════════
// LOCKER TYPE LOOKUP
// ══════════════════════════════════════════════════════════════
function openLockerTypeLookup() {
    document.getElementById('lockerTypeLookupModal').style.display = 'flex';
    document.getElementById('lockerTypeSearchInput').value = '';
    if (_allLockerTypes.length > 0) { renderLockerTypeList(_allLockerTypes); return; }
    document.getElementById('lockerTypeList').innerHTML = '<div style="text-align:center;padding:24px;color:#888;">Loading...</div>';
    fetch('lockerSurrender.jsp?action=getLockerTypes')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success && data.lockerTypes) { _allLockerTypes = data.lockerTypes; renderLockerTypeList(_allLockerTypes); }
            else document.getElementById('lockerTypeList').innerHTML = '<div style="text-align:center;padding:24px;color:red;">' + (data.message || 'Failed.') + '</div>';
        }).catch(function(err) { document.getElementById('lockerTypeList').innerHTML = '<div style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</div>'; });
}
function renderLockerTypeList(items) {
    document.getElementById('lockerTypeCount').textContent = items.length;
    if (!items.length) { document.getElementById('lockerTypeList').innerHTML = '<div style="text-align:center;padding:24px;color:#888;">No locker types found.</div>'; return; }
    var html = '';
    items.forEach(function(lt) { html += '<div class="simple-lookup-item" onclick="selectLockerType(\'' + lt.lockerType + '\')"><span>' + lt.lockerType + '</span></div>'; });
    document.getElementById('lockerTypeList').innerHTML = html;
}
function filterLockerTypes() {
    var q = document.getElementById('lockerTypeSearchInput').value.toUpperCase().trim();
    renderLockerTypeList(!q ? _allLockerTypes : _allLockerTypes.filter(function(lt) { return lt.lockerType.toUpperCase().indexOf(q) !== -1; }));
}
function selectLockerType(lockerType) {
    document.getElementById('lockerTypeSearch').value = lockerType;
    closeLockerTypeLookup();
    var btn = document.getElementById('lockerNumberBtn');
    btn.disabled = false; btn.title = 'Search issued lockers';
    document.getElementById('lockerNumberHint').textContent = '';
    document.getElementById('lockerNumberSearch').value = '';
    _allLockerNumbers = [];
}
function closeLockerTypeLookup() { document.getElementById('lockerTypeLookupModal').style.display = 'none'; }
document.getElementById('lockerTypeLookupModal').addEventListener('click', function(e) { if (e.target === this) closeLockerTypeLookup(); });

// ══════════════════════════════════════════════════════════════
// LOCKER NUMBER LOOKUP
// ══════════════════════════════════════════════════════════════
function openLockerNumberLookup() {
    var lockerType = document.getElementById('lockerTypeSearch').value.trim();
    if (!lockerType) { showToast('Please select a Locker Type first.', true); return; }
    document.getElementById('lockerNumberLookupModal').style.display = 'flex';
    document.getElementById('lockerNumberSearchInput').value = '';
    document.getElementById('lockerNumberModalSubtitle').textContent = 'Type: ' + lockerType + '  •  Issued lockers only';
    if (_allLockerNumbers.length > 0) { renderLockerNumberRows(_allLockerNumbers); return; }
    document.getElementById('lockerNumberTableBody').innerHTML = '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>';
    fetch('lockerSurrender.jsp?action=getIssuedLockers&lockerType=' + encodeURIComponent(lockerType))
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success) { _allLockerNumbers = data.lockers || []; renderLockerNumberRows(_allLockerNumbers); }
            else document.getElementById('lockerNumberTableBody').innerHTML = '<tr><td colspan="4" style="text-align:center;padding:24px;color:red;">' + (data.message || 'Failed.') + '</td></tr>';
        }).catch(function(err) { document.getElementById('lockerNumberTableBody').innerHTML = '<tr><td colspan="4" style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</td></tr>'; });
}
function renderLockerNumberRows(items) {
    var tbody = document.getElementById('lockerNumberTableBody');
    document.getElementById('lockerNumberCount').textContent = items.length;
    if (!items.length) { tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">No issued lockers found.</td></tr>'; return; }
    var fragment = document.createDocumentFragment();
    items.forEach(function(lk) {
        var tr = document.createElement('tr');
        tr.style.cssText = 'border-bottom:1px solid #ece8f8;cursor:pointer;border-left:3px solid transparent;transition:all 0.15s ease;';
        tr.addEventListener('mouseover', function() { this.style.background='#f0eefb'; this.style.borderLeftColor='#373279'; });
        tr.addEventListener('mouseout',  function() { this.style.background=''; this.style.borderLeftColor='transparent'; });
        tr.addEventListener('click',     function() { selectLockerNumber(lk.lockerNumber, lk.customerId, lk.nameOfHire); });
        [{ val: lk.lockerNumber, style: 'padding:11px 16px;font-weight:700;color:#373279;font-size:0.9rem;border-right:1px solid #ece8f8;' },
         { val: lk.lockerType,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;border-right:1px solid #ece8f8;' },
         { val: lk.customerId,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;border-right:1px solid #ece8f8;' },
         { val: lk.nameOfHire,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;' }
        ].forEach(function(c) { var td = document.createElement('td'); td.style.cssText = c.style; td.textContent = c.val || '-'; tr.appendChild(td); });
        fragment.appendChild(tr);
    });
    tbody.innerHTML = ''; tbody.appendChild(fragment);
}
function filterLockerNumbers() {
    var q = document.getElementById('lockerNumberSearchInput').value.toUpperCase().trim();
    renderLockerNumberRows(!q ? _allLockerNumbers : _allLockerNumbers.filter(function(lk) {
        return String(lk.lockerNumber).toUpperCase().indexOf(q) !== -1 || String(lk.nameOfHire).toUpperCase().indexOf(q) !== -1 || String(lk.customerId).toUpperCase().indexOf(q) !== -1;
    }));
}
function selectLockerNumber(lockerNumber, customerId, nameOfHire) {
    document.getElementById('lockerNumberSearch').value = lockerNumber;
    document.getElementById('customerId').value  = customerId  || '';
    document.getElementById('nameOfHire').value  = nameOfHire  || '';
    closeLockerNumberLookup();
    loadLockerDetails(); // auto-fetch details immediately
}
function closeLockerNumberLookup() { document.getElementById('lockerNumberLookupModal').style.display = 'none'; }
document.getElementById('lockerNumberLookupModal').addEventListener('click', function(e) { if (e.target === this) closeLockerNumberLookup(); });

// ══════════════════════════════════════════════════════════════
// DEBIT ACCOUNT LOOKUP
// ══════════════════════════════════════════════════════════════
function openDebitACLookup() {
    document.getElementById('debitACLookupModal').style.display = 'flex';
    document.getElementById('debitACSearchInput').value = '';
    document.getElementById('debitACCount').textContent = '0';
    // Load first 50 accounts immediately on open
    document.getElementById('debitACTableBody').innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>';
    fetch('lockerSurrender.jsp?action=getAccounts&search=')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success) renderDebitACRows(data.accounts || []);
            else document.getElementById('debitACTableBody').innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:red;">' + (data.message || 'Failed.') + '</td></tr>';
        }).catch(function(err) {
            document.getElementById('debitACTableBody').innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</td></tr>';
        });
}
function searchDebitAccounts() {
    var query = document.getElementById('debitACSearchInput').value.trim();
    document.getElementById('debitACTableBody').innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:#888;">Searching...</td></tr>';
    fetch('lockerSurrender.jsp?action=getAccounts&search=' + encodeURIComponent(query))
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success) renderDebitACRows(data.accounts || []);
            else document.getElementById('debitACTableBody').innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:red;">' + (data.message || 'Failed.') + '</td></tr>';
        }).catch(function(err) {
            document.getElementById('debitACTableBody').innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</td></tr>';
        });
}
function renderDebitACRows(items) {
    var tbody = document.getElementById('debitACTableBody');
    document.getElementById('debitACCount').textContent = items.length;
    if (!items.length) { tbody.innerHTML = '<tr><td colspan="2" style="text-align:center;padding:24px;color:#888;">No accounts found.</td></tr>'; return; }
    var fragment = document.createDocumentFragment();
    items.forEach(function(ac) {
        var tr = document.createElement('tr');
        tr.style.cssText = 'border-bottom:1px solid #ece8f8;cursor:pointer;border-left:3px solid transparent;transition:all 0.15s ease;';
        tr.addEventListener('mouseover', function() { this.style.background='#f0eefb'; this.style.borderLeftColor='#373279'; });
        tr.addEventListener('mouseout',  function() { this.style.background=''; this.style.borderLeftColor='transparent'; });
        tr.addEventListener('click',     function() { selectDebitAC(ac.accountCode, ac.accountName); });
        [{ val: ac.accountCode, style: 'padding:11px 16px;font-weight:700;color:#373279;font-size:0.9rem;border-right:1px solid #ece8f8;' },
         { val: ac.accountName, style: 'padding:11px 16px;font-size:0.875rem;color:#333;' }
        ].forEach(function(c) { var td = document.createElement('td'); td.style.cssText = c.style; td.textContent = c.val || '-'; tr.appendChild(td); });
        fragment.appendChild(tr);
    });
    tbody.innerHTML = ''; tbody.appendChild(fragment);
}
function selectDebitAC(accountCode, accountName) {
    document.getElementById('debitACCode').value = accountCode || '';
    document.getElementById('debitACName').value = accountName || '';
    closeDebitACLookup();
}
function closeDebitACLookup() { document.getElementById('debitACLookupModal').style.display = 'none'; }
document.getElementById('debitACLookupModal').addEventListener('click', function(e) { if (e.target === this) closeDebitACLookup(); });

// ══════════════════════════════════════════════════════════════
// LOAD LOCKER DETAILS — Check Availability
// ══════════════════════════════════════════════════════════════
function loadLockerDetails() {
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerType || !lockerNumber) { showToast('Please select Locker Type and Locker Number first.', true); return; }

    fetch('lockerSurrender.jsp?action=getLockerDetails&lockerType=' + encodeURIComponent(lockerType) + '&lockerNumber=' + encodeURIComponent(lockerNumber))
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data.success && data.found) {
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
            document.getElementById('transactionDate').value       = data.workingDate           || '';
            showToast('Locker details loaded successfully.', false);
        } else {
            showToast(data.message || 'Locker not found or not active.', true);
        }
    }).catch(function(err) { showToast('Error: ' + err.message, true); });
}

// ── Toggle debit section ────────────────────────────────────────────
function toggleDebitSection(radio) {
    var isTransfer = (radio.value === 'TRANSFER');
    document.getElementById('debitACSection').style.display     = isTransfer ? '' : 'none';
    document.getElementById('debitACNameSection').style.display = isTransfer ? '' : 'none';
    if (!isTransfer) {
        document.getElementById('debitACCode').value    = '';
        document.getElementById('debitACName').value    = '';
        document.getElementById('transferStatus').value = '';
    }
}


// ── Toast ───────────────────────────────────────────────────────────
function showToast(msg, isError) {
    var existing = document.getElementById('customToast');
    if (existing) existing.remove();

    var toast = document.createElement('div');
    toast.id = 'customToast';
    toast.style.cssText = [
        'position:fixed',
        'top:22px',
        'left:50%',
        'transform:translateX(-50%)',
        'z-index:99999',
        'background:#ffffff',
        'color:#1a1a2e',
        'font-family:Arial,sans-serif',
        'font-size:14px',
        'padding:14px 18px',
        'border-radius:8px',
        'box-shadow:0 4px 24px rgba(45,43,128,0.18)',
        'display:flex',
        'align-items:center',
        'gap:12px',
        'min-width:320px',
        'max-width:540px',
        'border:1px solid #e0daf5',
        'border-left:4px solid ' + (isError ? '#e53935' : '#2D2B80'),
        'animation:toastSlideIn 0.22s ease'
    ].join(';');

    // Info / Error icon circle
    var icon = document.createElement('span');
    icon.style.cssText = [
        'width:26px',
        'height:26px',
        'border-radius:50%',
        'background:' + (isError ? '#e53935' : '#2D2B80'),
        'color:#fff',
        'display:flex',
        'align-items:center',
        'justify-content:center',
        'font-size:13px',
        'font-weight:700',
        'font-style:italic',
        'flex-shrink:0'
    ].join(';');
    icon.textContent = 'i';

    // Message text
    var text = document.createElement('span');
    text.style.cssText = 'flex:1;line-height:1.45;color:#1a1a2e;font-size:13.5px;';
    text.textContent = msg;

    // Close ×
    var close = document.createElement('span');
    close.textContent = '×';
    close.style.cssText = 'font-size:20px;cursor:pointer;color:#aaa;flex-shrink:0;line-height:1;padding:0 2px;';
    close.onmouseover = function() { this.style.color = '#555'; };
    close.onmouseout  = function() { this.style.color = '#aaa'; };
    close.onclick     = function() { toast.remove(); };

    toast.appendChild(icon);
    toast.appendChild(text);
    toast.appendChild(close);
    document.body.appendChild(toast);

    setTimeout(function() { if (toast.parentNode) toast.remove(); }, 3500);
}

// ── Reset ───────────────────────────────────────────────────────────
function resetSurrenderForm() {
    document.querySelector('form').reset();
    document.getElementById('transactionDate').value = '<%= workingDateStr %>';
    ['scrollNumber','nameOfHire','customerId','customerName','hireDate','reviewDate',
     'rentFromDate','rentToDate','completedPeriodMonths','lockerRentPerMonth',
     'lockerRentDue','debitACName','transferStatus'].forEach(function(id) {
        var el = document.getElementById(id); if (el) el.value = '';
    });
    document.getElementById('period').value = '12';
    document.getElementById('amount').value = '0';
    document.getElementById('lockerNumberBtn').disabled = true;
    document.getElementById('lockerNumberBtn').title    = 'Select Locker Type first';
    document.getElementById('lockerNumberHint').textContent = 'Select locker type first';
    _allLockerNumbers = [];
    document.getElementById('debitACSection').style.display     = 'none';
    document.getElementById('debitACNameSection').style.display = 'none';
}

// ── Validation ──────────────────────────────────────────────────────
function validateSurrenderForm() {
    if (!document.getElementById('lockerTypeSearch').value.trim())   { showToast('Please select a Locker Type.', true); return false; }
    if (!document.getElementById('lockerNumberSearch').value.trim()) { showToast('Please select a Locker Number.', true); return false; }
    if (!document.getElementById('customerId').value.trim())         { showToast('Please load locker details first.', true); return false; }
    var amount = parseFloat(document.getElementById('amount').value);
    if (isNaN(amount) || amount < 0) { showToast('Please enter a valid Amount.', true); return false; }
    var mode = document.querySelector('input[name="transactionMode"]:checked').value;
    if (mode === 'TRANSFER' && !document.getElementById('debitACCode').value.trim()) {
        showToast('Please select a Debit Account for Transfer mode.', true); return false;
    }
    return true;
}

// ══════════════════════════════════════════════════════════════
// STEP 1: Surrender Locker button clicked
// → validate form, then show confirmation popup only
// → servlet is NOT called here
// ══════════════════════════════════════════════════════════════
function submitSurrenderForm(e) {
    e.preventDefault();
    if (!validateSurrenderForm()) return;

    // Just show confirmation popup — servlet call happens only on OK
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();
    showSurrenderConfirmPopup(lockerType, lockerNumber);
}

// ══════════════════════════════════════════════════════════════
// STEP 2: Show confirmation popup with locker details
// ══════════════════════════════════════════════════════════════
function showSurrenderConfirmPopup(lockerType, lockerNumber) {
    document.getElementById('successLockerType').textContent   = lockerType   || '—';
    document.getElementById('successLockerNumber').textContent = lockerNumber || '—';
    document.getElementById('surrenderSuccessModal').style.display = 'flex';
}

// ══════════════════════════════════════════════════════════════
// STEP 3: OK → call servlet | Cancel → close popup, form stays
// ══════════════════════════════════════════════════════════════
function closeSurrenderSuccessModal(doConfirm) {
    document.getElementById('surrenderSuccessModal').style.display = 'none';
    if (doConfirm) {
        // User clicked OK → now perform the actual surrender operation
        performSurrenderOperation();
    }
    // User clicked Cancel → popup closes, form stays exactly as is, nothing happens
}

// Clicking the dark backdrop = same as Cancel
document.getElementById('surrenderSuccessModal').addEventListener('click', function(e) {
    if (e.target === this) closeSurrenderSuccessModal(false);
});

// ══════════════════════════════════════════════════════════════
// STEP 4: Actual servlet call — only after OK is clicked
// ══════════════════════════════════════════════════════════════
function performSurrenderOperation() {
    var submitBtn = document.querySelector('.form-buttons button[type="submit"]');
    submitBtn.disabled    = true;
    submitBtn.textContent = 'Processing...';

    var formData = new FormData(document.getElementById('surrenderForm'));

    fetch(window.APP_CONTEXT_PATH + '/LockerSurrenderServlet', {
        method: 'POST',
        body:   formData
    })
    .then(function(res) { return res.json(); })
    .then(function(data) {
        submitBtn.disabled    = false;
        submitBtn.textContent = 'Surrender Locker';

        if (data.success) {
            showToast('Locker surrendered successfully!', false);
            resetSurrenderForm(); // reset form only after actual success
        } else {
            showToast(data.message || 'Failed to surrender locker.', true);
        }
    })
    .catch(function(err) {
        submitBtn.disabled    = false;
        submitBtn.textContent = 'Surrender Locker';
        showToast('Network error: ' + err.message, true);
    });
}
</script>
</body>
</html>
