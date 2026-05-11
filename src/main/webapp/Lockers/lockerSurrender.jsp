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
    // AJAX: Return ISSUED locker numbers as JSON
    // Fetches from ACCOUNT.LOCKERACCOUNT (active/issued lockers only)
    // ─────────────────────────────────────────────
    if ("getIssuedLockers".equals(request.getParameter("action"))) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

        String sessionBranch = (String) session.getAttribute("branchCode");
        String lockerType    = request.getParameter("lockerType");

        if (sessionBranch == null) {
            out.print("{\"success\":false,\"message\":\"Session expired\"}");
            return;
        }

        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print("{\"success\":false,\"message\":\"DB connection failed\"}"); return; }

            // Fetch from LOCKERACCOUNT — these are already issued lockers
            String sql = "SELECT LA.LOCKER_NUMBER, LA.LOCKER_TYPE, LA.KEY_NO, " +
                         "LA.CUSTOMER_ID, LA.NAME_OF_HIRE " +
                         "FROM ACCOUNT.LOCKERACCOUNT LA " +
                         "WHERE TRIM(LA.BRANCH_CODE) = TRIM(?)";

            if (lockerType != null && !lockerType.trim().isEmpty()) {
                sql += " AND TRIM(LA.LOCKER_TYPE) = TRIM(?)";
            }
            sql += " ORDER BY LA.LOCKER_NUMBER";

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
  <title>Locker Surrender</title>
  <link rel="stylesheet" href="../css/locker.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <link rel="stylesheet" href="../css/lookup-modal.css">
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
    .icon-btn:disabled {
      background-color: #aaa !important;
      cursor: not-allowed !important;
      opacity: 0.6;
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
    #checkAvailabilityBtn:hover  { background-color: #2b0d73; transform: scale(1.05); }
    #checkAvailabilityBtn:active { transform: scale(0.97); }

    .txn-mode-row {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .txn-mode-row .radio-group { flex-direction: row; }

    form { padding: 0 20px; }

    /* ── Simple list item — same as lockerIssues.jsp ── */
    .simple-lookup-item {
      padding: 13px 20px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      color: #373279;
      border-bottom: 1px solid #ece8f8;
      border-left: 3px solid transparent;
      transition: all 0.15s ease;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .simple-lookup-item:hover { background: #f0eefb; border-left-color: #373279; }
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


<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOCKER TYPE LOOKUP MODAL — same as lockerIssues.jsp            -->
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
<!-- Shows ISSUED lockers from ACCOUNT.LOCKERACCOUNT                -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lockerNumberLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:60%; max-width:680px;
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
                    <div style="font-size:1.05rem;font-weight:700;color:#fff;">Issued Lockers</div>
                    <div id="lockerNumberModalSubtitle"
                         style="font-size:0.78rem;color:rgba(255,255,255,0.7);margin-top:1px;"></div>
                </div>
            </div>
            <span onclick="closeLockerNumberLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'" onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <div style="padding:12px 18px 8px 18px; background:#f4f2fc; border-bottom:1px solid #e0daf5;">
            <input type="text" id="lockerNumberSearchInput" placeholder="Search locker number or customer..."
                   oninput="filterLockerNumbers()"
                   style="width:100%;height:38px;padding:0 14px;border:1.5px solid #c5bef0;
                          border-radius:6px;font-size:0.875rem;box-sizing:border-box;
                          outline:none;font-family:Arial,sans-serif;color:#333;">
        </div>

        <div style="font-size:0.75rem;color:#888;text-align:right;padding:5px 18px;border-bottom:1px solid #ece8f8;">
            Issued: <strong id="lockerNumberCount" style="color:#373279;">0</strong>
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
                                   border-right:1px solid rgba(255,255,255,0.12);">Customer ID</th>
                        <th style="padding:10px 16px;text-align:left;font-size:0.77rem;font-weight:700;
                                   color:rgba(255,255,255,0.95);letter-spacing:0.06em;text-transform:uppercase;">Name of Hire</th>
                    </tr>
                </thead>
                <tbody id="lockerNumberTableBody">
                    <tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>


<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

var _allLockerTypes   = [];
var _allLockerNumbers = [];

// ── Set today's date ────────────────────────────────────────────────
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


// ═══════════════════════════════════════════════════════════════════════
// LOCKER TYPE LOOKUP — same as lockerIssues.jsp
// Fetches from HEADOFFICE.LOCKERTYPE
// ═══════════════════════════════════════════════════════════════════════

function openLockerTypeLookup() {
    document.getElementById('lockerTypeLookupModal').style.display = 'flex';
    document.getElementById('lockerTypeSearchInput').value = '';

    if (_allLockerTypes.length > 0) { renderLockerTypeList(_allLockerTypes); return; }

    document.getElementById('lockerTypeList').innerHTML =
        '<div style="text-align:center;padding:24px;color:#888;">Loading...</div>';

    fetch('lockerSurrender.jsp?action=getLockerTypes')
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

    // Enable locker number button
    var btn  = document.getElementById('lockerNumberBtn');
    var hint = document.getElementById('lockerNumberHint');
    btn.disabled     = false;
    btn.title        = 'Search issued lockers';
    hint.textContent = '';

    // Clear previous selection & reset cache
    document.getElementById('lockerNumberSearch').value = '';
    _allLockerNumbers = [];
}

function closeLockerTypeLookup() {
    document.getElementById('lockerTypeLookupModal').style.display = 'none';
}

document.getElementById('lockerTypeLookupModal').addEventListener('click', function(e) {
    if (e.target === this) closeLockerTypeLookup();
});


// ═══════════════════════════════════════════════════════════════════════
// LOCKER NUMBER LOOKUP
// Fetches from ACCOUNT.LOCKERACCOUNT (issued/active lockers)
// ═══════════════════════════════════════════════════════════════════════

function openLockerNumberLookup() {
    var lockerType = document.getElementById('lockerTypeSearch').value.trim();
    if (!lockerType) { alert('Please select a Locker Type first.'); return; }

    document.getElementById('lockerNumberLookupModal').style.display = 'flex';
    document.getElementById('lockerNumberSearchInput').value = '';
    document.getElementById('lockerNumberModalSubtitle').textContent =
        'Type: ' + lockerType + '  •  Issued lockers only';

    if (_allLockerNumbers.length > 0) { renderLockerNumberRows(_allLockerNumbers); return; }

    document.getElementById('lockerNumberTableBody').innerHTML =
        '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">Loading...</td></tr>';

    // ✅ Fetches from ACCOUNT.LOCKERACCOUNT — issued lockers
    fetch('lockerSurrender.jsp?action=getIssuedLockers&lockerType=' + encodeURIComponent(lockerType))
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
            '<tr><td colspan="4" style="text-align:center;padding:24px;color:#888;">No issued lockers found for this type.</td></tr>';
        return;
    }

    var fragment = document.createDocumentFragment();
    items.forEach(function(lk) {
        var tr = document.createElement('tr');
        tr.style.cssText = 'border-bottom:1px solid #ece8f8;cursor:pointer;border-left:3px solid transparent;transition:all 0.15s ease;';
        tr.addEventListener('mouseover', function() { this.style.background='#f0eefb'; this.style.borderLeftColor='#373279'; });
        tr.addEventListener('mouseout',  function() { this.style.background='';       this.style.borderLeftColor='transparent'; });
        tr.addEventListener('click',     function() { selectLockerNumber(lk.lockerNumber, lk.customerId, lk.nameOfHire); });

        var cells = [
            { val: lk.lockerNumber, style: 'padding:11px 16px;font-weight:700;color:#373279;font-size:0.9rem;border-right:1px solid #ece8f8;' },
            { val: lk.lockerType,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;border-right:1px solid #ece8f8;' },
            { val: lk.customerId,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;border-right:1px solid #ece8f8;' },
            { val: lk.nameOfHire,   style: 'padding:11px 16px;font-size:0.875rem;color:#333;' }
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
        return String(lk.lockerNumber).toUpperCase().indexOf(query) !== -1
            || String(lk.nameOfHire).toUpperCase().indexOf(query) !== -1
            || String(lk.customerId).toUpperCase().indexOf(query) !== -1;
    }));
}

function selectLockerNumber(lockerNumber, customerId, nameOfHire) {
    document.getElementById('lockerNumberSearch').value = lockerNumber;
    // Pre-fill customer id and name of hire on selection
    if (document.getElementById('customerId'))  document.getElementById('customerId').value  = customerId  || '';
    if (document.getElementById('nameOfHire'))  document.getElementById('nameOfHire').value  = nameOfHire  || '';
    closeLockerNumberLookup();
}

function closeLockerNumberLookup() {
    document.getElementById('lockerNumberLookupModal').style.display = 'none';
}

document.getElementById('lockerNumberLookupModal').addEventListener('click', function(e) {
    if (e.target === this) closeLockerNumberLookup();
});


// ── Load full locker details on Check Availability ──────────────────
function loadLockerDetails() {
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();

    if (!lockerType && !lockerNumber) {
        alert('Please select Locker Type and Locker Number first.');
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

// ── Toggle transfer status field ────────────────────────────────────
function toggleTransferStatus(radio) {
    var statusField = document.getElementById('transferStatus');
    statusField.readOnly = (radio.value !== 'TRANSFER');
    if (radio.value !== 'TRANSFER') statusField.value = '';
}

// ── Debit AC Lookup placeholder ─────────────────────────────────────
function openDebitACLookup() { /* TODO: wire to your lookup modal */ }

// ── Reset form ──────────────────────────────────────────────────────
function resetSurrenderForm() {
    document.querySelector('form').reset();
    var today = new Date().toISOString().split('T')[0];
    document.getElementById('transactionDate').value = today;

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
    document.getElementById('period').value = '12';
    document.getElementById('amount').value = '0';

    // Reset locker number button
    var btn  = document.getElementById('lockerNumberBtn');
    var hint = document.getElementById('lockerNumberHint');
    btn.disabled     = true;
    btn.title        = 'Select Locker Type first';
    hint.textContent = 'Select locker type first';
    _allLockerNumbers = [];
}

// ── Form validation ─────────────────────────────────────────────────
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
