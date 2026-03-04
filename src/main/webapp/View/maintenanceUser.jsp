<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, db.DBConnection" %>

<%
String sessionBranchCode = (String) session.getAttribute("branchCode");
String sessionUserId     = (String) session.getAttribute("userId");   // logged-in editor
if (sessionBranchCode == null || sessionBranchCode.isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}

String userId = request.getParameter("userId");
if (userId == null || userId.trim().isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/View/allUsersMaintenance.jsp");
    return;
}

String saveMsg = "";
String saveErr = "";

// ── SAVE POST ─────────────────────────────────────────────────────────────────
if ("POST".equals(request.getMethod())) {
    String newName   = request.getParameter("name")   != null ? request.getParameter("name").trim()   : "";
    String newEmail  = request.getParameter("email")  != null ? request.getParameter("email").trim()  : "";
    String newMobile = request.getParameter("mobile") != null ? request.getParameter("mobile").trim() : "";
    String newPhone  = request.getParameter("phone")  != null ? request.getParameter("phone").trim()  : "";
    String newAddr1  = request.getParameter("addr1")  != null ? request.getParameter("addr1").trim()  : "";
    String newAddr2  = request.getParameter("addr2")  != null ? request.getParameter("addr2").trim()  : "";
    String newAddr3  = request.getParameter("addr3")  != null ? request.getParameter("addr3").trim()  : "";
    String[] selectedRoles = request.getParameterValues("selectedRoles");

    Connection ct = null;
    try {
        ct = DBConnection.getConnection();
        ct.setAutoCommit(false);

        // 1. Update USERREGISTER fields + set STATUS='E' + CREATED_BY = logged-in editor
        String editorId = sessionUserId != null ? sessionUserId.trim() : userId.trim();
        PreparedStatement ps1 = ct.prepareStatement(
            "UPDATE ACL.USERREGISTER SET NAME=?, EMAILADDRESS=?, MOBILE_NUMBER=?, " +
            "PHONE_NUMBER=?, CURRENTADDRESS1=?, CURRENTADDRESS2=?, CURRENTADDRESS3=?, " +
            "STATUS=?, CREATED_BY=? WHERE USER_ID=?"
        );
        ps1.setString(1, newName);
        ps1.setString(2, newEmail);
        ps1.setString(3, newMobile);
        ps1.setString(4, newPhone);
        ps1.setString(5, newAddr1);
        ps1.setString(6, newAddr2);
        ps1.setString(7, newAddr3);
        ps1.setString(8, "E");
        ps1.setString(9, editorId);   // CREATED_BY = logged-in editor
        ps1.setString(10, userId.trim());
        ps1.executeUpdate();
        ps1.close();

        // 2. Delete all existing pending roles for this user from USERPENDINGROLES
        PreparedStatement psDel = ct.prepareStatement(
            "DELETE FROM ACL.USERPENDINGROLES WHERE USER_ID = ?"
        );
        psDel.setString(1, userId.trim());
        psDel.executeUpdate();
        psDel.close();

        // 3. Get BRANCH_CODE for this user (needed for USERPENDINGROLES)
        String branchCodeForPending = sessionBranchCode;
        PreparedStatement psBr = ct.prepareStatement(
            "SELECT BRANCH_CODE FROM ACL.USERREGISTER WHERE USER_ID = ?"
        );
        psBr.setString(1, userId.trim());
        ResultSet rsBr = psBr.executeQuery();
        if (rsBr.next() && rsBr.getString("BRANCH_CODE") != null) {
            branchCodeForPending = rsBr.getString("BRANCH_CODE");
        }
        rsBr.close();
        psBr.close();

        // 4. Insert new pending roles into USERPENDINGROLES with STATUS = 'P'
        if (selectedRoles != null && selectedRoles.length > 0) {
            java.sql.Timestamp now = new java.sql.Timestamp(System.currentTimeMillis());
            for (String roleName : selectedRoles) {
                if (roleName == null || roleName.trim().isEmpty()) continue;
                // Look up MAINROLE_ID
                PreparedStatement psRid = ct.prepareStatement(
                    "SELECT MAINROLE_ID FROM ACL.MAINROLEREGISTER WHERE MAINROLE = ?"
                );
                psRid.setString(1, roleName.trim());
                ResultSet rsRid = psRid.executeQuery();
                if (rsRid.next()) {
                    String mainRoleId = rsRid.getString("MAINROLE_ID");
                    PreparedStatement psIns = ct.prepareStatement(
                        "INSERT INTO ACL.USERPENDINGROLES " +
                        "(USER_ID, MAINROLE_ID, BRANCH_CODE, STATUS, CREATED_BY, CREATED_DATE) " +
                        "VALUES (?, ?, ?, 'P', ?, ?)"
                    );
                    psIns.setString(1, userId.trim());
                    psIns.setString(2, mainRoleId);
                    psIns.setString(3, branchCodeForPending);
                    psIns.setString(4, editorId); // CREATED_BY = logged-in editor
                    psIns.setTimestamp(5, now);
                    psIns.executeUpdate();
                    psIns.close();
                }
                rsRid.close();
                psRid.close();
            }
        }

        ct.commit();
        saveMsg = "User updated successfully! Roles are pending authorization.";

    } catch (Exception e) {
        if (ct != null) { try { ct.rollback(); } catch (Exception ignored) {} }
        saveErr = "Update failed: " + e.getMessage();
    } finally {
        if (ct != null) { try { ct.setAutoCommit(true); ct.close(); } catch (Exception ignored) {} }
    }
}

// ── FETCH USER ────────────────────────────────────────────────────────────────
String dbUserId     = "";
String dbName       = "";
String dbBranchCode = "";
String dbEmail      = "";
String dbMobile     = "";
String dbPhone      = "";
String dbCustId     = "";
String dbEmpCode    = "";
String dbAddr1      = "";
String dbAddr2      = "";
String dbAddr3      = "";

Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
try {
    conn = DBConnection.getConnection();
    if (conn != null) {
        pstmt = conn.prepareStatement(
            "SELECT USER_ID, NAME, BRANCH_CODE, EMAILADDRESS, MOBILE_NUMBER, PHONE_NUMBER, " +
            "CUSTOMER_ID, EMPLOYEE_CODE, CURRENTADDRESS1, CURRENTADDRESS2, CURRENTADDRESS3 " +
            "FROM ACL.USERREGISTER WHERE USER_ID = ?"
        );
        pstmt.setString(1, userId.trim());
        rs = pstmt.executeQuery();
        if (rs.next()) {
            dbUserId     = rs.getString("USER_ID")         != null ? rs.getString("USER_ID")         : "";
            dbName       = rs.getString("NAME")            != null ? rs.getString("NAME")            : "";
            dbBranchCode = rs.getString("BRANCH_CODE")     != null ? rs.getString("BRANCH_CODE")     : "";
            dbEmail      = rs.getString("EMAILADDRESS")    != null ? rs.getString("EMAILADDRESS")    : "";
            dbMobile     = rs.getString("MOBILE_NUMBER")   != null ? rs.getString("MOBILE_NUMBER")   : "";
            dbPhone      = rs.getString("PHONE_NUMBER")    != null ? rs.getString("PHONE_NUMBER")    : "";
            dbCustId     = rs.getString("CUSTOMER_ID")     != null ? rs.getString("CUSTOMER_ID")     : "";
            dbEmpCode    = rs.getString("EMPLOYEE_CODE")   != null ? rs.getString("EMPLOYEE_CODE")   : "";
            dbAddr1      = rs.getString("CURRENTADDRESS1") != null ? rs.getString("CURRENTADDRESS1") : "";
            dbAddr2      = rs.getString("CURRENTADDRESS2") != null ? rs.getString("CURRENTADDRESS2") : "";
            dbAddr3      = rs.getString("CURRENTADDRESS3") != null ? rs.getString("CURRENTADDRESS3") : "";
        }
    }
} catch (Exception e) {
} finally {
    try { if (rs != null) rs.close(); } catch (Exception ignored) {}
    try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
    try { if (conn != null) conn.close(); } catch (Exception ignored) {}
}

// ── FETCH BRANCH NAME ─────────────────────────────────────────────────────────
String dbBranchName = "";
if (!dbBranchCode.isEmpty()) {
    Connection c = null; PreparedStatement p = null; ResultSet r = null;
    try {
        c = DBConnection.getConnection();
        p = c.prepareStatement("SELECT NAME FROM HEADOFFICE.BRANCH WHERE BRANCH_CODE = ?");
        p.setString(1, dbBranchCode);
        r = p.executeQuery();
        if (r.next()) dbBranchName = r.getString("NAME") != null ? r.getString("NAME") : "";
    } catch (Exception e) {
    } finally {
        try { if (r != null) r.close(); } catch (Exception ignored) {}
        try { if (p != null) p.close(); } catch (Exception ignored) {}
        try { if (c != null) c.close(); } catch (Exception ignored) {}
    }
}

// ── FETCH CUSTOMER NAME ───────────────────────────────────────────────────────
String dbCustName = "";
if (!dbCustId.isEmpty()) {
    Connection c = null; PreparedStatement p = null; ResultSet r = null;
    try {
        c = DBConnection.getConnection();
        p = c.prepareStatement("SELECT NAME FROM HEADOFFICE.CUSTOMER WHERE CUST_ID = ?");
        p.setString(1, dbCustId);
        r = p.executeQuery();
        if (r.next()) dbCustName = r.getString("NAME") != null ? r.getString("NAME") : "";
    } catch (Exception e) {
    } finally {
        try { if (r != null) r.close(); } catch (Exception ignored) {}
        try { if (p != null) p.close(); } catch (Exception ignored) {}
        try { if (c != null) c.close(); } catch (Exception ignored) {}
    }
}

// ── FETCH ASSIGNED ROLES ──────────────────────────────────────────────────────
java.util.List<String> userRoles = new java.util.ArrayList<>();
Connection cr = null; PreparedStatement pr = null; ResultSet rr = null;
try {
    cr = DBConnection.getConnection();
    if (cr != null) {
        pr = cr.prepareStatement(
            "SELECT M.MAINROLE FROM ACL.USERMAINROLE UR " +
            "JOIN ACL.MAINROLEREGISTER M ON UR.MAINROLE_ID = M.MAINROLE_ID " +
            "WHERE UR.USER_ID = ? ORDER BY M.MAINROLE"
        );
        pr.setString(1, userId.trim());
        rr = pr.executeQuery();
        while (rr.next()) { String role = rr.getString("MAINROLE"); if (role != null) userRoles.add(role); }
    }
} catch (Exception e) {
} finally {
    try { if (rr != null) rr.close(); } catch (Exception ignored) {}
    try { if (pr != null) pr.close(); } catch (Exception ignored) {}
    try { if (cr != null) cr.close(); } catch (Exception ignored) {}
}

// ── FETCH ALL AVAILABLE ROLES ─────────────────────────────────────────────────
java.util.List<String> allRoles = new java.util.ArrayList<>();
Connection car = null; PreparedStatement par = null; ResultSet rar = null;
try {
    car = DBConnection.getConnection();
    if (car != null) {
        par = car.prepareStatement("SELECT MAINROLE FROM ACL.MAINROLEREGISTER ORDER BY MAINROLE");
        rar = par.executeQuery();
        while (rar.next()) { String role = rar.getString("MAINROLE"); if (role != null) allRoles.add(role); }
    }
} catch (Exception e) {
} finally {
    try { if (rar != null) rar.close(); } catch (Exception ignored) {}
    try { if (par != null) par.close(); } catch (Exception ignored) {}
    try { if (car != null) car.close(); } catch (Exception ignored) {}
}

java.util.function.Function<String, String> esc = s ->
    s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit User - <%=esc.apply(dbUserId)%></title>
    <link rel="stylesheet" href="../css/totalCustomers.css">
    <style>
        :root { --bg: #E6E6FA; --navy: #2b0d73; --border: #B8B8E6; --ro-bg: #E0E0E0; --edit-bg: #fff; }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; background: var(--bg); padding: 20px 20px 60px; }
        .container { max-width: 1400px; margin: auto; }
        h2 { text-align: center; color: var(--navy); font-size: 22px; font-weight: bold; margin-bottom: 18px; }

        fieldset { border: 1.5px solid var(--border); border-radius: 8px; margin-bottom: 22px; padding: 18px; }
        legend { color: var(--navy); font-weight: bold; font-size: 15px; padding: 0 10px; background: var(--bg); }

        .grid-4 { display: grid; grid-template-columns: repeat(4,1fr); gap: 15px; align-items: end; }
        .grid-5 { display: grid; grid-template-columns: repeat(5,1fr); gap: 15px; margin-bottom: 15px; align-items: end; }

        .form-group label { display: block; font-size: 13px; font-weight: bold; color: var(--navy); margin-bottom: 4px; }
        .form-group input {
            width: 100%; padding: 7px; border: 1px solid var(--border);
            border-radius: 4px; font-size: 13px; color: #444;
            background: var(--ro-bg);
        }
        .form-group input.editable {
            background: var(--edit-bg); border-color: var(--navy); color: #222;
        }
        .form-group input.editable:focus {
            outline: none; box-shadow: 0 0 0 2px rgba(43,13,115,0.2);
        }

        /* ── Assigned role tags ── */
        .roles-label { font-size: 13px; font-weight: bold; color: var(--navy); margin-bottom: 10px; display: block; }
        .roles-wrap  { display: flex; flex-wrap: wrap; gap: 8px; min-height: 36px; align-items: center; margin-bottom: 14px; }
        .role-tag {
            display: inline-flex; align-items: center; gap: 7px;
            background: #eef0fb; color: var(--navy);
            font-size: 12px; font-weight: bold;
            padding: 6px 10px 6px 14px; border-radius: 20px; border: 1px solid #c5caee;
        }
        .x-btn {
            width: 18px; height: 18px; background: var(--navy); color: white;
            border: none; border-radius: 50%; font-size: 10px; font-weight: bold;
            cursor: pointer; display: flex; align-items: center; justify-content: center;
            transition: background 0.2s; flex-shrink: 0;
        }
        .x-btn:hover { background: #c0392b; }
        .no-roles { font-size: 13px; color: #999; font-style: italic; }
        .roles-divider { border: none; border-top: 1px dashed var(--border); margin: 14px 0; }

        /* ── Checkbox dropdown ── */
        .custom-select-wrapper { position: relative; width: 240px; }
        .custom-select-trigger {
            height: 36px; padding: 0 12px;
            border: 1.5px solid #b0b0d8; border-radius: 5px;
            font-family: Arial, sans-serif; font-size: 13px; font-weight: 400;
            color: #666; background: #fff; cursor: pointer;
            display: flex; align-items: center; justify-content: space-between; user-select: none;
        }
        .custom-select-trigger:hover { border-color: var(--navy); }
        .custom-select-trigger .arrow { font-size: 10px; color: #555; transition: transform 0.2s; }
        .custom-select-trigger.open .arrow { transform: rotate(180deg); }

        .checkbox-dropdown {
            display: none; position: absolute; top: 42px; left: 0;
            background: #ffffff; border: 1px solid #d0d0e8;
            border-radius: 10px; box-shadow: 0 6px 22px rgba(43,13,115,0.13);
            z-index: 9999; width: 530px; padding: 14px 14px 0 14px;
        }
        .checkbox-dropdown.open { display: block; }

        .checkbox-grid {
            display: grid; grid-template-columns: repeat(3,1fr);
            gap: 8px; max-height: 310px; overflow-y: auto; padding-bottom: 4px;
        }
        .checkbox-grid::-webkit-scrollbar { width: 5px; }
        .checkbox-grid::-webkit-scrollbar-track { background: #f0f0f8; border-radius: 4px; }
        .checkbox-grid::-webkit-scrollbar-thumb { background: #c5c5e0; border-radius: 4px; }

        .checkbox-item {
            display: flex; align-items: center; gap: 9px;
            padding: 9px 11px; background: #ffffff;
            border: 1.2px solid #d4d4ec; border-radius: 7px; cursor: pointer;
            font-family: Arial, sans-serif; font-size: 13px; font-weight: 400;
            color: #333333; letter-spacing: 0.3px;
            transition: background 0.12s, border-color 0.12s; user-select: none;
        }
        .checkbox-item:hover { background: #f4f4fd; border-color: #a0a0cc; }
        .checkbox-item.checked { background: #eeeef8; border-color: #5252b0; }
        .checkbox-item input[type=checkbox] {
            accent-color: #2b0d73; width: 15px; height: 15px;
            cursor: pointer; flex-shrink: 0; pointer-events: none;
        }

        .dropdown-footer {
            display: flex; justify-content: space-between; align-items: center;
            padding: 10px 2px; border-top: 1px solid #e0e0f0; margin-top: 10px;
        }
        .btn-clear-all {
            background: none; border: none; color: #888;
            font-size: 13px; font-weight: 400; font-family: Arial, sans-serif; cursor: pointer;
        }
        .btn-clear-all:hover { color: #c0392b; text-decoration: underline; }
        .btn-done {
            background: #1a1a5e; color: #ffffff; border: none;
            border-radius: 5px; padding: 7px 28px;
            font-family: Arial, sans-serif; font-size: 13px; font-weight: 600; cursor: pointer;
        }
        .btn-done:hover { background: #111147; }

        /* ── Action buttons ── */
        .btn-row { display: flex; justify-content: center; gap: 14px; margin-top: 20px; }
        .btn-save {
            padding: 10px 34px; background: #3cb554; color: white;
            border: none; border-radius: 5px; font-size: 15px; font-weight: bold; cursor: pointer;
        }
        .btn-save:hover { background: #3cb554; }
        .btn-cancel {
            padding: 10px 34px; background: #888; color: white;
            border: none; border-radius: 5px; font-size: 15px; font-weight: bold; cursor: pointer;
        }
        .btn-cancel:hover { background: #666; }

        /* ── Popup modal ── */
        .modal-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(0,0,0,0.45); z-index: 99999;
            align-items: center; justify-content: center;
        }
        .modal-overlay.show { display: flex; }
        .modal-box {
            background: #fff; border-radius: 20px;
            padding: 50px 50px 40px; max-width: 420px; width: 90%;
            text-align: center;
            box-shadow: 0 10px 40px rgba(0,0,0,0.18);
            animation: popIn 0.22s ease;
        }
        @keyframes popIn {
            from { transform: scale(0.85); opacity: 0; }
            to   { transform: scale(1);    opacity: 1; }
        }
        .modal-check {
            display: block; margin: 0 auto 18px auto;
            width: 64px; height: 64px;
        }
        .modal-title {
            font-size: 22px; font-weight: 800; color: var(--navy);
            margin-bottom: 28px; line-height: 1.3;
        }
        .modal-btn-ok {
            padding: 13px 60px; border: none; border-radius: 50px;
            font-size: 16px; font-weight: 700; cursor: pointer;
            font-family: Arial, sans-serif; letter-spacing: 0.5px;
            background: #3cb554; color: #fff;
            transition: background 0.2s;
        }
        .modal-btn-ok:hover { background: #3cb554 ; }
        .modal-btn-err {
            padding: 13px 60px; border: none; border-radius: 50px;
            font-size: 16px; font-weight: 700; cursor: pointer;
            font-family: Arial, sans-serif; letter-spacing: 0.5px;
            background: #c0392b; color: #fff;
            transition: background 0.2s;
        }
        .modal-btn-err:hover { background: #a93226; }
        .modal-err-icon {
            display: block; font-size: 52px; color: #c0392b;
            margin-bottom: 14px; line-height: 1;
        }
        .modal-err-msg { font-size: 13px; color: #666; margin-bottom: 24px; line-height: 1.5; }
    </style>
</head>
<body>
<div class="container">

    <h2>Edit User Details</h2>

    <!-- Success Modal -->
    <% if (!saveMsg.isEmpty()) { %>
    <div class="modal-overlay show" id="successModal">
        <div class="modal-box">
            <svg class="modal-check" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="32" cy="32" r="32" fill="none"/>
                <polyline points="14,34 26,46 50,20"
                    stroke="#28a745" stroke-width="6"
                    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
            </svg>
            <div class="modal-title">User updated successfully</div>
            <div class="modal-userid">User ID: <span><%=esc.apply(dbUserId)%></span></div>
            <button class="modal-btn-ok" onclick="document.getElementById('successModal').classList.remove('show')">OK</button>
        </div>
    </div>
    <% } %>

    <!-- Error Modal -->
    <% if (!saveErr.isEmpty()) { %>
    <div class="modal-overlay show" id="errorModal">
        <div class="modal-box">
            <span class="modal-err-icon">&#10008;</span>
            <div class="modal-title">Update Failed</div>
            <div class="modal-err-msg"><%=esc.apply(saveErr)%></div>
            <button class="modal-btn-err" onclick="document.getElementById('errorModal').classList.remove('show')">OK</button>
        </div>
    </div>
    <% } %>

    <form method="post" action="?userId=<%=esc.apply(dbUserId)%>" id="mainForm">

        <div id="hiddenRolesContainer"></div>

        <!-- User Details -->
        <fieldset>
            <legend>User Details</legend>
            <div class="grid-4">
                <div class="form-group">
                    <label>User Id</label>
                    <input type="text" value="<%=esc.apply(dbUserId)%>" readonly>
                </div>
                <div class="form-group">
                    <label>User Name <span style="color:#c0392b;">*</span></label>
                    <input type="text" name="name" value="<%=esc.apply(dbName)%>" class="editable" required>
                </div>
                <div class="form-group">
                    <label>Branch Code</label>
                    <input type="text" value="<%=esc.apply(dbBranchCode)%>" readonly>
                </div>
                <div class="form-group">
                    <label>Branch Name</label>
                    <input type="text" value="<%=esc.apply(dbBranchName)%>" readonly>
                </div>
            </div>
        </fieldset>

        <!-- Address Details -->
        <fieldset>
            <legend>Address Details</legend>
            <div class="grid-5">
                <div class="form-group">
                    <label>Customer ID</label>
                    <input type="text" value="<%=esc.apply(dbCustId)%>" readonly>
                </div>
                <div class="form-group">
                    <label>Customer Name</label>
                    <input type="text" value="<%=esc.apply(dbCustName)%>" readonly>
                </div>
                <div class="form-group">
                    <label>Employee Code</label>
                    <input type="text" value="<%=esc.apply(dbEmpCode)%>" readonly>
                </div>
                <div class="form-group">
                    <label>Phone</label>
                    <input type="text" name="phone" value="<%=esc.apply(dbPhone)%>" class="editable">
                </div>
                <div class="form-group">
                    <label>Mobile</label>
                    <input type="text" name="mobile" value="<%=esc.apply(dbMobile)%>" class="editable">
                </div>
            </div>
            <div class="grid-4">
                <div class="form-group">
                    <label>Address 1</label>
                    <input type="text" name="addr1" value="<%=esc.apply(dbAddr1)%>" class="editable">
                </div>
                <div class="form-group">
                    <label>Address 2</label>
                    <input type="text" name="addr2" value="<%=esc.apply(dbAddr2)%>" class="editable">
                </div>
                <div class="form-group">
                    <label>Address 3</label>
                    <input type="text" name="addr3" value="<%=esc.apply(dbAddr3)%>" class="editable">
                </div>
                <div class="form-group">
                    <label>Email</label>
                    <input type="text" name="email" value="<%=esc.apply(dbEmail)%>" class="editable">
                </div>
            </div>
        </fieldset>

        <!-- User Roles -->
        <fieldset>
            <legend>User Roles</legend>
            <span class="roles-label">Assigned Roles</span>

            <div class="roles-wrap" id="rolesWrap">
                <% if (userRoles.isEmpty()) { %>
                <span class="no-roles" id="noRolesMsg">No roles assigned</span>
                <% } else { for (String role : userRoles) { %>
                <span class="role-tag" data-role="<%=esc.apply(role)%>">
                    <%=esc.apply(role)%>
                    <button type="button" class="x-btn" onclick="removeRole(this,'<%=esc.apply(role)%>')">&#10005;</button>
                </span>
                <% } } %>
            </div>

            <hr class="roles-divider">

            <div style="display:flex; align-items:center; gap:12px;">
                <label style="font-size:13px;font-weight:bold;color:var(--navy);white-space:nowrap;">
                    Select Roles <span style="color:#c0392b;">*</span>
                </label>
                <div class="custom-select-wrapper" id="selectWrapper">
                    <div class="custom-select-trigger" id="dropdownTrigger" onclick="toggleDropdown(event)">
                        <span>-- Click to view roles --</span>
                        <span class="arrow">&#9650;</span>
                    </div>
                    <div class="checkbox-dropdown" id="checkboxDropdown">
                        <div class="checkbox-grid" id="checkboxGrid">
                            <%
                            for (String ar : allRoles) {
                                boolean isAssigned = userRoles.contains(ar);
                                String safeId = "chk_" + ar.replace(" ","_").replace("/","_");
                            %>
                            <label class="checkbox-item <%=isAssigned ? "checked" : ""%>"
                                   id="item_<%=safeId%>"
                                   onclick="handleItemClick(event, this, '<%=esc.apply(ar)%>')">
                                <input type="checkbox" id="<%=safeId%>"
                                       value="<%=esc.apply(ar)%>" <%=isAssigned ? "checked" : ""%>>
                                <%=esc.apply(ar)%>
                            </label>
                            <% } %>
                        </div>
                        <div class="dropdown-footer">
                            <button type="button" class="btn-clear-all" onclick="clearAllRoles()">Clear all</button>
                            <button type="button" class="btn-done"      onclick="closeDropdown()">Done</button>
                        </div>
                    </div>
                </div>
            </div>
        </fieldset>

        <!-- Buttons -->
        <div class="btn-row">
            <button type="submit" class="btn-save" onclick="prepareRoles()">&#10003; Save</button>
            <button type="button" class="btn-cancel" onclick="goBack()">&#10005; Cancel</button>
        </div>

    </form>
</div>

<script>
// ── Dropdown open/close ──────────────────────────────────────────────────────
var dropdownOpen = false;

function toggleDropdown(e) {
    if (e) e.stopPropagation();
    dropdownOpen ? closeDropdown() : openDropdown();
}
function openDropdown() {
    dropdownOpen = true;
    document.getElementById('checkboxDropdown').classList.add('open');
    document.getElementById('dropdownTrigger').classList.add('open');
}
function closeDropdown() {
    dropdownOpen = false;
    document.getElementById('checkboxDropdown').classList.remove('open');
    document.getElementById('dropdownTrigger').classList.remove('open');
}
document.addEventListener('click', function(e) {
    var wrapper = document.getElementById('selectWrapper');
    if (wrapper && !wrapper.contains(e.target)) closeDropdown();
});

// ── Checkbox item click ──────────────────────────────────────────────────────
function handleItemClick(e, labelEl, roleName) {
    e.preventDefault();
    var chk = labelEl.querySelector('input[type=checkbox]');
    var nowChecked = !chk.checked;
    chk.checked = nowChecked;
    if (nowChecked) {
        labelEl.classList.add('checked');
        addRoleTag(roleName);
    } else {
        labelEl.classList.remove('checked');
        removeRoleTagByName(roleName);
    }
}

// ── Role tags ────────────────────────────────────────────────────────────────
function addRoleTag(roleName) {
    var wrap = document.getElementById('rolesWrap');
    if (!wrap) return;
    var existing = wrap.querySelectorAll('.role-tag');
    for (var i = 0; i < existing.length; i++) {
        if (existing[i].getAttribute('data-role') === roleName) return;
    }
    var noMsg = document.getElementById('noRolesMsg');
    if (noMsg) noMsg.remove();

    var span = document.createElement('span');
    span.className = 'role-tag';
    span.setAttribute('data-role', roleName);
    span.appendChild(document.createTextNode(roleName + ' '));
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'x-btn';
    btn.innerHTML = '&#10005;';
    btn.onclick = function() { removeRole(btn, roleName); };
    span.appendChild(btn);
    wrap.appendChild(span);
}

function removeRoleTagByName(roleName) {
    var wrap = document.getElementById('rolesWrap');
    if (!wrap) return;
    wrap.querySelectorAll('.role-tag').forEach(function(tag) {
        if (tag.getAttribute('data-role') === roleName) tag.remove();
    });
    checkEmpty();
}

function removeRole(btn, roleName) {
    btn.closest('.role-tag').remove();
    checkEmpty();
    var safeId = 'chk_' + roleName.replace(/ /g,'_').replace(/\//g,'_');
    var chk = document.getElementById(safeId);
    if (chk) {
        chk.checked = false;
        var lbl = document.getElementById('item_' + safeId);
        if (lbl) lbl.classList.remove('checked');
    }
}

function checkEmpty() {
    var wrap = document.getElementById('rolesWrap');
    if (!wrap) return;
    if (wrap.querySelectorAll('.role-tag').length === 0 && !document.getElementById('noRolesMsg')) {
        var span = document.createElement('span');
        span.className = 'no-roles'; span.id = 'noRolesMsg';
        span.textContent = 'No roles assigned';
        wrap.appendChild(span);
    }
}

// ── Clear all ────────────────────────────────────────────────────────────────
function clearAllRoles() {
    document.getElementById('checkboxGrid').querySelectorAll('.checkbox-item').forEach(function(lbl) {
        lbl.classList.remove('checked');
        var chk = lbl.querySelector('input[type=checkbox]');
        if (chk) chk.checked = false;
    });
    var wrap = document.getElementById('rolesWrap');
    if (wrap) {
        wrap.querySelectorAll('.role-tag').forEach(function(t) { t.remove(); });
        checkEmpty();
    }
}

// ── Prepare hidden inputs before submit ─────────────────────────────────────
function prepareRoles() {
    var container = document.getElementById('hiddenRolesContainer');
    container.innerHTML = '';
    document.querySelectorAll('#rolesWrap .role-tag').forEach(function(tag) {
        var role = tag.getAttribute('data-role');
        if (role) {
            var inp = document.createElement('input');
            inp.type = 'hidden'; inp.name = 'selectedRoles'; inp.value = role;
            container.appendChild(inp);
        }
    });
}

// ── Navigation ───────────────────────────────────────────────────────────────
function goBack() {
    try {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('View > Maintenance');
        }
    } catch(e) {}
    window.location.href = '<%=request.getContextPath()%>/View/allUsersMaintenance.jsp';
}
</script>
</body>
</html>
