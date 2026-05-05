package loaders;

import db.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * OpenAccountFormLoader
 *
 * Loads ALL dropdown data required by Open Account forms in a single HTTP
 * request, exactly like AddCustomerDataLoader does for the Add Customer form.
 *
 * Endpoint : GET /loaders/OpenAccountFormLoader
 * Response : JSON object whose keys match the names used in the JS DD_MAP
 *            on each JSP (savingAcc, deposit, pigmy, shares, loan).
 *
 * Dropdowns included
 * ──────────────────
 * Common (all forms)
 *   salutation            – GLOBALCONFIG.SALUTATION
 *   accountOperationCapacity – GLOBALCONFIG.ACCOUNTOPERATIONCAPACITY
 *   minBalance            – HEADOFFICE.ACCOUNTMINBALANCE
 *   country               – GLOBALCONFIG.COUNTRY
 *   state                 – GLOBALCONFIG.STATE
 *   city                  – GLOBALCONFIG.CITY
 *   relation              – GLOBALCONFIG.RELATION   (nominee relation)
 *
 * Loan-only
 *   socialSection         – GLOBALCONFIG.SOCIALSECTION
 *   lbrCode               – HEADOFFICE.MIS
 *   purposeId             – HEADOFFICE.PURPOSE
 *   classificationId      – HEADOFFICE.CLASSIFICATION
 *   modeOfSanction        – HEADOFFICE.MODEOFSANCTION
 *   sanctionAuthority     – HEADOFFICE.SANCTIONAUTHORITY
 *   industryId            – HEADOFFICE.INDUSTRY
 *   securityType          – GLOBALCONFIG.SECURITYTYPE
 *   installmentType       – HEADOFFICE.INSTALLMENTTYPE
 *
 * JSON shape per array item
 *   { "v": "<option value>", "l": "<option label>" }
 */
@WebServlet("/loaders/OpenAccountFormLoader")
public class OpenAccountFormLoader extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ── Session guard ──────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("branchCode") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json; charset=UTF-8");
            response.getWriter().write("{\"error\":\"Session expired\"}");
            return;
        }

        response.setContentType("application/json; charset=UTF-8");
        response.setHeader("Cache-Control", "no-cache");
        PrintWriter out = response.getWriter();

        StringBuilder json = new StringBuilder();
        json.append("{");

        try (Connection conn = DBConnection.getConnection()) {

            // ── 1. Salutation ──────────────────────────────────────────
            json.append("\"salutation\":");
            json.append(queryToJsonArray(conn,
                "SELECT SALUTATION_CODE AS val, SALUTATION_CODE AS lbl " +
                "FROM GLOBALCONFIG.SALUTATION ORDER BY SALUTATION_CODE",
                "val", "lbl"));

            // ── 2. Account Operation Capacity ──────────────────────────
            json.append(",\"accountOperationCapacity\":");
            json.append(queryToJsonArray(conn,
                "SELECT ACCOUNTOPERATIONCAPACITY_ID AS val, DESCRIPTION AS lbl " +
                "FROM GLOBALCONFIG.ACCOUNTOPERATIONCAPACITY " +
                "ORDER BY ACCOUNTOPERATIONCAPACITY_ID",
                "val", "lbl"));

            // ── 3. Min Balance ─────────────────────────────────────────
            json.append(",\"minBalance\":");
            json.append(queryToJsonArray(conn,
                "SELECT MINBALANCE_ID AS val, MINBALANCE AS lbl " +
                "FROM HEADOFFICE.ACCOUNTMINBALANCE ORDER BY MINBALANCE_ID",
                "val", "lbl"));

            // ── 4. Country ─────────────────────────────────────────────
            json.append(",\"country\":");
            json.append(queryToJsonArray(conn,
                "SELECT COUNTRY_CODE AS val, NAME AS lbl " +
                "FROM GLOBALCONFIG.COUNTRY ORDER BY NAME",
                "val", "lbl"));

            // ── 5. State ───────────────────────────────────────────────
            json.append(",\"state\":");
            json.append(queryToJsonArray(conn,
                "SELECT STATE_CODE AS val, NAME AS lbl " +
                "FROM GLOBALCONFIG.STATE ORDER BY NAME",
                "val", "lbl"));

            // ── 6. City ────────────────────────────────────────────────
            json.append(",\"city\":");
            json.append(queryToJsonArray(conn,
                "SELECT CITY_CODE AS val, NAME AS lbl " +
                "FROM GLOBALCONFIG.CITY ORDER BY UPPER(NAME)",
                "val", "lbl"));

            // ── 7. Relation with Guardian ──────────────────────────────
            json.append(",\"relation\":");
            json.append(queryToJsonArray(conn,
                "SELECT RELATION_ID AS val, DESCRIPTION AS lbl " +
                "FROM GLOBALCONFIG.RELATION ORDER BY RELATION_ID",
                "val", "lbl"));

            // ── 8. Social Section (loan) ───────────────────────────────
            json.append(",\"socialSection\":");
            json.append(queryToJsonArray(conn,
                "SELECT SOCIALSECTION_ID AS val, DESCRIPTION AS lbl " +
                "FROM GLOBALCONFIG.SOCIALSECTION ORDER BY SOCIALSECTION_ID",
                "val", "lbl"));

            // ── 9. LBR Code / MIS (loan) ──────────────────────────────
            json.append(",\"lbrCode\":");
            json.append(queryToJsonArray(conn,
                "SELECT MIS_ID AS val, DESCRIPTION AS lbl " +
                "FROM HEADOFFICE.MIS ORDER BY DESCRIPTION",
                "val", "lbl"));

            // ── 10. Purpose (loan) ─────────────────────────────────────
            json.append(",\"purposeId\":");
            json.append(queryToJsonArray(conn,
                "SELECT PURPOSE_ID AS val, DESCRIPTION AS lbl " +
                "FROM HEADOFFICE.PURPOSE ORDER BY DESCRIPTION",
                "val", "lbl"));

            // ── 11. Classification (loan) ──────────────────────────────
            json.append(",\"classificationId\":");
            json.append(queryToJsonArray(conn,
                "SELECT CLASSIFICATION_ID AS val, DESCRIPTION AS lbl " +
                "FROM HEADOFFICE.CLASSIFICATION ORDER BY DESCRIPTION",
                "val", "lbl"));

            // ── 12. Mode of Sanction (loan) ────────────────────────────
            json.append(",\"modeOfSanction\":");
            json.append(queryToJsonArray(conn,
                "SELECT MODEOFSANCTION_ID AS val, DESCRIPTION AS lbl " +
                "FROM HEADOFFICE.MODEOFSANCTION ORDER BY DESCRIPTION",
                "val", "lbl"));

            // ── 13. Sanction Authority (loan) ──────────────────────────
            json.append(",\"sanctionAuthority\":");
            json.append(queryToJsonArray(conn,
                "SELECT SANCTIONAUTHORITY_ID AS val, DESCRIPTION AS lbl " +
                "FROM HEADOFFICE.SANCTIONAUTHORITY ORDER BY DESCRIPTION",
                "val", "lbl"));

            // ── 14. Industry (loan) ────────────────────────────────────
            json.append(",\"industryId\":");
            json.append(queryToJsonArray(conn,
                "SELECT INDUSTRY_ID AS val, DESCRIPTION AS lbl " +
                "FROM HEADOFFICE.INDUSTRY ORDER BY DESCRIPTION",
                "val", "lbl"));

            // ── 15. Security Type (loan collateral fieldsets) ──────────
            json.append(",\"securityType\":");
            json.append(queryToJsonArray(conn,
                "SELECT SECURITYTYPE_CODE AS val, SECURITYTYPE_CODE AS lbl " +
                "FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE",
                "val", "lbl"));

            // ── 16. Installment Type (loan) ────────────────────────────
            json.append(",\"installmentType\":");
            json.append(queryToJsonArray(conn,
                "SELECT INSTALLMENTTYPE_ID AS val, DISCRIPTION AS lbl " +
                "FROM HEADOFFICE.INSTALLMENTTYPE ORDER BY INSTALLMENTTYPE_ID",
                "val", "lbl"));

            // ── 17. Interest Payment Frequency (deposit – static) ──────
            //  These are hardcoded in deposit.jsp; kept here as a reference
            //  but the servlet returns them as static JSON so no extra query.
            json.append(",\"interestPaymentFrequency\":");
            json.append("[" +
                "{\"v\":\"On Maturity\",\"l\":\"On Maturity\"}," +
                "{\"v\":\"Monthly\",\"l\":\"Monthly\"}," +
                "{\"v\":\"Quarterly\",\"l\":\"Quarterly\"}," +
                "{\"v\":\"Half-Yearly\",\"l\":\"Half-Yearly\"}," +
                "{\"v\":\"Yearly\",\"l\":\"Yearly\"}" +
                "]");

        } catch (Exception e) {
            json.append(",\"_error\":\"").append(escapeJson(e.getMessage())).append("\"");
        }

        json.append("}");
        out.print(json.toString());
    }

    // ──────────────────────────────────────────────────────────────────
    // Executes a SELECT and returns a JSON array of {v, l} objects.
    // valueCol = column used as <option value="">
    // labelCol = column used as <option> display text
    // ──────────────────────────────────────────────────────────────────
    private String queryToJsonArray(Connection conn, String sql,
                                    String valueCol, String labelCol)
            throws SQLException {

        StringBuilder arr = new StringBuilder("[");
        boolean first = true;

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                if (!first) arr.append(",");
                first = false;
                String v = nullSafe(rs.getString(valueCol));
                String l = nullSafe(rs.getString(labelCol));
                arr.append("{\"v\":\"").append(escapeJson(v))
                   .append("\",\"l\":\"").append(escapeJson(l))
                   .append("\"}");
            }
        }

        arr.append("]");
        return arr.toString();
    }

    private String nullSafe(String s) {
        return s == null ? "" : s.trim();
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
