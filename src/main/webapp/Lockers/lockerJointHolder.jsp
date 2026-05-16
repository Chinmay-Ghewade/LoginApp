<%@ page import="java.sql.*, java.io.PrintWriter, db.DBConnection, org.json.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page buffer="8kb" autoFlush="true" %>

<%
    String _action = request.getParameter("action");

    // ─────────────────────────────────────────────
    // AJAX: Return ALL locker types from HEADOFFICE.LOCKERTYPE
    // (No status column in LOCKERTYPE — fetch all)
    // ─────────────────────────────────────────────
    if ("getHiredLockerTypes".equals(_action)) {
        out.clear();
        response.reset();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        PrintWriter pw = response.getWriter();

        String sessionBranch = (String) session.getAttribute("branchCode");
        if (sessionBranch == null) {
            pw.print("{\"success\":false,\"message\":\"Session expired\"}"); pw.flush(); return;
        }
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { pw.print("{\"success\":false,\"message\":\"DB connection failed\"}"); pw.flush(); return; }
            // HEADOFFICE.LOCKERTYPE has no status column — fetch all types
            ps = conn.prepareStatement(
                "SELECT TRIM(LOCKER_TYPE) AS LOCKER_TYPE " +
                "FROM HEADOFFICE.LOCKERTYPE " +
                "ORDER BY LOCKER_TYPE"
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
            pw.print(result.toString());
        } catch (Exception e) {
            String msg = e.getMessage() != null ? e.getMessage().replace("\"","\\\"") : "Unknown error";
            pw.print("{\"success\":false,\"message\":\"" + msg + "\"}");
        } finally {
            try { if (rs!=null) rs.close(); } catch(Exception i){}
            try { if (ps!=null) ps.close(); } catch(Exception i){}
            try { if (conn!=null) conn.close(); } catch(Exception i){}
        }
        pw.flush(); return;
    }

    // ─────────────────────────────────────────────
    // AJAX: Return locker numbers from BRANCH.BRANCHLOCKER
    // where LOCKER_STATUS = 'H' (Hired) for given type
    // ─────────────────────────────────────────────
    if ("getHiredLockerNumbers".equals(_action)) {
        out.clear();
        response.reset();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        PrintWriter pw = response.getWriter();

        String sessionBranch = (String) session.getAttribute("branchCode");
        String lockerType    = request.getParameter("lockerType");
        if (sessionBranch == null) {
            pw.print("{\"success\":false,\"message\":\"Session expired\"}"); pw.flush(); return;
        }
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { pw.print("{\"success\":false,\"message\":\"DB connection failed\"}"); pw.flush(); return; }
            // Filter by LOCKER_STATUS = 'H' in BRANCH.BRANCHLOCKER
            String sql = "SELECT LOCKER_NUMBER, LOCKER_TYPE, CUPBORD_NO, KEY_NO " +
                         "FROM BRANCH.BRANCHLOCKER " +
                         "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                         "AND TRIM(LOCKER_STATUS) = 'H'";
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
            pw.print(result.toString());
        } catch (Exception e) {
            String msg = e.getMessage() != null ? e.getMessage().replace("\"","\\\"") : "Unknown error";
            pw.print("{\"success\":false,\"message\":\"" + msg + "\"}");
        } finally {
            try { if (rs!=null) rs.close(); } catch(Exception i){}
            try { if (ps!=null) ps.close(); } catch(Exception i){}
            try { if (conn!=null) conn.close(); } catch(Exception i){}
        }
        pw.flush(); return;
    }

    // ─────────────────────────────────────────────
    // AJAX: Return customer by locker
    // Source: ACCOUNT.LOCKERACCOUNT
    // Conditions: ACCOUNT_STATUS = 'A', latest DATE_OF_HIRE
    // Customer name column: NAME_OF_HIRE (no join needed)
    // ─────────────────────────────────────────────
    if ("getCustomerByLocker".equals(_action)) {
        out.clear();
        response.reset();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        PrintWriter pw = response.getWriter();

        String sessionBranch   = (String) session.getAttribute("branchCode");
        String lockerType      = request.getParameter("lockerType");
        String lockerNumberStr = request.getParameter("lockerNumber");

        if (sessionBranch == null) {
            pw.print("{\"success\":false,\"message\":\"Session expired\"}");
            pw.flush(); return;
        }
        if (lockerNumberStr == null || lockerNumberStr.trim().isEmpty()) {
            pw.print("{\"success\":false,\"message\":\"Locker number is required\"}");
            pw.flush(); return;
        }

        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) {
                pw.print("{\"success\":false,\"message\":\"DB connection failed\"}");
                pw.flush(); return;
            }
            // Fetch from ACCOUNT.LOCKERACCOUNT only — no join needed
            // ACCOUNT_STATUS = 'A' (active), pick most recent DATE_OF_HIRE
            ps = conn.prepareStatement(
                "SELECT CUSTOMER_ID, NAME_OF_HIRE FROM (" +
                "  SELECT CUSTOMER_ID, NAME_OF_HIRE " +
                "  FROM ACCOUNT.LOCKERACCOUNT " +
                "  WHERE TRIM(BRANCH_CODE)    = TRIM(?) " +
                "  AND   TRIM(LOCKER_TYPE)    = TRIM(?) " +
                "  AND   LOCKER_NUMBER        = ? " +
                "  AND   TRIM(ACCOUNT_STATUS) = 'A' " +
                "  ORDER BY DATE_OF_HIRE DESC" +
                ") WHERE ROWNUM = 1"
            );
            ps.setString(1, sessionBranch.trim());
            ps.setString(2, lockerType != null ? lockerType.trim() : "");
            ps.setString(3, lockerNumberStr.trim());
            rs = ps.executeQuery();

            if (rs.next()) {
                String cid   = rs.getString("CUSTOMER_ID");
                String cname = rs.getString("NAME_OF_HIRE");
                JSONObject result = new JSONObject();
                result.put("success",      true);
                result.put("customerId",   cid   != null ? cid.trim()   : "");
                result.put("customerName", cname != null ? cname.trim() : "");
                pw.print(result.toString());
            } else {
                pw.print("{\"success\":false,\"message\":\"No active customer found for this locker\"}");
            }
        } catch (Exception e) {
            String raw  = (e.getMessage() != null) ? e.getMessage() : "Unknown DB error";
            String safe = raw.replaceAll("[\\r\\n\\t]", " ")
                             .replaceAll("\"", "\'")
                             .replaceAll("\\\\", "/")
                             .replaceAll("[^\\x20-\\x7E]", "");
            pw.print("{\"success\":false,\"message\":\"" + safe + "\"}");
        } finally {
            try { if (rs!=null) rs.close(); } catch(Exception i){}
            try { if (ps!=null) ps.close(); } catch(Exception i){}
            try { if (conn!=null) conn.close(); } catch(Exception i){}
        }
        pw.flush(); return;
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
  <title>Locker Joint Holder</title>
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

    .nominee-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
    .nominee-cid-row { display: flex; align-items: flex-end; gap: 20px; flex-wrap: wrap; margin-bottom: 14px; }
    .nominee-cid-row > div { display: flex; flex-direction: column; gap: 4px; }
    .nominee-cid-row .input-icon-box { display: flex; }
    .nominee-block { border: 1px solid #c9c5e8; border-radius: 6px; padding: 14px 16px; margin-bottom: 16px; }
    .nominee-block:last-of-type { margin-bottom: 4px; }
    .form-buttons { display: flex; gap: 10px; justify-content: center; margin-top: 4px; }
    .nominee-block .personal-grid {
      display: grid !important; grid-template-columns: repeat(4, 1fr) !important;
      gap: 12px !important; align-items: end !important; width: 100% !important;
    }
    .nominee-block .personal-grid > div {
      display: flex !important; flex-direction: column !important;
      gap: 4px !important; min-width: 0 !important; width: 100% !important;
    }
    .nominee-block .personal-grid input,
    .nominee-block .personal-grid select {
      width: 100% !important; box-sizing: border-box !important;
      min-width: 0 !important; max-width: 100% !important; display: block !important;
    }
    .nominee-block .personal-grid div:has(.zip-input) { position: relative !important; }
    .nominee-block .personal-grid .zip-input + small.zipError {
      position: absolute !important; font-size: 11px !important; color: red !important; margin-top: 2px !important;
    }
    .nominee-block .personal-grid .declaration-cell {
      grid-column: 1 / -1 !important; display: flex !important; flex-direction: row !important;
      align-items: center !important; justify-content: center !important; padding-top: 6px !important;
    }
    .nominee-block .personal-grid .declaration-cell label {
      display: flex !important; align-items: center !important;
      gap: 6px !important; cursor: pointer !important; white-space: nowrap !important;
    }
    form { padding: 0 20px; }

    /* locker lookup inputs */
    .input-icon-box { position: relative; width: 90%; }
    .input-icon-box input { width: 100%; padding-right: 40px; height: 30px; cursor: pointer; box-sizing: border-box; }
    .input-icon-box .inside-icon-btn {
      position: absolute; right: 5px; top: 50%; transform: translateY(-50%);
      background: none; border: none; font-size: 16px; cursor: pointer; color: #373279;
    }
    .icon-btn:disabled { background-color: #aaa !important; cursor: not-allowed !important; opacity: 0.6; }
    .simple-lookup-item {
      padding: 13px 20px; cursor: pointer; font-size: 14px; font-weight: 600;
      color: #373279; border-bottom: 1px solid #ece8f8;
      border-left: 3px solid transparent; transition: all 0.15s ease;
      display: flex; align-items: center; justify-content: space-between;
    }
    .simple-lookup-item:hover { background: #f0eefb; border-left-color: #373279; }

    /* joint holder card customer lookup table */
    #jhCardCustomerLookupContent .search-box { padding: 14px 18px 8px 18px; background: var(--lk-primary-light); border-bottom: 1px solid var(--lk-border-light); }
    #jhCardCustomerLookupContent #customerSearch {
      width: 100%; height: 40px; padding: 0 14px 0 42px;
      border: 1.5px solid var(--lk-border); border-radius: var(--lk-radius-md);
      font-size: 0.875rem; font-family: var(--lk-font); color: var(--lk-text);
      box-sizing: border-box; outline: none;
      background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='15' height='15' fill='%238066E8' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11'/%3E%3C/svg%3E") no-repeat 13px center;
      transition: border-color 0.18s ease, box-shadow 0.18s ease;
    }
    #jhCardCustomerLookupContent #customerSearch::placeholder { color: #a090cc; }
    #jhCardCustomerLookupContent #customerSearch:focus { border-color: var(--lk-primary); box-shadow: 0 0 0 3px rgba(55,50,121,0.10); }
    #jhCardCustomerLookupContent .customer-count { font-size: 0.75rem; color: var(--lk-text-muted); text-align: right; padding: 6px 18px; border-bottom: 1px solid var(--lk-border-light); }
    #jhCardCustomerLookupContent .customer-count strong { color: var(--lk-primary); }
    #jhCardCustomerLookupContent .table-container { flex: 1; overflow-y: auto; overflow-x: auto; min-height: 0; }
    #jhCardCustomerLookupContent .table-container::-webkit-scrollbar { width: 7px; }
    #jhCardCustomerLookupContent .table-container::-webkit-scrollbar-track { background: var(--lk-primary-light); }
    #jhCardCustomerLookupContent .table-container::-webkit-scrollbar-thumb { background: var(--lk-border); border-radius: 10px; }
    #jhCardCustomerLookupContent #customerTable { width: 100%; border-collapse: collapse; font-family: var(--lk-font); }
    #jhCardCustomerLookupContent #customerTable thead tr { background: linear-gradient(90deg, var(--lk-primary) 0%, var(--lk-accent) 100%); position: sticky; top: 0; z-index: 2; }
    #jhCardCustomerLookupContent #customerTable thead th { padding: 11px 16px; text-align: left; font-size: 0.77rem; font-weight: 700; color: rgba(255,255,255,0.95); letter-spacing: 0.06em; text-transform: uppercase; border-right: 1px solid rgba(255,255,255,0.12); white-space: nowrap; }
    #jhCardCustomerLookupContent #customerTable thead th:last-child { border-right: none; }
    #jhCardCustomerLookupContent #customerTable tbody tr { border-bottom: 1px solid var(--lk-border-light); cursor: pointer; transition: background 0.18s ease, transform 0.1s ease; border-left: 3px solid transparent; }
    #jhCardCustomerLookupContent #customerTable tbody tr:nth-child(even) { background: var(--lk-row-stripe); }
    #jhCardCustomerLookupContent #customerTable tbody tr:hover { background: var(--lk-row-hover); border-left-color: var(--lk-primary-mid); transform: translateX(2px); }
    #jhCardCustomerLookupContent #customerTable tbody td { padding: 11px 16px; font-size: 0.875rem; color: var(--lk-text); vertical-align: middle; border-right: 1px solid var(--lk-border-light); }
    #jhCardCustomerLookupContent #customerTable tbody td:last-child { border-right: none; }
    #jhCardCustomerLookupContent #customerTable tbody td:first-child { font-weight: 700; color: var(--lk-primary); font-size: 0.84rem; white-space: nowrap; }
  </style>
</head>
<body>

<form action="LockerJointHolderServlet" method="post" onsubmit="return validateForm()">

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 1: LOCKER INFORMATION                                 -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Information</legend>
    <div class="form-grid">

      <div>
        <label>Locker Type</label>
        <div class="input-icon-box">
          <input type="text" name="lockerType" id="lockerType" readonly>
          <button type="button" class="inside-icon-btn"
                  onclick="openLockerTypeLookup()" title="Search Locker Type">🔍</button>
        </div>
      </div>

      <div>
        <label>Locker Number</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="lockerNumber" id="lockerNumber" class="form-input" readonly>
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

      <div>
        <label>Customer ID</label>
        <input type="text" name="customerId" id="customerId" readonly style="background:#f4f2fc;">
      </div>

      <div>
        <label>Customer Name</label>
        <input type="text" name="customerName" id="customerName" readonly style="background:#f4f2fc;">
      </div>

    </div>
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: JOINT HOLDER                                       -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <fieldset id="nomineeFieldset">
    <legend>
      Joint Holder
      <button type="button" onclick="addNominee()"
        style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
        ➕
      </button>
    </legend>

    <div class="nominee-card nominee-block">

      <div class="nominee-header">
        <div class="nominee-title"
             style="font-weight:bold; font-size:15px; color:#373279;">
          Joint Holder <span class="nominee-serial">1</span>
        </div>
        <button type="button" class="nominee-remove" onclick="removeNominee(this)">✖</button>
      </div>

      <!-- Has Customer ID row -->
      <div class="nominee-cid-row">
        <div>
          <label>Has Customer ID ?</label>
          <div style="flex-direction: row;" class="radio-group">
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="yes" onchange="toggleNomineeCustomerID(this)"> Yes</label>
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="no"  onchange="toggleNomineeCustomerID(this)" checked> No</label>
          </div>
        </div>
        <div class="nomineeCustomerIDContainer" style="display:none;">
          <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="nomineeCustomerIDInput" name="nomineeCustomerID[]" onclick="openJHCardCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openJHCardCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <div class="personal-grid">

        <div>
          <label>Salutation Code <span class="dd-spinner jh-sp-salutation"></span></label>
          <select name="nomineeSalutation[]" class="jh-dd-salutation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>Name</label>
          <input type="text" name="nomineeName[]" required
                 oninput="this.value = this.value
                   .replace(/[^A-Za-z ]/g, '')
                   .replace(/\s{2,}/g, ' ')
                   .replace(/^\s+/g, '')
                   .toLowerCase()
                   .replace(/\b\w/g, c => c.toUpperCase());">
        </div>

        <div>
          <label>Zip</label>
          <input type="text" name="nomineeZip[]" class="zip-input" maxlength="6"
                 oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0, 6);" required>
          <small class="zipError"></small>
        </div>

        <div>
          <label>Address 1</label>
          <input type="text" name="nomineeAddress1[]" required>
        </div>

        <div>
          <label>Address 2</label>
          <input type="text" name="nomineeAddress2[]">
        </div>

        <div>
          <label>Address 3</label>
          <input type="text" name="nomineeAddress3[]">
        </div>

        <div>
          <label>City <span class="dd-spinner jh-sp-city"></span></label>
          <select name="nomineeCity[]" class="jh-dd-city dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>State <span class="dd-spinner jh-sp-state"></span></label>
          <select name="nomineeState[]" class="jh-dd-state dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>Relation with Joint Holder <span class="dd-spinner jh-sp-relation"></span></label>
          <select name="nomineeRelation[]" class="jh-dd-relation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div class="declaration-cell">
          <label>
            <input type="checkbox" class="nomineeDeclaration" name="nomineeDeclaration[]" required>
            I confirm the joint holder details are correct
          </label>
        </div>

      </div><!-- /.personal-grid -->
    </div><!-- /.nominee-block -->
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- BUTTON SECTION -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="reset" onclick="resetLockerInfo()" style="background:#dc3545;color:#fff;border:none;padding:8px 24px;border-radius:5px;cursor:pointer;font-size:14px;">Cancel</button>
    <button type="submit" style="background:#28a745;color:#fff;border:none;padding:8px 24px;border-radius:5px;cursor:pointer;font-size:14px;">Save</button>
  </div>

</form>


<!-- ════════ LOCKER TYPE LOOKUP MODAL ════════ -->
<div id="lockerTypeLookupModal" class="customer-modal">
    <div style="background:#fff;border-radius:14px;width:35%;max-width:380px;max-height:70vh;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 8px 32px rgba(55,50,121,0.18);font-family:Arial,sans-serif;">
        <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;background:linear-gradient(135deg,#373279,#2b0d73);border-radius:14px 14px 0 0;flex-shrink:0;">
            <div style="display:flex;align-items:center;gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:17px;">🔒</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;">Select Locker Type</span>
            </div>
            <span onclick="closeLockerTypeLookup()" style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;" onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>
        <div style="padding:12px 18px 8px 18px;background:#f4f2fc;border-bottom:1px solid #e0daf5;">
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


<!-- ════════ LOCKER NUMBER LOOKUP MODAL ════════ -->
<div id="lockerNumberLookupModal" class="customer-modal">
    <div style="background:#fff;border-radius:14px;width:50%;max-width:560px;max-height:72vh;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 8px 32px rgba(55,50,121,0.18);font-family:Arial,sans-serif;">
        <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;background:linear-gradient(135deg,#373279,#2b0d73);border-radius:14px 14px 0 0;flex-shrink:0;">
            <div style="display:flex;align-items:center;gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:17px;">🗄️</div>
                <div>
                    <div style="font-size:1.05rem;font-weight:700;color:#fff;">Hired Lockers</div>
                    <div id="lockerNumberModalSubtitle" style="font-size:0.78rem;color:rgba(255,255,255,0.7);margin-top:1px;"></div>
                </div>
            </div>
            <span onclick="closeLockerNumberLookup()" style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;" onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>
        <div style="padding:12px 18px 8px 18px;background:#f4f2fc;border-bottom:1px solid #e0daf5;">
            <input type="text" id="lockerNumberSearchInput" placeholder="Search locker number..." oninput="filterLockerNumbers()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;border-radius:6px;font-size:0.875rem;box-sizing:border-box;outline:none;font-family:Arial,sans-serif;color:#333;">
        </div>
        <div style="font-size:0.75rem;color:#888;text-align:right;padding:5px 18px;border-bottom:1px solid #ece8f8;">
            Hired: <strong id="lockerNumberCount" style="color:#373279;">0</strong>
        </div>
        <div style="flex:1;overflow-y:auto;overflow-x:auto;min-height:0;">
            <table style="width:100%;border-collapse:collapse;font-family:Arial,sans-serif;">
                <thead>
                    <tr style="background:linear-gradient(90deg,#373279,#5a3ec8);position:sticky;top:0;z-index:2;">
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Locker No.</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Type</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;border-right:1px solid rgba(255,255,255,0.12);">Cupboard No.</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;">Key No.</th>
                    </tr>
                </thead>
                <tbody id="lockerNumberTableBody">
                    <tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>


<!-- ════════ JOINT HOLDER CARD — Customer Lookup Modal ════════ -->
<div id="jhCardCustomerLookupModal" class="customer-modal">
    <div style="background:#fff;border-radius:14px;width:85%;max-width:920px;max-height:84vh;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 8px 32px rgba(55,50,121,0.18);font-family:Arial,sans-serif;">
        <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;background:linear-gradient(135deg,#373279,#2b0d73);border-radius:14px 14px 0 0;flex-shrink:0;">
            <div style="display:flex;align-items:center;gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:17px;">🔍</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;letter-spacing:0.02em;">Customer Lookup</span>
            </div>
            <span onclick="closeJHCardCustomerLookup()" style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;" onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>
        <div id="jhCardCustomerLookupLoading" style="display:flex;align-items:center;justify-content:center;gap:10px;padding:40px 20px;color:#8066E8;font-size:14px;">
            <div style="width:18px;height:18px;border:2.5px solid #e0dcf8;border-top-color:#8066E8;border-radius:50%;animation:lk-spin 0.7s linear infinite;"></div>
            Loading customers...
        </div>
        <div id="jhCardCustomerLookupContent" style="display:flex;flex-direction:column;flex:1;overflow:hidden;"></div>
    </div>
</div>


<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

var _allLockerTypes   = [];
var _allLockerNumbers = [];

// ══════════════════════════════════════════════════════════════════════
// LOCKER TYPE LOOKUP
// Source: HEADOFFICE.LOCKERTYPE (all types, no status filter)
// ══════════════════════════════════════════════════════════════════════
function openLockerTypeLookup() {
    document.getElementById('lockerTypeLookupModal').style.display = 'flex';
    document.getElementById('lockerTypeSearchInput').value = '';

    if (_allLockerTypes.length > 0) { renderLockerTypeList(_allLockerTypes); return; }

    document.getElementById('lockerTypeList').innerHTML =
        '<div style="text-align:center;padding:24px;color:#888;">Loading...</div>';

    fetch('lockerJointHolder.jsp?action=getHiredLockerTypes')
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.success && data.lockerTypes) {
                _allLockerTypes = data.lockerTypes;
                renderLockerTypeList(_allLockerTypes);
            } else {
                document.getElementById('lockerTypeList').innerHTML =
                    '<div style="text-align:center;padding:24px;color:red;">' + (data.message || 'Failed to load.') + '</div>';
            }
        })
        .catch(function(err) {
            document.getElementById('lockerTypeList').innerHTML =
                '<div style="text-align:center;padding:24px;color:red;">Error: ' + err.message + '</div>';
        });
}

function renderLockerTypeList(items) {
    document.getElementById('lockerTypeCount').textContent = items.length;
    var list = document.getElementById('lockerTypeList');
    if (!items.length) {
        list.innerHTML = '<div style="text-align:center;padding:24px;color:#888;">No locker types found.</div>';
        return;
    }
    var html = '';
    items.forEach(function(lt) {
        html += '<div class="simple-lookup-item" onclick="selectLockerType(\'' + lt.lockerType + '\')">'
              + '<span>' + lt.lockerType + '</span></div>';
    });
    list.innerHTML = html;
}

function filterLockerTypes() {
    var q = document.getElementById('lockerTypeSearchInput').value.toUpperCase().trim();
    renderLockerTypeList(!q ? _allLockerTypes : _allLockerTypes.filter(function(lt) {
        return lt.lockerType.toUpperCase().indexOf(q) !== -1;
    }));
}

function selectLockerType(lockerType) {
    document.getElementById('lockerType').value = lockerType;
    closeLockerTypeLookup();
    document.getElementById('lockerNumberBtn').disabled     = false;
    document.getElementById('lockerNumberBtn').title        = 'Search hired lockers';
    document.getElementById('lockerNumberHint').textContent = '';
    document.getElementById('lockerNumber').value = '';
    document.getElementById('customerId').value   = '';
    document.getElementById('customerName').value = '';
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
// Source: BRANCH.BRANCHLOCKER where LOCKER_STATUS = 'H'
// ══════════════════════════════════════════════════════════════════════
function openLockerNumberLookup() {
    var lockerType = document.getElementById('lockerType').value.trim();
    if (!lockerType) { showToast('Please select a Locker Type first.', true); return; }

    document.getElementById('lockerNumberLookupModal').style.display = 'flex';
    document.getElementById('lockerNumberSearchInput').value = '';
    document.getElementById('lockerNumberModalSubtitle').textContent =
        'Type: ' + lockerType + '  •  Status: Hired';

    if (_allLockerNumbers.length > 0) { renderLockerNumberRows(_allLockerNumbers); return; }

    document.getElementById('lockerNumberTableBody').innerHTML =
        '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>';

    fetch('lockerJointHolder.jsp?action=getHiredLockerNumbers&lockerType=' + encodeURIComponent(lockerType))
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.success) {
                _allLockerNumbers = data.lockers || [];
                renderLockerNumberRows(_allLockerNumbers);
            } else {
                document.getElementById('lockerNumberTableBody').innerHTML =
                    '<tr><td colspan="4" style="text-align:center;padding:24px;color:red;">' + (data.message || 'Failed to load.') + '</td></tr>';
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
    if (!items.length) {
        tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">No hired lockers found for this type.</td></tr>';
        return;
    }
    var fragment = document.createDocumentFragment();
    items.forEach(function(lk) {
        var tr = document.createElement('tr');
        tr.style.cssText = 'border-bottom:1px solid #ece8f8;cursor:pointer;border-left:3px solid transparent;transition:all 0.15s ease;';
        tr.addEventListener('mouseover', function() { this.style.background='#f0eefb'; this.style.borderLeftColor='#373279'; });
        tr.addEventListener('mouseout',  function() { this.style.background='';       this.style.borderLeftColor='transparent'; });
        tr.addEventListener('click',     function() { selectLockerNumber(lk.lockerNumber, lk.lockerType); });
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
    var q = document.getElementById('lockerNumberSearchInput').value.toUpperCase().trim();
    renderLockerNumberRows(!q ? _allLockerNumbers : _allLockerNumbers.filter(function(lk) {
        return String(lk.lockerNumber).toUpperCase().indexOf(q) !== -1;
    }));
}

function selectLockerNumber(lockerNumber, lockerType) {
    document.getElementById('lockerNumber').value = lockerNumber;
    closeLockerNumberLookup();
    document.getElementById('customerId').value   = '';
    document.getElementById('customerName').value = 'Fetching...';

    // Fetch customer from ACCOUNT.LOCKERACCOUNT
    // where ACCOUNT_STATUS = 'A' and latest DATE_OF_HIRE
    fetch('lockerJointHolder.jsp?action=getCustomerByLocker'
            + '&lockerType='   + encodeURIComponent(lockerType)
            + '&lockerNumber=' + encodeURIComponent(lockerNumber))
        .then(function(r) {
            var contentType = r.headers.get('content-type') || '';
            if (!r.ok || contentType.indexOf('application/json') === -1) {
                document.getElementById('customerName').value = '';
                if (r.redirected) {
                    showToast('Session expired. Please log in again.', true);
                } else {
                    showToast('Server error (' + r.status + '). Could not fetch customer.', true);
                }
                return null;
            }
            return r.json();
        })
        .then(function(data) {
            if (!data) return;
            if (data.success) {
                document.getElementById('customerId').value   = data.customerId   || '';
                document.getElementById('customerName').value = data.customerName || '';
            } else {
                document.getElementById('customerId').value   = '';
                document.getElementById('customerName').value = '';
                showToast(data.message || 'No active customer found for this locker.', false);
            }
        })
        .catch(function(err) {
            document.getElementById('customerName').value = '';
            document.getElementById('customerId').value  = '';
            showToast('Unable to fetch customer details. Please try again.', true);
        });
}

function closeLockerNumberLookup() {
    document.getElementById('lockerNumberLookupModal').style.display = 'none';
}
document.getElementById('lockerNumberLookupModal').addEventListener('click', function(e) {
    if (e.target === this) closeLockerNumberLookup();
});


// ══════════════════════════════════════════════════════════════════════
// JOINT HOLDER CARD DROPDOWNS
// ══════════════════════════════════════════════════════════════════════
var _jhDropdownCache = null;
var JH_DD_MAP = {
    salutation : { sel: '.jh-dd-salutation', sp: '.jh-sp-salutation' },
    relation   : { sel: '.jh-dd-relation',   sp: '.jh-sp-relation'   },
    city       : { sel: '.jh-dd-city',       sp: '.jh-sp-city'       },
    state      : { sel: '.jh-dd-state',      sp: '.jh-sp-state'      }
};

function _fillJHSelect(selectEl, items) {
    selectEl.innerHTML = '';
    var blank = document.createElement('option'); blank.value = ''; blank.textContent = '-- Select --';
    selectEl.appendChild(blank);
    items.forEach(function(item) {
        var opt = document.createElement('option'); opt.value = item.v; opt.textContent = item.l;
        selectEl.appendChild(opt);
    });
    selectEl.classList.remove('dd-loading'); selectEl.style.color = ''; selectEl.style.fontStyle = '';
}

function _fillJHBlock(block, data) {
    Object.keys(JH_DD_MAP).forEach(function(key) {
        var cfg = JH_DD_MAP[key];
        var selEl = block.querySelector(cfg.sel); var spEl = block.querySelector(cfg.sp);
        if (!selEl) return;
        var items = data[key];
        if (Array.isArray(items) && items.length > 0) { _fillJHSelect(selEl, items); }
        else { selEl.innerHTML = '<option value="">-- Error loading --</option>'; selEl.classList.remove('dd-loading'); }
        if (spEl) spEl.classList.add('done');
    });
}

(function loadJHDropdowns() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
        .then(function(r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
        .then(function(data) {
            if (data._error) console.warn('Joint holder dropdown warning:', data._error);
            _jhDropdownCache = data;
            var firstBlock = document.querySelector('.nominee-block');
            if (firstBlock) _fillJHBlock(firstBlock, data);
        })
        .catch(function(err) {
            console.error('Joint holder dropdown error:', err);
            var firstBlock = document.querySelector('.nominee-block');
            if (!firstBlock) return;
            Object.keys(JH_DD_MAP).forEach(function(key) {
                var selEl = firstBlock.querySelector(JH_DD_MAP[key].sel);
                var spEl  = firstBlock.querySelector(JH_DD_MAP[key].sp);
                if (selEl) { selEl.innerHTML = '<option value="">-- Error: reload page --</option>'; selEl.classList.remove('dd-loading'); selEl.style.borderColor = '#f44336'; }
                if (spEl)  { spEl.style.background = '#f44336'; spEl.classList.add('done'); }
            });
        });
})();

function renumberNominees() {
    document.querySelectorAll('.nominee-block').forEach(function(card, idx) {
        var serial = card.querySelector('.nominee-serial');
        if (serial) serial.textContent = idx + 1;
        card.querySelectorAll('.nomineeHasCustomerRadio').forEach(function(r) { r.name = 'nomineeHasCustomerID_' + (idx + 1); });
    });
}

function addNominee() {
    var fieldset = document.getElementById('nomineeFieldset');
    var firstCard = fieldset.querySelector('.nominee-block');
    var newCard = firstCard.cloneNode(true);
    newCard.querySelectorAll('input, select, textarea').forEach(function(el) {
        if (el.type === 'radio')    { el.checked = (el.value === 'no'); return; }
        if (el.type === 'checkbox') { el.checked = false; return; }
        el.value = '';
    });
    var cidContainer = newCard.querySelector('.nomineeCustomerIDContainer');
    if (cidContainer) cidContainer.style.display = 'none';
    newCard.querySelectorAll('.zipError').forEach(function(el) { el.textContent = ''; });
    newCard.querySelectorAll('.dd-spinner').forEach(function(sp) { sp.classList.remove('done'); });
    Object.keys(JH_DD_MAP).forEach(function(key) {
        var selEl = newCard.querySelector(JH_DD_MAP[key].sel);
        if (selEl) { selEl.innerHTML = '<option value="">Loading...</option>'; selEl.classList.add('dd-loading'); }
    });
    var blocks = fieldset.querySelectorAll('.nominee-block');
    blocks[blocks.length - 1].insertAdjacentElement('afterend', newCard);
    renumberNominees();
    if (_jhDropdownCache) { _fillJHBlock(newCard, _jhDropdownCache); }
    else {
        fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
            .then(function(r) { return r.json(); })
            .then(function(data) { _jhDropdownCache = data; _fillJHBlock(newCard, data); });
    }
}

function removeNominee(btn) {
    if (document.querySelectorAll('.nominee-block').length <= 1) { alert('At least one joint holder is required.'); return; }
    btn.closest('.nominee-block').remove();
    renumberNominees();
}

function toggleNomineeCustomerID(radio) {
    var card = radio.closest('.nominee-block');
    var container = card.querySelector('.nomineeCustomerIDContainer');
    if (!container) return;
    container.style.display = (radio.value === 'yes') ? 'flex' : 'none';
    var input = container.querySelector('.nomineeCustomerIDInput');
    if (input && radio.value !== 'yes') input.value = '';
}


// ══════════════════════════════════════════════════════════════════════
// JOINT HOLDER CARD — Customer Lookup
// ══════════════════════════════════════════════════════════════════════
var _activeJHCard = null;

function openJHCardCustomerLookup(triggerEl) {
    _activeJHCard = triggerEl.closest('.nominee-block');
    document.getElementById('jhCardCustomerLookupModal').style.display = 'flex';
    document.getElementById('jhCardCustomerLookupLoading').style.display = 'flex';
    document.getElementById('jhCardCustomerLookupContent').innerHTML = '';
    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/lookupForCustomerId.jsp')
        .then(function(r) { return r.text(); })
        .then(function(html) {
            document.getElementById('jhCardCustomerLookupLoading').style.display = 'none';
            var content = document.getElementById('jhCardCustomerLookupContent');
            content.innerHTML = html;
            content.querySelectorAll('script').forEach(function(s) {
                var ns = document.createElement('script'); ns.textContent = s.textContent;
                document.body.appendChild(ns); document.body.removeChild(ns);
            });
        });
}

function closeJHCardCustomerLookup() {
    document.getElementById('jhCardCustomerLookupModal').style.display = 'none';
}

window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
    if (!_activeJHCard) return;
    var idInput = _activeJHCard.querySelector('.nomineeCustomerIDInput');
    if (idInput) idInput.value = customerId;
    closeJHCardCustomerLookup();
    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/getCustomerDetails.jsp?customerId=' + encodeURIComponent(customerId))
        .then(function(r) {
            var contentType = r.headers.get('content-type') || '';
            if (!r.ok || contentType.indexOf('application/json') === -1) {
                throw new Error('Non-JSON response from getCustomerDetails');
            }
            return r.json();
        })
        .then(function(data) {
            if (!data.success || !data.customer) return;
            var c = data.customer;
            var fieldMap = {
                'nomineeName[]'     : c.customerName || '',
                'nomineeAddress1[]' : c.address1     || '',
                'nomineeAddress2[]' : c.address2     || '',
                'nomineeAddress3[]' : c.address3     || '',
                'nomineeZip[]'      : c.zip ? String(c.zip) : ''
            };
            Object.keys(fieldMap).forEach(function(name) {
                var el = _activeJHCard.querySelector('[name="' + name + '"]');
                if (el) el.value = fieldMap[name];
            });
            var ddMap = { 'nomineeCity[]': c.city || '', 'nomineeState[]': c.state || '' };
            Object.keys(ddMap).forEach(function(name) {
                var sel = _activeJHCard.querySelector('[name="' + name + '"]');
                if (!sel || !ddMap[name]) return;
                for (var i = 0; i < sel.options.length; i++) {
                    if (sel.options[i].value === ddMap[name] || sel.options[i].text === ddMap[name]) { sel.selectedIndex = i; break; }
                }
            });
        })
        .catch(function(err) {
            console.error('Failed to fetch joint holder customer details:', err);
        });
};


// ── Toast ───────────────────────────────────────────────────────────
function showToast(msg, isError) {
    Toastify({
        text: msg, duration: 3500, gravity: 'top', position: 'right', stopOnFocus: true,
        style: {
            background: isError ? 'linear-gradient(to right,#e53935,#b71c1c)' : 'linear-gradient(to right,#373279,#5a3ec8)',
            borderRadius: '8px', fontFamily: 'Arial,sans-serif', fontSize: '14px'
        }
    }).showToast();
}

// ── Reset ───────────────────────────────────────────────────────────
function resetLockerInfo() {
    document.getElementById('lockerType').value   = '';
    document.getElementById('lockerNumber').value = '';
    document.getElementById('customerId').value   = '';
    document.getElementById('customerName').value = '';
    document.getElementById('lockerNumberBtn').disabled     = true;
    document.getElementById('lockerNumberBtn').title        = 'Select Locker Type first';
    document.getElementById('lockerNumberHint').textContent = 'Select locker type first';
    _allLockerTypes = []; _allLockerNumbers = [];
}

// ── Form validation ─────────────────────────────────────────────────
function validateForm() {
    var valid = true;
    document.querySelectorAll('.zip-input').forEach(function(inp) {
        var errEl = inp.nextElementSibling;
        if (inp.value.length !== 6 || !/^\d{6}$/.test(inp.value)) {
            if (errEl) errEl.textContent = 'Must be exactly 6 digits';
            valid = false;
        } else {
            if (errEl) errEl.textContent = '';
        }
    });
    if (valid) {
        var unchecked = false;
        document.querySelectorAll('.nomineeDeclaration').forEach(function(cb) {
            if (!cb.checked) unchecked = true;
        });
        if (unchecked) { alert('Please accept the declaration for all joint holders.'); valid = false; }
    }
    return valid;
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath
                ? window.buildBreadcrumbPath('Lockers/lockerJointHolder.jsp')
                : 'Locker Joint Holder'
        );
    }
};
</script>

</body>
</html>
