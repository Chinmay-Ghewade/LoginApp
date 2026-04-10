<%@ page import="java.sql.*, db.DBConnection, org.json.JSONObject" %>
<%@ page contentType="application/json; charset=UTF-8" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    JSONObject jsonResponse = new JSONObject();
    Connection conn = null;
    CallableStatement cstmt = null;

    try {
        // Get parameters
        String loanAmountStr = request.getParameter("loanAmount");
        String rateStr = request.getParameter("rate");
        String periodStr = request.getParameter("period");

        System.out.println("📊 EMI Request:");
        System.out.println("Loan: " + loanAmountStr);
        System.out.println("Rate: " + rateStr);
        System.out.println("Period: " + periodStr);

        // Validate parameters
        if (loanAmountStr == null || rateStr == null || periodStr == null) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Missing required parameters");
            out.print(jsonResponse.toString());
            return;
        }

        double loanAmount = Double.parseDouble(loanAmountStr);
        double rate = Double.parseDouble(rateStr);
        int period = Integer.parseInt(periodStr);

        if (loanAmount <= 0 || rate <= 0 || period <= 0) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "All values must be greater than 0");
            out.print(jsonResponse.toString());
            return;
        }

        // DB Connection
        conn = DBConnection.getConnection();
        System.out.println("✅ DB Connected");

        // ✅ Correct function call (ONLY 3 PARAMETERS)
        String funcSql = "{? = call fn_get_emi_inst(?, ?, ?)}";
        cstmt = conn.prepareCall(funcSql);

        // Register return value
        cstmt.registerOutParameter(1, Types.NUMERIC);

        // Set inputs
        cstmt.setBigDecimal(2, new java.math.BigDecimal(loanAmount));
        cstmt.setBigDecimal(3, new java.math.BigDecimal(rate));
        cstmt.setInt(4, period);

        System.out.println("📞 Calling fn_get_emi_inst...");

        // Execute
        cstmt.execute();

        java.math.BigDecimal emiBD = cstmt.getBigDecimal(1);

        if (emiBD == null) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Function returned NULL");
        } else {
            double emi = emiBD.doubleValue();

            jsonResponse.put("success", true);
            jsonResponse.put("emiAmount", Math.round(emi * 100.0) / 100.0);
            jsonResponse.put("message", "EMI calculated successfully");

            System.out.println("✅ EMI: " + emi);
        }

    } catch (NumberFormatException e) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Invalid number format");
        e.printStackTrace();

    } catch (SQLException e) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Database error: " + e.getMessage());
        e.printStackTrace();

    } catch (Exception e) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Unexpected error: " + e.getMessage());
        e.printStackTrace();

    } finally {
        try {
            if (cstmt != null) cstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    out.print(jsonResponse.toString());
%>