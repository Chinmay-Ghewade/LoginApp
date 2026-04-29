package servlet;

import db.DBConnection;
import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/CommonLookupServlet")
public class CommonLookupServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String type = request.getParameter("type");
        String action = request.getParameter("action");

        Connection conn = null;
        PrintWriter out = response.getWriter();

        try {

            if (type == null) {
                out.print("Invalid request");
                return;
            }

            // ✅ INIT CONNECTION FIRST
            conn = DBConnection.getConnection();

            // ===============================
            // 🔥 SESSION + AUTO LOAD FROM DB
            // ===============================
            HttpSession session = request.getSession();

            String isSupportUser = (String) session.getAttribute("isSupportUser");
            String sessionBranchCode = (String) session.getAttribute("branchCode");

            if (isSupportUser == null || sessionBranchCode == null) {

                String userId = (String) session.getAttribute("userId");

                if (userId != null) {

                    PreparedStatement psUser = conn.prepareStatement(
                        "SELECT IS_SUPPORT_USER, BRANCH_CODE FROM ACL.USERREGISTER WHERE USER_ID=?"
                    );
                    psUser.setString(1, userId);

                    ResultSet rsUser = psUser.executeQuery();

                    if (rsUser.next()) {

                        isSupportUser = rsUser.getString("IS_SUPPORT_USER");
                        sessionBranchCode = rsUser.getString("BRANCH_CODE");

                        // ✅ CLEAN VALUE
                        if (isSupportUser != null) {
                            isSupportUser = isSupportUser.trim().toUpperCase();
                        } else {
                            isSupportUser = "N";
                        }

                        // ✅ STORE IN SESSION
                        session.setAttribute("isSupportUser", isSupportUser);
                        session.setAttribute("branchCode", sessionBranchCode);
                    }

                    rsUser.close();
                    psUser.close();
                }
            }

            // fallback
            if (isSupportUser == null) isSupportUser = "N";
            if (sessionBranchCode == null) sessionBranchCode = "";

            // ===============================
            // 🔹 GET NAME
            // ===============================
            if ("getName".equalsIgnoreCase(action)) {

                response.setContentType("text/plain");

                String code = request.getParameter("code");

                if (code == null || code.trim().isEmpty()) {
                    out.print("");
                    return;
                }

                String query = "";

                if ("branch".equalsIgnoreCase(type)) {
                    query = "SELECT NAME FROM HEADOFFICE.BRANCH WHERE BRANCH_CODE=?";
                } else if ("account".equalsIgnoreCase(type)) {
                    query = "SELECT NAME FROM ACCOUNT.ACCOUNT WHERE ACCOUNT_CODE=?";
                } else if ("bank".equalsIgnoreCase(type)) {
                    query = "SELECT NAME FROM GLOBALCONFIG.BANK WHERE BANK_CODE=?";
                } else if ("product".equalsIgnoreCase(type)) {
                    query = "SELECT DESCRIPTION FROM HEADOFFICE.PRODUCT WHERE PRODUCT_CODE=?";
                } else if ("gl".equalsIgnoreCase(type)) {
                    query = "SELECT DESCRIPTION FROM HEADOFFICE.GLACCOUNT WHERE GLACCOUNT_CODE=?";   
                } else if ("area".equalsIgnoreCase(type)) {
                	query = "SELECT AREA_DESCRIPTION FROM BRANCH.BRANCHAREA WHERE AREA_CODE=?";
                } else if ("installment".equalsIgnoreCase(type)) {
                    query = "SELECT DISCRIPTION FROM HEADOFFICE.INSTALLMENTTYPE WHERE INSTALLMENTTYPE_ID=?";
                } else if ("accountType".equalsIgnoreCase(type)) {
                    query = "SELECT NAME FROM HEADOFFICE.ACCOUNTTYPE WHERE ACCOUNT_TYPE=?";
                } else if ("customer".equalsIgnoreCase(type)) {
                    query = "SELECT NAME FROM CUSTOMER.CUSTOMER WHERE CUSTOMER_ID=?";
                } else if ("city".equalsIgnoreCase(type)) {
                    query = "SELECT NAME FROM GLOBALCONFIG.CITY WHERE CITY_CODE=?";    
                } else if ("memberType".equalsIgnoreCase(type)) {
                    query = "SELECT DISCREPTION FROM SHARES.MEMBERTYPE_MASTER WHERE MEMBER_TYPECODE=?";
                } else {
                    out.print("");
                    return;
                }

                PreparedStatement ps = conn.prepareStatement(query);
                ps.setString(1, code);

                ResultSet rs = ps.executeQuery();

                if (rs.next()) {
                    out.print(rs.getString(1));
                }

                rs.close();
                ps.close();
                return;
            }

            response.setContentType("text/html;charset=UTF-8");

            // ===============================
            // 🔹 LIST DATA
            // ===============================
            if ("branch".equalsIgnoreCase(type)) {
                listBranch(conn, out, request, isSupportUser, sessionBranchCode);
            } else if ("account".equalsIgnoreCase(type)) {
                listAccount(conn, out, request);
            } else if ("bank".equalsIgnoreCase(type)) {
                listBank(conn, out);
            } else if ("product".equalsIgnoreCase(type)) {
            	listProduct(conn, out, request);
            } else if ("glByAccountType".equalsIgnoreCase(type)) {
                listGLByAccountType(conn, out, request);
            } else if ("area".equalsIgnoreCase(type)) {
                listArea(conn, out);  
            } else if ("installment".equalsIgnoreCase(type)) {
                listInstallment(conn, out);
            } else if ("accountType".equalsIgnoreCase(type)) {
                listAccountType(conn, out);
            } else if ("customer".equalsIgnoreCase(type)) {
                listCustomer(conn, out);
            } else if ("city".equalsIgnoreCase(type)) {
                listCity(conn, out);
            } else if ("memberType".equalsIgnoreCase(type)) {
                listMemberType(conn, out);
            } else {
                out.println("<h3 style='color:red;'>Invalid type</h3>");
            }

        } catch (Exception e) {
            e.printStackTrace();
            out.println("<h3 style='color:red;'>Error loading data</h3>");
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }

    // ===============================
    // 🔹 HEADER
    // ===============================
    private void printTableHeader(PrintWriter out, String title, String col1, String col2, boolean showCity) {

        out.println("<div class='lookup-container'>");
        out.println("<div class='lookup-title'>" + title + "</div>");
        out.println("<div class='lookup-table-wrapper'>");
        out.println("<table class='lookup-table'>");

        out.println("<tr>");
        out.println("<th>" + col1 + "</th>");
        out.println("<th>" + col2 + "</th>");

        if (showCity) out.println("<th>City Code</th>");

        out.println("</tr>");
    }

    private void printTableFooter(PrintWriter out) {
        out.println("</table></div></div>");
    }

    // ===============================
    // 🔹 BRANCH (ROLE BASED)
    // ===============================
    private void listBranch(Connection conn, PrintWriter out,
            HttpServletRequest request,
            String isSupportUser,
            String sessionBranchCode) throws Exception {

        boolean showCity = "true".equalsIgnoreCase(request.getParameter("showCity"));

        String sql;

        if ("Y".equalsIgnoreCase(isSupportUser)) {
            sql = "SELECT BRANCH_CODE, NAME, CITY_CODE FROM HEADOFFICE.BRANCH ORDER BY BRANCH_CODE";
        } else {
            sql = "SELECT BRANCH_CODE, NAME, CITY_CODE FROM HEADOFFICE.BRANCH WHERE BRANCH_CODE = ?";
        }

        PreparedStatement ps = conn.prepareStatement(sql);

        if (!"Y".equalsIgnoreCase(isSupportUser)) {
            ps.setString(1, sessionBranchCode);
        }

        ResultSet rs = ps.executeQuery();

        printTableHeader(out, "Select Branch", "Code", "Description", showCity);

        while (rs.next()) {

            String code = rs.getString("BRANCH_CODE");
            String name = rs.getString("NAME");
            String city = showCity ? rs.getString("CITY_CODE") : "";

            code = code == null ? "" : code.replace("'", "\\'");
            name = name == null ? "" : name.replace("'", "\\'");
            city = city == null ? "" : city.replace("'", "\\'");

            out.println("<tr class='lookup-row' onclick=\"selectBranch('"
                    + code + "','" + name + "'" +
                    (showCity ? ",'" + city + "'" : "") +
                    ")\">");

            out.println("<td>" + code + "</td>");
            out.println("<td>" + name + "</td>");
            if (showCity) out.println("<td>" + city + "</td>");

            out.println("</tr>");
        }

        printTableFooter(out);

        rs.close();
        ps.close();
    }

    // ===============================
    // 🔹 ACCOUNT
    // ===============================
    private void listAccount(Connection conn, PrintWriter out, HttpServletRequest request) throws Exception {

        String branchCode = request.getParameter("branchCode");

        if (branchCode == null || branchCode.trim().isEmpty()) {
            out.println("<h3 style='color:red;'>Branch required</h3>");
            return;
        }

        String sql =
            "SELECT ACCOUNT_CODE, NAME FROM ACCOUNT.ACCOUNT " +
            "WHERE ACCOUNT_CODE LIKE ? AND ACCOUNT_STATUS='L' AND DATEACCOUNTCLOSE IS NULL ORDER BY ACCOUNT_CODE";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, branchCode + "%");

        ResultSet rs = ps.executeQuery();

        printTableHeader(out, "Select Account", "Account Code", "Name", false);

        while (rs.next()) {

            String code = rs.getString("ACCOUNT_CODE");
            String name = rs.getString("NAME");

            code = code == null ? "" : code.replace("'", "\\'");
            name = name == null ? "" : name.replace("'", "\\'");

            out.println("<tr class='lookup-row' onclick=\"selectAccount('"
                    + code + "','" + name + "')\">");

            out.println("<td>" + code + "</td>");
            out.println("<td>" + name + "</td>");
            out.println("</tr>");
        }

        printTableFooter(out);

        rs.close();
        ps.close();
    }

    // ===============================
    // 🔹 BANK
    // ===============================
    private void listBank(Connection conn, PrintWriter out) throws Exception {

        PreparedStatement ps = conn.prepareStatement(
            "SELECT BANK_CODE, NAME FROM GLOBALCONFIG.BANK ORDER BY BANK_CODE"
        );

        ResultSet rs = ps.executeQuery();

        printTableHeader(out, "Select Bank", "Bank Code", "Name", false);

        while (rs.next()) {

            String code = rs.getString("BANK_CODE");
            String name = rs.getString("NAME");

            out.println("<tr class='lookup-row' onclick=\"selectBank('"
                    + code + "','" + name + "')\">");

            out.println("<td>" + code + "</td>");
            out.println("<td>" + name + "</td>");
            out.println("</tr>");
        }

        printTableFooter(out);

        rs.close();
        ps.close();
    }

    // ===============================
    // 🔹 PRODUCT
    // ===============================
 
 private void listProduct(Connection conn, PrintWriter out, HttpServletRequest request) throws Exception {

     String sql =
         "SELECT PRODUCT_CODE, DESCRIPTION, ACCOUNT_TYPE FROM HEADOFFICE.PRODUCT ORDER BY PRODUCT_CODE";

     PreparedStatement ps = conn.prepareStatement(sql);
     ResultSet rs = ps.executeQuery();

     out.println("<div class='lookup-container'>");
     out.println("<div class='lookup-title'>Select Product</div>");
     out.println("<div class='lookup-table-wrapper'>");
     out.println("<table class='lookup-table'>");

     // ✅ HEADER (ADDED ACCOUNT TYPE COLUMN)
     out.println("<tr>");
     out.println("<th>Product Code</th>");
     out.println("<th>Description</th>");
     out.println("<th>Account Type</th>");
     out.println("</tr>");

     while (rs.next()) {

         String code = rs.getString("PRODUCT_CODE");
         String name = rs.getString("DESCRIPTION");
         String type = rs.getString("ACCOUNT_TYPE");

         if (code == null) code = "";
         if (name == null) name = "";
         if (type == null) type = "";

         code = code.replace("'", "\\'");
         name = name.replace("'", "\\'");
         type = type.replace("'", "\\'");

         // ✅ PASS ACCOUNT TYPE ALSO
         out.println("<tr class='lookup-row' onclick=\"selectProduct('"
                 + code + "','" + name + "','" + type + "')\">");

         out.println("<td>" + code + "</td>");
         out.println("<td>" + name + "</td>");
         out.println("<td>" + type + "</td>");

         out.println("</tr>");
     }

     printTableFooter(out);

     rs.close();
     ps.close();
 }
//===============================
 // 🔹 GL ACCOUNT
 // ===============================
 
 private void listGLByAccountType(Connection conn, PrintWriter out, HttpServletRequest request) throws Exception {

	 String accType = request.getParameter("accountType");

	 String sql;
	 PreparedStatement ps;

	 if (accType == null || accType.trim().isEmpty()) {

	     // ✅ CURRENT MODE (DIRECT ALL GL)
	     sql = "SELECT DISTINCT GLACCOUNT_CODE , DESCRIPTION FROM HEADOFFICE.GLACCOUNT ORDER BY GLACCOUNT_CODE";
	     ps = conn.prepareStatement(sql);

	 } else {

	     // ✅ FUTURE MODE (FILTER BY ACCOUNT TYPE)
	     sql =
	         "SELECT DISTINCT G.GLACCOUNT_CODE , G.DESCRIPTION " +
	         "FROM HEADOFFICE.GLACCOUNT G " +
	         "JOIN HEADOFFICE.PRODUCT P ON G.PRODUCT_CODE = P.PRODUCT_CODE " +
	         "WHERE P.ACCOUNT_TYPE = ? " +
	         "ORDER BY G.GLACCOUNT_CODE";

	     ps = conn.prepareStatement(sql);
	     ps.setString(1, accType);
	 }

	 ResultSet rs = ps.executeQuery();

	    out.println("<div class='lookup-container'>");
	    out.println("<div class='lookup-title'>Select GL Account</div>");
	    out.println("<div class='lookup-table-wrapper'>");
	    out.println("<table class='lookup-table'>");

	    out.println("<tr>");
	    out.println("<th>GL Account Code</th>");
	    out.println("<th>Description</th>");
	    out.println("</tr>");

	    while (rs.next()) {

	    	String glCode = rs.getString("GLACCOUNT_CODE");
	    	String desc = rs.getString("DESCRIPTION");

	    	if (glCode == null) glCode = "";
	    	if (desc == null) desc = "";

	    	glCode = glCode.replace("'", "\\'");
	    	desc = desc.replace("'", "\\'");

	        out.println("<tr class='lookup-row' onclick=\"selectGL('"
	                + glCode + "','" + desc + "')\">");

	        out.println("<td>" + glCode + "</td>");
	        out.println("<td>" + desc + "</td>");
	        out.println("</tr>");
	    }

	    printTableFooter(out);

	    rs.close();
	    ps.close();
	}
//===============================
 // 🔹 AREA
 // ===============================
 
 private void listArea(Connection conn, PrintWriter out) throws Exception {

	 String sql = "SELECT AREA_CODE, AREA_DESCRIPTION FROM BRANCH.BRANCHAREA ORDER BY AREA_CODE";
	 
	    PreparedStatement ps = conn.prepareStatement(sql);
	    ResultSet rs = ps.executeQuery();

	    printTableHeader(out, "Select Area", "Area Code", "Name", false);

	    while (rs.next()) {

	        String code = rs.getString(1);   // safer
	        String name = rs.getString(2);   // safer

	        if (code == null) code = "";
	        if (name == null) name = "";

	        code = code.replace("'", "\\'");
	        name = name.replace("'", "\\'");

	        out.println("<tr class='lookup-row' onclick=\"selectArea('" 
	        	    + code.replace("'", "") + "','" 
	        	    + name.replace("'", "") + "')\">");

	        out.println("<td>" + code + "</td>");
	        out.println("<td>" + name + "</td>");
	        out.println("</tr>");
	    }

	    printTableFooter(out);

	    rs.close();
	    ps.close();
	}

//===============================
 // 🔹 listInstallment
 // ===============================

private void listInstallment(Connection conn, PrintWriter out) throws Exception {

	String sql = "SELECT INSTALLMENTTYPE_ID, DISCRIPTION FROM HEADOFFICE.INSTALLMENTTYPE ORDER BY INSTALLMENTTYPE_ID";
	
    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();

    printTableHeader(out, "Select Installment", "Code", "Description", false);

    while (rs.next()) {

    	String code = rs.getString("INSTALLMENTTYPE_ID");
    	String name = rs.getString("DISCRIPTION");
    	
        code = code == null ? "" : code.replace("'", "\\'");
        name = name == null ? "" : name.replace("'", "\\'");

        out.println("<tr class='lookup-row' onclick=\"selectInstallment('"
                + code + "','" + name + "')\">");

        out.println("<td>" + code + "</td>");
        out.println("<td>" + name + "</td>");
        out.println("</tr>");
    }

    printTableFooter(out);

    rs.close();
    ps.close();
}

//===============================
// 🔹 ACCOUNT TYPE
// ===============================

private void listAccountType(Connection conn, PrintWriter out) throws Exception {

	String sql = 
		    "SELECT ACCOUNT_TYPE, NAME FROM HEADOFFICE.ACCOUNTTYPE ORDER BY ACCOUNT_TYPE";
	
    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();

    printTableHeader(out, "Select Account Type", "Type", "Description", false);

    while (rs.next()) {

        String code = rs.getString("ACCOUNT_TYPE");
        String name = rs.getString("NAME");

        if (code == null) code = "";
        if (name == null) name = "";

        code = code.replace("'", "\\'");
        name = name.replace("'", "\\'");

        out.println("<tr class='lookup-row' onclick=\"selectAccountType('"
                + code + "','" + name + "')\">");

        out.println("<td>" + code + "</td>");
        out.println("<td>" + name + "</td>");
        out.println("</tr>");
    }

    printTableFooter(out);

    rs.close();
    ps.close();
}
//===============================
//🔹 CUSTOMER
//===============================

private void listCustomer(Connection conn, PrintWriter out) throws Exception {

    String sql =
        "SELECT CUSTOMER_ID, NAME FROM CUSTOMER.CUSTOMER ORDER BY CUSTOMER_ID";

    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();

    printTableHeader(out, "Select Customer", "Customer ID", "Name", false);

    while (rs.next()) {

        String id = rs.getString("CUSTOMER_ID");
        String name = rs.getString("NAME");

        if (id == null) id = "";
        if (name == null) name = "";

        id = id.replace("'", "\\'");
        name = name.replace("'", "\\'");

        out.println("<tr class='lookup-row' onclick=\"selectCustomer('"
                + id + "','" + name + "')\">");

        out.println("<td>" + id + "</td>");
        out.println("<td>" + name + "</td>");
        out.println("</tr>");
    }

    printTableFooter(out);

    rs.close();
    ps.close();
}
//===============================
//🔹 CITY
//===============================
private void listCity(Connection conn, PrintWriter out) throws Exception {

    String sql =
        "SELECT CITY_CODE, NAME FROM GLOBALCONFIG.CITY ORDER BY CITY_CODE";

    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();

    printTableHeader(out, "Select City", "City Code", "City Name", false);

    while (rs.next()) {

        String code = rs.getString("CITY_CODE");
        String name = rs.getString("NAME");

        if (code == null) code = "";
        if (name == null) name = "";

        code = code.replace("'", "\\'");
        name = name.replace("'", "\\'");

        out.println("<tr class='lookup-row' onclick=\"selectCity('"
                + code + "','" + name + "')\">");

        out.println("<td>" + code + "</td>");
        out.println("<td>" + name + "</td>");
        out.println("</tr>");
    }

    printTableFooter(out);

    rs.close();
    ps.close();
}
//===============================
//🔹 MEMBER TYPE
//===============================
private void listMemberType(Connection conn, PrintWriter out) throws Exception {

 String sql = 
     "SELECT MEMBER_TYPECODE, DISCREPTION FROM SHARES.MEMBERTYPE_MASTER ORDER BY MEMBER_TYPECODE";

 PreparedStatement ps = conn.prepareStatement(sql);
 ResultSet rs = ps.executeQuery();

 printTableHeader(out, "Select Member Type", "Code", "Description", false);

 while (rs.next()) {

     String code = rs.getString("MEMBER_TYPECODE");
     String name = rs.getString("DISCREPTION");

     if (code == null) code = "";
     if (name == null) name = "";

     code = code.replace("'", "\\'");
     name = name.replace("'", "\\'");

     out.println("<tr class='lookup-row' onclick=\"selectMemberType('"
             + code + "','" + name + "')\">");

     out.println("<td>" + code + "</td>");
     out.println("<td>" + name + "</td>");
     out.println("</tr>");
 }

 printTableFooter(out);

 rs.close();
 ps.close();
}

}

