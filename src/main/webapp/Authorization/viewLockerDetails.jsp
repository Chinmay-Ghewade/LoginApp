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
<link rel="stylesheet" href="../css/totalCustomers.css">
<script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>

<style>
* {
    box-sizing: border-box;
}

body {
    background: #e8e8f0;
    font-family: Arial, sans-serif;
    padding: 20px;
}

.page-wrapper {
    max-width: 1200px;
    margin: 0 auto;
    padding: 10px;
}

fieldset {
    border: 1.5px solid #b0b8d0;
    border-radius: 8px;
    padding: 20px 25px 15px 25px;
    margin-bottom: 20px;
    background: #fff;
}

legend {
    font-size: 15px;
    font-weight: bold;
    color: #2b0d73;
    padding: 0 10px;
}

.form-grid {
    display: grid;
    gap: 15px 20px;
}

.form-grid-4 { grid-template-columns: repeat(4, 1fr); }
.form-grid-3 { grid-template-columns: repeat(3, 1fr); }
.form-grid-2 { grid-template-columns: repeat(2, 1fr); }

.form-group {
    display: flex;
    flex-direction: column;
    gap: 5px;
}

.form-group label {
    font-size: 13px;
    font-weight: bold;
    color: #2b0d73;
}

.form-group input[type="text"] {
    padding: 8px 10px;
    border: 1px solid #ccc;
    border-radius: 4px;
    background: #f0f0f0;
    font-size: 13px;
    color: #333;
    width: 100%;
    cursor: default;
}

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
    if (confirm('Are you sure you want to AUTHORIZE this locker?')) {
        window.location.href = 'authorizeLockerAction.jsp?customerId=<%= customerId %>&branchCode=<%= branchCode %>&action=AUTHORIZE';
    }
}

function rejectLocker() {
    if (confirm('Are you sure you want to REJECT this locker?')) {
        window.location.href = 'authorizeLockerAction.jsp?customerId=<%= customerId %>&branchCode=<%= branchCode %>&action=REJECT';
    }
}

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
