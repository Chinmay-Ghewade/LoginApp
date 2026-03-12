<%@ page import="java.sql.*, db.DBConnection, db.AESEncryption" %> 
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    // Disable caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String userId = request.getParameter("username");
    String password = request.getParameter("password");
    String branchCode = request.getParameter("branch");
    String errorMessage = null;
    boolean showForm = true;

    if (userId != null && password != null && branchCode != null) {
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
                String encryptedPassword = rs.getString("PASSWD");
                String currentLoginStatus = rs.getString("CURRENTLOGIN_STATUS");
                
                try {
                    String decryptedPassword = AESEncryption.decrypt(encryptedPassword);
                    
                    if (decryptedPassword.equals(password)) {
                        if ("L".equals(currentLoginStatus)) {
                            errorMessage = "User is already logged in from another machine/session. Please logout from the other session first or contact administrator.";
                        } else {
                            session.setAttribute("userId", userId);
                            session.setAttribute("branchCode", branchCode);
                            
                            PreparedStatement historyStmt = null;
                            try {
                                String historySql = "INSERT INTO ACL.USERREGISTERLOGINHISTORY (USER_ID, BRANCH_CODE, LOGIN_TIME) VALUES (?, ?, SYSDATE)";
                                historyStmt = conn.prepareStatement(historySql);
                                historyStmt.setString(1, userId);
                                historyStmt.setString(2, branchCode);
                                historyStmt.executeUpdate();
                            } catch (Exception historyEx) {
                                System.err.println("Error inserting login history: " + historyEx.getMessage());
                            } finally {
                                try { if (historyStmt != null) historyStmt.close(); } catch (Exception ignored) {}
                            }
                            
                            PreparedStatement statusStmt = null;
                            try {
                                String statusSql = "UPDATE ACL.USERREGISTER SET CURRENTLOGIN_STATUS = 'L' WHERE USER_ID = ? AND BRANCH_CODE = ?";
                                statusStmt = conn.prepareStatement(statusSql);
                                statusStmt.setString(1, userId);
                                statusStmt.setString(2, branchCode);
                                statusStmt.executeUpdate();
                            } catch (Exception statusEx) {
                                System.err.println("Error updating login status: " + statusEx.getMessage());
                            } finally {
                                try { if (statusStmt != null) statusStmt.close(); } catch (Exception ignored) {}
                            }
                            
                            response.sendRedirect("main.jsp");
                            showForm = false;
                        }
                    } else {
                        errorMessage = "Invalid username or password";
                    }
                } catch (Exception decryptEx) {
                    System.err.println("Error decrypting password: " + decryptEx.getMessage());
                    errorMessage = "Invalid username or password";
                }
            } else {
                errorMessage = "Invalid username or password";
            }
        } catch (Exception e) {
            errorMessage = "Database Error: " + e.getMessage();
            System.err.println("Login Error: " + e.getMessage());
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignored) {}
            try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
            try { if (conn != null) conn.close(); } catch (Exception ignored) {}
        }
    }
%>

<% if (showForm) { %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Bank CBS - Secure Login</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Playfair+Display:wght@600&display=swap" rel="stylesheet">
<style>
/* ─── Reset & Base ─────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
    --navy:      #0B1437;
    --blue:      #1B4FE4;
    --blue-mid:  #2563EB;
    --blue-light:#3B76F7;
    --indigo:    #4458DC;
    --sky:       #EEF3FF;
    --gray-50:   #F8FAFF;
    --gray-100:  #F1F5FD;
    --gray-300:  #CBD5E1;
    --gray-500:  #64748B;
    --gray-700:  #334155;
    --white:     #FFFFFF;
    --danger:    #EF4444;
    --warn-bg:   #FFF7ED;
    --warn-border:#F97316;
    --warn-text: #C2410C;
    --radius:    12px;
    --shadow-card: 0 20px 60px rgba(11,20,55,0.15), 0 4px 16px rgba(11,20,55,0.08);
}

html, body {
    height: 100%;
    font-family: 'DM Sans', sans-serif;
    background: var(--navy);
    overflow: hidden;
}

/* ─── Background pattern ────────────────────────────────── */
body::before {
    content: '';
    position: fixed;
    inset: 0;
    background:
        radial-gradient(ellipse 80% 60% at 20% 10%, rgba(27,79,228,0.35) 0%, transparent 60%),
        radial-gradient(ellipse 60% 50% at 80% 90%, rgba(68,88,220,0.25) 0%, transparent 55%),
        radial-gradient(ellipse 40% 40% at 70% 20%, rgba(59,118,247,0.15) 0%, transparent 50%);
    pointer-events: none;
    z-index: 0;
}

/* subtle dot grid */
body::after {
    content: '';
    position: fixed;
    inset: 0;
    background-image: radial-gradient(rgba(255,255,255,0.07) 1px, transparent 1px);
    background-size: 28px 28px;
    pointer-events: none;
    z-index: 0;
}

/* ─── Page wrapper ──────────────────────────────────────── */
.page-wrapper {
    position: relative;
    z-index: 1;
    display: flex;
    height: 100vh;
    width: 100%;
    overflow: hidden;
}

/* ─── Left panel ────────────────────────────────────────── */
.left-panel {
    flex: 1.1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 60px 50px;
    position: relative;
    animation: slideInLeft 0.7s ease both;
}

.left-panel .illustration-wrap {
    width: 100%;
    max-width: 500px;
    position: relative;
}

.left-panel .illustration-wrap img {
    width: 100%;
    height: auto;
    max-height: 340px;
    object-fit: contain;
    border-radius: 16px;
    filter: drop-shadow(0 20px 40px rgba(0,0,0,0.35));
    animation: floatUp 4s ease-in-out infinite;
}

.left-panel .brand-block {
    text-align: center;
    margin-top: 36px;
}

.left-panel .brand-block .logo-wrap {
    display: inline-flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 14px;
}

.left-panel .brand-block img.bank-logo {
    height: 52px;
    width: auto;
    filter: brightness(0) invert(1) drop-shadow(0 2px 8px rgba(0,0,0,0.3));
}

.left-panel .brand-block .brand-title {
    font-family: 'Playfair Display', serif;
    font-size: 26px;
    color: #fff;
    letter-spacing: 0.5px;
    text-shadow: 0 2px 12px rgba(0,0,0,0.3);
}

.left-panel .brand-block .brand-sub {
    font-size: 14px;
    color: rgba(255,255,255,0.6);
    letter-spacing: 0.3px;
    margin-top: 4px;
}

/* trust badges */
.trust-badges {
    display: flex;
    gap: 16px;
    margin-top: 28px;
    flex-wrap: wrap;
    justify-content: center;
}

.trust-badge {
    display: flex;
    align-items: center;
    gap: 6px;
    background: rgba(255,255,255,0.08);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 50px;
    padding: 6px 14px;
    font-size: 12px;
    color: rgba(255,255,255,0.75);
    backdrop-filter: blur(6px);
}

.trust-badge .dot {
    width: 7px; height: 7px;
    border-radius: 50%;
    background: #4ADE80;
    box-shadow: 0 0 6px #4ADE80;
}

/* ─── Right panel (login card) ──────────────────────────── */
.right-panel {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 32px 40px;
    animation: slideInRight 0.7s ease both;
}

.login-card {
    background: var(--white);
    border-radius: 20px;
    box-shadow: var(--shadow-card);
    width: 420px;
    padding: 44px 40px 36px;
    position: relative;
    overflow: hidden;
}

/* top accent bar */
.login-card::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--blue), var(--indigo), var(--blue-light));
}

.card-header {
    margin-bottom: 28px;
}

.card-header h2 {
    font-size: 22px;
    font-weight: 700;
    color: var(--navy);
    margin-bottom: 4px;
}

.card-header p {
    font-size: 13.5px;
    color: var(--gray-500);
}

/* ─── Form fields ───────────────────────────────────────── */
.field-group {
    margin-bottom: 16px;
}

.field-group label {
    display: block;
    font-size: 12.5px;
    font-weight: 600;
    color: var(--gray-700);
    margin-bottom: 6px;
    letter-spacing: 0.2px;
}

.field-wrap {
    position: relative;
}

.field-wrap .field-icon {
    position: absolute;
    left: 13px;
    top: 50%;
    transform: translateY(-50%);
    width: 17px;
    height: 17px;
    opacity: 0.45;
    pointer-events: none;
}

/* shared input/select style */
.field-wrap select,
.field-wrap input[type="text"],
.field-wrap input[type="password"] {
    width: 100%;
    height: 44px;
    padding: 0 42px 0 40px;
    border: 1.5px solid var(--gray-300);
    border-radius: 9px;
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    color: var(--navy);
    background: var(--gray-50);
    transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
    outline: none;
    appearance: none;
    -webkit-appearance: none;
}

.field-wrap select {
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' stroke='%2364748B' stroke-width='1.5' fill='none' stroke-linecap='round'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 14px center;
}

.field-wrap select:focus,
.field-wrap input:focus {
    border-color: var(--blue);
    background: var(--white);
    box-shadow: 0 0 0 3px rgba(27,79,228,0.1);
}

/* eye toggle */
.eye-toggle {
    position: absolute;
    right: 13px;
    top: 50%;
    transform: translateY(-50%);
    width: 20px;
    height: 20px;
    cursor: pointer;
    opacity: 0.45;
    transition: opacity 0.2s;
    display: none;
}
.eye-toggle:hover { opacity: 0.75; }

/* ─── CAPTCHA ───────────────────────────────────────────── */
.captcha-row {
    display: flex;
    gap: 10px;
    align-items: stretch;
    margin-bottom: 16px;
}

.captcha-image-box {
    flex: 1;
    min-height: 44px;
    background: linear-gradient(135deg, #e8edf8, #dce4f5);
    border: 1.5px solid var(--gray-300);
    border-radius: 9px;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    position: relative;
}

.captcha-placeholder {
    font-family: 'DM Sans', sans-serif;
    font-size: 22px;
    font-weight: 700;
    letter-spacing: 6px;
    color: var(--navy);
    opacity: 0.55;
    user-select: none;
    text-decoration: line-through;
    text-decoration-style: dotted;
}

.captcha-refresh-btn {
    width: 44px;
    height: 44px;
    background: var(--sky);
    border: 1.5px solid var(--gray-300);
    border-radius: 9px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: background 0.2s, border-color 0.2s, transform 0.3s;
    flex-shrink: 0;
}

.captcha-refresh-btn:hover {
    background: #dce8ff;
    border-color: var(--blue);
    transform: rotate(180deg);
}

.captcha-refresh-btn svg {
    width: 18px; height: 18px;
    stroke: var(--blue);
    fill: none;
    stroke-width: 2;
    stroke-linecap: round;
    stroke-linejoin: round;
}

/* ─── Login button ──────────────────────────────────────── */
.btn-login {
    width: 100%;
    height: 46px;
    background: linear-gradient(135deg, var(--blue) 0%, var(--indigo) 100%);
    color: #fff;
    font-family: 'DM Sans', sans-serif;
    font-size: 15px;
    font-weight: 600;
    border: none;
    border-radius: 9px;
    cursor: pointer;
    letter-spacing: 0.3px;
    transition: opacity 0.2s, transform 0.15s, box-shadow 0.2s;
    box-shadow: 0 4px 16px rgba(27,79,228,0.35);
    margin-top: 4px;
}

.btn-login:hover {
    opacity: 0.92;
    transform: translateY(-1px);
    box-shadow: 0 6px 22px rgba(27,79,228,0.45);
}

.btn-login:active {
    transform: translateY(0);
    box-shadow: 0 2px 8px rgba(27,79,228,0.3);
}

/* ─── Alerts ────────────────────────────────────────────── */
.alert {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    border-radius: 9px;
    padding: 11px 14px;
    font-size: 13px;
    font-weight: 500;
    margin-top: 14px;
    line-height: 1.45;
}

.alert-error {
    background: #FEF2F2;
    border: 1px solid #FECACA;
    color: #991B1B;
}

.alert-warning {
    background: var(--warn-bg);
    border: 1px solid #FED7AA;
    color: var(--warn-text);
}

.alert svg {
    width: 16px; height: 16px;
    flex-shrink: 0;
    margin-top: 1px;
    fill: currentColor;
}

/* ─── Help row ──────────────────────────────────────────── */
.help-row {
    display: flex;
    justify-content: flex-end;
    margin-top: 14px;
}

.help-row a {
    font-size: 12.5px;
    color: var(--blue);
    text-decoration: none;
    font-weight: 500;
}
.help-row a:hover { text-decoration: underline; }

/* ─── Card footer ───────────────────────────────────────── */
.card-footer-note {
    text-align: center;
    font-size: 11.5px;
    color: var(--gray-500);
    margin-top: 22px;
    padding-top: 18px;
    border-top: 1px solid var(--gray-100);
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
}

.card-footer-note svg {
    width: 13px; height: 13px;
    stroke: var(--gray-500);
    fill: none;
    stroke-width: 2;
    flex-shrink: 0;
}

/* ─── Page footer ───────────────────────────────────────── */
.page-footer {
    position: fixed;
    bottom: 0;
    left: 0; right: 0;
    text-align: center;
    font-size: 12px;
    color: rgba(255,255,255,0.35);
    padding: 12px;
    z-index: 2;
}

/* ─── Animations ────────────────────────────────────────── */
@keyframes slideInLeft {
    from { opacity: 0; transform: translateX(-30px); }
    to   { opacity: 1; transform: translateX(0); }
}

@keyframes slideInRight {
    from { opacity: 0; transform: translateX(30px); }
    to   { opacity: 1; transform: translateX(0); }
}

@keyframes floatUp {
    0%, 100% { transform: translateY(0px); }
    50%       { transform: translateY(-12px); }
}

/* ─── Responsive ────────────────────────────────────────── */
@media (max-width: 900px) {
    .left-panel { display: none; }
    .right-panel { flex: 1; padding: 20px; }
    .login-card { width: 100%; max-width: 420px; }
    html, body { overflow: auto; }
    .page-wrapper { height: auto; min-height: 100vh; }
}

/* Fix browser password eye icon */
input[type="password"]::-ms-reveal,
input[type="password"]::-ms-clear { display: none; }
input[type="password"]::-webkit-credentials-auto-fill-button,
input[type="password"]::-webkit-password-toggle-button { display: none !important; }
</style>
</head>
<body>

<div class="page-wrapper">

    <!-- ══════════════════════════════════════
         LEFT PANEL — Illustration + Branding
    ══════════════════════════════════════ -->
    <div class="left-panel">
<div class="brand-block">
            
            <%
                String loginBankName = "Bank CBS";
                try (Connection connBank = DBConnection.getConnection();
                     PreparedStatement psLoginBank = connBank.prepareStatement(
                         "SELECT NAME FROM GLOBALCONFIG.BANK WHERE BANK_CODE = ?")) {
                    psLoginBank.setString(1, "0100");
                    ResultSet rsLoginBank = psLoginBank.executeQuery();
                    if (rsLoginBank.next()) {
                        loginBankName = rsLoginBank.getString("NAME");
                    }
                } catch (Exception ignored) {}
            %>
            <div class="brand-title"><%= loginBankName.toUpperCase() %></div>
            <div class="brand-sub">Core Banking System &nbsp;·&nbsp; Secure Access Portal</div>

            <br>
            <br>
        </div>
        <div class="illustration-wrap">
            <img src="images/image.gif" alt="Bank System Illustration">
        </div>

        

    </div>

    <!-- ══════════════════════════════════════
         RIGHT PANEL — Login Card
    ══════════════════════════════════════ -->
    <div class="right-panel">
        <div class="login-card">

            <div class="card-header">
                <h2>Welcome Back</h2>
                <p>Sign in to your CBS account to continue</p>
            </div>

            <!-- ── FORM (action / names / ids unchanged) ── -->
            <form action="login.jsp" method="post" autocomplete="off">

                <!-- Branch -->
                <div class="field-group">
                    <label for="branch">Branch</label>
                    <div class="field-wrap">
                        <!-- branch icon -->
                        <svg class="field-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 10v11M12 10v11M16 10v11"/>
                        </svg>
                        <select id="branch" name="branch" required>
                            <option value="">— Select Branch —</option>
                            <%
                                try (Connection conn = DBConnection.getConnection();
                                     Statement stmt = conn.createStatement();
                                     ResultSet branchRS = stmt.executeQuery("SELECT BRANCH_CODE, NAME FROM HEADOFFICE.BRANCH ORDER BY BRANCH_CODE")) {
                                    while(branchRS.next()) {
                                        String bCode = branchRS.getString("BRANCH_CODE");
                                        String bName = branchRS.getString("NAME");
                            %>
                                        <option value="<%=bCode%>"><%=bCode%> — <%=bName%></option>
                            <%
                                    }
                                } catch(Exception ex) {
                                    out.println("<option>Error loading branches</option>");
                                }
                            %>
                        </select>
                    </div>
                </div>

                <!-- User ID -->
                <div class="field-group">
                    <label for="username">User ID</label>
                    <div class="field-wrap">
                        <svg class="field-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="8" r="4"/>
                            <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
                        </svg>
                        <input type="text" placeholder="Enter your User ID" id="username" name="username" required>
                    </div>
                </div>

                <!-- Password -->
                <div class="field-group">
                    <label for="password">Password</label>
                    <div class="field-wrap">
                        <svg class="field-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                        </svg>
                        <input type="password" placeholder="Enter your password" id="password" name="password" required>
                        <img src="images/eye.png" id="eyeIcon" class="eye-toggle" alt="Toggle password">
                    </div>
                </div>

                <!-- CAPTCHA (UI only — backend not connected) -->
                <div class="field-group">
                    <label>Security Verification</label>
                    <div class="captcha-row">
                        <div class="captcha-image-box" id="captchaBox">
                            <span class="captcha-placeholder" id="captchaText">X4P9R</span>
                        </div>
                        <button type="button" class="captcha-refresh-btn" id="captchaRefreshBtn" title="Refresh CAPTCHA">
                            <svg viewBox="0 0 24 24">
                                <polyline points="23 4 23 10 17 10"/>
                                <polyline points="1 20 1 14 7 14"/>
                                <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
                            </svg>
                        </button>
                    </div>
                    <div class="field-wrap">
                        <svg class="field-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        </svg>
                        <input type="text" id="captchaInput" name="captchaInput" placeholder="Enter the characters above" maxlength="10">
                    </div>
                </div>

                <!-- Login button -->
                <button type="submit" class="btn-login">Sign In to CBS</button>

                <!-- Error / Warning alerts -->
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

                <div class="help-row">
                    <a href="#">Forgot Password?</a>
                </div>

            </form>
            <!-- ── end form ── -->

            <div class="card-footer-note">
                <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                </svg>
                Your connection is secured and encrypted
            </div>

        </div>
    </div>
    <!-- end right panel -->

</div>

<!-- Page footer -->
<div class="page-footer">© 2025 Merchants Liberal Co-op Bank Ltd. All rights reserved.</div>

<!-- ── Scripts (all original logic preserved + captcha UI) ── -->
<script>
// ── Password eye toggle (original logic unchanged) ──────────
const passwordInput = document.getElementById("password");
const eyeIcon       = document.getElementById("eyeIcon");

eyeIcon.style.display = "none";

function togglePassword() {
    if (passwordInput.type === "password") {
        passwordInput.type = "text";
        eyeIcon.src = "images/eye-hide.png";
    } else {
        passwordInput.type = "password";
        eyeIcon.src = "images/eye.png";
    }
}

eyeIcon.addEventListener("click", togglePassword);

passwordInput.addEventListener("input", function () {
    eyeIcon.style.display = passwordInput.value.length > 0 ? "block" : "none";
});

// ── CAPTCHA UI logic (UI-only, no backend) ──────────────────
const captchaChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateCaptcha() {
    let code = '';
    for (let i = 0; i < 5; i++) {
        code += captchaChars[Math.floor(Math.random() * captchaChars.length)];
    }
    document.getElementById('captchaText').textContent = code;
    document.getElementById('captchaInput').value = '';
}

document.getElementById('captchaRefreshBtn').addEventListener('click', function () {
    generateCaptcha();
});
</script>

</body>
</html>
<% } %>
