<%@ page trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.io.PrintWriter, db.DBConnection" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    String bankCode   = (String) sess.getAttribute("bankCode");
    String user       = (String) sess.getAttribute("userId");
    String today      = new SimpleDateFormat("dd-MM-yyyy").format(new java.util.Date());
    if (bankCode == null) bankCode = "";
    if (user     == null) user     = "";

    String action = request.getParameter("action");

    /* ── AJAX: search accounts (shares only — SUBSTR(ACCOUNT_CODE,5,3)='901') ── */
    if ("search".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String term = request.getParameter("term");
        if (term == null) term = "";
        term = term.trim();
        String likeVal = term.isEmpty() ? "%" : "%" + term + "%";
        int maxRows = term.isEmpty() ? 50 : 30;
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(
                    "SELECT ACCOUNT_CODE, Fn_Get_Account_name(ACCOUNT_CODE) AS ANAME " +
                    "FROM BALANCE.ACCOUNT " +
                    "WHERE ACCOUNT_CODE LIKE ? " +
                    "AND SUBSTR(ACCOUNT_CODE, 5, 3) = '901' " +
                    "AND ROWNUM <= " + maxRows + " " +
                    "ORDER BY ACCOUNT_CODE");
            ps.setString(1, likeVal);
            rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("{\"accounts\":[");
            boolean first = true;
            while (rs.next()) {
                String c = rs.getString("ACCOUNT_CODE");
                if (c == null) c = ""; else c = c.trim();
                String a = rs.getString("ANAME");
                if (a == null) a = ""; else a = a.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                if (!first) sb.append(",");
                sb.append("{\"code\":\"").append(c).append("\",\"name\":\"").append(a).append("\"}");
                first = false;
            }
            sb.append("]}");
            pw.print(sb.toString());
        } catch (Exception e) {
            String msg = e.getMessage(); if (msg == null) msg = "DB error";
            msg = msg.replace("\"","'").replace("\r","").replace("\n"," ");
            pw.print("{\"error\":\"" + msg + "\",\"accounts\":[]}");
        } finally {
            try{if(rs!=null)rs.close();}catch(Exception ex){}
            try{if(ps!=null)ps.close();}catch(Exception ex){}
            try{if(con!=null)con.close();}catch(Exception ex){}
        }
        pw.flush(); return;
    }

    /* ── AJAX: search transfer accounts (exclude shares — SUBSTR != '901') ── */
    if ("searchTr".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String term = request.getParameter("term");
        if (term == null) term = "";
        term = term.trim();
        String likeVal = term.isEmpty() ? "%" : "%" + term + "%";
        int maxRows = term.isEmpty() ? 50 : 30;
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(
                    "SELECT ACCOUNT_CODE, Fn_Get_Account_name(ACCOUNT_CODE) AS ANAME " +
                    "FROM BALANCE.ACCOUNT " +
                    "WHERE ACCOUNT_CODE LIKE ? " +
                    "AND SUBSTR(ACCOUNT_CODE, 5, 3) != '901' " +
                    "AND ROWNUM <= " + maxRows + " " +
                    "ORDER BY ACCOUNT_CODE");
            ps.setString(1, likeVal);
            rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("{\"accounts\":[");
            boolean first = true;
            while (rs.next()) {
                String c = rs.getString("ACCOUNT_CODE");
                if (c == null) c = ""; else c = c.trim();
                String a = rs.getString("ANAME");
                if (a == null) a = ""; else a = a.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                if (!first) sb.append(",");
                sb.append("{\"code\":\"").append(c).append("\",\"name\":\"").append(a).append("\"}");
                first = false;
            }
            sb.append("]}");
            pw.print(sb.toString());
        } catch (Exception e) {
            String msg = e.getMessage(); if (msg == null) msg = "DB error";
            msg = msg.replace("\"","'").replace("\r","").replace("\n"," ");
            pw.print("{\"error\":\"" + msg + "\",\"accounts\":[]}");
        } finally {
            try{if(rs!=null)rs.close();}catch(Exception ex){}
            try{if(ps!=null)ps.close();}catch(Exception ex){}
            try{if(con!=null)con.close();}catch(Exception ex){}
        }
        pw.flush(); return;
    }

    /* ── AJAX: get full account details ── */
    if ("get".equals(action)) {
        response.reset();
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = response.getWriter();
        String ac = request.getParameter("code");
        if (ac == null || ac.trim().isEmpty()) {
            pw.print("{\"error\":\"Code required\"}"); pw.flush(); return;
        }
        ac = ac.trim();
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps  = con.prepareStatement(
                    "SELECT LEDGERBALANCE, AVAILABLEBALANCE, " +
                    "FN_GET_AC_GL(?) AS GC, " +
                    "Fn_Get_Account_name(FN_GET_AC_GL(?)) AS GN, " +
                    "Fn_Get_Account_name(?) AS ANAME, " +
                    "FN_GET_CUSTOMER_ID(?) AS CI " +
                    "FROM BALANCE.ACCOUNT WHERE ACCOUNT_CODE = ?");
            ps.setString(1,ac); ps.setString(2,ac); ps.setString(3,ac);
            ps.setString(4,ac); ps.setString(5,ac);
            rs = ps.executeQuery();
            if (rs.next()) {
                String n  = rs.getString("ANAME"); if(n==null)n=""; else n=n.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                String gc = rs.getString("GC");    if(gc==null)gc=""; else{gc=gc.trim();if("00000000000000".equals(gc))gc="";}
                String gn = rs.getString("GN");    if(gn==null)gn=""; else gn=gn.trim().replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","");
                String ci = rs.getString("CI");    if(ci==null)ci=""; else ci=ci.trim();
                java.math.BigDecimal lbD=rs.getBigDecimal("LEDGERBALANCE");
                java.math.BigDecimal abD=rs.getBigDecimal("AVAILABLEBALANCE");
                String lb=(lbD!=null)?lbD.toPlainString():"0";
                String ab=(abD!=null)?abD.toPlainString():"0";
                pw.print("{\"ok\":true,\"n\":\""+n+"\",\"gc\":\""+gc+"\",\"gn\":\""+gn+"\",\"ci\":\""+ci+"\",\"lb\":\""+lb+"\",\"ab\":\""+ab+"\"}");
            } else { pw.print("{\"error\":\"Account not found\"}"); }
        } catch (Exception e) {
            String msg=e.getMessage(); if(msg==null)msg="DB error";
            msg=msg.replace("\"","'").replace("\r","").replace("\n"," ");
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
    <title>Shares Refund</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #eaeaf5;
            min-height: 100vh;
            padding: 24px 28px 44px;
            color: #1a1464;
        }

        .page-title {
            text-align: center;
            font-size: 1.4rem;
            font-weight: 800;
            color: #1a1464;
            margin-bottom: 4px;
        }

        .meta-bar {
            display: flex;
            justify-content: center;
            gap: 30px;
            font-size: 0.76rem;
            font-weight: 600;
            color: #3a3a7a;
            margin-bottom: 18px;
        }
        .meta-bar b { color: #1a1464; font-weight: 700; }

        /* ── Main box ── */
        .box {
            background: #fff;
            border: 1.5px solid #c8c8ef;
            border-radius: 14px;
            box-shadow: 0 2px 12px rgba(80,80,180,.09);
            position: relative;
            margin-bottom: 16px;
            overflow: hidden;
        }

        /* ── 3-column modules row ── */
        .modules-row {
            display: grid;
            grid-template-columns: 22% 40% 38%;
            align-items: stretch;
            padding-top: 12px;
        }

        .module {
            padding: 16px 14px;
            display: flex;
            flex-direction: column;
            gap: 9px;
            border-right: 1.5px dashed #e0e0f0;
        }
        .module:last-child { border-right: none; }

        .mod-title {
            font-size: .75rem;
            font-weight: 800;
            color: #2d3db0;
            letter-spacing: .06em;
            text-transform: uppercase;
            padding-bottom: 8px;
            border-bottom: 1.5px solid #eeeef8;
        }

        .fg-row  { display: grid; grid-template-columns: 1fr 1fr;     gap: 8px; align-items: end; }
        .fg-row3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; align-items: end; }

        .fg { display: flex; flex-direction: column; gap: 4px; width: 100%; }
        .fg > label { font-size: .76rem; font-weight: 700; color: #1a1464; }

        input[type=text],
        input[type=number],
        input[type=date] {
            height: 32px;
            padding: 0 9px;
            border: 1.5px solid #c0c0e8;
            border-radius: 7px;
            font-size: .84rem;
            font-family: inherit;
            color: #2d2d6b;
            background: #f4f4ff;
            outline: none;
            width: 100%;
            transition: border-color .15s, box-shadow .15s;
        }
        input:focus { border-color: #5050b8; box-shadow: 0 0 0 2px rgba(80,80,184,.10); background: #f8f8ff; }
        input[readonly], input[disabled] { background: #ebebf8; color: #5a5a90; border-color: #d0d0ee; cursor: default; }
        input::placeholder { color: #a8a8cc; font-size: .82rem; }

        .hint-xs { color: #9090c0; font-size: .70rem; margin-top: 1px; }

        .ib { display: flex; gap: 5px; align-items: center; width: 100%; }
        .ib input { flex: 1; min-width: 0; }

        .sw { position: relative; flex: 1; min-width: 0; }
        .sw input { width: 100%; }

        .sdrop {
            position: absolute;
            top: calc(100% + 2px);
            left: 0; right: 0;
            background: #fff;
            border: 1.5px solid #c0c0e8;
            border-radius: 0 0 8px 8px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 2000;
            display: none;
            box-shadow: 0 6px 20px rgba(60,60,160,.14);
        }
        .sdrop.on { display: block; }

        .sr-item { padding: 8px 11px; cursor: pointer; border-bottom: 1px solid #f0f0f8; }
        .sr-item:last-child { border: none; }
        .sr-item:hover { background: #eeeeff; }
        .sr-code { font-weight: 700; color: #1a1464; font-size: .78rem; margin-bottom: 2px; }
        .sr-name { color: #5050b0; font-size: .75rem; }
        .sr-hint { padding: 8px 11px; color: #a0a0c0; font-size: .76rem; font-style: italic; }
        .hl { background: #ffe066; border-radius: 2px; padding: 0 1px; }

        .btn-dot {
            height: 32px; min-width: 36px; padding: 0 8px;
            background: #2d3db0; color: #fff;
            border: none; border-radius: 7px;
            font-size: .88rem; font-weight: 700;
            cursor: pointer; flex-shrink: 0;
            transition: background .12s;
        }
        .btn-dot:hover    { background: #1d2d9f; }
        .btn-dot:disabled { background: #a0a8d8; cursor: default; }

        .btn-add {
            height: 32px; padding: 0 12px;
            background: #2d3db0; color: #fff;
            border: none; border-radius: 7px;
            font-size: .82rem; font-weight: 700;
            font-family: inherit; cursor: pointer;
            white-space: nowrap; flex-shrink: 0;
            transition: background .12s;
        }
        .btn-add:hover { background: #1d2d9f; }

        .rg { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
        .rg label {
            display: flex; align-items: center; gap: 6px;
            padding: 0 11px; height: 30px;
            border: 1.5px solid #c0c0e8; border-radius: 7px;
            font-size: .82rem; font-weight: 600; color: #2d2d6b;
            cursor: pointer; background: #f8f8ff;
            user-select: none; transition: border-color .15s, background .15s;
        }
        .rg label.on { border-color: #3d4db7; background: #eeeeff; font-weight: 700; }
        .rg input[type=radio] { width: 14px; height: 14px; accent-color: #3d4db7; cursor: pointer; }

        .spin {
            display: none; width: 14px; height: 14px;
            border: 2px solid #d0d0ee; border-top-color: #3d4db7;
            border-radius: 50%; animation: sp .65s linear infinite;
            flex-shrink: 0; margin-left: 2px;
        }
        @keyframes sp { to { transform: rotate(360deg); } }

        /* ── Account Details Panel ── */
        #acDetails { display: none; padding: 20px 24px 24px; background: #eaeaf5; }
        #acDetails.show { display: block; }

        .ac-info-box {
            background: #fff;
            border: 1.5px solid #c8c8ef;
            border-radius: 12px;
            padding: 20px;
            position: relative;
        }
        .ac-info-title {
            font-size: 1.05rem; font-weight: 800; color: #1a1464;
            margin-bottom: 16px; padding-bottom: 10px;
            border-bottom: 2px solid #1a1464; display: inline-block;
        }
        .ac-info-grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 12px 16px; }
        .ac-fg { display: flex; flex-direction: column; gap: 5px; }
        .ac-fg label { font-size: .78rem; font-weight: 700; color: #1a1464; }
        .ac-fg input {
            height: 34px; padding: 0 10px;
            background: #f0f0f0; border: 1px solid #d0d0d0;
            border-radius: 4px; font-size: .84rem;
            color: #333; font-family: inherit; width: 100%;
        }

        .bal-pos { color: #1a7a3a !important; font-weight: 700 !important; }
        .bal-neg { color: #c04040 !important; font-weight: 700 !important; }
        .amt-red { color: #c04040 !important; font-weight: 700 !important; }

        /* ── Message + Action ── */
        .msg-bar { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
        #msgBox {
            flex: 1; height: 36px; padding: 0 13px;
            border-radius: 8px; border: 1.5px solid #c0c0e8;
            background: #f4f4ff; color: #2d2d6b;
            font-size: .84rem; font-weight: 600;
            font-family: inherit; outline: none;
        }

        .act-bar { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; }

        .btn-primary {
            height: 38px; padding: 0 40px;
            background: #2d3db0; color: #fff;
            border: none; border-radius: 9px;
            font-size: .88rem; font-weight: 700;
            font-family: inherit; cursor: pointer;
            transition: background .12s;
        }
        .btn-primary:hover { background: #1d2d9f; }

        .btn-secondary {
            height: 38px; padding: 0 20px;
            background: #fff; color: #2d2d6b;
            border: 1.5px solid #c0c0e8; border-radius: 9px;
            font-size: .84rem; font-weight: 700;
            font-family: inherit; cursor: pointer;
            transition: background .12s;
        }
        .btn-secondary:hover { background: #f0f0ff; }

        .btn-danger {
            height: 38px; padding: 0 20px;
            background: #fff; color: #c04040;
            border: 1.5px solid #e0b0b0; border-radius: 9px;
            font-size: .84rem; font-weight: 700;
            font-family: inherit; cursor: pointer;
            transition: background .12s;
        }
        .btn-danger:hover { background: #fff0f0; }

        /* ── Lookup Modal ── */
        .lk-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(20,20,60,.5); z-index: 9999;
            align-items: flex-start; justify-content: center;
            padding-top: 60px;
        }
        .lk-overlay.open { display: flex; }
        .lk-modal {
            background: #fff; border-radius: 14px;
            box-shadow: 0 8px 40px rgba(30,30,100,.25);
            width: 860px; max-width: 96vw; max-height: 80vh;
            display: flex; flex-direction: column; overflow: hidden;
        }
        .lk-head { display: flex; align-items: center; gap: 12px; padding: 14px 18px; border-bottom: 1.5px solid #e8e8f4; flex-shrink: 0; }
        .lk-head-title { font-size: 1.1rem; font-weight: 800; color: #1a1464; }
        .lk-head-badge { background: #6c63ff; color: #fff; font-size: .72rem; font-weight: 700; padding: 3px 12px; border-radius: 20px; }
        .lk-head-close { margin-left: auto; width: 34px; height: 34px; background: #e03030; color: #fff; border: none; border-radius: 8px; font-size: 1rem; font-weight: 900; cursor: pointer; }
        .lk-head-close:hover { background: #c02020; }
        .lk-search-wrap { padding: 10px 16px; border-bottom: 1px solid #eeeef8; flex-shrink: 0; }
        .lk-search-input {
            width: 100%; height: 38px; padding: 0 14px 0 38px;
            border: 1.5px solid #c0c0e8; border-radius: 22px;
            font-size: .9rem; font-family: inherit; color: #2d2d6b;
            background: #f8f8ff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='15' height='15' fill='%236c63ff' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11'/%3E%3C/svg%3E") no-repeat 12px center;
            outline: none;
        }
        .lk-search-input:focus { border-color: #5050b8; }
        .lk-search-input::placeholder { color: #a8a8cc; }
        .lk-body { flex: 1; overflow-y: auto; }
        .lk-table { width: 100%; border-collapse: collapse; }
        .lk-table thead tr { background: #2d3db0; color: #fff; position: sticky; top: 0; z-index: 1; }
        .lk-table thead th { padding: 10px 14px; text-align: center; font-size: .83rem; font-weight: 700; }
        .lk-table tbody tr { border-bottom: 1px solid #eeeef8; cursor: pointer; transition: background .1s; }
        .lk-table tbody tr:hover { background: #eeeeff; }
        .lk-table tbody td { padding: 9px 14px; font-size: .83rem; color: #2d2d6b; }
        .lk-table tbody td:first-child { font-weight: 700; color: #1a1464; }
        .lk-table tbody td:last-child { text-align: center; color: #5050a0; }
        .lk-msg { text-align: center; padding: 28px; color: #a0a0c0; font-style: italic; font-size: .88rem; }
        .lk-err { text-align: center; padding: 16px; color: #c04040; font-size: .85rem; }
        .lk-hl  { background: #ffe066; border-radius: 2px; padding: 0 1px; }
        .lk-status { padding: 6px 16px; font-size: .74rem; color: #8080b0; border-top: 1px solid #eeeef8; flex-shrink: 0; }
    </style>
</head>
<body>

    <div class="page-title">Shares Refund</div>
   

    <div class="box">

        <div class="modules-row">

            <!-- ░░ MODULE 1 : Account Info ░░ -->
            <div class="module">
                <div class="mod-title">Account Info</div>

                <div class="fg">
                    <label>Account Code</label>
                    <div class="ib">
                        <div class="sw">
                            <input type="text" id="accountCode"
                                   placeholder="Last 7 digits…"
                                   autocomplete="off"
                                   oninput="onAcInput(this.value)"
                                   onkeydown="if(event.key==='Enter'){event.preventDefault();triggerFetch();}"/>
                            <div class="sdrop" id="dropMain"></div>
                        </div>
                        <button class="btn-dot" type="button" onclick="openLookup('main')">...</button>
                        <span class="spin" id="spinMain"></span>
                    </div>
                    <span class="hint-xs">Type last 7 digits to search</span>
                </div>

                <div class="fg">
                    <label>Account Name</label>
                    <input type="text" id="accountName" readonly placeholder="—"/>
                </div>
            </div>

            <!-- ░░ MODULE 2 : Share Details ░░ -->
            <div class="module">
                <div class="mod-title">Share Details</div>

                <div class="fg-row3">
                    <div class="fg">
                        <label>Total No. of Shares</label>
                        <input type="text" id="totalNoShares" value="0" readonly class="amt-red"/>
                    </div>
                    <div class="fg">
                        <label>Total Face Value</label>
                        <input type="text" id="totalFaceValue" value="0.00" readonly class="amt-red"/>
                    </div>
                    <div class="fg">
                        <label>Total Amount</label>
                        <input type="text" id="totalAmount" value="0.00" readonly class="amt-red"/>
                    </div>
                </div>

                <div class="fg-row">
                    <div class="fg">
                        <label>Meeting Date</label>
                        <input type="date" id="meetDate"/>
                    </div>
                    <div class="fg">
                        <label>Remark</label>
                        <input type="text" id="remark" placeholder="Enter remark"/>
                    </div>
                </div>
            </div>

            <!-- ░░ MODULE 3 : Transaction Details ░░ -->
            <div class="module">
                <div class="mod-title">Transaction Details</div>

                <div class="fg-row">
                    <div class="fg">
                        <label>Mode of Payment</label>
                        <div class="rg">
                            <label id="lblTransfer">
                                <input type="radio" name="mop" value="Transfer"
                                       id="modeTransfer" onchange="onModeChange()"/>
                                Transfer
                            </label>
                            <label id="lblCash" class="on">
                                <input type="radio" name="mop" value="Cash"
                                       id="modeCash" onchange="onModeChange()" checked/>
                                Cash
                            </label>
                        </div>
                    </div>
                    <div class="fg">
                        <label>Amount</label>
                        <div class="ib">
                            <input type="number" id="payAmt" placeholder="0.00"/>
                            <button class="btn-add" type="button" onclick="doAddPayment()">Add</button>
                        </div>
                    </div>
                </div>

                <div class="fg-row">
                    <div class="fg">
                        <label>Transfer A/c. Code</label>
                        <div class="ib">
                            <div class="sw">
                                <input type="text" id="trCode" disabled
                                       autocomplete="off"
                                       oninput="onTrInput(this.value)"
                                       onkeydown="if(event.key==='Enter'){event.preventDefault();triggerTrFetch();}"/>
                                <div class="sdrop" id="dropTr"></div>
                            </div>
                            <button class="btn-dot" id="btnTr" type="button"
                                    disabled onclick="openLookup('tr')">...</button>
                            <span class="spin" id="spinTr"></span>
                        </div>
                    </div>
                    <div class="fg">
                        <label>Transfer A/c. Name</label>
                        <input type="text" id="trName" readonly placeholder="—"/>
                    </div>
                </div>

                <div class="fg">
                    <label>Tr. Particular</label>
                    <input type="text" id="trParticular" placeholder="Enter particular"/>
                </div>
            </div>

        </div><!-- /.modules-row -->

        <!-- ── Account Details Panel ── -->
        <div id="acDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Account Information</div>
                <div class="ac-info-grid">
                    <div class="ac-fg">
                        <label>GL Account Code</label>
                        <input type="text" id="glCode" readonly placeholder=""/>
                    </div>
                    <div class="ac-fg">
                        <label>GL Account Name</label>
                        <input type="text" id="glName" readonly placeholder=""/>
                    </div>
                    <div class="ac-fg">
                        <label>Customer ID</label>
                        <input type="text" id="custId" readonly placeholder=""/>
                    </div>
                    <div class="ac-fg">
                        <label>Ledger Balance</label>
                        <input type="text" id="ledgerBal" readonly placeholder=""/>
                    </div>
                    <div class="ac-fg">
                        <label>Available Balance</label>
                        <input type="text" id="availBal" readonly placeholder=""/>
                    </div>
                    <div class="ac-fg">
                        <label>New Ledger Balance</label>
                        <input type="text" id="newLedgerBal" readonly placeholder=""/>
                    </div>
                </div>
            </div>
        </div>

    </div><!-- /.box -->


    <!-- ── Action Buttons ── -->
    <div class="act-bar">
        <button class="btn-primary"   type="button" onclick="doSave()">Save</button>
        <button class="btn-danger"    type="button" onclick="doCancel()">Clear</button>
    </div>

    <script>
        var PAGE_URL   = '<%= request.getContextPath() + request.getServletPath() %>';
        var SEARCH_MIN = 3;
        var WAIT_MS    = 300;
        var _timer     = null;
        var _prev      = '';

        /* ── Main account input ── */
        function onAcInput(v) {
            if (v !== _prev) { clearAcDetails(); _prev = v; }
            liveSearch(v, 'dropMain', 'main');
        }

        /* ── Transfer account input ── */
        function onTrInput(v) {
            liveSearch(v, 'dropTr', 'tr');
        }

        /* ── Generic live search ── */
        function liveSearch(val, dropId, target) {
            clearTimeout(_timer);
            var drop = document.getElementById(dropId);
            if (!val) { drop.classList.remove('on'); return; }
            var term = val.length > 7 ? val.slice(-7) : val;
            if (term.length < SEARCH_MIN) {
                drop.innerHTML = '<div class="sr-hint">Type at least ' + SEARCH_MIN + ' digits…</div>';
                drop.classList.add('on');
                return;
            }
            drop.innerHTML = '<div class="sr-hint">Searching…</div>';
            drop.classList.add('on');
            _timer = setTimeout(function() { doSearch(term, dropId, target); }, WAIT_MS);
        }

        function doSearch(term, dropId, target) {
            var drop = document.getElementById(dropId);
            /* use searchTr action for transfer field — excludes 901 accounts */
            var act  = (target === 'tr') ? 'searchTr' : 'search';
            var xhr  = new XMLHttpRequest();
            xhr.open('GET', PAGE_URL + '?action=' + act + '&term=' + encodeURIComponent(term), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                if (xhr.status !== 200) { drop.innerHTML = '<div class="sr-hint">Error ' + xhr.status + '</div>'; return; }
                var d;
                try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { drop.innerHTML = '<div class="sr-hint">' + xe(xhr.responseText.substring(0,80)) + '</div>'; return; }
                if (d.error) { drop.innerHTML = '<div class="sr-hint">' + xe(d.error) + '</div>'; return; }
                var list = d.accounts || [];
                if (!list.length) { drop.innerHTML = '<div class="sr-hint">No accounts found</div>'; return; }
                var html = '';
                for (var i = 0; i < list.length; i++) {
                    var c = list[i].code || '';
                    var a = list[i].name || '';
                    html += '<div class="sr-item" onclick="pick(\'' + xq(c) + '\',\'' + xq(a) + '\',\'' + target + '\')">'
                          + '<div class="sr-code">' + hlMatch(c, term) + '</div>'
                          + '<div class="sr-name">' + xe(a) + '</div>'
                          + '</div>';
                }
                drop.innerHTML = html;
            };
            xhr.send();
        }

        function hlMatch(text, search) {
            var last7 = text.slice(-7);
            var idx   = last7.indexOf(search);
            if (idx === -1) return xe(text);
            var pos = text.length - 7 + idx;
            return xe(text.substring(0, pos))
                 + '<span class="hl">' + xe(search) + '</span>'
                 + xe(text.substring(pos + search.length));
        }

        /* ── Pick from inline dropdown ── */
        function pick(code, name, target) {
            if (target === 'tr') {
                document.getElementById('dropTr').classList.remove('on');
                document.getElementById('trCode').value = code;
                sv('trName', name);
                fetchTr(code);
            } else {
                document.getElementById('dropMain').classList.remove('on');
                document.getElementById('accountCode').value = code;
                _prev = code;
                fetchAc(code);
            }
        }

        function triggerFetch() {
            var code = document.getElementById('accountCode').value.trim();
            if (!code) { setMsg('Please enter an Account Code.', true); return; }
            document.getElementById('dropMain').classList.remove('on');
            fetchAc(code);
        }

        function triggerTrFetch() {
            var code = document.getElementById('trCode').value.trim();
            if (!code) { setMsg('Please enter a Transfer Account Code.', true); return; }
            document.getElementById('dropTr').classList.remove('on');
            fetchTr(code);
        }

        /* ── Fetch main account details ── */
        function fetchAc(code) {
            document.getElementById('spinMain').style.display = 'inline-block';
            setMsg('Fetching…', false);
            var xhr = new XMLHttpRequest();
            xhr.open('GET', PAGE_URL + '?action=get&code=' + encodeURIComponent(code), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                document.getElementById('spinMain').style.display = 'none';
                if (xhr.status !== 200) { clearAcDetails(); setMsg('Server error: ' + xhr.status, true); return; }
                var d;
                try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { clearAcDetails(); setMsg('Parse error: '+e.message, true); return; }
                if (d && d.ok === true) {
                    sv('accountName', d.n  || '');
                    sv('glCode',      d.gc || '');
                    sv('glName',      d.gn || '');
                    sv('custId',      d.ci || '');
                    svBal('ledgerBal',  d.lb);
                    svBal('availBal',   d.ab);
                    sv('newLedgerBal', '');
                    document.getElementById('acDetails').classList.add('show');
                    setMsg('Account loaded: ' + (d.n || code), false);
                } else {
                    clearAcDetails();
                    setMsg((d && d.error) ? d.error : 'Account not found.', true);
                }
            };
            xhr.send();
        }

        /* ── Fetch transfer account details ── */
        function fetchTr(code) {
            document.getElementById('spinTr').style.display = 'inline-block';
            var xhr = new XMLHttpRequest();
            xhr.open('GET', PAGE_URL + '?action=get&code=' + encodeURIComponent(code), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                document.getElementById('spinTr').style.display = 'none';
                var d;
                try { var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); d=JSON.parse(raw.trim()); }
                catch(e) { setMsg('Parse error', true); return; }
                if (d && d.ok === true) {
                    sv('trName', d.n || '');
                    setMsg('Transfer account: ' + (d.n || code), false);
                } else {
                    sv('trName', '');
                    setMsg((d && d.error) ? d.error : 'Not found.', true);
                }
            };
            xhr.send();
        }

        function onModeChange() {
            var isT = document.getElementById('modeTransfer').checked;
            document.getElementById('trCode').disabled = !isT;
            document.getElementById('btnTr').disabled  = !isT;
            document.getElementById('lblTransfer').classList.toggle('on',  isT);
            document.getElementById('lblCash').classList.toggle('on', !isT);
            if (!isT) {
                sv('trCode', ''); sv('trName', '');
                document.getElementById('dropTr').classList.remove('on');
            }
        }

        function clearAcDetails() {
            document.getElementById('acDetails').classList.remove('show');
            sv('accountName', '');
            ['glCode','glName','custId','ledgerBal','availBal','newLedgerBal'].forEach(function(id) {
                var el = document.getElementById(id);
                if (el) { el.value = ''; el.classList.remove('bal-pos','bal-neg'); }
            });
        }

        function sv(id, val) { var el = document.getElementById(id); if(el) el.value = val || ''; }

        function svBal(id, val) {
            var el = document.getElementById(id); if(!el) return;
            var n  = parseFloat(val);
            el.value = isNaN(n) ? (val||'') : n.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2});
            el.classList.remove('bal-pos','bal-neg');
            if (!isNaN(n)) el.classList.add(n >= 0 ? 'bal-pos' : 'bal-neg');
        }

        function setMsg(txt, isErr) {
            var b = document.getElementById('msgBox'); if(!b) return;
            b.value             = txt;
            b.style.color       = isErr ? '#c04040' : '#1a7a3a';
            b.style.background  = isErr ? '#fff5f5' : '#f0fff4';
            b.style.borderColor = isErr ? '#e0a0a0' : '#7ad0a0';
        }

        function doValidate()   { setMsg('Validating…',       false); }
        function doSave()       { setMsg('Saving…',           false); }
        function doVouchers()   { setMsg('Loading vouchers…', false); }
        function doAddPayment() { setMsg('Payment added.',    false); }

        function doCancel() {
            if (!confirm('Clear the form?')) return;
            clearAcDetails();
            ['accountCode','trCode','trName','payAmt','trParticular','remark','meetDate'].forEach(function(id) {
                var el = document.getElementById(id); if(el) el.value = '';
            });
            sv('totalNoShares','0'); sv('totalFaceValue','0.00'); sv('totalAmount','0.00');
            document.getElementById('dropMain').classList.remove('on');
            document.getElementById('dropTr').classList.remove('on');
            document.getElementById('modeCash').checked = true;
            onModeChange(); _prev = '';
            setMsg('Form cleared.', false);
        }

        /* ── Close dropdowns on outside click ── */
        document.addEventListener('click', function(e) {
            if (!e.target.closest('.sw') && !e.target.closest('.lk-modal')) {
                document.getElementById('dropMain').classList.remove('on');
                document.getElementById('dropTr').classList.remove('on');
            }
        });

        document.addEventListener('keydown', function(e) { if(e.key==='Escape') lkClose(); });

        function xe(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
        function xq(s) { return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

        /* ════ LOOKUP MODAL ════ */
        var _lkTarget = 'main';
        var _lkTimer  = null;

        function openLookup(target) {
            _lkTarget = target;
            document.getElementById('lkSearchInput').value = '';
            document.getElementById('lkTbody').innerHTML = '<tr><td colspan="3" class="lk-msg">Loading&#8230;</td></tr>';
            document.getElementById('lkStatus').textContent = 'Click a row to select.';
            /* update badge label based on target */
            document.getElementById('lkBadge').textContent = (target === 'tr') ? 'TRANSFER A/C' : 'SHARES A/C';
            document.getElementById('lkOverlay').classList.add('open');
            setTimeout(function(){ document.getElementById('lkSearchInput').focus(); }, 80);
            lkLoad('');
        }

        function lkClose() { document.getElementById('lkOverlay').classList.remove('open'); }

        function lkOnInput(val) {
            clearTimeout(_lkTimer);
            _lkTimer = setTimeout(function(){ lkLoad(val.trim()); }, 300);
        }

        function lkLoad(term) {
            var tbody = document.getElementById('lkTbody');
            tbody.innerHTML = '<tr><td colspan="3" class="lk-msg">Searching&#8230;</td></tr>';
            /* use searchTr for transfer lookup — excludes 901 accounts */
            var act = (_lkTarget === 'tr') ? 'searchTr' : 'search';
            var xhr = new XMLHttpRequest();
            xhr.open('GET', PAGE_URL + '?action=' + act + '&term=' + encodeURIComponent(term), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                if (xhr.status !== 200) { tbody.innerHTML = '<tr><td colspan="3" class="lk-err">HTTP Error ' + xhr.status + '</td></tr>'; return; }
                var d;
                try {
                    var raw=xhr.responseText; var si=raw.indexOf('{'); if(si>0)raw=raw.substring(si); raw=raw.trim();
                    if(!raw){tbody.innerHTML='<tr><td colspan="3" class="lk-err">Empty response.</td></tr>';return;}
                    d=JSON.parse(raw);
                } catch(e) { tbody.innerHTML='<tr><td colspan="3" class="lk-err">'+xe(xhr.responseText.substring(0,100))+'</td></tr>'; return; }
                if (d.error) { tbody.innerHTML='<tr><td colspan="3" class="lk-err">'+xe(d.error)+'</td></tr>'; return; }
                var list = d.accounts || [];
                if (!list.length) { tbody.innerHTML='<tr><td colspan="3" class="lk-msg">No accounts found.</td></tr>'; return; }
                var html = '';
                for (var i = 0; i < list.length; i++) {
                    var c = list[i].code || '';
                    var n = list[i].name || '';
                    html += '<tr onclick="lkPick(\'' + xq(c) + '\',\'' + xq(n) + '\')">'
                          + '<td>' + lkHl(c,term) + '</td>'
                          + '<td>' + lkHl(n,term) + '</td>'
                          + '<td>' + (_lkTarget==='tr'?'TRANSFER':'SHARES') + '</td></tr>';
                }
                tbody.innerHTML = html;
                document.getElementById('lkStatus').textContent = list.length + ' result(s). Click a row to select.';
            };
            xhr.send();
        }

        function lkPick(code, name) {
            lkClose();
            if (_lkTarget === 'tr') {
                document.getElementById('trCode').value = code;
                sv('trName', name);
                fetchTr(code);
            } else {
                document.getElementById('accountCode').value = code;
                _prev = code;
                fetchAc(code);
            }
        }

        function lkHl(text, search) {
            if (!search) return xe(text);
            var idx = text.toLowerCase().indexOf(search.toLowerCase());
            if (idx === -1) return xe(text);
            return xe(text.substring(0,idx))
                 + '<span class="lk-hl">'+xe(text.substring(idx,idx+search.length))+'</span>'
                 + xe(text.substring(idx+search.length));
        }
    </script>

    <!-- ════ LOOKUP MODAL ════ -->
    <div class="lk-overlay" id="lkOverlay" onclick="if(event.target===this)lkClose()">
        <div class="lk-modal">
            <div class="lk-head">
                <span class="lk-head-title">Select Account</span>
                <span class="lk-head-badge" id="lkBadge">SHARES A/C</span>
                <button class="lk-head-close" onclick="lkClose()">&#10005;</button>
            </div>
            <div class="lk-search-wrap">
                <input class="lk-search-input" id="lkSearchInput" type="text"
                       placeholder="Search by Account Code or Name..."
                       autocomplete="off"
                       oninput="lkOnInput(this.value)"/>
            </div>
            <div class="lk-body">
                <table class="lk-table">
                    <thead><tr><th>Code</th><th>Name</th><th>Type</th></tr></thead>
                    <tbody id="lkTbody"><tr><td colspan="3" class="lk-msg">Loading&#8230;</td></tr></tbody>
                </table>
            </div>
            <div class="lk-status" id="lkStatus">Click a row to select.</div>
        </div>
    </div>

</body>
</html>
