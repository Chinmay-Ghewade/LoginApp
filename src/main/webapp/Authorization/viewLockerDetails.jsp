<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String branchCode  = (String) sess.getAttribute("branchCode");
    String customerId  = request.getParameter("customerId");

    if (customerId == null || customerId.trim().isEmpty()) {
        response.sendRedirect("authorizationPendingLockers.jsp");
        return;
    }

    // Variables for display
    String dbCustomerId    = "";
    String nameOfHire      = "";
    String dbBranchCode    = "";
    String dateOfHire      = "";
    String keyNo           = "";
    String lockerType      = "";
    String lockerNumber    = "";
    String addressLine1    = "";
    String addressLine2    = "";
    String addressLine3    = "";
    String pin             = "";
    String mobileNo        = "";
    String nominee         = "";
    String errorMsg        = "";

    try (Connection conn = DBConnection.getConnection()) {

        PreparedStatement ps = conn.prepareStatement(
            "SELECT " +
            "  l.CUSTOMER_ID, " +
            "  NVL(l.NAME_OF_HIRE,   '')  AS NAME_OF_HIRE, " +
            "  l.BRANCH_CODE, " +
            "  TO_CHAR(l.DATE_OF_HIRE, 'DD-Mon-YYYY') AS DATE_OF_HIRE, " +
            "  NVL(l.KEY_NO,          '')  AS KEY_NO, " +
            "  NVL(l.LOCKER_TYPE,     '')  AS LOCKER_TYPE, " +
            "  NVL(TO_CHAR(l.LOCKER_NUMBER), '') AS LOCKER_NUMBER, " +
            "  NVL(l.ADDRESS_LINE1,   '')  AS ADDRESS_LINE1, " +
            "  NVL(l.ADDRESS_LINE2,   '')  AS ADDRESS_LINE2, " +
            "  NVL(l.ADDRESS_LINE3,   '')  AS ADDRESS_LINE3, " +
            "  NVL(l.PIN,             '')  AS PIN, " +
            "  NVL(l.MOBILE_NO,       '')  AS MOBILE_NO, " +
            "  NVL(l.NOMINEE,         '')  AS NOMINEE " +
            "FROM ACCOUNT.LOCKERACCOUNT l " +
            "WHERE l.CUSTOMER_ID = ? " +
            "  AND l.BRANCH_CODE = ? " +
            "  AND l.ACCOUNT_STATUS = 'E' " +
            "AND ROWNUM = 1"
        );

        ps.setString(1, customerId);
        ps.setString(2, branchCode);

        ResultSet rs = ps.executeQuery();

        if (rs.next()) {
            dbCustomerId  = rs.getString("CUSTOMER_ID")   != null ? rs.getString("CUSTOMER_ID")   : "";
            nameOfHire    = rs.getString("NAME_OF_HIRE")  != null ? rs.getString("NAME_OF_HIRE")  : "";
            dbBranchCode  = rs.getString("BRANCH_CODE")   != null ? rs.getString("BRANCH_CODE")   : "";
            dateOfHire    = rs.getString("DATE_OF_HIRE")  != null ? rs.getString("DATE_OF_HIRE")  : "";
            keyNo         = rs.getString("KEY_NO")         != null ? rs.getString("KEY_NO")         : "";
            lockerType    = rs.getString("LOCKER_TYPE")   != null ? rs.getString("LOCKER_TYPE")   : "";
            lockerNumber  = rs.getString("LOCKER_NUMBER") != null ? rs.getString("LOCKER_NUMBER") : "";
            addressLine1  = rs.getString("ADDRESS_LINE1") != null ? rs.getString("ADDRESS_LINE1") : "";
            addressLine2  = rs.getString("ADDRESS_LINE2") != null ? rs.getString("ADDRESS_LINE2") : "";
            addressLine3  = rs.getString("ADDRESS_LINE3") != null ? rs.getString("ADDRESS_LINE3") : "";
            pin           = rs.getString("PIN")            != null ? rs.getString("PIN")            : "";
            mobileNo      = rs.getString("MOBILE_NO")     != null ? rs.getString("MOBILE_NO")     : "";
            nominee       = rs.getString("NOMINEE")       != null ? rs.getString("NOMINEE")       : "";
        } else {
            errorMsg = "No locker record found for Customer ID: " + customerId;
        }

    } catch (Exception e) {
        errorMsg = "Database error: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Locker Details - <%= customerId %></title>
<link rel="stylesheet" href="../css/locker.css">
<link rel="stylesheet" href="../css/addCustomer.css">
<script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>

<style>

.btn-container {
    display: flex;
    justify-content: center;
    gap: 15px;
    margin-top: 25px;
    flex-wrap: wrap;
}

.btn {
    padding: 10px 28px;
    border: none;
    border-radius: 6px;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
    transition: opacity 0.2s;
}

.btn:hover { opacity: 0.88; }

.btn-back {
    background: #2b0d73;
    color: white;
}

.btn-authorize {
    background: #28a745;
    color: white;
}

.btn-reject {
    background: #dc3545;
    color: white;
}

.error-msg {
    background: #ffe0e0;
    color: #c00;
    border: 1px solid #f5c6cb;
    border-radius: 6px;
    padding: 12px 18px;
    margin-bottom: 20px;
    font-weight: bold;
}

/* ===== Modal Overlay ===== */
.modal-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.45);
    z-index: 1000;
    justify-content: center;
    align-items: center;
}

.modal-overlay.active {
    display: flex;
}

.modal-box {
    background: #fff;
    border-radius: 16px;
    padding: 40px 36px 32px 36px;
    width: 420px;
    max-width: 92vw;
    box-shadow: 0 8px 40px rgba(0,0,0,0.18);
    text-align: center;
    animation: modalIn 0.2s ease;
}

@keyframes modalIn {
    from { transform: scale(0.92); opacity: 0; }
    to   { transform: scale(1);    opacity: 1; }
}

.modal-icon {
    font-size: 36px;
    font-weight: bold;
    margin-bottom: 10px;
}

.auth-icon {
    color: #28a745;
}

.reject-icon {
    color: #dc3545;
}

.modal-title {
    font-size: 22px;
    font-weight: bold;
    color: #2b0d73;
    margin-bottom: 12px;
}

.modal-title.reject-title {
    color: #dc3545;
}

.modal-message {
    font-size: 14px;
    color: #444;
    margin-bottom: 16px;
    line-height: 1.6;
}

.modal-info {
    background: #f4f4f8;
    border-radius: 8px;
    padding: 12px 16px;
    margin-bottom: 24px;
    text-align: left;
}

.modal-info-row {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    padding: 4px 0;
    border-bottom: 1px solid #e0e0e8;
}

.modal-info-row:last-child {
    border-bottom: none;
}

.modal-info-row span:first-child {
    color: #666;
    font-weight: 600;
}

.modal-info-row span:last-child {
    color: #2b0d73;
    font-weight: bold;
}

.modal-btn-row {
    display: flex;
    gap: 14px;
    justify-content: center;
}

.modal-btn-cancel {
    padding: 10px 28px;
    border: none;
    border-radius: 8px;
    background: #e0e0e0;
    color: #333;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
    transition: background 0.2s;
}

.modal-btn-cancel:hover { background: #ccc; }

.modal-btn-confirm-auth {
    padding: 10px 28px;
    border: none;
    border-radius: 8px;
    background: #28a745;
    color: #fff;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
    transition: background 0.2s;
}

.modal-btn-confirm-auth:hover { background: #218838; }

.modal-btn-confirm-reject {
    padding: 10px 28px;
    border: none;
    border-radius: 8px;
    background: #dc3545;
    color: #fff;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
    transition: background 0.2s;
}

.modal-btn-confirm-reject:hover { background: #b02a37; }

@media (max-width: 900px) {
    .form-grid-4 { grid-template-columns: repeat(2, 1fr); }
    .form-grid-3 { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 540px) {
    .form-grid-4,
    .form-grid-3,
    .form-grid-2 { grid-template-columns: 1fr; }
}
</style>
</head>
<body>

<div class="page-wrapper">

<h2 style="text-align:center; color:#2b0d73; margin-bottom:20px;">Locker Details</h2>

<% if (!errorMsg.isEmpty()) { %>
    <div class="error-msg"><%= errorMsg %></div>
<% } else { %>

    <%-- ====== Fieldset 1: Customer Details ====== --%>
    <fieldset>
        <legend>Customer Details</legend>
        <div class="form-grid form-grid-4">
            <div class="form-group">
                <label>Customer ID</label>
                <input type="text" value="<%= dbCustomerId %>" readonly>
            </div>
            <div class="form-group">
                <label>Name</label>
                <input type="text" value="<%= nameOfHire %>" readonly>
            </div>
            <div class="form-group">
                <label>Branch Code</label>
                <input type="text" value="<%= dbBranchCode %>" readonly>
            </div>
            <div class="form-group">
                <label>Date of Hire</label>
                <input type="text" value="<%= dateOfHire %>" readonly>
            </div>
        </div>
    </fieldset>

    <%-- ====== Fieldset 2: Locker Details ====== --%>
    <fieldset>
        <legend>Locker Details</legend>
        <div class="form-grid form-grid-3">
            <div class="form-group">
                <label>Key No</label>
                <input type="text" value="<%= keyNo %>" readonly>
            </div>
            <div class="form-group">
                <label>Locker Type</label>
                <input type="text" value="<%= lockerType %>" readonly>
            </div>
            <div class="form-group">
                <label>Locker Number</label>
                <input type="text" value="<%= lockerNumber %>" readonly>
            </div>
        </div>
    </fieldset>

    <%-- ====== Fieldset 3: Other Details ====== --%>
    <fieldset>
        <legend>Other Details</legend>
        <div class="form-grid form-grid-3">
            <div class="form-group">
                <label>Address Line 1</label>
                <input type="text" value="<%= addressLine1 %>" readonly>
            </div>
            <div class="form-group">
                <label>Address Line 2</label>
                <input type="text" value="<%= addressLine2 %>" readonly>
            </div>
            <div class="form-group">
                <label>Address Line 3</label>
                <input type="text" value="<%= addressLine3 %>" readonly>
            </div>
            <div class="form-group">
                <label>PIN</label>
                <input type="text" value="<%= pin %>" readonly>
            </div>
            <div class="form-group">
                <label>Mobile No</label>
                <input type="text" value="<%= mobileNo %>" readonly>
            </div>
            <div class="form-group">
                <label>Nominee</label>
                <input type="text" value="<%= nominee %>" readonly>
            </div>
        </div>
    </fieldset>

<% } %>

    <%-- ====== Buttons ====== --%>
    <div class="btn-container">
        <button class="btn btn-back" onclick="goBack()">← Back to List</button>
        <% if (errorMsg.isEmpty()) { %>
        <button class="btn btn-authorize" onclick="authorizeLocker()">✔ Authorize</button>
        <button class="btn btn-reject"    onclick="rejectLocker()">✘ Reject</button>
        <% } %>
    </div>

</div>

<!-- ===== Authorize Modal ===== -->
<div class="modal-overlay" id="authorizeModal">
    <div class="modal-box">
        <div class="modal-icon auth-icon">&#10003;</div>
        <div class="modal-title">Confirm Authorization</div>
        <p class="modal-message">Are you sure you want to <strong>authorize</strong> this locker?</p>
        <div class="modal-info">
            <div class="modal-info-row">
                <span>Name</span>
                <span><%= nameOfHire %></span>
            </div>
            <div class="modal-info-row">
                <span>Key No</span>
                <span><%= keyNo %></span>
            </div>
            <div class="modal-info-row">
                <span>Locker Type</span>
                <span><%= lockerType %></span>
            </div>
            <div class="modal-info-row">
                <span>Locker Number</span>
                <span><%= lockerNumber %></span>
            </div>
        </div>
        <div class="modal-btn-row">
            <button class="modal-btn-cancel" onclick="closeModal('authorizeModal')">Cancel</button>
            <button class="modal-btn-confirm-auth" onclick="confirmAction('AUTHORIZE')">Yes, Authorize</button>
        </div>
    </div>
</div>

<!-- ===== Reject Modal ===== -->
<div class="modal-overlay" id="rejectModal">
    <div class="modal-box">
        <div class="modal-icon reject-icon">&#10007;</div>
        <div class="modal-title reject-title">Confirm Rejection</div>
        <p class="modal-message">Are you sure you want to <strong>reject</strong> this locker?</p>
        <div class="modal-info">
            <div class="modal-info-row">
                <span>Name</span>
                <span><%= nameOfHire %></span>
            </div>
            <div class="modal-info-row">
                <span>Key No</span>
                <span><%= keyNo %></span>
            </div>
            <div class="modal-info-row">
                <span>Locker Type</span>
                <span><%= lockerType %></span>
            </div>
            <div class="modal-info-row">
                <span>Locker Number</span>
                <span><%= lockerNumber %></span>
            </div>
        </div>
        <div class="modal-btn-row">
            <button class="modal-btn-cancel" onclick="closeModal('rejectModal')">Cancel</button>
            <button class="modal-btn-confirm-reject" onclick="confirmAction('REJECT')">Yes, Reject</button>
        </div>
    </div>
</div>

<script>
function goBack() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('authorizationPendingLockers.jsp')
        );
    }
    window.location.replace('authorizationPendingLockers.jsp');
}

function authorizeLocker() {
    document.getElementById('authorizeModal').classList.add('active');
}

function rejectLocker() {
    document.getElementById('rejectModal').classList.add('active');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

function confirmAction(action) {
    window.location.href = 'authorizeLockerAction.jsp?customerId=<%= customerId %>&branchCode=<%= branchCode %>&action=' + action;
}

// Close modal on overlay click
document.querySelectorAll('.modal-overlay').forEach(function(overlay) {
    overlay.addEventListener('click', function(e) {
        if (e.target === overlay) overlay.classList.remove('active');
    });
});

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('viewLockerDetails.jsp')
        );
    }
};
</script>

</body>
</html>
