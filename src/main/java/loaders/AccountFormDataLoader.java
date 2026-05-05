package loaders;

import db.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

@WebServlet("/loaders/AccountFormDataLoader")
public class AccountFormDataLoader extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

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

            // 1. Salutation
            json.append("\"salutation\":");
            json.append(queryToJsonArray(conn,
                "SELECT SALUTATION_CODE AS val FROM GLOBALCONFIG.SALUTATION ORDER BY SALUTATION_CODE",
                "val", "val"));

            // 2. Relation with Guardian
            json.append(",\"relation\":");
            json.append(queryToJsonArray(conn,
                "SELECT RELATION_ID AS code, DESCRIPTION AS label FROM GLOBALCONFIG.RELATION ORDER BY RELATION_ID",
                "code", "label"));

            // 3. Country
            json.append(",\"country\":");
            json.append(queryToJsonArray(conn,
                "SELECT COUNTRY_CODE AS code, NAME AS label FROM GLOBALCONFIG.COUNTRY ORDER BY NAME",
                "code", "label"));

            // 4. State
            json.append(",\"state\":");
            json.append(queryToJsonArray(conn,
                "SELECT STATE_CODE AS code, NAME AS label FROM GLOBALCONFIG.STATE ORDER BY NAME",
                "code", "label"));

            // 5. City
            json.append(",\"city\":");
            json.append(queryToJsonArray(conn,
                "SELECT CITY_CODE AS code, NAME AS label FROM GLOBALCONFIG.CITY ORDER BY UPPER(NAME)",
                "code", "label"));

            // 6. Account Operation Capacity
            json.append(",\"accountOperationCapacity\":");
            json.append(queryToJsonArray(conn,
                "SELECT ACCOUNTOPERATIONCAPACITY_ID AS code, DESCRIPTION AS label " +
                "FROM GLOBALCONFIG.ACCOUNTOPERATIONCAPACITY ORDER BY ACCOUNTOPERATIONCAPACITY_ID",
                "code", "label"));

            // 7. Min Balance
            json.append(",\"minBalance\":");
            json.append(queryToJsonArray(conn,
                "SELECT MINBALANCE_ID AS code, MINBALANCE AS label " +
                "FROM HEADOFFICE.ACCOUNTMINBALANCE ORDER BY MINBALANCE_ID",
                "code", "label"));
            
	         // Security Type (used in many loan fieldsets)
	         json.append(",\"securityType\":");
	         json.append(queryToJsonArray(conn,
	             "SELECT SECURITYTYPE_CODE AS val FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE",
	             "val", "val"));

        } catch (Exception e) {
            json.append(",\"_error\":\"").append(escapeJson(e.getMessage())).append("\"");
        }

        json.append("}");
        out.print(json.toString());
    }

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

    private String nullSafe(String s) { return s == null ? "" : s; }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}