package servlet;

import db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

@WebServlet("/dividendCal")
public class DividendCalServlet extends HttpServlet {

    // ── Safe string for JSON ──
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

    private String nvl(String s) { return s == null ? "" : s.trim(); }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException { doPost(req, res); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("branchCode") == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action     = nvl(req.getParameter("action"));
        String branchCode = nvl((String) sess.getAttribute("branchCode"));
        String userId     = nvl((String) sess.getAttribute("userId"));

        res.reset();
        res.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = res.getWriter();

        try {
            switch (action) {
                case "getMemberTypes": getMemberTypes(pw);                              break;
                case "getAccounts":    getAccounts(req, pw);                            break;
                case "calculate":      calculate(req, pw, branchCode, userId);          break;
                case "report":         report(req, pw, branchCode);                     break;
                case "postingPayable": postingPayable(req, pw, branchCode, userId);     break;
                case "postingSB":      postingSB(req, pw, branchCode, userId);          break;
                default:               pw.print("{\"success\":false,\"message\":\"Unknown action\"}");
            }
        } finally {
            pw.flush();
        }
    }

    // ══════════════════════════════════════════
    // ACTION 1 — Get Member Types for Lookup Popup
    // SUBSTR(ACCOUNT_NUMBER, 5, 3) extracts product code (901/902)
    // from account number format e.g. 00029020051055 → 902
    // Only STATUS = 'A' active accounts
    // ══════════════════════════════════════════
    private void getMemberTypes(PrintWriter pw) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuilder sb = new StringBuilder("[");
        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT DISTINCT SUBSTR(ACCOUNT_NUMBER, 5, 3) AS PRODUCT_CODE, " +
                "       MEMBER_TYPE " +
                "FROM SHARES.CERTIFICATE_MASTER " +
                "WHERE MEMBER_TYPE IN ('A','B') " +
                "AND   STATUS = 'A' " +
                "AND   ACCOUNT_NUMBER IS NOT NULL " +
                "ORDER BY MEMBER_TYPE, SUBSTR(ACCOUNT_NUMBER, 5, 3)";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            boolean first = true;
            while (rs.next()) {
                if (!first) sb.append(",");
                sb.append("{")
                  .append("\"productCode\":\"").append(jsonSafe(rs.getString("PRODUCT_CODE"))).append("\",")
                  .append("\"memberType\":\"").append(jsonSafe(rs.getString("MEMBER_TYPE"))).append("\"")
                  .append("}");
                first = false;
            }
            sb.append("]");
            pw.print(sb.toString());
        } catch (Exception e) {
            pw.print("[]");
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 2 — Get count of active accounts
    // Filters by MEMBER_TYPE and SUBSTR(ACCOUNT_NUMBER,5,3) = productCode
    // Only STATUS = 'A'
    // ══════════════════════════════════════════
    private void getAccounts(HttpServletRequest req, PrintWriter pw) {
        String memberType  = nvl(req.getParameter("memberType"));
        String productCode = nvl(req.getParameter("productCode"));
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT COUNT(*) AS total " +
                "FROM SHARES.CERTIFICATE_MASTER " +
                "WHERE MEMBER_TYPE = ? " +
                "AND   SUBSTR(ACCOUNT_NUMBER, 5, 3) = ? " +
                "AND   STATUS = 'A'";
            ps = conn.prepareStatement(sql);
            ps.setString(1, memberType);
            ps.setString(2, productCode);
            rs = ps.executeQuery();
            int count = 0;
            if (rs.next()) count = rs.getInt("total");
            pw.print("{\"success\":true,\"count\":" + count + ",\"memberType\":\"" + jsonSafe(memberType) + "\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 3 — Calculate Dividend
    // Calls sp_dividend_calc stored procedure
    // ══════════════════════════════════════════
    private void calculate(HttpServletRequest req, PrintWriter pw,
                           String branchCode, String userId) {
        String productCode = nvl(req.getParameter("productCode"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        CallableStatement cs = null;
        try {
            conn = DBConnection.getConnection();
            // sp_dividend_calc(branch, working_date, div_bal_date, y_begin, y_end, mem_product)
            cs = conn.prepareCall("{call sp_dividend_calc(?,?,?,?,?,?)}");
            cs.setString(1, branchCode);
            cs.setDate(2, java.sql.Date.valueOf(yearBegin));
            cs.setDate(3, java.sql.Date.valueOf(divBalDate));
            cs.setDate(4, java.sql.Date.valueOf(yearBegin));
            cs.setDate(5, java.sql.Date.valueOf(yearEnd));
            cs.setString(6, productCode);
            cs.execute();
            pw.print("{\"success\":true,\"message\":\"Dividend calculated successfully for product " + jsonSafe(productCode) + "\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(null, cs, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 4 — Report
    // Reads from shares.dividend_calc, filters by memberType correctly
    // ══════════════════════════════════════════
    private void report(HttpServletRequest req, PrintWriter pw, String branchCode) {
        String productCode = nvl(req.getParameter("productCode"));
        String memberType  = nvl(req.getParameter("memberType"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        PreparedStatement ps = null;
        ResultSet rs       = null;
        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT MEMBER_CODE, PAYABLE_AC, CR_ACCOUNT_CODE, " +
                "       BAL_SHARES_FOR_DIV, CURR_BALANCE, DIV_PERCENTAGE, " +
                "       DIV_AMOUNT, DIV_AMOUNT_POST, DIV_WARR_NO, " +
                "       NVL(PAYABLE_TXN_NO,0) AS PAYABLE_TXN_NO, " +
                "       TO_CHAR(PAYABLE_TXN_DATE,'DD-MM-YYYY') AS PAYABLE_TXN_DATE " +
                "FROM shares.dividend_calc " +
                "WHERE BRANCH_CODE = ? " +
                "AND Y_BEGIN_DATE  = TO_DATE(?,'YYYY-MM-DD') " +
                "AND Y_END_DATE    = TO_DATE(?,'YYYY-MM-DD') " +
                "AND DIV_BAL_DATE  = TO_DATE(?,'YYYY-MM-DD') " +
                "AND MEMBER_TYPE   = ? " +
                "ORDER BY MEMBER_CODE";
            ps = conn.prepareStatement(sql);
            ps.setString(1, branchCode);
            ps.setString(2, yearBegin);
            ps.setString(3, yearEnd);
            ps.setString(4, divBalDate);
            ps.setString(5, memberType);
            rs = ps.executeQuery();
            double total = 0;
            int count = 0;
            StringBuilder rows = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) rows.append(",");
                double amt = rs.getDouble("DIV_AMOUNT_POST");
                total += amt;
                count++;
                rows.append("{")
                    .append("\"memberCode\":\"").append(jsonSafe(rs.getString("MEMBER_CODE"))).append("\",")
                    .append("\"payableAc\":\"").append(jsonSafe(rs.getString("PAYABLE_AC"))).append("\",")
                    .append("\"crAccountCode\":\"").append(jsonSafe(rs.getString("CR_ACCOUNT_CODE"))).append("\",")
                    .append("\"balForDiv\":").append(rs.getDouble("BAL_SHARES_FOR_DIV")).append(",")
                    .append("\"currBalance\":").append(rs.getDouble("CURR_BALANCE")).append(",")
                    .append("\"divPercentage\":").append(rs.getDouble("DIV_PERCENTAGE")).append(",")
                    .append("\"divAmount\":").append(rs.getDouble("DIV_AMOUNT")).append(",")
                    .append("\"divAmountPost\":").append(amt).append(",")
                    .append("\"divWarrNo\":").append(rs.getLong("DIV_WARR_NO")).append(",")
                    .append("\"payableTxnNo\":").append(rs.getLong("PAYABLE_TXN_NO")).append(",")
                    .append("\"payableTxnDate\":\"").append(jsonSafe(rs.getString("PAYABLE_TXN_DATE"))).append("\"")
                    .append("}");
                first = false;
            }
            rows.append("]");
            pw.print("{\"success\":true,\"count\":" + count + ",\"total\":" + total + ",\"rows\":" + rows + "}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 5 — Posting Payable
    // Calls sp_dividend_pay stored procedure
    // ══════════════════════════════════════════
    private void postingPayable(HttpServletRequest req, PrintWriter pw,
                                String branchCode, String userId) {
        String productCode = nvl(req.getParameter("productCode"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        CallableStatement cs = null;
        try {
            conn = DBConnection.getConnection();
            // sp_dividend_pay(branch, working_date, div_bal_date, y_begin, y_end, mem_product, user_id)
            cs = conn.prepareCall("{call sp_dividend_pay(?,?,?,?,?,?,?)}");
            cs.setString(1, branchCode);
            cs.setDate(2, new java.sql.Date(new java.util.Date().getTime()));
            cs.setDate(3, java.sql.Date.valueOf(divBalDate));
            cs.setDate(4, java.sql.Date.valueOf(yearBegin));
            cs.setDate(5, java.sql.Date.valueOf(yearEnd));
            cs.setString(6, productCode);
            cs.setString(7, userId);
            cs.execute();
            pw.print("{\"success\":true,\"message\":\"Dividend posted successfully to all accounts!\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(null, cs, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 6 — Posting SB
    // Posts dividend to SB savings accounts
    // ══════════════════════════════════════════
    private void postingSB(HttpServletRequest req, PrintWriter pw,
                           String branchCode, String userId) {
        String productCode = nvl(req.getParameter("productCode"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        CallableStatement cs = null;
        try {
            conn = DBConnection.getConnection();
            cs = conn.prepareCall("{call sp_dividend_pay(?,?,?,?,?,?,?)}");
            cs.setString(1, branchCode);
            cs.setDate(2, new java.sql.Date(new java.util.Date().getTime()));
            cs.setDate(3, java.sql.Date.valueOf(divBalDate));
            cs.setDate(4, java.sql.Date.valueOf(yearBegin));
            cs.setDate(5, java.sql.Date.valueOf(yearEnd));
            cs.setString(6, productCode);
            cs.setString(7, userId);
            cs.execute();
            pw.print("{\"success\":true,\"message\":\"Dividend posted to SB accounts successfully!\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(null, cs, conn);
        }
    }

    // ── Helper: close DB resources ──
    private void closeQuietly(ResultSet rs, Statement st, Connection conn) {
        try { if (rs   != null) rs.close();  } catch (Exception ignored) {}
        try { if (st   != null) st.close();  } catch (Exception ignored) {}
        try { if (conn != null) conn.close(); } catch (Exception ignored) {}
    }
}
