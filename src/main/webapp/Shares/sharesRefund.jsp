<%@ page trimDirectiveWhitespaces="true" %>
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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shares Refund</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', Tahoma, Arial, sans-serif; background: #eaeaf5; min-height: 100vh; padding: 24px 28px 44px; color: #1a1a6e; }
        .page-title { text-align: center; font-size: 1.45rem; font-weight: 800; color: #1a1a6e; margin-bottom: 4px; }
        .box { background: #fff; border: 1.5px solid #c0c0e0; border-radius: 12px; position: relative; margin-bottom: 16px; overflow: hidden; }
        .shared-grid { display: grid; grid-template-columns: 22% 33% 45%; }
        .cell { padding: 12px 20px 20px; border-right: 1.5px dashed #dcdcf0; display: flex; flex-direction: column; gap: 9px; }
        .cell:last-child { border-right: none; }
        .titles-row { padding-top: 16px; }
        .titles-row .cell { padding-bottom: 0; }
        .mod-title { font-size: .76rem; font-weight: 800; color: #1a1a6e; letter-spacing: .05em; text-transform: uppercase; padding-bottom: 7px; border-bottom: 1.5px solid #dcdcf0; display: block; }
        .cell-inner { display: flex; gap: 8px; align-items: flex-end; }
        .cell-inner .fg { flex: 1; min-width: 0; }
        .fg { display: flex; flex-direction: column; gap: 4px; width: 100%; }
        .fg > label { font-size: .76rem; font-weight: 600; color: #1a1a6e; }
        input[type=text], input[type=number], input[type=date] { height: 32px; padding: 0 9px; border: 1px solid #c0c0e0; border-radius: 6px; font-size: .84rem; font-family: inherit; color: #1a1a6e; background: #fff; outline: none; width: 100%; transition: border-color .15s, box-shadow .15s; }
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
        .btn-dot { height: 32px; min-width: 36px; padding: 0 8px; background: #3535a0; color: #fff; border: none; border-radius: 6px; font-size: .88rem; font-weight: 700; cursor: pointer; flex-shrink: 0; transition: background .12s; }
        .btn-dot:hover { background: #252588; }
        .btn-dot:disabled { background: #a0a0c8; cursor: default; }
        .btn-add { height: 32px; padding: 0 16px; background: #3535a0; color: #fff; border: none; border-radius: 6px; font-size: .82rem; font-weight: 700; font-family: inherit; cursor: pointer; white-space: nowrap; flex-shrink: 0; transition: background .12s; }
        .btn-add:hover { background: #252588; }
        .rg { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
        .rg label { display: flex; align-items: center; gap: 9px; padding: 0 25px; height: 32px; border: 1.5px solid #c0c0e0; border-radius: 6px; font-size: .84rem; font-weight: 500; color: #1a1a6e; cursor: pointer; background: #fff; user-select: none; transition: border-color .15s, background .15s; }
        .rg label.on { border-color: #3535a0; background: #ebebff; font-weight: 700; }
        .rg input[type=radio] { width: 15px; height: 15px; accent-color: #3535a0; cursor: pointer; }
        .spin { display: none; width: 14px; height: 14px; border: 2px solid #d0d0e8; border-top-color: #3535a0; border-radius: 50%; animation: sp .65s linear infinite; flex-shrink: 0; margin-left: 2px; }
        @keyframes sp { to { transform: rotate(360deg); } }

        /* ── Payment / Transfer Tables ── */
        .tr-table-wrap { display: none; border-top: 1.5px solid #4a4aaa; overflow: hidden; margin: 0; }
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
        .btn-remove { height: 26px; padding: 0 10px; background: #fff; color: #b03030; border: 1px solid #e0a0a0; border-radius: 4px; font-size: .75rem; font-weight: 700; cursor: pointer; transition: background .12s; }
        .btn-remove:hover { background: #fff0f0; }

        /* ── Panels ── */
        #acDetails { display: none; padding: 20px 24px 24px; background: #eaeaf5; }
        #acDetails.show { display: block; }
        #trDetails { display: none; padding: 20px 24px 24px; background: #eaeaf5; }
        #trDetails.show { display: block; }
        /* Transfer row-click detail panel — sits below the tr table */
        #trRowDetails { display: none; padding: 20px 24px 24px; background: #eaeaf5; }
        #trRowDetails.show { display: block; }

        .ac-info-box { background: #fff; border: 1.5px solid #c0c0e0; border-radius: 12px; padding: 22px 20px 20px; position: relative; }
        .ac-info-title { position: absolute; top: -11px; left: 14px; background: #fff; padding: 0 8px; font-size: .9rem; font-weight: 700; color: #1a1a6e; display: flex; align-items: center; gap: 8px; }
        .ac-info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px 16px; margin-top: 4px; }
        .ac-info-grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px 16px; margin-top: 4px; }
        .ac-fg { display: flex; flex-direction: column; gap: 5px; }
        .ac-fg label { font-size: .77rem; font-weight: 600; color: #1a1a6e; }
        .ac-fg input { height: 34px; padding: 0 10px; background: #ebebf5; border: 1px solid #d0d0e8; border-radius: 5px; font-size: .84rem; color: #1a1a6e; font-family: inherit; width: 100%; outline: none; }
        .bal-pos { color: #1a7a3a !important; font-weight: 700 !important; }
        .bal-neg { color: #b03030 !important; font-weight: 700 !important; }
        .amt-red { color: #b03030 !important; font-weight: 700 !important; }

        .act-bar { display: flex; justify-content: center; gap: 14px; flex-wrap: wrap; }
        .btn-primary { height: 40px; padding: 0 48px; background: #1a1a6e; color: #fff; border: none; border-radius: 8px; font-size: .9rem; font-weight: 700; font-family: inherit; cursor: pointer; transition: background .12s; }
        .btn-primary:hover { background: #12126e; }
        .btn-danger { height: 40px; padding: 0 28px; background: #fff; color: #cc2222; border: 1.5px solid #cc2222; border-radius: 8px; font-size: .9rem; font-weight: 700; font-family: inherit; cursor: pointer; transition: background .12s; }
        .btn-danger:hover { background: #fff5f5; }

        .lk-overlay { display: none; position: fixed; inset: 0; background: rgba(20,20,60,.5); z-index: 9999; align-items: flex-start; justify-content: center; padding-top: 60px; }
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

        .success-overlay { display: none; position: fixed; inset: 0; background: rgba(80,80,120,.35); z-index: 99999; align-items: center; justify-content: center; }
        .success-overlay.open { display: flex; }
        .success-modal { background: #fff; border-radius: 18px; box-shadow: 0 8px 40px rgba(30,30,100,.18); width: 420px; max-width: 92vw; padding: 44px 40px 32px; display: flex; flex-direction: column; align-items: center; gap: 14px; }
        .success-tick { font-size: 3.2rem; font-weight: 900; line-height: 1; }
        .success-title { font-size: 1.1rem; font-weight: 700; color: #111; text-align: center; }
        .success-info  { font-size: .9rem; color: #222; font-weight: 500; text-align: center; line-height: 2.2; }
        .btn-ok { height: 42px; padding: 0 64px; background: #22aa55; color: #fff; border: none; border-radius: 8px; font-size: .95rem; font-weight: 700; font-family: inherit; cursor: pointer; margin-top: 4px; transition: background .12s; }
        .btn-ok:hover { background: #1a8f44; }
        .btn-ok-red  { background: #cc2222 !important; white-space: nowrap; }
        .btn-ok-red:hover  { background: #aa1a1a !important; }
        .btn-ok-grey { background: #909090 !important; }
        .btn-ok-grey:hover { background: #707070 !important; }
    </style>
</head>
<body>
    <div class="page-title">Shares Refund</div>

    <div class="box">
        <!-- ── Column Headers ── -->
        <div class="shared-grid titles-row">
            <div class="cell"><span class="mod-title">Account Info</span></div>
            <div class="cell"><span class="mod-title">Share Details</span></div>
            <div class="cell"><span class="mod-title">Transaction Details</span></div>
        </div>

        <!-- ── Row 1 ── -->
        <div class="shared-grid">
            <div class="cell">
                <div class="fg">
                    <label>Account Code</label>
                    <div class="ib">
                        <div class="sw">
                            <input type="text" id="accountCode" placeholder="Last 7 digits&hellip;" autocomplete="off"
                                   oninput="onAcInput(this.value)" onfocus="showMainPanel()"
                                   onkeydown="if(event.key==='Enter'){event.preventDefault();triggerFetch();}"/>
                            <div class="sdrop" id="dropMain"></div>
                        </div>
                        <button class="btn-dot" type="button" onclick="openLookup('main')">...</button>
                        <span class="spin" id="spinMain"></span>
                    </div>
                    <span class="hint-xs">Type last 7 digits to search</span>
                </div>
            </div>
            <div class="cell">
                <div class="cell-inner">
                    <div class="fg"><label>Total No. of Shares</label><input type="text" id="totalNoShares" value="0" readonly class="amt-red"/></div>
                    <div class="fg"><label>Total Face Value</label>  <input type="text" id="totalFaceValue" value="0.00" readonly class="amt-red"/></div>
                    <div class="fg"><label>Total Amount</label>      <input type="text" id="totalAmount"    value="0.00" readonly class="amt-red"/></div>
                </div>
            </div>
            <div class="cell">
                <div class="cell-inner">
                    <div class="fg">
                        <label>Mode of Payment</label>
                        <div class="rg">
                            <label id="lblTransfer"><input type="radio" name="mop" value="Transfer" id="modeTransfer" onchange="onModeChange()"/>Transfer</label>
                            <label id="lblCash" class="on"><input type="radio" name="mop" value="Cash" id="modeCash" onchange="onModeChange()" checked/>Cash</label>
                        </div>
                    </div>
                    <div class="fg">
                        <label>Amount</label>
                        <div class="ib">
                            <input type="number" id="payAmt" placeholder="0.00" min="0" step="0.01"/>
                            <button class="btn-add" type="button" onclick="doAddPayment()">Add</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ── Row 2 ── -->
        <div class="shared-grid">
            <div class="cell">
                <div class="fg"><label>Account Name</label><input type="text" id="accountName" readonly placeholder="&mdash;"/></div>
            </div>
            <div class="cell">
                <div class="cell-inner">
                    <div class="fg"><label>Meeting Date</label><input type="date" id="meetDate"/></div>
                    <div class="fg"><label>Particular</label>  <input type="text" id="particular" placeholder="Enter particular"/></div>
                </div>
            </div>
            <div class="cell">
                <div class="cell-inner" style="align-items:flex-end;">
                    <div class="fg" style="flex:1;min-width:0;">
                        <label>Transfer A/c. Code</label>
                        <div class="ib">
                            <div class="sw">
                                <input type="text" id="trCode" disabled autocomplete="off"
                                       oninput="onTrInput(this.value)" onfocus="showTrPanel()"
                                       onkeydown="if(event.key==='Enter'){event.preventDefault();triggerTrFetch();}"/>
                                <div class="sdrop" id="dropTr"></div>
                            </div>
                            <button class="btn-dot" id="btnTr" type="button" disabled onclick="openLookup('tr')">...</button>
                            <span class="spin" id="spinTr"></span>
                        </div>
                    </div>
                    <div class="fg" style="flex:1;min-width:0;">
                        <label>Transfer A/c. Name</label>
                        <input type="text" id="trName" readonly placeholder="&mdash;"/>
                    </div>
                </div>
                <span class="hint-xs">Type last 7 digits to search savings a/c</span>
            </div>
        </div>

        <!-- ══ Cash Payment Table ══ -->
        <div class="tr-table-wrap" id="payTableWrap">
            <table class="tr-table">
                <thead>
                    <tr><th>Sr No</th><th>Mode</th><th>Amount (&#8377;)</th><th>Particular</th><th></th></tr>
                </thead>
                <tbody id="payTbody"></tbody>
                <tfoot>
                    <tr>
                        <td colspan="2">Total Refunded</td>
                        <td id="payTotal">&#8377;0.00</td>
                        <td colspan="2"></td>
                    </tr>
                </tfoot>
            </table>
        </div>

        <!-- ══ Transfer Entries Table ══ -->
        <div class="tr-table-wrap" id="trTableWrap">
            <table class="tr-table">
                <thead>
                    <tr>
                        <th>Sr No</th><th>Mode</th><th>Transfer A/c. Code</th>
                        <th>Transfer A/c. Name</th><th>Amount (&#8377;)</th><th></th>
                    </tr>
                </thead>
                <tbody id="trTbody"></tbody>
                <tfoot>
                    <tr>
                        <td colspan="4">Total Transferred</td>
                        <td id="trTotal">&#8377;0.00</td>
                        <td></td>
                    </tr>
                </tfoot>
            </table>
        </div>

        <!-- ══ Transfer Row Click Detail Panel ══ -->
        <div id="trRowDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">
                    Transfer Account Information
                    <span class="spin" id="spinTrRow" style="display:none;"></span>
                </div>
                <div class="ac-info-grid-4">
                    <div class="ac-fg"><label>Account Code</label>      <input type="text" id="trRowAccCode"    readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>      <input type="text" id="trRowAccName"    readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label>   <input type="text" id="trRowGlCode"     readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label>   <input type="text" id="trRowGlName"     readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>       <input type="text" id="trRowCustId"     readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>    <input type="text" id="trRowLedger"     readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label> <input type="text" id="trRowAvail"      readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="trRowNewLedger"  readonly/></div>
                </div>
            </div>
        </div>

        <!-- ══ Main Account Details Panel (focused on accountCode) ══ -->
        <div id="acDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Account Information</div>
                <div class="ac-info-grid">
                    <div class="ac-fg"><label>GL Account Code</label>        <input type="text" id="glCode"  readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label>        <input type="text" id="glName"  readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>            <input type="text" id="custId"  readonly/></div>
                    <div class="ac-fg"><label>Certificate Number</label>     <input type="text" id="certNo"  readonly/></div>
                    <div class="ac-fg"><label>Member Number</label>          <input type="text" id="memNo"   readonly/></div>
                    <div class="ac-fg"><label>Form No (From &mdash; To)</label><input type="text" id="formNo" readonly/></div>
                </div>
            </div>
        </div>

        <!-- ══ Transfer Account Details Panel (focused on trCode field) ══ -->
        <div id="trDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">
                    Transfer Account Information
                    <span class="spin" id="spinTrDetails" style="display:none;"></span>
                </div>
                <div class="ac-info-grid-4">
                    <div class="ac-fg"><label>Account Code</label>      <input type="text" id="trDispCode"       readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>      <input type="text" id="trDispName"       readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label>   <input type="text" id="trGlCode"         readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label>   <input type="text" id="trGlName"         readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>       <input type="text" id="trCustId"         readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>    <input type="text" id="trLedgerBal"      readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label> <input type="text" id="trAvailBal"       readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="trNewLedgerBal"   readonly/></div>
                </div>
            </div>
        </div>

    </div><!-- /.box -->

    <div class="act-bar">
        <button class="btn-primary" type="button" onclick="doSave()">Save</button>
        <button class="btn-danger"  type="button" onclick="doCancel()">Clear</button>
    </div>

    <!-- ── Confirm Clear Popup ── -->
    <div class="success-overlay" id="clearOverlay">
        <div class="success-modal">
            <div class="success-tick" style="color:#cc2222;">&#9888;</div>
            <div class="success-title">Clear Form?</div>
            <div class="success-info">Are you sure you want to clear?</div>
            <div style="display:flex;gap:14px;margin-top:4px;">
                <button class="btn-ok btn-ok-red"  onclick="confirmClear()">Yes, Clear</button>
                <button class="btn-ok btn-ok-grey" onclick="closeClearPopup()">Cancel</button>
            </div>
        </div>
    </div>

    <!-- ── Lookup Modal ── -->
    <div class="lk-overlay" id="lkOverlay" onclick="if(event.target===this)lkClose()">
        <div class="lk-modal">
            <div class="lk-head">
                <span class="lk-head-title">Select Account</span>
                <span class="lk-head-badge" id="lkBadge">SHARES A/C</span>
                <button class="lk-head-close" onclick="lkClose()">&#10005;</button>
            </div>
            <div class="lk-search-wrap">
                <input class="lk-search-input" id="lkSearchInput" type="text"
                       placeholder="Search by Account Code or Name..." autocomplete="off" oninput="lkOnInput(this.value)"/>
            </div>
            <div class="lk-body">
                <table class="lk-table">
                    <thead><tr><th>Code</th><th>Name</th></tr></thead>
                    <tbody id="lkTbody"><tr><td colspan="2" class="lk-msg">Loading&#8230;</td></tr></tbody>
                </table>
            </div>
            <div class="lk-status" id="lkStatus">Click a row to select.</div>
        </div>
    </div>

    <script>
        var PAGE_URL   = '<%= request.getContextPath() %>/sharesRefund';
        var SEARCH_MIN = 3;
        var WAIT_MS    = 300;

        var _timer = null, _prev = '', _ledgerBal = 0;
        var _maxRefundAmt = 0, _maxShares = 0;
        /* Arrays that mirror the allotment pattern */
        var _payEntries  = [];   /* Cash entries  */
        var _trEntries   = [];   /* Transfer entries */
        var _trLedgerMap = {};   /* code → ledger balance, for new-balance calc */

        /* ═══════════════════════════════════════════════
           PANEL SWITCHING
        ═══════════════════════════════════════════════ */
        function showMainPanel() {
            var hasData = document.getElementById('glCode').value.trim() !== '';
            document.getElementById('acDetails').style.display    = hasData ? 'block' : 'none';
            document.getElementById('trDetails').style.display    = 'none';
            hideTrRowDetails();
        }
        function showTrPanel() {
            var hasData = document.getElementById('trDispCode').value.trim() !== '';
            document.getElementById('trDetails').style.display    = hasData ? 'block' : 'none';
            document.getElementById('acDetails').style.display    = 'none';
            hideTrRowDetails();
        }

        /* ═══════════════════════════════════════════════
           LIVE SEARCH
        ═══════════════════════════════════════════════ */
        function onAcInput(v) {
            if (v !== _prev) { clearAcDetails(); _prev = v; }
            liveSearch(v, 'dropMain', 'main');
        }
        function onTrInput(v) {
            hideTrDetails();
            liveSearch(v, 'dropTr', 'tr');
        }

        function liveSearch(val, dropId, target) {
            clearTimeout(_timer);
            var drop = document.getElementById(dropId);
            if (!val) { drop.classList.remove('on'); return; }
            if (val.length < SEARCH_MIN) {
                drop.innerHTML = '<div class="sr-hint">Type at least ' + SEARCH_MIN + ' digits\u2026</div>';
                drop.classList.add('on'); return;
            }
            drop.innerHTML = '<div class="sr-hint">Searching\u2026</div>';
            drop.classList.add('on');
            var sa = (target === 'tr') ? 'searchTr' : 'search';
            _timer = setTimeout(function() { doSearch(val, dropId, target, sa); }, WAIT_MS);
        }

        function doSearch(term, dropId, target, sa) {
            var drop = document.getElementById(dropId);
            ajaxGet(PAGE_URL + '?action=' + sa + '&term=' + encodeURIComponent(term), function(d) {
                if (d.error) { drop.innerHTML = '<div class="sr-hint">' + xe(d.error) + '</div>'; return; }
                var list = d.accounts || [];
                if (!list.length) { drop.innerHTML = '<div class="sr-hint">No accounts found</div>'; return; }
                drop.innerHTML = '';
                for (var i = 0; i < list.length; i++) {
                    var c = list[i].code || '', a = list[i].name || '';
                    var item = document.createElement('div');
                    item.className = 'sr-item';
                    item.innerHTML = '<div class="sr-code">' + hlMatch(c, term) + '</div>'
                                   + '<div class="sr-name">' + xe(a) + '</div>';
                    item.addEventListener('click', (function(code, name) {
                        return function() { pick(code, name, target); };
                    })(c, a));
                    drop.appendChild(item);
                }
            }, function() { drop.innerHTML = '<div class="sr-hint">Error</div>'; });
        }

        function hlMatch(text, search) {
            var idx = text.toLowerCase().indexOf(search.toLowerCase());
            if (idx === -1) return xe(text);
            return xe(text.substring(0, idx))
                 + '<span class="hl">' + xe(text.substring(idx, idx + search.length)) + '</span>'
                 + xe(text.substring(idx + search.length));
        }

        function pick(code, name, target) {
            if (target === 'tr') {
                document.getElementById('dropTr').classList.remove('on');
                document.getElementById('trCode').value = code;
                sv('trName', name);
                fetchTrDetails(code);
            } else {
                document.getElementById('dropMain').classList.remove('on');
                document.getElementById('accountCode').value = code;
                sv('accountName', name);
                _prev = code;
                fetchAc(code);
            }
        }

        function triggerFetch() {
            var code = document.getElementById('accountCode').value.trim();
            if (!code) return;
            document.getElementById('dropMain').classList.remove('on');
            fetchAc(code);
        }
        function triggerTrFetch() {
            var code = document.getElementById('trCode').value.trim();
            if (!code) return;
            document.getElementById('dropTr').classList.remove('on');
            fetchTrDetails(code);
        }

        /* ═══════════════════════════════════════════════
           FETCH MAIN ACCOUNT
        ═══════════════════════════════════════════════ */
        function fetchAc(code) {
            showSpin('spinMain');
            ajaxGet(PAGE_URL + '?action=get&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinMain');
                if (d && d.ok === true) {
                    _ledgerBal = parseFloat(d.lb) || 0;
                    sv('accountName', d.n  || '');
                    sv('glCode',      d.gc || '');
                    sv('glName',      d.gn || '');
                    sv('custId',      d.ci || '');
                    document.getElementById('trDetails').style.display = 'none';
                    document.getElementById('acDetails').style.display = 'block';
                    hideTrRowDetails();
                    fetchShares(code);
                } else {
                    clearAcDetails();
                    alert(d && d.error ? d.error : 'Account not found.');
                }
            }, function() { hideSpin('spinMain'); clearAcDetails(); });
        }

        /* ═══════════════════════════════════════════════
           FETCH TRANSFER ACCOUNT DETAILS
           Shows in the trDetails panel (focused state)
           AND pre-calculates new ledger balance
        ═══════════════════════════════════════════════ */
        function fetchTrDetails(code) {
            if (!code) { hideTrDetails(); return; }
            showSpin('spinTrDetails');
            ajaxGet(PAGE_URL + '?action=getTr&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinTrDetails');
                if (d && d.ok === true) {
                    var lb = parseFloat(d.lb) || 0;
                    _trLedgerMap[code] = lb;

                    sv('trName',        d.n  || '');
                    sv('trDispCode',    code);
                    sv('trDispName',    d.n  || '');
                    sv('trGlCode',      d.gc || '');
                    sv('trGlName',      d.gn || '');
                    sv('trCustId',      d.ci || '');
                    svBal('trLedgerBal',  d.lb);
                    svBal('trAvailBal',   d.ab);

                    /* Refund ADDS to transfer account balance */
                    var refundAmt = parseFloat(document.getElementById('payAmt').value) || 0;
                    svBal('trNewLedgerBal', (lb + refundAmt).toFixed(2));

                    document.getElementById('acDetails').style.display = 'none';
                    document.getElementById('trDetails').style.display = 'block';
                    hideTrRowDetails();
                } else {
                    clearTrDetails();
                    alert(d && d.error ? d.error : 'Account not found.');
                }
            }, function() { hideSpin('spinTrDetails'); clearTrDetails(); });
        }

        /* Hides the focused transfer panel and clears it */
        function hideTrDetails() {
            document.getElementById('trDetails').style.display = 'none';
            ['trDispCode','trDispName','trGlCode','trGlName','trCustId','trLedgerBal','trAvailBal','trNewLedgerBal'].forEach(function(id) {
                var el = document.getElementById(id);
                if (el) { el.value = ''; el.classList.remove('bal-pos','bal-neg'); }
            });
        }

        /* ═══════════════════════════════════════════════
           FETCH SHARES
        ═══════════════════════════════════════════════ */
        function fetchShares(code) {
            showSpin('spinMain');
            ajaxGet(PAGE_URL + '?action=getShares&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinMain');
                if (d && d.ok === true) {
                    sv('totalNoShares',  d.ts  != null ? String(d.ts) : '0');
                    sv('totalFaceValue', fmtAmt(d.tfv));
                    sv('totalAmount',    fmtAmt(d.ta));
                    sv('certNo',  d.certNo || '');
                    sv('memNo',   d.memNo  || '');
                    sv('formNo',  (d.formNo || '0') + ' \u2014 ' + (d.toNo || '0'));
                    _maxRefundAmt = parseFloat(d.ta)  || 0;
                    _maxShares    = parseInt(d.ts, 10) || 0;
                    /* Pre-fill amount with total refundable */
                    var payEl = document.getElementById('payAmt');
                    if (payEl && _maxRefundAmt > 0) {
                        payEl.value = _maxRefundAmt.toFixed(2);
                        payEl.max   = _maxRefundAmt;
                    }
                } else {
                    clearShareFields();
                }
            }, function() { hideSpin('spinMain'); clearShareFields(); });
        }

        /* ═══════════════════════════════════════════════
           MODE OF PAYMENT
        ═══════════════════════════════════════════════ */
        function onModeChange() {
            var isT = document.getElementById('modeTransfer').checked;
            document.getElementById('trCode').disabled = !isT;
            document.getElementById('btnTr').disabled  = !isT;
            document.getElementById('lblTransfer').classList.toggle('on',  isT);
            document.getElementById('lblCash').classList.toggle('on', !isT);
            if (!isT) {
                sv('trCode', ''); sv('trName', '');
                document.getElementById('dropTr').classList.remove('on');
                hideTrDetails();
                clearTrEntries();
                showMainPanel();
            } else {
                clearPayments();
            }
        }

        /* ═══════════════════════════════════════════════
           ADD PAYMENT / TRANSFER ENTRY
        ═══════════════════════════════════════════════ */
        function doAddPayment() {
            var isT      = document.getElementById('modeTransfer').checked;
            var payAmt   = parseFloat(document.getElementById('payAmt').value);
            var maxAmt   = _maxRefundAmt;

            if (isNaN(payAmt) || payAmt <= 0) {
                alert('Please enter a valid amount greater than 0.');
                return;
            }
            if (maxAmt > 0 && payAmt > maxAmt + 0.001) {
                alert('Refund amount \u20B9' + payAmt.toFixed(2) + ' cannot exceed total share amount \u20B9' + maxAmt.toFixed(2));
                document.getElementById('payAmt').value = maxAmt.toFixed(2);
                return;
            }

            if (isT) {
                /* ── Transfer entry ── */
                var trCode = document.getElementById('trCode').value.trim();
                var trName = document.getElementById('trName').value.trim();
                if (!trCode) { alert('Please select a Transfer Account Code.'); return; }

                /* Prevent same-account transfer */
                var mainCode = document.getElementById('accountCode').value.trim();
                if (trCode === mainCode) { alert('Transfer account cannot be the same as the main account.'); return; }

                /* Prevent duplicate code */
                for (var i = 0; i < _trEntries.length; i++) {
                    if (_trEntries[i].code === trCode) { alert('This transfer account is already added.'); return; }
                }

                /* Total already queued + new must not exceed max */
                var already = _trEntries.reduce(function(s, e) { return s + e.amount; }, 0);
                if (already + payAmt > maxAmt + 0.001) {
                    alert('Total transfer amount cannot exceed \u20B9' + maxAmt.toFixed(2));
                    return;
                }

                _trEntries.push({ code: trCode, name: trName, amount: payAmt });

                /* Reset transfer input row */
                sv('trCode', ''); sv('trName', '');
                document.getElementById('payAmt').value = '';
                document.getElementById('dropTr').classList.remove('on');
                hideTrDetails();
                hideTrRowDetails();
                renderTrTable();
                /* Keep acDetails hidden while transfer table is visible */
                document.getElementById('acDetails').style.display = 'none';

            } else {
                /* ── Cash entry (only one allowed, must equal total) ── */
                if (_payEntries.length > 0) { alert('Cash entry already added.'); return; }
                if (Math.abs(payAmt - maxAmt) > 0.001 && maxAmt > 0) {
                    alert('Cash refund amount must equal total share amount \u20B9' + maxAmt.toFixed(2));
                    return;
                }
                var particular = document.getElementById('particular').value.trim() || 'By Cash';
                _payEntries.push({ mode: 'Cash', amount: payAmt, particular: particular });
                renderPayTable();
                document.getElementById('acDetails').style.display = 'none';
            }
        }

        /* ═══════════════════════════════════════════════
           RENDER CASH TABLE
        ═══════════════════════════════════════════════ */
        function renderPayTable() {
            var wrap  = document.getElementById('payTableWrap');
            var tbody = document.getElementById('payTbody');
            var total = document.getElementById('payTotal');
            if (_payEntries.length === 0) {
                wrap.classList.remove('show');
                total.textContent = '\u20b90.00';
                return;
            }
            wrap.classList.add('show');
            var html = '', sum = 0;
            for (var i = 0; i < _payEntries.length; i++) {
                var e = _payEntries[i]; sum += e.amount;
                html += '<tr>'
                      + '<td>' + (i + 1) + '</td>'
                      + '<td>CSCR</td>'
                      + '<td>\u20b9' + e.amount.toFixed(2) + '</td>'
                      + '<td>' + xe(e.particular) + '</td>'
                      + '<td><button class="btn-remove" onclick="removePayment(' + i + ')">\u2715 Remove</button></td>'
                      + '</tr>';
            }
            tbody.innerHTML = html;
            total.textContent = '\u20b9' + sum.toFixed(2);
        }

        /* ═══════════════════════════════════════════════
           RENDER TRANSFER TABLE
        ═══════════════════════════════════════════════ */
        function renderTrTable() {
            var wrap  = document.getElementById('trTableWrap');
            var tbody = document.getElementById('trTbody');
            var total = document.getElementById('trTotal');
            if (_trEntries.length === 0) {
                wrap.classList.remove('show');
                total.textContent = '\u20b90.00';
                hideTrRowDetails();
                return;
            }
            wrap.classList.add('show');
            tbody.innerHTML = '';
            var sum = 0;
            for (var i = 0; i < _trEntries.length; i++) {
                var e = _trEntries[i]; sum += e.amount;
                var tr = document.createElement('tr');
                tr.setAttribute('data-code', e.code);

                /* Clickable cells → show row detail panel */
                var clickCells = [ String(i + 1), 'TRCR', xe(e.code), xe(e.name) ];
                for (var j = 0; j < clickCells.length; j++) {
                    var td = document.createElement('td');
                    td.innerHTML = clickCells[j];
                    td.style.cursor = 'pointer';
                    td.addEventListener('click', (function(code, amt) {
                        return function() { showTrRowDetails(code, amt); };
                    })(e.code, e.amount));
                    tr.appendChild(td);
                }

                var tdAmt = document.createElement('td');
                tdAmt.textContent = '\u20b9' + e.amount.toFixed(2);
                tr.appendChild(tdAmt);

                var tdBtn = document.createElement('td');
                var btn   = document.createElement('button');
                btn.className   = 'btn-remove';
                btn.textContent = '\u2715 Remove';
                btn.addEventListener('click', (function(idx) {
                    return function() { removeTrEntry(idx); };
                })(i));
                tdBtn.appendChild(btn);
                tr.appendChild(tdBtn);

                tbody.appendChild(tr);
            }
            total.textContent = '\u20b9' + sum.toFixed(2);
        }

        /* ═══════════════════════════════════════════════
           ROW CLICK → show trRowDetails panel
           Refund ADDS to the transfer account balance
        ═══════════════════════════════════════════════ */
        function showTrRowDetails(code, rowAmt) {
            /* Hide the focused-field trDetails panel while showing row detail */
            document.getElementById('trDetails').style.display = 'none';
            document.getElementById('acDetails').style.display = 'none';

            showSpin('spinTrRow');
            ajaxGet(PAGE_URL + '?action=getTr&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinTrRow');
                if (d && d.ok === true) {
                    var lb = parseFloat(d.lb) || 0;
                    _trLedgerMap[code] = lb;

                    document.getElementById('trRowAccCode').value  = code;
                    document.getElementById('trRowAccName').value  = d.n  || '';
                    document.getElementById('trRowGlCode').value   = d.gc || '';
                    document.getElementById('trRowGlName').value   = d.gn || '';
                    document.getElementById('trRowCustId').value   = d.ci || '';
                    svBal('trRowLedger',    d.lb);
                    svBal('trRowAvail',     d.ab);
                    /* Refund → balance INCREASES */
                    svBal('trRowNewLedger', (lb + rowAmt).toFixed(2));

                    document.getElementById('trRowDetails').style.display = 'block';
                }
            }, function() { hideSpin('spinTrRow'); });
        }

        function hideTrRowDetails() {
            document.getElementById('trRowDetails').style.display = 'none';
            ['trRowAccCode','trRowAccName','trRowGlCode','trRowGlName',
             'trRowCustId','trRowLedger','trRowAvail','trRowNewLedger'].forEach(function(id) {
                var el = document.getElementById(id);
                if (el) { el.value = ''; el.classList.remove('bal-pos','bal-neg'); }
            });
        }

        /* ═══════════════════════════════════════════════
           REMOVE ENTRIES
        ═══════════════════════════════════════════════ */
        function removeTrEntry(idx) {
            _trEntries.splice(idx, 1);
            renderTrTable();
            hideTrRowDetails();
            if (_trEntries.length === 0) {
                document.getElementById('acDetails').style.display = 'block';
            }
        }
        function clearTrEntries() {
            _trEntries   = [];
            _trLedgerMap = {};
            renderTrTable();
            hideTrRowDetails();
            hideTrDetails();
        }

        function removePayment(idx) {
            _payEntries.splice(idx, 1);
            renderPayTable();
            document.getElementById('acDetails').style.display = 'block';
        }
        function clearPayments() { _payEntries = []; renderPayTable(); }

        /* ═══════════════════════════════════════════════
           SAVE
        ═══════════════════════════════════════════════ */
        function doSave() {
            var acCode   = document.getElementById('accountCode').value.trim();
            if (!acCode) { alert('Please select an Account Code.'); return; }

            var meetDate = document.getElementById('meetDate').value.trim();
            if (!meetDate) { alert('Please select a Meeting Date.'); return; }

            var isT      = document.getElementById('modeTransfer').checked;
            var maxAmt   = _maxRefundAmt;

            if (isT) {
                var t = _trEntries.reduce(function(s, e) { return s + e.amount; }, 0);
                if (_trEntries.length === 0 || (maxAmt > 0 && Math.abs(t - maxAmt) >= 0.001)) {
                    alert('Please add transfer entries that equal the total refund amount \u20B9' + maxAmt.toFixed(2));
                    return;
                }
            } else {
                var p = _payEntries.reduce(function(s, e) { return s + e.amount; }, 0);
                if (_payEntries.length === 0 || (maxAmt > 0 && Math.abs(p - maxAmt) >= 0.001)) {
                    alert('Please add a cash payment entry equal to the total refund amount \u20B9' + maxAmt.toFixed(2));
                    return;
                }
            }

            var mode      = isT ? 'Transfer' : 'Cash';
            var particular = document.getElementById('particular').value.trim();
            if (!particular) particular = isT ? 'By Transfer' : 'By Cash';

            var trCodes = '[]';
            if (isT && _trEntries.length > 0) {
                var arr = [];
                for (var i = 0; i < _trEntries.length; i++) {
                    arr.push('{"code":"' + xq(_trEntries[i].code) + '","amount":' + _trEntries[i].amount + '}');
                }
                trCodes = '[' + arr.join(',') + ']';
            }

            var body = 'accountCode=' + encodeURIComponent(acCode)
                     + '&meetDate='   + encodeURIComponent(meetDate)
                     + '&mode='       + encodeURIComponent(mode)
                     + '&trCodes='    + encodeURIComponent(trCodes)
                     + '&particular=' + encodeURIComponent(particular);

            var btnSave = document.querySelector('.btn-primary');
            btnSave.disabled    = true;
            btnSave.textContent = 'Saving\u2026';

            ajaxPost(PAGE_URL + '?action=save', body, function(d) {
                btnSave.disabled    = false;
                btnSave.textContent = 'Save';
                if (d && d.ok === true) {
                    alert('Shares refund processed successfully.');
                    clearForm();
                } else {
                    alert((d && d.error) ? d.error : 'Save failed.');
                }
            }, function() {
                btnSave.disabled    = false;
                btnSave.textContent = 'Save';
                alert('Network error. Please try again.');
            });
        }

        /* ═══════════════════════════════════════════════
           CLEAR / CANCEL
        ═══════════════════════════════════════════════ */
        function doCancel()        { document.getElementById('clearOverlay').classList.add('open'); }
        function closeClearPopup() { document.getElementById('clearOverlay').classList.remove('open'); }
        function confirmClear()    { closeClearPopup(); clearForm(); }

        function clearForm() {
            clearAcDetails();
            ['accountCode','trCode','trName','payAmt','particular','meetDate'].forEach(function(id) {
                var el = document.getElementById(id); if (el) el.value = '';
            });
            document.getElementById('dropMain').classList.remove('on');
            document.getElementById('dropTr').classList.remove('on');
            document.getElementById('modeCash').checked = true;
            onModeChange();
            _prev = ''; _ledgerBal = 0; _maxRefundAmt = 0; _maxShares = 0;
        }

        function clearAcDetails() {
            document.getElementById('acDetails').style.display = 'none';
            hideTrDetails();
            hideTrRowDetails();
            _ledgerBal = 0; _maxRefundAmt = 0; _maxShares = 0;
            sv('accountName', '');
            ['glCode','glName','custId'].forEach(function(id) {
                var el = document.getElementById(id);
                if (el) { el.value = ''; el.classList.remove('bal-pos','bal-neg'); }
            });
            clearShareFields();
            clearTrEntries();
            clearPayments();
        }

        function clearTrDetails() { hideTrDetails(); }

        function clearShareFields() {
            sv('totalNoShares','0'); sv('totalFaceValue','0.00'); sv('totalAmount','0.00');
            sv('certNo',''); sv('memNo',''); sv('formNo','');
            var payEl = document.getElementById('payAmt');
            if (payEl) { payEl.value = ''; payEl.removeAttribute('max'); }
            _maxRefundAmt = 0; _maxShares = 0;
        }

        /* ═══════════════════════════════════════════════
           LOOKUP MODAL
        ═══════════════════════════════════════════════ */
        var _lkTarget = 'main', _lkTimer = null;

        function openLookup(target) {
            _lkTarget = target;
            document.getElementById('lkSearchInput').value = '';
            document.getElementById('lkTbody').innerHTML   = '<tr><td colspan="2" class="lk-msg">Loading&#8230;</td></tr>';
            document.getElementById('lkStatus').textContent = 'Click a row to select.';
            document.getElementById('lkBadge').textContent  = (target === 'tr') ? 'SAVINGS / CURRENT' : 'SHARES A/C';
            document.getElementById('lkOverlay').classList.add('open');
            setTimeout(function() { document.getElementById('lkSearchInput').focus(); }, 80);
            lkLoad('');
        }
        function lkClose()        { document.getElementById('lkOverlay').classList.remove('open'); }
        function lkOnInput(val)   { clearTimeout(_lkTimer); _lkTimer = setTimeout(function() { lkLoad(val.trim()); }, 300); }

        function lkLoad(term) {
            var tbody = document.getElementById('lkTbody');
            tbody.innerHTML = '<tr><td colspan="2" class="lk-msg">Searching&#8230;</td></tr>';
            var act = (_lkTarget === 'tr') ? 'searchTr' : 'search';
            ajaxGet(PAGE_URL + '?action=' + act + '&term=' + encodeURIComponent(term), function(d) {
                if (d.error) { tbody.innerHTML = '<tr><td colspan="2" class="lk-err">' + xe(d.error) + '</td></tr>'; return; }
                var list = d.accounts || [];
                if (!list.length) { tbody.innerHTML = '<tr><td colspan="2" class="lk-msg">No accounts found.</td></tr>'; return; }
                tbody.innerHTML = '';
                for (var i = 0; i < list.length; i++) {
                    var c = list[i].code || '', n = list[i].name || '';
                    var tr = document.createElement('tr');
                    var td1 = document.createElement('td'); td1.innerHTML = lkHl(c, term);
                    var td2 = document.createElement('td'); td2.innerHTML = lkHl(n, term);
                    tr.appendChild(td1); tr.appendChild(td2);
                    tr.addEventListener('click', (function(code, name) {
                        return function() { lkPick(code, name); };
                    })(c, n));
                    tbody.appendChild(tr);
                }
                document.getElementById('lkStatus').textContent = list.length + ' result(s). Click a row to select.';
            }, function() { tbody.innerHTML = '<tr><td colspan="2" class="lk-err">Network error.</td></tr>'; });
        }

        function lkPick(code, name) {
            lkClose();
            if (_lkTarget === 'tr') {
                document.getElementById('trCode').value = code;
                sv('trName', name);
                fetchTrDetails(code);
            } else {
                document.getElementById('accountCode').value = code;
                sv('accountName', name);
                _prev = code;
                fetchAc(code);
            }
        }

        function lkHl(text, search) {
            if (!search) return xe(text);
            var idx = text.toLowerCase().indexOf(search.toLowerCase());
            if (idx === -1) return xe(text);
            return xe(text.substring(0, idx))
                 + '<span class="lk-hl">' + xe(text.substring(idx, idx + search.length)) + '</span>'
                 + xe(text.substring(idx + search.length));
        }

        /* ═══════════════════════════════════════════════
           UTILITY
        ═══════════════════════════════════════════════ */
        function sv(id, val)    { var el = document.getElementById(id); if (el) el.value = val || ''; }
        function showSpin(id)   { var el = document.getElementById(id); if (el) el.style.display = 'inline-block'; }
        function hideSpin(id)   { var el = document.getElementById(id); if (el) el.style.display = 'none'; }

        function svBal(id, val) {
            var el = document.getElementById(id); if (!el) return;
            var n  = parseFloat(val);
            el.value = isNaN(n) ? (val || '') : n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            el.classList.remove('bal-pos','bal-neg');
            if (!isNaN(n)) el.classList.add(n >= 0 ? 'bal-pos' : 'bal-neg');
        }

        function fmtAmt(val) {
            var n = parseFloat(val);
            return isNaN(n) ? '0.00' : n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        }

        function ajaxGet(url, onSuccess, onError) {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                if (xhr.status !== 200) { if (onError) onError(); return; }
                var d;
                try { var raw = xhr.responseText; var si = raw.indexOf('{'); if (si > 0) raw = raw.substring(si); d = JSON.parse(raw.trim()); }
                catch(e) { if (onError) onError(); return; }
                onSuccess(d);
            };
            xhr.send();
        }

        function ajaxPost(url, body, onSuccess, onError) {
            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return;
                if (xhr.status !== 200) { if (onError) onError(); return; }
                var d;
                try { var raw = xhr.responseText; var si = raw.indexOf('{'); if (si > 0) raw = raw.substring(si); d = JSON.parse(raw.trim()); }
                catch(e) { if (onError) onError(); return; }
                onSuccess(d);
            };
            xhr.send(body);
        }

        function xe(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
        function xq(s) { return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

        /* ═══════════════════════════════════════════════
           INIT
        ═══════════════════════════════════════════════ */
        document.addEventListener('DOMContentLoaded', function() {
            document.addEventListener('click', function(e) {
                if (!e.target.closest || !e.target.closest('.sw')) {
                    document.getElementById('dropMain').classList.remove('on');
                    document.getElementById('dropTr').classList.remove('on');
                }
            });
            document.addEventListener('keydown', function(e) { if (e.key === 'Escape') lkClose(); });
        });
    </script>
</body>
</html>
