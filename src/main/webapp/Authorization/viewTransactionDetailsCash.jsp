<%@ page import="java.sql.*, db.DBConnection, java.text.SimpleDateFormat, java.util.Date" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String branchCode = (String) sess.getAttribute("branchCode");
%>

<%! 
    String getStringSafe(ResultSet r, String col) throws SQLException {
        String v = r.getString(col);
        return (v == null) ? "" : v;
    }
    
    String formatDateForInput(ResultSet r, String col) throws SQLException {
        java.sql.Timestamp ts = null;
        try {
            ts = r.getTimestamp(col);
        } catch (Exception ex) {
            try {
                java.sql.Date d = r.getDate(col);
                if (d != null) ts = new java.sql.Timestamp(d.getTime());
            } catch (Exception ignore) {}
        }
        if (ts == null) return "";
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return sdf.format(new java.util.Date(ts.getTime()));
    }
%>

<%
    String scrollNumber = request.getParameter("scrollNumber");
    if (scrollNumber == null || scrollNumber.trim().isEmpty()) {
        out.println("<h3 style='color:red;'>Scroll Number not provided.</h3>");
        return;
    }

    Connection conn = null;
    PreparedStatement psTransaction = null;
    ResultSet rsTransaction = null;

    try {
        conn = DBConnection.getConnection();
        
        // Fetch transaction details with all columns
        psTransaction = conn.prepareStatement(
            "SELECT " +
            "  BRANCH_CODE, " +
            "  SCROLL_NUMBER, " +
            "  SUBSCROLL_NUMBER, " +
            "  ACCOUNT_CODE, " +
            "  GLACCOUNT_CODE, " +
            "  FORACCOUNT_CODE, " +
            "  TRANSACTIONINDICATOR_CODE, " +
            "  AMOUNT, " +
            "  ACCOUNTBALANCE, " +
            "  GLACCOUNTBALANCE, " +
            "  CHEQUE_TYPE, " +
            "  CHEQUESERIES, " +
            "  CHEQUENUMBER, " +
            "  CHEQUEDATE, " +
            "  TRANIDENTIFICATION_ID, " +
            "  PARTICULAR, " +
            "  USER_ID, " +
            "  CASHHANDLING_NUMBER, " +
            "  GLBRANCH_CODE " +
            "FROM TRANSACTION.DAILYSCROLL " +
            "WHERE SCROLL_NUMBER = ? " +
            "  AND TRANSACTIONSTATUS = 'E' " +
            "  AND TRANSACTIONINDICATOR_CODE LIKE 'CS%' "
        );
        psTransaction.setString(1, scrollNumber);
        rsTransaction = psTransaction.executeQuery();

        if (!rsTransaction.next()) {
            out.println("<h3 style='color:red;'>No transaction found with number: " + scrollNumber + "</h3>");
            return;
        }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>View Cash Transaction — <%= scrollNumber %></title>
  <link rel="stylesheet" href="../css/addCustomer.css">
  <link rel="stylesheet" href="../css/authViewCustomers.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <script>
    window.onload = function() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb(
                window.buildBreadcrumbPath('viewTransactionDetailsCash.jsp', 'authorizationPendingTransactionCash.jsp')
            );
        }
    };

    function goBackToList() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb(
                window.buildBreadcrumbPath('authorizationPendingTransactionCash.jsp')
            );
        }
        window.location.href = 'authorizationPendingTransactionCash.jsp';
    }

    function showAuthorizeConfirmation(event) {
        event.preventDefault();
        document.getElementById('authorizeModal').style.display = 'block';
    }

    function showRejectConfirmation(event) {
        event.preventDefault();
        document.getElementById('rejectModal').style.display = 'block';
    }

    function closeAuthorizeModal() {
        document.getElementById('authorizeModal').style.display = 'none';
    }

    function closeRejectModal() {
        document.getElementById('rejectModal').style.display = 'none';
    }

    function confirmAuthorize() {
        document.getElementById('authorizeForm').submit();
    }

    function confirmReject() {
        document.getElementById('rejectForm').submit();
    }

    window.onclick = function(event) {
        const authorizeModal = document.getElementById('authorizeModal');
        const rejectModal = document.getElementById('rejectModal');
        if (event.target === authorizeModal) {
            closeAuthorizeModal();
        }
        if (event.target === rejectModal) {
            closeRejectModal();
        }
    }

    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeAuthorizeModal();
            closeRejectModal();
        }
    });
  </script>
</head>
<body>

<form>
    <!-- ================= TRANSACTION DETAILS ================= -->
    <fieldset>
      <legend>Transaction Details</legend>
      <div class="form-grid">
        <div>
          <label>BRANCH CODE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "BRANCH_CODE") %>">
        </div>
        <div>
          <label>SCROLL NUMBER</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "SCROLL_NUMBER") %>">
        </div>
        <div>
          <label>SUB SCROLL NUMBER</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "SUBSCROLL_NUMBER") %>">
        </div>
        <div>
          <label>ACCOUNT CODE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "ACCOUNT_CODE") %>">
        </div>
        <div>
          <label>GL ACCOUNT CODE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "GLACCOUNT_CODE") %>">
        </div>
        <div>
          <label>FOR ACCOUNT CODE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "FORACCOUNT_CODE") %>">
        </div>
        <div>
          <label>TRANSACTION INDICATOR CODE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "TRANSACTIONINDICATOR_CODE") %>">
        </div>
        <div>
          <label>AMOUNT</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "AMOUNT") %>">
        </div>
        <div>
          <label>ACCOUNT BALANCE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "ACCOUNTBALANCE") %>">
        </div>
        <div>
          <label>GL ACCOUNT BALANCE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "GLACCOUNTBALANCE") %>">
        </div>
        <div>
          <label>CHEQUE TYPE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "CHEQUE_TYPE") %>">
        </div>
        <div>
          <label>CHEQUE SERIES</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "CHEQUESERIES") %>">
        </div>
        <div>
          <label>CHEQUE NUMBER</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "CHEQUENUMBER") %>">
        </div>
        <div>
          <label>CHEQUE DATE</label>
          <input readonly value="<%= formatDateForInput(rsTransaction, "CHEQUEDATE") %>">
        </div>
        <div>
          <label>TRANIDENT IFICATION ID</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "TRANIDENTIFICATION_ID") %>">
        </div>
        <div>
          <label>PARTICULAR</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "PARTICULAR") %>">
        </div>
        <div>
          <label>USER_ID</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "USER_ID") %>">
        </div>
        <div>
          <label>CASHHANDLING_NUMBER</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "CASHHANDLING_NUMBER") %>">
        </div>
        <div>
          <label>GLBRANCH_CODE</label>
          <input readonly value="<%= getStringSafe(rsTransaction, "GLBRANCH_CODE") %>">
        </div>
      </div>
    </fieldset>

    <div style="text-align:center;">
        <button type="button" onclick="goBackToList();" class="back-btn"
            style="padding:10px 22px; background:#373279; color:white;
                   border:none; border-radius:6px; cursor:pointer;
                   font-size:16px; font-weight:bold;">
            ← Back to List
        </button>
    </div>
</form>

<!-- ================= AUTHORIZE / REJECT BUTTONS ================= -->
<div style="text-align:center; margin-top:30px;">
<form id="authorizeForm" action="UpdateTransactionStatusServlet" method="post" style="display:inline;">
    <input type="hidden" name="scrollNumber" value="<%= getStringSafe(rsTransaction, "SCROLL_NUMBER") %>">
    <input type="hidden" name="type" value="CASH">
    <input type="hidden" name="status" value="A">
    <button type="button" onclick="showAuthorizeConfirmation(event)"
        style="padding:10px 22px; background:linear-gradient(45deg, #28a745, #34ce57); color:white;
               border:none; border-radius:6px; cursor:pointer;
               font-size:16px; font-weight:bold;">
        ✔ Authorize
    </button>
</form>

<!-- REJECT FORM -->
<form id="rejectForm" action="UpdateTransactionStatusServlet" method="post" style="display:inline;">
    <input type="hidden" name="scrollNumber" value="<%= getStringSafe(rsTransaction, "SCROLL_NUMBER") %>">
    <input type="hidden" name="type" value="CASH">
    <input type="hidden" name="status" value="R">
    <button type="button" onclick="showRejectConfirmation(event)"
        style="padding:10px 22px; background:linear-gradient(45deg, #dc3545, #e74c3c); color:white;
               border:none; border-radius:6px; cursor:pointer;
               font-size:16px; font-weight:bold;">
        ✘ Reject
    </button>
</form>
</div>

<!-- ================= AUTHORIZE MODAL ================= -->
<div id="authorizeModal" class="confirmation-modal">
    <div class="confirmation-modal-content">
        <h2>✔ Confirm Authorization</h2>
        <p>Are you sure you want to <strong>authorize</strong> this transaction?<br>Scroll Number: <strong><%= getStringSafe(rsTransaction, "SCROLL_NUMBER") %></strong></p>
        <div class="confirmation-modal-buttons">
            <button class="confirmation-btn confirmation-btn-cancel" onclick="closeAuthorizeModal()">Cancel</button>
            <button class="confirmation-btn confirmation-btn-confirm" onclick="confirmAuthorize()">Yes, Authorize</button>
        </div>
    </div>
</div>

<!-- ================= REJECT MODAL ================= -->
<div id="rejectModal" class="confirmation-modal">
    <div class="confirmation-modal-content">
        <h2>✘ Confirm Rejection</h2>
        <p>Are you sure you want to <strong>reject</strong> this transaction?<br>Scroll Number: <strong><%= getStringSafe(rsTransaction, "SCROLL_NUMBER") %></strong></p>
        <div class="confirmation-modal-buttons">
            <button class="confirmation-btn confirmation-btn-cancel" onclick="closeRejectModal()">Cancel</button>
            <button class="confirmation-btn confirmation-btn-reject" onclick="confirmReject()">Yes, Reject</button>
        </div>
    </div>
</div>

</body>
</html>

<%
    } 
    catch (Exception e) {
        out.println("<pre style='color:red'>Error: " + e.getMessage() + "</pre>");
        e.printStackTrace();
    } 
    finally {
        try { if (rsTransaction != null) rsTransaction.close(); } catch (Exception ex) {}
        try { if (psTransaction != null) psTransaction.close(); } catch (Exception ex) {}
        try { if (conn != null) conn.close(); } catch (Exception ex) {}
    }
%>
