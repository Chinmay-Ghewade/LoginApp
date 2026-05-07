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
    <link rel="stylesheet" href="../css/shares.css">
    <style>
        /* ── Refund-specific layout ── */
        .shared-grid { display: grid; grid-template-columns: 22% 33% 45%; }
        .cell { padding: 12px 20px 20px; border-right: 1.5px dashed #dcdcf0; display: flex; flex-direction: column; gap: 9px; }
        .cell:last-child { border-right: none; }
        .titles-row { padding-top: 16px; }
        .titles-row .cell { padding-bottom: 0; }
        .cell-inner { display: flex; gap: 8px; align-items: flex-end; }
        .cell-inner .fg { flex: 1; min-width: 0; }

        /* ── Refund uses 3-col grid for main account info ── */
        .ac-info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px 16px; margin-top: 4px; }
        /* ── 4-col variant used for transfer account panels ── */
        .ac-info-grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px 16px; margin-top: 4px; }

        /* ── Show/hide helpers ── */
        #acDetails    { display: none; margin: 24px 16px 0; }
        #trDetails    { display: none; margin: 24px 16px 0; }
        #trRowDetails { display: none; margin: 24px 16px 0; }

        /* ── Table margin override for refund ── */
        .tr-table-wrap { margin: 20px 16px 0; }

        /* ── Fieldset replaces .box — legend sits on the border ── */
        fieldset.box {
            border: 1.5px solid #c8c8e8;
            border-radius: 10px;
            padding: 0 0 4px 0;
            background: #fff;
        }
        fieldset.box legend {
            font-size: 15px;
            font-weight: 700;
            color: #2d2d7a;
            letter-spacing: 0.04em;
            padding: 0 10px;
            margin-left: 12px;
            line-height: 1.2;
        }

        /* ── Section title style matching Allotment uppercase headers ── */
        .mod-title {
            font-size: 11px;
            font-weight: 800;
            color: #2d2d7a;
            letter-spacing: 0.09em;
            text-transform: uppercase;
        }
    </style>
</head>
<body>
    <div class="page-title">Shares Refund</div>

    <fieldset class="box">
        <legend>Transaction Details</legend>

        <div class="shared-grid titles-row">
                <div class="cell"><span class="mod-title">Account Info</span></div>
                <div class="cell"><span class="mod-title">Share Details</span></div>
                <div class="cell"><span class="mod-title">Transaction Details</span></div>
            </div>

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
                        <span class="field-error-msg" id="errAccountCode">Account code is required</span>
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
                    <div class="cell-inner" style="align-items:flex-start;">
                        <div class="fg">
                            <label>Mode of Payment</label>
                            <div class="rg">
                                <label id="lblTransfer"><input type="radio" name="mop" value="Transfer" id="modeTransfer" onchange="onModeChange()"/>Transfer</label>
                                <label id="lblCash" class="on"><input type="radio" name="mop" value="Cash" id="modeCash" onchange="onModeChange()" checked/>Cash</label>
                            </div>
                            <span class="field-error-msg" style="visibility:hidden;">&#8203;</span>
                        </div>
                        <div class="fg">
                            <label>Amount</label>
                            <div class="ib" id="payAmtWrap">
                                <input type="number" id="payAmt" placeholder="0.00" min="0" step="0.01"/>
                                <button class="btn-add" id="btnAdd" type="button" onclick="doAddPayment()" disabled>Add</button>
                            </div>
                            <span class="hint-xs">Click on add for payment entry</span>
                            <span class="field-error-msg" id="errPayment">Please add a payment entry</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="shared-grid">
                <div class="cell">
                    <div class="fg"><label>Account Name</label><input type="text" id="accountName" readonly placeholder="&mdash;"/></div>
                </div>
                <div class="cell">
                    <div class="cell-inner">
                        <div class="fg">
                            <label>Particular</label>
                            <input type="text" id="particular" placeholder="Enter particular"
                                   oninput="clearFieldError('particular','errParticular');"/>
                            <span class="field-error-msg" id="errParticular">Particular is required</span>
                        </div>
                         <div class="fg">
                            <label>Meeting Date</label>
                            <input type="date" id="meetDate" oninput="clearFieldError('meetDate','errMeetDate');"/>
                            <span class="field-error-msg" id="errMeetDate">Meeting date is required</span>
                        </div>
                    </div>
                </div>
                <div class="cell" id="trCell">
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

        <div class="tr-table-wrap" id="payTableWrap">
            <table class="tr-table">
                <thead><tr><th>Sr No</th><th>Mode</th><th>Amount (&#8377;)</th><th>Particular</th><th></th></tr></thead>
                <tbody id="payTbody"></tbody>
                <tfoot><tr><td colspan="2">Total Refunded</td><td id="payTotal">&#8377;0.00</td><td colspan="2"></td></tr></tfoot>
            </table>
        </div>

        <div class="tr-table-wrap" id="trTableWrap">
            <table class="tr-table">
                <thead><tr><th>Sr No</th><th>Mode</th><th>Transfer A/c. Code</th><th>Transfer A/c. Name</th><th>Amount (&#8377;)</th><th></th></tr></thead>
                <tbody id="trTbody"></tbody>
                <tfoot><tr><td colspan="4">Total Transferred</td><td id="trTotal">&#8377;0.00</td><td></td></tr></tfoot>
            </table>
        </div>

        <div id="trRowDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Transfer Account Information <span class="spin" id="spinTrRow" style="display:none;"></span></div>
                <div class="ac-info-grid-4">
                    <div class="ac-fg"><label>Account Code</label>      <input type="text" id="trRowAccCode"   readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>      <input type="text" id="trRowAccName"   readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label>   <input type="text" id="trRowGlCode"    readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label>   <input type="text" id="trRowGlName"    readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>       <input type="text" id="trRowCustId"    readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>    <input type="text" id="trRowLedger"    readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label> <input type="text" id="trRowAvail"     readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="trRowNewLedger" readonly/></div>
                </div>
            </div>
        </div>

        <div id="acDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Account Information</div>
                <div class="ac-info-grid">
                    <div class="ac-fg"><label>GL Account Code</label>             <input type="text" id="glCode"  readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label>             <input type="text" id="glName"  readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>                 <input type="text" id="custId"  readonly/></div>
                    <div class="ac-fg"><label>Certificate Number</label>          <input type="text" id="certNo"  readonly/></div>
                    <div class="ac-fg"><label>Member Number</label>               <input type="text" id="memNo"   readonly/></div>
                    <div class="ac-fg"><label>Form No (From &mdash; To)</label>   <input type="text" id="formNo"  readonly/></div>
                </div>
            </div>
        </div>

        <div id="trDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Transfer Account Information <span class="spin" id="spinTrDetails" style="display:none;"></span></div>
                <div class="ac-info-grid-4">
                    <div class="ac-fg"><label>Account Code</label>      <input type="text" id="trDispCode"     readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>      <input type="text" id="trDispName"     readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label>   <input type="text" id="trGlCode"       readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label>   <input type="text" id="trGlName"       readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>       <input type="text" id="trCustId"       readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>    <input type="text" id="trLedgerBal"    readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label> <input type="text" id="trAvailBal"     readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="trNewLedgerBal" readonly/></div>
                </div>
            </div>
        </div><!-- /#trDetails -->

    </fieldset><!-- /.box (fieldset) -->

    <div class="act-bar">
        <button class="btn-primary" id="btnSave" type="button" onclick="doSave()" disabled>Save</button>
        <button class="btn-danger"  type="button" onclick="doCancel()">Clear</button>
    </div>

    <div class="success-overlay" id="successOverlay">
        <div class="success-modal">
            <div class="success-tick" style="color:#22aa55;">&#10003;</div>
            <div class="success-title">Shares Refund Processed!</div>
            <div class="success-info">Scroll No &nbsp;: &nbsp;<strong id="sc-scrollNo">&mdash;</strong></div>
            <button class="btn-ok" onclick="closeSuccess()">OK</button>
        </div>
    </div>

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
                    <thead><tr><th>Code</th><th>Name</th><th>Product</th></tr></thead>
                    <tbody id="lkTbody"><tr><td colspan="3" class="lk-msg">Loading&#8230;</td></tr></tbody>
                </table>
            </div>
            <div class="lk-status" id="lkStatus">Click a row to select.</div>
        </div>
    </div>

    <div class="toast-wrap" id="toastWrap"></div>

    <script>
        var PAGE_URL   = '<%= request.getContextPath() %>/sharesRefund';
        var SEARCH_MIN = 3;
        var WAIT_MS    = 300;

        var _timer = null, _prev = '', _ledgerBal = 0;
        var _maxRefundAmt = 0, _maxShares = 0;
        var _payEntries = [], _trEntries = [], _trLedgerMap = {};

        /* ── Shake helper ── */
        function shakeEl(id) {
            var el = document.getElementById(id);
            if (!el) return;
            el.classList.remove('shake');
            void el.offsetWidth;
            el.classList.add('shake');
            el.addEventListener('animationend', function() { el.classList.remove('shake'); }, { once: true });
        }

        /* ── Button state manager (mirrors sharesAllotment) ── */
        function refreshButtonStates() {
            var maxAmt = _maxRefundAmt;
            var isT    = document.getElementById('modeTransfer').checked;

            var paidTotal = 0;
            if (isT) {
                paidTotal = _trEntries.reduce(function(s, e) { return s + e.amount; }, 0);
            } else {
                paidTotal = _payEntries.reduce(function(s, e) { return s + e.amount; }, 0);
            }

            var isMatched = maxAmt > 0 && Math.abs(paidTotal - maxAmt) < 0.001;
            var canAdd    = maxAmt > 0 && !isMatched;

            var btnAdd  = document.getElementById('btnAdd');
            var btnSave = document.getElementById('btnSave');

            if (btnAdd)  btnAdd.disabled  = !canAdd;
            if (btnSave) btnSave.disabled = !isMatched;

            // Clear payment error hint once matched
            if (isMatched) {
                var pm = document.getElementById('errPayment');
                if (pm) pm.classList.remove('show');
            }
        }

        /*
         * positionDropTr — dynamically aligns #dropTr's RIGHT edge to the
         * RIGHT edge of #trCell, so the dropdown never overflows the page.
         */
        function positionDropTr() {
            var drop     = document.getElementById('dropTr');
            var sw       = document.getElementById('trCode').closest('.sw');
            var cell     = document.getElementById('trCell');
            var dropW    = 620;
            var swLeft    = sw.getBoundingClientRect().left;
            var cellRight = cell.getBoundingClientRect().right;
            var leftOffset = cellRight - swLeft - dropW;
            drop.style.left  = leftOffset + 'px';
            drop.style.right = 'auto';
        }

        function showToast(msg, duration) {
            duration = duration || 3500;
            var wrap = document.getElementById('toastWrap');
            var t = document.createElement('div');
            t.className = 'toast';
            t.innerHTML = '<div class="toast-icon">i</div><div class="toast-msg">' + xe(msg) + '</div><button class="toast-close" onclick="this.parentNode.remove()">&#215;</button>';
            wrap.appendChild(t);
            setTimeout(function() { if (t.parentNode) t.remove(); }, duration);
        }

        function setFieldError(inputId, msgId) {
            var el = document.getElementById(inputId);
            var mg = document.getElementById(msgId);
            if (el) el.classList.add('field-error');
            if (mg) mg.classList.add('show');
        }
        function clearFieldError(inputId, msgId) {
            var el = document.getElementById(inputId);
            var mg = document.getElementById(msgId);
            if (el) el.classList.remove('field-error');
            if (mg) mg.classList.remove('show');
        }
        function clearAllErrors() {
            [['accountCode','errAccountCode'],['meetDate','errMeetDate'],['particular','errParticular']].forEach(function(p){ clearFieldError(p[0],p[1]); });
            var pm = document.getElementById('errPayment');
            if (pm) pm.classList.remove('show');
        }

        function showMainPanel() {
            var hasData = document.getElementById('glCode').value.trim() !== '';
            document.getElementById('acDetails').style.display = hasData ? 'block' : 'none';
            document.getElementById('trDetails').style.display = 'none';
            hideTrRowDetails();
        }
        function showTrPanel() {
            var hasData = document.getElementById('trDispCode').value.trim() !== '';
            document.getElementById('trDetails').style.display = hasData ? 'block' : 'none';
            document.getElementById('acDetails').style.display = 'none';
            hideTrRowDetails();
        }

        function onAcInput(v) { clearFieldError('accountCode','errAccountCode'); if(v!==_prev){clearAcDetails();_prev=v;} liveSearch(v,'dropMain','main'); }
        function onTrInput(v) { hideTrDetails(); liveSearch(v,'dropTr','tr'); }

        function liveSearch(val, dropId, target) {
            clearTimeout(_timer);
            var drop = document.getElementById(dropId);
            if (!val) { drop.classList.remove('on'); return; }
            if (dropId === 'dropTr') positionDropTr();
            if (val.length < SEARCH_MIN) { drop.innerHTML='<div class="sr-hint">Type at least '+SEARCH_MIN+' digits\u2026</div>'; drop.classList.add('on'); return; }
            drop.innerHTML = '<div class="sr-hint">Searching\u2026</div>';
            drop.classList.add('on');
            var sa = (target==='tr') ? 'searchTr' : 'search';
            _timer = setTimeout(function(){ doSearch(val,dropId,target,sa); }, WAIT_MS);
        }

        function doSearch(term, dropId, target, sa) {
            var drop = document.getElementById(dropId);
            ajaxGet(PAGE_URL+'?action='+sa+'&term='+encodeURIComponent(term), function(d) {
                if (d.error) { drop.innerHTML='<div class="sr-hint">'+xe(d.error)+'</div>'; return; }
                var list = d.accounts || [];
                if (!list.length) { drop.innerHTML='<div class="sr-hint">No accounts found</div>'; return; }
                drop.innerHTML = '';
                for (var i=0; i<list.length; i++) {
                    var c=list[i].code||'', a=list[i].name||'', p=list[i].product||'';
                    var item = document.createElement('div');
                    item.className = 'sr-item';
                    item.innerHTML = '<span class="sr-code">'+hlMatch(c,term)+'</span>'
                                   + '<span class="sr-name">'+xe(a)+'</span>'
                                   + '<span class="sr-prod">'+xe(p)+'</span>';
                    item.addEventListener('click', (function(code,name){ return function(){ pick(code,name,target); }; })(c,a));
                    drop.appendChild(item);
                }
            }, function(){ drop.innerHTML='<div class="sr-hint">Error</div>'; });
        }

        function hlMatch(text, search) {
            var idx = text.toLowerCase().indexOf(search.toLowerCase());
            if (idx===-1) return xe(text);
            return xe(text.substring(0,idx))+'<span class="hl">'+xe(text.substring(idx,idx+search.length))+'</span>'+xe(text.substring(idx+search.length));
        }

        function pick(code, name, target) {
            if (target==='tr') {
                document.getElementById('dropTr').classList.remove('on');
                document.getElementById('trCode').value=code; sv('trName',name); fetchTrDetails(code);
            } else {
                document.getElementById('dropMain').classList.remove('on');
                document.getElementById('accountCode').value=code; sv('accountName',name);
                _prev=code; clearFieldError('accountCode','errAccountCode'); fetchAc(code);
            }
        }

        function triggerFetch() { var c=document.getElementById('accountCode').value.trim(); if(!c) return; document.getElementById('dropMain').classList.remove('on'); fetchAc(c); }
        function triggerTrFetch() { var c=document.getElementById('trCode').value.trim(); if(!c) return; document.getElementById('dropTr').classList.remove('on'); fetchTrDetails(c); }

        function fetchAc(code) {
            showSpin('spinMain');
            ajaxGet(PAGE_URL+'?action=get&code='+encodeURIComponent(code), function(d) {
                hideSpin('spinMain');
                if (d && d.ok===true) {
                    _ledgerBal=parseFloat(d.lb)||0;
                    sv('accountName',d.n||''); sv('glCode',d.gc||''); sv('glName',d.gn||''); sv('custId',d.ci||'');
                    document.getElementById('trDetails').style.display='none';
                    document.getElementById('acDetails').style.display='block';
                    hideTrRowDetails(); fetchShares(code);
                } else { clearAcDetails(); showToast(d&&d.error?d.error:'Account not found.'); }
            }, function(){ hideSpin('spinMain'); clearAcDetails(); });
        }

        function fetchTrDetails(code) {
            if (!code) { hideTrDetails(); return; }
            showSpin('spinTrDetails');
            ajaxGet(PAGE_URL+'?action=getTr&code='+encodeURIComponent(code), function(d) {
                hideSpin('spinTrDetails');
                if (d && d.ok===true) {
                    var lb=parseFloat(d.lb)||0; _trLedgerMap[code]=lb;
                    sv('trName',d.n||''); sv('trDispCode',code); sv('trDispName',d.n||'');
                    sv('trGlCode',d.gc||''); sv('trGlName',d.gn||''); sv('trCustId',d.ci||'');
                    svBal('trLedgerBal',d.lb); svBal('trAvailBal',d.ab);
                    var refundAmt=parseFloat(document.getElementById('payAmt').value)||0;
                    svBal('trNewLedgerBal',(lb+refundAmt).toFixed(2));
                    document.getElementById('acDetails').style.display='none';
                    document.getElementById('trDetails').style.display='block';
                    hideTrRowDetails();
                } else { clearTrDetails(); showToast(d&&d.error?d.error:'Account not found.'); }
            }, function(){ hideSpin('spinTrDetails'); clearTrDetails(); });
        }

        function hideTrDetails() {
            document.getElementById('trDetails').style.display='none';
            ['trDispCode','trDispName','trGlCode','trGlName','trCustId','trLedgerBal','trAvailBal','trNewLedgerBal'].forEach(function(id){ var el=document.getElementById(id); if(el){el.value='';el.classList.remove('bal-pos','bal-neg');} });
        }

        function fetchShares(code) {
            showSpin('spinMain');
            ajaxGet(PAGE_URL+'?action=getShares&code='+encodeURIComponent(code), function(d) {
                hideSpin('spinMain');
                if (d && d.ok===true) {
                    sv('totalNoShares', d.ts!=null?String(d.ts):'0');
                    sv('totalFaceValue', fmtAmt(d.tfv)); sv('totalAmount', fmtAmt(d.ta));
                    sv('certNo',d.certNo||''); sv('memNo',d.memNo||'');
                    sv('formNo',(d.formNo||'0')+' \u2014 '+(d.toNo||'0'));
                    _maxRefundAmt=parseFloat(d.ta)||0; _maxShares=parseInt(d.ts,10)||0;
                    var payEl=document.getElementById('payAmt');
                    if (payEl && _maxRefundAmt>0) { payEl.value=_maxRefundAmt.toFixed(2); payEl.max=_maxRefundAmt; }
                    refreshButtonStates();
                } else { clearShareFields(); }
            }, function(){ hideSpin('spinMain'); clearShareFields(); });
        }

        function onModeChange() {
            var isT=document.getElementById('modeTransfer').checked;
            document.getElementById('trCode').disabled=!isT; document.getElementById('btnTr').disabled=!isT;
            document.getElementById('lblTransfer').classList.toggle('on',isT); document.getElementById('lblCash').classList.toggle('on',!isT);
            document.getElementById('particular').value=isT?'By Transfer':'By Cash';
            clearFieldError('particular','errParticular');
            if (!isT) { sv('trCode',''); sv('trName',''); document.getElementById('dropTr').classList.remove('on'); hideTrDetails(); clearTrEntries(); showMainPanel(); }
            else { clearPayments(); }
            refreshButtonStates();
        }

        function doAddPayment() {
            var isT=document.getElementById('modeTransfer').checked;
            var payAmt=parseFloat(document.getElementById('payAmt').value);
            var maxAmt=_maxRefundAmt;
            if (isNaN(payAmt)||payAmt<=0) { showToast('Please enter a valid amount greater than 0.'); return; }
            if (maxAmt>0 && payAmt>maxAmt+0.001) { showToast('Refund amount \u20B9'+payAmt.toFixed(2)+' cannot exceed total share amount \u20B9'+maxAmt.toFixed(2)); document.getElementById('payAmt').value=maxAmt.toFixed(2); return; }
            if (isT) {
                var trCode=document.getElementById('trCode').value.trim();
                var trName=document.getElementById('trName').value.trim();
                if (!trCode) { showToast('Please select a Transfer Account Code.'); return; }
                var mainCode=document.getElementById('accountCode').value.trim();
                if (trCode===mainCode) { showToast('Transfer account cannot be the same as the main account.'); return; }
                for (var i=0;i<_trEntries.length;i++) { if(_trEntries[i].code===trCode){showToast('This transfer account is already added.');return;} }
                var already=_trEntries.reduce(function(s,e){return s+e.amount;},0);
                if (already+payAmt>maxAmt+0.001) { showToast('Total transfer amount cannot exceed \u20B9'+maxAmt.toFixed(2)); return; }
                _trEntries.push({code:trCode,name:trName,amount:payAmt});
                sv('trCode',''); sv('trName','');
                document.getElementById('payAmt').value='';
                document.getElementById('dropTr').classList.remove('on');
                hideTrDetails(); hideTrRowDetails(); renderTrTable();
                document.getElementById('acDetails').style.display='none';
                document.getElementById('errPayment').classList.remove('show');
            } else {
                if (_payEntries.length>0) { showToast('Cash entry already added.'); return; }
                if (Math.abs(payAmt-maxAmt)>0.001 && maxAmt>0) { showToast('Cash refund amount must equal total share amount \u20B9'+maxAmt.toFixed(2)); return; }
                var particular=document.getElementById('particular').value.trim()||'By Cash';
                _payEntries.push({mode:'Cash',amount:payAmt,particular:particular});
                renderPayTable();
                document.getElementById('acDetails').style.display='none';
                document.getElementById('errPayment').classList.remove('show');
            }
            refreshButtonStates();
        }

        function renderPayTable() {
            var wrap=document.getElementById('payTableWrap'), tbody=document.getElementById('payTbody'), total=document.getElementById('payTotal');
            if (_payEntries.length===0) { wrap.classList.remove('show'); total.textContent='\u20b90.00'; return; }
            wrap.classList.add('show');
            var html='', sum=0;
            for (var i=0;i<_payEntries.length;i++) { var e=_payEntries[i]; sum+=e.amount; html+='<tr><td>'+(i+1)+'</td><td>CSCR</td><td>\u20b9'+e.amount.toFixed(2)+'</td><td>'+xe(e.particular)+'</td><td><button class="btn-remove" onclick="removePayment('+i+')">\u2715 Remove</button></td></tr>'; }
            tbody.innerHTML=html; total.textContent='\u20b9'+sum.toFixed(2);
        }

        function renderTrTable() {
            var wrap=document.getElementById('trTableWrap'), tbody=document.getElementById('trTbody'), total=document.getElementById('trTotal');
            if (_trEntries.length===0) { wrap.classList.remove('show'); total.textContent='\u20b90.00'; hideTrRowDetails(); return; }
            wrap.classList.add('show'); tbody.innerHTML='';
            var sum=0;
            for (var i=0;i<_trEntries.length;i++) {
                var e=_trEntries[i]; sum+=e.amount;
                var tr=document.createElement('tr'); tr.setAttribute('data-code',e.code);
                var clickCells=[String(i+1),'TRCR',xe(e.code),xe(e.name)];
                for (var j=0;j<clickCells.length;j++) { var td=document.createElement('td'); td.innerHTML=clickCells[j]; td.style.cursor='pointer'; td.addEventListener('click',(function(code,amt){return function(){showTrRowDetails(code,amt);};})(e.code,e.amount)); tr.appendChild(td); }
                var tdAmt=document.createElement('td'); tdAmt.textContent='\u20b9'+e.amount.toFixed(2); tr.appendChild(tdAmt);
                var tdBtn=document.createElement('td'); var btn=document.createElement('button'); btn.className='btn-remove'; btn.textContent='\u2715 Remove';
                btn.addEventListener('click',(function(idx){return function(){removeTrEntry(idx);};})(i)); tdBtn.appendChild(btn); tr.appendChild(tdBtn);
                tbody.appendChild(tr);
            }
            total.textContent='\u20b9'+sum.toFixed(2);
        }

        function showTrRowDetails(code, rowAmt) {
            document.getElementById('trDetails').style.display='none';
            document.getElementById('acDetails').style.display='none';
            showSpin('spinTrRow');
            ajaxGet(PAGE_URL+'?action=getTr&code='+encodeURIComponent(code), function(d) {
                hideSpin('spinTrRow');
                if (d && d.ok===true) {
                    var lb=parseFloat(d.lb)||0; _trLedgerMap[code]=lb;
                    document.getElementById('trRowAccCode').value=code;
                    document.getElementById('trRowAccName').value=d.n||'';
                    document.getElementById('trRowGlCode').value=d.gc||'';
                    document.getElementById('trRowGlName').value=d.gn||'';
                    document.getElementById('trRowCustId').value=d.ci||'';
                    svBal('trRowLedger',d.lb); svBal('trRowAvail',d.ab);
                    svBal('trRowNewLedger',(lb+rowAmt).toFixed(2));
                    document.getElementById('trRowDetails').style.display='block';
                }
            }, function(){ hideSpin('spinTrRow'); });
        }

        function hideTrRowDetails() {
            document.getElementById('trRowDetails').style.display='none';
            ['trRowAccCode','trRowAccName','trRowGlCode','trRowGlName','trRowCustId','trRowLedger','trRowAvail','trRowNewLedger'].forEach(function(id){ var el=document.getElementById(id); if(el){el.value='';el.classList.remove('bal-pos','bal-neg');} });
        }

        function removeTrEntry(idx) {
            _trEntries.splice(idx,1); renderTrTable(); hideTrRowDetails();
            if(_trEntries.length===0) document.getElementById('acDetails').style.display='block';
            refreshButtonStates();
        }
        function clearTrEntries() { _trEntries=[]; _trLedgerMap={}; renderTrTable(); hideTrRowDetails(); hideTrDetails(); }
        function removePayment(idx) {
            _payEntries.splice(idx,1); renderPayTable();
            document.getElementById('acDetails').style.display='block';
            refreshButtonStates();
        }
        function clearPayments() { _payEntries=[]; renderPayTable(); }

        function doSave() {
            clearAllErrors();
            var acCode     = document.getElementById('accountCode').value.trim();
            var meetDate   = document.getElementById('meetDate').value.trim();
            var particular = document.getElementById('particular').value.trim();
            var isT        = document.getElementById('modeTransfer').checked;
            var maxAmt     = _maxRefundAmt;
            var hasError   = false;

            if (!acCode) {
                setFieldError('accountCode', 'errAccountCode');
                shakeEl('accountCode');
                hasError = true;
            }
            if (!meetDate) {
                setFieldError('meetDate', 'errMeetDate');
                shakeEl('meetDate');
                hasError = true;
            }
            if (!particular) {
                setFieldError('particular', 'errParticular');
                shakeEl('particular');
                hasError = true;
            }
            if (isT) {
                var t = _trEntries.reduce(function(s,e){return s+e.amount;},0);
                if (_trEntries.length===0 || (maxAmt>0 && Math.abs(t-maxAmt)>=0.001)) {
                    document.getElementById('errPayment').classList.add('show');
                    shakeEl('payAmtWrap');
                    hasError = true;
                }
            } else {
                var p = _payEntries.reduce(function(s,e){return s+e.amount;},0);
                if (_payEntries.length===0 || (maxAmt>0 && Math.abs(p-maxAmt)>=0.001)) {
                    document.getElementById('errPayment').classList.add('show');
                    shakeEl('payAmtWrap');
                    hasError = true;
                }
            }
            if (hasError) return;

            if (!particular) particular = isT ? 'By Transfer' : 'By Cash';
            var trCodes = '[]';
            if (isT && _trEntries.length>0) {
                var arr = [];
                for (var i=0; i<_trEntries.length; i++)
                    arr.push('{"code":"'+xq(_trEntries[i].code)+'","amount":'+_trEntries[i].amount+'}');
                trCodes = '['+arr.join(',')+']';
            }
            var body = 'accountCode='+encodeURIComponent(acCode)
                     + '&meetDate='  +encodeURIComponent(meetDate)
                     + '&noShares='  +encodeURIComponent(_maxShares)
                     + '&mode='      +encodeURIComponent(isT?'Transfer':'Cash')
                     + '&trCodes='   +encodeURIComponent(trCodes)
                     + '&particular='+encodeURIComponent(particular);

            var btnSave = document.getElementById('btnSave');
            btnSave.disabled=true; btnSave.textContent='Saving\u2026';

            ajaxPost(PAGE_URL+'?action=save', body, function(d) {
                btnSave.textContent='Save';
                if (d && d.ok===true) {
                    document.getElementById('sc-scrollNo').textContent = d.scrollNo || '\u2014';
                    document.getElementById('successOverlay').classList.add('open');
                } else {
                    btnSave.disabled=false;
                    showToast((d&&d.error)?d.error:'Save failed.');
                }
            }, function(){
                btnSave.disabled=false; btnSave.textContent='Save';
                showToast('Network error. Please try again.');
            });
        }

        function closeSuccess() { document.getElementById('successOverlay').classList.remove('open'); clearForm(); }
        function doCancel() { document.getElementById('clearOverlay').classList.add('open'); }
        function closeClearPopup() { document.getElementById('clearOverlay').classList.remove('open'); }
        function confirmClear() { closeClearPopup(); clearForm(); }

        function clearForm() {
            clearAcDetails(); clearAllErrors();
            ['accountCode','trCode','trName','payAmt','meetDate'].forEach(function(id){ var el=document.getElementById(id); if(el) el.value=''; });
            document.getElementById('particular').value='By Cash';
            document.getElementById('dropMain').classList.remove('on');
            document.getElementById('dropTr').classList.remove('on');
            document.getElementById('modeCash').checked=true;
            onModeChange(); _prev=''; _ledgerBal=0; _maxRefundAmt=0; _maxShares=0;
            refreshButtonStates();
        }

        function clearAcDetails() {
            document.getElementById('acDetails').style.display='none';
            hideTrDetails(); hideTrRowDetails();
            _ledgerBal=0; _maxRefundAmt=0; _maxShares=0; sv('accountName','');
            ['glCode','glName','custId'].forEach(function(id){ var el=document.getElementById(id); if(el){el.value='';el.classList.remove('bal-pos','bal-neg');} });
            clearShareFields(); clearTrEntries(); clearPayments();
            refreshButtonStates();
        }

        function clearTrDetails() { hideTrDetails(); }

        function clearShareFields() {
            sv('totalNoShares','0'); sv('totalFaceValue','0.00'); sv('totalAmount','0.00');
            sv('certNo',''); sv('memNo',''); sv('formNo','');
            var payEl=document.getElementById('payAmt'); if(payEl){payEl.value='';payEl.removeAttribute('max');}
            _maxRefundAmt=0; _maxShares=0;
            refreshButtonStates();
        }

        var _lkTarget='main', _lkTimer=null;

        function openLookup(target) {
            _lkTarget=target;
            document.getElementById('lkSearchInput').value='';
            document.getElementById('lkTbody').innerHTML='<tr><td colspan="3" class="lk-msg">Loading&#8230;</td></tr>';
            document.getElementById('lkStatus').textContent='Click a row to select.';
            document.getElementById('lkBadge').textContent=(target==='tr')?'SAVINGS / CURRENT':'SHARES A/C';
            document.getElementById('lkOverlay').classList.add('open');
            setTimeout(function(){ document.getElementById('lkSearchInput').focus(); },80);
            lkLoad('');
        }
        function lkClose() { document.getElementById('lkOverlay').classList.remove('open'); }
        function lkOnInput(val) { clearTimeout(_lkTimer); _lkTimer=setTimeout(function(){ lkLoad(val.trim()); },300); }

        function lkLoad(term) {
            var tbody=document.getElementById('lkTbody');
            tbody.innerHTML='<tr><td colspan="3" class="lk-msg">Searching&#8230;</td></tr>';
            var act=(_lkTarget==='tr')?'searchTr':'search';
            ajaxGet(PAGE_URL+'?action='+act+'&term='+encodeURIComponent(term), function(d) {
                if (d.error) { tbody.innerHTML='<tr><td colspan="3" class="lk-err">'+xe(d.error)+'</td></tr>'; return; }
                var list=d.accounts||[];
                if (!list.length) { tbody.innerHTML='<tr><td colspan="3" class="lk-msg">No accounts found.</td></tr>'; return; }
                tbody.innerHTML='';
                for (var i=0;i<list.length;i++) {
                    var c=list[i].code||'', n=list[i].name||'', p=list[i].product||'';
                    var tr=document.createElement('tr');
                    var td1=document.createElement('td'); td1.innerHTML=lkHl(c,term);
                    var td2=document.createElement('td'); td2.innerHTML=lkHl(n,term);
                    var td3=document.createElement('td'); td3.textContent=p;
                    tr.appendChild(td1); tr.appendChild(td2); tr.appendChild(td3);
                    tr.addEventListener('click',(function(code,name){return function(){lkPick(code,name);};})(c,n));
                    tbody.appendChild(tr);
                }
                document.getElementById('lkStatus').textContent=list.length+' result(s). Click a row to select.';
            }, function(){ tbody.innerHTML='<tr><td colspan="3" class="lk-err">Network error.</td></tr>'; });
        }

        function lkPick(code, name) {
            lkClose();
            if (_lkTarget==='tr') { document.getElementById('trCode').value=code; sv('trName',name); fetchTrDetails(code); }
            else { document.getElementById('accountCode').value=code; sv('accountName',name); _prev=code; clearFieldError('accountCode','errAccountCode'); fetchAc(code); }
        }

        function lkHl(text, search) {
            if (!search) return xe(text);
            var idx=text.toLowerCase().indexOf(search.toLowerCase());
            if (idx===-1) return xe(text);
            return xe(text.substring(0,idx))+'<span class="lk-hl">'+xe(text.substring(idx,idx+search.length))+'</span>'+xe(text.substring(idx+search.length));
        }

        function sv(id,val) { var el=document.getElementById(id); if(el) el.value=val||''; }
        function showSpin(id) { var el=document.getElementById(id); if(el) el.style.display='inline-block'; }
        function hideSpin(id) { var el=document.getElementById(id); if(el) el.style.display='none'; }
        function svBal(id,val) {
            var el=document.getElementById(id); if(!el) return;
            var n=parseFloat(val);
            el.value=isNaN(n)?(val||''):n.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2});
            el.classList.remove('bal-pos','bal-neg');
            if(!isNaN(n)) el.classList.add(n>=0?'bal-pos':'bal-neg');
        }
        function fmtAmt(val) { var n=parseFloat(val); return isNaN(n)?'0.00':n.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2}); }
        function ajaxGet(url,onSuccess,onError) {
            var xhr=new XMLHttpRequest(); xhr.open('GET',url,true);
            xhr.onreadystatechange=function(){ if(xhr.readyState!==4) return; if(xhr.status!==200){if(onError)onError();return;} var d; try{var raw=xhr.responseText;var si=raw.indexOf('{');if(si>0)raw=raw.substring(si);d=JSON.parse(raw.trim());}catch(e){if(onError)onError();return;} onSuccess(d); };
            xhr.send();
        }
        function ajaxPost(url,body,onSuccess,onError) {
            var xhr=new XMLHttpRequest(); xhr.open('POST',url,true); xhr.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
            xhr.onreadystatechange=function(){ if(xhr.readyState!==4) return; if(xhr.status!==200){if(onError)onError();return;} var d; try{var raw=xhr.responseText;var si=raw.indexOf('{');if(si>0)raw=raw.substring(si);d=JSON.parse(raw.trim());}catch(e){if(onError)onError();return;} onSuccess(d); };
            xhr.send(body);
        }
        function xe(s){ return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
        function xq(s){ return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('particular').value='By Cash';
            refreshButtonStates();
            document.addEventListener('click', function(e) {
                if (!e.target.closest||!e.target.closest('.sw')) {
                    document.getElementById('dropMain').classList.remove('on');
                    document.getElementById('dropTr').classList.remove('on');
                }
            });
            document.addEventListener('keydown', function(e){ if(e.key==='Escape') lkClose(); });
            window.addEventListener('resize', function() {
                var drop = document.getElementById('dropTr');
                if (drop.classList.contains('on')) positionDropTr();
            });
        });
    </script>
</body>
</html>
