package servlet;

import db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * SharesAllotmentServlet
 * ─────────────────────────────────────────────────────────────────────────────
 * Handles all backend AJAX actions for the Shares Allotment module.
 *
 * Actions (via ?action=...):
 *   search        – Search savings accounts (SUBSTR pos 5-7 = '901') by last digits
 *   lookup        – Alias for search
 *   searchtr      – Search transfer accounts (SUBSTR pos 5-7 = '201') by last digits
 *   get           – Fetch full details of a savings account (901)
 *   gettrdetails  – Fetch full details of a transfer account (201)
 *   gettr         – Fetch name-only of a transfer account (201) – quick validation
 *   save          – Save share allotment (INSERT into SHARES.CERTIFICATE_MASTER)
 *
 * Non-AJAX (no action param):
 *   Forward to sharesAllotment.jsp for page render.
 *
 * Mapped to:  /shares/allotment  (adjust in web.xml or @WebServlet below)
 * ─────────────────────────────────────────────────────────────────────────────
 */
@WebServlet("/shares/allotment")
public class Sharesallotmentservlet extends HttpServlet {

    // ── Account type codes embedded in ACCOUNT_CODE (characters 5-7, 1-based) ──
    private static final String AC_TYPE_SAVINGS  = "901"; // main share-receiver account
    private static final String AC_TYPE_TRANSFER = "201"; // transfer / savings payer account

    // ─────────────────────────────────────────────────────────────────────────
    // GET  →  AJAX read actions  (search, lookup, searchtr, get, gettrdetails, gettr)
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Session guard
        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("branchCode") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");

        if (action == null || action.isEmpty()) {
            // No action → render the JSP page
            req.getRequestDispatcher("/shares/sharesAllotment.jsp").forward(req, resp);
            return;
        }

        // All other actions return JSON
        resp.reset();
        resp.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = resp.getWriter();

        try {
            switch (action) {
                case "search":
                case "lookup":
                    handleSearch(req, pw, AC_TYPE_SAVINGS);
                    break;

                case "searchtr":
                    handleSearch(req, pw, AC_TYPE_TRANSFER);
                    break;

                case "get":
                    handleGetAccountDetails(req, pw, AC_TYPE_SAVINGS);
                    break;

                case "gettrdetails":
                    handleGetAccountDetails(req, pw, AC_TYPE_TRANSFER);
                    break;

                case "gettr":
                    handleGetAccountName(req, pw);
                    break;

default:
                    pw.print("{\"error\":\"Unknown action\"}");
            }
        } finally {
            pw.flush();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST  →  save
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Session guard
        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("branchCode") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        resp.reset();
        resp.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = resp.getWriter();

        try {
            if ("save".equals(action)) {
                handleSave(req, pw);
            } else {
                pw.print("{\"error\":\"Unknown action\"}");
            }
        } finally {
            pw.flush();
        }
    }

    // =========================================================================
    // ACTION HANDLERS
    // =========================================================================

    /**
     * Search accounts by trailing digits.
     * Returns: { "accounts": [ {"code":"...", "name":"..."}, … ] }
     *
     * @param acType  "901" for savings, "201" for transfer accounts
     */
    private void handleSearch(HttpServletRequest req, PrintWriter pw, String acType) {

        String term = nvl(req.getParameter("term")).trim();
        String likeVal = term.isEmpty() ? "%" : "%" + term;
        int maxRows = term.isEmpty() ? 50 : 30;

        String sql =
            "SELECT ACCOUNT_CODE, NAME " +
            "FROM ACCOUNT.ACCOUNT " +
            "WHERE ACCOUNT_CODE LIKE ? " +
            "  AND SUBSTR(ACCOUNT_CODE, 5, 3) = ? " +
            "  AND ROWNUM <= " + maxRows + " " +
            "ORDER BY ACCOUNT_CODE";

        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, likeVal);
            ps.setString(2, acType);
            rs  = ps.executeQuery();

            StringBuilder sb = new StringBuilder("{\"accounts\":[");
            boolean first = true;
            while (rs.next()) {
                String code = clean(rs.getString("ACCOUNT_CODE"));
                String name = jsonSafe(rs.getString("NAME"));
                if (!first) sb.append(",");
                sb.append("{\"code\":\"").append(code)
                  .append("\",\"name\":\"").append(name).append("\"}");
                first = false;
            }
            sb.append("]}");
            pw.print(sb.toString());

        } catch (Exception e) {
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\",\"accounts\":[]}");
        } finally {
            closeQuietly(rs, ps, con);
        }
    }

    /**
     * Fetch full account details (code, name, customer ID, GL code/name, balances).
     * Returns: { "ok":true, "n":"...", "ci":"...", "gc":"...", "gn":"...", "lb":"...", "ab":"..." }
     *
     * @param acType  "901" or "201"
     */
    private void handleGetAccountDetails(HttpServletRequest req, PrintWriter pw, String acType) {

        String ac = nvl(req.getParameter("code")).trim();
        if (ac.isEmpty()) { pw.print("{\"error\":\"Code required\"}"); return; }

        String sql =
            "SELECT A.ACCOUNT_CODE, A.NAME, A.CUSTOMER_ID, " +
            "       B.LEDGERBALANCE, B.AVAILABLEBALANCE, " +
            "       FN_GET_AC_GL(A.ACCOUNT_CODE) AS GL_CODE, " +
            "       Fn_Get_gl_name(FN_GET_AC_GL(A.ACCOUNT_CODE)) AS GL_NAME " +
            "FROM ACCOUNT.ACCOUNT A " +
            "LEFT JOIN BALANCE.ACCOUNT B ON A.ACCOUNT_CODE = B.ACCOUNT_CODE " +
            "WHERE A.ACCOUNT_CODE = ? " +
            "  AND SUBSTR(A.ACCOUNT_CODE, 5, 3) = ?";

        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, ac);
            ps.setString(2, acType);
            rs  = ps.executeQuery();

            if (rs.next()) {
                String name = jsonSafe(rs.getString("NAME"));
                String ci   = clean(rs.getString("CUSTOMER_ID"));
                String gc   = clean(rs.getString("GL_CODE"));
                if ("00000000000000".equals(gc)) gc = "";
                String gn   = jsonSafe(rs.getString("GL_NAME"));
                if (".".equals(gn)) gn = "";

                BigDecimal lbD = rs.getBigDecimal("LEDGERBALANCE");
                BigDecimal abD = rs.getBigDecimal("AVAILABLEBALANCE");
                String lb = (lbD != null) ? lbD.toPlainString() : "0";
                String ab = (abD != null) ? abD.toPlainString() : "0";

                pw.print("{\"ok\":true,\"n\":\"" + name + "\",\"ci\":\"" + ci +
                         "\",\"gc\":\"" + gc + "\",\"gn\":\"" + gn +
                         "\",\"lb\":\"" + lb + "\",\"ab\":\"" + ab + "\"}");
            } else {
                pw.print("{\"error\":\"Account not found\"}");
            }

        } catch (Exception e) {
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, con);
        }
    }

    /**
     * Quick validation: does a transfer account (201) with this code exist?
     * Returns: { "ok":true, "n":"Account Name" }  or  { "error":"..." }
     */
    private void handleGetAccountName(HttpServletRequest req, PrintWriter pw) {

        String ac = nvl(req.getParameter("code")).trim();
        if (ac.isEmpty()) { pw.print("{\"error\":\"Code required\"}"); return; }

        String sql =
            "SELECT ACCOUNT_CODE, NAME " +
            "FROM ACCOUNT.ACCOUNT " +
            "WHERE ACCOUNT_CODE = ? " +
            "  AND SUBSTR(ACCOUNT_CODE, 5, 3) = '201'";

        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(sql);
            ps.setString(1, ac);
            rs  = ps.executeQuery();

            if (rs.next()) {
                String name = jsonSafe(rs.getString("NAME"));
                pw.print("{\"ok\":true,\"n\":\"" + name + "\"}");
            } else {
                pw.print("{\"error\":\"Not a valid savings account\"}");
            }

        } catch (Exception e) {
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, con);
        }
    }

    /**
     * Save share allotment.
     *
     * Does 2 things inside a single DB transaction:
     *   A) INSERT into SHARES.CERTIFICATE_MASTER  (share receiver only)
     *   B) INSERT into TRANSACTION.DAILYSCROLL    (one row per account involved)
     *
     * Daily scroll row logic:
     *   Cash mode:
     *     Row 1 – receiver (901)  : TRANSACTIONINDICATOR_CODE = CSCR, FORACCOUNT_CODE = null
     *
     *   Transfer mode:
     *     Row 1       – receiver (901)       : TRCR, FORACCOUNT_CODE = payer with highest amount
     *     Row 2..N    – each payer (201)     : TRDR, FORACCOUNT_CODE = receiver (901)
     *
     *   SCROLL_NUMBER   = NEXT_SCROLL_NO.NEXTVAL  (same for all rows in this transaction)
     *   SUBSCROLL_NUMBER= 1, 2, 3 … incremented per row
     *   BRANCH_CODE     = from session attribute "branchCode"
     *   USER_ID         = from session attribute "userId"
     *   SCROLL_DATE     = meetDate
     *   TRANSACTIONSTATUS = 'A'  (Active)
     *   IS_PASSBOOK_PRINTED = 'N'
     *   ACCOUNTBALANCE  = current ledger balance + amount (for TRCR/CSCR) or - amount (for TRDR)
     *   GLACCOUNT_CODE  = FN_GET_AC_GL(account_code)
     *   GLACCOUNTBALANCE= current GL balance after transaction
     *   PARTICULAR      = "Share Allotment"
     */
    private void handleSave(HttpServletRequest req, PrintWriter pw) {

        // ── Session attributes ──────────────────────────────────────────────
        HttpSession session = req.getSession(false);
        String branchCode = (session != null && session.getAttribute("branchCode") != null)
                            ? session.getAttribute("branchCode").toString().trim() : "";
        String userId     = (session != null && session.getAttribute("userId") != null)
                            ? session.getAttribute("userId").toString().trim() : "";

        // ── Read & validate params ──────────────────────────────────────────
        String mainAccCode = nvl(req.getParameter("accountCode")).trim();
        String meetDateStr = nvl(req.getParameter("meetDate")).trim();
        String noSharesStr = nvl(req.getParameter("noShares")).trim();
        String modeOfPay   = nvl(req.getParameter("mode")).trim();
        String trCodesJson = nvl(req.getParameter("trCodes")).trim();

        if (mainAccCode.isEmpty()) { pw.print("{\"error\":\"Account code required\"}");  return; }
        if (meetDateStr.isEmpty()) { pw.print("{\"error\":\"Meeting date required\"}");   return; }
        if (noSharesStr.isEmpty()) { pw.print("{\"error\":\"No. of shares required\"}");  return; }

        int noShares;
        try { noShares = Integer.parseInt(noSharesStr); }
        catch (Exception ex) { pw.print("{\"error\":\"Invalid shares count\"}"); return; }
        if (noShares < 1) { pw.print("{\"error\":\"Minimum 1 share required\"}"); return; }

        java.sql.Date issueDate;
        try { issueDate = java.sql.Date.valueOf(meetDateStr); }
        catch (Exception ex) { pw.print("{\"error\":\"Invalid meeting date\"}"); return; }

        boolean isTransfer = "Transfer".equals(modeOfPay);
        List<String[]> trList = parseTransferEntries(trCodesJson, isTransfer);
        if (trList == null) { pw.print("{\"error\":\"Invalid transfer data\"}"); return; }

        // ── DB transaction ─────────────────────────────────────────────────
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);

            // ── A1: MAX certificate number & TO_NUMBER ──────────────────────
            long maxCertNo = 0, maxToNo = 0;
            ps = con.prepareStatement(
                "SELECT NVL(MAX(CERTIFICATE_NUMBER),0) AS MAX_CERT, " +
                "       NVL(MAX(TO_NUMBER),0)          AS MAX_TO " +
                "FROM SHARES.CERTIFICATE_MASTER WHERE MEMBER_TYPE = 'A'");
            rs = ps.executeQuery();
            if (rs.next()) { maxCertNo = rs.getLong("MAX_CERT"); maxToNo = rs.getLong("MAX_TO"); }
            rs.close(); ps.close();

            // ── A2: MAX member number ───────────────────────────────────────
            long maxMemberNo = 0;
            ps = con.prepareStatement(
                "SELECT NVL(MAX(MEMBER_NUMBER),0) AS MAX_MEM " +
                "FROM SHARES.CERTIFICATE_MASTER WHERE MEMBER_TYPE = 'A'");
            rs = ps.executeQuery();
            if (rs.next()) maxMemberNo = rs.getLong("MAX_MEM");
            rs.close(); ps.close();

            long mainMemberNo = maxMemberNo + 1;
            long certNo       = maxCertNo   + 1;
            long fromNo       = maxToNo     + 1;
            long toNo         = fromNo + noShares - 1;
            java.math.BigDecimal totalAmt = new java.math.BigDecimal(noShares * 100L);

            // ── A3: Insert SHARES.CERTIFICATE_MASTER ───────────────────────
            ps = con.prepareStatement(
                "INSERT INTO SHARES.CERTIFICATE_MASTER " +
                "  (MEMBER_TYPE, MEMBER_NUMBER, CERTIFICATE_NUMBER, ISSUE_DATE, FACE_VALUE, " +
                "   NUMBEROF_SHARES, FROM_NUMBER, TO_NUMBER, TOTAL_SHARESAMOUNT, ACCOUNT_NUMBER, PRINT_STATUS) " +
                "VALUES ('A', ?, ?, ?, 100, ?, ?, ?, ?, ?, 'N')");
            ps.setLong  (1, mainMemberNo); ps.setLong(2, certNo);
            ps.setDate  (3, issueDate);    ps.setInt (4, noShares);
            ps.setLong  (5, fromNo);       ps.setLong(6, toNo);
            ps.setBigDecimal(7, totalAmt); ps.setString(8, mainAccCode);
            ps.executeUpdate(); ps.close();

            // ── B: Daily Scroll inserts ────────────────────────────────────

            // B1: Get next scroll number from sequence
            long scrollNo = getNextScrollNumber(con);
            int  subScroll = 1; // increments per row

            // B2: Get GL code for receiver account
            String mainGlCode = getGlCode(con, mainAccCode);

            // B3: Get current ledger balance of receiver
            java.math.BigDecimal mainLedgerBal = getLedgerBalance(con, mainAccCode);

            // B4: Determine FORACCOUNT_CODE for receiver row
            //     Transfer → payer with highest amount
            //     Cash     → null
            String forAccCodeReceiver = null;
            if (isTransfer && !trList.isEmpty()) {
                // find payer with highest amount
                String[]  highestPayer    = trList.get(0);
                java.math.BigDecimal highestAmt = new java.math.BigDecimal(highestPayer[1]);
                for (String[] tr : trList) {
                    java.math.BigDecimal amt = new java.math.BigDecimal(tr[1]);
                    if (amt.compareTo(highestAmt) > 0) { highestAmt = amt; highestPayer = tr; }
                }
                forAccCodeReceiver = highestPayer[0];
            }

            // B5: Insert receiver row (TRCR or CSCR)
            String receiverTrnInd = isTransfer ? "TRCR" : "CSCR";
            java.math.BigDecimal receiverNewBal = mainLedgerBal.add(totalAmt);

            // Get GL balance for receiver GL
            java.math.BigDecimal mainGlBal = getGlBalance(con, branchCode, mainGlCode);
            java.math.BigDecimal mainNewGlBal = mainGlBal.add(totalAmt);

            insertDailyScroll(con, ps,
                branchCode, issueDate, scrollNo, subScroll++,
                mainAccCode, mainGlCode, forAccCodeReceiver,
                receiverTrnInd, totalAmt,
                receiverNewBal, mainNewGlBal,
                userId, "Share Allotment");

            // B6: Insert payer rows (TRDR) — transfer mode only
            if (isTransfer) {
                for (String[] tr : trList) {
                    String payerCode = tr[0];
                    java.math.BigDecimal payerAmt = new java.math.BigDecimal(tr[1]);
                    String payerGlCode = getGlCode(con, payerCode);
                    java.math.BigDecimal payerLedgerBal = getLedgerBalance(con, payerCode);
                    java.math.BigDecimal payerNewBal    = payerLedgerBal.subtract(payerAmt);
                    java.math.BigDecimal payerGlBal     = getGlBalance(con, branchCode, payerGlCode);
                    java.math.BigDecimal payerNewGlBal  = payerGlBal.subtract(payerAmt);

                    insertDailyScroll(con, ps,
                        branchCode, issueDate, scrollNo, subScroll++,
                        payerCode, payerGlCode, mainAccCode, // FORACCOUNT = receiver
                        "TRDR", payerAmt,
                        payerNewBal, payerNewGlBal,
                        userId, "Share Allotment");
                }
            }

            con.commit();
            pw.print("{\"ok\":true,\"certNo\":" + certNo +
                     ",\"msg\":\"Saved successfully! Certificate No: " + certNo + "\"}");

        } catch (Exception e) {
            try { if (con != null) con.rollback(); } catch (Exception ex) { /* ignore */ }
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, con);
        }
    }

    /**
     * Insert one row into TRANSACTION.DAILYSCROLL.
     */
    private void insertDailyScroll(
            Connection con, PreparedStatement ps,
            String branchCode, java.sql.Date scrollDate,
            long scrollNo, int subScrollNo,
            String accountCode, String glCode, String forAccountCode,
            String trnInd, java.math.BigDecimal amount,
            java.math.BigDecimal accountBalance, java.math.BigDecimal glBalance,
            String userId, String particular) throws SQLException {

        // Column mapping:
        // IS_PASSBOOK_PRINTED  = 'N'          (hardcoded)
        // TRANSACTIONSTATUS    = 'E'          (hardcoded — as per requirement)
        // TRANIDENTIFICATION_ID= 0            (hardcoded)
        // AUTHORISE_DATE       = NULL         (as per requirement)
        // CASHHANDLING_NUMBER  = NULL         (as per requirement)
        // GLBRANCH_CODE        = NULL         (as per requirement)
        // CREATED_DATE         = SYSTIMESTAMP (system timestamp)
        // MODIFIED_DATE        = SYSTIMESTAMP (system timestamp — as per requirement)
        // RECON_CODE           = 0            (hardcoded)
        ps = con.prepareStatement(
            "INSERT INTO TRANSACTION.DAILYSCROLL " +
            "  (BRANCH_CODE, SCROLL_DATE, SCROLL_NUMBER, SUBSCROLL_NUMBER, " +
            "   ACCOUNT_CODE, GLACCOUNT_CODE, FORACCOUNT_CODE, " +
            "   TRANSACTIONINDICATOR_CODE, AMOUNT, ACCOUNTBALANCE, GLACCOUNTBALANCE, " +
            "   PARTICULAR, USER_ID, IS_PASSBOOK_PRINTED, TRANSACTIONSTATUS, " +
            "   TRANIDENTIFICATION_ID, AUTHORISE_DATE, CASHHANDLING_NUMBER, " +
            "   GLBRANCH_CODE, CREATED_DATE, MODIFIED_DATE, RECON_CODE) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', 'E', " +
            "        0, NULL, NULL, NULL, SYSTIMESTAMP, SYSTIMESTAMP, NUll)");

        ps.setString    (1,  branchCode);
        ps.setDate      (2,  scrollDate);
        ps.setLong      (3,  scrollNo);
        ps.setInt       (4,  subScrollNo);
        ps.setString    (5,  accountCode);
        ps.setString    (6,  glCode);
        if (forAccountCode != null) ps.setString(7, forAccountCode);
        else                        ps.setNull  (7, java.sql.Types.CHAR);
        ps.setString    (8,  trnInd);
        ps.setBigDecimal(9,  amount);
        ps.setBigDecimal(10, accountBalance);
        ps.setBigDecimal(11, glBalance);
        ps.setString    (12, particular);
        ps.setString    (13, userId);
        ps.executeUpdate();
        ps.close();
    }

    /**
     * Get GL account code for a given account using FN_GET_AC_GL.
     */
    private String getGlCode(Connection con, String accountCode) throws SQLException {
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement("SELECT FN_GET_AC_GL(?) AS GL_CODE FROM DUAL");
            ps.setString(1, accountCode);
            rs = ps.executeQuery();
            if (rs.next()) {
                String gc = rs.getString("GL_CODE");
                if (gc == null || gc.trim().equals("00000000000000")) return "";
                return gc.trim();
            }
            return "";
        } finally { closeQuietly(rs, ps, null); }
    }

    /**
     * Get current ledger balance for a given account.
     */
    private java.math.BigDecimal getLedgerBalance(Connection con, String accountCode) throws SQLException {
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement(
                "SELECT NVL(LEDGERBALANCE, 0) AS BAL FROM BALANCE.ACCOUNT WHERE ACCOUNT_CODE = ?");
            ps.setString(1, accountCode);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getBigDecimal("BAL");
            return java.math.BigDecimal.ZERO;
        } finally { closeQuietly(rs, ps, null); }
    }

    /**
     * Get current GL balance for a branch + GL account code.
     */
    private java.math.BigDecimal getGlBalance(Connection con, String branchCode, String glCode) throws SQLException {
        if (glCode == null || glCode.isEmpty()) return java.math.BigDecimal.ZERO;
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement(
                "SELECT NVL(CURRENTBALANCE, 0) AS BAL FROM BALANCE.BRANCHGL " +
                "WHERE BRANCH_CODE = ? AND GLACCOUNT_CODE = ?");
            ps.setString(1, branchCode);
            ps.setString(2, glCode);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getBigDecimal("BAL");
            return java.math.BigDecimal.ZERO;
        } finally { closeQuietly(rs, ps, null); }
    }

    /**
     * Get next scroll number from sequence NEXT_SCROLL_NO.
     */
    private long getNextScrollNumber(Connection con) throws SQLException {
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement("SELECT NEXT_SCROLL_NO.NEXTVAL FROM DUAL");
            rs = ps.executeQuery();
            if (rs.next()) return rs.getLong(1);
            throw new SQLException("Failed to get next scroll number from sequence");
        } finally { closeQuietly(rs, ps, null); }
    }

    // =========================================================================
    // HELPERS
    // =========================================================================

    /**
     * Parse the JSON transfer-entries array sent from the front-end.
     * Format: [{"code":"XXX","amount":1000},{"code":"YYY","amount":500}]
     *
     * Returns a (possibly empty) list of String[]{code, amountStr},
     * or null if parsing failed.
     */
    private List<String[]> parseTransferEntries(String json, boolean isTransfer) {
        List<String[]> list = new ArrayList<>();
        if (!isTransfer || json == null || json.trim().isEmpty()) return list;
        try {
            json = json.trim();
            json = json.substring(1, json.length() - 1).trim(); // strip [ ]
            if (json.isEmpty()) return list;

            for (String entry : json.split("\\},\\{")) {
                entry = entry.replace("{", "").replace("}", "");
                String code = "", amt = "0";
                for (String part : entry.split(",")) {
                    part = part.trim();
                    if (part.startsWith("\"code\"")) {
                        code = part.split(":", 2)[1].trim().replace("\"", "");
                    } else if (part.startsWith("\"amount\"")) {
                        amt  = part.split(":", 2)[1].trim().replace("\"", "");
                    }
                }
                if (!code.isEmpty()) list.add(new String[]{code, amt});
            }
            return list;
        } catch (Exception ex) {
            return null; // signal parse failure
        }
    }

    /** Returns empty string instead of null. */
    private String nvl(String s) { return s == null ? "" : s; }

    /** Trim and return empty string for null DB values. */
    private String clean(String s) { return s == null ? "" : s.trim(); }

    /**
     * Escape a DB string value for safe embedding in a JSON string literal.
     * Handles backslash, double-quote, CR, LF.
     */
    private String jsonSafe(String s) {
        if (s == null) return "";
        return s.trim()
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "");
    }

    /** Extract and JSON-safe the exception message for error responses. */
    private String jsonSafeErr(Exception e) {
        String msg = e.getMessage();
        if (msg == null) msg = "DB error";
        return msg.replace("\"", "'").replace("\r", "").replace("\n", " ");
    }

    /** Close JDBC resources silently. */
    private void closeQuietly(ResultSet rs, PreparedStatement ps, Connection con) {
        try { if (rs  != null) rs.close();  } catch (Exception ex) { /* ignore */ }
        try { if (ps  != null) ps.close();  } catch (Exception ex) { /* ignore */ }
        try { if (con != null) con.close(); } catch (Exception ex) { /* ignore */ }
    }
}
