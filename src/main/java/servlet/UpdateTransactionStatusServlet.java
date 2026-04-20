package servlet;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import db.DBConnection;

@WebServlet("/Authorization/UpdateTransactionStatusServlet")
public class UpdateTransactionStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Session validation
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("branchCode") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String branchCode   = (String) session.getAttribute("branchCode");
        String scrollNumber = request.getParameter("scrollNumber");
        String type         = request.getParameter("type");
        String status       = request.getParameter("status");
        String userId       = (String) session.getAttribute("userId");

        if (scrollNumber == null || scrollNumber.trim().isEmpty()) {
            response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Invalid%20Scroll%20Number");
            return;
        }

        if (userId == null || userId.trim().isEmpty()) {
            response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Invalid%20User%20ID");
            return;
        }

        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // All updates are atomic — rollback if any fails

            // Get working date from session — REQUIRED for AUTHORISE_DATE
            Date workingDate;
            Object workingDateObj = session.getAttribute("workingDate");
            if (workingDateObj instanceof Date) {
                workingDate = (Date) workingDateObj;
            } else {
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Working%20Date%20not%20set%20in%20session");
                return;
            }

            // ================================================================
            // STEP 1: Fetch ALL transaction details from DAILYSCROLL
            //         (needed for STEP 1.5 - History Record Creation)
            // ================================================================
            String selectQuery =
                    "SELECT TRANSACTIONINDICATOR_CODE, " +
                    "       AMOUNT, " +
                    "       ACCOUNT_CODE, " +
                    "       FN_GET_AC_GL(ACCOUNT_CODE) AS GLACCOUNT_CODE, " +
                    "       SUBSCROLL_NUMBER, " +
                    "       FORACCOUNT_CODE, " +
                    "       CHEQUE_TYPE, " +
                    "       CHEQUESERIES, " +
                    "       CHEQUENUMBER, " +
                    "       CHEQUEDATE, " +
                    "       PARTICULAR, " +
                    "       IS_PASSBOOK_PRINTED, " +
                    "       SCROLL_DATE " +
                    "FROM TRANSACTION.DAILYSCROLL " +
                    "WHERE SCROLL_NUMBER = ? " +
                    "  AND BRANCH_CODE   = ?";

            ps = conn.prepareStatement(selectQuery);
            ps.setString(1, scrollNumber);
            ps.setString(2, branchCode);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                conn.rollback();
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Transaction%20not%20found");
                return;
            }

            // Fetch all transaction details
            String txnCode           = rs.getString("TRANSACTIONINDICATOR_CODE");
            double amount            = rs.getDouble("AMOUNT");
            String accountCode       = rs.getString("ACCOUNT_CODE");
            String glAccountCode     = rs.getString("GLACCOUNT_CODE");
            long subScrollNumber     = rs.getLong("SUBSCROLL_NUMBER");
            String forAccountCode    = rs.getString("FORACCOUNT_CODE")    != null ? rs.getString("FORACCOUNT_CODE")    : "";
            String chequeType        = rs.getString("CHEQUE_TYPE")        != null ? rs.getString("CHEQUE_TYPE")        : "";
            String chequeSeries      = rs.getString("CHEQUESERIES")       != null ? rs.getString("CHEQUESERIES")       : "";
            long   chequeNumber      = rs.getLong("CHEQUENUMBER");
            Date   chequeDate        = rs.getDate("CHEQUEDATE");
            String particular        = rs.getString("PARTICULAR")         != null ? rs.getString("PARTICULAR")         : "";
            String isPassbookPrinted = rs.getString("IS_PASSBOOK_PRINTED") != null ? rs.getString("IS_PASSBOOK_PRINTED") : "N";
            Date   scrollDate        = rs.getDate("SCROLL_DATE");

            rs.close();
            ps.close();
            ps = null;

            // ================================================================
            // STEP 1.5: INSERT INTO HISTORY.DAILYSCROLL BEFORE STATUS UPDATE
            //           This creates an audit trail of the transaction
            // ================================================================
            try {
                String historyInsertResult = insertDailyScrollHistory(
                        conn,
                        branchCode,
                        scrollDate,
                        Long.parseLong(scrollNumber),
                        subScrollNumber,
                        accountCode,
                        glAccountCode,
                        forAccountCode,
                        txnCode,
                        amount,
                        amount,
                        amount,
                        chequeType,
                        chequeSeries,
                        chequeNumber,
                        chequeDate,
                        particular,
                        userId,
                        isPassbookPrinted,
                        status,
                        userId,
                        0,
                        branchCode,
                        0
                );

                if (!historyInsertResult.isEmpty()) {
                    conn.rollback();
                    response.sendRedirect("authorizationPendingTransactionCash.jsp?error="
                            + java.net.URLEncoder.encode("History Record Error: " + historyInsertResult, "UTF-8"));
                    return;
                }
            } catch (Exception historyException) {
                conn.rollback();
                historyException.printStackTrace();
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error="
                        + java.net.URLEncoder.encode("Failed to create history record: " + historyException.getMessage(), "UTF-8"));
                return;
            }

            // ================================================================
            // STEP 2: Update TRANSACTION.DAILYSCROLL status
            //         (Authorize or Reject)
            // ================================================================
            String updateQuery =
                "UPDATE TRANSACTION.DAILYSCROLL SET " +
                "  TRANSACTIONSTATUS = ?, " +
                "  AUTHORISE_DATE    = ?, " +
                "  OFFICER_ID        = ? " +
                "WHERE SCROLL_NUMBER = ? " +
                "  AND BRANCH_CODE   = ? " +
                "  AND TRANSACTIONINDICATOR_CODE LIKE 'CS%'";

            ps = conn.prepareStatement(updateQuery);
            ps.setString(1, status);
            ps.setDate(2, workingDate);
            ps.setString(3, userId);
            ps.setString(4, scrollNumber);
            ps.setString(5, branchCode);

            int rowsUpdated = ps.executeUpdate();
            ps.close();
            ps = null;

            if (rowsUpdated == 0) {
                conn.rollback();
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error=No%20transaction%20found%20for%20update");
                return;
            }

            // ================================================================
            // Steps 3-6 only run on Authorize ("A"). Reject just updates status.
            // ================================================================
            if ("A".equals(status)) {
            	
            	// ============================================================
                // STEP 2.5: Re-validate transaction server-side before authorize
                // ============================================================
                CallableStatement csValidate = null;
                try {
                    java.text.SimpleDateFormat sdfV = new java.text.SimpleDateFormat("dd/MM/yyyy");
                    String wdStr = sdfV.format(workingDate);

                    csValidate = conn.prepareCall(
                        "{? = call Fn_Get_Valid_Transaction(?, TO_DATE(?, 'DD/MM/YYYY'), ?, ?)}");
                    csValidate.registerOutParameter(1, java.sql.Types.CHAR);
                    csValidate.setString(2, accountCode);
                    csValidate.setString(3, wdStr);
                    csValidate.setString(4, txnCode);
                    csValidate.setDouble(5, amount);
                    csValidate.execute();

                    String validResult = csValidate.getString(1);
                    if (validResult != null && validResult.trim().length() > 0
                            && validResult.charAt(0) == 'Y') {
                        String errMsg = validResult.length() > 1
                                ? validResult.substring(1).trim()
                                : "Transaction validation failed";
                        conn.rollback();
                        response.sendRedirect("viewTransactionDetailsCash.jsp?scrollNumber="
                                + scrollNumber + "&validationError="
                                + java.net.URLEncoder.encode(errMsg, "UTF-8"));
                        return;
                    }
                } finally {
                    try { if (csValidate != null) csValidate.close(); } catch (Exception ignore) {}
                }

                // ============================================================
                // STEP 3: Update BALANCE.ACCOUNT
                //         (Ledger + Available balance)
                // ============================================================
                String balanceUpdateQuery;
                if ("CSDR".equals(txnCode)) {
                    // Debit → subtract from both balances
                    balanceUpdateQuery =
                        "UPDATE BALANCE.ACCOUNT SET " +
                        "  LEDGERBALANCE    = LEDGERBALANCE    - ?, " +
                        "  AVAILABLEBALANCE = AVAILABLEBALANCE - ? " +
                        "WHERE ACCOUNT_CODE = ?";
                } else {
                    // Credit (CSCR) → add to both balances
                    balanceUpdateQuery =
                        "UPDATE BALANCE.ACCOUNT SET " +
                        "  LEDGERBALANCE    = LEDGERBALANCE    + ?, " +
                        "  AVAILABLEBALANCE = AVAILABLEBALANCE + ? " +
                        "WHERE ACCOUNT_CODE = ?";
                }

                ps = conn.prepareStatement(balanceUpdateQuery);
                ps.setDouble(1, amount);
                ps.setDouble(2, amount);
                ps.setString(3, accountCode);
                ps.executeUpdate();
                ps.close();
                ps = null;

                // ============================================================
                // STEP 4: Update BALANCE.BRANCHGL
                //         (Branch GL current balance)
                // ============================================================
                updateBranchGLAccountBalance(conn, branchCode, txnCode,
                                             workingDate.toString(), glAccountCode, amount);

                // ============================================================
                // STEP 5: Update BALANCE.BRANCHGLHISTORY
                //         (CS cash codes only)
                // ============================================================
                updateBranchGLAccountBalanceHistory(conn, branchCode, txnCode,
                                                    workingDate.toString(), glAccountCode, amount);

                // ============================================================
                // STEP 6: INSERT INTO TRANSACTION.DAILYTXN
                //         Generate next TXN number, then insert the authorized
                //         cash transaction record. Throws on failure → rollback.
                // ============================================================
                insertDailyTxnRecord(
                        conn,
                        branchCode,
                        workingDate,
                        Long.parseLong(scrollNumber),
                        subScrollNumber,
                        accountCode,
                        glAccountCode,
                        forAccountCode,
                        txnCode,
                        amount,
                        amount,   // ACCOUNTBALANCE  — same as amount (post-auth snapshot)
                        amount,   // GLACCOUNTBALANCE — same as amount (post-auth snapshot)
                        chequeType,
                        chequeSeries,
                        chequeNumber,
                        chequeDate,
                        particular,
                        Long.parseLong(scrollNumber),
                        userId,
                        isPassbookPrinted,
                        "A",      // TRANSACTIONSTATUS — Authorized
                        userId,   // OFFICER_ID
                        0L,       // CASHHANDLING_NUMBER
                        branchCode
                );
            }

            conn.commit();

            String successMsg = "A".equals(status) ? "Authorized" : "Rejected";
            response.sendRedirect("authorizationPendingTransactionCash.jsp?success=Transaction%20"
                    + successMsg + "%20successfully");

        } catch (SQLException e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ex) { ex.printStackTrace(); }
            e.printStackTrace();
            try {
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error="
                        + java.net.URLEncoder.encode("Database Error: " + e.getMessage(), "UTF-8"));
            } catch (Exception ex) { ex.printStackTrace(); }
        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ex) { ex.printStackTrace(); }
            e.printStackTrace();
            try {
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error="
                        + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
            } catch (Exception ex) { ex.printStackTrace(); }
        } finally {
            try { if (ps   != null) ps.close();  } catch (Exception ex) { ex.printStackTrace(); }
            try { if (conn != null) conn.close(); } catch (Exception ex) { ex.printStackTrace(); }
        }
    }

    // =========================================================================
    // INSERT HISTORY.DAILYSCROLL RECORD
    // Creates an audit trail before any status change.
    // On error: throws exception which triggers rollback in caller.
    // =========================================================================
    private String insertDailyScrollHistory(
            Connection connection,
            String branchCode,
            Date   scrollDate,
            long   scrollNumber,
            long   subScrollNumber,
            String accountCode,
            String glAccountCode,
            String forAccountCode,
            String txnIndicatorCode,
            double amount,
            double accountBalance,
            double glAccountBalance,
            String chequeType,
            String chequeSeries,
            long   chequeNumber,
            Date   chequeDate,
            String particular,
            String userId,
            String isPassbookPrinted,
            String txnStatus,
            String officerId,
            long   cashHandlingNumber,
            String glBranchCode,
            int    reconCode)
            throws SQLException {

        String returnValue = "";
        PreparedStatement ps = null;

        try {
            String columnList =
                "BRANCH_CODE, " +
                "SCROLL_DATE, " +
                "SCROLL_NUMBER, " +
                "SUBSCROLL_NUMBER, " +
                "ACCOUNT_CODE, " +
                "GLACCOUNT_CODE, " +
                "FORACCOUNT_CODE, " +
                "TRANSACTIONINDICATOR_CODE, " +
                "AMOUNT, " +
                "ACCOUNTBALANCE, " +
                "GLACCOUNTBALANCE, " +
                "CHEQUE_TYPE, " +
                "CHEQUESERIES, " +
                "CHEQUENUMBER, " +
                "CHEQUEDATE, " +
                "PARTICULAR, " +
                "USER_ID, " +
                "IS_PASSBOOK_PRINTED, " +
                "TRANSACTIONSTATUS, " +
                "OFFICER_ID, " +
                "CASHHANDLING_NUMBER, " +
                "GLBRANCH_CODE ";

            String sqlInsert =
                    "INSERT INTO HISTORY.DAILYSCROLL (" + columnList + ") " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            ps = connection.prepareStatement(sqlInsert);

            int i = 1;
            ps.setString(i++, branchCode);
            ps.setDate(i++, scrollDate);
            ps.setLong(i++, scrollNumber);
            ps.setLong(i++, subScrollNumber);
            ps.setString(i++, accountCode);
            ps.setString(i++, glAccountCode);
            ps.setString(i++, forAccountCode);
            ps.setString(i++, txnIndicatorCode);
            ps.setDouble(i++, amount);
            ps.setDouble(i++, accountBalance);
            ps.setDouble(i++, glAccountBalance);
            ps.setString(i++, chequeType);
            ps.setString(i++, chequeSeries);
            ps.setLong(i++, chequeNumber);

            if (chequeDate != null) {
                ps.setDate(i++, chequeDate);
            } else {
                ps.setNull(i++, Types.DATE);
            }

            ps.setString(i++, particular);
            ps.setString(i++, userId);
            ps.setString(i++, isPassbookPrinted);
            ps.setString(i++, txnStatus);
            ps.setString(i++, officerId);
            ps.setLong(i++, cashHandlingNumber);
            ps.setString(i++, glBranchCode);

            ps.executeUpdate();

        } catch (SQLException sqlException) {
            returnValue = "Error in insertDailyScrollHistory: " + sqlException.getMessage();
            sqlException.printStackTrace();
            throw sqlException; // caller handles rollback
        } finally {
            try { if (ps != null) ps.close(); } catch (SQLException ignore) {}
        }

        return returnValue;
    }

    // =========================================================================
    // STEP 6: INSERT INTO TRANSACTION.DAILYTXN
    //
    // Mirrors the cash transaction pattern from Transaction.java
    // (createCashDailyTxnRecord).  TXN_NUMBER is generated by atomically
    // incrementing LASTTXN_NUMBER in HEADOFFICE.BRANCHPARAMETER within the
    // same connection/transaction so it rolls back together with everything
    // else if anything fails.
    //
    // Columns inserted (matches sqlCashDailyTxnColumns from Transaction.java):
    //   BRANCH_CODE, TXN_DATE, TXN_NUMBER, SUBTXN_NUMBER,
    //   ACCOUNT_CODE, GLACCOUNT_CODE, FORACCOUNT_CODE, TRANSACTIONINDICATOR_CODE,
    //   AMOUNT, ACCOUNTBALANCE, GLACCOUNTBALANCE,
    //   CHEQUE_TYPE, CHEQUESERIES, CHEQUENUMBER, CHEQUEDATE,
    //   TRANIDENTIFICATION_ID, PARTICULAR, SCROLL_NUMBER,
    //   USER_ID, IS_PASSBOOK_PRINTED, TRANSACTIONSTATUS, OFFICER_ID,
    //   CASHHANDLING_NUMBER, GLBRANCH_CODE
    // =========================================================================
    private void insertDailyTxnRecord(
            Connection connection,
            String branchCode,
            Date   txnDate,
            long   scrollNumberLong,
            long   subScrollNumber,
            String accountCode,
            String glAccountCode,
            String forAccountCode,
            String txnCode,
            double amount,
            double accountBalance,
            double glAccountBalance,
            String chequeType,
            String chequeSeries,
            long   chequeNumber,
            Date   chequeDate,
            String particular,
            long   scrollNumberRef,
            String userId,
            String isPassbookPrinted,
            String txnStatus,
            String officerId,
            long   cashHandlingNumber,
            String glBranchCode)
            throws SQLException {

        PreparedStatement ps = null;

        try {
            // ------------------------------------------------------------------
            // 6a. Generate next TXN_NUMBER within this same transaction.
            //     We increment LASTTXN_NUMBER in HEADOFFICE.BRANCHPARAMETER
            //      getNextTXNNumber when IS_TXN_SCROLL_BANK_WIDE = 'N'). if IS_TXN_SCROLL_BANK_WIDE = 'N' then it generate max TXN_NUMBER of TRANSACTION.DAILYTXN 
            //     If your bank uses bank-wide numbering, switch the UPDATE to
            //     GLOBALCONFIG.UNIVERSALPARAMETER .
            // ------------------------------------------------------------------
            long txnNumber = getNextTxnNumber(connection, branchCode);

            // ------------------------------------------------------------------
            // 6b. Insert the DAILYTXN row.
            // ------------------------------------------------------------------
            String sql =
                "INSERT INTO TRANSACTION.DAILYTXN (" +
                "  BRANCH_CODE, TXN_DATE, TXN_NUMBER, SUBTXN_NUMBER, " +
                "  ACCOUNT_CODE, GLACCOUNT_CODE, FORACCOUNT_CODE, " +
                "  TRANSACTIONINDICATOR_CODE, " +
                "  AMOUNT, ACCOUNTBALANCE, GLACCOUNTBALANCE, " +
                "  CHEQUE_TYPE, CHEQUESERIES, CHEQUENUMBER, CHEQUEDATE, " +
                "  TRANIDENTIFICATION_ID, PARTICULAR, SCROLL_NUMBER, " +
                "  USER_ID, IS_PASSBOOK_PRINTED, TRANSACTIONSTATUS, OFFICER_ID, " +
                "  CASHHANDLING_NUMBER, GLBRANCH_CODE " +
                ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            ps = connection.prepareStatement(sql);

            int i = 1;
            ps.setString(i++, branchCode);
            ps.setDate(i++, txnDate);
            ps.setLong(i++, txnNumber);
            ps.setLong(i++, subScrollNumber);
            ps.setString(i++, accountCode);
            ps.setString(i++, glAccountCode);
            ps.setString(i++, forAccountCode);
            ps.setString(i++, txnCode);
            ps.setDouble(i++, amount);
            ps.setDouble(i++, accountBalance);
            ps.setDouble(i++, glAccountBalance);
            ps.setString(i++, chequeType);
            ps.setString(i++, chequeSeries);
            ps.setLong(i++, chequeNumber);

            if (chequeDate != null) {
                ps.setDate(i++, chequeDate);
            } else {
                ps.setNull(i++, Types.DATE);
            }

            ps.setInt(i++, 0);              // TRANIDENTIFICATION_ID — 0 for cash
            ps.setString(i++, particular);
            ps.setLong(i++, scrollNumberRef);
            ps.setString(i++, userId);
            ps.setString(i++, isPassbookPrinted);
            ps.setString(i++, txnStatus);
            ps.setString(i++, officerId);
            ps.setLong(i++, cashHandlingNumber);
            ps.setString(i++, glBranchCode);

            ps.executeUpdate();

        } catch (SQLException sqlException) {
            sqlException.printStackTrace();
            // Re-throw so the caller's catch block rolls back the entire transaction
            throw sqlException;
        } finally {
            try { if (ps != null) ps.close(); } catch (SQLException ignore) {}
        }
    }

    // =========================================================================
    // Generate next TXN_NUMBER (branch-wise) within the current transaction.
    //
    // Reads LASTTXN_NUMBER from HEADOFFICE.BRANCHPARAMETER, increments it,
    // writes it back, and returns the new value — all on the same Connection
    // so it participates in the outer transaction and rolls back on failure.
    //
    // Note: If your bank runs bank-wide TXN numbering (IS_TXN_SCROLL_BANK_WIDE
    // = 'Y'), replace this with an UPDATE on GLOBALCONFIG.UNIVERSALPARAMETER
    // exactly as done in Transaction.java getNextTXNNumber().
    // =========================================================================
    private long getNextTxnNumber(Connection connection, String branchCode)
            throws SQLException {

        PreparedStatement selectPs = null;
        PreparedStatement updatePs = null;
        ResultSet rs = null;

        try {
            selectPs = connection.prepareStatement(
                "SELECT LASTTXN_NUMBER FROM HEADOFFICE.BRANCHPARAMETER WHERE BRANCH_CODE = ?");
            selectPs.setString(1, branchCode);
            rs = selectPs.executeQuery();

            if (!rs.next()) {
                throw new SQLException(
                    "No BRANCHPARAMETER record found for BRANCH_CODE = '" + branchCode + "'");
            }

            long newTxnNumber = rs.getLong("LASTTXN_NUMBER") + 1;

            updatePs = connection.prepareStatement(
                "UPDATE HEADOFFICE.BRANCHPARAMETER SET LASTTXN_NUMBER = ? WHERE BRANCH_CODE = ?");
            updatePs.setLong(1, newTxnNumber);
            updatePs.setString(2, branchCode);
            updatePs.executeUpdate();

            return newTxnNumber;

        } finally {
            try { if (rs       != null) rs.close();       } catch (SQLException ignore) {}
            try { if (selectPs != null) selectPs.close(); } catch (SQLException ignore) {}
            try { if (updatePs != null) updatePs.close(); } catch (SQLException ignore) {}
        }
    }

    // =========================================================================
    // STEP 4 helper: Update BALANCE.BRANCHGL current balance
    // "CSDR" → subtract;  "CSCR" → add
    // =========================================================================
    private double updateBranchGLAccountBalance(
            Connection connection,
            String branchCode,
            String transactionIndicatorCode,
            String txnDate,
            String glAccountCode,
            double amount)
            throws SQLException {

        PreparedStatement selectPs = null;
        PreparedStatement updatePs = null;
        ResultSet rs = null;
        double currentBalance = 0.0;

        String drCr = transactionIndicatorCode.substring(2).toUpperCase(); // "DR" or "CR"

        try {
            String sqlWhere =
                " WHERE BRANCH_CODE  = '" + branchCode    + "'" +
                " AND GLACCOUNT_CODE = '" + glAccountCode + "'";

            selectPs = connection.prepareStatement(
                "SELECT CURRENTBALANCE FROM BALANCE.BRANCHGL" + sqlWhere);
            rs = selectPs.executeQuery();

            if (rs.next()) {
                currentBalance = rs.getDouble("CURRENTBALANCE");
                currentBalance = currentBalance + ("DR".equals(drCr) ? -amount : amount);

                updatePs = connection.prepareStatement(
                    "UPDATE BALANCE.BRANCHGL SET CURRENTBALANCE = ?" + sqlWhere);
                updatePs.setDouble(1, currentBalance);
                updatePs.executeUpdate();

            } else {
                throw new SQLException(
                    "No record found in BALANCE.BRANCHGL for " +
                    "GLACCOUNT_CODE = '" + glAccountCode + "', " +
                    "BRANCH_CODE = '"    + branchCode    + "'");
            }

        } finally {
            if (rs       != null) try { rs.close();       } catch (SQLException ignore) {}
            if (selectPs != null) try { selectPs.close(); } catch (SQLException ignore) {}
            if (updatePs != null) try { updatePs.close(); } catch (SQLException ignore) {}
        }

        return currentBalance;
    }

    // =========================================================================
    // STEP 5 helper: Update BALANCE.BRANCHGLHISTORY
    // CSDR → increments DEBITCASH;  CSCR → increments CREDITCASH
    // =========================================================================
    private void updateBranchGLAccountBalanceHistory(
            Connection connection,
            String branchCode,
            String transactionIndicatorCode,
            String txnDate,
            String glAccountCode,
            double amount)
            throws SQLException {

        PreparedStatement selectPs = null;
        PreparedStatement updatePs = null;
        ResultSet rs = null;

        try {
            java.sql.Date txnSqlDate = java.sql.Date.valueOf(txnDate);

            String sqlWhere =
                " WHERE BRANCH_CODE  = '" + branchCode    + "'" +
                " AND GLACCOUNT_CODE = '" + glAccountCode + "'" +
                " AND TXN_DATE = ?";

            selectPs = connection.prepareStatement(
                "SELECT DEBITCASH, CREDITCASH FROM BALANCE.BRANCHGLHISTORY" + sqlWhere);
            selectPs.setDate(1, txnSqlDate);
            rs = selectPs.executeQuery();

            if (rs.next()) {
                String updateSql;
                if ("CSDR".equals(transactionIndicatorCode)) {
                    updateSql = "UPDATE BALANCE.BRANCHGLHISTORY SET DEBITCASH  = DEBITCASH  + ?" + sqlWhere;
                } else if ("CSCR".equals(transactionIndicatorCode)) {
                    updateSql = "UPDATE BALANCE.BRANCHGLHISTORY SET CREDITCASH = CREDITCASH + ?" + sqlWhere;
                } else {
                    throw new SQLException(
                        "Unhandled CS indicator code for history update: " + transactionIndicatorCode);
                }

                updatePs = connection.prepareStatement(updateSql);
                updatePs.setDouble(1, amount);
                updatePs.setDate(2, txnSqlDate);
                updatePs.executeUpdate();

            } else {
                throw new SQLException(
                    "No record found in BALANCE.BRANCHGLHISTORY for " +
                    "GLACCOUNT_CODE = '" + glAccountCode + "', " +
                    "BRANCH_CODE = '"    + branchCode    + "', " +
                    "TXN_DATE = '"       + txnDate       + "'");
            }

        } finally {
            if (rs       != null) try { rs.close();       } catch (SQLException ignore) {}
            if (selectPs != null) try { selectPs.close(); } catch (SQLException ignore) {}
            if (updatePs != null) try { updatePs.close(); } catch (SQLException ignore) {}
        }
    }
}