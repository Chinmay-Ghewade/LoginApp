package servlet;

import db.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/LockerNomineeServlet")
public class LockerNomineeServlet extends HttpServlet {

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

        // workingDate may be stored in session as java.sql.Date, java.util.Date,
        // or String — handle all cases safely without casting
        java.sql.Date workingDate;
        Object workingDateObj = session.getAttribute("workingDate");
        if (workingDateObj instanceof java.sql.Date) {
            workingDate = (java.sql.Date) workingDateObj;
        } else if (workingDateObj instanceof java.util.Date) {
            workingDate = new java.sql.Date(((java.util.Date) workingDateObj).getTime());
        } else if (workingDateObj instanceof String) {
            String workingDateStr = ((String) workingDateObj).trim();
            if (!workingDateStr.isEmpty()) {
                java.sql.Date parsed = null;
                try { parsed = java.sql.Date.valueOf(workingDateStr); } catch (Exception e1) {}
                if (parsed == null) {
                    try {
                        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd-MMM-yyyy");
                        parsed = new java.sql.Date(sdf.parse(workingDateStr).getTime());
                    } catch (Exception e2) {}
                }
                workingDate = (parsed != null) ? parsed : new java.sql.Date(System.currentTimeMillis());
            } else {
                workingDate = new java.sql.Date(System.currentTimeMillis());
            }
        } else {
            // null or unknown type — fall back to today
            workingDate = new java.sql.Date(System.currentTimeMillis());
        }

        // ── Locker info from fieldset 1 ──────────────────────────────
        String lockerType   = clean(request.getParameter("lockerType"));
        String lockerNumber = clean(request.getParameter("lockerNumber"));

        // Basic validation — locker must be selected
        if (lockerType == null || lockerNumber == null) {
            response.sendRedirect(
                "lockerNominee.jsp?status=error&message=" +
                java.net.URLEncoder.encode("Please select a Locker Type and Locker Number.", "UTF-8")
            );
            return;
        }

        // ── Nominee arrays from fieldset 2 ───────────────────────────
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
        // NOTE: genders[] is collected by the form but ACCOUNT.LOCKERNOMINEE has no
        //       GENDER column, so we intentionally do NOT read or insert it.

        // At least one nominee must be present
        if (names == null || names.length == 0) {
            response.sendRedirect(
                "lockerNominee.jsp?status=error&message=" +
                java.net.URLEncoder.encode("At least one nominee is required.", "UTF-8")
            );
            return;
        }

        int nomineeCount = names.length;

        Connection        conn  = null;
        PreparedStatement ps    = null;
        PreparedStatement delPs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // transaction — all nominees save or none

            // ── Delete existing nominees for this locker before re-inserting ──
            delPs = conn.prepareStatement(
                "DELETE FROM ACCOUNT.LOCKERNOMINEE " +
                "WHERE TRIM(LOCKER_TYPE)   = TRIM(?) " +
                "  AND TRIM(LOCKER_NUMBER) = TRIM(?)"
            );
            delPs.setString(1, lockerType);
            delPs.setString(2, lockerNumber);
            delPs.executeUpdate();

            // ── INSERT each nominee ──────────────────────────────────
            // GENDER column intentionally omitted — column does not exist in table.
            // The form still collects gender for UI purposes but it is not persisted.
            String insertSQL =
                "INSERT INTO ACCOUNT.LOCKERNOMINEE (" +
                "  LOCKER_TYPE, LOCKER_NUMBER, CUSTOMER_ID, SERIAL_NUMBER, " +
                "  SALUTATION_CODE, NAME, " +
                "  ADDRESS1, ADDRESS2, ADDRESS3, " +
                "  CITY, STATE, ZIP, " +
                "  RELATION, DATETIME, CREATED_DATE, MODIFIED_DATE" +
                ") VALUES (" +
                "  ?, ?, ?, ?, " +
                "  ?, ?, " +
                "  ?, ?, ?, " +
                "  ?, ?, ?, " +
                "  ?, ?, ?, ?" +
                ")";

            ps = conn.prepareStatement(insertSQL);

            int savedCount = 0;

            for (int i = 0; i < nomineeCount; i++) {

                // nominee name — required; skip blank rows
                String nomineeName = (names[i] != null) ? names[i].trim() : "";
                if (nomineeName.isEmpty()) continue;

                // serial number — always sequential 1, 2, 3...
                int serialNumber = i + 1;

                // salutation code
                String salutation = (salutations != null && i < salutations.length)
                    ? clean(salutations[i]) : null;

                // addresses
                String addr1 = (addresses1 != null && i < addresses1.length)
                    ? clean(addresses1[i]) : null;
                String addr2 = (addresses2 != null && i < addresses2.length)
                    ? clean(addresses2[i]) : null;
                String addr3 = (addresses3 != null && i < addresses3.length)
                    ? clean(addresses3[i]) : null;

                // city / state
                String city  = (cities != null && i < cities.length)
                    ? clean(cities[i])  : null;
                String state = (states != null && i < states.length)
                    ? clean(states[i])  : null;

                // zip
                Integer zip = (zips != null && i < zips.length)
                    ? parseInt(zips[i]) : null;

                // relation
                Integer relation = (relations != null && i < relations.length)
                    ? parseInt(relations[i]) : null;

                // customerIds[] array is correctly aligned because disabled
                // inputs are not submitted — index i is safe to use directly.
                String customerId = null;
                if (customerIds != null && i < customerIds.length) {
                    customerId = clean(customerIds[i]);
                }

                int idx = 1;

                ps.setString(idx++, lockerType);    // LOCKER_TYPE
                ps.setString(idx++, lockerNumber);  // LOCKER_NUMBER

                // CUSTOMER_ID — nullable
                if (customerId != null) ps.setString(idx++, customerId);
                else                    ps.setNull  (idx++, Types.CHAR);

                ps.setInt(idx++, serialNumber);     // SERIAL_NUMBER

                // SALUTATION_CODE — nullable
                if (salutation != null) ps.setString(idx++, salutation);
                else                    ps.setNull  (idx++, Types.CHAR);

                ps.setString(idx++, nomineeName);   // NAME

                // ── GENDER intentionally skipped — no column in table ──

                // ADDRESS1 — nullable
                if (addr1 != null) ps.setString(idx++, addr1);
                else               ps.setNull  (idx++, Types.CHAR);

                // ADDRESS2 — nullable
                if (addr2 != null) ps.setString(idx++, addr2);
                else               ps.setNull  (idx++, Types.CHAR);

                // ADDRESS3 — nullable
                if (addr3 != null) ps.setString(idx++, addr3);
                else               ps.setNull  (idx++, Types.CHAR);

                // CITY — nullable
                if (city != null) ps.setString(idx++, city);
                else              ps.setNull  (idx++, Types.CHAR);

                // STATE — nullable
                if (state != null) ps.setString(idx++, state);
                else               ps.setNull  (idx++, Types.CHAR);

                // ZIP — nullable
                if (zip != null) ps.setInt (idx++, zip);
                else             ps.setNull(idx++, Types.NUMERIC);

                // RELATION — nullable
                if (relation != null) ps.setInt (idx++, relation);
                else                  ps.setNull(idx++, Types.NUMERIC);

                // DATETIME, CREATED_DATE, MODIFIED_DATE
                ps.setDate(idx++, workingDate);
                ps.setDate(idx++, workingDate);
                ps.setDate(idx++, workingDate);

                ps.addBatch();
                savedCount++;
            }

            if (savedCount == 0) {
                conn.rollback();
                response.sendRedirect(
                    "lockerNominee.jsp?status=error&message=" +
                    java.net.URLEncoder.encode("No valid nominee data found to save.", "UTF-8")
                );
                return;
            }

            // Catch BatchUpdateException to surface the real Oracle ORA- error
            try {
                ps.executeBatch();
                conn.commit();
            } catch (java.sql.BatchUpdateException bue) {
                conn.rollback();
                SQLException next = bue.getNextException();
                String detail = (next != null) ? next.getMessage() : bue.getMessage();
                System.out.println("LockerNomineeServlet BATCH ERROR: " + detail);
                bue.printStackTrace();
                response.sendRedirect(
                    "lockerNominee.jsp?status=error&message=" +
                    java.net.URLEncoder.encode("Failed to save nominee(s): " + detail, "UTF-8")
                );
                return;
            }

            System.out.println("LockerNomineeServlet: Saved " + savedCount +
                " nominee(s) for Locker " + lockerType + "-" + lockerNumber +
                " Branch " + branchCode);

            response.sendRedirect(
                "lockerNominee.jsp?status=success&message=" +
                java.net.URLEncoder.encode(
                    savedCount + " nominee(s) saved successfully for Locker " +
                    lockerType + "-" + lockerNumber + ".", "UTF-8"
                )
            );

        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignored) {}
            }
            System.out.println("LockerNomineeServlet ERROR: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(
                "lockerNominee.jsp?status=error&message=" +
                java.net.URLEncoder.encode(
                    "Failed to save nominee(s): " + e.getMessage(), "UTF-8"
                )
            );

        } finally {
            try { if (delPs != null) delPs.close(); } catch (Exception ignored) {}
            try { if (ps    != null) ps.close();    } catch (Exception ignored) {}
            try { if (conn  != null) conn.close();  } catch (Exception ignored) {}
        }
    }
}