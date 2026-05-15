package servlet;

import db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.*;
import org.json.JSONObject;

@WebServlet("/LockerSurrenderServlet")
@javax.servlet.annotation.MultipartConfig
public class LockerSurrenderServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // ── 1. Session validation ────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        if (session == null) {
            out.print(errorJson("Session expired. Please login again.")); return;
        }

        String branchCode = (String) session.getAttribute("branchCode");
        String userId     = (String) session.getAttribute("userId");

        // ✅ Working date from session
        java.sql.Date workingDate = (java.sql.Date) session.getAttribute("workingDate");

        if (branchCode == null || branchCode.trim().isEmpty()) {
            out.print(errorJson("Branch code not found in session.")); return;
        }

        // ── 2. Read form parameters ──────────────────────────────────────────
        String lockerType      = trim(request.getParameter("lockerTypeSearch"));
        String lockerNumberStr = trim(request.getParameter("lockerNumberSearch"));
        String transactionMode = trim(request.getParameter("transactionMode"));
        String debitACCode     = trim(request.getParameter("debitACCode"));
        String amountStr       = trim(request.getParameter("amount"));
        String customerId      = trim(request.getParameter("customerId"));

        // ── 3. Basic validation ──────────────────────────────────────────────
        if (lockerType.isEmpty())      { out.print(errorJson("Locker Type is required."));     return; }
        if (lockerNumberStr.isEmpty()) { out.print(errorJson("Locker Number is required."));   return; }
        if (customerId.isEmpty())      { out.print(errorJson("Customer ID is required."));     return; }

        int lockerNumber;
        try {
            lockerNumber = Integer.parseInt(lockerNumberStr.trim());
        } catch (NumberFormatException e) {
            out.print(errorJson("Invalid Locker Number format.")); return;
        }

        BigDecimal amount = BigDecimal.ZERO;
        try {
            if (!amountStr.isEmpty()) amount = new BigDecimal(amountStr);
        } catch (NumberFormatException e) {
            out.print(errorJson("Invalid Amount format.")); return;
        }

        boolean isTransfer = "TRANSFER".equalsIgnoreCase(transactionMode);

        if (isTransfer && debitACCode.isEmpty()) {
            out.print(errorJson("Debit A/C Code is required for Transfer mode.")); return;
        }

        // ✅ Fallback working date
        java.sql.Date surrenderDate = (workingDate != null)
                ? workingDate
                : new java.sql.Date(System.currentTimeMillis());

        // ── 4. DB operations ─────────────────────────────────────────────────
        Connection        conn             = null;
        PreparedStatement psCheck          = null;
        PreparedStatement psDailyScroll    = null;
        PreparedStatement psSurrender      = null;
        PreparedStatement psUpdateBranch   = null;
        ResultSet         rs               = null;

        try {
            conn = DBConnection.getConnection();
            if (conn == null) { out.print(errorJson("Database connection failed.")); return; }

            conn.setAutoCommit(false);

            // ── 4a. Verify locker exists and is active ────────────────────────
            psCheck = conn.prepareStatement(
                "SELECT LA.KEY_NO, BL.CUPBORD_NO " +
                "FROM ACCOUNT.LOCKERACCOUNT LA " +
                "LEFT JOIN BRANCH.BRANCHLOCKER BL " +
                "  ON  TRIM(BL.BRANCH_CODE) = TRIM(LA.BRANCH_CODE) " +
                "  AND TRIM(BL.LOCKER_TYPE) = TRIM(LA.LOCKER_TYPE) " +
                "  AND BL.LOCKER_NUMBER     = LA.LOCKER_NUMBER " +
                "WHERE TRIM(LA.BRANCH_CODE) = TRIM(?) " +
                "AND   TRIM(LA.LOCKER_TYPE) = TRIM(?) " +
                "AND   LA.LOCKER_NUMBER     = ? " +
                "AND   LA.ACCOUNT_STATUS    = 'A' " +
                "AND   ROWNUM = 1"
            );
            psCheck.setString(1, branchCode.trim());
            psCheck.setString(2, lockerType.trim());
            psCheck.setInt   (3, lockerNumber);
            rs = psCheck.executeQuery();

            if (!rs.next()) {
                conn.rollback();
                out.print(errorJson("Locker not found or not active.")); return;
            }

            String keyNo     = rs.getString("KEY_NO")    != null ? rs.getString("KEY_NO")  : "";
            int    cupbordNo = rs.getObject("CUPBORD_NO") != null ? rs.getInt("CUPBORD_NO") : 0;
            rs.close();    rs      = null;
            psCheck.close(); psCheck = null;

            // ── 4b. Transfer mode — validate balance + generate scroll ────────
            long scrollNumber = 0;

            if (isTransfer && amount.compareTo(BigDecimal.ZERO) > 0) {

                // Validate account balance via DB function
                CallableStatement cs = null;
                try {
                    cs = conn.prepareCall("{? = call Fn_Get_Valid_Transaction(?, TO_DATE(?, 'DD/MM/YYYY'), ?, ?)}");
                    cs.registerOutParameter(1, Types.CHAR);
                    cs.setString(2, debitACCode.trim());
                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd/MM/yyyy");
                    cs.setString    (3, sdf.format(surrenderDate));
                    cs.setString    (4, "TRDR");
                    cs.setBigDecimal(5, amount);
                    cs.execute();
                    String validResult = cs.getString(1);
                    if (validResult != null && validResult.length() > 0
                            && validResult.charAt(0) == 'Y') {
                        conn.rollback();
                        String errMsg = validResult.length() > 1
                                ? validResult.substring(1).trim()
                                : "Insufficient balance or invalid account.";
                        out.print(errorJson(errMsg)); return;
                    }
                } catch (Exception ex) {
                    System.err.println("Validation function warning: " + ex.getMessage());
                } finally {
                    try { if (cs != null) cs.close(); } catch (Exception ignored) {}
                }

                // Generate scroll number
                scrollNumber = getNextScrollNumber(conn);

                // Get GL account code
                String glAccountCode = null;
                PreparedStatement psGL = null; ResultSet rsGL = null;
                try {
                    psGL = conn.prepareStatement("SELECT FN_GET_AC_GL(?) AS GL_CODE FROM DUAL");
                    psGL.setString(1, debitACCode.trim());
                    rsGL = psGL.executeQuery();
                    if (rsGL.next()) {
                        String gl = rsGL.getString("GL_CODE");
                        if (gl != null && !gl.trim().equals("00000000000000"))
                            glAccountCode = gl.trim();
                    }
                } finally {
                    try { if (rsGL != null) rsGL.close(); } catch (Exception ignored) {}
                    try { if (psGL != null) psGL.close(); } catch (Exception ignored) {}
                }

                // Get current account balance
                BigDecimal accountBalance = BigDecimal.ZERO;
                PreparedStatement psBal = null; ResultSet rsBal = null;
                try {
                    psBal = conn.prepareStatement(
                        "SELECT LEDGERBALANCE FROM BALANCE.ACCOUNT WHERE ACCOUNT_CODE = ?");
                    psBal.setString(1, debitACCode.trim());
                    rsBal = psBal.executeQuery();
                    if (rsBal.next()) {
                        BigDecimal bal = rsBal.getBigDecimal("LEDGERBALANCE");
                        accountBalance = bal != null ? bal : BigDecimal.ZERO;
                    }
                } finally {
                    try { if (rsBal != null) rsBal.close(); } catch (Exception ignored) {}
                    try { if (psBal != null) psBal.close(); } catch (Exception ignored) {}
                }

                // INSERT into TRANSACTION.DAILYSCROLL
                psDailyScroll = conn.prepareStatement(
                    "INSERT INTO TRANSACTION.DAILYSCROLL (" +
                    "  BRANCH_CODE, SCROLL_DATE, SCROLL_NUMBER, SUBSCROLL_NUMBER, " +
                    "  ACCOUNT_CODE, GLACCOUNT_CODE, FORACCOUNT_CODE, " +
                    "  TRANSACTIONINDICATOR_CODE, AMOUNT, ACCOUNTBALANCE, " +
                    "  GLACCOUNTBALANCE, CHEQUE_TYPE, CHEQUESERIES, " +
                    "  CHEQUENUMBER, CHEQUEDATE, TRANIDENTIFICATION_ID, " +
                    "  PARTICULAR, USER_ID, IS_PASSBOOK_PRINTED, " +
                    "  TRANSACTIONSTATUS, OFFICER_ID, AUTHORISE_DATE, " +
                    "  CASHHANDLING_NUMBER, GLBRANCH_CODE, " +
                    "  CREATED_DATE, MODIFIED_DATE, RECON_CODE" +
                    ") VALUES (" +
                    "  ?,?,?,1," +
                    "  ?,?,?," +
                    "  'TRDR',?,?,0," +
                    "  NULL,NULL,NULL,NULL," +
                    "  0,'LOCKER SURRENDER',?,'N'," +
                    "  'E',NULL,NULL,NULL,?," +
                    "  SYSDATE,SYSDATE,NULL" +
                    ")"
                );
                int k = 1;
                psDailyScroll.setString    (k++, branchCode.trim());
                psDailyScroll.setDate      (k++, surrenderDate);
                psDailyScroll.setLong      (k++, scrollNumber);
                psDailyScroll.setString    (k++, debitACCode.trim());
                if (glAccountCode != null) {
                    psDailyScroll.setString(k++, glAccountCode);
                } else {
                    psDailyScroll.setNull  (k++, Types.VARCHAR);
                }
                psDailyScroll.setString    (k++, debitACCode.trim());
                psDailyScroll.setBigDecimal(k++, amount);
                psDailyScroll.setBigDecimal(k++, accountBalance);
                psDailyScroll.setString    (k++, userId != null ? userId.trim() : null);
                psDailyScroll.setString    (k++, branchCode.trim());

                if (psDailyScroll.executeUpdate() == 0) {
                    conn.rollback();
                    out.print(errorJson("Failed to insert daily scroll transaction.")); return;
                }
                psDailyScroll.close(); psDailyScroll = null;
            }

            // ── 4c. INSERT into HISTORY.LOCKERSURRENDER ───────────────────────
            psSurrender = conn.prepareStatement(
                "INSERT INTO HISTORY.LOCKERSURRENDER (" +
                "  BRANCH_CODE, LOCKER_TYPE, LOCKER_NUMBER, " +
                "  CUPBORD_NO, KEY_NO, LOCKER_STATUS, " +
                "  DATEOFHIRE, DATEOFSURRENDOR, " +
                "  USER_ID, OFFICER_ID, " +
                "  CREATED_DATE, MODIFIED_DATE" +
                ") VALUES (" +
                "  ?,?,?," +
                "  ?,?,'R'," +
                "  (SELECT DATE_OF_HIRE FROM ACCOUNT.LOCKERACCOUNT " +
                "   WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "   AND   TRIM(LOCKER_TYPE) = TRIM(?) " +
                "   AND   LOCKER_NUMBER     = ? AND ROWNUM = 1)," +
                "  ?,?,?," +
                "  SYSDATE, SYSDATE" +
                ")"
            );
            int s = 1;
            psSurrender.setString(s++, branchCode.trim());
            psSurrender.setString(s++, lockerType.trim());
            psSurrender.setInt   (s++, lockerNumber);
            if (cupbordNo > 0) {
                psSurrender.setInt(s++, cupbordNo);
            } else {
                psSurrender.setNull(s++, Types.INTEGER);
            }
            psSurrender.setString(s++, keyNo.isEmpty() ? null : keyNo);
            psSurrender.setString(s++, branchCode.trim());
            psSurrender.setString(s++, lockerType.trim());
            psSurrender.setInt   (s++, lockerNumber);
            psSurrender.setDate  (s++, surrenderDate);
            psSurrender.setString(s++, userId != null ? userId.trim() : null);
            psSurrender.setString(s++, userId != null ? userId.trim() : null);

            if (psSurrender.executeUpdate() == 0) {
                conn.rollback();
                out.print(errorJson("Failed to insert surrender history record.")); return;
            }
            psSurrender.close(); psSurrender = null;

            // ── 4d. UPDATE BRANCH.BRANCHLOCKER → status back to 'A' ──────────
            psUpdateBranch = conn.prepareStatement(
                "UPDATE BRANCH.BRANCHLOCKER " +
                "SET LOCKER_STATUS = 'A', DATEOFHIRE = NULL " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "AND   TRIM(LOCKER_TYPE) = TRIM(?) " +
                "AND   LOCKER_NUMBER     = ?"
            );
            psUpdateBranch.setString(1, branchCode.trim());
            psUpdateBranch.setString(2, lockerType.trim());
            psUpdateBranch.setInt   (3, lockerNumber);

            if (psUpdateBranch.executeUpdate() == 0) {
                conn.rollback();
                out.print(errorJson("Failed to update branch locker status.")); return;
            }
            psUpdateBranch.close(); psUpdateBranch = null;

            // ── 4f. Commit all ────────────────────────────────────────────────
            conn.commit();

            // ── 5. Success response ───────────────────────────────────────────
            JSONObject result = new JSONObject();
            result.put("success",      true);
            result.put("message",      "Locker surrendered successfully!");
            result.put("lockerType",   lockerType.trim());
            result.put("lockerNumber", lockerNumber);
            result.put("customerId",   customerId.trim());
            if (scrollNumber > 0) result.put("scrollNumber", scrollNumber);
            out.print(result.toString());

        } catch (SQLException e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ignored) {}
            e.printStackTrace();
            out.print(errorJson("Database error: " + e.getMessage()));
        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ignored) {}
            e.printStackTrace();
            out.print(errorJson("Unexpected error: " + e.getMessage()));
        } finally {
            try { if (rs             != null) rs.close();             } catch (Exception ignored) {}
            try { if (psCheck        != null) psCheck.close();        } catch (Exception ignored) {}
            try { if (psDailyScroll  != null) psDailyScroll.close();  } catch (Exception ignored) {}
            try { if (psSurrender    != null) psSurrender.close();    } catch (Exception ignored) {}
            try { if (psUpdateBranch != null) psUpdateBranch.close(); } catch (Exception ignored) {}
            try { if (conn           != null) conn.close();           } catch (Exception ignored) {}
        }
    }

    // ── Generate next scroll number from DB sequence ─────────────────────────
    private long getNextScrollNumber(Connection conn) throws SQLException {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = conn.prepareStatement("SELECT NEXT_SCROLL_NO.NEXTVAL FROM DUAL");
            rs = ps.executeQuery();
            if (rs.next()) return rs.getLong(1);
            throw new SQLException("Failed to get next scroll number from sequence.");
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignored) {}
            try { if (ps != null) ps.close(); } catch (Exception ignored) {}
        }
    }

    // ── Utility: null-safe trim ──────────────────────────────────────────────
    private String trim(String val) {
        return (val == null) ? "" : val.trim();
    }

    // ── Utility: build error JSON ────────────────────────────────────────────
    private String errorJson(String message) {
        if (message == null) message = "Unknown error";
        message = message.replace("\\", "\\\\")
                         .replace("\"", "\\\"")
                         .replace("\n", " ")
                         .replace("\r", " ")
                         .replace("\t", " ");
        return "{\"success\":false,\"message\":\"" + message + "\"}";
    }
}
