<%@ page trimDirectiveWhitespaces="true" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String SERVLET_URL = request.getContextPath() + "/shares/allotment";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shares Allotment</title>
    <link rel="stylesheet" href="../css/shares.css">
    <style>
        /* ── Allotment-specific layout ── */
        .modules-row {
            display: grid;
            grid-template-columns: 22% 38% 40%;
            grid-template-rows: auto auto;
            align-items: start;
            background-image: linear-gradient(to bottom, #dcdcf0, #dcdcf0), linear-gradient(to bottom, #dcdcf0, #dcdcf0);
            background-size: 1px 100%, 1px 100%;
            background-position: 22% 0, 60% 0;
            background-repeat: no-repeat, no-repeat;
        }
        .module { display: contents; }
        .mod-block {
            padding: 8px 16px 16px;
            display: flex; flex-direction: column; gap: 10px;
        }

        .fg-row  { display: grid; grid-template-columns: 1fr 1fr;     gap: 8px; align-items: start; }
        .fg-row3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; align-items: start; }

        /* ── Show/hide helpers ── */
        #acDetails        { display: none; margin-top: 24px; }
        #acDetails.show   { display: block; }
        #trPayDetails     { display: none; margin-top: 24px; }
        #trPayDetails.show{ display: block; }
        .ac-details-wrap  { display: none; margin-top: 24px; }
        .ac-details-wrap.show { display: block; }

        /* ── Lookup modal border-bottom override ── */
        .lk-head { border-bottom: none; }
        .lk-search-wrap { border-bottom: none; }
    </style>
</head>
<body>

    <div id="jsErrBar" style="display:none;background:#fdd;color:#900;padding:6px 14px;font-size:.82rem;font-weight:700;border-bottom:1px solid #e99;"></div>
    <div class="page-title">Shares Allotment</div>

    <div class="box">
        <span class="box-legend" style="background:#eaeaf5;">Transaction Details</span>

        <div class="modules-row">

            <!-- ══ MODULE 1: Account Info ══ -->
            <div class="module">
                <div class="mod-block" style="grid-column:1; grid-row:1;">
                    <div class="mod-title">Account Info</div>
                    <div class="fg">
                        <label>Account Code</label>
                        <div class="ib">
                            <div class="sw">
                                <input type="text" id="accountCode" placeholder="Type last 3+ digits…" autocomplete="off"
                                       oninput="onAcInput(this.value)"
                                       onfocus="switchPanel('main')"
                                       onblur="onAcBlur()"
                                       onkeydown="if(event.key==='Enter'){event.preventDefault();triggerFetch();}"/>
                                <div class="sdrop" id="dropMain"></div>
                            </div>
                            <button class="btn-dot" type="button" onclick="openLookup('main')">...</button>
                            <span class="spin" id="spinMain"></span>
                        </div>
                        <span class="hint-xs">Type last 3+ digits to search</span>
                        <span class="field-error-msg" id="errAccountCode">Account code is required</span>
                    </div>
                </div>
                <div class="mod-block" style="grid-column:1; grid-row:2;">
                    <div class="fg">
                        <label>Account Name</label>
                        <input type="text" id="accountName" readonly placeholder="—"/>
                    </div>
                </div>
            </div>

            <!-- ══ MODULE 2: Transaction Details ══ -->
            <div class="module">
                <div class="mod-block" style="grid-column:2; grid-row:1;">
                    <div class="mod-title">Transaction Details</div>
                    <div class="fg-row3">
                        <div class="fg">
                            <label>No. of Shares</label>
                            <input type="number" id="noShares" placeholder="Min. 1" min="1" step="1"
                                   oninput="calcAmt(); clearFieldError('noShares','errNoShares');"
                                   onblur="onSharesBlur()"/>
                            <span class="field-error-msg" id="errNoShares">Required (min. 1)</span>
                        </div>
                        <div class="fg">
                            <label>Face Value</label>
                            <input type="number" id="faceVal" value="100" readonly/>
                        </div>
                        <div class="fg">
                            <label>Amount</label>
                            <input type="text" id="txnAmt" value="0.00" readonly class="amt-red"/>
                        </div>
                    </div>
                </div>
                <div class="mod-block" style="grid-column:2; grid-row:2;">
                    <div class="fg-row">
                        <div class="fg">
                            <label>Meeting Date</label>
                            <input type="date" id="meetDate"
                                   oninput="clearFieldError('meetDate','errMeetDate');"
                                   onblur="onMeetDateBlur()"/>
                            <span class="field-error-msg" id="errMeetDate">Meeting date is required</span>
                        </div>
                        <div class="fg">
                            <label>Particular</label>
                            <input type="text" id="particular" value="By Cash"/>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ══ MODULE 3: Payment Details ══ -->
            <div class="module">
                <div class="mod-block" id="paymentModBlock" style="grid-column:3; grid-row:1;">
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
                                <button class="btn-add" id="btnAdd" type="button" onclick="doAddPayment()" disabled>Add</button>
                            </div>
                              <span class="hint-xs">Click on add for payment entry</span>
                            <span class="field-error-msg" id="errPayment">Please add a payment entry</span>
                        </div>
                    </div>
                </div>
                <div class="mod-block" id="trCodeModBlock" style="grid-column:3; grid-row:2;">
                    <div class="fg-row">
                        <div class="fg">
                            <label>Transfer A/c. Code</label>
                            <div class="ib">
                                <div class="sw">
                                    <input type="text" id="trCode" disabled autocomplete="off"
                                           oninput="onTrInput(this.value)"
                                           onfocus="switchPanel('tr')"
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
                </div>
            </div>

        </div><!-- /.modules-row -->

        <!-- ══ Cash Payment Table ══ -->
        <div class="tr-table-wrap" id="payTableWrap">
            <table class="tr-table">
                <thead>
                    <tr><th>Sr No</th><th>Mode</th><th>Amount (&#8377;)</th><th>Particular</th><th></th></tr>
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

        <!-- ══ Transfer Account Info Panel ══ -->
        <div id="trPayDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">
                    Transfer Account Information
                    <span class="spin" id="spinTrPay" style="display:none;"></span>
                </div>
                <div class="ac-info-grid">
                    <div class="ac-fg"><label>Account Code</label>    <input type="text" id="trPayCode"       readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>    <input type="text" id="trPayName"       readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label> <input type="text" id="trPayGlCode"     readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label> <input type="text" id="trPayGlName"     readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>     <input type="text" id="trPayCustId"     readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>  <input type="text" id="trPayLedger"     readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label><input type="text" id="trPayAvail"     readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="trPayNewLedger" readonly/></div>
                </div>
            </div>
        </div>

        <!-- ══ Transfer Row Click Detail Panel ══ -->
        <div id="trDetails" class="ac-details-wrap">
            <div class="ac-info-box">
                <div class="ac-info-title">
                    Account Information
                    <span class="spin" id="spinTrDetails" style="display:none;"></span>
                </div>
                <div class="ac-info-grid">
                    <div class="ac-fg"><label>Account Code</label>    <input type="text" id="trDispAccCode"     readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>    <input type="text" id="trDispAccName"     readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label> <input type="text" id="trDispGlCode"      readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label> <input type="text" id="trDispGlName"      readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>     <input type="text" id="trDispCustId"      readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>  <input type="text" id="trDispLedger"      readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label><input type="text" id="trDispAvail"      readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="trDispNewLedger" readonly/></div>
                </div>
            </div>
        </div>

        <!-- ══ Main Account Details Panel ══ -->
        <div id="acDetails">
            <div class="ac-info-box">
                <div class="ac-info-title">Account Information</div>
                <div class="ac-info-grid">
                    <div class="ac-fg"><label>Account Code</label>    <input type="text" id="dispAccCode"   readonly/></div>
                    <div class="ac-fg"><label>Account Name</label>    <input type="text" id="dispAccName"   readonly/></div>
                    <div class="ac-fg"><label>GL Account Code</label> <input type="text" id="glCode"        readonly/></div>
                    <div class="ac-fg"><label>GL Account Name</label> <input type="text" id="glName"        readonly/></div>
                    <div class="ac-fg"><label>Customer ID</label>     <input type="text" id="custId"        readonly/></div>
                    <div class="ac-fg"><label>Ledger Balance</label>  <input type="text" id="ledgerBal"     readonly/></div>
                    <div class="ac-fg"><label>Available Balance</label><input type="text" id="availBal"     readonly/></div>
                    <div class="ac-fg"><label>New Ledger Balance</label><input type="text" id="newLedgerBal" readonly/></div>
                </div>
            </div>
        </div>

    </div><!-- /.box -->

    <div class="act-bar">
        <button class="btn-primary" id="btnSave" type="button" onclick="doSave()" disabled>Save</button>
        <button class="btn-danger" type="button" onclick="doCancel()">Clear</button>
    </div>

    <!-- ── Lookup Modal ── -->
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
                    <thead><tr><th>Code</th><th>Name</th><th>Product</th></tr></thead>
                    <tbody id="lkTbody"></tbody>
                </table>
            </div>
            <div class="lk-status" id="lkStatus">Click a row to select.</div>
        </div>
    </div>

    <!-- ── Success Popup ── -->
    <div class="success-overlay" id="successOverlay">
        <div class="success-modal">
            <div class="success-tick">&#10003;</div>
            <div class="success-title">Shares Allotted Successfully!</div>
            <div class="success-info">
                Certificate No &nbsp;: &nbsp;<strong id="sc-certNo">—</strong><br>
                No. of Shares &nbsp;&nbsp;: &nbsp;<strong id="sc-shares">—</strong><br>
                Scroll No &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: &nbsp;<strong id="sc-scrollNo">—</strong>
            </div>
            <button class="btn-ok" onclick="closeSuccess()">OK</button>
        </div>
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

    <!-- ── Error Popup ── -->
    <div class="success-overlay" id="errorOverlay">
        <div class="success-modal">
            <div class="success-tick" style="color:#cc2222;">&#10007;</div>
            <div class="success-title" id="errorTitle">Error</div>
            <div class="success-info" id="errorMsg">—</div>
            <button class="btn-ok btn-ok-red" onclick="closeErrorPopup()">OK</button>
        </div>
    </div>

    <div class="toast-wrap" id="toastWrap"></div>

    <script>
        window.onerror = function(msg, src, line, col, err) {
            var d = document.getElementById('jsErrBar');
            if (d) { d.style.display = 'block'; d.textContent = 'JS ERROR line ' + line + ': ' + msg; }
            return false;
        };

        var PAGE_URL   = '<%= SERVLET_URL %>';
        var SEARCH_MIN = 3;
        var WAIT_MS    = 300;

        var _timer       = null;
        var _prev        = '';
        var _ledgerBal   = 0;
        var _payEntries  = [];
        var _trEntries   = [];
        var _trLedgerMap = {};

        /* ── Shake helper ── */
        function shakeEl(id) {
            var el = document.getElementById(id);
            if (!el) return;
            el.classList.remove('shake');
            void el.offsetWidth;
            el.classList.add('shake');
            el.addEventListener('animationend', function() { el.classList.remove('shake'); }, { once: true });
        }

        /* ── Button state manager ── */
        function refreshButtonStates() {
            var txnAmt  = parseFloat(document.getElementById('txnAmt').value) || 0;
            var isT     = document.getElementById('modeTransfer').checked;

            var paidTotal = 0;
            if (isT) {
                paidTotal = _trEntries.reduce(function(s, e) { return s + e.amount; }, 0);
            } else {
                paidTotal = _payEntries.reduce(function(s, e) { return s + e.amount; }, 0);
            }

            var isMatched = txnAmt > 0 && Math.abs(paidTotal - txnAmt) < 0.001;
            var canAdd    = txnAmt > 0 && !isMatched;

            var btnAdd  = document.getElementById('btnAdd');
            var btnSave = document.getElementById('btnSave');

            if (btnAdd)  btnAdd.disabled  = !canAdd;
            if (btnSave) btnSave.disabled = !isMatched;

            if (isMatched) {
                var pm = document.getElementById('errPayment');
                if (pm) pm.classList.remove('show');
            }
        }

        /*
         * positionDropTr — dynamically aligns #dropTr's RIGHT edge to the
         * RIGHT edge of #trCodeModBlock, so the dropdown never overflows the page.
         */
        function positionDropTr() {
            var drop      = document.getElementById('dropTr');
            var sw        = document.getElementById('trCode').closest('.sw');
            var cell      = document.getElementById('trCodeModBlock');
            var dropW     = 620;
            var swLeft    = sw.getBoundingClientRect().left;
            var cellRight = cell.getBoundingClientRect().right;
            var leftOffset = cellRight - swLeft - dropW;
            drop.style.left  = leftOffset + 'px';
            drop.style.right = 'auto';
        }

        /* ── Blur handlers ── */
        function onAcBlur() {
            setTimeout(function() {
                var val = document.getElementById('accountCode').value.trim();
                if (!val) setFieldError('accountCode', 'errAccountCode');
                else      clearFieldError('accountCode', 'errAccountCode');
            }, 200);
        }

        function onSharesBlur() {
            var val = parseInt(document.getElementById('noShares').value) || 0;
            if (val < 1) setFieldError('noShares', 'errNoShares');
            else         clearFieldError('noShares', 'errNoShares');
        }

        function onMeetDateBlur() {
            var val = document.getElementById('meetDate').value.trim();
            if (!val) setFieldError('meetDate', 'errMeetDate');
            else      clearFieldError('meetDate', 'errMeetDate');
        }

        function showToast(msg, duration) {
            duration = duration || 3500;
            var wrap = document.getElementById('toastWrap');
            var t = document.createElement('div');
            t.className = 'toast';
            t.innerHTML = '<div class="toast-icon">i</div>'
                        + '<div class="toast-msg">' + xe(msg) + '</div>'
                        + '<button class="toast-close" onclick="this.parentNode.remove()">&#215;</button>';
            wrap.appendChild(t);
            setTimeout(function() { if (t.parentNode) t.remove(); }, duration);
        }

        function switchPanel(target) {
            if (target === 'main') {
                var hasData = document.getElementById('dispAccCode').value.trim() !== '';
                document.getElementById('acDetails').style.display    = hasData ? 'block' : 'none';
                document.getElementById('trPayDetails').style.display = 'none';
                hideTrDetails();
            } else {
                var hasTrData = document.getElementById('trPayCode').value.trim() !== '';
                document.getElementById('trPayDetails').style.display = hasTrData ? 'block' : 'none';
                document.getElementById('acDetails').style.display    = 'none';
                hideTrDetails();
            }
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
            [['accountCode','errAccountCode'],['noShares','errNoShares'],['meetDate','errMeetDate']]
                .forEach(function(p) { clearFieldError(p[0], p[1]); });
            var pm = document.getElementById('errPayment');
            if (pm) pm.classList.remove('show');
        }

        function onAcInput(v) {
            clearFieldError('accountCode', 'errAccountCode');
            if (v !== _prev) { clearAcDetails(); _prev = v; }
            liveSearch(v, 'dropMain', 'main');
        }
        function onTrInput(v) {
            hideTrPayDetails();
            liveSearch(v, 'dropTr', 'tr');
        }

        function liveSearch(val, dropId, target) {
            clearTimeout(_timer);
            var drop = document.getElementById(dropId);
            if (!val) { drop.classList.remove('on'); return; }
            if (dropId === 'dropTr') positionDropTr();
            if (val.length < SEARCH_MIN) {
                drop.innerHTML = '<div class="sr-hint">Type at least ' + SEARCH_MIN + ' digits\u2026</div>';
                drop.classList.add('on'); return;
            }
            drop.innerHTML = '<div class="sr-hint">Searching\u2026</div>';
            drop.classList.add('on');
            var sa = (target === 'tr') ? 'searchtr' : 'search';
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
                    var c = list[i].code || '', a = list[i].name || '', p = list[i].product || '';
                    var item = document.createElement('div');
                    item.className = 'sr-item';
                    item.innerHTML = '<span class="sr-code">'  + hlMatch(c, term) + '</span>'
                                   + '<span class="sr-name">'  + xe(a) + '</span>'
                                   + '<span class="sr-prod">'  + xe(p) + '</span>';
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
                fetchTrPayDetails(code);
            } else {
                document.getElementById('dropMain').classList.remove('on');
                document.getElementById('accountCode').value = code;
                sv('accountName', name);
                _prev = code;
                clearFieldError('accountCode', 'errAccountCode');
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
            fetchTrPayDetails(code);
        }

        function fetchAc(code) {
            showSpin('spinMain');
            ajaxGet(PAGE_URL + '?action=get&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinMain');
                if (d && d.ok === true) {
                    _ledgerBal = parseFloat(d.lb) || 0;
                    sv('accountName', d.n || '');
                    sv('dispAccCode', code); sv('dispAccName', d.n || '');
                    sv('glCode', d.gc || ''); sv('glName', d.gn || '');
                    sv('custId', d.ci || '');
                    svBal('ledgerBal', d.lb); svBal('availBal', d.ab);
                    calcNewLedgerBal();
                    document.getElementById('acDetails').style.display    = 'block';
                    document.getElementById('trPayDetails').style.display = 'none';
                    hideTrDetails();
                } else {
                    clearAcDetails();
                }
            }, function() { hideSpin('spinMain'); clearAcDetails(); });
        }

        function fetchTrPayDetails(code) {
            if (!code) { hideTrPayDetails(); return; }
            showSpin('spinTr');
            ajaxGet(PAGE_URL + '?action=gettr&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinTr');
                sv('trName', (d && d.ok === true) ? (d.n || '') : '');
            }, function() { hideSpin('spinTr'); sv('trName', ''); });

            showSpin('spinTrPay');
            ajaxGet(PAGE_URL + '?action=gettrdetails&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinTrPay');
                if (d && d.ok === true) {
                    var lb = parseFloat(d.lb) || 0;
                    _trLedgerMap[code] = lb;
                    document.getElementById('trPayCode').value   = code;
                    document.getElementById('trPayName').value   = d.n  || '';
                    document.getElementById('trPayGlCode').value = d.gc || '';
                    document.getElementById('trPayGlName').value = d.gn || '';
                    document.getElementById('trPayCustId').value = d.ci || '';
                    svBal('trPayLedger', d.lb);
                    svBal('trPayAvail',  d.ab);
                    var txnAmt = parseFloat(document.getElementById('txnAmt').value) || 0;
                    svBal('trPayNewLedger', (lb - txnAmt).toString());
                    document.getElementById('acDetails').style.display    = 'none';
                    document.getElementById('trPayDetails').style.display = 'block';
                    hideTrDetails();
                }
            }, function() { hideSpin('spinTrPay'); });
        }

        function hideTrPayDetails() {
            document.getElementById('trPayDetails').style.display = 'none';
            ['trPayCode','trPayName','trPayGlCode','trPayGlName',
             'trPayCustId','trPayLedger','trPayAvail','trPayNewLedger'].forEach(function(id) {
                var el = document.getElementById(id);
                if (el) { el.value = ''; el.classList.remove('bal-pos','bal-neg'); }
            });
        }

        function onModeChange() {
            var isT = document.getElementById('modeTransfer').checked;
            document.getElementById('trCode').disabled = !isT;
            document.getElementById('btnTr').disabled  = !isT;
            document.getElementById('particular').value = isT ? 'By Transfer' : 'By Cash';
            document.getElementById('lblTransfer').classList.toggle('on',  isT);
            document.getElementById('lblCash').classList.toggle('on',     !isT);
            var payAmtEl = document.getElementById('payAmt');
            if (!isT) {
                payAmtEl.readOnly = true;
                payAmtEl.value = document.getElementById('txnAmt').value || '';
            } else {
                payAmtEl.readOnly = false;
                payAmtEl.value = '';
            }
            if (!isT) {
                sv('trCode', ''); sv('trName', '');
                document.getElementById('dropTr').classList.remove('on');
                hideTrPayDetails();
                clearTrEntries();
            } else {
                clearPayments();
            }
            var pm = document.getElementById('errPayment');
            if (pm) pm.classList.remove('show');
            refreshButtonStates();
        }

        function calcAmt() {
            var s = parseInt(document.getElementById('noShares').value) || 0;
            if (s < 0) { s = 0; document.getElementById('noShares').value = ''; }
            var amt = (s * 100).toFixed(2);
            document.getElementById('txnAmt').value = amt;
            if (!document.getElementById('modeTransfer').checked) {
                document.getElementById('payAmt').value = amt;
            }
            calcNewLedgerBal();
            clearPayments();
            clearTrEntries();
            hideTrPayDetails();
            refreshButtonStates();
        }

        function calcNewLedgerBal() {
            var txnAmt = parseFloat(document.getElementById('txnAmt').value) || 0;
            var lb     = isNaN(_ledgerBal) ? 0 : _ledgerBal;
            svBal('newLedgerBal', (lb + txnAmt).toFixed(2));
        }

        function doAddPayment() {
            var isTransfer = document.getElementById('modeTransfer').checked;
            var payAmt     = parseFloat(document.getElementById('payAmt').value);
            var txnAmt     = parseFloat(document.getElementById('txnAmt').value) || 0;
            var noShares   = parseInt(document.getElementById('noShares').value) || 0;

            if (isNaN(payAmt) || payAmt <= 0) {
                showToast('Please enter a valid amount greater than 0.');
                return;
            }
            if (noShares < 1 || txnAmt <= 0) {
                showToast('Please enter the number of shares first.');
                return;
            }
            if (payAmt > txnAmt + 0.001) {
                showToast('Amount \u20B9' + payAmt.toFixed(2) + ' cannot exceed transaction amount \u20B9' + txnAmt.toFixed(2) + '.');
                document.getElementById('payAmt').value = txnAmt.toFixed(2);
                return;
            }

            if (isTransfer) {
                var trCode = document.getElementById('trCode').value.trim();
                var trName = document.getElementById('trName').value.trim();
                if (!trCode) { showToast('Please select a Transfer Account Code.'); return; }
                var mainCode = document.getElementById('accountCode').value.trim();
                if (trCode === mainCode) { showToast('Transfer account cannot be the same as the main account.'); return; }
                for (var i = 0; i < _trEntries.length; i++) {
                    if (_trEntries[i].code === trCode) { showToast('This transfer account is already added.'); return; }
                }
                var already = _trEntries.reduce(function(s, e) { return s + e.amount; }, 0);
                if (already + payAmt > txnAmt + 0.001) { showToast('Total transfer amount cannot exceed \u20B9' + txnAmt.toFixed(2) + '.'); return; }
                _trEntries.push({ code: trCode, name: trName, amount: payAmt });
                sv('trCode', ''); sv('trName', '');
                document.getElementById('payAmt').value = '';
                document.getElementById('dropTr').classList.remove('on');
                hideTrPayDetails(); hideTrDetails(); renderTrTable();
                document.getElementById('acDetails').style.display = 'none';
                document.getElementById('errPayment').classList.remove('show');
            } else {
                if (_payEntries.length > 0) { showToast('Cash entry already added.'); return; }
                if (Math.abs(payAmt - txnAmt) > 0.001) { showToast('Cash amount must equal transaction amount \u20B9' + txnAmt.toFixed(2) + '.'); return; }
                var particular = document.getElementById('particular').value.trim() || 'By Cash';
                _payEntries.push({ mode: 'Cash', amount: payAmt, particular: particular });
                renderPayTable();
                document.getElementById('acDetails').style.display = 'none';
                document.getElementById('errPayment').classList.remove('show');
            }

            refreshButtonStates();
        }

        function renderTrTable() {
            var wrap  = document.getElementById('trTableWrap');
            var tbody = document.getElementById('trTbody');
            var total = document.getElementById('trTotal');
            if (_trEntries.length === 0) { wrap.classList.remove('show'); total.textContent = '\u20b90.00'; hideTrDetails(); return; }
            wrap.classList.add('show');
            tbody.innerHTML = '';
            var sum = 0;
            for (var i = 0; i < _trEntries.length; i++) {
                var e = _trEntries[i]; sum += e.amount;
                var tr = document.createElement('tr');
                var clickCells = [ String(i + 1), 'TRDR', xe(e.code), xe(e.name) ];
                for (var j = 0; j < clickCells.length; j++) {
                    var td = document.createElement('td');
                    td.innerHTML = clickCells[j]; td.style.cursor = 'pointer';
                    td.addEventListener('click', (function(code, amt) { return function() { showTrDetails(code, amt); }; })(e.code, e.amount));
                    tr.appendChild(td);
                }
                var tdAmt = document.createElement('td'); tdAmt.textContent = '\u20b9' + e.amount.toFixed(2); tr.appendChild(tdAmt);
                var tdBtn = document.createElement('td');
                var btn = document.createElement('button'); btn.className = 'btn-remove'; btn.textContent = '\u2715 Remove';
                btn.addEventListener('click', (function(idx) { return function() { removeTrEntry(idx); }; })(i));
                tdBtn.appendChild(btn); tr.appendChild(tdBtn);
                tbody.appendChild(tr);
            }
            total.textContent = '\u20b9' + sum.toFixed(2);
        }

        function renderPayTable() {
            var wrap  = document.getElementById('payTableWrap');
            var tbody = document.getElementById('payTbody');
            var total = document.getElementById('payTotal');
            if (_payEntries.length === 0) { wrap.classList.remove('show'); total.textContent = '\u20b90.00'; return; }
            wrap.classList.add('show');
            var html = '', sum = 0;
            for (var i = 0; i < _payEntries.length; i++) {
                var e = _payEntries[i]; sum += e.amount;
                html += '<tr><td>' + (i+1) + '</td><td>CSCR</td><td>\u20b9' + e.amount.toFixed(2) + '</td><td>' + xe(e.particular) + '</td>'
                      + '<td><button class="btn-remove" onclick="removePayment(' + i + ')">\u2715 Remove</button></td></tr>';
            }
            tbody.innerHTML = html;
            total.textContent = '\u20b9' + sum.toFixed(2);
        }

        function showTrDetails(code, rowAmt) {
            hideTrPayDetails();
            showSpin('spinTrDetails');
            ajaxGet(PAGE_URL + '?action=gettrdetails&code=' + encodeURIComponent(code), function(d) {
                hideSpin('spinTrDetails');
                if (d && d.ok === true) {
                    var lb = parseFloat(d.lb) || 0;
                    _trLedgerMap[code] = lb;
                    document.getElementById('trDispAccCode').value = code;
                    document.getElementById('trDispAccName').value = d.n  || '';
                    document.getElementById('trDispGlCode').value  = d.gc || '';
                    document.getElementById('trDispGlName').value  = d.gn || '';
                    document.getElementById('trDispCustId').value  = d.ci || '';
                    svBal('trDispLedger', d.lb); svBal('trDispAvail', d.ab);
                    svBal('trDispNewLedger', (lb - rowAmt).toString());
                    document.getElementById('trDetails').classList.add('show');
                }
            }, function() { hideSpin('spinTrDetails'); });
        }
        function hideTrDetails() { document.getElementById('trDetails').classList.remove('show'); }

        function removeTrEntry(idx) {
            _trEntries.splice(idx, 1);
            renderTrTable();
            hideTrDetails();
            if (_trEntries.length === 0) document.getElementById('acDetails').style.display = 'block';
            refreshButtonStates();
        }
        function clearTrEntries() { _trEntries = []; _trLedgerMap = {}; renderTrTable(); hideTrDetails(); hideTrPayDetails(); }

        function removePayment(idx) {
            _payEntries.splice(idx, 1);
            renderPayTable();
            document.getElementById('acDetails').style.display = 'block';
            refreshButtonStates();
        }
        function clearPayments() { _payEntries = []; renderPayTable(); }

        function doSave() {
            var txnAmt = parseFloat(document.getElementById('txnAmt').value) || 0;
            var isT    = document.getElementById('modeTransfer').checked;
            var paidTotal = isT
                ? _trEntries.reduce(function(s,e){return s+e.amount;},0)
                : _payEntries.reduce(function(s,e){return s+e.amount;},0);
            if (txnAmt <= 0 || Math.abs(paidTotal - txnAmt) >= 0.001) return;

            var hasError = false;

            var accountCode = document.getElementById('accountCode').value.trim();
            if (!accountCode) {
                setFieldError('accountCode', 'errAccountCode');
                shakeEl('accountCode');
                hasError = true;
            } else {
                clearFieldError('accountCode', 'errAccountCode');
            }

            var noShares = parseInt(document.getElementById('noShares').value) || 0;
            if (noShares < 1) {
                setFieldError('noShares', 'errNoShares');
                shakeEl('noShares');
                hasError = true;
            } else {
                clearFieldError('noShares', 'errNoShares');
            }

            var meetDate = document.getElementById('meetDate').value.trim();
            if (!meetDate) {
                setFieldError('meetDate', 'errMeetDate');
                shakeEl('meetDate');
                hasError = true;
            } else {
                clearFieldError('meetDate', 'errMeetDate');
            }

            if (hasError) return;

            var particular = document.getElementById('particular').value.trim();
            if (!particular) particular = isT ? 'By Transfer' : 'By Cash';

            var btnSave = document.getElementById('btnSave');
            btnSave.disabled = true; btnSave.textContent = 'Saving\u2026';

            var trCodes = '[]';
            if (isT && _trEntries.length > 0) {
                var arr = [];
                for (var i = 0; i < _trEntries.length; i++)
                    arr.push('{"code":"' + xq(_trEntries[i].code) + '","amount":' + _trEntries[i].amount + '}');
                trCodes = '[' + arr.join(',') + ']';
            }
            var body = 'accountCode=' + encodeURIComponent(accountCode)
                     + '&meetDate='   + encodeURIComponent(meetDate)
                     + '&noShares='   + encodeURIComponent(noShares)
                     + '&mode='       + encodeURIComponent(isT ? 'Transfer' : 'Cash')
                     + '&trCodes='    + encodeURIComponent(trCodes)
                     + '&particular=' + encodeURIComponent(particular);

            ajaxPost(PAGE_URL + '?action=save', body, function(d) {
                btnSave.textContent = 'Save';
                if (d && d.ok === true) {
                    document.getElementById('sc-certNo').textContent   = d.certNo   || '\u2014';
                    document.getElementById('sc-shares').textContent   = noShares;
                    document.getElementById('sc-scrollNo').textContent = d.scrollNo || '\u2014';
                    document.getElementById('successOverlay').classList.add('open');
                } else {
                    btnSave.disabled = false;
                    showError('Error', (d && d.error) ? d.error : 'Save failed.');
                }
            }, function() {
                btnSave.disabled = false; btnSave.textContent = 'Save';
                showError('Network Error','Could not connect. Please try again.');
            });
        }

        function closeSuccess()    { document.getElementById('successOverlay').classList.remove('open'); clearForm(); }
        function showError(t,m)    { document.getElementById('errorTitle').textContent=t; document.getElementById('errorMsg').textContent=m; document.getElementById('errorOverlay').classList.add('open'); }
        function closeErrorPopup() { document.getElementById('errorOverlay').classList.remove('open'); }
        function doCancel()        { document.getElementById('clearOverlay').classList.add('open'); }
        function closeClearPopup() { document.getElementById('clearOverlay').classList.remove('open'); }
        function confirmClear()    { closeClearPopup(); clearForm(); }

        function clearForm() {
            clearAcDetails(); clearAllErrors();
            ['accountCode','trCode','trName','payAmt','noShares','meetDate'].forEach(function(id){ var el=document.getElementById(id); if(el) el.value=''; });
            sv('faceVal','100'); sv('txnAmt','0.00'); sv('particular','By Cash');
            document.getElementById('dropMain').classList.remove('on');
            document.getElementById('dropTr').classList.remove('on');
            document.getElementById('modeCash').checked = true;
            hideTrPayDetails(); onModeChange();
            _prev=''; _ledgerBal=0;
            refreshButtonStates();
        }
        function clearAcDetails() {
            document.getElementById('acDetails').style.display = 'none';
            _ledgerBal=0; sv('accountName','');
            ['dispAccCode','dispAccName','glCode','glName','custId','ledgerBal','availBal','newLedgerBal'].forEach(function(id){
                var el=document.getElementById(id); if(el){el.value='';el.classList.remove('bal-pos','bal-neg');}
            });
            clearPayments(); clearTrEntries();
        }

        /* ── Lookup Modal ── */
        var _lkTarget='main', _lkTimer=null, _lkAllData=[];

        function openLookup(target) {
            _lkTarget = target;
            document.getElementById('lkSearchInput').value = '';
            document.getElementById('lkOverlay').classList.add('open');
            document.getElementById('lkBadge').textContent = (target === 'tr') ? 'SAVINGS / CURRENT' : 'CUSTOMER';
            document.getElementById('lkTbody').innerHTML = '<tr><td colspan="3" class="lk-msg">Loading&#8230;</td></tr>';
            document.getElementById('lkStatus').textContent = 'Loading...';
            setTimeout(function(){ document.getElementById('lkSearchInput').focus(); }, 80);
            lkLoad('');
        }
        function lkClose() { document.getElementById('lkOverlay').classList.remove('open'); }
        function lkOnInput(val) { clearTimeout(_lkTimer); _lkTimer = setTimeout(function(){ lkLoad(val.trim()); }, 300); }

        function lkLoad(term) {
            var sa = (_lkTarget === 'tr') ? 'searchtr' : 'search';
            ajaxGet(PAGE_URL + '?action=' + sa + '&term=' + encodeURIComponent(term), function(d) {
                if (d.error) {
                    document.getElementById('lkTbody').innerHTML = '<tr><td colspan="3" class="lk-err">' + xe(d.error) + '</td></tr>';
                    return;
                }
                var list = d.accounts || [];
                _lkAllData = list;
                lkRender(list, term);
            }, function() {
                document.getElementById('lkTbody').innerHTML = '<tr><td colspan="3" class="lk-err">Network error.</td></tr>';
            });
        }

        function lkRender(list, term) {
            var tbody = document.getElementById('lkTbody');
            if (!list.length) {
                tbody.innerHTML = '<tr><td colspan="3" class="lk-msg">No accounts found.</td></tr>';
                document.getElementById('lkStatus').textContent = '0 result(s).';
                return;
            }
            tbody.innerHTML = '';
            for (var i = 0; i < list.length; i++) {
                var c = list[i].code || '', n = list[i].name || '', p = list[i].product || '';
                var tr = document.createElement('tr');
                var td1 = document.createElement('td');
                var td2 = document.createElement('td');
                var td3 = document.createElement('td');
                td1.innerHTML = lkHl(c, term);
                td2.innerHTML = lkHl(n, term);
                td3.textContent = p;
                tr.appendChild(td1); tr.appendChild(td2); tr.appendChild(td3);
                tr.addEventListener('click', (function(code, name) {
                    return function() { lkPick(code, name); };
                })(c, n));
                tbody.appendChild(tr);
            }
            document.getElementById('lkStatus').textContent = list.length + ' result(s). Click a row to select.';
        }

        function lkPick(code, name) {
            lkClose();
            if (_lkTarget === 'tr') {
                document.getElementById('trCode').value = code;
                sv('trName', name);
                fetchTrPayDetails(code);
            } else {
                document.getElementById('accountCode').value = code;
                sv('accountName', name);
                _prev = code;
                clearFieldError('accountCode', 'errAccountCode');
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

        function sv(id,val)  { var el=document.getElementById(id); if(el) el.value=val||''; }
        function showSpin(id){ var el=document.getElementById(id); if(el) el.style.display='inline-block'; }
        function hideSpin(id){ var el=document.getElementById(id); if(el) el.style.display='none'; }
        function svBal(id,val){
            var el=document.getElementById(id); if(!el) return;
            var n=parseFloat(val);
            el.value=isNaN(n)?(val||''):n.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2});
            el.classList.remove('bal-pos','bal-neg');
            if(!isNaN(n)) el.classList.add(n>=0?'bal-pos':'bal-neg');
        }
        function xe(s){ return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
        function xq(s){ return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

        function ajaxGet(url,onSuccess,onError){
            var xhr=new XMLHttpRequest(); xhr.open('GET',url,true);
            xhr.onreadystatechange=function(){
                if(xhr.readyState!==4) return;
                if(xhr.status!==200){if(onError)onError();return;}
                var d; try{var raw=xhr.responseText;var si=raw.indexOf('{');if(si>0)raw=raw.substring(si);d=JSON.parse(raw.trim());}catch(e){if(onError)onError();return;}
                onSuccess(d);
            }; xhr.send();
        }
        function ajaxPost(url,body,onSuccess,onError){
            var xhr=new XMLHttpRequest(); xhr.open('POST',url,true);
            xhr.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
            xhr.onreadystatechange=function(){
                if(xhr.readyState!==4) return;
                if(xhr.status!==200){if(onError)onError();return;}
                var d; try{var raw=xhr.responseText;var si=raw.indexOf('{');if(si>0)raw=raw.substring(si);d=JSON.parse(raw.trim());}catch(e){if(onError)onError();return;}
                onSuccess(d);
            }; xhr.send(body);
        }

        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('payAmt').readOnly = true;
            refreshButtonStates();
            document.addEventListener('click', function(e) {
                if (!e.target.closest || !e.target.closest('.sw')) {
                    document.getElementById('dropMain').classList.remove('on');
                    document.getElementById('dropTr').classList.remove('on');
                }
            });
            document.addEventListener('keydown', function(e) { if (e.key === 'Escape') lkClose(); });
            window.addEventListener('resize', function() {
                var drop = document.getElementById('dropTr');
                if (drop.classList.contains('on')) positionDropTr(); 
            });
        });
    </script>
</body>
</html>
