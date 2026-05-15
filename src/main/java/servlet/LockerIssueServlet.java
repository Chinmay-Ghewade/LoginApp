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

@WebServlet("/LockerIssueServlet")
@javax.servlet.annotation.MultipartConfig
public class LockerIssueServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // ── 1. Session validation ────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        if (session == null) {
            out.print(errorJson("Session expired. Please login again."));
            return;
        }

        String branchCode = (String) session.getAttribute("branchCode");
        String userId     = (String) session.getAttribute("userId");

        // ✅ Working date from session
        java.sql.Date workingDate = (java.sql.Date) session.getAttribute("workingDate");

        if (branchCode == null || branchCode.trim().isEmpty()) {
            out.print(errorJson("Branch code not found in session."));
            return;
        }

        // ── 2. Read form parameters ──────────────────────────────────────────
        String lockerType       = trim(request.getParameter("lockerTypeSearch"));
        String lockerNumberStr  = trim(request.getParameter("lockerNumberSearch"));
        String keyNo            = trim(request.getParameter("keyNo"));
        String customerId       = trim(request.getParameter("customerIdLookup"));

        System.out.println("DEBUG SERVLET >>> lockerType='" + lockerType
                + "' | lockerNumber='" + lockerNumberStr
                + "' | customerId='" + customerId + "'");

        String customerName     = trim(request.getParameter("customerNameDisplay"));
        String nameOfHire       = trim(request.getParameter("nameOfHire"));
        String category         = trim(request.getParameter("category"));
        String mobileNo         = trim(request.getParameter("dispMobile"));
        String address1         = trim(request.getParameter("dispAddress1"));
        String address2         = trim(request.getParameter("dispAddress2"));
        String address3         = trim(request.getParameter("dispAddress3"));
        String telRes           = trim(request.getParameter("dispTelRes"));
        String telOffice        = trim(request.getParameter("dispTelOffice"));
        String city             = trim(request.getParameter("dispCity"));
        String pin              = trim(request.getParameter("dispPin"));
        String rentPaidTillDate = trim(request.getParameter("rentPaidTillDate"));
        String modeOfOperation  = trim(request.getParameter("modeOfOperation"));
        String lessorAgre       = trim(request.getParameter("lessorAgre"));
        String nomineeFlag      = trim(request.getParameter("nomineeFlag"));
        String joinOperation    = trim(request.getParameter("joinOperation"));

        // ── 3. Basic validation ──────────────────────────────────────────────
        if (lockerType.isEmpty()) {
            out.print(errorJson("Locker Type is required."));
            return;
        }
        if (lockerNumberStr.isEmpty()) {
            out.print(errorJson("Locker Number is required."));
            return;
        }

        int lockerNumber;
        try {
            lockerNumber = Integer.parseInt(lockerNumberStr.trim());
        } catch (NumberFormatException e) {
            out.print(errorJson("Invalid Locker Number format."));
            return;
        }

        if (customerId.isEmpty()) {
            out.print(errorJson("Customer ID is required."));
            return;
        }

        // ── 4. Convert nominee / joinOperation to single char ────────────────
        String nomineeChar  = "yes".equalsIgnoreCase(nomineeFlag)  ? "Y" : "N";
        String joinOperChar = "yes".equalsIgnoreCase(joinOperation) ? "Y" : "N";

        // ── 5. Parse rent paid till date ─────────────────────────────────────
        java.sql.Date rentDate = null;
        if (!rentPaidTillDate.isEmpty()) {
            try {
                rentDate = java.sql.Date.valueOf(rentPaidTillDate);
            } catch (IllegalArgumentException e) {
                out.print(errorJson("Invalid Rent Paid Till Date format."));
                return;
            }
        }

        // ✅ Fallback: if workingDate not in session, use today
        java.sql.Date dateOfHire = (workingDate != null)
                ? workingDate
                : new java.sql.Date(System.currentTimeMillis());

        // ── 6. DB operations (single transaction) ────────────────────────────
        Connection        conn      = null;
        PreparedStatement psCheck   = null;
        PreparedStatement psRent    = null;
        PreparedStatement psExist   = null;
        PreparedStatement psInsert  = null;
        PreparedStatement psUpdate  = null;
        PreparedStatement psTxn     = null;
        ResultSet         rs        = null;

        try {
            conn = DBConnection.getConnection();
            if (conn == null) {
                out.print(errorJson("Database connection failed."));
                return;
            }

            conn.setAutoCommit(false);

            // ── 6a. Check locker is still available ──────────────────────────
            psCheck = conn.prepareStatement(
                "SELECT LOCKER_STATUS FROM BRANCH.BRANCHLOCKER " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "AND   LOCKER_NUMBER     = ? " +
                "AND   TRIM(LOCKER_TYPE) = TRIM(?) " +
                "FOR UPDATE"
            );
            psCheck.setString(1, branchCode.trim());
            psCheck.setInt   (2, lockerNumber);
            psCheck.setString(3, lockerType.trim());
            rs = psCheck.executeQuery();

            if (!rs.next()) {
                conn.rollback();
                out.print(errorJson("Locker not found for this branch and type."));
                return;
            }

            String currentStatus = rs.getString("LOCKER_STATUS");
            if (!"A".equalsIgnoreCase(currentStatus != null ? currentStatus.trim() : "")) {
                conn.rollback();
                out.print(errorJson("Locker is no longer available (Status: "
                        + (currentStatus != null ? currentStatus.trim() : "Unknown") + ")."));
                return;
            }
            rs.close();    rs      = null;
            psCheck.close(); psCheck = null;

            // ── 6b. Fetch RENT and PERIOD from BRANCHLOCKER_RENTS ────────────
            BigDecimal rent   = BigDecimal.ZERO;
            int        period = 0;

            psRent = conn.prepareStatement(
                "SELECT RENT, PERIOD_IN_MONTHS " +
                "FROM BRANCH.BRANCHLOCKER_RENTS " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "AND   TRIM(LOCKER_TYPE) = TRIM(?) " +
                "AND ROWNUM = 1"
            );
            psRent.setString(1, branchCode.trim());
            psRent.setString(2, lockerType.trim());
            rs = psRent.executeQuery();
            if (rs.next()) {
                rent   = rs.getBigDecimal("RENT") != null ? rs.getBigDecimal("RENT") : BigDecimal.ZERO;
                period = rs.getInt("PERIOD_IN_MONTHS");
            }
            rs.close();    rs     = null;
            psRent.close(); psRent = null;

            // ── 6c. Generate scroll number from sequence ──────────────────────
            long scrollNumber = getNextScrollNumber(conn);

            // ── 6d. Calculate RENT_TODATE = dateOfHire + period months ────────
            java.sql.Date rentFromDate = dateOfHire;
            java.sql.Date rentToDate   = null;
            if (period > 0) {
                java.util.Calendar cal = java.util.Calendar.getInstance();
                cal.setTime(dateOfHire);
                cal.add(java.util.Calendar.MONTH, period);
                rentToDate = new java.sql.Date(cal.getTimeInMillis());
            }

            // ── 6e. Check if LOCKERACCOUNT record already exists (from previous tenant) ──
            psExist = conn.prepareStatement(
                "SELECT COUNT(1) FROM ACCOUNT.LOCKERACCOUNT " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "AND   LOCKER_NUMBER     = ? " +
                "AND   TRIM(LOCKER_TYPE) = TRIM(?)"
            );
            psExist.setString(1, branchCode.trim());
            psExist.setInt   (2, lockerNumber);
            psExist.setString(3, lockerType.trim());
            rs = psExist.executeQuery();
            boolean recordExists = rs.next() && rs.getInt(1) > 0;
            rs.close();    rs      = null;
            psExist.close(); psExist = null;

            if (recordExists) {
                // ── 6e-i. UPDATE existing record for the new tenant ──────────
                psInsert = conn.prepareStatement(
                    "UPDATE ACCOUNT.LOCKERACCOUNT SET " +
                    "  CUSTOMER_ID          = ?, " +
                    "  DATE_OF_HIRE         = ?, " +
                    "  KEY_NO               = ?, " +
                    "  LESSOR_AGREEMENT     = ?, " +
                    "  NAME_OF_HIRE         = ?, " +
                    "  ADDRESS_LINE1        = ?, " +
                    "  ADDRESS_LINE2        = ?, " +
                    "  ADDRESS_LINE3        = ?, " +
                    "  CITY                 = ?, " +
                    "  PIN                  = ?, " +
                    "  TELEPHONE_RES        = ?, " +
                    "  TELEPHONE_OFFICE     = ?, " +
                    "  MOBILE_NO            = ?, " +
                    "  RENT_PAID_TILL_DATE  = ?, " +
                    "  MODE_OF_OPERATION    = ?, " +
                    "  CATEGORY             = ?, " +
                    "  JOIN_OPERATION       = ?, " +
                    "  NOMINEE              = ?, " +
                    "  USER_ID              = ?, " +
                    "  OFFICER_ID           = ?, " +
                    "  ACCOUNT_STATUS       = 'E', " +
                    "  SAVINGACCOUNT_CODE   = NULL, " +
                    "  MODIFIED_DATE        = SYSDATE " +
                    "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                    "AND   LOCKER_NUMBER     = ? " +
                    "AND   TRIM(LOCKER_TYPE) = TRIM(?)"
                );
                int i = 1;
                psInsert.setString(i++, customerId.trim());
                psInsert.setDate  (i++, dateOfHire);
                psInsert.setString(i++, keyNo.isEmpty()        ? null : keyNo);
                psInsert.setString(i++, lessorAgre.isEmpty()   ? null : lessorAgre);
                psInsert.setString(i++, nameOfHire.isEmpty()   ? null : nameOfHire);
                psInsert.setString(i++, address1.isEmpty()     ? null : address1);
                psInsert.setString(i++, address2.isEmpty()     ? null : address2);
                psInsert.setString(i++, address3.isEmpty()     ? null : address3);
                psInsert.setString(i++, city.isEmpty()         ? null : city);
                psInsert.setString(i++, pin.isEmpty()          ? null : pin);
                psInsert.setString(i++, telRes.isEmpty()       ? null : telRes);
                psInsert.setString(i++, telOffice.isEmpty()    ? null : telOffice);
                psInsert.setString(i++, mobileNo.isEmpty()     ? null : mobileNo);
                if (rentDate != null) {
                    psInsert.setDate(i++, rentDate);
                } else {
                    psInsert.setNull(i++, Types.DATE);
                }
                psInsert.setString(i++, modeOfOperation.isEmpty() ? null : modeOfOperation);
                psInsert.setString(i++, category.isEmpty()         ? "PUBLIC" : category);
                psInsert.setString(i++, joinOperChar);
                psInsert.setString(i++, nomineeChar);
                psInsert.setString(i++, userId != null ? userId.trim() : null);
                psInsert.setString(i++, userId != null ? userId.trim() : null);
                // WHERE clause params
                psInsert.setString(i++, branchCode.trim());
                psInsert.setInt   (i++, lockerNumber);
                psInsert.setString(i++, lockerType.trim());

            } else {
                // ── 6e-ii. INSERT fresh record ───────────────────────────────
                psInsert = conn.prepareStatement(
                    "INSERT INTO ACCOUNT.LOCKERACCOUNT (" +
                    "  BRANCH_CODE, LOCKER_TYPE, LOCKER_NUMBER, DATE_OF_HIRE, KEY_NO, " +
                    "  CUSTOMER_ID, SAVINGACCOUNT_CODE, LESSOR_AGREEMENT, NAME_OF_HIRE, " +
                    "  ADDRESS_LINE1, ADDRESS_LINE2, ADDRESS_LINE3, CITY, PIN, " +
                    "  TELEPHONE_RES, TELEPHONE_OFFICE, RENT_PAID_TILL_DATE, " +
                    "  MODE_OF_OPERATION, CATEGORY, JOIN_OPERATION, NOMINEE, " +
                    "  USER_ID, OFFICER_ID, ACCOUNT_STATUS, MOBILE_NO, " +
                    "  CREATED_DATE, MODIFIED_DATE" +
                    ") VALUES (" +
                    "  ?,?,?,?,?, " +
                    "  ?,NULL,?,?, " +
                    "  ?,?,?,?,?, " +
                    "  ?,?,?, " +
                    "  ?,?,?,?, " +
                    "  ?,?,'E',?, " +
                    "  SYSDATE, SYSDATE" +
                    ")"
                );
                int i = 1;
                psInsert.setString(i++, branchCode.trim());
                psInsert.setString(i++, lockerType.trim());
                psInsert.setInt   (i++, lockerNumber);
                psInsert.setDate  (i++, dateOfHire);
                psInsert.setString(i++, keyNo.isEmpty()        ? null : keyNo);
                psInsert.setString(i++, customerId.trim());
                psInsert.setString(i++, lessorAgre.isEmpty()   ? null : lessorAgre);
                psInsert.setString(i++, nameOfHire.isEmpty()   ? null : nameOfHire);
                psInsert.setString(i++, address1.isEmpty()     ? null : address1);
                psInsert.setString(i++, address2.isEmpty()     ? null : address2);
                psInsert.setString(i++, address3.isEmpty()     ? null : address3);
                psInsert.setString(i++, city.isEmpty()         ? null : city);
                psInsert.setString(i++, pin.isEmpty()          ? null : pin);
                psInsert.setString(i++, telRes.isEmpty()       ? null : telRes);
                psInsert.setString(i++, telOffice.isEmpty()    ? null : telOffice);
                if (rentDate != null) {
                    psInsert.setDate(i++, rentDate);
                } else {
                    psInsert.setNull(i++, Types.DATE);
                }
                psInsert.setString(i++, modeOfOperation.isEmpty() ? null : modeOfOperation);
                psInsert.setString(i++, category.isEmpty()         ? "PUBLIC" : category);
                psInsert.setString(i++, joinOperChar);
                psInsert.setString(i++, nomineeChar);
                psInsert.setString(i++, userId != null ? userId.trim() : null);
                psInsert.setString(i++, userId != null ? userId.trim() : null);
                psInsert.setString(i++, mobileNo.isEmpty()     ? null : mobileNo);
            }

            if (psInsert.executeUpdate() == 0) {
                conn.rollback();
                out.print(errorJson("Failed to save locker account record."));
                return;
            }
            psInsert.close(); psInsert = null;

            // ── 6f. UPDATE BRANCH.BRANCHLOCKER status to 'H' ─────────────────
            psUpdate = conn.prepareStatement(
                "UPDATE BRANCH.BRANCHLOCKER " +
                "SET LOCKER_STATUS = 'H', DATEOFHIRE = ? " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "AND   LOCKER_NUMBER     = ? " +
                "AND   TRIM(LOCKER_TYPE) = TRIM(?)"
            );
            psUpdate.setDate  (1, dateOfHire);
            psUpdate.setString(2, branchCode.trim());
            psUpdate.setInt   (3, lockerNumber);
            psUpdate.setString(4, lockerType.trim());

            if (psUpdate.executeUpdate() == 0) {
                conn.rollback();
                out.print(errorJson("Failed to update locker status in branch."));
                return;
            }
            psUpdate.close(); psUpdate = null;

            // ── 6g. INSERT into TRANSACTION.LOCKERTRANSACTION ─────────────────
            psTxn = conn.prepareStatement(
                "INSERT INTO TRANSACTION.LOCKERTRANSACTION (" +
                "  BRANCH_CODE, LOCKER_TYPE, LOCKER_NUMBER, " +
                "  ISSUE_DATE, TXN_DATE, " +
                "  RENT_FROMDATE, RENT_TODATE, " +
                "  TXN_NUMBER, SCROLL_NUMBER, " +
                "  RENT, PERIOD, AMOUNT, " +
                "  GLACCOUNT_HEAD, TRANSACTION_STATUS, " +
                "  USER_ID, OFFICER_ID, TRN_TYPE, " +
                "  SERVICE_TAX, CREATED_DATE, MODIFIED_DATE" +
                ") VALUES (" +
                "  ?,?,?, " +
                "  ?,?, " +
                "  ?,?, " +
                "  0,?, " +
                "  ?,?,?, " +
                "  NULL,'E', " +
                "  ?,?,'T', " +
                "  0, SYSDATE, SYSDATE" +
                ")"
            );
            int j = 1;
            psTxn.setString    (j++, branchCode.trim());
            psTxn.setString    (j++, lockerType.trim());
            psTxn.setInt       (j++, lockerNumber);
            psTxn.setDate      (j++, dateOfHire);
            psTxn.setDate      (j++, dateOfHire);
            psTxn.setDate      (j++, rentFromDate);
            if (rentToDate != null) {
                psTxn.setDate  (j++, rentToDate);
            } else {
                psTxn.setNull  (j++, Types.DATE);
            }
            psTxn.setLong      (j++, scrollNumber);
            psTxn.setBigDecimal(j++, rent);
            psTxn.setInt       (j++, period);
            psTxn.setBigDecimal(j++, rent);
            psTxn.setString    (j++, userId != null ? userId.trim() : null);
            psTxn.setString    (j++, userId != null ? userId.trim() : null);

            if (psTxn.executeUpdate() == 0) {
                conn.rollback();
                out.print(errorJson("Failed to insert locker transaction record."));
                return;
            }
            psTxn.close(); psTxn = null;

            // ── 6h. Commit all ────────────────────────────────────────────────
            conn.commit();

            // ── 7. Success response ───────────────────────────────────────────
            JSONObject result = new JSONObject();
            result.put("success",      true);
            result.put("message",      "Locker issued successfully!");
            result.put("scrollNumber", scrollNumber);
            result.put("lockerType",   lockerType.trim());
            result.put("lockerNumber", lockerNumber);
            result.put("customerId",   customerId.trim());
            result.put("customerName", customerName.trim());
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
            try { if (rs       != null) rs.close();       } catch (Exception ignored) {}
            try { if (psCheck  != null) psCheck.close();  } catch (Exception ignored) {}
            try { if (psRent   != null) psRent.close();   } catch (Exception ignored) {}
            try { if (psExist  != null) psExist.close();  } catch (Exception ignored) {}
            try { if (psInsert != null) psInsert.close(); } catch (Exception ignored) {}
            try { if (psUpdate != null) psUpdate.close(); } catch (Exception ignored) {}
            try { if (psTxn    != null) psTxn.close();    } catch (Exception ignored) {}
            try { if (conn     != null) conn.close();     } catch (Exception ignored) {}
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