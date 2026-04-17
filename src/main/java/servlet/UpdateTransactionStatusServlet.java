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
            conn.setAutoCommit(false); // All 4 updates are atomic — rollback if any fails

            // Get working date from session, if available
            Date workingDate;
            Object workingDateObj = session.getAttribute("workingDate");
            if (workingDateObj instanceof Date) {
                workingDate = (Date) workingDateObj;
            } else {
                workingDate = new java.sql.Date(System.currentTimeMillis());
            }

            // ----------------------------------------------------------------
            // STEP 1: Update DAILYSCROLL status (Authorize or Reject)
            // ----------------------------------------------------------------
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
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error=No%20transaction%20found");
                return;
            }

            // ----------------------------------------------------------------
            // Steps 2-4 only run on Authorize ("A"). Reject just updates status.
            // ----------------------------------------------------------------
            if ("A".equals(status)) {

                // Fetch all details needed for the 3 balance updates in one query
                String selectQuery =
                    "SELECT TRANSACTIONINDICATOR_CODE, " +
                    "       AMOUNT, " +
                    "       ACCOUNT_CODE, " +
                    "       FN_GET_AC_GL(ACCOUNT_CODE) AS GLACCOUNT_CODE " +
                    "FROM TRANSACTION.DAILYSCROLL " +
                    "WHERE SCROLL_NUMBER = ? " +
                    "  AND BRANCH_CODE   = ?";

                ps = conn.prepareStatement(selectQuery);
                ps.setString(1, scrollNumber);
                ps.setString(2, branchCode);
                ResultSet rs = ps.executeQuery();

                if (!rs.next()) {
                    conn.rollback();
                    response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Transaction%20detail%20not%20found%20for%20balance%20update");
                    return;
                }

                String txnCode       = rs.getString("TRANSACTIONINDICATOR_CODE");
                double amount        = rs.getDouble("AMOUNT");
                String accountCode   = rs.getString("ACCOUNT_CODE");
                String glAccountCode = rs.getString("GLACCOUNT_CODE");

                rs.close();
                ps.close();
                ps = null;

                // ------------------------------------------------------------
                // STEP 2: Update BALANCE.ACCOUNT (Ledger + Available balance)
                // ------------------------------------------------------------
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

                // ------------------------------------------------------------
                // STEP 3: Update BALANCE.BRANCHGL (Branch GL current balance)
                // ------------------------------------------------------------
                updateBranchGLAccountBalance(conn, branchCode, txnCode,
                                             workingDate.toString(), glAccountCode, amount);

                // ------------------------------------------------------------
                // STEP 4: Update BALANCE.BRANCHGLHISTORY (CS cash codes only)
                // ------------------------------------------------------------
                updateBranchGLAccountBalanceHistory(conn, branchCode, txnCode,
                                                    workingDate.toString(), glAccountCode, amount);
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

    // -------------------------------------------------------------------------
    // STEP 3 helper: Update BALANCE.BRANCHGL current balance
    // "CSDR" → DR → subtract from balance
    // "CSCR" → CR → add to balance
    // -------------------------------------------------------------------------
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

        // "CSDR" → "DR",  "CSCR" → "CR"
        String drCr = transactionIndicatorCode.substring(2).toUpperCase();

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

    // -------------------------------------------------------------------------
    // STEP 4 helper: Update BALANCE.BRANCHGLHISTORY
    // CSDR → increments DEBITCASH column
    // CSCR → increments CREDITCASH column
    // -------------------------------------------------------------------------
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
            java.sql.Date txnSqlDate = java.sql.Date.valueOf(txnDate); // expects yyyy-MM-dd

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