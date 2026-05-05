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
  <link rel="stylesheet" href="../css/addCustomer.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
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

      <div>
        <label>Locker Number</label>
        <input type="text" name="lockerNumber" id="lockerNumber" required>
      </div>

      <div>
        <label>Locker Type</label>
        <input type="text" name="lockerType" id="lockerType" required>
      </div>

    </div>
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: NOMINEE                                            -->
  <!-- 5 dropdowns use AJAX via AddCustomerDataLoader:                -->
  <!--   salutation | relation | city | state | country               -->
  <!-- Gender is static (Male/Female/Other) — no DB needed            -->
  <!-- All other fields are plain inputs — no DB needed               -->
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

        <!-- ✅ AJAX — key "salutation" from AddCustomerDataLoader -->
        <div>
          <label>Salutation Code <span class="dd-spinner nominee-sp-salutation"></span></label>
          <select name="nomineeSalutation[]" class="nominee-dd-salutation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- plain input — no DB -->
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

        <!-- static options — no DB -->
        <div>
          <label>Gender</label>
          <select name="nomineeGender[]" required>
            <option value="">-- Select Gender --</option>
            <option>Male</option>
            <option>Female</option>
            <option>Other</option>
          </select>
        </div>

        <!-- plain inputs — no DB -->
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

        <!-- ✅ AJAX — key "city" from AddCustomerDataLoader -->
        <div>
          <label>City <span class="dd-spinner nominee-sp-city"></span></label>
          <select name="nomineeCity[]" class="nominee-dd-city dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- ✅ AJAX — key "state" from AddCustomerDataLoader -->
        <div>
          <label>State <span class="dd-spinner nominee-sp-state"></span></label>
          <select name="nomineeState[]" class="nominee-dd-state dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- ✅ AJAX — key "country" from AddCustomerDataLoader -->
        <div>
          <label>Country <span class="dd-spinner nominee-sp-country"></span></label>
          <select name="nomineeCountry[]" class="nominee-dd-country dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Mobile Number</label>
          <input type="text" name="nomineeMobile[]"
                 oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0, 10);">
        </div>

        <!-- plain input — no DB -->
        <div>
          <label>Zip</label>
          <input type="text" name="nomineeZip[]" class="zip-input" maxlength="6"
                 oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0, 6);" required>
          <small class="zipError"></small>
        </div>

        <!-- ✅ AJAX — key "relation" from AddCustomerDataLoader -->
        <div>
          <label>Relation with Nominee <span class="dd-spinner nominee-sp-relation"></span></label>
          <select name="nomineeRelation[]" class="nominee-dd-relation dd-loading" required>
            <option value="">Loading...</option>
          </select>
        </div>

        <!-- declaration — no DB -->
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

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ═══════════════════════════════════════════════════════════════════════
// AJAX DROPDOWN LOADER
// ✅ Calls AddCustomerDataLoader — no new Java file needed.
//
// AddCustomerDataLoader returns 12 keys. We only READ 5 of them:
//   "salutation" → Salutation Code
//   "relation"   → Relation with Nominee
//   "city"       → City
//   "state"      → State
//   "country"    → Country
//
// The other 7 keys (religion, caste, category, etc.) arrive in the
// response but are simply ignored — causes zero issues.
// ═══════════════════════════════════════════════════════════════════════

// Fetched once on load → reused instantly for every addNominee() clone
var _nomineeDropdownCache = null;

// Only the 5 keys this page needs, mapped to their select/spinner classes
var NOMINEE_DD_MAP = {
    salutation : { sel: '.nominee-dd-salutation', sp: '.nominee-sp-salutation' },
    relation   : { sel: '.nominee-dd-relation',   sp: '.nominee-sp-relation'   },
    city       : { sel: '.nominee-dd-city',        sp: '.nominee-sp-city'       },
    state      : { sel: '.nominee-dd-state',       sp: '.nominee-sp-state'      },
    country    : { sel: '.nominee-dd-country',     sp: '.nominee-sp-country'    }
};

// Fill one <select> from [{v, l}, ...] array
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

// Fill only the 5 nominee dropdowns inside one nominee block
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

// ── Fires once on page open ─────────────────────────────────────────
(function loadNomineeDropdowns() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')  // ✅ same Java file
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function(data) {
            if (data._error) console.warn('Nominee dropdown warning:', data._error);
            _nomineeDropdownCache = data;                               // cache for clones
            var firstBlock = document.querySelector('.nominee-block');
            if (firstBlock) _fillNomineeBlock(firstBlock, data);
            console.log('✅ Nominee dropdowns loaded via AddCustomerDataLoader');
        })
        .catch(function(err) {
            console.error('❌ Nominee dropdown error:', err);
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

    // Reset all field values
    newCard.querySelectorAll('input, select, textarea').forEach(function(el) {
        if (el.type === 'radio')    { el.checked = (el.value === 'no'); return; }
        if (el.type === 'checkbox') { el.checked = false; return; }
        el.value = '';
    });

    // Hide Customer ID container
    var cidContainer = newCard.querySelector('.nomineeCustomerIDContainer');
    if (cidContainer) cidContainer.style.display = 'none';

    // Clear any zip errors
    newCard.querySelectorAll('.zipError').forEach(function(el) { el.textContent = ''; });

    // Reset spinners to visible
    newCard.querySelectorAll('.dd-spinner').forEach(function(sp) { sp.classList.remove('done'); });

    // Mark nominee dropdowns as loading
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

    // Fill from cache instantly — no extra network call
    if (_nomineeDropdownCache) {
        _fillNomineeBlock(newCard, _nomineeDropdownCache);
    } else {
        // Edge case: cache not ready yet — refetch same loader
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

// ── Customer lookup modal trigger ───────────────────────────────────
function openNomineeCustomerLookup(triggerEl) {
    var card  = triggerEl.closest('.nominee-block');
    var input = card.querySelector('.nomineeCustomerIDInput');
    // TODO: open modal → on select: input.value = selectedCustomerId
}

// ── Form validation ─────────────────────────────────────────────────
function validateForm() {
    var valid = true;

    // Percentage share check (if field exists)
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

    // Zip validation
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

    // Declaration check
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
