package servlet;

import db.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/LockerJointHolderServlet")
public class LockerJointHolderServlet extends HttpServlet {

    // ── Safe parseInt ───────────────────────────────────────────────
    private Integer parseInt(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    // ── Safe trimmed string (null → null) ───────────────────────────
    private String clean(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        return s.trim();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        // ── Session guard ────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("branchCode") == null) {
            response.sendRedirect("../login.jsp");
            return;
        }

        String branchCode = ((String) session.getAttribute("branchCode")).trim();

        // ── workingDate — safe regardless of session storage type ────
        java.sql.Timestamp workingTimestamp;
        Object workingDateObj = session.getAttribute("workingDate");
        if (workingDateObj instanceof java.sql.Timestamp) {
            workingTimestamp = (java.sql.Timestamp) workingDateObj;
        } else if (workingDateObj instanceof java.sql.Date) {
            workingTimestamp = new java.sql.Timestamp(((java.sql.Date) workingDateObj).getTime());
        } else if (workingDateObj instanceof java.util.Date) {
            workingTimestamp = new java.sql.Timestamp(((java.util.Date) workingDateObj).getTime());
        } else if (workingDateObj instanceof String) {
            String wdStr = ((String) workingDateObj).trim();
            java.sql.Timestamp parsed = null;
            if (!wdStr.isEmpty()) {
                try { parsed = new java.sql.Timestamp(java.sql.Date.valueOf(wdStr).getTime()); } catch (Exception e1) {}
                if (parsed == null) {
                    try {
                        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd-MMM-yyyy");
                        parsed = new java.sql.Timestamp(sdf.parse(wdStr).getTime());
                    } catch (Exception e2) {}
                }
            }
            workingTimestamp = (parsed != null) ? parsed : new java.sql.Timestamp(System.currentTimeMillis());
        } else {
            workingTimestamp = new java.sql.Timestamp(System.currentTimeMillis());
        }

        // ── Fieldset 1: Locker info — type and number ────────────────
        String lockerType   = clean(request.getParameter("lockerType"));
        String lockerNumber = clean(request.getParameter("lockerNumber"));

        if (lockerType == null || lockerNumber == null) {
            response.sendRedirect(
                "lockerJointHolder.jsp?status=error&message=" +
                java.net.URLEncoder.encode("Please select a Locker Type and Locker Number.", "UTF-8")
            );
            return;
        }

        // LOCKER_NUMBER is NUMBER(5,0)
        Integer lockerNumberInt = parseInt(lockerNumber);
        if (lockerNumberInt == null) {
            response.sendRedirect(
                "lockerJointHolder.jsp?status=error&message=" +
                java.net.URLEncoder.encode("Invalid Locker Number.", "UTF-8")
            );
            return;
        }

        // ── Fieldset 2: Joint holder arrays ─────────────────────────
        String[] salutations = request.getParameterValues("nomineeSalutation[]");
        String[] names       = request.getParameterValues("nomineeName[]");
        String[] addresses1  = request.getParameterValues("nomineeAddress1[]");
        String[] addresses2  = request.getParameterValues("nomineeAddress2[]");
        String[] addresses3  = request.getParameterValues("nomineeAddress3[]");
        String[] cities      = request.getParameterValues("nomineeCity[]");
        String[] states      = request.getParameterValues("nomineeState[]");
        String[] zips        = request.getParameterValues("nomineeZip[]");
        String[] relations   = request.getParameterValues("nomineeRelation[]");
        String[] customerIds = request.getParameterValues("nomineeCustomerID[]");

        if (names == null || names.length == 0) {
            response.sendRedirect(
                "lockerJointHolder.jsp?status=error&message=" +
                java.net.URLEncoder.encode("At least one joint holder is required.", "UTF-8")
            );
            return;
        }

        int holderCount = names.length;

        Connection        conn    = null;
        PreparedStatement ps      = null;
        PreparedStatement delPs   = null;
        PreparedStatement fetchPs = null;
        ResultSet         fetchRs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // ── OPTION A: Fetch primary customer ID from ACCOUNT.LOCKERACCOUNT ──
            // CUSTOMER_ID is NOT NULL in ACCOUNT.LOCKERJOINTHOLDER, so if the
            // joint holder does not have their own customer ID we fall back to
            // the locker's primary (hired) customer ID.
            String primaryCustomerId = null;
            try {
                fetchPs = conn.prepareStatement(
                    "SELECT CUSTOMER_ID FROM (" +
                    "  SELECT CUSTOMER_ID " +
                    "  FROM ACCOUNT.LOCKERACCOUNT " +
                    "  WHERE TRIM(LOCKER_TYPE)    = TRIM(?) " +
                    "    AND LOCKER_NUMBER        = ? " +
                    "    AND TRIM(ACCOUNT_STATUS) = 'A' " +
                    "  ORDER BY DATE_OF_HIRE DESC" +
                    ") WHERE ROWNUM = 1"
                );
                fetchPs.setString(1, lockerType);
                fetchPs.setInt   (2, lockerNumberInt);
                fetchRs = fetchPs.executeQuery();
                if (fetchRs.next()) {
                    primaryCustomerId = clean(fetchRs.getString("CUSTOMER_ID"));
                }
            } finally {
                try { if (fetchRs != null) fetchRs.close(); } catch (Exception i) {}
                try { if (fetchPs != null) fetchPs.close(); } catch (Exception i) {}
                fetchPs = null;
                fetchRs = null;
            }

            if (primaryCustomerId == null) {
                conn.rollback();
                response.sendRedirect(
                    "lockerJointHolder.jsp?status=error&message=" +
                    java.net.URLEncoder.encode(
                        "No active customer found for Locker " + lockerType + "-" + lockerNumberInt +
                        ". Cannot save joint holder(s).", "UTF-8")
                );
                return;
            }

            // ── Delete existing joint holders for this locker ────────
            delPs = conn.prepareStatement(
                "DELETE FROM ACCOUNT.LOCKERJOINTHOLDER " +
                "WHERE TRIM(LOCKER_TYPE) = TRIM(?) " +
                "  AND LOCKER_NUMBER     = ?"
            );
            delPs.setString(1, lockerType);
            delPs.setInt   (2, lockerNumberInt);
            delPs.executeUpdate();

            // ── INSERT each joint holder ─────────────────────────────
            // Columns (per table schema):
            //   LOCKER_TYPE      CHAR(2)       NOT NULL
            //   LOCKER_NUMBER    NUMBER(5,0)   NOT NULL
            //   CUSTOMER_ID      CHAR(10)      NOT NULL  ← fallback to primary if not provided
            //   SERIAL_NUMBER    NUMBER(2,0)   NOT NULL
            //   SALUTATION_CODE  CHAR(6)       NULL
            //   NAME             CHAR(50)      NULL
            //   ADDRESS1         CHAR(50)      NULL
            //   ADDRESS2         CHAR(50)      NULL
            //   ADDRESS3         CHAR(50)      NULL
            //   RELATION         NUMBER(2,0)   NULL  (default 0)
            //   CITY             CHAR(20)      NULL
            //   STATE            CHAR(20)      NULL
            //   ZIP              NUMBER(6,0)   NULL  (default 0)
            //   DATETIME         TIMESTAMP(6)  NULL
            //   CREATED_DATE     TIMESTAMP(6)  NULL  (default SYSDATE)
            //   MODIFIED_DATE    TIMESTAMP(6)  NULL
            String insertSQL =
                "INSERT INTO ACCOUNT.LOCKERJOINTHOLDER (" +
                "  LOCKER_TYPE, LOCKER_NUMBER, CUSTOMER_ID, SERIAL_NUMBER, " +
                "  SALUTATION_CODE, NAME, " +
                "  ADDRESS1, ADDRESS2, ADDRESS3, " +
                "  RELATION, CITY, STATE, ZIP, " +
                "  DATETIME, CREATED_DATE, MODIFIED_DATE" +
                ") VALUES (" +
                "  ?, ?, ?, ?, " +
                "  ?, ?, " +
                "  ?, ?, ?, " +
                "  ?, ?, ?, ?, " +
                "  ?, ?, ?" +
                ")";

            ps = conn.prepareStatement(insertSQL);

            int savedCount = 0;

            for (int i = 0; i < holderCount; i++) {

                // name — required; skip completely blank rows silently
                String holderName = (names[i] != null) ? names[i].trim() : "";
                if (holderName.isEmpty()) continue;

                int serialNumber = i + 1;

                String salutation = (salutations != null && i < salutations.length)
                    ? clean(salutations[i]) : null;

                String addr1 = (addresses1 != null && i < addresses1.length)
                    ? clean(addresses1[i]) : null;
                String addr2 = (addresses2 != null && i < addresses2.length)
                    ? clean(addresses2[i]) : null;
                String addr3 = (addresses3 != null && i < addresses3.length)
                    ? clean(addresses3[i]) : null;

                String city  = (cities != null && i < cities.length)
                    ? clean(cities[i])  : null;
                String state = (states != null && i < states.length)
                    ? clean(states[i])  : null;

                // ZIP is NUMBER(6,0) — parse to int; accepts 5 or 6 digits
                Integer zip = (zips != null && i < zips.length)
                    ? parseInt(zips[i]) : null;

                // RELATION is NUMBER(2,0)
                Integer relation = (relations != null && i < relations.length)
                    ? parseInt(relations[i]) : null;

                // ── OPTION A: Customer ID resolution ─────────────────
                // customerIds array only contains entries when "Has Customer ID = Yes"
                // (disabled inputs are not submitted).
                // If the joint holder has their own customer ID, use it;
                // otherwise fall back to the locker's primary customer ID.
                String jointCustomerId = null;
                if (customerIds != null && i < customerIds.length) {
                    jointCustomerId = clean(customerIds[i]);
                }
                // Use joint holder's own ID if available, else primary customer ID
                String effectiveCustomerId = (jointCustomerId != null && !jointCustomerId.isEmpty())
                    ? jointCustomerId
                    : primaryCustomerId;

                // Defensive — should never happen since we validated primaryCustomerId above
                if (effectiveCustomerId == null || effectiveCustomerId.isEmpty()) {
                    conn.rollback();
                    response.sendRedirect(
                        "lockerJointHolder.jsp?status=error&message=" +
                        java.net.URLEncoder.encode(
                            "Customer ID could not be resolved for Joint Holder " + serialNumber + ".", "UTF-8")
                    );
                    return;
                }

                int idx = 1;

                ps.setString(idx++, lockerType);         // LOCKER_TYPE   CHAR(2)
                ps.setInt   (idx++, lockerNumberInt);    // LOCKER_NUMBER NUMBER(5,0)
                ps.setString(idx++, effectiveCustomerId);// CUSTOMER_ID   CHAR(10)  NOT NULL
                ps.setInt   (idx++, serialNumber);       // SERIAL_NUMBER NUMBER(2,0)

                // SALUTATION_CODE — nullable CHAR(6)
                if (salutation != null) ps.setString(idx++, salutation);
                else                    ps.setNull  (idx++, Types.CHAR);

                ps.setString(idx++, holderName);         // NAME CHAR(50)

                // ADDRESS1 — nullable CHAR(50)
                if (addr1 != null) ps.setString(idx++, addr1);
                else               ps.setNull  (idx++, Types.CHAR);

                // ADDRESS2 — nullable CHAR(50)
                if (addr2 != null) ps.setString(idx++, addr2);
                else               ps.setNull  (idx++, Types.CHAR);

                // ADDRESS3 — nullable CHAR(50)
                if (addr3 != null) ps.setString(idx++, addr3);
                else               ps.setNull  (idx++, Types.CHAR);

                // RELATION — nullable NUMBER(2,0)
                if (relation != null) ps.setInt (idx++, relation);
                else                  ps.setNull(idx++, Types.NUMERIC);

                // CITY — nullable CHAR(20)
                if (city != null) ps.setString(idx++, city);
                else              ps.setNull  (idx++, Types.CHAR);

                // STATE — nullable CHAR(20)
                if (state != null) ps.setString(idx++, state);
                else               ps.setNull  (idx++, Types.CHAR);

                // ZIP — nullable NUMBER(6,0); accepts 5 or 6 digits
                if (zip != null) ps.setInt (idx++, zip);
                else             ps.setNull(idx++, Types.NUMERIC);

                // DATETIME, CREATED_DATE, MODIFIED_DATE — TIMESTAMP(6)
                ps.setTimestamp(idx++, workingTimestamp);
                ps.setTimestamp(idx++, workingTimestamp);
                ps.setTimestamp(idx++, workingTimestamp);

                ps.addBatch();
                savedCount++;
            }

            if (savedCount == 0) {
                conn.rollback();
                response.sendRedirect(
                    "lockerJointHolder.jsp?status=error&message=" +
                    java.net.URLEncoder.encode("No valid joint holder data found to save.", "UTF-8")
                );
                return;
            }

            try {
                ps.executeBatch();
                conn.commit();
            } catch (java.sql.BatchUpdateException bue) {
                conn.rollback();
                // Walk the exception chain to get the real Oracle error
                SQLException next = bue.getNextException();
                String detail = (next != null) ? next.getMessage() : bue.getMessage();
                System.out.println("LockerJointHolderServlet BATCH ERROR: " + detail);
                bue.printStackTrace();
                if (next != null) next.printStackTrace();
                response.sendRedirect(
                    "lockerJointHolder.jsp?status=error&message=" +
                    java.net.URLEncoder.encode("Failed to save joint holder(s): " + detail, "UTF-8")
                );
                return;
            }

            System.out.println("LockerJointHolderServlet: Saved " + savedCount +
                " joint holder(s) for Locker " + lockerType + "-" + lockerNumberInt +
                " Branch " + branchCode +
                " (primaryCustomerId=" + primaryCustomerId + ")");

            response.sendRedirect(
                "lockerJointHolder.jsp?status=success&message=" +
                java.net.URLEncoder.encode(
                    savedCount + " joint holder(s) saved successfully for Locker " +
                    lockerType + "-" + lockerNumberInt + ".", "UTF-8"
                )
            );

        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignored) {}
            }
            // Print full exception chain for debugging
            Throwable t = e;
            while (t != null) {
                System.out.println("LockerJointHolderServlet CAUSE: " + t.getMessage());
                t = t.getCause();
            }
            e.printStackTrace();
            response.sendRedirect(
                "lockerJointHolder.jsp?status=error&message=" +
                java.net.URLEncoder.encode(
                    "Failed to save joint holder(s): " + e.getMessage(), "UTF-8"
                )
            );

        } finally {
            try { if (delPs != null) delPs.close(); } catch (Exception ignored) {}
            try { if (ps    != null) ps.close();    } catch (Exception ignored) {}
            try { if (conn  != null) conn.close();  } catch (Exception ignored) {}
        }
    }
}