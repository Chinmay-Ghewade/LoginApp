<%@ page import="java.sql.*, db.DBConnection, java.util.*, org.json.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        out.print("{\"error\": \"Only POST method allowed\", \"accounts\": []}");
        return;
    }

    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        out.print("{\"error\": \"Session expired\", \"accounts\": []}");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    String searchTerm  = request.getParameter("searchNumber");   // reused for IFSC text too
    String category    = request.getParameter("category");

    if (searchTerm == null || searchTerm.trim().isEmpty() ||
        category   == null || category.trim().isEmpty()) {
        out.print("{\"error\": \"Invalid parameters\", \"accounts\": []}");
        return;
    }

    searchTerm = searchTerm.trim();
    category   = category.trim().toLowerCase();

    // ─────────────────────────────────────────────────────────────────
    // IFSC SEARCH  (separate branch — no branchCode / digit check)
    // ─────────────────────────────────────────────────────────────────
    if ("ifsc".equals(category)) {

        if (searchTerm.length() < 3) {
            out.print("{\"error\": \"Type at least 3 characters to search\", \"accounts\": []}");
            return;
        }

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBConnection.getConnection();

            // ✅ MODIFIED: Added DISTRICT_NAME and STATE_NAME to query
            String query = "SELECT IFSC_CODE, BANK_NAME, BRANCH_NAME, DISTRICT_NAME, STATE_NAME " +
                           "FROM GLOBALCONFIG.BANK_BRANCH_IFC_CODE " +
                           "WHERE UPPER(IFSC_CODE) LIKE UPPER(?) " +
                           "AND ROWNUM <= 50 " +
                           "ORDER BY IFSC_CODE";

            ps = con.prepareStatement(query);
            ps.setString(1, searchTerm + "%");   // prefix match from start
            rs = ps.executeQuery();

            JSONObject jsonResponse = new JSONObject();
            jsonResponse.put("success", true);

            JSONArray accountsArray = new JSONArray();
            int count = 0;

            while (rs.next()) {
                JSONObject item = new JSONObject();
                item.put("code",        rs.getString("IFSC_CODE")   != null ? rs.getString("IFSC_CODE").trim()   : "");
                item.put("name",        rs.getString("BANK_NAME")   != null ? rs.getString("BANK_NAME").trim()   : "");
                item.put("branchName",  rs.getString("BRANCH_NAME") != null ? rs.getString("BRANCH_NAME").trim() : "");
                // ✅ ADDED: districtName and stateName
                item.put("districtName", rs.getString("DISTRICT_NAME") != null ? rs.getString("DISTRICT_NAME").trim() : "");
                item.put("stateName",    rs.getString("STATE_NAME")    != null ? rs.getString("STATE_NAME").trim()    : "");
                item.put("productDesc", "");
                accountsArray.put(item);
                count++;
            }

            jsonResponse.put("count",        count);
            jsonResponse.put("accounts",     accountsArray);
            jsonResponse.put("searchNumber", searchTerm);
            jsonResponse.put("category",     category);

            out.print(jsonResponse.toString());

        } catch (SQLException e) {
            e.printStackTrace();
            JSONObject err = new JSONObject();
            err.put("success", false);
            err.put("error",   "Database error: " + e.getMessage());
            err.put("accounts", new JSONArray());
            out.print(err.toString());

        } finally {
            if (rs  != null) try { rs.close();  } catch (SQLException e) { e.printStackTrace(); }
            if (ps  != null) try { ps.close();  } catch (SQLException e) { e.printStackTrace(); }
            if (con != null) try { con.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        return;
    }

    // ─────────────────────────────────────────────────────────────────
    // ACCOUNT SEARCH  (original logic — digits only)
    // ─────────────────────────────────────────────────────────────────
    if (!searchTerm.matches("\\d+")) {
        out.print("{\"error\": \"Invalid search number\", \"accounts\": []}");
        return;
    }

    if (searchTerm.length() < 3) {
        out.print("{\"error\": \"Search term too short\", \"accounts\": []}");
        return;
    }

    // PAD THE SEARCH NUMBER WITH LEADING ZEROS TO MAKE IT 7 DIGITS
    String paddedSearchNumber = String.format("%07d", Integer.parseInt(searchTerm));

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = DBConnection.getConnection();

        String query = "";

        if ("loan".equals(category)) {
            query = "SELECT ACCOUNT_CODE, NAME, " +
                    "FN_GET_PRODUCT_DESC(SUBSTR(ACCOUNT_CODE, 5, 3)) AS PRODUCT_DESC " +
                    "FROM ACCOUNT.ACCOUNT " +
                    "WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ? " +
                    "AND SUBSTR(ACCOUNT_CODE, 5, 1) IN ('5','7') " +
                    "AND SUBSTR(ACCOUNT_CODE, -7) LIKE ? " +
                    "AND ACCOUNT_STATUS = 'L' " +
                    "ORDER BY ACCOUNT_CODE";
        } else if ("rtgs".equals(category)) {
            query = "SELECT ACCOUNT_CODE, NAME, " +
                    "FN_GET_PRODUCT_DESC(SUBSTR(ACCOUNT_CODE, 5, 3)) AS PRODUCT_DESC " +
                    "FROM ACCOUNT.ACCOUNT " +
                    "WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ? " +
                    "AND SUBSTR(ACCOUNT_CODE, 5, 1) IN ('1','2','3') " +
                    "AND SUBSTR(ACCOUNT_CODE, -7) LIKE ? " +
                    "AND ACCOUNT_STATUS = 'L' " +
                    "ORDER BY ACCOUNT_CODE";
        } else {
            String productCodePattern = "";
            switch (category) {
                case "saving":  productCodePattern = "2"; break;
                case "deposit": productCodePattern = "4"; break;
                case "pigmy":   productCodePattern = "6"; break;
                case "current": productCodePattern = "1"; break;
                case "cc":      productCodePattern = "3"; break;
                default:
                    out.print("{\"error\": \"Invalid category\", \"accounts\": []}");
                    return;
            }

            query = "SELECT ACCOUNT_CODE, NAME, " +
                    "FN_GET_PRODUCT_DESC(SUBSTR(ACCOUNT_CODE, 5, 3)) AS PRODUCT_DESC " +
                    "FROM ACCOUNT.ACCOUNT " +
                    "WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ? " +
                    "AND SUBSTR(ACCOUNT_CODE, 5, 1) = ? " +
                    "AND SUBSTR(ACCOUNT_CODE, -7) LIKE ? " +
                    "AND ACCOUNT_STATUS = 'L' " +
                    "ORDER BY ACCOUNT_CODE";
        }

        ps = con.prepareStatement(query);
        ps.setString(1, branchCode);

        if ("loan".equals(category) || "rtgs".equals(category)) {
            ps.setString(2, "%" + paddedSearchNumber + "%");
        } else {
            String productCodePattern = "";
            switch (category) {
                case "saving":  productCodePattern = "2"; break;
                case "deposit": productCodePattern = "4"; break;
                case "pigmy":   productCodePattern = "6"; break;
                case "current": productCodePattern = "1"; break;
                case "cc":      productCodePattern = "3"; break;
            }
            ps.setString(2, productCodePattern);
            ps.setString(3, "%" + paddedSearchNumber + "%");
        }

        rs = ps.executeQuery();

        JSONObject jsonResponse = new JSONObject();
        jsonResponse.put("success", true);

        JSONArray accountsArray = new JSONArray();
        int count = 0;

        while (rs.next()) {
            JSONObject account = new JSONObject();
            account.put("code", rs.getString("ACCOUNT_CODE"));
            account.put("name", rs.getString("NAME"));

            String productDesc = rs.getString("PRODUCT_DESC");
            account.put("productDesc", productDesc != null ? productDesc : "");

            accountsArray.put(account);
            count++;
        }

        jsonResponse.put("count",              count);
        jsonResponse.put("accounts",           accountsArray);
        jsonResponse.put("searchNumber",       searchTerm);
        jsonResponse.put("paddedSearchNumber", paddedSearchNumber);
        jsonResponse.put("category",           category);

        out.print(jsonResponse.toString());

    } catch (NumberFormatException e) {
        JSONObject errorResponse = new JSONObject();
        errorResponse.put("success", false);
        errorResponse.put("error",   "Invalid number format");
        errorResponse.put("accounts", new JSONArray());
        out.print(errorResponse.toString());

    } catch (SQLException e) {
        e.printStackTrace();

        JSONObject errorResponse = new JSONObject();
        errorResponse.put("success", false);
        errorResponse.put("error",   "Database error: " + e.getMessage());
        errorResponse.put("accounts", new JSONArray());
        out.print(errorResponse.toString());

    } finally {
        if (rs  != null) try { rs.close();  } catch (SQLException e) { e.printStackTrace(); }
        if (ps  != null) try { ps.close();  } catch (SQLException e) { e.printStackTrace(); }
        if (con != null) try { con.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>
