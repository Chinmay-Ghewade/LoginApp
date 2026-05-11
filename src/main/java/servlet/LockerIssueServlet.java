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

        if (branchCode == null || branchCode.trim().isEmpty()) {
            out.print(errorJson("Branch code not found in session."));
            return;
        }

        // ── 2. Read form parameters ──────────────────────────────────────────
        String lockerType       = trim(request.getParameter("lockerTypeSearch"));
        String lockerNumberStr  = trim(request.getParameter("lockerNumberSearch"));
        String keyNo            = trim(request.getParameter("keyNo"));
        String customerId       = trim(request.getParameter("customerIdLookup"));

        // ── DEBUG — remove after confirming ─────────────────────────────────
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
        String nomineeFlag      = trim(request.getParameter("nomineeFlag"));   // "yes"/"no"
        String joinOperation    = trim(request.getParameter("joinOperation")); // "yes"/"no"

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
        String nomineeChar      = "yes".equalsIgnoreCase(nomineeFlag)   ? "Y" : "N";
        String joinOperChar     = "yes".equalsIgnoreCase(joinOperation)  ? "Y" : "N";

        // ── 5. Parse rent paid till date ─────────────────────────────────────
        java.sql.Date rentDate = null;
        if (!rentPaidTillDate.isEmpty()) {
            try {
                rentDate = java.sql.Date.valueOf(rentPaidTillDate); // expects yyyy-MM-dd from <input type="date">
            } catch (IllegalArgumentException e) {
                out.print(errorJson("Invalid Rent Paid Till Date format."));
                return;
            }
        }

        // ── 6. DB operations (single transaction) ────────────────────────────
        Connection conn = null;
        PreparedStatement psCheck  = null;
        PreparedStatement psInsert = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            if (conn == null) {
                out.print(errorJson("Database connection failed."));
                return;
            }

            conn.setAutoCommit(false); // start transaction

            // ── 6a. Check locker is still available (race-condition guard) ───
            String sqlCheck =
                "SELECT LOCKER_STATUS FROM BRANCH.BRANCHLOCKER " +
                "WHERE TRIM(BRANCH_CODE)  = TRIM(?) " +
                "AND   LOCKER_NUMBER      = ? " +
                "AND   TRIM(LOCKER_TYPE)  = TRIM(?) " +
                "FOR UPDATE";               // row-level lock until commit

            psCheck = conn.prepareStatement(sqlCheck);
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

            // ── 6b. INSERT into ACCOUNT.LOCKERACCOUNT ───────────────────────
            String sqlInsert =
                "INSERT INTO ACCOUNT.LOCKERACCOUNT (" +
                "  BRANCH_CODE, LOCKER_TYPE, LOCKER_NUMBER, DATE_OF_HIRE, KEY_NO, " +
                "  CUSTOMER_ID, SAVINGACCOUNT_CODE, LESSOR_AGREEMENT, NAME_OF_HIRE, " +
                "  ADDRESS_LINE1, ADDRESS_LINE2, ADDRESS_LINE3, CITY, PIN, " +
                "  TELEPHONE_RES, TELEPHONE_OFFICE, RENT_PAID_TILL_DATE, " +
                "  MODE_OF_OPERATION, CATEGORY, JOIN_OPERATION, NOMINEE, " +
                "  USER_ID, OFFICER_ID, ACCOUNT_STATUS, MOBILE_NO, " +
                "  CREATED_DATE, MODIFIED_DATE" +
                ") VALUES (" +
                "  ?,?,?,SYSDATE,?, " +       // BRANCH_CODE, LOCKER_TYPE, LOCKER_NUMBER, DATE_OF_HIRE, KEY_NO
                "  ?,NULL,?,?, "            + // CUSTOMER_ID, SAVINGACCOUNT_CODE(null), LESSOR_AGREEMENT, NAME_OF_HIRE
                "  ?,?,?,?,?, "             + // ADDRESS_LINE1-3, CITY, PIN
                "  ?,?,?, "                 + // TELEPHONE_RES, TELEPHONE_OFFICE, RENT_PAID_TILL_DATE
                "  ?,?,?,?, "               + // MODE_OF_OPERATION, CATEGORY, JOIN_OPERATION, NOMINEE
                "  ?,?, 'E', ?, "           + // USER_ID, OFFICER_ID(same as userId), ACCOUNT_STATUS, MOBILE_NO
                "  SYSDATE, SYSDATE"        + // CREATED_DATE, MODIFIED_DATE
                ")";

            psInsert = conn.prepareStatement(sqlInsert);
            int i = 1;
            psInsert.setString(i++, branchCode.trim());
            psInsert.setString(i++, lockerType.trim());
            psInsert.setInt   (i++, lockerNumber);
            psInsert.setString(i++, keyNo.isEmpty()      ? null : keyNo);
            psInsert.setString(i++, customerId.trim());
            psInsert.setString(i++, lessorAgre.isEmpty() ? null : lessorAgre);
            psInsert.setString(i++, nameOfHire.isEmpty() ? null : nameOfHire);
            psInsert.setString(i++, address1.isEmpty()   ? null : address1);
            psInsert.setString(i++, address2.isEmpty()   ? null : address2);
            psInsert.setString(i++, address3.isEmpty()   ? null : address3);
            psInsert.setString(i++, city.isEmpty()       ? null : city);
            psInsert.setString(i++, pin.isEmpty()        ? null : pin);
            psInsert.setString(i++, telRes.isEmpty()     ? null : telRes);
            psInsert.setString(i++, telOffice.isEmpty()  ? null : telOffice);

            if (rentDate != null) {
                psInsert.setDate(i++, rentDate);
            } else {
                psInsert.setNull(i++, Types.DATE);
            }

            psInsert.setString(i++, modeOfOperation.isEmpty() ? null : modeOfOperation);
            psInsert.setString(i++, category.isEmpty()        ? "PUBLIC" : category);
            psInsert.setString(i++, joinOperChar);
            psInsert.setString(i++, nomineeChar);
            psInsert.setString(i++, userId != null ? userId.trim() : null);  // USER_ID
            psInsert.setString(i++, userId != null ? userId.trim() : null);  // OFFICER_ID (same as userId)
            psInsert.setString(i++, mobileNo.isEmpty() ? null : mobileNo);

            int inserted = psInsert.executeUpdate();
            if (inserted == 0) {
                conn.rollback();
                out.print(errorJson("Failed to insert locker account record."));
                return;
            }

            // ── 6c. UPDATE BRANCH.BRANCHLOCKER — set status to 'H' ──────────
            String sqlUpdate =
                "UPDATE BRANCH.BRANCHLOCKER " +
                "SET LOCKER_STATUS = 'H', DATEOFHIRE = SYSDATE " +
                "WHERE TRIM(BRANCH_CODE) = TRIM(?) " +
                "AND   LOCKER_NUMBER     = ? " +
                "AND   TRIM(LOCKER_TYPE) = TRIM(?)";

            psUpdate = conn.prepareStatement(sqlUpdate);
            psUpdate.setString(1, branchCode.trim());
            psUpdate.setInt   (2, lockerNumber);
            psUpdate.setString(3, lockerType.trim());

            int updated = psUpdate.executeUpdate();
            if (updated == 0) {
                conn.rollback();
                out.print(errorJson("Failed to update locker status in branch."));
                return;
            }

            // ── 6d. Commit ───────────────────────────────────────────────────
            conn.commit();

            // ── 7. Success response ──────────────────────────────────────────
            JSONObject result = new JSONObject();
            result.put("success",      true);
            result.put("message",      "Locker issued successfully!");
            result.put("lockerType",   lockerType.trim());
            result.put("lockerNumber", lockerNumber);
            result.put("customerId",   customerId.trim());
            result.put("customerName", customerName.trim());
            out.print(result.toString());

        } catch (SQLException e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ignored) {}
            e.printStackTrace();
            out.print(errorJson("Database error: " + e.getMessage().replace("\"", "\\\"")));
        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ignored) {}
            e.printStackTrace();
            out.print(errorJson("Unexpected error: " + e.getMessage().replace("\"", "\\\"")));
        } finally {
            try { if (rs       != null) rs.close();       } catch (Exception ignored) {}
            try { if (psCheck  != null) psCheck.close();  } catch (Exception ignored) {}
            try { if (psInsert != null) psInsert.close(); } catch (Exception ignored) {}
            try { if (psUpdate != null) psUpdate.close(); } catch (Exception ignored) {}
            try { if (conn     != null) conn.close();     } catch (Exception ignored) {}
        }
    }

    // ── Utility: null-safe trim ──────────────────────────────────────────────
    private String trim(String val) {
        return (val == null) ? "" : val.trim();
    }

    // ── Utility: build error JSON ────────────────────────────────────────────
    private String errorJson(String message) {
        return "{\"success\":false,\"message\":\"" + message + "\"}";
    }
}
