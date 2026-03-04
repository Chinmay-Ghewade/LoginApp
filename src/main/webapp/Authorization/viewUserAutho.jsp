<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, db.DBConnection" %>

<%
String userId = request.getParameter("userId");

if(userId == null || userId.trim().equals("")){
%>
    <h3>User Id not received</h3>
<%
    return;
}

/* ================= FETCH USER DATA ================= */
String userName   = "";
String branchCode = "";
String custId     = "";
String mobile     = "";
String empCode    = "";

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = DBConnection.getConnection();

    String sql =
        "SELECT USER_ID, NAME, BRANCH_CODE, CUSTOMER_ID, MOBILE_NUMBER " +
        "FROM ACL.USERREGISTER WHERE USER_ID = ?";

    ps = conn.prepareStatement(sql);
    ps.setString(1, userId);
    rs = ps.executeQuery();

    if (rs.next()) {
        userName   = rs.getString("NAME");
        branchCode = rs.getString("BRANCH_CODE");
        custId     = rs.getString("CUSTOMER_ID");
        mobile     = rs.getString("MOBILE_NUMBER");
    } else {
%>
        <h3>User Not Found</h3>
<%
        return;
    }

} catch(Exception e) {
    out.print(e);
} finally {
    try { if (rs != null) rs.close(); } catch (Exception ignored) {}
    try { if (ps != null) ps.close(); } catch (Exception ignored) {}
    try { if (conn != null) conn.close(); } catch (Exception ignored) {}
}

/* ================= FETCH PENDING ROLES ================= */
java.util.List<String> pendingRoles = new java.util.ArrayList<>();

Connection conn2 = null;
PreparedStatement ps2 = null;
ResultSet rs2 = null;

try {
    conn2 = DBConnection.getConnection();

    String roleSql =
        "SELECT M.MAINROLE " +
        "FROM ACL.USERPENDINGROLES U " +
        "JOIN ACL.MAINROLEREGISTER M ON U.MAINROLE_ID = M.MAINROLE_ID " +
        "WHERE U.USER_ID = ? AND U.STATUS = 'P' " +
        "ORDER BY M.MAINROLE";

    ps2 = conn2.prepareStatement(roleSql);
    ps2.setString(1, userId);
    rs2 = ps2.executeQuery();

    while (rs2.next()) {
        pendingRoles.add(rs2.getString("MAINROLE"));
    }

} catch(Exception e) {
    out.print("Error fetching roles: " + e.getMessage());
} finally {
    try { if (rs2 != null) rs2.close(); } catch (Exception ignored) {}
    try { if (ps2 != null) ps2.close(); } catch (Exception ignored) {}
    try { if (conn2 != null) conn2.close(); } catch (Exception ignored) {}
}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>View User Authorization</title>

<link rel="stylesheet" type="text/css"
href="<%=request.getContextPath()%>/OpenAccount/css/savingAcc.css">

<style>
:root {
    --bg-lavender: #E6E6FA;
    --navy-blue: #2b0d73;
    --border-color: #B8B8E6;
    --readonly-bg: #E0E0E0;
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

.form-group input {
    width: 100%;
    padding: 7px;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    font-size: 13px;
    box-sizing: border-box;
}

input[readonly] { background-color: var(--readonly-bg); }

/* ===== ROLES DISPLAY ===== */
.roles-display-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 8px;
    padding: 4px 0;
}

.role-display-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    background-color: #eef0fb;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    font-size: 13px;
    color: var(--navy-blue);
    font-weight: bold;
}

.role-display-item::before {
    content: "✔";
    color: #28a745;
    font-size: 12px;
    flex-shrink: 0;
}

.no-roles-msg {
    color: #999;
    font-size: 13px;
    font-style: italic;
    padding: 10px 0;
}

/* ===== PASSWORD FIELD ===== */
.password-field {
    position: relative;
    width: 100%;
}

.password-field input {
    padding-right: 40px;
    background-color: white;
}

.toggle-password {
    position: absolute;
    right: 15px;
    top: 50%;
    transform: translateY(-50%);
    cursor: pointer;
    color: #6c757d;
    font-size: 16px;
    user-select: none;
    display: flex;
    align-items: center;
    justify-content: center;
}

.toggle-password:hover { color: var(--navy-blue); }

input[type="password"]::-ms-reveal,
input[type="password"]::-ms-clear { display: none; }

input[type="password"] {
    appearance: none;
    -webkit-appearance: none;
}

.error-message {
    color: #dc3545;
    font-size: 12px;
    margin-top: 4px;
    display: none;
}

/* ===== MODAL STYLES ===== */
.modal {
    display: none;
    position: fixed;
    z-index: 1000;
    left: 0; top: 0;
    width: 100%; height: 100%;
    background-color: rgba(0,0,0,0.6);
}

.modal-content {
    background-color: white;
    margin: 12% auto;
    padding: 35px 40px;
    border-radius: 12px;
    width: 550px;
    box-shadow: 0 8px 20px rgba(0,0,0,0.3);
    text-align: center;
}

.modal-header {
    font-size: 24px;
    font-weight: bold;
    color: #3f3a7f;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
}

.modal-header .icon { font-size: 28px; }

.modal-body {
    margin-bottom: 25px;
    color: #555;
    font-size: 15px;
    line-height: 1.6;
}

.modal-body .app-number {
    font-weight: bold;
    color: #3f3a7f;
}

.modal-footer {
    display: flex;
    justify-content: center;
    gap: 15px;
}

.modal-btn {
    padding: 12px 30px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 15px;
    font-weight: 600;
    min-width: 140px;
    transition: all 0.3s ease;
}

.btn-confirm-authorize { background-color: #28a745; color: white; }
.btn-confirm-authorize:hover {
    background-color: #218838;
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(40,167,69,0.3);
}

.btn-confirm-reject { background-color: #dc3545; color: white; }
.btn-confirm-reject:hover {
    background-color: #c82333;
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(220,53,69,0.3);
}

.btn-cancel { background-color: #e0e0e0; color: #555; }
.btn-cancel:hover { background-color: #d0d0d0; transform: translateY(-1px); }

/* ===== PASSWORD STRENGTH & RULES ===== */
.strength-bar-wrapper {
    margin-top: 8px;
    display: none;
}
.strength-bar-track {
    height: 6px;
    background: #e0e0e0;
    border-radius: 10px;
    overflow: hidden;
}
.strength-bar-fill {
    height: 100%;
    width: 0%;
    border-radius: 10px;
    transition: width 0.4s ease, background 0.4s ease;
}
.strength-label {
    font-size: 12px;
    margin-top: 5px;
    font-weight: 600;
}

.password-rules {
    margin-top: 10px;
    padding: 10px 14px;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    display: none;
}
.password-rules.visible {
    display: block;
}
.rule-item {
    font-size: 12px;
    color: #94a3b8;
    margin-bottom: 4px;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: color 0.3s;
}
.rule-item.passed {
    color: #22c55e;
}
.rule-item .rule-icon {
    font-size: 13px;
    width: 16px;
    text-align: center;
}

.alert-custom {
    padding: 12px 16px;
    border-radius: 8px;
    margin-bottom: 15px;
    font-size: 14px;
    display: none;
    font-weight: 500;
}

.alert-error-custom {
    background-color: #fee;
    border: 2px solid #fcc;
    color: #d32f2f;
}

.alert-success-custom {
    background-color: #efe;
    border: 2px solid #cfc;
    color: #2d5016;
}
</style>
</head>

<body>
<div class="container">

<h2>View User Authorization</h2>

<!-- ================= USER DETAILS ================= -->
<fieldset>
<legend>User Details</legend>
<div class="grid-row-1" style="grid-template-columns: repeat(4, 1fr);">

    <div class="form-group">
        <label>User Id</label>
        <input type="text" value="<%=userId%>" readonly>
    </div>

    <div class="form-group">
        <label>User Name</label>
        <input type="text" value="<%=userName%>" readonly>
    </div>

    <div class="form-group">
        <label>Branch Code</label>
        <input type="text" value="<%=branchCode%>" readonly>
    </div>

    <div class="form-group">
        <label>Employee Code</label>
        <input type="text" value="<%=empCode%>" readonly>
    </div>

</div>
</fieldset>

<!-- ================= ADDRESS DETAILS ================= -->
<fieldset id="addressFieldset">
<legend>Address Details</legend>

<div class="grid-row-1">

    <div class="form-group">
        <label>Customer ID</label>
        <input type="text" id="customerId" value="<%=custId%>" readonly>
    </div>

    <div class="form-group">
        <label>Customer Name</label>
        <input type="text" id="customerName" readonly>
    </div>

    <div class="form-group">
        <label>Phone</label>
        <input type="text" id="phone" readonly>
    </div>

    <div class="form-group">
        <label>Mobile</label>
        <input type="text" id="mobile" value="<%=mobile%>" readonly>
    </div>

    <div class="form-group">
        <label>Email</label>
        <input type="text" id="email" readonly>
    </div>

</div>

<div class="grid-row-2">

    <div class="form-group">
        <label>Address 1</label>
        <input type="text" id="addr1" readonly>
    </div>

    <div class="form-group">
        <label>Address 2</label>
        <input type="text" id="addr2" readonly>
    </div>

    <div class="form-group">
        <label>Address 3</label>
        <input type="text" id="addr3" readonly>
    </div>

</div>
</fieldset>

<!-- ================= USER ROLES ================= -->
<fieldset>
<legend>User Roles</legend>

<%
if (pendingRoles.isEmpty()) {
%>
    <div class="no-roles-msg">No pending roles found for this user.</div>
<%
} else {
%>
    <div class="roles-display-grid">
        <%
        for (String role : pendingRoles) {
        %>
            <div class="role-display-item"><%=role%></div>
        <%
        }
        %>
    </div>
<%
}
%>

</fieldset>

<!-- ================= PASSWORD DETAILS ================= -->
<fieldset>
<legend>Password Details</legend>

<div class="alert-custom alert-error-custom" id="passwordAlert"></div>

<div style="display:grid; grid-template-columns:repeat(2,1fr); gap:80px; align-items:end; max-width:900px; margin:0 auto;">

    <div class="form-group">
        <label>Password <span style="color:red;">*</span></label>
        <div class="password-field">
            <input type="password" id="password" name="password" required
                   style="height:38px; padding:8px 40px 8px 12px;">
            <span class="toggle-password" onclick="togglePassword('password')">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                    <circle cx="12" cy="12" r="3"></circle>
                </svg>
            </span>
        </div>
        <!-- Strength Bar -->
        <div class="strength-bar-wrapper">
            <div class="strength-bar-track">
                <div class="strength-bar-fill" id="strengthBarFill"></div>
            </div>
            <div class="strength-label" id="strengthLabel"></div>
        </div>
        <!-- Rules Checklist -->
        <div class="password-rules" id="passwordRules">
            <div class="rule-item" id="rule-length"><span class="rule-icon">✗</span> Minimum 8 characters</div>
            <div class="rule-item" id="rule-upper"><span class="rule-icon">✗</span> At least 1 uppercase letter</div>
            <div class="rule-item" id="rule-lower"><span class="rule-icon">✗</span> At least 1 lowercase letter</div>
            <div class="rule-item" id="rule-number"><span class="rule-icon">✗</span> At least 1 number</div>
            <div class="rule-item" id="rule-special"><span class="rule-icon">✗</span> At least 1 special character (!@#$%^&*)</div>
        </div>
    </div>

    <div class="form-group">
        <label>Confirm Password <span style="color:red;">*</span></label>
        <div class="password-field">
            <input type="password" id="confirmPassword" name="confirmPassword" required
                   style="height:38px; padding:8px 40px 8px 12px;">
            <span class="toggle-password" onclick="togglePassword('confirmPassword')">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                    <circle cx="12" cy="12" r="3"></circle>
                </svg>
            </span>
        </div>
    </div>

</div>
</fieldset>

<!-- ================= BUTTONS ================= -->
<br>

<div style="text-align:center;">
    <button type="button" onclick="goBackToList();"
        style="padding:10px 22px; background:#373279; color:white;
               border:none; border-radius:6px; cursor:pointer;
               font-size:16px; font-weight:bold;">
        ← Back to List
    </button>
</div>

<div style="text-align:center; margin-top:30px;">

    <form id="authorizeForm" action="UserAuthorizationServlet" method="post" style="display:inline;">
        <input type="hidden" name="userId" value="<%=userId%>">
        <input type="hidden" name="branchCode" value="<%=branchCode%>">
        <input type="hidden" name="status" value="A">
        <input type="hidden" name="password" id="hiddenPassword">
        <button type="button" onclick="showAuthorizeConfirmation(event)"
            style="padding:10px 22px; background:linear-gradient(45deg,#28a745,#34ce57);
                   color:white; border:none; border-radius:6px; cursor:pointer;
                   font-size:16px; font-weight:bold;">
            ✔ Authorize
        </button>
    </form>

    &nbsp;&nbsp;&nbsp;

    <form id="rejectForm" action="UserAuthorizationServlet" method="post" style="display:inline;">
        <input type="hidden" name="userId" value="<%=userId%>">
        <input type="hidden" name="branchCode" value="<%=branchCode%>">
        <input type="hidden" name="status" value="R">
        <button type="button" onclick="showRejectConfirmation(event)"
            style="padding:10px 22px; background:linear-gradient(45deg,#dc3545,#e74c3c);
                   color:white; border:none; border-radius:6px; cursor:pointer;
                   font-size:16px; font-weight:bold;">
            ✘ Reject
        </button>
    </form>

</div>

<!-- ================= MODALS ================= -->
<div id="authorizeModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <span class="icon" style="color:#28a745;">✓</span>
            Confirm Authorization
        </div>
        <div class="modal-body">
            Are you sure you want to <strong>authorize</strong> this user?<br>
            User ID: <span class="app-number"><%=userId%></span>
        </div>
        <div class="modal-footer">
            <button class="modal-btn btn-cancel" onclick="closeModal('authorizeModal')">Cancel</button>
            <button class="modal-btn btn-confirm-authorize" onclick="submitAuthorize()">Yes, Authorize</button>
        </div>
    </div>
</div>

<div id="rejectModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <span class="icon" style="color:#dc3545;">✗</span>
            Confirm Rejection
        </div>
        <div class="modal-body">
            Are you sure you want to <strong>reject</strong> this user?<br>
            User ID: <span class="app-number"><%=userId%></span>
        </div>
        <div class="modal-footer">
            <button class="modal-btn btn-cancel" onclick="closeModal('rejectModal')">Cancel</button>
            <button class="modal-btn btn-confirm-reject" onclick="submitReject()">Yes, Reject</button>
        </div>
    </div>
</div>

<script>
window.onload = function() {
    let custId = document.getElementById("customerId").value;
    if (custId) {
        fetch("<%=request.getContextPath()%>/OpenAccount/getCustomerDetails.jsp?customerId=" + encodeURIComponent(custId))
        .then(res => res.json())
        .then(data => {
            if (data.success && data.customer) {
                let c = data.customer;
                document.getElementById("customerName").value = c.customerName || "";
                document.getElementById("phone").value        = c.residencePhone || "";
                document.getElementById("email").value        = c.email || "";
                document.getElementById("addr1").value        = c.address1 || "";
                document.getElementById("addr2").value        = c.address2 || "";
                document.getElementById("addr3").value        = c.address3 || "";
            }
        });
    }
};

function togglePassword(fieldId) {
    const field = document.getElementById(fieldId);
    const toggleIcon = field.parentElement.querySelector('.toggle-password svg');
    if (field.type === "password") {
        field.type = "text";
        toggleIcon.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line>';
    } else {
        field.type = "password";
        toggleIcon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>';
    }
}

// ========== PASSWORD STRENGTH CHECKER ==========
function checkPasswordStrength(password) {
    const rules = {
        length:  password.length >= 8,
        upper:   /[A-Z]/.test(password),
        lower:   /[a-z]/.test(password),
        number:  /[0-9]/.test(password),
        special: /[!@#$%^&*()_+\-=\[\]{};':"|,.<>\/?]/.test(password)
    };

    Object.keys(rules).forEach(function(key) {
        const el = document.getElementById('rule-' + key);
        if (!el) return;
        const icon = el.querySelector('.rule-icon');
        if (rules[key]) {
            el.classList.add('passed');
            icon.textContent = '✓';
        } else {
            el.classList.remove('passed');
            icon.textContent = '✗';
        }
    });

    const score = Object.values(rules).filter(Boolean).length;
    const bar = document.getElementById('strengthBarFill');
    const label = document.getElementById('strengthLabel');

    if (password.length === 0) {
        bar.style.width = '0%';
        bar.style.background = '';
        label.textContent = '';
    } else if (score <= 2) {
        bar.style.width = '33%';
        bar.style.background = '#ef4444';
        label.textContent = 'Weak';
        label.style.color = '#ef4444';
    } else if (score <= 4) {
        bar.style.width = '66%';
        bar.style.background = '#f59e0b';
        label.textContent = 'Medium';
        label.style.color = '#f59e0b';
    } else {
        bar.style.width = '100%';
        bar.style.background = '#22c55e';
        label.textContent = 'Strong';
        label.style.color = '#22c55e';
    }
}

// Show password strength and rules on input
document.addEventListener('DOMContentLoaded', function() {
    const passwordInput = document.getElementById('password');
    const confirmPasswordInput = document.getElementById('confirmPassword');
    
    if (passwordInput) {
        passwordInput.addEventListener('input', function() {
            document.querySelector('.strength-bar-wrapper').style.display = this.value.length > 0 ? 'block' : 'none';
            document.getElementById('passwordRules').classList.toggle('visible', this.value.length > 0);
            checkPasswordStrength(this.value);
        });
    }
});

function validatePasswords() {
    const password        = document.getElementById("password").value;
    const confirmPassword = document.getElementById("confirmPassword").value;
    const alert = document.getElementById("passwordAlert");

    alert.style.display = "none";
    alert.textContent = "";

    if (!password || password.trim() === "") {
        alert.textContent  = "❌ Password is required";
        alert.style.display = "block";
        return false;
    }
    if (password.length < 8) {
        alert.textContent  = "❌ Password must be at least 8 characters";
        alert.style.display = "block";
        return false;
    }

    // Validate strong password rules
    const pwRules = {
        length:  password.length >= 8,
        upper:   /[A-Z]/.test(password),
        lower:   /[a-z]/.test(password),
        number:  /[0-9]/.test(password),
        special: /[!@#$%^&*()_+\-=\[\]{};':"|,.<>\/?]/.test(password)
    };
    const ruleMessages = {
        length:  'at least 8 characters',
        upper:   'at least 1 uppercase letter',
        lower:   'at least 1 lowercase letter',
        number:  'at least 1 number',
        special: 'at least 1 special character'
    };
    const failedRules = Object.keys(pwRules).filter(k => !pwRules[k]);
    if (failedRules.length > 0) {
        alert.textContent = '❌ Password must contain ' + failedRules.map(k => ruleMessages[k]).join(', ') + '.';
        alert.style.display = 'block';
        return false;
    }

    if (!confirmPassword || confirmPassword.trim() === "") {
        alert.textContent  = "❌ Please confirm your password";
        alert.style.display = "block";
        return false;
    }
    if (password !== confirmPassword) {
        alert.textContent  = "❌ Passwords do not match";
        alert.style.display = "block";
        return false;
    }
    return true;
}

function goBackToList() {
    window.location.href = "<%=request.getContextPath()%>/Authorization/authorizationPendingUsers.jsp";
}

function showAuthorizeConfirmation(event) {
    event.preventDefault();
    if (!validatePasswords()) return;
    document.getElementById("authorizeModal").style.display = "block";
}

function showRejectConfirmation(event) {
    event.preventDefault();
    document.getElementById("rejectModal").style.display = "block";
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = "none";
}

function submitAuthorize() {
    document.getElementById("hiddenPassword").value = document.getElementById("password").value;
    document.getElementById("authorizeForm").submit();
}

function submitReject() {
    document.getElementById("rejectForm").submit();
}

window.onclick = function(event) {
    const authorizeModal = document.getElementById("authorizeModal");
    const rejectModal    = document.getElementById("rejectModal");
    if (event.target == authorizeModal) authorizeModal.style.display = "none";
    if (event.target == rejectModal)    rejectModal.style.display    = "none";
};
</script>

</body>
</html>
