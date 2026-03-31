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

@WebServlet("/sharesRefund")
public class SharesRefundServlet extends HttpServlet {

    private static final String AC_TYPE_SHARES   = "901";
    private static final String AC_TYPE_TRANSFER = "901"; // Changed: Transfer A/c also searches savings (901)

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("branchCode") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");

        if (action == null || action.isEmpty()) {
            req.getRequestDispatcher("/shares/sharesRefund.jsp").forward(req, resp);
            return;
        }

        resp.reset();
        resp.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = resp.getWriter();

        try {
            switch (action) {
                case "search":
                case "lookup":
                    handleSearch(req, pw, AC_TYPE_SHARES);
                    break;

                case "searchTr":
                    handleSearch(req, pw, AC_TYPE_TRANSFER);
                    break;

                case "get":
                    handleGetAccountDetails(req, pw, AC_TYPE_SHARES);
                    break;

                case "getTr":
                    handleGetAccountDetails(req, pw, AC_TYPE_TRANSFER);
                    break;

                case "getShares":
                    handleGetShares(req, pw);
                    break;

                default:
                    pw.print("{\"error\":\"Unknown action\"}");
            }
        } finally {
            pw.flush();
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

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

    private void handleSearch(HttpServletRequest req, PrintWriter pw, String acType) {

        String term    = nvl(req.getParameter("term")).trim();
        String likeVal = term.isEmpty() ? "%" : "%" + term;
        int    maxRows = term.isEmpty() ? 50 : 30;

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

    private void handleGetShares(HttpServletRequest req, PrintWriter pw) {

        String ac = nvl(req.getParameter("code")).trim();
        if (ac.isEmpty()) { pw.print("{\"error\":\"Code required\"}"); return; }

        String sqlTotals =
            "SELECT NVL(SUM(NUMBEROF_SHARES), 0)               AS TOTAL_SHARES, " +
            "       NVL(SUM(TOTAL_SHARESAMOUNT), 0)            AS TOTAL_AMT, " +
            "       NVL(SUM(NUMBEROF_SHARES * FACE_VALUE), 0)  AS TOTAL_FACE_VAL " +
            "FROM SHARES.CERTIFICATE_MASTER " +
            "WHERE ACCOUNT_NUMBER = ? " +
            "  AND STATUS = 'A'";

        String sqlLatest =
            "SELECT * FROM (" +
            "  SELECT CERTIFICATE_NUMBER, MEMBER_NUMBER, FROM_NUMBER, TO_NUMBER " +
            "  FROM SHARES.CERTIFICATE_MASTER " +
            "  WHERE ACCOUNT_NUMBER = ? " +
            "    AND STATUS = 'A' " +
            "  ORDER BY CERTIFICATE_NUMBER DESC" +
            ") WHERE ROWNUM = 1";

        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();

            long       totalShares  = 0;
            BigDecimal totalAmt     = BigDecimal.ZERO;
            BigDecimal totalFaceVal = BigDecimal.ZERO;

            ps = con.prepareStatement(sqlTotals);
            ps.setString(1, ac);
            rs = ps.executeQuery();
            if (rs.next()) {
                totalShares  = rs.getLong("TOTAL_SHARES");
                totalAmt     = rs.getBigDecimal("TOTAL_AMT");
                totalFaceVal = rs.getBigDecimal("TOTAL_FACE_VAL");
                if (totalAmt     == null) totalAmt     = BigDecimal.ZERO;
                if (totalFaceVal == null) totalFaceVal = BigDecimal.ZERO;
            }
            rs.close(); ps.close();

            if (totalShares == 0) {
                pw.print("{\"ok\":true,\"ts\":0,\"tfv\":\"0.00\",\"ta\":\"0.00\"" +
                         ",\"certNo\":\"\",\"memNo\":\"\",\"formNo\":\"\",\"toNo\":\"\"}");
                return;
            }

            long certNo = 0, memNo = 0, fromNo = 0, toNo = 0;
            ps = con.prepareStatement(sqlLatest);
            ps.setString(1, ac);
            rs = ps.executeQuery();
            if (rs.next()) {
                certNo = rs.getLong("CERTIFICATE_NUMBER");
                memNo  = rs.getLong("MEMBER_NUMBER");
                fromNo = rs.getLong("FROM_NUMBER");
                toNo   = rs.getLong("TO_NUMBER");
            }
            rs.close(); ps.close();

            pw.print("{\"ok\":true" +
                     ",\"ts\":" + totalShares +
                     ",\"tfv\":\"" + totalFaceVal.toPlainString() + "\"" +
                     ",\"ta\":\"" + totalAmt.toPlainString() + "\"" +
                     ",\"certNo\":\"" + certNo  + "\"" +
                     ",\"memNo\":\"" + memNo   + "\"" +
                     ",\"formNo\":\"" + fromNo  + "\"" +
                     ",\"toNo\":\""   + toNo    + "\"" +
                     "}");

        } catch (Exception e) {
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, con);
        }
    }

    private void handleSave(HttpServletRequest req, PrintWriter pw) {

        HttpSession session   = req.getSession(false);
        String branchCode     = sessionAttr(session, "branchCode");
        String userId         = sessionAttr(session, "userId");

        String mainAccCode    = nvl(req.getParameter("accountCode")).trim();
        String meetDateStr    = nvl(req.getParameter("meetDate")).trim();
        String noSharesStr    = nvl(req.getParameter("noShares")).trim();
        String modeOfPay      = nvl(req.getParameter("mode")).trim();
        String trCodesJson    = nvl(req.getParameter("trCodes")).trim();

        String particular     = nvl(req.getParameter("particular")).trim();
        if (particular.isEmpty()) particular = "Share Refund";

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

        boolean isTransfer  = "Transfer".equals(modeOfPay);
        List<String[]> trList = parseTransferEntries(trCodesJson, isTransfer);
        if (trList == null) { pw.print("{\"error\":\"Invalid transfer data\"}"); return; }

        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);

            BigDecimal totalAmt   = new BigDecimal(noShares * 100L);
            java.sql.Date workingDate = getWorkingDate(con, branchCode);

            String receiverTrnIndVal = isTransfer ? "TRCR" : "CSCR";
            CallableStatement cs = null;
            try {
                cs = con.prepareCall("{? = call Fn_Get_Valid_Transaction(?, ?, ?, ?)}");
                cs.registerOutParameter(1, Types.CHAR);
                cs.setString    (2, mainAccCode);
                cs.setDate      (3, workingDate);
                cs.setString    (4, receiverTrnIndVal);
                cs.setBigDecimal(5, totalAmt);
                cs.execute();
                String result = cs.getString(1);
                if (result != null && result.charAt(0) == 'Y') {
                    pw.print("{\"error\":\"" + jsonSafe(result.substring(1).trim()) + "\"}");
                    return;
                }
            } finally {
                try { if (cs != null) cs.close(); } catch (Exception ex) { /* ignore */ }
            }

            if (isTransfer) {
                for (String[] tr : trList) {
                    String payerCode  = tr[0];
                    BigDecimal payerAmt = new BigDecimal(tr[1]);
                    try {
                        cs = con.prepareCall("{? = call Fn_Get_Valid_Transaction(?, ?, ?, ?)}");
                        cs.registerOutParameter(1, Types.CHAR);
                        cs.setString    (2, payerCode);
                        cs.setDate      (3, workingDate);
                        cs.setString    (4, "TRDR");
                        cs.setBigDecimal(5, payerAmt);
                        cs.execute();
                        String result = cs.getString(1);
                        if (result != null && result.charAt(0) == 'Y') {
                            pw.print("{\"error\":\"Account " + payerCode + ": "
                                     + jsonSafe(result.substring(1).trim()) + "\"}");
                            return;
                        }
                    } finally {
                        try { if (cs != null) cs.close(); } catch (Exception ex) { /* ignore */ }
                    }
                }
            }

            long existingCertNo = 0, existingMemNo = 0;
            ps = con.prepareStatement(
                "SELECT * FROM (" +
                "  SELECT CERTIFICATE_NUMBER, MEMBER_NUMBER " +
                "  FROM SHARES.CERTIFICATE_MASTER " +
                "  WHERE ACCOUNT_NUMBER = ? AND STATUS = 'A' " +
                "  ORDER BY CERTIFICATE_NUMBER DESC" +
                ") WHERE ROWNUM = 1");
            ps.setString(1, mainAccCode);
            rs = ps.executeQuery();
            if (rs.next()) {
                existingCertNo = rs.getLong("CERTIFICATE_NUMBER");
                existingMemNo  = rs.getLong("MEMBER_NUMBER");
            }
            rs.close(); ps.close();

            if (existingCertNo == 0) {
                pw.print("{\"error\":\"No active shares found for this account.\"}");
                return;
            }

            ps = con.prepareStatement(
                "UPDATE SHARES.CERTIFICATE_MASTER SET STATUS = 'R' " +
                "WHERE CERTIFICATE_NUMBER = ? AND ACCOUNT_NUMBER = ?");
            ps.setLong  (1, existingCertNo);
            ps.setString(2, mainAccCode);
            ps.executeUpdate(); ps.close();

            long scrollNo  = getNextScrollNumber(con);
            int  subScroll = 1;

            String mainGlCode        = getGlCode(con, mainAccCode);
            BigDecimal mainLedgerBal = getLedgerBalance(con, mainAccCode);

            String forAccCodeReceiver = mainAccCode;
            if (isTransfer && !trList.isEmpty()) {
                String[]   highestPayer = trList.get(0);
                BigDecimal highestAmt   = new BigDecimal(highestPayer[1]);
                for (String[] tr : trList) {
                    BigDecimal amt = new BigDecimal(tr[1]);
                    if (amt.compareTo(highestAmt) > 0) { highestAmt = amt; highestPayer = tr; }
                }
                forAccCodeReceiver = highestPayer[0];
            }

            String     receiverTrnInd = isTransfer ? "TRCR" : "CSCR";
            BigDecimal receiverNewBal = mainLedgerBal.subtract(totalAmt);
            BigDecimal mainGlBal      = getGlBalance(con, branchCode, mainGlCode);
            BigDecimal mainNewGlBal   = mainGlBal.subtract(totalAmt);

            insertDailyScroll(con, ps,
                branchCode, workingDate, scrollNo, subScroll++,
                mainAccCode, mainGlCode, forAccCodeReceiver,
                receiverTrnInd, totalAmt,
                receiverNewBal, mainNewGlBal,
                userId, particular);

            if (isTransfer) {
                for (String[] tr : trList) {
                    String     payerCode     = tr[0];
                    BigDecimal payerAmt      = new BigDecimal(tr[1]);
                    String     payerGlCode   = getGlCode(con, payerCode);
                    BigDecimal payerLedgerBal = getLedgerBalance(con, payerCode);
                    BigDecimal payerNewBal    = payerLedgerBal.add(payerAmt);
                    BigDecimal payerGlBal     = getGlBalance(con, branchCode, payerGlCode);
                    BigDecimal payerNewGlBal  = payerGlBal.add(payerAmt);

                    insertDailyScroll(con, ps,
                        branchCode, workingDate, scrollNo, subScroll++,
                        payerCode, payerGlCode, mainAccCode,
                        "TRDR", payerAmt,
                        payerNewBal, payerNewGlBal,
                        userId, particular);
                }
            }

            con.commit();

            pw.print("{\"ok\":true,\"certNo\":" + existingCertNo +
                     ",\"scrollNo\":" + scrollNo +
                     ",\"msg\":\"Refund saved successfully! Certificate No: " + existingCertNo + "\"}");

        } catch (Exception e) {
            try { if (con != null) con.rollback(); } catch (Exception ex) { /* ignore */ }
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, con);
        }
    }

    // =========================================================================
    // DB HELPERS
    // =========================================================================

    private void insertDailyScroll(
            Connection con, PreparedStatement ps,
            String branchCode, java.sql.Date scrollDate,
            long scrollNo, int subScrollNo,
            String accountCode, String glCode, String forAccountCode,
            String trnInd, BigDecimal amount,
            BigDecimal accountBalance, BigDecimal glBalance,
            String userId, String particular) throws SQLException {

        ps = con.prepareStatement(
            "INSERT INTO TRANSACTION.DAILYSCROLL " +
            "  (BRANCH_CODE, SCROLL_DATE, SCROLL_NUMBER, SUBSCROLL_NUMBER, " +
            "   ACCOUNT_CODE, GLACCOUNT_CODE, FORACCOUNT_CODE, " +
            "   TRANSACTIONINDICATOR_CODE, AMOUNT, ACCOUNTBALANCE, GLACCOUNTBALANCE, " +
            "   PARTICULAR, USER_ID, IS_PASSBOOK_PRINTED, TRANSACTIONSTATUS, " +
            "   TRANIDENTIFICATION_ID, AUTHORISE_DATE, CASHHANDLING_NUMBER, " +
            "   GLBRANCH_CODE, CREATED_DATE, MODIFIED_DATE, RECON_CODE) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', 'E', " +
            "        0, NULL, NULL, NULL, SYSTIMESTAMP, SYSTIMESTAMP, NULL)");

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

    private BigDecimal getLedgerBalance(Connection con, String accountCode) throws SQLException {
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement(
                "SELECT NVL(LEDGERBALANCE, 0) AS BAL FROM BALANCE.ACCOUNT WHERE ACCOUNT_CODE = ?");
            ps.setString(1, accountCode);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getBigDecimal("BAL");
            return BigDecimal.ZERO;
        } finally { closeQuietly(rs, ps, null); }
    }

    private BigDecimal getGlBalance(Connection con, String branchCode, String glCode) throws SQLException {
        if (glCode == null || glCode.isEmpty()) return BigDecimal.ZERO;
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement(
                "SELECT NVL(CURRENTBALANCE, 0) AS BAL FROM BALANCE.BRANCHGL " +
                "WHERE BRANCH_CODE = ? AND GLACCOUNT_CODE = ?");
            ps.setString(1, branchCode);
            ps.setString(2, glCode);
            rs = ps.executeQuery();
            if (rs.next()) return rs.getBigDecimal("BAL");
            return BigDecimal.ZERO;
        } finally { closeQuietly(rs, ps, null); }
    }

    private long getNextScrollNumber(Connection con) throws SQLException {
        PreparedStatement ps = null; ResultSet rs = null;
        try {
            ps = con.prepareStatement("SELECT NEXT_SCROLL_NO.NEXTVAL FROM DUAL");
            rs = ps.executeQuery();
            if (rs.next()) return rs.getLong(1);
            throw new SQLException("Failed to get next scroll number from sequence");
        } finally { closeQuietly(rs, ps, null); }
    }

    private java.sql.Date getWorkingDate(Connection con, String branchCode) throws SQLException {
        CallableStatement cs = null;
        try {
            cs = con.prepareCall("{? = call SYSTEM.FN_GET_WORKINGDATE(?, ?)}");
            cs.registerOutParameter(1, Types.DATE);
            cs.setString(2, "0100");
            cs.setString(3, branchCode);
            cs.execute();
            java.sql.Date wd = cs.getDate(1);
            return (wd != null) ? wd : new java.sql.Date(System.currentTimeMillis());
        } finally {
            try { if (cs != null) cs.close(); } catch (Exception ex) { /* ignore */ }
        }
    }

    private List<String[]> parseTransferEntries(String json, boolean isTransfer) {
        List<String[]> list = new ArrayList<>();
        if (!isTransfer || json == null || json.trim().isEmpty()) return list;
        try {
            json = json.trim();
            json = json.substring(1, json.length() - 1).trim();
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
            return null;
        }
    }

    // =========================================================================
    // UTILITY HELPERS
    // =========================================================================

    private String sessionAttr(HttpSession sess, String key) {
        if (sess == null) return "";
        Object v = sess.getAttribute(key);
        return v == null ? "" : v.toString().trim();
    }

    private String nvl(String s)   { return s == null ? "" : s; }
    private String clean(String s) { return s == null ? "" : s.trim(); }

    private String jsonSafe(String s) {
        if (s == null) return "";
        return s.trim()
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "");
    }

    private String jsonSafeErr(Exception e) {
        String msg = e.getMessage();
        if (msg == null) msg = "DB error";
        return msg.replace("\"", "'").replace("\r", "").replace("\n", " ");
    }

    private void closeQuietly(ResultSet rs, PreparedStatement ps, Connection con) {
        try { if (rs  != null) rs.close();  } catch (Exception ex) { /* ignore */ }
        try { if (ps  != null) ps.close();  } catch (Exception ex) { /* ignore */ }
        try { if (con != null) con.close(); } catch (Exception ex) { /* ignore */ }
    }
}
