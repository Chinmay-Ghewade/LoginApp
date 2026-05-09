<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Locker Joint Holder</title>
  <link rel="stylesheet" href="../css/locker.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <link rel="stylesheet" href="../css/lookup-modal.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    select.dd-loading {
      color: #999;
      background-color: #f9f9f9;
      font-style: italic;
    }
    .dd-spinner {
      display: inline-block;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: #373279;
      margin-left: 4px;
      animation: ddPulse 0.8s ease-in-out infinite alternate;
      vertical-align: middle;
    }
    @keyframes ddPulse {
      from { opacity: 0.2; transform: scale(0.8); }
      to   { opacity: 1;   transform: scale(1.1); }
    }
    .dd-spinner.done { display: none; }

    /* Nominee header: title left, remove button right */
    .nominee-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
    }

    /* Customer ID row: radio + CID field on the same line */
    .nominee-cid-row {
      display: flex;
      align-items: flex-end;
      gap: 20px;
      flex-wrap: wrap;
      margin-bottom: 14px;
    }
    .nominee-cid-row > div {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    /* Customer ID input + search button flush */
    .nominee-cid-row .input-icon-box {
      display: flex;
    }

    /* Each joint holder block */
    .nominee-block {
      border: 1px solid #c9c5e8;
      border-radius: 6px;
      padding: 14px 16px;
      margin-bottom: 16px;
    }
    .nominee-block:last-of-type {
      margin-bottom: 4px;
    }

    /* Form buttons centered */
    .form-buttons {
      display: flex;
      gap: 10px;
      justify-content: center;
      margin-top: 4px;
    }

    /* Equal 3-column grid — overrides addCustomer.css for joint holder fields only */
    .nominee-block .personal-grid {
      display: grid !important;
      grid-template-columns: repeat(4, 1fr) !important;
      gap: 12px !important;
      align-items: end !important;
      width: 100% !important;
    }

    /* Every cell stacks label + field */
    .nominee-block .personal-grid > div {
      display: flex !important;
      flex-direction: column !important;
      gap: 4px !important;
      min-width: 0 !important;
      width: 100% !important;
    }

    /* ALL inputs AND selects same width */
    .nominee-block .personal-grid input,
    .nominee-block .personal-grid select {
      width: 100% !important;
      box-sizing: border-box !important;
      min-width: 0 !important;
      max-width: 100% !important;
      display: block !important;
    }

    /* Declaration cell — spans all 3 cols, checkbox+text centered */
    .nominee-block .personal-grid .declaration-cell {
      grid-column: 1 / -1 !important;
      display: flex !important;
      flex-direction: row !important;
      align-items: center !important;
      justify-content: center !important;
      padding-top: 6px !important;
    }
    .nominee-block .personal-grid .declaration-cell label {
      display: flex !important;
      align-items: center !important;
      gap: 6px !important;
      cursor: pointer !important;
      white-space: nowrap !important;
    }
    form {
      padding: 0 20px;
    }

    /* ── Lookup table styling scoped to joint holder customer lookup content ── */
    #jhCustomerLookupContent .lookup-title {
      font-size: 1.05rem;
      font-weight: 700;
      color: var(--lk-primary);
      padding: 16px 18px 12px 18px;
      border-bottom: 1px solid var(--lk-border-light);
      display: flex;
      align-items: center;
      gap: 10px;
    }
    #jhCustomerLookupContent .search-box {
      padding: 14px 18px 8px 18px;
      background: var(--lk-primary-light);
      border-bottom: 1px solid var(--lk-border-light);
    }
    #jhCustomerLookupContent #customerSearch {
      width: 100%;
      height: 40px;
      padding: 0 14px 0 42px;
      border: 1.5px solid var(--lk-border);
      border-radius: var(--lk-radius-md);
      font-size: 0.875rem;
      font-family: var(--lk-font);
      color: var(--lk-text);
      box-sizing: border-box;
      outline: none;
      background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='15' height='15' fill='%238066E8' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11'/%3E%3C/svg%3E") no-repeat 13px center;
      transition: border-color 0.18s ease, box-shadow 0.18s ease;
    }
    #jhCustomerLookupContent #customerSearch::placeholder { color: #a090cc; }
    #jhCustomerLookupContent #customerSearch:focus {
      border-color: var(--lk-primary);
      box-shadow: 0 0 0 3px rgba(55,50,121,0.10);
    }
    #jhCustomerLookupContent .customer-count {
      font-size: 0.75rem;
      color: var(--lk-text-muted);
      text-align: right;
      padding: 6px 18px;
      border-bottom: 1px solid var(--lk-border-light);
    }
    #jhCustomerLookupContent .customer-count strong { color: var(--lk-primary); }
    #jhCustomerLookupContent .table-container {
      flex: 1;
      overflow-y: auto;
      overflow-x: auto;
      min-height: 0;
    }
    #jhCustomerLookupContent .table-container::-webkit-scrollbar { width: 7px; }
    #jhCustomerLookupContent .table-container::-webkit-scrollbar-track { background: var(--lk-primary-light); }
    #jhCustomerLookupContent .table-container::-webkit-scrollbar-thumb { background: var(--lk-border); border-radius: 10px; }
    #jhCustomerLookupContent #customerTable {
      width: 100%;
      border-collapse: collapse;
      font-family: var(--lk-font);
    }
    #jhCustomerLookupContent #customerTable thead tr {
      background: linear-gradient(90deg, var(--lk-primary) 0%, var(--lk-accent) 100%);
      position: sticky;
      top: 0;
      z-index: 2;
    }
    #jhCustomerLookupContent #customerTable thead th {
      padding: 11px 16px;
      text-align: left;
      font-size: 0.77rem;
      font-weight: 700;
      color: rgba(255,255,255,0.95);
      letter-spacing: 0.06em;
      text-transform: uppercase;
      border-right: 1px solid rgba(255,255,255,0.12);
      white-space: nowrap;
    }
    #jhCustomerLookupContent #customerTable thead th:last-child { border-right: none; }
    #jhCustomerLookupContent #customerTable tbody tr {
      border-bottom: 1px solid var(--lk-border-light);
      cursor: pointer;
      transition: background 0.18s ease, transform 0.1s ease;
      border-left: 3px solid transparent;
    }
    #jhCustomerLookupContent #customerTable tbody tr:nth-child(even) { background: var(--lk-row-stripe); }
    #jhCustomerLookupContent #customerTable tbody tr:hover {
      background: var(--lk-row-hover);
      border-left-color: var(--lk-primary-mid);
      transform: translateX(2px);
    }
    #jhCustomerLookupContent #customerTable tbody td {
      padding: 11px 16px;
      font-size: 0.875rem;
      color: var(--lk-text);
      vertical-align: middle;
      border-right: 1px solid var(--lk-border-light);
    }
    #jhCustomerLookupContent #customerTable tbody td:last-child { border-right: none; }
    #jhCustomerLookupContent #customerTable tbody td:first-child {
      font-weight: 700;
      color: var(--lk-primary);
      font-size: 0.84rem;
      white-space: nowrap;
    }
  </style>
</head>
<body>

<form action="LockerJointHolderServlet" method="post" onsubmit="return validateForm()">

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 1: LOCKER INFORMATION -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Information</legend>
    <div class="form-grid">

      <div>
        <label>Locker Type</label>
        <input type="text" name="lockerType" id="lockerType" required>
      </div>

      <div>
        <label>Locker Number</label>
        <input type="text" name="lockerNumber" id="lockerNumber" required>
      </div>

      <div style="display:flex; flex-direction:column; gap:4px;">
         <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="nomineeCustomerIDInput" name="nomineeCustomerID[]" onclick="openJHCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openJHCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
      </div>

    </div>
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: JOINT HOLDER                                       -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <fieldset id="nomineeFieldset">
    <legend>
      Joint Holder
      <button type="button" onclick="addNominee()"
        style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
        ➕
      </button>
    </legend>

    <div class="nominee-card nominee-block">

      <!-- Header: title left, remove button right -->
      <div class="nominee-header">
        <div class="nominee-title"
             style="font-weight:bold; font-size:15px; color:#373279;">
          Joint Holder <span class="nominee-serial">1</span>
        </div>
        <button type="button" class="nominee-remove" onclick="removeNominee(this)">✖</button>
      </div>

      <!-- Has Customer ID row -->
      <div class="nominee-cid-row">
        <div>
          <label>Has Customer ID ?</label>
          <div style="flex-direction: row;" class="radio-group">
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="yes" onchange="toggleNomineeCustomerID(this)"> Yes</label>
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="no"  onchange="toggleNomineeCustomerID(this)" checked> No</label>
          </div>
        </div>
        <div class="nomineeCustomerIDContainer" style="display:none;">
          <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="nomineeCustomerIDInput" name="nomineeCustomerID[]" onclick="openJHCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openJHCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <div class="personal-grid">

        <!-- ✅ AJAX — key "salutation" from AddCustomerDataLoader -->
        <div>
          <label>Salutation Code <span class="dd-spinner jh-sp-salutation"></span></label>
          <select name="nomineeSalutation[]" class="jh-dd-salutation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Name</label>
          <input type="text" name="nomineeName[]" required
                 oninput="this.value = this.value
                   .replace(/[^A-Za-z ]/g, '')
                   .replace(/\s{2,}/g, ' ')
                   .replace(/^\s+/g, '')
                   .toLowerCase()
                   .replace(/\b\w/g, c => c.toUpperCase());">
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Zip</label>
          <input type="text" name="nomineeZip[]" class="zip-input" maxlength="6"
                 oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0, 6);" required>
          <small class="zipError"></small>
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Address 1</label>
          <input type="text" name="nomineeAddress1[]" required>
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Address 2</label>
          <input type="text" name="nomineeAddress2[]">
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Address 3</label>
          <input type="text" name="nomineeAddress3[]">
        </div>

        <!-- ✅ AJAX — key "city" from AddCustomerDataLoader -->
        <div>
          <label>City <span class="dd-spinner jh-sp-city"></span></label>
          <select name="nomineeCity[]" class="jh-dd-city dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- ✅ AJAX — key "state" from AddCustomerDataLoader -->
        <div>
          <label>State <span class="dd-spinner jh-sp-state"></span></label>
          <select name="nomineeState[]" class="jh-dd-state dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- ✅ AJAX — key "relation" from AddCustomerDataLoader -->
        <div>
          <label>Relation with Nominee <span class="dd-spinner jh-sp-relation"></span></label>
          <select name="nomineeRelation[]" class="jh-dd-relation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- Declaration: last cell, checkbox+text centered -->
        <div class="declaration-cell">
          <label>
            <input type="checkbox" class="nomineeDeclaration" name="nomineeDeclaration[]" required>
            I confirm the joint holder details are correct
          </label>
        </div>

      </div><!-- /.personal-grid -->

    </div><!-- /.nominee-block -->
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- BUTTON SECTION -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="reset" style="background:#dc3545;color:#fff;border:none;padding:8px 24px;border-radius:5px;cursor:pointer;font-size:14px;">Cancel</button>
    <button type="submit" style="background:#28a745;color:#fff;border:none;padding:8px 24px;border-radius:5px;cursor:pointer;font-size:14px;">Save</button>
  </div>

</form>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- CUSTOMER LOOKUP MODAL (Locker Information fieldset)            -->
<!-- exact same structure as lockerNominee.jsp                      -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="jhCustomerLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:85%; max-width:920px;
                max-height:84vh; overflow:hidden; display:flex; flex-direction:column;
                box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">

        <!-- Header -->
        <div style="display:flex; align-items:center; justify-content:space-between;
                    padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73);
                    border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);
                            border-radius:6px;display:flex;align-items:center;
                            justify-content:center;font-size:17px;">🔍</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;letter-spacing:0.02em;">Customer Lookup</span>
            </div>
            <span onclick="closeJHCustomerLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);
                         cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'"
                  onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <!-- Loading indicator shown until content loads -->
        <div id="jhCustomerLookupLoading"
             style="display:flex;align-items:center;justify-content:center;
                    gap:10px;padding:40px 20px;color:#8066E8;font-size:14px;">
            <div style="width:18px;height:18px;border:2.5px solid #e0dcf8;
                        border-top-color:#8066E8;border-radius:50%;
                        animation:lk-spin 0.7s linear infinite;"></div>
            Loading customers...
        </div>

        <!-- Content loaded from lookupForCustomerId.jsp -->
        <div id="jhCustomerLookupContent"
             style="display:flex;flex-direction:column;flex:1;overflow:hidden;"></div>

    </div>
</div>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ═══════════════════════════════════════════════════════════════════════
// AJAX DROPDOWN LOADER
// ═══════════════════════════════════════════════════════════════════════

var _jhDropdownCache = null;

var JH_DD_MAP = {
    salutation : { sel: '.jh-dd-salutation', sp: '.jh-sp-salutation' },
    city       : { sel: '.jh-dd-city',       sp: '.jh-sp-city'       },
    state      : { sel: '.jh-dd-state',      sp: '.jh-sp-state'      },
    relation   : { sel: '.jh-dd-relation',   sp: '.jh-sp-relation'   }
};

function _fillJHSelect(selectEl, items) {
    selectEl.innerHTML = '';
    var blank = document.createElement('option');
    blank.value = '';
    blank.textContent = '-- Select --';
    selectEl.appendChild(blank);
    items.forEach(function(item) {
        var opt = document.createElement('option');
        opt.value = item.v;
        opt.textContent = item.l;
        selectEl.appendChild(opt);
    });
    selectEl.classList.remove('dd-loading');
    selectEl.style.color = '';
    selectEl.style.fontStyle = '';
}

function _fillJHBlock(block, data) {
    Object.keys(JH_DD_MAP).forEach(function(key) {
        var cfg   = JH_DD_MAP[key];
        var selEl = block.querySelector(cfg.sel);
        var spEl  = block.querySelector(cfg.sp);
        if (!selEl) return;
        var items = data[key];
        if (Array.isArray(items) && items.length > 0) {
            _fillJHSelect(selEl, items);
        } else {
            selEl.innerHTML = '<option value="">-- Error loading --</option>';
            selEl.classList.remove('dd-loading');
        }
        if (spEl) spEl.classList.add('done');
    });
}

(function loadJHDropdowns() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function(data) {
            if (data._error) console.warn('Joint holder dropdown warning:', data._error);
            _jhDropdownCache = data;
            var firstBlock = document.querySelector('.nominee-block');
            if (firstBlock) _fillJHBlock(firstBlock, data);
            console.log('✅ Joint holder dropdowns loaded via AddCustomerDataLoader');
        })
        .catch(function(err) {
            console.error('❌ Joint holder dropdown error:', err);
            var firstBlock = document.querySelector('.nominee-block');
            if (!firstBlock) return;
            Object.keys(JH_DD_MAP).forEach(function(key) {
                var cfg   = JH_DD_MAP[key];
                var selEl = firstBlock.querySelector(cfg.sel);
                var spEl  = firstBlock.querySelector(cfg.sp);
                if (selEl) {
                    selEl.innerHTML = '<option value="">-- Error: reload page --</option>';
                    selEl.classList.remove('dd-loading');
                    selEl.style.borderColor = '#f44336';
                }
                if (spEl) { spEl.style.background = '#f44336'; spEl.classList.add('done'); }
            });
        });
})();


// ── Joint holder serial renumbering ────────────────────────────────
function renumberNominees() {
    document.querySelectorAll('.nominee-block').forEach(function(card, idx) {
        var serial = card.querySelector('.nominee-serial');
        if (serial) serial.textContent = idx + 1;
        card.querySelectorAll('.nomineeHasCustomerRadio').forEach(function(r) {
            r.name = 'nomineeHasCustomerID_' + (idx + 1);
        });
    });
}

// ── Add joint holder card (clones the first card) ───────────────────
function addNominee() {
    var fieldset  = document.getElementById('nomineeFieldset');
    var firstCard = fieldset.querySelector('.nominee-block');
    var newCard   = firstCard.cloneNode(true);

    newCard.querySelectorAll('input, select, textarea').forEach(function(el) {
        if (el.type === 'radio')    { el.checked = (el.value === 'no'); return; }
        if (el.type === 'checkbox') { el.checked = false; return; }
        el.value = '';
    });

    var cidContainer = newCard.querySelector('.nomineeCustomerIDContainer');
    if (cidContainer) cidContainer.style.display = 'none';

    newCard.querySelectorAll('.zipError').forEach(function(el) { el.textContent = ''; });

    newCard.querySelectorAll('.dd-spinner').forEach(function(sp) { sp.classList.remove('done'); });

    Object.keys(JH_DD_MAP).forEach(function(key) {
        var selEl = newCard.querySelector(JH_DD_MAP[key].sel);
        if (selEl) {
            selEl.innerHTML = '<option value="">Loading...</option>';
            selEl.classList.add('dd-loading');
        }
    });

    var blocks = fieldset.querySelectorAll('.nominee-block');
    blocks[blocks.length - 1].insertAdjacentElement('afterend', newCard);
    renumberNominees();

    if (_jhDropdownCache) {
        _fillJHBlock(newCard, _jhDropdownCache);
    } else {
        fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
            .then(function(res) { return res.json(); })
            .then(function(data) {
                _jhDropdownCache = data;
                _fillJHBlock(newCard, data);
            });
    }
}

// ── Remove joint holder card ────────────────────────────────────────
function removeNominee(btn) {
    var blocks = document.querySelectorAll('.nominee-block');
    if (blocks.length <= 1) {
        alert('At least one joint holder is required.');
        return;
    }
    btn.closest('.nominee-block').remove();
    renumberNominees();
}

// ── Toggle Customer ID container visibility ─────────────────────────
function toggleNomineeCustomerID(radio) {
    var card      = radio.closest('.nominee-block');
    var container = card.querySelector('.nomineeCustomerIDContainer');
    if (!container) return;
    container.style.display = (radio.value === 'yes') ? 'flex' : 'none';
    var input = container.querySelector('.nomineeCustomerIDInput');
    if (input && radio.value !== 'yes') input.value = '';
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOMER LOOKUP (Locker Information fieldset) — same pattern as lockerNominee.jsp
// ═══════════════════════════════════════════════════════════════════════

function openCustomerLookup(triggerEl) {
    document.getElementById('jhCustomerLookupModal').style.display = 'flex';
    document.getElementById('jhCustomerLookupLoading').style.display = 'flex';
    document.getElementById('jhCustomerLookupContent').innerHTML = '';

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/lookupForCustomerId.jsp')
        .then(function(res) { return res.text(); })
        .then(function(html) {
            document.getElementById('jhCustomerLookupLoading').style.display = 'none';
            var content = document.getElementById('jhCustomerLookupContent');
            content.innerHTML = html;
            content.querySelectorAll('script').forEach(function(s) {
                var ns = document.createElement('script');
                ns.textContent = s.textContent;
                document.body.appendChild(ns);
                document.body.removeChild(ns);
            });
        });
}

function closeJHCustomerLookup() {
    document.getElementById('jhCustomerLookupModal').style.display = 'none';
}

// Called by lookupForCustomerId.jsp when a row is clicked (Locker Information fieldset)
window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
    document.getElementById('customerID').value = customerId;

    closeJHCustomerLookup();
};

// ═══════════════════════════════════════════════════════════════════════
// JOINT HOLDER CARD — Customer Lookup (same pattern as lockerNominee.jsp)
// ═══════════════════════════════════════════════════════════════════════

var _activeJHCard = null;

function openJHCustomerLookup(triggerEl) {
    _activeJHCard = triggerEl.closest('.nominee-block');
    document.getElementById('jhCustomerLookupModal').style.display = 'flex';
    document.getElementById('jhCustomerLookupLoading').style.display = 'flex';
    document.getElementById('jhCustomerLookupContent').innerHTML = '';

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/lookupForCustomerId.jsp')
        .then(function(res) { return res.text(); })
        .then(function(html) {
            document.getElementById('jhCustomerLookupLoading').style.display = 'none';
            var content = document.getElementById('jhCustomerLookupContent');
            content.innerHTML = html;
            content.querySelectorAll('script').forEach(function(s) {
                var ns = document.createElement('script');
                ns.textContent = s.textContent;
                document.body.appendChild(ns);
                document.body.removeChild(ns);
            });
            // Switch setCustomerData to joint holder card mode
            window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
                if (!_activeJHCard) return;

                var idInput = _activeJHCard.querySelector('.nomineeCustomerIDInput');
                if (idInput) idInput.value = customerId;

                closeJHCustomerLookup();

                fetch(window.APP_CONTEXT_PATH + '/OpenAccount/getCustomerDetails.jsp?customerId=' + encodeURIComponent(customerId))
                    .then(function(res) { return res.json(); })
                    .then(function(data) {
                        if (!data.success || !data.customer) return;
                        var c = data.customer;

                        var fieldMap = {
                            'nomineeName[]'     : c.customerName || '',
                            'nomineeAddress1[]' : c.address1     || '',
                            'nomineeAddress2[]' : c.address2     || '',
                            'nomineeAddress3[]' : c.address3     || '',
                            'nomineeZip[]'      : c.zip ? String(c.zip) : '' 
                        };

                        Object.keys(fieldMap).forEach(function(name) {
                            var el = _activeJHCard.querySelector('[name="' + name + '"]');
                            if (el) el.value = fieldMap[name];
                        });

                        var ddMap = {
                            'nomineeCity[]'  : c.city  || '',
                            'nomineeState[]' : c.state || ''
                        };

                        Object.keys(ddMap).forEach(function(name) {
                            var sel = _activeJHCard.querySelector('[name="' + name + '"]');
                            if (!sel || !ddMap[name]) return;
                            for (var i = 0; i < sel.options.length; i++) {
                                if (sel.options[i].value === ddMap[name] ||
                                    sel.options[i].text  === ddMap[name]) {
                                    sel.selectedIndex = i;
                                    break;
                                }
                            }
                        });
                    })
                    .catch(function(err) {
                        console.error('Failed to fetch joint holder customer details:', err);
                    });

                // Restore base setCustomerData for the Locker Information fieldset
                window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
                    document.getElementById('customerID').value = customerId;
                    closeJHCustomerLookup();
                };
            };
        });
}

// ── Form validation ─────────────────────────────────────────────────
function validateForm() {
    var valid = true;

    document.querySelectorAll('.zip-input').forEach(function(inp) {
        var errEl = inp.nextElementSibling;
        if (inp.value.length !== 6 || !/^\d{6}$/.test(inp.value)) {
            if (errEl) errEl.textContent = 'Must be exactly 6 digits';
            valid = false;
        } else {
            if (errEl) errEl.textContent = '';
        }
    });

    if (valid) {
        var unchecked = false;
        document.querySelectorAll('.nomineeDeclaration').forEach(function(cb) {
            if (!cb.checked) unchecked = true;
        });
        if (unchecked) {
            alert('Please accept the declaration for all joint holders.');
            valid = false;
        }
    }

    return valid;
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath ? window.buildBreadcrumbPath('Lockers/lockerJointHolder.jsp') : 'Locker Joint Holder'
        );
    }
};
</script>

</body>
</html>
