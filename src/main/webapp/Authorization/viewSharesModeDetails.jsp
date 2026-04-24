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
<%
    String workingDateStr = "";
    Object wdObj = sess.getAttribute("workingDate");
    if (wdObj instanceof java.util.Date) {
        java.text.SimpleDateFormat sdfWd = new java.text.SimpleDateFormat("dd/MM/yyyy");
        workingDateStr = sdfWd.format((java.util.Date) wdObj);
    }
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
            "WHERE SCROLL_NUMBER = ?"
        );
        psTransaction.setString(1, scrollNumber);
        rsTransaction = psTransaction.executeQuery();

        if (!rsTransaction.next()) {
            out.println("<h3 style='color:red;'>No transaction found with scroll number: " + scrollNumber + "</h3>");
            return;
        }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>View Shares Transaction</title>
  <link rel="stylesheet" href="../css/addCustomer.css">
  <link rel="stylesheet" href="../css/authViewCustomers.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <script>
    window.onload = function() {
        // ✅ Replace current history entry so browser back won't return here
        history.replaceState(null, '', window.location.href);

        var params = new URLSearchParams(window.location.search);
        if (params.get('balanceError')) {
            var msg = decodeURIComponent(params.get('balanceError'));
            var parts = msg.split('|');
            var html = parts.map(function(p) { return p.trim(); }).join('<br>');
            document.getElementById('balanceErrorMsg').innerHTML = html;
            document.getElementById('balanceErrorModal').style.display = 'block';
        }
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb(
                window.buildBreadcrumbPath('viewSharesModeDetails.jsp', 'authorizationSharesMode.jsp')
            );
        }
    };

    // ✅ Handle browser back button — redirect to list instead of going back to details
    window.addEventListener('popstate', function(event) {
        window.location.replace('authorizationSharesMode.jsp');
    });

    function closeBalanceErrorModal() {
        document.getElementById('balanceErrorModal').style.display = 'none';
        var url = new URL(window.location.href);
        url.searchParams.delete('balanceError');
        window.history.replaceState({}, '', url);
    }

    // ✅ Back button uses replace() so it won't add list to history stack again
    function goBackToList() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb(
                window.buildBreadcrumbPath('authorizationSharesMode.jsp')
            );
        }
        window.location.replace('authorizationSharesMode.jsp');
    }

    function showAuthorizeConfirmation(event) {
        event.preventDefault();
        const btn = event.target;
        btn.disabled = true;
        btn.textContent = 'Validating...';

        const params = new URLSearchParams({
            accountCode:          VALIDATE_ACCOUNT_CODE,
            workingDate:          VALIDATE_WORKING_DATE,
            transactionIndicator: VALIDATE_TXN_INDICATOR,
            transactionAmount:    VALIDATE_AMOUNT
        });

        fetch('../Transactions/ValidateTransaction.jsp?' + params.toString())
            .then(res => res.json())
            .then(data => {
                btn.disabled = false;
                btn.innerHTML = '&#10004; Authorize';
                if (data.error) { showValidationError('Validation Error: ' + data.error); return; }
                if (data.success === false) {
                    showValidationError(data.message || 'Transaction validation failed.');
                } else {
                    document.getElementById('authorizeModal').style.display = 'block';
                }
            })
            .catch(err => {
                btn.disabled = false;
                btn.innerHTML = '&#10004; Authorize';
                showValidationError('Network error during validation: ' + err.message);
            });
    }

    function showValidationError(message) {
        document.getElementById('validationErrorMsg').textContent = message;
        document.getElementById('validationErrorModal').style.display = 'block';
    }
    function closeValidationErrorModal() { document.getElementById('validationErrorModal').style.display = 'none'; }
    function showRejectConfirmation(event) { event.preventDefault(); document.getElementById('rejectModal').style.display = 'block'; }
    function closeAuthorizeModal() { document.getElementById('authorizeModal').style.display = 'none'; }
    function closeRejectModal()    { document.getElementById('rejectModal').style.display = 'none'; }
    function confirmAuthorize()    { document.getElementById('authorizeForm').submit(); }
    function confirmReject()       { document.getElementById('rejectForm').submit(); }

    window.onclick = function(event) {
        if (event.target === document.getElementById('authorizeModal'))       closeAuthorizeModal();
        if (event.target === document.getElementById('rejectModal'))          closeRejectModal();
        if (event.target === document.getElementById('validationErrorModal')) closeValidationErrorModal();
        if (event.target === document.getElementById('balanceErrorModal'))    closeBalanceErrorModal();
    };
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') { closeAuthorizeModal(); closeRejectModal(); closeValidationErrorModal(); closeBalanceErrorModal(); }
    });

    const VALIDATE_ACCOUNT_CODE  = "<%=getStringSafe(rsTransaction,"ACCOUNT_CODE")%>";
    const VALIDATE_TXN_INDICATOR = "<%=getStringSafe(rsTransaction,"TRANSACTIONINDICATOR_CODE")%>";
    const VALIDATE_AMOUNT        = "<%=getStringSafe(rsTransaction,"AMOUNT")%>";
    const VALIDATE_WORKING_DATE  = "<%=workingDateStr%>";

    function showTransactionVoucher() {
        const urlParams = new URLSearchParams(window.location.search);
        const voucherScrollNumber = urlParams.get('scrollNumber');
        if (!voucherScrollNumber) { alert('Scroll number not found in URL'); return; }
        const sessionWorkingDate = '<%=workingDateStr%>';
        fetchVoucherData(voucherScrollNumber, sessionWorkingDate);
        document.getElementById('voucherModal').style.display = 'flex';
    }
    function closeVoucherModal() { document.getElementById('voucherModal').style.display = 'none'; }

    function fetchVoucherData(scrollNumber, workingDate) {
        const c = document.getElementById('voucherTableContainer');
        c.innerHTML = '<p style="text-align:center;color:#8066E8;">Loading voucher data...</p>';
        fetch('../Transactions/GetDailyScrollData.jsp?' + new URLSearchParams({scrollNumber, workingDate}))
            .then(r => r.json())
            .then(data => {
                if (data.error) { c.innerHTML = '<p style="color:#e74c3c;text-align:center;">Error: '+data.error+'</p>'; return; }
                if (data.rows && data.rows.length > 0) displayVoucherTable(data.rows);
                else c.innerHTML = '<p style="color:#7f8c8d;text-align:center;">No voucher records found</p>';
            })
            .catch(() => { c.innerHTML = '<p style="color:#e74c3c;text-align:center;">Failed to load voucher data</p>'; });
    }

    function displayVoucherTable(rows) {
        let html = '<table style="width:100%;border-collapse:collapse;border:1px solid #ddd;">';
        html += '<thead style="background:#373279;color:white;font-size:12px;"><tr>';
        ['SR NO','SCROLL NO','SUB SR','ACCOUNT CODE','FOR ACCOUNT CODE','TXN INDICATOR','AMOUNT','PARTICULAR']
            .forEach(h => html += '<th style="padding:12px;border:1px solid #ddd;">'+h+'</th>');
        html += '</tr></thead><tbody>';
        rows.forEach((row, i) => {
            const bg = i % 2 === 0 ? '#f9f9f9' : '#fff';
            const amt = parseFloat(row.amount)||0;
            html += '<tr style="background:'+bg+';font-size:14px;">';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:center;">'+row.srNo+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:center;">'+row.scrollNumber+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:center;">'+row.subscrollNumber+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:center;font-weight:bold;">'+row.accountCode+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:center;font-weight:bold;">'+(row.forAccountCode||'-')+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:center;">'+(row.transactionIndicator||'-')+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;text-align:right;font-weight:bold;">&#8377; '+amt.toFixed(2)+'</td>';
            html += '<td style="padding:10px;border:1px solid #ddd;">'+(row.particular||'-')+'</td>';
            html += '</tr>';
        });
        html += '</tbody></table>';
        document.getElementById('voucherTableContainer').innerHTML = html;
    }
  </script>
</head>
<body>

<form>
  <fieldset>
    <legend>Shares Transaction Details</legend>
    <div class="form-grid">
      <div><label>BRANCH CODE</label><input readonly value="<%=getStringSafe(rsTransaction,"BRANCH_CODE")%>"></div>
      <div><label>SCROLL NUMBER</label><input readonly value="<%=getStringSafe(rsTransaction,"SCROLL_NUMBER")%>"></div>
      <div><label>SUB SCROLL NUMBER</label><input readonly value="<%=getStringSafe(rsTransaction,"SUBSCROLL_NUMBER")%>"></div>
      <div><label>ACCOUNT CODE</label><input readonly value="<%=getStringSafe(rsTransaction,"ACCOUNT_CODE")%>"></div>
      <div><label>GL ACCOUNT CODE</label><input readonly value="<%=getStringSafe(rsTransaction,"GLACCOUNT_CODE")%>"></div>
      <div><label>FOR ACCOUNT CODE</label><input readonly value="<%=getStringSafe(rsTransaction,"FORACCOUNT_CODE")%>"></div>
      <div><label>TRANSACTION INDICATOR CODE</label><input readonly value="<%=getStringSafe(rsTransaction,"TRANSACTIONINDICATOR_CODE")%>"></div>
      <div><label>AMOUNT</label><input readonly value="<%=getStringSafe(rsTransaction,"AMOUNT")%>"></div>
      <div><label>ACCOUNT BALANCE</label><input readonly value="<%=getStringSafe(rsTransaction,"ACCOUNTBALANCE")%>"></div>
      <div><label>GL ACCOUNT BALANCE</label><input readonly value="<%=getStringSafe(rsTransaction,"GLACCOUNTBALANCE")%>"></div>
      <div><label>CHEQUE TYPE</label><input readonly value="<%=getStringSafe(rsTransaction,"CHEQUE_TYPE")%>"></div>
      <div><label>CHEQUE SERIES</label><input readonly value="<%=getStringSafe(rsTransaction,"CHEQUESERIES")%>"></div>
      <div><label>CHEQUE NUMBER</label><input readonly value="<%=getStringSafe(rsTransaction,"CHEQUENUMBER")%>"></div>
      <div><label>CHEQUE DATE</label><input readonly value="<%=formatDateForInput(rsTransaction,"CHEQUEDATE")%>"></div>
      <div><label>TRANIDENTIFICATION ID</label><input readonly value="<%=getStringSafe(rsTransaction,"TRANIDENTIFICATION_ID")%>"></div>
      <div><label>PARTICULAR</label><input readonly value="<%=getStringSafe(rsTransaction,"PARTICULAR")%>"></div>
      <div><label>USER ID</label><input readonly value="<%=getStringSafe(rsTransaction,"USER_ID")%>"></div>
      <div><label>CASHHANDLING NUMBER</label><input readonly value="<%=getStringSafe(rsTransaction,"CASHHANDLING_NUMBER")%>"></div>
      <div><label>GL BRANCH CODE</label><input readonly value="<%=getStringSafe(rsTransaction,"GLBRANCH_CODE")%>"></div>
    </div>
  </fieldset>

  <div style="text-align:center;">
    <button type="button" onclick="goBackToList();" class="back-btn"
        style="padding:10px 22px;background:#373279;color:white;border:none;border-radius:6px;cursor:pointer;font-size:16px;font-weight:bold;">
        ← Back to List
    </button>
    <button type="button" onclick="showTransactionVoucher()"
        style="background:#373279;color:white;padding:12px 25px;border:none;border-radius:6px;font-size:14px;font-weight:bold;cursor:pointer;margin:10px;">
        Voucher
    </button>
  </div>
</form>

<!-- VOUCHER MODAL -->
<div id="voucherModal" style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.5);justify-content:center;align-items:center;z-index:10001;overflow:auto;">
  <div style="background:white;width:90%;max-width:1200px;padding:30px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.3);margin:20px auto;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
      <h2 style="margin:0;color:#333;font-size:20px;">Transaction Voucher</h2>
      <button onclick="closeVoucherModal()" style="background:#e74c3c;color:white;border:none;padding:8px 15px;border-radius:4px;cursor:pointer;font-size:14px;font-weight:bold;">Close</button>
    </div>
    <div id="voucherTableContainer" style="overflow-x:auto;"></div>
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
