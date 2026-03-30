<%@ page import="java.sql.*, db.DBConnection, db.AESEncryption" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String userId       = request.getParameter("username");
    String password     = request.getParameter("password");
    String branchCode   = request.getParameter("branch");
    String errorMessage = null;
    boolean showForm    = true;

    // ── Check if user was force logged out by someone else ───────────────────
    boolean wasForcedOut = "forcedout".equals(request.getParameter("reason"));

    // ── Force Login ──────────────────────────────────────────────────────────
    if ("forceLogin".equals(request.getParameter("action"))) {
        String forceUserId     = request.getParameter("userId");
        String forceBranchCode = request.getParameter("branchCode");
        String forcePassword   = request.getParameter("password");

        Connection connForce = null;
        PreparedStatement psForce = null;

        try {
            connForce = DBConnection.getConnection();

            // Reset CURRENTLOGIN_STATUS to 'U' and clear SESSION_ID
            // The old user's session will be detected as invalid on their next sessionCheck
            psForce = connForce.prepareStatement(
                "UPDATE ACL.USERREGISTER SET CURRENTLOGIN_STATUS = 'U', SESSION_ID = NULL " +
                "WHERE USER_ID = ? AND BRANCH_CODE = ?"
            );
            psForce.setString(1, forceUserId);
            psForce.setString(2, forceBranchCode);
            psForce.executeUpdate();

            // Redirect back to login with same credentials to auto-login
            response.sendRedirect("login.jsp?username=" + forceUserId +
                                  "&branch=" + forceBranchCode +
                                  "&password=" + java.net.URLEncoder.encode(forcePassword, "UTF-8") +
                                  "&autoLogin=true");
            showForm = false;

        } catch (Exception e) {
            errorMessage = "Force login failed: " + e.getMessage();
        } finally {
            try { if (psForce   != null) psForce.close();   } catch (Exception ignored) {}
            try { if (connForce != null) connForce.close(); } catch (Exception ignored) {}
        }
    }

    // ── Auto Login after Force Login redirect ────────────────────────────────
    if ("true".equals(request.getParameter("autoLogin"))) {
        userId     = request.getParameter("username");
        password   = request.getParameter("password");
        branchCode = request.getParameter("branch");
    }

    // ── Normal Login ─────────────────────────────────────────────────────────
    if (showForm && userId != null && password != null && branchCode != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT USER_ID, PASSWD, CURRENTLOGIN_STATUS FROM ACL.USERREGISTER WHERE USER_ID=? AND BRANCH_CODE=?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, userId);
            pstmt.setString(2, branchCode);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                String encryptedPassword  = rs.getString("PASSWD");
                String currentLoginStatus = rs.getString("CURRENTLOGIN_STATUS");

                try {
                    String decryptedPassword = AESEncryption.decrypt(encryptedPassword);

                    if (decryptedPassword.equals(password)) {
                        if ("L".equals(currentLoginStatus)) {
                            errorMessage = "User is already logged in from another session. Please contact administrator.";
                        } else {
                            // Set session attributes
                            session.setAttribute("userId",     userId);
                            session.setAttribute("branchCode", branchCode);

                            // Fetch and set role
                            PreparedStatement roleStmt = null;
                            ResultSet roleRs = null;
                            try {
                                String roleSql = "SELECT IS_SUPPORT_USER FROM ACL.USERREGISTER WHERE USER_ID=? AND BRANCH_CODE=?";
                                roleStmt = conn.prepareStatement(roleSql);
                                roleStmt.setString(1, userId);
                                roleStmt.setString(2, branchCode);
                                roleRs = roleStmt.executeQuery();
                                if (roleRs.next()) {
                                    String role = roleRs.getString("IS_SUPPORT_USER");
                                    role = (role != null) ? role.trim().toUpperCase() : "N";
                                    session.setAttribute("isSupportUser", role);
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                try { if (roleRs   != null) roleRs.close();   } catch (Exception e) {}
                                try { if (roleStmt != null) roleStmt.close(); } catch (Exception e) {}
                            }

                            // Insert login history
                            PreparedStatement historyStmt = null;
                            try {
                                String historySql = "INSERT INTO ACL.USERREGISTERLOGINHISTORY (USER_ID, BRANCH_CODE, LOGIN_TIME) VALUES (?, ?, SYSDATE)";
                                historyStmt = conn.prepareStatement(historySql);
                                historyStmt.setString(1, userId);
                                historyStmt.setString(2, branchCode);
                                historyStmt.executeUpdate();
                            } catch (Exception ignored) {
                            } finally {
                                try { if (historyStmt != null) historyStmt.close(); } catch (Exception e2) {}
                            }

                            // Update login status to 'L' AND save SESSION_ID
                            PreparedStatement statusStmt = null;
                            try {
                                String statusSql = "UPDATE ACL.USERREGISTER SET CURRENTLOGIN_STATUS = 'L', SESSION_ID = ? WHERE USER_ID = ? AND BRANCH_CODE = ?";
                                statusStmt = conn.prepareStatement(statusSql);
                                statusStmt.setString(1, session.getId()); // save session ID to DB
                                statusStmt.setString(2, userId);
                                statusStmt.setString(3, branchCode);
                                statusStmt.executeUpdate();
                            } catch (Exception ignored) {
                            } finally {
                                try { if (statusStmt != null) statusStmt.close(); } catch (Exception e2) {}
                            }

                            response.sendRedirect("main.jsp");
                            showForm = false;
                        }
                    } else {
                        errorMessage = "Invalid username or password.";
                    }
                } catch (Exception decryptEx) {
                    errorMessage = "Invalid username or password.";
                }
            } else {
                errorMessage = "Invalid username or password.";
            }
        } catch (Exception e) {
            errorMessage = "Database Error: " + e.getMessage();
        } finally {
            try { if (rs    != null) rs.close();    } catch (Exception ignored) {}
            try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
            try { if (conn  != null) conn.close();  } catch (Exception ignored) {}
        }
    }

    // ── Fetch CBS version from DB ─────────────────────────────────────────────
    String cbsVersion = "v3.1";
    try (Connection connVer = DBConnection.getConnection();
         PreparedStatement psVer = connVer.prepareStatement(
             "SELECT CBS_VERSION FROM GLOBALCONFIG.UNIVERSALPARAMETER WHERE ROWNUM = 1")) {
        ResultSet rsVer = psVer.executeQuery();
        if (rsVer.next() && rsVer.getString("CBS_VERSION") != null) {
            cbsVersion = rsVer.getString("CBS_VERSION").trim();
        }
        rsVer.close();
    } catch (Exception ignored) {}
%>

<% if (showForm) { %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CBS Login</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="css/login.css">
<style>
    /* ── Forced Out Popup ── */
    .forcedout-overlay {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.6);
        z-index: 9999;
        justify-content: center;
        align-items: center;
    }
    .forcedout-overlay.show {
        display: flex;
    }
    .forcedout-box {
        background: #fff;
        border-radius: 16px;
        padding: 40px 36px 32px;
        max-width: 420px;
        width: 90%;
        text-align: center;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.25);
        animation: popIn 0.3s ease;
    }
    @keyframes popIn {
        from { transform: scale(0.85); opacity: 0; }
        to   { transform: scale(1);    opacity: 1; }
    }
    .forcedout-icon {
        font-size: 52px;
        margin-bottom: 14px;
        line-height: 1;
    }
    .forcedout-title {
        font-size: 20px;
        font-weight: 700;
        color: #b91c1c;
        margin-bottom: 12px;
    }
    .forcedout-message {
        font-size: 14px;
        color: #555;
        line-height: 1.6;
        margin-bottom: 28px;
    }
    .forcedout-btn {
        padding: 12px 48px;
        background: #4361d8;
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 15px;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s;
    }
    .forcedout-btn:hover {
        background: #3451c4;
    }
</style>
</head>
<body>

<!-- Arc pattern background -->
<div class="bg-arc"></div>

<!-- ── Forced Out Popup — shown when A is kicked out by B ── -->
<% if (wasForcedOut) { %>
<div class="forcedout-overlay show" id="forcedOutOverlay">
    <div class="forcedout-box">
        <div class="forcedout-icon">⚠️</div>
        <div class="forcedout-title">Session Terminated</div>
        <div class="forcedout-message">
            You have been logged out because someone logged in with your credentials from another device or location.
            <br><br>
            If this was not you, please contact your administrator immediately.
        </div>
        <button class="forcedout-btn" onclick="closeForcedOutPopup()">OK, Got It</button>
    </div>
</div>
<% } %>

<!-- Licence modal overlay -->
<div id="licenseOverlay">
    <div id="licenseBox">
        <div id="licenseIcon"></div>
        <div id="licenseTitle"></div>
        <p id="licenseMessage"></p>
        <div id="licenseContact">
            📞 Contact IDSSPL Support &nbsp;|&nbsp;
            <a href="https://idsspl.com/" target="_blank">infokop@idsspl.com</a>
        </div><br>
        <button id="licenseOkBtn" onclick="handleLicenseOk()">OK</button>
    </div>
</div>

<!-- ── PAGE WRAPPER ── -->
<div class="page-wrapper">

    <div class="login-card">

        <!-- LEFT — logo + illustration panel -->
        <div class="card-left">
            <div class="card-left-content">

                <img src="images/IDSSPL_LOGO.png" alt="IDSSPL Logo" class="idsspl-logo-img">

                <div class="idsspl-logo-label">IDSSPL TECHNOLOGIES PVT LTD</div>

                <img src="images/online_banking.png" alt="Online Banking" class="banking-img">

                <!-- Product badge — version from DB -->
                <div class="product-badge">
                    <div class="product-badge-top">
                        <span class="product-dot"></span>
                        <span class="product-name">Core Banking Solution</span>
                        <span class="product-version"><%= cbsVersion %></span>
                    </div>
                </div>

            </div>
        </div>

        <!-- RIGHT — form -->
        <div class="card-right">

            <div class="greeting">Back Again !</div>

            <div class="bank-name">
                <%
                    String loginBankName = "Demo Bank/Society Ltd.";
                    try (Connection connBank = DBConnection.getConnection();
                         PreparedStatement psBank = connBank.prepareStatement(
                             "SELECT NAME FROM GLOBALCONFIG.BANK WHERE BANK_CODE = ?")) {
                        psBank.setString(1, "0100");
                        ResultSet rsBank = psBank.executeQuery();
                        if (rsBank.next()) loginBankName = rsBank.getString("NAME");
                    } catch (Exception ignored) {}
                %>
                THE <%= loginBankName.toUpperCase() %>
            </div>

            <!-- Main Login Form -->
            <form action="login.jsp" method="post" autocomplete="off">

                <!-- Branch -->
                <div class="field-row">
                    <label for="branch">Branch</label>
                    <select id="branch" name="branch" required>
                        <option value="">— Select Branch —</option>
                        <%
                            try (Connection connBr = DBConnection.getConnection();
                                 Statement stmtBr  = connBr.createStatement();
                                 ResultSet rsBr    = stmtBr.executeQuery(
                                     "SELECT BRANCH_CODE, NAME FROM HEADOFFICE.BRANCH ORDER BY BRANCH_CODE")) {
                                while (rsBr.next()) {
                                    String bc = rsBr.getString("BRANCH_CODE");
                                    String bn = rsBr.getString("NAME");
                                    boolean sel = bc.equals(request.getParameter("branch"));
                            %>
                                <option value="<%= bc %>" <%= sel ? "selected" : "" %>><%= bc %> — <%= bn %></option>
                            <%
                                }
                            } catch (Exception ex) {
                                out.println("<option>Error loading branches</option>");
                            }
                        %>
                    </select>
                </div>

                <!-- User Name -->
                <div class="field-row">
                    <label for="username">User Name</label>
                    <input type="text" id="username" name="username" placeholder=" " required
                           value="<%= userId != null ? userId : "" %>">
                    <img src="images/user.png" class="f-icon" alt="">
                </div>

                <!-- Password -->
                <div class="field-row">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" placeholder=" " required>
                    <img src="images/password_lock.png" id="lockIcon" class="f-icon" alt="">
                    <img src="images/eye.png" id="eyeIcon" class="eye-btn" alt="show/hide" style="display:none;">
                </div>

                <!-- Forgot -->
                <div class="forgot-row"><a href="#">Forgot Password?</a></div>

                <!-- Submit -->
                <button type="submit" class="btn-login">Login</button>

                <!-- Error messages -->
                <% if (errorMessage != null) { %>
                    <% if (errorMessage.contains("already logged in")) { %>
                        <div class="alert alert-warning">
                            <svg viewBox="0 0 20 20"><path d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"/></svg>
                            <%= errorMessage %>
                        </div>
                    <% } else { %>
                        <div class="alert alert-error">
                            <svg viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/></svg>
                            <%= errorMessage %>
                        </div>
                    <% } %>
                <% } %>

            </form>

            <!-- Force Login Form — outside main form, shown only on "already logged in" error -->
            <% if (errorMessage != null && errorMessage.contains("already logged in")) { %>
                <form action="login.jsp" method="post" style="margin-top: 10px;">
                    <input type="hidden" name="action"     value="forceLogin">
                    <input type="hidden" name="userId"     value="<%= userId %>">
                    <input type="hidden" name="branchCode" value="<%= branchCode %>">
                    <input type="hidden" name="password"   value="<%= password %>">
                    <button type="submit" style="
                        width: 100%;
                        padding: 10px;
                        background: #f59e0b;
                        color: white;
                        border: none;
                        border-radius: 6px;
                        font-size: 14px;
                        font-weight: 600;
                        cursor: pointer;
                        transition: background 0.2s;">
                        ⚡ Force Login — End Other Session & Login
                    </button>
                </form>
            <% } %>

        </div>

    </div>
</div>

<!-- Footer -->
<div class="page-footer">
    <span class="footer-icon">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#8a96a8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 8.2c0 7.3-8 11.8-8 11.8z"/><circle cx="12" cy="10" r="3"/></svg>
        11, "Gurukrupa" Friends Colony Kolhapur 416005
    </span>
    <span class="footer-sep">|</span>
    <span class="footer-icon">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#8a96a8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.62 12 19.79 19.79 0 0 1 1.55 3.41 2 2 0 0 1 3.53 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.56a16 16 0 0 0 6.06 6.06l.81-.81a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
        +91 2312530950
    </span>
    <span class="footer-sep">|</span>
    <span class="footer-icon">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#8a96a8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
        www.infokop@idsspl.com
    </span>
</div>

<script>
// ── Forced Out Popup ──
function closeForcedOutPopup() {
    document.getElementById('forcedOutOverlay').classList.remove('show');
}

// ── Password Eye Toggle ──
var passwordInput = document.getElementById("password");
var eyeIcon       = document.getElementById("eyeIcon");
var lockIcon      = document.getElementById("lockIcon");

passwordInput.addEventListener("input", function () {
    var hasValue = passwordInput.value.length > 0;
    lockIcon.style.display = hasValue ? "none"  : "block";
    eyeIcon.style.display  = hasValue ? "block" : "none";
});

eyeIcon.addEventListener("click", function () {
    if (passwordInput.type === "password") {
        passwordInput.type = "text";
        eyeIcon.src = "images/eye-hide.png";
    } else {
        passwordInput.type = "password";
        eyeIcon.src = "images/eye.png";
    }
});

function handleLicenseOk() {
    document.getElementById('licenseOverlay').classList.remove('show');
    if (window._licenseRedirect) {
        window.location.href = 'main.jsp';
    }
}
</script>

</body>
</html>
<% } %>
