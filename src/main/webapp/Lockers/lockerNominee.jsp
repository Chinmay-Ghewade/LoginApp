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
  <title>Locker Nominee Management</title>
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

    .nominee-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
    }
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
    .nominee-cid-row .input-icon-box {
      display: flex;
    }
    .nominee-block {
      border: 1px solid #c9c5e8;
      border-radius: 6px;
      padding: 14px 16px;
      margin-bottom: 16px;
    }
    .nominee-block:last-of-type {
      margin-bottom: 4px;
    }
    .form-buttons {
      display: flex;
      gap: 10px;
      justify-content: center;
      margin-top: 4px;
    }
    .nominee-block .personal-grid {
      display: grid !important;
      grid-template-columns: repeat(4, 1fr) !important;
      gap: 12px !important;
      align-items: end !important;
      width: 100% !important;
    }
    .nominee-block .personal-grid > div {
      display: flex !important;
      flex-direction: column !important;
      gap: 4px !important;
      min-width: 0 !important;
      width: 100% !important;
    }
    .nominee-block .personal-grid input,
    .nominee-block .personal-grid select {
      width: 100% !important;
      box-sizing: border-box !important;
      min-width: 0 !important;
      max-width: 100% !important;
      display: block !important;
    }
    .nominee-block .personal-grid .zip-input + small.zipError {
      position: absolute !important;
      font-size: 11px !important;
      color: red !important;
      margin-top: 2px !important;
    }
    .nominee-block .personal-grid div:has(.zip-input) {
      position: relative !important;
    }
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

    /* ── input-icon-box for locker info fieldset ── */
    .input-icon-box { position: relative; display: flex; align-items: center; }
    .input-icon-box input { padding-right: 36px; }
    .inside-icon-btn {
      position: absolute; right: 4px;
      background: none; border: none; font-size: 16px;
      cursor: pointer; color: #373279; padding: 0 4px;
    }

    /* ── Lookup table styling scoped to nominee lookup content ── */
    #nomineeCustomerLookupContent .lookup-title {
      font-size: 1.05rem;
      font-weight: 700;
      color: var(--lk-primary);
      padding: 16px 18px 12px 18px;
      border-bottom: 1px solid var(--lk-border-light);
      display: flex;
      align-items: center;
      gap: 10px;
    }
    #nomineeCustomerLookupContent .search-box {
      padding: 14px 18px 8px 18px;
      background: var(--lk-primary-light);
      border-bottom: 1px solid var(--lk-border-light);
    }
    #nomineeCustomerLookupContent #customerSearch {
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
    #nomineeCustomerLookupContent #customerSearch::placeholder { color: #a090cc; }
    #nomineeCustomerLookupContent #customerSearch:focus {
      border-color: var(--lk-primary);
      box-shadow: 0 0 0 3px rgba(55,50,121,0.10);
    }
    #nomineeCustomerLookupContent .customer-count {
      font-size: 0.75rem;
      color: var(--lk-text-muted);
      text-align: right;
      padding: 6px 18px;
      border-bottom: 1px solid var(--lk-border-light);
    }
    #nomineeCustomerLookupContent .customer-count strong { color: var(--lk-primary); }
    #nomineeCustomerLookupContent .table-container {
      flex: 1;
      overflow-y: auto;
      overflow-x: auto;
      min-height: 0;
    }
    #nomineeCustomerLookupContent .table-container::-webkit-scrollbar { width: 7px; }
    #nomineeCustomerLookupContent .table-container::-webkit-scrollbar-track { background: var(--lk-primary-light); }
    #nomineeCustomerLookupContent .table-container::-webkit-scrollbar-thumb { background: var(--lk-border); border-radius: 10px; }
    #nomineeCustomerLookupContent #customerTable {
      width: 100%;
      border-collapse: collapse;
      font-family: var(--lk-font);
    }
    #nomineeCustomerLookupContent #customerTable thead tr {
      background: linear-gradient(90deg, var(--lk-primary) 0%, var(--lk-accent) 100%);
      position: sticky;
      top: 0;
      z-index: 2;
    }
    #nomineeCustomerLookupContent #customerTable thead th {
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
    #nomineeCustomerLookupContent #customerTable thead th:last-child { border-right: none; }
    #nomineeCustomerLookupContent #customerTable tbody tr {
      border-bottom: 1px solid var(--lk-border-light);
      cursor: pointer;
      transition: background 0.18s ease, transform 0.1s ease;
      border-left: 3px solid transparent;
    }
    #nomineeCustomerLookupContent #customerTable tbody tr:nth-child(even) { background: var(--lk-row-stripe); }
    #nomineeCustomerLookupContent #customerTable tbody tr:hover {
      background: var(--lk-row-hover);
      border-left-color: var(--lk-primary-mid);
      transform: translateX(2px);
    }
    #nomineeCustomerLookupContent #customerTable tbody td {
      padding: 11px 16px;
      font-size: 0.875rem;
      color: var(--lk-text);
      vertical-align: middle;
      border-right: 1px solid var(--lk-border-light);
    }
    #nomineeCustomerLookupContent #customerTable tbody td:last-child { border-right: none; }
    #nomineeCustomerLookupContent #customerTable tbody td:first-child {
      font-weight: 700;
      color: var(--lk-primary);
      font-size: 0.84rem;
      white-space: nowrap;
    }
  </style>
</head>
<body>

<form action="LockerNomineeServlet" method="post" onsubmit="return validateForm()">

  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 1: LOCKER INFORMATION -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Information</legend>
    <div class="form-grid">

      <!-- ── NEW: Customer ID with lookup ── -->
      <div>
        <label>Customer ID</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="lockerCustomerId" id="lockerCustomerId"
                 class="form-input" readonly>
          <button type="button" class="icon-btn"
                  onclick="openLockerInfoCustomerLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;" title="Search Customer">…</button>
        </div>
      </div>

      <div>
        <label>Locker Number</label>
        <input type="text" name="lockerNumber" id="lockerNumber" readonly
               style="background:#f4f2fc;">
      </div>

      <div>
        <label>Locker Type</label>
        <input type="text" name="lockerType" id="lockerType" readonly
               style="background:#f4f2fc;">
      </div>

    </div>
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: NOMINEE                                            -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <fieldset id="nomineeFieldset">
    <legend>
      Nominee
      <button type="button" onclick="addNominee()"
        style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
        ➕
      </button>
    </legend>

    <div class="nominee-card nominee-block">

      <div class="nominee-header">
        <div class="nominee-title" style="font-weight:bold; font-size:15px; color:#373279;">
          Nominee <span class="nominee-serial">1</span>
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
            <input type="text" class="nomineeCustomerIDInput" name="nomineeCustomerID[]" onclick="openNomineeCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openNomineeCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <div class="personal-grid">

        <div>
          <label>Salutation Code <span class="dd-spinner nominee-sp-salutation"></span></label>
          <select name="nomineeSalutation[]" class="nominee-dd-salutation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>Nominee Name</label>
          <input type="text" name="nomineeName[]" required
                 oninput="this.value = this.value
                   .replace(/[^A-Za-z ]/g, '')
                   .replace(/\s{2,}/g, ' ')
                   .replace(/^\s+/g, '')
                   .toLowerCase()
                   .replace(/\b\w/g, c => c.toUpperCase());">
        </div>

        <div>
          <label>Gender</label>
          <select name="nomineeGender[]" required>
            <option value="">-- Select Gender --</option>
            <option>Male</option>
            <option>Female</option>
            <option>Other</option>
          </select>
        </div>

        <div>
          <label>Address 1</label>
          <input type="text" name="nomineeAddress1[]" required>
        </div>

        <div>
          <label>Address 2</label>
          <input type="text" name="nomineeAddress2[]">
        </div>

        <div>
          <label>Address 3</label>
          <input type="text" name="nomineeAddress3[]">
        </div>

        <div>
          <label>City <span class="dd-spinner nominee-sp-city"></span></label>
          <select name="nomineeCity[]" class="nominee-dd-city dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>State <span class="dd-spinner nominee-sp-state"></span></label>
          <select name="nomineeState[]" class="nominee-dd-state dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>Country <span class="dd-spinner nominee-sp-country"></span></label>
          <select name="nomineeCountry[]" class="nominee-dd-country dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div>
          <label>Mobile Number</label>
          <input type="text" name="nomineeMobile[]"
                 oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0, 10);">
        </div>

        <div>
          <label>Zip</label>
          <input type="text" name="nomineeZip[]" class="zip-input" maxlength="6"
                 oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0, 6);" required>
          <small class="zipError"></small>
        </div>

        <div>
          <label>Relation with Nominee <span class="dd-spinner nominee-sp-relation"></span></label>
          <select name="nomineeRelation[]" class="nominee-dd-relation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <div class="declaration-cell">
          <label>
            <input type="checkbox" class="nomineeDeclaration" name="nomineeDeclaration[]" required>
            I confirm the nominee details are correct
          </label>
        </div>

      </div><!-- /.personal-grid -->
    </div><!-- /.nominee-block -->
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- BUTTON SECTION -->
  <!-- ════════════════════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="reset">Reset</button>
    <button type="submit" style="background:#28a745;color:#fff;border:none;padding:8px 24px;border-radius:5px;cursor:pointer;font-size:14px;">Save Nominee</button>
  </div>

</form>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- CUSTOMER LOOKUP MODAL — shared for both locker info & nominees  -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="nomineeCustomerLookupModal" class="customer-modal">
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
            <span onclick="closeNomineeCustomerLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);
                         cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'"
                  onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <!-- Loading indicator -->
        <div id="nomineeCustomerLookupLoading"
             style="display:flex;align-items:center;justify-content:center;
                    gap:10px;padding:40px 20px;color:#8066E8;font-size:14px;">
            <div style="width:18px;height:18px;border:2.5px solid #e0dcf8;
                        border-top-color:#8066E8;border-radius:50%;
                        animation:lk-spin 0.7s linear infinite;"></div>
            Loading customers...
        </div>

        <!-- Content loaded from lookupForCustomerId.jsp -->
        <div id="nomineeCustomerLookupContent"
             style="display:flex;flex-direction:column;flex:1;overflow:hidden;"></div>

    </div>
</div>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ── Tracks which context opened the lookup modal ────────────────────
// 'lockerInfo' = Fieldset 1 Customer ID
// nominee card element = Fieldset 2 nominee card
var _nomineeModalContext = null;

// ═══════════════════════════════════════════════════════════════════════
// AJAX DROPDOWN LOADER
// ═══════════════════════════════════════════════════════════════════════

var _nomineeDropdownCache = null;

var NOMINEE_DD_MAP = {
    salutation : { sel: '.nominee-dd-salutation', sp: '.nominee-sp-salutation' },
    relation   : { sel: '.nominee-dd-relation',   sp: '.nominee-sp-relation'   },
    city       : { sel: '.nominee-dd-city',        sp: '.nominee-sp-city'       },
    state      : { sel: '.nominee-dd-state',       sp: '.nominee-sp-state'      },
    country    : { sel: '.nominee-dd-country',     sp: '.nominee-sp-country'    }
};

function _fillNomineeSelect(selectEl, items) {
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

function _fillNomineeBlock(block, data) {
    Object.keys(NOMINEE_DD_MAP).forEach(function(key) {
        var cfg   = NOMINEE_DD_MAP[key];
        var selEl = block.querySelector(cfg.sel);
        var spEl  = block.querySelector(cfg.sp);
        if (!selEl) return;
        var items = data[key];
        if (Array.isArray(items) && items.length > 0) {
            _fillNomineeSelect(selEl, items);
        } else {
            selEl.innerHTML = '<option value="">-- Error loading --</option>';
            selEl.classList.remove('dd-loading');
        }
        if (spEl) spEl.classList.add('done');
    });
}

(function loadNomineeDropdowns() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function(data) {
            if (data._error) console.warn('Nominee dropdown warning:', data._error);
            _nomineeDropdownCache = data;
            var firstBlock = document.querySelector('.nominee-block');
            if (firstBlock) _fillNomineeBlock(firstBlock, data);
        })
        .catch(function(err) {
            console.error('Nominee dropdown error:', err);
            var firstBlock = document.querySelector('.nominee-block');
            if (!firstBlock) return;
            Object.keys(NOMINEE_DD_MAP).forEach(function(key) {
                var cfg   = NOMINEE_DD_MAP[key];
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


// ── Renumber nominee serials & radio names after add/remove ────────
function renumberNominees() {
    document.querySelectorAll('.nominee-block').forEach(function(card, idx) {
        var serial = card.querySelector('.nominee-serial');
        if (serial) serial.textContent = idx + 1;
        card.querySelectorAll('.nomineeHasCustomerRadio').forEach(function(r) {
            r.name = 'nomineeHasCustomerID_' + (idx + 1);
        });
    });
}

// ── Add new nominee card ────────────────────────────────────────────
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

    Object.keys(NOMINEE_DD_MAP).forEach(function(key) {
        var selEl = newCard.querySelector(NOMINEE_DD_MAP[key].sel);
        if (selEl) {
            selEl.innerHTML = '<option value="">Loading...</option>';
            selEl.classList.add('dd-loading');
        }
    });

    var blocks = fieldset.querySelectorAll('.nominee-block');
    blocks[blocks.length - 1].insertAdjacentElement('afterend', newCard);
    renumberNominees();

    if (_nomineeDropdownCache) {
        _fillNomineeBlock(newCard, _nomineeDropdownCache);
    } else {
        fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
            .then(function(res) { return res.json(); })
            .then(function(data) {
                _nomineeDropdownCache = data;
                _fillNomineeBlock(newCard, data);
            });
    }
}

// ── Remove nominee card ─────────────────────────────────────────────
function removeNominee(btn) {
    var blocks = document.querySelectorAll('.nominee-block');
    if (blocks.length <= 1) {
        alert('At least one nominee is required.');
        return;
    }
    btn.closest('.nominee-block').remove();
    renumberNominees();
}

// ── Toggle Customer ID field visibility ─────────────────────────────
function toggleNomineeCustomerID(radio) {
    var card      = radio.closest('.nominee-block');
    var container = card.querySelector('.nomineeCustomerIDContainer');
    if (!container) return;
    container.style.display = (radio.value === 'yes') ? 'flex' : 'none';
    var input = container.querySelector('.nomineeCustomerIDInput');
    if (input && radio.value !== 'yes') input.value = '';
}


// ═══════════════════════════════════════════════════════════════════════
// LOCKER INFO — Customer ID lookup (Fieldset 1)
// Fetches LOCKERACCOUNT where CUSTOMER_ID = ? and ACCOUNT_STATUS = 'E'
// (which corresponds to BRANCHLOCKER status 'H' = hired)
// ═══════════════════════════════════════════════════════════════════════
function openLockerInfoCustomerLookup() {
    _nomineeModalContext = 'lockerInfo';
    _openSharedCustomerLookup();
}

function _fetchLockerDetailsByCustomer(customerId) {
    fetch(window.APP_CONTEXT_PATH + '/loaders/LockerDetailsByCustomerLoader?customerId='
            + encodeURIComponent(customerId))
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (data.success && data.locker) {
                document.getElementById('lockerNumber').value = data.locker.lockerNumber || '';
                document.getElementById('lockerType').value   = data.locker.lockerType   || '';
            } else {
                document.getElementById('lockerNumber').value = '';
                document.getElementById('lockerType').value   = '';
                showToast(data.message || 'No active locker found for this customer.', true);
            }
        })
        .catch(function(err) {
            console.error('Locker detail fetch error:', err);
            showToast('Failed to fetch locker details.', true);
        });
}


// ═══════════════════════════════════════════════════════════════════════
// NOMINEE CARD — Customer ID lookup (Fieldset 2)
// ═══════════════════════════════════════════════════════════════════════
function openNomineeCustomerLookup(triggerEl) {
    _nomineeModalContext = triggerEl.closest('.nominee-block');
    _openSharedCustomerLookup();
}


// ── Shared modal open ───────────────────────────────────────────────
function _openSharedCustomerLookup() {
    document.getElementById('nomineeCustomerLookupModal').style.display = 'flex';
    document.getElementById('nomineeCustomerLookupLoading').style.display = 'flex';
    document.getElementById('nomineeCustomerLookupContent').innerHTML = '';

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/lookupForCustomerId.jsp')
        .then(function(res) { return res.text(); })
        .then(function(html) {
            document.getElementById('nomineeCustomerLookupLoading').style.display = 'none';
            var content = document.getElementById('nomineeCustomerLookupContent');
            content.innerHTML = html;
            content.querySelectorAll('script').forEach(function(s) {
                var ns = document.createElement('script');
                ns.textContent = s.textContent;
                document.body.appendChild(ns);
                document.body.removeChild(ns);
            });
        });
}

function closeNomineeCustomerLookup() {
    document.getElementById('nomineeCustomerLookupModal').style.display = 'none';
}

// ── Called by lookupForCustomerId.jsp when a row is clicked ─────────
window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {

    if (_nomineeModalContext === 'lockerInfo') {
        // ── Fieldset 1: fill Customer ID then fetch locker details ──
        document.getElementById('lockerCustomerId').value = customerId;
        closeNomineeCustomerLookup();
        _fetchLockerDetailsByCustomer(customerId);

    } else if (_nomineeModalContext && _nomineeModalContext !== 'lockerInfo') {
        // ── Fieldset 2: fill nominee card fields ────────────────────
        var card = _nomineeModalContext;
        var idInput = card.querySelector('.nomineeCustomerIDInput');
        if (idInput) idInput.value = customerId;

        closeNomineeCustomerLookup();

        fetch(window.APP_CONTEXT_PATH + '/OpenAccount/getCustomerDetails.jsp?customerId='
                + encodeURIComponent(customerId))
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (!data.success || !data.customer) return;
                var c = data.customer;

                var fieldMap = {
                    'nomineeName[]'     : c.customerName || '',
                    'nomineeMobile[]'   : c.mobileNo     || '',
                    'nomineeAddress1[]' : c.address1     || '',
                    'nomineeAddress2[]' : c.address2     || '',
                    'nomineeAddress3[]' : c.address3     || '',
                    'nomineeZip[]'      : c.zip ? String(c.zip) : ''
                };
                Object.keys(fieldMap).forEach(function(name) {
                    var el = card.querySelector('[name="' + name + '"]');
                    if (el) el.value = fieldMap[name];
                });

                var ddMap = {
                    'nomineeCity[]'    : c.city    || '',
                    'nomineeState[]'   : c.state   || '',
                    'nomineeCountry[]' : c.country || ''
                };
                Object.keys(ddMap).forEach(function(name) {
                    var sel = card.querySelector('[name="' + name + '"]');
                    if (!sel || !ddMap[name]) return;
                    for (var i = 0; i < sel.options.length; i++) {
                        if (sel.options[i].value === ddMap[name] ||
                            sel.options[i].text  === ddMap[name]) {
                            sel.selectedIndex = i; break;
                        }
                    }
                });
            })
            .catch(function(err) {
                console.error('Failed to fetch nominee customer details:', err);
            });
    }
};

// ── Toast helper ────────────────────────────────────────────────────
function showToast(msg, isError) {
    Toastify({
        text: msg, duration: 3500, gravity: 'top', position: 'right', stopOnFocus: true,
        style: {
            background: isError
                ? 'linear-gradient(to right,#e53935,#b71c1c)'
                : 'linear-gradient(to right,#373279,#5a3ec8)',
            borderRadius: '8px', fontFamily: 'Arial,sans-serif', fontSize: '14px'
        }
    }).showToast();
}

// ── Form validation ─────────────────────────────────────────────────
function validateForm() {
    var valid = true;

    var shareInputs = document.querySelectorAll('input[name="nomineePercentageShare[]"]');
    var totalShare  = 0;
    shareInputs.forEach(function(inp) {
        var val = parseFloat(inp.value);
        if (isNaN(val) || val < 0 || val > 100) {
            alert('Each Percentage Share must be between 0 and 100.');
            valid = false;
        }
        totalShare += (isNaN(val) ? 0 : val);
    });
    if (valid && shareInputs.length > 0 && Math.round(totalShare) !== 100) {
        alert('Total Percentage Share must equal 100. Current: ' + totalShare.toFixed(2));
        valid = false;
    }

    if (valid) {
        document.querySelectorAll('.zip-input').forEach(function(inp) {
            var errEl = inp.nextElementSibling;
            if (inp.value.length !== 6 || !/^\d{6}$/.test(inp.value)) {
                if (errEl) errEl.textContent = 'Must be exactly 6 digits';
                valid = false;
            } else {
                if (errEl) errEl.textContent = '';
            }
        });
    }

    if (valid) {
        document.querySelectorAll('.nomineeDeclaration').forEach(function(cb) {
            if (!cb.checked) { valid = false; }
        });
        if (!valid) alert('Please accept the declaration for all nominees.');
    }

    return valid;
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath
                ? window.buildBreadcrumbPath('Lockers/lockerNominee.jsp')
                : 'Locker Nominee'
        );
    }
};
</script>

</body>
</html>
