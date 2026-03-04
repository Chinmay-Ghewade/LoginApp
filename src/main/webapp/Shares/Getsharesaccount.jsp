<%@ page import="java.sql.*, java.io.PrintWriter, db.DBConnection" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%
    response.reset();
    response.setContentType("application/json; charset=UTF-8");
    PrintWriter pw = response.getWriter();

    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        pw.print("{\"error\":\"Session expired\"}");
        pw.flush(); return;
    }

    String ac = request.getParameter("accountCode");
    if (ac == null || ac.trim().isEmpty()) {
        pw.print("{\"error\":\"Account code required\"}");
        pw.flush(); return;
    }
    ac = ac.trim();

    Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
    try {
        con = DBConnection.getConnection();
        ps = con.prepareStatement(
            "SELECT " +
            "  LEDGERBALANCE, " +
            "  AVAILABLEBALANCE, " +
            "  Fn_Get_Account_name(?)                          AS ACCOUNT_NAME, " +
            "  FN_GET_AC_GL(?)                                 AS GL_CODE, " +
            "  Fn_Get_Account_name(FN_GET_AC_GL(?))            AS GL_NAME, " +
            "  FN_GET_CUSTOMER_ID(?)                           AS CUST_ID, " +
            "  Fn_Get_Cust_aadhar(FN_GET_CUSTOMER_ID(?))       AS AADHAR, " +
            "  Fn_Get_Cust_PAN(FN_GET_CUSTOMER_ID(?))          AS PAN, " +
            "  Fn_Get_Cust_ZIPNO(FN_GET_CUSTOMER_ID(?))        AS ZIP " +
            "FROM account.account " +
            "WHERE ACCOUNT_CODE = ?"
        );
        // 8 bind params: ac for each function arg + final WHERE
        for (int i = 1; i <= 8; i++) ps.setString(i, ac);
        rs = ps.executeQuery();

        if (rs.next()) {
            String n  = rs.getString("ACCOUNT_NAME");
            String gc = rs.getString("GL_CODE");
            String gn = rs.getString("GL_NAME");
            String ci = rs.getString("CUST_ID");
            String ad = rs.getString("AADHAR");
            String pn = rs.getString("PAN");
            String zp = rs.getString("ZIP");
            java.math.BigDecimal lbD = rs.getBigDecimal("LEDGERBALANCE");
            java.math.BigDecimal abD = rs.getBigDecimal("AVAILABLEBALANCE");

            if (n  == null) n  = ""; else n  = n.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
            if (gc == null) gc = ""; else { gc = gc.trim(); if("00000000000000".equals(gc)) gc=""; }
            if (gn == null) gn = ""; else gn = gn.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
            if (ci == null) ci = ""; else ci = ci.trim();
            if (ad == null) ad = ""; else { ad = ad.trim(); if(".".equals(ad)) ad=""; }
            if (pn == null) pn = ""; else { pn = pn.trim(); if("0".equals(pn)) pn=""; }
            if (zp == null) zp = ""; else { zp = zp.trim(); if(".".equals(zp)) zp=""; }
            String lb = (lbD != null) ? lbD.toPlainString() : "0";
            String ab = (abD != null) ? abD.toPlainString() : "0";

            pw.print("{\"ok\":true," +
                "\"acName\":\"" + n  + "\"," +
                "\"lb\":\""     + lb + "\"," +
                "\"ab\":\""     + ab + "\"," +
                "\"gc\":\""     + gc + "\"," +
                "\"gn\":\""     + gn + "\"," +
                "\"ci\":\""     + ci + "\"," +
                "\"ad\":\""     + ad + "\"," +
                "\"pn\":\""     + pn + "\"," +
                "\"zp\":\""     + zp + "\"}"
            );
        } else {
            pw.print("{\"error\":\"Account not found\"}");
        }

    } catch (Exception e) {
        String msg = e.getMessage(); if(msg==null)msg="Unknown error";
        msg = msg.replace("\"","'").replace("\r","").replace("\n"," ");
        pw.print("{\"error\":\""+msg+"\"}");
    } finally {
        try{if(rs!=null)rs.close();}catch(Exception e){}
        try{if(ps!=null)ps.close();}catch(Exception e){}
        try{if(con!=null)con.close();}catch(Exception e){}
    }
    pw.flush();
%>
