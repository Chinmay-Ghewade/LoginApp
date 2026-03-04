<%@ page import="java.sql.*, java.io.PrintWriter, db.DBConnection" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%
    response.reset();
    response.setContentType("application/json; charset=UTF-8");
    PrintWriter pw = response.getWriter();

    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        pw.print("{\"error\":\"Session expired\",\"accounts\":[]}");
        pw.flush(); return;
    }

    String searchNumber = request.getParameter("searchNumber");
    if (searchNumber == null || searchNumber.trim().isEmpty()) {
        pw.print("{\"accounts\":[]}");
        pw.flush(); return;
    }
    searchNumber = searchNumber.trim();

    Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
    try {
        con = DBConnection.getConnection();
        ps = con.prepareStatement(
            "SELECT ACCOUNT_CODE, Fn_Get_Account_name(ACCOUNT_CODE) AS ACCOUNT_NAME " +
            "FROM account.account " +
            "WHERE ACCOUNT_CODE LIKE ? " +
            "AND ROWNUM <= 20 " +
            "ORDER BY ACCOUNT_CODE"
        );
        ps.setString(1, "%" + searchNumber + "%");
        rs = ps.executeQuery();

        StringBuilder sb = new StringBuilder("{\"accounts\":[");
        boolean first = true;
        while (rs.next()) {
            String code = rs.getString("ACCOUNT_CODE");
            String name = rs.getString("ACCOUNT_NAME");
            if (code == null) code = ""; else code = code.trim();
            if (name == null) name = ""; else name = name.trim()
                .replace("\\","\\\\").replace("\"","\\\"")
                .replace("\r","").replace("\n","");
            if (!first) sb.append(",");
            sb.append("{\"code\":\"").append(code)
              .append("\",\"name\":\"").append(name).append("\"}");
            first = false;
        }
        sb.append("]}");
        pw.print(sb.toString());

    } catch (Exception e) {
        String msg = e.getMessage(); if(msg==null)msg="Unknown error";
        msg = msg.replace("\"","'").replace("\r","").replace("\n"," ");
        pw.print("{\"error\":\""+msg+"\",\"accounts\":[]}");
    } finally {
        try{if(rs!=null)rs.close();}catch(Exception e){}
        try{if(ps!=null)ps.close();}catch(Exception e){}
        try{if(con!=null)con.close();}catch(Exception e){}
    }
    pw.flush();
%>
