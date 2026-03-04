<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, db.DBConnection" %>

<%
// ─────────────────────────────────────────────
// AJAX: Check if User ID already exists
// ─────────────────────────────────────────────
if ("checkUserId".equals(request.getParameter("action"))) {
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String userId = request.getParameter("userId");

    if (userId == null || userId.trim().isEmpty()) {
        out.print("{\"exists\":false,\"message\":\"\"}");
        return;
    }

    Connection conn   = null;
    PreparedStatement pstmt = null;
    ResultSet rs      = null;

    try {
        conn = DBConnection.getConnection();
        if (conn == null) {
            out.print("{\"error\":true,\"message\":\"Database connection failed\"}");
            return;
        }

        String sql = "SELECT USER_ID FROM ACL.USERREGISTER WHERE USER_ID = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId.trim());
        rs = pstmt.executeQuery();

        if (rs.next()) {
            String message = "User ID '" + userId + "' already exists";
            out.print("{\"exists\":true,\"message\":\"" + message.replace("\\","\\\\").replace("\"","\\\"") + "\"}");
        } else {
            out.print("{\"exists\":false,\"message\":\"User ID is available\"}");
        }

    } catch (Exception e) {
        out.print("{\"error\":true,\"message\":\"" + e.getMessage().replace("\\","\\\\").replace("\"","\\\"") + "\"}");
    } finally {
        try { if (rs    != null) rs.close();    } catch (Exception ignored) {}
        try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
        try { if (conn  != null) conn.close();  } catch (Exception ignored) {}
    }
    return;
}

// ─────────────────────────────────────────────
// AJAX: Load all roles from MAINROLEREGISTER
// ─────────────────────────────────────────────
if ("getRoles".equals(request.getParameter("action"))) {
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Connection conn   = null;
    PreparedStatement pstmt = null;
    ResultSet rs      = null;

    try {
        conn = DBConnection.getConnection();
        if (conn == null) {
            out.print("{\"success\":false,\"message\":\"Database connection failed\"}");
            return;
        }

        String sql = "SELECT MAINROLE_ID, MAINROLE FROM ACL.MAINROLEREGISTER ORDER BY MAINROLE";
        pstmt = conn.prepareStatement(sql);
        rs    = pstmt.executeQuery();

        StringBuilder json = new StringBuilder("{\"success\":true,\"roles\":[");
        boolean first = true;

        while (rs.next()) {
            if (!first) json.append(",");
            first = false;

            int    roleId   = rs.getInt("MAINROLE_ID");
            String roleName = rs.getString("MAINROLE");

            if (roleName != null) {
                roleName = roleName.replace("\\","\\\\")
                                   .replace("\"","\\\"")
                                   .replace("\r","")
                                   .replace("\n","");
            } else {
                roleName = "";
            }

            json.append("{\"id\":").append(roleId)
                .append(",\"name\":\"").append(roleName).append("\"}");
        }

        json.append("]}");
        out.print(json.toString());

    } catch (Exception e) {
        out.print("{\"success\":false,\"message\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
    } finally {
        try { if (rs    != null) rs.close();    } catch (Exception ignored) {}
        try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
        try { if (conn  != null) conn.close();  } catch (Exception ignored) {}
    }
    return;
}

// ─────────────────────────────────────────────
// Read and immediately clear popup status from SESSION
// Using session ensures it works after servlet forward
// ─────────────────────────────────────────────
String popupStatus = (String) session.getAttribute("popupStatus");
String popupMsg    = (String) session.getAttribute("popupMsg");
session.removeAttribute("popupStatus"); // clear so refresh doesn't re-show
session.removeAttribute("popupMsg");

if (popupStatus == null) popupStatus = "";
if (popupMsg    == null) popupMsg    = "";
popupMsg = popupMsg.replace("\\","\\\\").replace("'","\\'");

// ─────────────────────────────────────────────
// Branch name lookup
// ─────────────────────────────────────────────
String sessionBranchCode = (String) session.getAttribute("branchCode");
String branchName        = "";

if (sessionBranchCode != null && !sessionBranchCode.isEmpty()) {
    Connection conn   = null;
    PreparedStatement pstmt = null;
    ResultSet rs      = null;

    try {
        conn = DBConnection.getConnection();
        String sql = "SELECT NAME FROM HEADOFFICE.BRANCH WHERE BRANCH_CODE = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, sessionBranchCode);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            branchName = rs.getString("NAME");
        }
    } catch (Exception e) {
        branchName = "Error loading branch";
    } finally {
        try { if (rs    != null) rs.close();    } catch (Exception ignored) {}
        try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
        try { if (conn  != null) conn.close();  } catch (Exception ignored) {}
    }

} else {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>New User Creation</title>
    <link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/OpenAccount/css/savingAcc.css">

    <style>
        :root {
            --bg-lavender:   #E6E6FA;
            --navy-blue:     #2b0d73;
            --border-color:  #B8B8E6;
            --readonly-bg:   #E0E0E0;
            --success-green: #3cb554;
            --error-red:     #dc3545;
            --info-blue:     #2196F3;
        }

        body {
            font-family: Arial, sans-serif;
            background-color: var(--bg-lavender);
            margin: 0;
            padding: 20px 20px 60px 20px;
        }

        .container { max-width: 1400px; margin: auto; }

        h2 {
            text-align: center;
            color: var(--navy-blue);
            margin-bottom: 25px;
        }

        fieldset {
            border: 1.5px solid var(--border-color);
            border-radius: 8px;
            margin-bottom: 22px;
            padding: 18px;
            overflow: visible;
        }

        legend {
            color: var(--navy-blue);
            font-weight: bold;
            font-size: 15px;
            padding: 0 10px;
            background-color: var(--bg-lavender);
        }

        .grid-row-1 {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 15px;
            margin-bottom: 15px;
            align-items: end;
        }

        .grid-row-2 {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            align-items: end;
        }

        .form-group { width: 100%; }

        .form-group label {
            display: block;
            font-size: 13px;
            font-weight: bold;
            color: var(--navy-blue);
            margin-bottom: 4px;
        }

        .form-group input,
        .form-group select {
            width: 100%;
            padding: 7px;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            font-size: 13px;
            box-sizing: border-box;
        }

        input[readonly]  { background-color: var(--readonly-bg); }
        input.error      { border-color: var(--error-red); }
        input.success    { border-color: var(--success-green); }

        .input-row {
            display: flex !important;
            flex-direction: row !important;
            flex-wrap: nowrap !important;
            align-items: center !important;
            gap: 6px;
            width: 100%;
        }

        .input-row input { flex: 1; min-width: 0; }

        .search-btn {
            width: 38px;
            height: 31px;
            flex-shrink: 0;
            border: 1px solid var(--navy-blue);
            background: #fff;
            border-radius: 4px;
            font-weight: bold;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* ── USER ROLES ── */
        .roles-container     { display: flex; flex-direction: column; gap: 12px; }
        .role-dropdown-wrapper { width: 260px; position: relative; z-index: 500; }

        .role-dropdown-wrapper label {
            display: block;
            font-size: 13px;
            font-weight: bold;
            color: var(--navy-blue);
            margin-bottom: 4px;
        }

        .role-dropdown-btn {
            width: 100%;
            padding: 7px 10px;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            background-color: white;
            font-family: Arial, sans-serif;
            font-size: 13px;
            color: #555;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 6px;
            box-sizing: border-box;
            transition: border-color 0.15s;
            user-select: none;
        }

        .role-dropdown-btn:hover       { border-color: var(--navy-blue); }
        .role-dropdown-btn.open        { border-color: var(--navy-blue); outline: none; }
        .role-dropdown-btn.error-border { border-color: var(--error-red); border-width: 2px; }

        .btn-left-content { display: flex; align-items: center; gap: 6px; }

        .role-count-badge {
            display: none;
            background-color: var(--navy-blue);
            color: white;
            font-size: 11px;
            font-weight: bold;
            padding: 1px 7px;
            border-radius: 10px;
        }
        .role-count-badge.visible { display: inline-block; }

        .dropdown-arrow {
            font-size: 10px;
            color: #888;
            transition: transform 0.2s ease;
            flex-shrink: 0;
        }
        .role-dropdown-btn.open .dropdown-arrow { transform: rotate(180deg); }

        .role-dropdown-panel {
            position: absolute;
            top: calc(100% + 4px);
            left: 0;
            width: 580px;
            background: white;
            border: 1px solid var(--border-color);
            border-radius: 6px;
            box-shadow: 0 4px 20px rgba(48,63,159,0.15), 0 1px 4px rgba(0,0,0,0.08);
            z-index: 9000;
            overflow: hidden;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.16s ease, transform 0.16s ease;
            transform: translateY(-4px);
            display: flex;
            flex-direction: column;
            max-height: 480px;
        }
        .role-dropdown-panel.open {
            opacity: 1;
            pointer-events: all;
            transform: translateY(0);
        }

        .roles-checkbox-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 7px;
            padding: 12px 14px;
            overflow-y: auto;
            flex: 1;
            min-height: 0;
        }
        .roles-checkbox-grid::-webkit-scrollbar       { width: 8px; }
        .roles-checkbox-grid::-webkit-scrollbar-track { background: #f5f5f5; }
        .roles-checkbox-grid::-webkit-scrollbar-thumb { background: #a0a8d8; border-radius: 10px; }

        .role-checkbox-item {
            display: flex;
            align-items: center;
            gap: 9px;
            padding: 9px 12px;
            border-radius: 4px;
            border: 1px solid var(--border-color);
            background-color: #f9f9fc;
            cursor: pointer;
            transition: background-color 0.12s, border-color 0.12s;
            user-select: none;
        }
        .role-checkbox-item:hover  { background-color: #eef0fb; border-color: var(--navy-blue); }
        .role-checkbox-item.checked { background-color: #eef0fb; border-color: var(--navy-blue); }

        .role-checkbox-item input[type="checkbox"] {
            width: 15px;
            height: 15px;
            cursor: pointer;
            margin: 0;
            accent-color: var(--navy-blue);
            flex-shrink: 0;
            pointer-events: none;
        }

        .role-checkbox-item label {
            font-size: 13px;
            font-family: Arial, sans-serif;
            color: #333;
            font-weight: normal;
            margin: 0;
            cursor: pointer;
            white-space: normal;
            word-break: break-word;
            line-height: 1.3;
            pointer-events: none;
            flex: 1;
        }
        .role-checkbox-item.checked label { color: var(--navy-blue); font-weight: bold; }

        .panel-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 8px 14px;
            border-top: 1px solid var(--border-color);
            background-color: #fafafa;
        }

        .panel-clear-btn {
            font-size: 13px;
            font-weight: bold;
            color: #999;
            background: none;
            border: none;
            cursor: pointer;
            padding: 8px 10px;
            border-radius: 4px;
            transition: color 0.12s, background 0.12s;
        }
        .panel-clear-btn:hover { color: var(--error-red); background-color: #fff5f5; }

        .panel-done-btn {
            font-size: 13px;
            font-weight: bold;
            background-color: var(--navy-blue);
            color: white;
            border: none;
            cursor: pointer;
            padding: 8px 26px;
            border-radius: 4px;
        }
        .panel-done-btn:hover { background-color: #1a2a80; }

        .no-roles-message {
            grid-column: 1 / -1;
            text-align: center;
            color: #999;
            padding: 20px;
            font-size: 13px;
        }

        .selected-tags-label {
            font-size: 11px;
            font-weight: bold;
            color: #999;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 7px;
            display: none;
        }
        .selected-tags-label.visible { display: block; }

        .selected-tags-wrap { display: flex; flex-wrap: wrap; gap: 6px; }

        .role-tag {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background-color: #eef0fb;
            color: var(--navy-blue);
            font-size: 11px;
            font-weight: bold;
            padding: 4px 8px 4px 10px;
            border-radius: 12px;
            border: 1px solid #c5caee;
            animation: tagPop 0.15s ease;
        }

        @keyframes tagPop {
            from { opacity: 0; transform: scale(0.8); }
            to   { opacity: 1; transform: scale(1); }
        }

        .role-tag-remove {
            background: none;
            border: none;
            cursor: pointer;
            color: var(--navy-blue);
            opacity: 0.5;
            font-size: 12px;
            line-height: 1;
            padding: 0 1px;
            transition: opacity 0.1s;
        }
        .role-tag-remove:hover { opacity: 1; }

        .role-error-message {
            color: var(--error-red);
            font-size: 12px;
            margin-top: 5px;
            display: none;
        }

        /* ── TOAST ── */
        .toast-overlay {
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background: rgba(0,0,0,0);
            display: none;
            align-items: flex-start;
            justify-content: center;
            z-index: 9999;
            padding-top: 50px;
        }
        .toast-overlay.show { display: flex; }

        .toast {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.15);
            min-width: 380px;
            max-width: 500px;
            animation: slideDown 0.3s ease-out;
            display: flex;
            align-items: center;
            padding: 14px 18px;
            gap: 12px;
            border-left: 4px solid #2196F3;
        }

        .toast-icon-wrapper {
            width: 24px; height: 24px;
            background: #2196F3;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .toast-icon  { color: white; font-size: 16px; font-weight: bold; font-family: serif; }
        .toast-content { flex: 1; }
        .toast-message { font-size: 15px; color: #333; line-height: 1.4; margin: 0; }

        .toast-close {
            cursor: pointer;
            font-size: 20px;
            color: #999;
            background: none;
            border: none;
            padding: 0;
            width: 20px; height: 20px;
            line-height: 1;
            flex-shrink: 0;
        }
        .toast-close:hover { color: #666; }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-30px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes slideUp {
            from { opacity: 1; transform: translateY(0); }
            to   { opacity: 0; transform: translateY(-30px); }
        }
        .toast.hiding { animation: slideUp 0.2s ease-out; }

        /* ── SUCCESS MODAL ── */
        .msg-overlay {
            display: none;
            position: fixed;
            z-index: 2000;
            left: 0; top: 0;
            width: 100%; height: 100%;
            background-color: rgba(0,0,0,0.5);
            align-items: center;
            justify-content: center;
        }

        .msg-card {
            background: white;
            padding: 40px;
            border-radius: 15px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            width: 90%;
            max-width: 400px;
        }

        .msg-icon        { font-size: 45px; color: var(--success-green); margin-bottom: 15px; display: block; }
        .msg-title       { font-size: 20px; font-weight: bold; color: #3cb554 ; margin-bottom: 20px; }
        .msg-confirm-btn {
            background-color: #3cb554;
            color: white;
            padding: 12px 40px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }

        /* ── CUSTOMER LOOKUP MODAL ── */
        .customer-modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0; top: 0;
            width: 100%; height: 100%;
            background: rgba(0,0,0,0.5);
            align-items: center;
            justify-content: center;
        }

        .customer-modal-content {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            width: 80%;
            max-width: 800px;
            max-height: 80vh;
            overflow-y: auto;
            position: relative;
        }

        .customer-close { position: absolute; right: 15px; top: 10px; font-size: 24px; cursor: pointer; }
        .loading        { opacity: 0.5; pointer-events: none; }
    </style>
</head>
<body>

    <!-- ── Toast Notification ── -->
    <div id="toastOverlay" class="toast-overlay">
        <div id="toast" class="toast">
            <div class="toast-icon-wrapper">
                <span class="toast-icon">i</span>
            </div>
            <div class="toast-content">
                <p class="toast-message" id="toastMessage">Loading...</p>
            </div>
            <button class="toast-close" onclick="hideToast()">&times;</button>
        </div>
    </div>

    <!-- ── Success Popup ── -->
    <div id="statusPopup" class="msg-overlay">
        <div class="msg-card">
            <span class="msg-icon">&#10004;</span>
            <div class="msg-title">User created successfully</div>
            <button class="msg-confirm-btn" onclick="closeStatusPopup()">OK</button>
        </div>
    </div>

    <div class="container">
        <form action="<%=request.getContextPath()%>/Utility/CreateUserServlet" method="post" id="userForm">
            <h2>New User Registration</h2>

            <!-- ── User Details ── -->
            <fieldset>
                <legend>User Details</legend>
                <div class="grid-row-1" style="grid-template-columns: repeat(4, 1fr);">
                    <div class="form-group">
                        <label>User Id</label>
                        <input type="text" id="userId" name="userId"
                               onblur="checkUserId()" oninput="resetUserIdValidation()" required>
                        <span id="userIdMsg" style="font-size:12px;"></span>
                    </div>
                    <div class="form-group">
                        <label>User Name</label>
                        <input type="text" name="userName" required>
                    </div>
                    <div class="form-group">
                        <label>Branch Code</label>
                        <input type="text" name="branchCode" value="<%=sessionBranchCode%>" readonly>
                    </div>
                    <div class="form-group">
                        <label>Branch Name</label>
                        <input type="text" value="<%=branchName%>" readonly>
                    </div>
                </div>
            </fieldset>

            <!-- ── Address Details ── -->
            <fieldset id="addressFieldset">
                <legend>Address Details</legend>
                <div class="grid-row-1">
                    <div class="form-group">
                        <label>Customer ID</label>
                        <div class="input-row">
                            <input type="text" id="customerId" name="custId" readonly>
                            <button type="button" class="search-btn" onclick="openCustomerLookup()">...</button>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Customer Name</label>
                        <input type="text" id="customerName" readonly>
                    </div>
                    <div class="form-group">
                        <label>Employee Code</label>
                        <input type="text" name="empCode">
                    </div>
                    <div class="form-group">
                        <label>Phone</label>
                        <input type="text" id="phone" name="phone" readonly>
                    </div>
                    <div class="form-group">
                        <label>Mobile</label>
                        <input type="text" id="mobile" name="mobile" readonly>
                    </div>
                </div>
                <div class="grid-row-2">
                    <div class="form-group">
                        <label>Address 1</label>
                        <input type="text" id="addr1" name="addr1" readonly>
                    </div>
                    <div class="form-group">
                        <label>Address 2</label>
                        <input type="text" id="addr2" name="addr2" readonly>
                    </div>
                    <div class="form-group">
                        <label>Address 3</label>
                        <input type="text" id="addr3" name="addr3" readonly>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" id="email" name="email" readonly>
                    </div>
                </div>
            </fieldset>

            <!-- ── User Roles ── -->
            <fieldset>
                <legend>User Roles</legend>
                <div class="roles-container">

                    <!-- Dropdown trigger -->
                    <div class="role-dropdown-wrapper">
                        <label>Select Roles <span style="color:red;">*</span></label>

                        <button type="button" class="role-dropdown-btn"
                                id="roleDropdownBtn" onclick="toggleRoleDropdown()">
                            <div class="btn-left-content">
                                <span id="roleDropdownLabel">-- Click to view roles --</span>
                                <span class="role-count-badge" id="roleCountBadge">0</span>
                            </div>
                            <span class="dropdown-arrow">&#9660;</span>
                        </button>

                        <!-- Dropdown panel -->
                        <div class="role-dropdown-panel" id="roleDropdownPanel">
                            <div class="roles-checkbox-grid" id="rolesCheckboxContainer">
                                <div class="no-roles-message">Loading roles...</div>
                            </div>
                            <div class="panel-footer">
                                <button type="button" class="panel-clear-btn" onclick="clearAllRoles()">Clear all</button>
                                <button type="button" class="panel-done-btn"  onclick="closeRoleDropdown()">Done</button>
                            </div>
                        </div>
                    </div>

                    <!-- Selected role tags -->
                    <div>
                        <div class="selected-tags-label" id="selectedTagsLabel">Selected Roles</div>
                        <div class="selected-tags-wrap"  id="selectedTagsWrap"></div>
                        <div class="role-error-message"  id="roleErrorMsg">Please select at least one role</div>
                    </div>

                </div>
            </fieldset>

            <!-- ── Save Button ── -->
            <div style="text-align: center; margin-top: 20px;">
                <input type="submit" value="Save" id="submitBtn"
                       style="padding: 10px 55px; background: #3cb554; color: white;
                              border: none; border-radius: 5px; font-size: 15px; cursor: pointer;">
            </div>

        </form>
    </div>

    <!-- ── Customer Lookup Modal ── -->
    <div id="customerLookupModal" class="customer-modal">
        <div class="customer-modal-content">
            <span class="customer-close" onclick="closeCustomerLookup()">&times;</span>
            <div id="customerLookupContent"></div>
        </div>
    </div>

<script>
    let userIdExists    = false;
    let toastTimeout;
    let rolesLoaded     = false;
    let selectedRoleIds = new Set();

    // ── Popup status written by JSP from session at render time ──
    var POPUP_STATUS = '<%=popupStatus%>';
    var POPUP_MSG    = '<%=popupMsg%>';

    window.onload = function () {
        if (POPUP_STATUS === 'success') {
            document.getElementById('statusPopup').style.display = 'flex';
        } else if (POPUP_STATUS === 'error' && POPUP_MSG) {
            showToast(POPUP_MSG);
        }
        loadAllRoles();
    };

    // ── Popup ──
    function closeStatusPopup() {
        document.getElementById('statusPopup').style.display = 'none';
        window.location.href = '<%=request.getContextPath()%>/Utility/NewUser.jsp';
    }

    // ── Toast ──
    function showToast(message) {
        const overlay = document.getElementById('toastOverlay');
        const toast   = document.getElementById('toast');
        document.getElementById('toastMessage').textContent = message;
        toast.classList.remove('hiding');
        overlay.classList.add('show');
        clearTimeout(toastTimeout);
        toastTimeout = setTimeout(() => hideToast(), 5000);
    }

    function hideToast() {
        const overlay = document.getElementById('toastOverlay');
        const toast   = document.getElementById('toast');
        toast.classList.add('hiding');
        setTimeout(() => {
            overlay.classList.remove('show');
            toast.classList.remove('hiding');
        }, 200);
    }

    // ── Roles Dropdown ──
    function toggleRoleDropdown() {
        const panel = document.getElementById('roleDropdownPanel');
        const btn   = document.getElementById('roleDropdownBtn');
        if (panel.classList.contains('open')) {
            closeRoleDropdown();
        } else {
            positionPanel();
            panel.classList.add('open');
            btn.classList.add('open');
        }
    }

    function positionPanel() {
        const btn    = document.getElementById('roleDropdownBtn');
        const rect   = btn.getBoundingClientRect();
        const needed = rect.bottom + 480 + 16;
        if (needed > window.innerHeight) {
            window.scrollBy({ top: needed - window.innerHeight + 20, behavior: 'smooth' });
        }
    }

    function closeRoleDropdown() {
        document.getElementById('roleDropdownPanel').classList.remove('open');
        document.getElementById('roleDropdownBtn').classList.remove('open');
    }

    // Close panel when clicking outside
    document.addEventListener('click', function (e) {
        const wrapper = document.querySelector('.role-dropdown-wrapper');
        if (wrapper && !wrapper.contains(e.target)) {
            closeRoleDropdown();
        }
    });

    // ── Load Roles from DB ──
    function loadAllRoles() {
        if (rolesLoaded) return;

        const container = document.getElementById('rolesCheckboxContainer');
        container.innerHTML = '<div class="no-roles-message">Loading roles...</div>';

        fetch('<%=request.getContextPath()%>/Utility/NewUser.jsp?action=getRoles')
            .then(res => {
                if (!res.ok) throw new Error('Status ' + res.status);
                return res.text();
            })
            .then(text => {
                const data = JSON.parse(text);
                if (data.success && data.roles && data.roles.length > 0) {
                    renderRolesGrid(data.roles);
                    rolesLoaded = true;
                } else {
                    container.innerHTML = '<div class="no-roles-message">No roles available.</div>';
                }
            })
            .catch(err => {
                container.innerHTML =
                    '<div class="no-roles-message" style="color:red;">Failed to load roles: ' + err.message + '</div>';
            });
    }

    function renderRolesGrid(roles) {
        const container = document.getElementById('rolesCheckboxContainer');
        let html = '';

        roles.forEach(function (role) {
            const isChecked = selectedRoleIds.has(String(role.id));
            const roleName  = role.name || 'Role ' + role.id;

            html += '<div class="role-checkbox-item' + (isChecked ? ' checked' : '') + '"'
                  + ' onclick="toggleRoleItem(event,' + role.id + ',\'' + roleName.replace(/'/g, "\\'") + '\')">';
            html += '<input type="checkbox" id="role_' + role.id + '" name="roles" value="' + role.id + '"'
                  + (isChecked ? ' checked' : '') + '>';
            html += '<label for="role_' + role.id + '">' + roleName + '</label>';
            html += '</div>';
        });

        container.innerHTML = html;
    }

    function toggleRoleItem(e, roleId, roleName) {
        e.stopPropagation();
        const id = String(roleId);

        if (selectedRoleIds.has(id)) {
            selectedRoleIds.delete(id);
        } else {
            selectedRoleIds.add(id);
        }

        const checkbox = document.getElementById('role_' + roleId);
        const item     = checkbox ? checkbox.closest('.role-checkbox-item') : null;

        if (checkbox) checkbox.checked = selectedRoleIds.has(id);
        if (item)     item.classList.toggle('checked', selectedRoleIds.has(id));

        updateBadge();
        renderSelectedTags();
        clearRoleError();
    }

    function updateBadge() {
        const badge = document.getElementById('roleCountBadge');
        const label = document.getElementById('roleDropdownLabel');

        if (selectedRoleIds.size > 0) {
            badge.textContent = selectedRoleIds.size;
            badge.classList.add('visible');
            label.textContent = 'Roles selected';
        } else {
            badge.classList.remove('visible');
            label.textContent = '-- Click to view roles --';
        }
    }

    function renderSelectedTags() {
        const wrap  = document.getElementById('selectedTagsWrap');
        const label = document.getElementById('selectedTagsLabel');

        if (selectedRoleIds.size === 0) {
            wrap.innerHTML = '';
            label.classList.remove('visible');
            return;
        }

        label.classList.add('visible');
        let html = '';

        selectedRoleIds.forEach(function (id) {
            const checkbox = document.getElementById('role_' + id);
            const roleName = checkbox ? checkbox.nextElementSibling.textContent : 'Role ' + id;
            html += '<span class="role-tag">'
                  + roleName
                  + '<button type="button" class="role-tag-remove" onclick="removeTagRole(' + id + ')">&#x2715;</button>'
                  + '</span>';
        });

        wrap.innerHTML = html;
    }

    function removeTagRole(roleId) {
        const id       = String(roleId);
        const checkbox = document.getElementById('role_' + roleId);
        const item     = checkbox ? checkbox.closest('.role-checkbox-item') : null;

        selectedRoleIds.delete(id);
        if (checkbox) checkbox.checked = false;
        if (item)     item.classList.remove('checked');

        updateBadge();
        renderSelectedTags();
    }

    function clearAllRoles() {
        selectedRoleIds.clear();
        document.querySelectorAll('input[name="roles"]').forEach(function (cb) {
            cb.checked = false;
            const item = cb.closest('.role-checkbox-item');
            if (item) item.classList.remove('checked');
        });
        updateBadge();
        renderSelectedTags();
    }

    function clearRoleError() {
        if (selectedRoleIds.size > 0) {
            document.getElementById('roleDropdownBtn').classList.remove('error-border');
            document.getElementById('roleErrorMsg').style.display = 'none';
        }
    }

    // ── User ID Validation ──
    function checkUserId() {
        const userIdInput = document.getElementById('userId');
        const userId      = userIdInput.value.trim();
        const userIdMsg   = document.getElementById('userIdMsg');

        if (!userId) {
            userIdMsg.textContent = '';
            userIdInput.classList.remove('error', 'success');
            userIdExists = false;
            return;
        }

        fetch('<%=request.getContextPath()%>/Utility/NewUser.jsp?action=checkUserId&userId=' + encodeURIComponent(userId))
            .then(res => res.text())
            .then(text => {
                const data = JSON.parse(text);
                if (data.error) {
                    showToast(data.message);
                    userIdMsg.textContent = '';
                    userIdInput.classList.remove('error', 'success');
                    userIdExists = false;
                } else if (data.exists) {
                    showToast(data.message);
                    userIdMsg.textContent   = 'User ID already exists';
                    userIdMsg.style.color   = '#dc3545';
                    userIdInput.classList.add('error');
                    userIdInput.classList.remove('success');
                    userIdExists = true;
                } else {
                    userIdMsg.textContent = '';
                    userIdInput.classList.remove('error', 'success');
                    userIdExists = false;
                }
            })
            .catch(() => {
                showToast('Failed to check user ID availability');
                userIdExists = false;
            });
    }

    function resetUserIdValidation() {
        document.getElementById('userIdMsg').textContent = '';
        document.getElementById('userId').classList.remove('error', 'success');
        userIdExists = false;
    }

    // ── Form Submit Validation ──
    document.getElementById('userForm').addEventListener('submit', function (e) {
        if (userIdExists) {
            e.preventDefault();
            showToast('User ID already exists. Please choose a different User ID.');
            document.getElementById('userId').focus();
            return false;
        }

        if (selectedRoleIds.size === 0) {
            e.preventDefault();
            document.getElementById('roleDropdownBtn').classList.add('error-border');
            document.getElementById('roleErrorMsg').style.display = 'block';
            showToast('Please select at least one role for the user');
            document.getElementById('roleDropdownBtn').scrollIntoView({ behavior: 'smooth', block: 'center' });
            return false;
        }

        document.getElementById('roleDropdownBtn').classList.remove('error-border');
        document.getElementById('roleErrorMsg').style.display = 'none';
    });

    // ── Customer Lookup ──
    window.setCustomerData = function (customerId, customerName, categoryCode, riskCategory) {
        document.getElementById('customerId').value    = customerId;
        document.getElementById('customerName').value  = customerName || '';
        closeCustomerLookup();
        fetchCustomerDetails(customerId);
    };

    function fetchCustomerDetails(customerId) {
        const fieldset = document.getElementById('addressFieldset');
        if (fieldset) fieldset.classList.add('loading');

        fetch('<%=request.getContextPath()%>/OpenAccount/getCustomerDetails.jsp?customerId=' + encodeURIComponent(customerId))
            .then(res => res.json())
            .then(data => {
                if (data.success && data.customer) {
                    const c = data.customer;
                    document.getElementById('phone').value  = c.residencePhone || '';
                    document.getElementById('mobile').value = c.mobileNo       || '';
                    document.getElementById('addr1').value  = c.address1       || '';
                    document.getElementById('addr2').value  = c.address2       || '';
                    document.getElementById('addr3').value  = c.address3       || '';
                    document.getElementById('email').value  = c.email          || '';
                }
            })
            .finally(() => fieldset.classList.remove('loading'));
    }

    function openCustomerLookup() {
        document.getElementById('customerLookupModal').style.display = 'flex';
        fetch('<%=request.getContextPath()%>/OpenAccount/lookupForCustomerId.jsp')
            .then(res => res.text())
            .then(html => {
                document.getElementById('customerLookupContent').innerHTML = html;
                document.getElementById('customerLookupContent')
                    .querySelectorAll('script')
                    .forEach(s => {
                        const ns = document.createElement('script');
                        ns.textContent = s.textContent;
                        document.body.appendChild(ns);
                        document.body.removeChild(ns);
                    });
            });
    }

    function closeCustomerLookup() {
        document.getElementById('customerLookupModal').style.display = 'none';
    }
</script>

</body>
</html>
