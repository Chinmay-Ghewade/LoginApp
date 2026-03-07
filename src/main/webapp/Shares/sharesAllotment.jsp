<%@ page trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.io.PrintWriter, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String action = request.getParameter("action");

    if ("search".equals(action) || "lookup".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String term = request.getParameter("term");
        if (term == null) term = "";
        term = term.trim();
        String likeVal = term.isEmpty() ? "%" : "%" + term;
        int maxRows = term.isEmpty() ? 50 : 30;
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps = con.prepareStatement("SELECT ACCOUNT_CODE, NAME FROM ACCOUNT.ACCOUNT WHERE ACCOUNT_CODE LIKE ? AND SUBSTR(ACCOUNT_CODE, 5, 3) = '901' AND ROWNUM <= " + maxRows + " ORDER BY ACCOUNT_CODE");
            ps.setString(1, likeVal); rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("{\"accounts\":["); boolean first = true;
            while (rs.next()) {
                String c = rs.getString("ACCOUNT_CODE"); if (c == null) c = ""; else c = c.trim();
                String a = rs.getString("NAME"); if (a == null) a = ""; else a = a.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                if (!first) sb.append(",");
                sb.append("{\"code\":\"").append(c).append("\",\"name\":\"").append(a).append("\"}"); first = false;
            }
            sb.append("]}"); pw.print(sb.toString());
        } catch (Exception e) { String msg = e.getMessage(); if (msg==null) msg="DB error"; msg=msg.replace("\"","'").replace("\r","").replace("\n"," "); pw.print("{\"error\":\""+msg+"\",\"accounts\":[]}"); }
        finally { try{if(rs!=null)rs.close();}catch(Exception ex){} try{if(ps!=null)ps.close();}catch(Exception ex){} try{if(con!=null)con.close();}catch(Exception ex){} }
        pw.flush(); return;
    }

    if ("searchtr".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String term = request.getParameter("term");
        if (term == null) term = "";
        term = term.trim();
        String likeVal = term.isEmpty() ? "%" : "%" + term;
        int maxRows = term.isEmpty() ? 50 : 30;
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps = con.prepareStatement("SELECT ACCOUNT_CODE, NAME FROM ACCOUNT.ACCOUNT WHERE ACCOUNT_CODE LIKE ? AND SUBSTR(ACCOUNT_CODE, 5, 3) = '901' AND ROWNUM <= " + maxRows + " ORDER BY ACCOUNT_CODE");
            ps.setString(1, likeVal); rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("{\"accounts\":["); boolean first = true;
            while (rs.next()) {
                String c = rs.getString("ACCOUNT_CODE"); if (c == null) c = ""; else c = c.trim();
                String a = rs.getString("NAME"); if (a == null) a = ""; else a = a.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                if (!first) sb.append(",");
                sb.append("{\"code\":\"").append(c).append("\",\"name\":\"").append(a).append("\"}"); first = false;
            }
            sb.append("]}"); pw.print(sb.toString());
        } catch (Exception e) { String msg = e.getMessage(); if (msg==null) msg="DB error"; msg=msg.replace("\"","'").replace("\r","").replace("\n"," "); pw.print("{\"error\":\""+msg+"\",\"accounts\":[]}"); }
        finally { try{if(rs!=null)rs.close();}catch(Exception ex){} try{if(ps!=null)ps.close();}catch(Exception ex){} try{if(con!=null)con.close();}catch(Exception ex){} }
        pw.flush(); return;
    }

    if ("get".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String ac = request.getParameter("code");
        if (ac == null || ac.trim().isEmpty()) { pw.print("{\"error\":\"Code required\"}"); pw.flush(); return; }
        ac = ac.trim();
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps = con.prepareStatement("SELECT A.ACCOUNT_CODE, A.NAME, A.CUSTOMER_ID, B.LEDGERBALANCE, B.AVAILABLEBALANCE, FN_GET_AC_GL(A.ACCOUNT_CODE) AS GL_CODE, Fn_Get_gl_name(FN_GET_AC_GL(A.ACCOUNT_CODE)) AS GL_NAME FROM ACCOUNT.ACCOUNT A LEFT JOIN BALANCE.ACCOUNT B ON A.ACCOUNT_CODE = B.ACCOUNT_CODE WHERE A.ACCOUNT_CODE = ? AND SUBSTR(A.ACCOUNT_CODE, 5, 3) = '901'");
            ps.setString(1, ac); rs = ps.executeQuery();
            if (rs.next()) {
                String n = rs.getString("NAME"); if (n==null) n=""; else n=n.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                String ci = rs.getString("CUSTOMER_ID"); if (ci==null) ci=""; else ci=ci.trim();
                String gc = rs.getString("GL_CODE"); if (gc==null) gc=""; else { gc=gc.trim(); if ("00000000000000".equals(gc)) gc=""; }
                String gn = rs.getString("GL_NAME"); if (gn==null) gn=""; else gn=gn.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n",""); if (".".equals(gn)) gn="";
                java.math.BigDecimal lbD = rs.getBigDecimal("LEDGERBALANCE"); java.math.BigDecimal abD = rs.getBigDecimal("AVAILABLEBALANCE");
                String lb = (lbD!=null)?lbD.toPlainString():"0"; String ab = (abD!=null)?abD.toPlainString():"0";
                pw.print("{\"ok\":true,\"n\":\""+n+"\",\"ci\":\""+ci+"\",\"gc\":\""+gc+"\",\"gn\":\""+gn+"\",\"lb\":\""+lb+"\",\"ab\":\""+ab+"\"}");
            } else { pw.print("{\"error\":\"Account not found\"}"); }
        } catch (Exception e) { String msg = e.getMessage(); if (msg==null) msg="DB error"; msg=msg.replace("\"","'").replace("\r","").replace("\n"," "); pw.print("{\"error\":\""+msg+"\"}"); }
        finally { try{if(rs!=null)rs.close();}catch(Exception ex){} try{if(ps!=null)ps.close();}catch(Exception ex){} try{if(con!=null)con.close();}catch(Exception ex){} }
        pw.flush(); return;
    }

    if ("gettr".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String ac = request.getParameter("code");
        if (ac == null || ac.trim().isEmpty()) { pw.print("{\"error\":\"Code required\"}"); pw.flush(); return; }
        ac = ac.trim();
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps = con.prepareStatement("SELECT ACCOUNT_CODE, NAME FROM ACCOUNT.ACCOUNT WHERE ACCOUNT_CODE = ? AND SUBSTR(ACCOUNT_CODE, 5, 3) = '901'");
            ps.setString(1, ac); rs = ps.executeQuery();
            if (rs.next()) {
                String n = rs.getString("NAME"); if (n==null) n=""; else n=n.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                pw.print("{\"ok\":true,\"n\":\""+n+"\"}");
            } else { pw.print("{\"error\":\"Not a valid 901 shareholder account\"}"); }
        } catch (Exception e) { String msg = e.getMessage(); if (msg==null) msg="DB error"; msg=msg.replace("\"","'").replace("\r","").replace("\n"," "); pw.print("{\"error\":\""+msg+"\"}"); }
        finally { try{if(rs!=null)rs.close();}catch(Exception ex){} try{if(ps!=null)ps.close();}catch(Exception ex){} try{if(con!=null)con.close();}catch(Exception ex){} }
        pw.flush(); return;
    }

    if ("save".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();

        // ── Read POST parameters ──────────────────────────────────────
        String mainAccCode  = request.getParameter("accountCode");   // e.g. 0011901051055
        String meetDateStr  = request.getParameter("meetDate");       // e.g. 2026-03-07
        String noSharesStr  = request.getParameter("noShares");       // e.g. 10
        String modeOfPay    = request.getParameter("mode");           // Cash / Transfer
        String trCodesJson  = request.getParameter("trCodes");        // JSON array of transfer codes & amounts

        // Basic validation
        if (mainAccCode==null||mainAccCode.trim().isEmpty()) { pw.print("{\"error\":\"Account code required\"}"); pw.flush(); return; }
        if (meetDateStr==null||meetDateStr.trim().isEmpty()) { pw.print("{\"error\":\"Meeting date required\"}"); pw.flush(); return; }
        if (noSharesStr==null||noSharesStr.trim().isEmpty()) { pw.print("{\"error\":\"No. of shares required\"}"); pw.flush(); return; }

        mainAccCode = mainAccCode.trim();
        int noShares = 0;
        try { noShares = Integer.parseInt(noSharesStr.trim()); } catch(Exception ex) { pw.print("{\"error\":\"Invalid shares count\"}"); pw.flush(); return; }
        if (noShares < 1) { pw.print("{\"error\":\"Minimum 1 share required\"}"); pw.flush(); return; }

        // Parse meeting date
        java.sql.Date issueDate = null;
        try { issueDate = java.sql.Date.valueOf(meetDateStr.trim()); } catch(Exception ex) { pw.print("{\"error\":\"Invalid meeting date\"}"); pw.flush(); return; }

        boolean isTransfer = "Transfer".equals(modeOfPay);

        // Parse transfer entries JSON: [{"code":"xxx","amount":1000},...]
        java.util.List<String[]> trList = new java.util.ArrayList<String[]>();
        if (isTransfer && trCodesJson != null && !trCodesJson.trim().isEmpty()) {
            try {
                String json = trCodesJson.trim();
                // Remove [ and ]
                json = json.substring(1, json.length()-1).trim();
                if (!json.isEmpty()) {
                    // Split by },{
                    String[] entries = json.split("\\},\\{");
                    for (String entry : entries) {
                        entry = entry.replace("{","").replace("}","");
                        // Extract code and amount
                        String code = ""; String amt = "0";
                        String[] parts = entry.split(",");
                        for (String part : parts) {
                            part = part.trim();
                            if (part.startsWith("\"code\"")) {
                                code = part.split(":")[1].trim().replace("\"","");
                            } else if (part.startsWith("\"amount\"")) {
                                amt = part.split(":")[1].trim().replace("\"","");
                            }
                        }
                        if (!code.isEmpty()) trList.add(new String[]{code, amt});
                    }
                }
            } catch(Exception ex) { pw.print("{\"error\":\"Invalid transfer data\"}"); pw.flush(); return; }
        }

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false); // Transaction start

            // ── Step 1: Get MAX values ────────────────────────────────
            long maxCertNo = 0, maxToNo = 0;
            ps = con.prepareStatement("SELECT NVL(MAX(CERTIFICATE_NUMBER),0) AS MAX_CERT, NVL(MAX(TO_NUMBER),0) AS MAX_TO FROM SHARES.CERTIFICATE_MASTER");
            rs = ps.executeQuery();
            if (rs.next()) { maxCertNo = rs.getLong("MAX_CERT"); maxToNo = rs.getLong("MAX_TO"); }
            rs.close(); ps.close();

            // ── Step 2: Get MEMBER_NUMBER — last 5 digits of account code ──
            // Form account:  0011901051139 → last 5 = 51139 = MEMBER_NUMBER
            // DB account:    00029020051139 → built as "0002902" + "0051139" (7 digits)
            String last5Main = mainAccCode.length() >= 5 ? mainAccCode.substring(mainAccCode.length()-5) : mainAccCode;
            long mainMemberNo = 0;
            try { mainMemberNo = Long.parseLong(last5Main); } catch(Exception ex) { mainMemberNo = maxCertNo + 1; }
            String mainDbAccNo = "0002902" + String.format("%07d", mainMemberNo);

            // ── Step 3: Insert main account (Cash mode only) ─────────
            long certNo = maxCertNo + 1; // first cert no (used for response)

            if (!isTransfer) {
                // CASH MODE — Ramesh is buying shares for himself
                long fromNo   = maxToNo + 1;
                long toNo     = fromNo + noShares - 1;
                long totalAmt = (long) noShares * 100;

                ps = con.prepareStatement(
                    "INSERT INTO SHARES.CERTIFICATE_MASTER " +
                    "(MEMBER_TYPE, MEMBER_NUMBER, CERTIFICATE_NUMBER, ISSUE_DATE, FACE_VALUE, " +
                    "NUMBEROF_SHARES, FROM_NUMBER, TO_NUMBER, TOTAL_SHARESAMOUNT, ACCOUNT_NUMBER, PRINT_STATUS) " +
                    "VALUES ('A', ?, ?, ?, 100, ?, ?, ?, ?, ?, 'N')"
                );
                ps.setLong  (1, mainMemberNo);
                ps.setLong  (2, certNo);
                ps.setDate  (3, issueDate);
                ps.setInt   (4, noShares);
                ps.setLong  (5, fromNo);
                ps.setLong  (6, toNo);
                ps.setLong  (7, totalAmt);
                ps.setString(8, mainDbAccNo);
                ps.executeUpdate();
                ps.close();

                maxToNo     = toNo;
            }
            // TRANSFER MODE — Ramesh is distributing, NO insert for Ramesh

            // ── Step 4: Insert transfer accounts (Suresh, Mahesh...) ─
            if (isTransfer && !trList.isEmpty()) {
                for (String[] tr : trList) {
                    String trAccCode = tr[0];
                    int trAmt = 0;
                    try { trAmt = (int) Double.parseDouble(tr[1]); } catch(Exception ex) {}
                    int trShares = trAmt / 100; // face value = 100
                    if (trShares < 1) continue;

                    // MEMBER_NUMBER = last 5 digits of transfer account code
                    String last5Tr = trAccCode.length() >= 5 ? trAccCode.substring(trAccCode.length()-5) : trAccCode;
                    long trMemberNo = 0;
                    try { trMemberNo = Long.parseLong(last5Tr); } catch(Exception ex) { trMemberNo = maxCertNo + 1; }
                    String trDbAccNo = "0002902" + String.format("%07d", trMemberNo);

                    // New cert no and from/to for this transfer account
                    long trCertNo  = maxCertNo + 1;
                    maxCertNo++;
                    long trFromNo  = maxToNo + 1;
                    long trToNo    = trFromNo + trShares - 1;
                    maxToNo = trToNo;

                    // First transfer entry cert no = certNo for popup display
                    // (certNo already set to maxCertNo+1 before loop)

                    ps = con.prepareStatement(
                        "INSERT INTO SHARES.CERTIFICATE_MASTER " +
                        "(MEMBER_TYPE, MEMBER_NUMBER, CERTIFICATE_NUMBER, ISSUE_DATE, FACE_VALUE, " +
                        "NUMBEROF_SHARES, FROM_NUMBER, TO_NUMBER, TOTAL_SHARESAMOUNT, ACCOUNT_NUMBER, PRINT_STATUS) " +
                        "VALUES ('A', ?, ?, ?, 100, ?, ?, ?, ?, ?, 'N')"
                    );
                    ps.setLong  (1, trMemberNo);
                    ps.setLong  (2, trCertNo);
                    ps.setDate  (3, issueDate);
                    ps.setInt   (4, trShares);
                    ps.setLong  (5, trFromNo);
                    ps.setLong  (6, trToNo);
                    ps.setLong  (7, (long)trShares * 100);
                    ps.setString(8, trDbAccNo);
                    ps.executeUpdate();
                    ps.close();
                }
            }

            con.commit(); // ── All inserts done — commit!
            pw.print("{\"ok\":true,\"certNo\":"+certNo+",\"msg\":\"Saved successfully! Certificate No: "+certNo+"\"}");

        } catch (Exception e) {
            try { if(con!=null) con.rollback(); } catch(Exception ex) {}
            String msg = e.getMessage(); if(msg==null) msg="DB error";
            msg = msg.replace("\"","'").replace("\r","").replace("\n"," ");
            pw.print("{\"error\":\""+msg+"\"}");
        } finally {
            try{if(rs!=null)rs.close();}catch(Exception ex){}
            try{if(ps!=null)ps.close();}catch(Exception ex){}
            try{if(con!=null)con.close();}catch(Exception ex){}
        }
        pw.flush(); return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shares Allotment</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', Tahoma, Arial, sans-serif; background: #eaeaf5; min-height: 100vh; padding: 24px 28px 44px; color: #1a1a6e; }
        .page-title { text-align: center; font-size: 1.45rem; font-weight: 800; color: #1a1a6e; margin-bottom: 20px; }

        .box { background: #fff; border: 1.5px solid #c0c0e0; border-radius: 12px; position: relative; margin-bottom: 20px; padding: 22px 16px 18px; }
        .box-legend { position: absolute; top: -11px; left: 14px; background: #fff; padding: 0 8px; font-size: .88rem; font-weight: 700; color: #1a1a6e; }
        .modules-row { display: grid; grid-template-columns: 22% 40% 38%; align-items: start; }
        .module { padding: 8px 16px 12px; display: flex; flex-direction: column; gap: 10px; border-right: 1px solid #dcdcf0; }
        .module:last-child { border-right: none; }
        .mod-title { font-size: .76rem; font-weight: 800; color: #1a1a6e; letter-spacing: .05em; text-transform: uppercase; padding-bottom: 7px; border-bottom: 1.5px solid #dcdcf0; }

        .fg-row  { display: grid; grid-template-columns: 1fr 1fr;     gap: 8px; align-items: end; }
        .fg-row3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; align-items: end; }
        .fg { display: flex; flex-direction: column; gap: 4px; width: 100%; }
        .fg > label { font-size: .78rem; font-weight: 600; color: #1a1a6e; }

        input[type=text], input[type=number], input[type=date] {
            height: 34px; padding: 0 10px; border: 1px solid #c0c0e0; border-radius: 6px;
            font-size: .84rem; font-family: inherit; color: #1a1a6e; background: #fff;
            outline: none; width: 100%; transition: border-color .15s, box-shadow .15s;
        }
        input:focus { border-color: #5050b0; box-shadow: 0 0 0 2px rgba(80,80,176,.10); }
        input[readonly], input[disabled] { background: #ebebf5; color: #6060a0; border-color: #d0d0e8; cursor: default; }
        input::placeholder { color: #a0a0c8; font-size: .82rem; }

        .hint-xs { color: #8080b0; font-size: .70rem; margin-top: 1px; }
        .ib { display: flex; gap: 5px; align-items: center; width: 100%; }
        .ib input { flex: 1; min-width: 0; }
        .sw { position: relative; flex: 1; min-width: 0; }
        .sw input { width: 100%; }
        .sdrop { position: absolute; top: calc(100% + 2px); left: 0; right: 0; background: #fff; border: 1px solid #c0c0e0; border-radius: 0 0 8px 8px; max-height: 200px; overflow-y: auto; z-index: 2000; display: none; box-shadow: 0 6px 20px rgba(60,60,160,.14); }
        .sdrop.on { display: block; }
        .sr-item { padding: 8px 11px; cursor: pointer; border-bottom: 1px solid #f0f0f8; }
        .sr-item:last-child { border: none; }
        .sr-item:hover { background: #ebebff; }
        .sr-code { font-weight: 700; color: #1a1a6e; font-size: .78rem; margin-bottom: 2px; }
        .sr-name { color: #5050a0; font-size: .75rem; }
        .sr-hint { padding: 8px 11px; color: #9898c0; font-size: .76rem; font-style: italic; }
        .hl { background: #ffe066; border-radius: 2px; padding: 0 1px; }

        .btn-dot { height: 34px; min-width: 38px; padding: 0 8px; background: #3535a0; color: #fff; border: none; border-radius: 6px; font-size: .88rem; font-weight: 700; cursor: pointer; flex-shrink: 0; transition: background .12s; }
        .btn-dot:hover { background: #252588; }
        .btn-dot:disabled { background: #a0a0c8; cursor: default; }
        .btn-add { height: 34px; padding: 0 16px; background: #3535a0; color: #fff; border: none; border-radius: 6px; font-size: .84rem; font-weight: 700; font-family: inherit; cursor: pointer; white-space: nowrap; flex-shrink: 0; transition: background .12s; }
        .btn-add:hover { background: #252588; }

        .rg { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
        .rg label { display: flex; align-items: center; gap: 7px; padding: 0 16px; height: 34px; border: 1.5px solid #c0c0e0; border-radius: 6px; font-size: .84rem; font-weight: 500; color: #1a1a6e; cursor: pointer; background: #fff; user-select: none; transition: border-color .15s, background .15s; }
        .rg label.on { border-color: #3535a0; background: #ebebff; font-weight: 700; }
        .rg input[type=radio] { width: 15px; height: 15px; accent-color: #3535a0; cursor: pointer; }

        .spin { display: none; width: 14px; height: 14px; border: 2px solid #d0d0e8; border-top-color: #3535a0; border-radius: 50%; animation: sp .65s linear infinite; flex-shrink: 0; margin-left: 2px; }
        @keyframes sp { to { transform: rotate(360deg); } }

        .tr-table-wrap { display: none; border: 1.5px solid #4a4aaa; border-radius: 0; overflow: hidden; margin: 20px 0 0; }
        .tr-table-wrap.show { display: block; }
        .tr-table { width: 100%; border-collapse: collapse; font-size: .82rem; }
        .tr-table thead tr { background: #3a3a9a; color: #fff; }
        .tr-table thead th { padding: 11px 14px; text-align: center; font-weight: 700; font-size: .80rem; letter-spacing: .03em; text-transform: uppercase; border-right: 1px solid #5555b0; }
        .tr-table thead th:last-child { border-right: none; }
        .tr-table tbody tr { border-bottom: 1.5px solid #dcdcf0; background: #fff; }
        .tr-table tbody tr:nth-child(even) { background: #f8f8fd; }
        .tr-table tbody tr:hover { background: #efeffc; }
        .tr-table tbody td { padding: 10px 14px; color: #1a1a6e; vertical-align: middle; border-right: 1px solid #eeeef8; }
        .tr-table tbody td:last-child { border-right: none; }
        .tr-table tfoot tr { background: #f0f0fa; border-top: 2px solid #4a4aaa; }
        .tr-table tfoot td { padding: 10px 14px; font-weight: 700; color: #1a1a6e; border-right: 1px solid #eeeef8; }
        .tr-table tfoot td:last-child { border-right: none; }

        .pay-table-wrap { display: none; margin-top: 10px; border: 1.5px solid #4a4aaa; border-radius: 0; overflow: hidden; }
        .pay-table-wrap.show { display: block; }
        .pay-table { width: 100%; border-collapse: collapse; font-size: .82rem; }
        .pay-table thead tr { background: #3a3a9a; color: #fff; }
        .pay-table thead th { padding: 11px 14px; text-align: center; font-weight: 700; font-size: .80rem; letter-spacing: .03em; text-transform: uppercase; border-right: 1px solid #5555b0; }
        .pay-table thead th:last-child { border-right: none; }
        .pay-table tbody tr { border-bottom: 1.5px solid #dcdcf0; background: #fff; }
        .pay-table tbody tr:nth-child(even) { background: #f8f8fd; }
        .pay-table tbody tr:hover { background: #efeffc; }
        .pay-table tbody td { padding: 10px 14px; color: #1a1a6e; border-right: 1px solid #eeeef8; }
        .pay-table tbody td:last-child { border-right: none; }
        .pay-table tfoot tr { background: #f0f0fa; border-top: 2px solid #4a4aaa; }
        .pay-table tfoot td { padding: 10px 14px; font-weight: 700; color: #1a1a6e; border-right: 1px solid #eeeef8; }
        .pay-table tfoot td:last-child { border-right: none; }
        .btn-remove { height: 26px; padding: 0 10px; background: #fff; color: #b03030; border: 1px solid #e0a0a0; border-radius: 4px; font-size: .75rem; font-weight: 700; cursor: pointer; transition: background .12s; }
        .btn-remove:hover { background: #fff0f0; }

        #acDetails { display: none; margin-top: 16px; }
        #acDetails.show { display: block; }
        .ac-info-box { background: #fff; border: 1.5px solid #c0c0e0; border-radius: 12px; padding: 22px 20px 20px; position: relative; }
        .ac-info-title { position: absolute; top: -11px; left: 14px; background: #fff; padding: 0 8px; font-size: .9rem; font-weight: 700; color: #1a1a6e; }
        .ac-info-grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 12px 16px; margin-top: 4px; }
        .ac-fg { display: flex; flex-direction: column; gap: 4px; }
        .ac-fg label { font-size: .77rem; font-weight: 600; color: #1a1a6e; }
        .ac-fg input { height: 34px; padding: 0 10px; background: #ebebf5; border: 1px solid #d0d0e8; border-radius: 5px; font-size: .84rem; color: #1a1a6e; font-family: inherit; width: 100%; outline: none; }
        .bal-pos { color: #1a7a3a !important; font-weight: 700 !important; }
        .bal-neg { color: #b03030 !important; font-weight: 700 !important; }
        .amt-red { color: #b03030 !important; font-weight: 700 !important; }

        .msg-bar { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
        .msg-bar span { font-size: .82rem; font-weight: 700; color: #1a1a6e; white-space: nowrap; }
        #msgBox { flex: 1; height: 34px; padding: 0 12px; border-radius: 6px; border: 1px solid #c0c0e0; background: #fff; color: #1a1a6e; font-size: .84rem; font-weight: 600; font-family: inherit; outline: none; }

        .act-bar { display: flex; justify-content: center; gap: 14px; flex-wrap: wrap; margin-top: 4px; }
        .btn-primary { height: 40px; padding: 0 48px; background: #1a1a6e; color: #fff; border: none; border-radius: 8px; font-size: .9rem; font-weight: 700; font-family: inherit; cursor: pointer; transition: background .12s; }
        .btn-primary:hover { background: #12126e; }
        .btn-primary:disabled { background: #b0b0d0; cursor: default; }
        .btn-danger { height: 40px; padding: 0 28px; background: #fff; color: #cc2222; border: 1.5px solid #cc2222; border-radius: 8px; font-size: .9rem; font-weight: 700; font-family: inherit; cursor: pointer; transition: background .12s; }
        .btn-danger:hover { background: #fff5f5; }

        /* ── Success Popup ── */
        .success-overlay { display: none; position: fixed; inset: 0; background: rgba(80,80,120,.35); z-index: 99999; align-items: center; justify-content: center; }
        .success-overlay.open { display: flex; }
        .success-modal { background: #fff; border-radius: 18px; box-shadow: 0 8px 40px rgba(30,30,100,.18); width: 420px; max-width: 92vw; padding: 44px 40px 32px; display: flex; flex-direction: column; align-items: center; gap: 14px; }
        .success-tick { font-size: 3.2rem; color: #22aa55; font-weight: 900; line-height: 1; }
        .success-title { font-size: 1.1rem; font-weight: 700; color: #111; text-align: center; }
        .success-info { font-size: .9rem; color: #222; font-weight: 500; text-align: center; line-height: 2.2; }
        .btn-ok { height: 42px; padding: 0 64px; background: #22aa55; color: #fff; border: none; border-radius: 8px; font-size: .95rem; font-weight: 700; font-family: inherit; cursor: pointer; margin-top: 4px; transition: background .12s; }
        .btn-ok:hover { background: #1a8f44; } { display: none; position: fixed; inset: 0; background: rgba(20,20,60,.5); z-index: 9999; align-items: flex-start; justify-content: center; padding-top: 60px; }
        .lk-overlay.open { display: flex; }
        .lk-modal { background: #fff; border-radius: 12px; box-shadow: 0 8px 40px rgba(30,30,100,.25); width: 860px; max-width: 96vw; max-height: 80vh; display: flex; flex-direction: column; overflow: hidden; }
        .lk-head { display: flex; align-items: center; gap: 12px; padding: 14px 18px; border-bottom: 1px solid #e8e8f4; flex-shrink: 0; }
        .lk-head-title { font-size: 1.05rem; font-weight: 700; color: #1a1a6e; }
        .lk-head-badge { background: #5050b0; color: #fff; font-size: .72rem; font-weight: 700; padding: 3px 12px; border-radius: 20px; }
        .lk-head-close { margin-left: auto; width: 32px; height: 32px; background: #d03030; color: #fff; border: none; border-radius: 7px; font-size: 1rem; font-weight: 900; cursor: pointer; line-height: 32px; text-align: center; }
        .lk-head-close:hover { background: #b02020; }
        .lk-search-wrap { padding: 10px 16px; border-bottom: 1px solid #f0f0f8; flex-shrink: 0; }
        .lk-search-input { width: 100%; height: 36px; padding: 0 14px 0 38px; border: 1px solid #c0c0e0; border-radius: 20px; font-size: .88rem; font-family: inherit; color: #1a1a6e; background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='15' height='15' fill='%235050b0' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11'/%3E%3C/svg%3E") no-repeat 12px center; outline: none; }
        .lk-search-input:focus { border-color: #5050b0; }
        .lk-search-input::placeholder { color: #a0a0c8; }
        .lk-body { flex: 1; overflow-y: auto; }
        .lk-table { width: 100%; border-collapse: collapse; }
        .lk-table thead tr { background: #3535a0; color: #fff; position: sticky; top: 0; z-index: 1; }
        .lk-table thead th { padding: 10px 14px; text-align: center; font-size: .83rem; font-weight: 700; }
        .lk-table tbody tr { border-bottom: 1px solid #f0f0f8; cursor: pointer; transition: background .1s; }
        .lk-table tbody tr:hover { background: #ebebff; }
        .lk-table tbody td { padding: 9px 14px; font-size: .83rem; color: #1a1a6e; }
        .lk-table tbody td:first-child { font-weight: 700; }
        .lk-msg { text-align: center; padding: 28px; color: #9898c0; font-style: italic; font-size: .88rem; }
        .lk-err { text-align: center; padding: 16px; color: #b03030; font-size: .85rem; }
        .lk-hl  { background: #ffe066; border-radius: 2px; padding: 0 1px; }
        .lk-status { padding: 6px 16px; font-size: .74rem; color: #7878a8; border-top: 1px solid #f0f0f8; flex-shrink: 0; }

        .lk-overlay { display: none; position: fixed; inset: 0; background: rgba(20,20,60,.5); z-index: 9999; align-items: flex-start; justify-content: center; padding-top: 60px; }
        .lk-overlay.open { display: flex; }
    </style>
</head>
<body>

    <div id="jsErrBar" style="display:none;background:#fdd;color:#900;padding:6px 14px;font-size:.82rem;font-weight:700;border-bottom:1px solid #e99;"></div>
    <div class="page-title">Shares Allotment</div>

    <div class="box">
        <span class="box-legend" style="background:#eaeaf5;">Transaction Details</span>
        <div class="modules-row">

            <!-- MODULE 1: Account Info -->
            <div class="module">
                <div class="mod-title">Account Info</div>
                <div class="fg">
                    <label>Account Code</label>
                    <div class="ib">
                        <div class="sw">
                            <input type="text" id="accountCode" placeholder="Type last 3+ digits…" autocomplete="off"
                                   oninput="onAcInput(this.value)"
                                   onkeydown="if(event.key==='Enter'){event.preventDefault();triggerFetch();}"/>
                            <div class="sdrop" id="dropMain"></div>
                        </div>
                        <button class="btn-dot" type="button" onclick="openLookup('main')">...</button>
                        <span class="spin" id="spinMain"></span>
                    </div>
                    <span class="hint-xs">Type last 3+ digits to search</span>
                </div>
                <div class="fg">
                    <label>Account Name</label>
                    <input type="text" id="accountName" readonly placeholder="—"/>
                </div>
            </div>

            <!-- MODULE 2: Payment Details -->
            <div class="module">
                <div class="mod-title">Payment Details</div>
                <div class="fg-row">
                    <div class="fg">
                        <label>Mode of Payment</label>
                        <div class="rg">
                            <label id="lblTransfer">
                                <input type="radio" name="mop" value="Transfer" id="modeTransfer" onchange="onModeChange()"/>
                                Transfer
                            </label>
                            <label id="lblCash" class="on">
                                <input type="radio" name="mop" value="Cash" id="modeCash" onchange="onModeChange()" checked/>
                                Cash
                            </label>
                        </div>
                    </div>
                    <div class="fg">
                        <label>Amount</label>
                        <div class="ib">
                            <input type="number" id="payAmt" placeholder="0.00" min="0"/>
                            <button class="btn-add" type="button" onclick="doAddPayment()">Add</button>
                        </div>
                    </div>
                </div>
                <div class="fg-row">
                    <div class="fg">
                        <label>Transfer A/c. Code</label>
                        <div class="ib">
                            <div class="sw">
                                <input type="text" id="trCode" disabled autocomplete="off"
                                       oninput="onTrInput(this.value)"
                                       onkeydown="if(event.key==='Enter'){event.preventDefault();triggerTrFetch();}"/>
                                <div class="sdrop" id="dropTr"></div>
                            </div>
                            <button class="btn-dot" id="btnTr" type="button" disabled onclick="openLookup('tr')">...</button>
                            <span class="spin" id="spinTr"></span>
                        </div>
                    </div>
                    <div class="fg">
                        <label>Transfer A/c. Name</label>
                        <input type="text" id="trName" readonly placeholder="—"/>
                    </div>
                </div>

                <!-- Cash payment table -->
                <div class="pay-table-wrap" id="payTableWrap">
                    <table class="pay-table">
                        <thead>
                            <tr><th>#</th><th>Mode</th><th>Amount</th><th>Particular</th><th></th></tr>
                        </thead>
                        <tbody id="payTbody"></tbody>
                        <tfoot>
                            <tr>
                                <td colspan="2">Total Paid</td>
                                <td id="payTotal">&#8377;0.00</td>
                                <td colspan="2"></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>

            <!-- MODULE 3: Transaction Details -->
            <div class="module">
                <div class="mod-title">Transaction Details</div>
                <div class="fg-row3">
                    <div class="fg">
                        <label>No. of Shares <span style="color:#b03030;">*</span></label>
                        <input type="number" id="noShares" placeholder="Min. 1" min="1" step="1" oninput="calcAmt()"/>
                    </div>
                    <div class="fg">
                        <label>Face Value</label>
                        <!-- CHANGED: Face value fixed to 100, readonly -->
                        <input type="number" id="faceVal" value="100" readonly/>
                    </div>
                    <div class="fg">
                        <label>Amount</label>
                        <input type="text" id="txnAmt" value="0.00" readonly class="amt-red"/>
                    </div>
                </div>
                <div class="fg-row">
                    <div class="fg">
                        <label>Meeting Date</label>
                        <input type="date" id="meetDate"/>
                    </div>
                    <div class="fg">
                        <label>Particular</label>
                        <input type="text" id="particular" value="By Cash"/>
                    </div>
                </div>
            </div>

        </div><!-- /.modules-row -->

        <!-- Transfer Entries Table -->
        <div class="tr-table-wrap" id="trTableWrap">
            <table class="tr-table">
                <thead>
                    <tr>
                        <th>Sr No</th>
                        <th>Transfer A/c. Code</th>
                        <th>Transfer A/c. Name</th>
                        <th>Amount (&#8377;)</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody id="trTbody"></tbody>
                <tfoot>
                    <tr>
                        <td colspan="3">Total Transferred</td>
                        <td id="trTotal">&#8377;0.00</td>
                        <td></td>
                    </tr>
                </tfoot>
            </table>
        </div>

        <!-- Account Details Panel -->
        <div id="acDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Account Information</div>
                <div class="ac-info-grid">
                    <div class="ac-fg"><label>Account Code</label><input type="text" id="dispAccCode" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>Account Name</label><input type="text" id="dispAccName" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>GL Account Code</label><input type="text" id="glCode" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>GL Account Name</label><input type="text" id="glName" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>Customer ID</label><input type="text" id="custId" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>Ledger Balance</label><input type="text" id="ledgerBal" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>Available Balance</label><input type="text" id="availBal" readonly placeholder=""/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="newLedgerBal" readonly placeholder=""/></div>
                </div>
            </div>
        </div>
    </div><!-- /.box -->

    <!-- Action Buttons -->
    <div class="act-bar">
        <button class="btn-primary" id="btnSave" type="button" disabled onclick="doSave()">Save</button>
        <button class="btn-danger" type="button" onclick="doCancel()">Clear</button>
    </div>

    <script>
        window.onerror = function(msg, src, line, col, err) {
            var d = document.getElementById('jsErrBar');
            if (d) { d.style.display='block'; d.textContent='JS ERROR line '+line+': '+msg; }
            return false;
        };

        var PAGE_URL   = '<%= request.getContextPath() + request.getServletPath() %>';
        var SEARCH_MIN = 3;
        var WAIT_MS    = 300;
        var _timer     = null;
        var _prev      = '';

        var _ledgerBal  = 0;
        var _payEntries = [];
        var _trEntries  = [];

        function onAcInput(v) {
            if (v !== _prev) { clearAcDetails(); _prev = v; }
            liveSearch(v, 'dropMain', 'main');
        }
        function onTrInput(v) { liveSearch(v, 'dropTr', 'tr'); }

        function liveSearch(val, dropId, target) {
            clearTimeout(_timer);
            var drop = document.getElementById(dropId);
            if (!val) { drop.classList.remove('on'); return; }
            if (val.length < SEARCH_MIN) {
                drop.innerHTML = '<div class="sr-hint">Type at least '+SEARCH_MIN+' digits\u2026</div>';
                drop.classList.add('on'); return;
            }
            drop.innerHTML = '<div class="sr-hint">Searching\u2026</div>';
            drop.classList.add('on');
            var sa = (target === 'tr') ? 'searchtr' : 'search';
            _timer = setTimeout(function(){ doSearch(val, dropId, target, sa); }, WAIT_MS);
        }

        function doSearch(term, dropId, target, sa) {
            var drop = document.getElementById(dropId);
            var xhr = new XMLHttpRequest();
            xhr.open('GET', PAGE_URL+'?action='+sa+'&term='+encodeURIComponent(term), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                if (xhr.status !== 200) { drop.innerHTML='<div class="sr-hint">HTTP Error '+xhr.status+'</div>'; return; }
                var d; try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { drop.innerHTML='<div class="sr-hint">Parse error</div>'; return; }
                if (d.error) { drop.innerHTML='<div class="sr-hint">'+xe(d.error)+'</div>'; return; }
                var list = d.accounts||[];
                if (!list.length) { drop.innerHTML='<div class="sr-hint">No accounts found</div>'; return; }
                var html='';
                for (var i=0;i<list.length;i++) {
                    var c=list[i].code||'', a=list[i].name||'';
                    html+='<div class="sr-item" onclick="pick(\''+xq(c)+'\',\''+xq(a)+'\',\''+target+'\')"><div class="sr-code">'+hlMatch(c,term)+'</div><div class="sr-name">'+xe(a)+'</div></div>';
                }
                drop.innerHTML = html;
            };
            xhr.send();
        }

        function hlMatch(text, search) {
            var idx=text.toLowerCase().indexOf(search.toLowerCase());
            if (idx===-1) return xe(text);
            return xe(text.substring(0,idx))+'<span class="hl">'+xe(text.substring(idx,idx+search.length))+'</span>'+xe(text.substring(idx+search.length));
        }

        function pick(code, name, target) {
            if (target==='tr') {
                document.getElementById('dropTr').classList.remove('on');
                document.getElementById('trCode').value = code;
                sv('trName', name);
                setMsg('Transfer account: '+name, false);
            } else {
                document.getElementById('dropMain').classList.remove('on');
                document.getElementById('accountCode').value = code;
                sv('accountName', name);
                _prev = code;
                fetchAc(code);
            }
        }

        function triggerFetch() {
            var code=document.getElementById('accountCode').value.trim();
            if (!code) { setMsg('Please enter an Account Code.', true); return; }
            document.getElementById('dropMain').classList.remove('on');
            fetchAc(code);
        }
        function triggerTrFetch() {
            var code=document.getElementById('trCode').value.trim();
            if (!code) { setMsg('Please enter a Transfer Account Code.', true); return; }
            document.getElementById('dropTr').classList.remove('on');
            fetchTr(code);
        }

        function fetchAc(code) {
            document.getElementById('spinMain').style.display='inline-block';
            setMsg('Fetching account details\u2026', false);
            var xhr=new XMLHttpRequest();
            xhr.open('GET', PAGE_URL+'?action=get&code='+encodeURIComponent(code), true);
            xhr.onreadystatechange=function() {
                if (xhr.readyState!==4) return;
                document.getElementById('spinMain').style.display='none';
                if (xhr.status!==200) { clearAcDetails(); setMsg('Server error: '+xhr.status, true); return; }
                var d; try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { clearAcDetails(); setMsg('Parse error: '+e.message, true); return; }
                if (d&&d.ok===true) {
                    _ledgerBal=parseFloat(d.lb)||0;
                    sv('accountName', d.n||''); sv('dispAccCode', code); sv('dispAccName', d.n||'');
                    sv('glCode', d.gc||''); sv('glName', d.gn||''); sv('custId', d.ci||'');
                    svBal('ledgerBal', d.lb); svBal('availBal', d.ab);
                    calcNewLedgerBal();
                    document.getElementById('acDetails').classList.add('show');
                    setMsg('Account loaded: '+(d.n||code), false);
                } else { clearAcDetails(); setMsg((d&&d.error)?d.error:'Account not found.', true); }
            };
            xhr.send();
        }

        function fetchTr(code) {
            document.getElementById('spinTr').style.display='inline-block';
            var xhr=new XMLHttpRequest();
            xhr.open('GET', PAGE_URL+'?action=gettr&code='+encodeURIComponent(code), true);
            xhr.onreadystatechange=function() {
                if (xhr.readyState!==4) return;
                document.getElementById('spinTr').style.display='none';
                var d; try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { setMsg('Parse error', true); return; }
                if (d&&d.ok===true) { sv('trName', d.n||''); setMsg('Transfer account: '+(d.n||code), false); }
                else { sv('trName',''); setMsg((d&&d.error)?d.error:'Not found.', true); }
            };
            xhr.send();
        }

        function onModeChange() {
            var isT=document.getElementById('modeTransfer').checked;
            document.getElementById('trCode').disabled=!isT;
            document.getElementById('btnTr').disabled=!isT;
            document.getElementById('particular').value=isT?'By Transfer':'By Cash';
            document.getElementById('lblTransfer').classList.toggle('on', isT);
            document.getElementById('lblCash').classList.toggle('on', !isT);
            if (!isT) {
                sv('trCode',''); sv('trName','');
                document.getElementById('dropTr').classList.remove('on');
                clearTrEntries();
            } else {
                clearPayments();
            }
        }

        function calcAmt() {
            var s = parseInt(document.getElementById('noShares').value) || 0;
            // CHANGED: Validate minimum 1 share
            if (s < 0) { s = 0; document.getElementById('noShares').value = ''; }
            var f = 100; // CHANGED: Face value always 100
            document.getElementById('txnAmt').value = (s * f).toFixed(2);
            calcNewLedgerBal();
            clearPayments();
            clearTrEntries();
        }

        function calcNewLedgerBal() {
            var txnAmt=parseFloat(document.getElementById('txnAmt').value)||0;
            svBal('newLedgerBal', (_ledgerBal+txnAmt).toString());
        }

        function doAddPayment() {
            var isTransfer = document.getElementById('modeTransfer').checked;
            var payAmt     = parseFloat(document.getElementById('payAmt').value);
            var txnAmt     = parseFloat(document.getElementById('txnAmt').value)||0;

            // CHANGED: Validate minimum 1 share before allowing payment
            var noShares = parseInt(document.getElementById('noShares').value) || 0;
            if (noShares < 1) { setMsg('Minimum 1 share is required.', true); return; }
            if (txnAmt <= 0)  { setMsg('Please enter No. of Shares first.', true); return; }
            if (isNaN(payAmt)||payAmt<=0) { setMsg('Please enter a valid amount.', true); return; }

            if (isTransfer) {
                var trCode = document.getElementById('trCode').value.trim();
                var trName = document.getElementById('trName').value.trim();

                if (!trCode) { setMsg('Please select a Transfer Account first.', true); return; }

                var distributorCode = document.getElementById('accountCode').value.trim();
                if (trCode === distributorCode) {
                    setMsg('Receiver account cannot be the same as the distributing account.', true); return;
                }

                for (var i=0;i<_trEntries.length;i++) {
                    if (_trEntries[i].code===trCode) {
                        setMsg('Account '+trCode+' already added. Remove it first to change.', true); return;
                    }
                }

                var already=_trEntries.reduce(function(s,e){return s+e.amount;},0);
                if (already+payAmt>txnAmt+0.001) {
                    setMsg('Total \u20b9'+(already+payAmt).toFixed(2)+' would exceed share value \u20b9'+txnAmt.toFixed(2)+'.', true); return;
                }

                _trEntries.push({code:trCode, name:trName, amount:payAmt});
                sv('trCode',''); sv('trName','');
                document.getElementById('payAmt').value='';
                document.getElementById('dropTr').classList.remove('on');

                renderTrTable();
                updateSaveBtn();
                document.getElementById('acDetails').classList.remove('show');
                setMsg('Added: '+(trName||trCode)+' \u20b9'+payAmt.toFixed(2)+'. Total: \u20b9'+(_trEntries.reduce(function(s,e){return s+e.amount;},0)).toFixed(2)+' / \u20b9'+txnAmt.toFixed(2), false);

            } else {
                var particular = document.getElementById('particular').value||'';
                if (_payEntries.length>0) { setMsg('Payment already added. Remove it first to change.', true); return; }
                if (payAmt>txnAmt)        { setMsg('Payment \u20b9'+payAmt.toFixed(2)+' exceeds share value \u20b9'+txnAmt.toFixed(2)+'.', true); return; }
                if (payAmt<txnAmt)        { setMsg('Payment \u20b9'+payAmt.toFixed(2)+' is less than share value \u20b9'+txnAmt.toFixed(2)+'. Full payment required.', true); return; }
                _payEntries.push({mode:'Cash', amount:payAmt, particular:particular});
                renderPayTable();
                updateSaveBtn();
                setMsg('Payment of \u20b9'+payAmt.toFixed(2)+' added successfully.', false);
            }
        }

        function renderTrTable() {
            var wrap=document.getElementById('trTableWrap'), tbody=document.getElementById('trTbody'), total=document.getElementById('trTotal');
            if (_trEntries.length===0) { wrap.classList.remove('show'); total.textContent='\u20b90.00'; return; }
            wrap.classList.add('show');
            var html='', sum=0;
            for (var i=0;i<_trEntries.length;i++) {
                var e=_trEntries[i]; sum+=e.amount;
                html+='<tr>'
                    +'<td>'+(i+1)+'</td>'
                    +'<td>'+xe(e.code)+'</td>'
                    +'<td>'+xe(e.name)+'</td>'
                    +'<td>\u20b9'+e.amount.toFixed(2)+'</td>'
                    +'<td><button class="btn-remove" onclick="removeTrEntry('+i+')">\u2715 Remove</button></td>'
                    +'</tr>';
            }
            tbody.innerHTML=html;
            total.textContent='\u20b9'+sum.toFixed(2);
        }

        function removeTrEntry(idx) {
            _trEntries.splice(idx,1);
            renderTrTable();
            updateSaveBtn();
            if (_trEntries.length === 0) document.getElementById('acDetails').classList.add('show');
            setMsg('Transfer entry removed.', false);
        }
        function clearTrEntries() { _trEntries=[]; renderTrTable(); updateSaveBtn(); }

        function renderPayTable() {
            var wrap=document.getElementById('payTableWrap'), tbody=document.getElementById('payTbody'), total=document.getElementById('payTotal');
            if (_payEntries.length===0) { wrap.classList.remove('show'); total.textContent='\u20b90.00'; return; }
            wrap.classList.add('show');
            var html='', sum=0;
            for (var i=0;i<_payEntries.length;i++) {
                var e=_payEntries[i]; sum+=e.amount;
                html+='<tr><td>'+(i+1)+'</td><td>'+xe(e.mode)+'</td><td>\u20b9'+e.amount.toFixed(2)+'</td><td>'+xe(e.particular)+'</td><td><button class="btn-remove" onclick="removePayment('+i+')">\u2715 Remove</button></td></tr>';
            }
            tbody.innerHTML=html; total.textContent='\u20b9'+sum.toFixed(2);
        }
        function removePayment(idx) { _payEntries.splice(idx,1); renderPayTable(); updateSaveBtn(); setMsg('Payment entry removed.', false); }
        function clearPayments()    { _payEntries=[]; renderPayTable(); updateSaveBtn(); }

        function updateSaveBtn() {
            var txnAmt=parseFloat(document.getElementById('txnAmt').value)||0;
            var noShares=parseInt(document.getElementById('noShares').value)||0;
            var isT=document.getElementById('modeTransfer').checked;
            var ready=false;
            // CHANGED: Also check noShares >= 1
            if (noShares < 1 || txnAmt <= 0) { document.getElementById('btnSave').disabled=true; return; }
            if (isT) { var t=_trEntries.reduce(function(s,e){return s+e.amount;},0); ready=(_trEntries.length>0&&Math.abs(t-txnAmt)<0.001); }
            else     { var p=_payEntries.reduce(function(s,e){return s+e.amount;},0); ready=(_payEntries.length>0&&Math.abs(p-txnAmt)<0.001); }
            document.getElementById('btnSave').disabled=!ready;
        }

        function clearAcDetails() {
            document.getElementById('acDetails').classList.remove('show');
            _ledgerBal=0; sv('accountName','');
            ['dispAccCode','dispAccName','glCode','glName','custId','ledgerBal','availBal','newLedgerBal'].forEach(function(id){
                var el=document.getElementById(id); if(el){el.value='';el.classList.remove('bal-pos','bal-neg');}
            });
            clearPayments(); clearTrEntries();
        }

        function sv(id,val)    { var el=document.getElementById(id); if(el) el.value=val||''; }
        function svBal(id,val) {
            var el=document.getElementById(id); if(!el) return;
            var n=parseFloat(val);
            el.value=isNaN(n)?(val||''):n.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2});
            el.classList.remove('bal-pos','bal-neg');
            if (!isNaN(n)) el.classList.add(n>=0?'bal-pos':'bal-neg');
        }
        function setMsg(txt,isErr) {
            var b=document.getElementById('msgBox'); if(!b) return;
            b.value=txt; b.style.color=isErr?'#c04040':'#1a7a3a';
            b.style.background=isErr?'#fff5f5':'#f0fff4'; b.style.borderColor=isErr?'#e0a0a0':'#7ad0a0';
        }

        function doSave() {
            var accountCode = document.getElementById('accountCode').value.trim();
            var meetDate    = document.getElementById('meetDate').value.trim();
            var noShares    = document.getElementById('noShares').value.trim();
            var mode        = document.getElementById('modeTransfer').checked ? 'Transfer' : 'Cash';

            // Validations
            if (!accountCode) { setMsg('Please select an account.', true); return; }
            if (!meetDate)     { setMsg('Please enter meeting date.', true); return; }
            if (!noShares || parseInt(noShares) < 1) { setMsg('Minimum 1 share required.', true); return; }

            // Build transfer codes JSON array
            var trCodes = '[]';
            if (mode === 'Transfer' && _trEntries.length > 0) {
                var arr = [];
                for (var i = 0; i < _trEntries.length; i++) {
                    arr.push('{"code":"' + xq(_trEntries[i].code) + '","amount":' + _trEntries[i].amount + '}');
                }
                trCodes = '[' + arr.join(',') + ']';
            }

            // Disable save button while saving
            document.getElementById('btnSave').disabled = true;
            setMsg('Saving\u2026 Please wait.', false);

            // POST to server
            var xhr = new XMLHttpRequest();
            xhr.open('POST', PAGE_URL + '?action=save', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                var d;
                try {
                    var raw = xhr.responseText;
                    var si = raw.indexOf('{'); if (si > 0) raw = raw.substring(si);
                    d = JSON.parse(raw.trim());
                } catch(e) {
                    setMsg('Parse error: ' + e.message, true);
                    document.getElementById('btnSave').disabled = false;
                    return;
                }
                if (d && d.ok === true) {
                    document.getElementById('sc-certNo').textContent  = d.certNo || '—';
                    document.getElementById('sc-shares').textContent  = noShares;
                    document.getElementById('successOverlay').classList.add('open');
                    setMsg('\u2705 Saved successfully! Certificate No: ' + d.certNo, false);
                } else {
                    setMsg('\u274c Error: ' + (d.error || 'Save failed.'), true);
                    document.getElementById('btnSave').disabled = false;
                }
            };
            xhr.send(
                'accountCode=' + encodeURIComponent(accountCode) +
                '&meetDate='   + encodeURIComponent(meetDate) +
                '&noShares='   + encodeURIComponent(noShares) +
                '&mode='       + encodeURIComponent(mode) +
                '&trCodes='    + encodeURIComponent(trCodes)
            );
        }

        function successOk() {
            document.getElementById('successOverlay').classList.remove('open');
            doCancel();
        }

        function closeSuccess() {
            document.getElementById('successOverlay').classList.remove('open');
            clearForm(); // silent clear, no confirm
        }

        function doCancel() {
            if (!confirm('Clear the form?')) return;
            clearForm();
        }

        function clearForm() {
            clearAcDetails();
            ['accountCode','trCode','trName','payAmt','noShares','meetDate'].forEach(function(id){ var el=document.getElementById(id); if(el) el.value=''; });
            sv('faceVal','100'); sv('txnAmt','0.00'); sv('particular','By Cash');
            document.getElementById('dropMain').classList.remove('on');
            document.getElementById('dropTr').classList.remove('on');
            document.getElementById('modeCash').checked=true;
            onModeChange(); _prev=''; _ledgerBal=0;
            setMsg('Form cleared.', false);
        }

        document.addEventListener('DOMContentLoaded', function() {
            document.addEventListener('click', function(e) {
                if (!e.target.closest||!e.target.closest('.sw')) {
                    document.getElementById('dropMain').classList.remove('on');
                    document.getElementById('dropTr').classList.remove('on');
                }
            });
            document.addEventListener('keydown', function(e){ if(e.key==='Escape') lkClose(); });
        });

        function xe(s){ return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
        function xq(s){ return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

        var _lkTarget='main', _lkTimer=null;
        function openLookup(target) {
            _lkTarget=target;
            document.getElementById('lkSearchInput').value='';
            document.getElementById('lkOverlay').classList.add('open');
            document.getElementById('lkTbody').innerHTML='<tr><td colspan="2" class="lk-msg">Loading&#8230;</td></tr>';
            document.getElementById('lkBadge').textContent=(target==='tr')?'ALL ACCOUNTS':'CUSTOMER';
            setTimeout(function(){ document.getElementById('lkSearchInput').focus(); },80);
            lkLoad('');
        }
        function lkClose() { document.getElementById('lkOverlay').classList.remove('open'); }
        function lkOnInput(val) { clearTimeout(_lkTimer); _lkTimer=setTimeout(function(){ lkLoad(val.trim()); },300); }
        function lkLoad(term) {
            var tbody=document.getElementById('lkTbody');
            tbody.innerHTML='<tr><td colspan="2" class="lk-msg">Searching&#8230;</td></tr>';
            var sa=(_lkTarget==='tr')?'searchtr':'search';
            var xhr=new XMLHttpRequest();
            xhr.open('GET', PAGE_URL+'?action='+sa+'&term='+encodeURIComponent(term), true);
            xhr.onreadystatechange=function() {
                if (xhr.readyState!==4) return;
                var d; try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { tbody.innerHTML='<tr><td colspan="2" class="lk-err">Parse error</td></tr>'; return; }
                if (d.error) { tbody.innerHTML='<tr><td colspan="2" class="lk-err">'+xe(d.error)+'</td></tr>'; return; }
                var list=d.accounts||[];
                if (!list.length) { tbody.innerHTML='<tr><td colspan="2" class="lk-msg">No accounts found.</td></tr>'; return; }
                var html='';
                for (var i=0;i<list.length;i++) {
                    var c=list[i].code||'', n=list[i].name||'';
                    html+='<tr onclick="lkPick(\''+xq(c)+'\',\''+xq(n)+'\')"><td>'+lkHl(c,term)+'</td><td>'+lkHl(n,term)+'</td></tr>';
                }
                tbody.innerHTML=html;
                document.getElementById('lkStatus').textContent=list.length+' result(s). Click a row to select.';
            };
            xhr.send();
        }
        function lkPick(code,name) {
            lkClose();
            if (_lkTarget==='tr') { document.getElementById('trCode').value=code; sv('trName',name); setMsg('Transfer account: '+name, false); }
            else { document.getElementById('accountCode').value=code; sv('accountName',name); _prev=code; fetchAc(code); }
        }
        function lkHl(text,search) {
            if (!search) return xe(text);
            var idx=text.toLowerCase().indexOf(search.toLowerCase());
            if (idx===-1) return xe(text);
            return xe(text.substring(0,idx))+'<span class="lk-hl">'+xe(text.substring(idx,idx+search.length))+'</span>'+xe(text.substring(idx+search.length));
        }
    </script>

    <div class="lk-overlay" id="lkOverlay" onclick="if(event.target===this)lkClose()">
        <div class="lk-modal">
            <div class="lk-head">
                <span class="lk-head-title">Select Account</span>
                <span class="lk-head-badge" id="lkBadge">CUSTOMER</span>
                <button class="lk-head-close" onclick="lkClose()">&#10005;</button>
            </div>
            <div class="lk-search-wrap">
                <input class="lk-search-input" id="lkSearchInput" type="text"
                       placeholder="Search by Account Code or Name..."
                       autocomplete="off" oninput="lkOnInput(this.value)"/>
            </div>
            <div class="lk-body">
                <table class="lk-table">
                    <thead><tr><th>Code</th><th>Name</th></tr></thead>
                    <tbody id="lkTbody"></tbody>
                </table>
            </div>
            <div class="lk-status" id="lkStatus">Click a row to select.</div>
        </div>
    </div>

    <!-- Success Popup -->
    <div class="success-overlay" id="successOverlay">
        <div class="success-modal">
            <div class="success-tick">&#10003;</div>
            <div class="success-title">Shares Allotted Successfully!</div>
            <div class="success-info">
                Certificate No &nbsp;: &nbsp;<strong id="sc-certNo">—</strong><br>
                No. of Shares &nbsp;&nbsp;: &nbsp;<strong id="sc-shares">—</strong>
            </div>
            <button class="btn-ok" onclick="closeSuccess()">OK</button>
        </div>
    </div>

</body>
</html>
