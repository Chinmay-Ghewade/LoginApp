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
        <div style="display:flex; flex-direction:row; align-items:stretch; gap:0;">
          <input type="text" id="customerID" name="customerID" onclick="openCustomerLookup(this)" readonly style="flex:1; min-width:0; box-sizing:border-box;">
          <button type="button" onclick="openCustomerLookup(this)" title="Search Customer"
            style="background:#f0f0f0;border:1px solid #ccc;border-left:none;border-radius:0 4px 4px 0;padding:0 10px;cursor:pointer;flex-shrink:0;">🔍</button>
        </div>
      </div>

    </div>
  </fieldset>


  <!-- ════════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: JOINT HOLDER                                       -->
  <!-- 4 dropdowns use AJAX via AddCustomerDataLoader:                -->
  <!--   salutation | city | state | relation                         -->
  <!-- All other fields are plain inputs — no DB needed               -->
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

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ═══════════════════════════════════════════════════════════════════════
// AJAX DROPDOWN LOADER
// ✅ Reuses AddCustomerDataLoader — no new Java file needed.
// Keys used here must match exactly what AddCustomerDataLoader returns:
//   "salutation" | "city" | "state" | "relation"
// The other 8 keys in the response are ignored — causes zero issues.
// ═══════════════════════════════════════════════════════════════════════

// Fetched once on load → reused instantly for every addNominee() clone
var _jhDropdownCache = null;

// Only the 4 keys this page needs, mapped to their select/spinner classes
var JH_DD_MAP = {
    salutation : { sel: '.jh-dd-salutation', sp: '.jh-sp-salutation' },
    city       : { sel: '.jh-dd-city',       sp: '.jh-sp-city'       },
    state      : { sel: '.jh-dd-state',      sp: '.jh-sp-state'      },
    relation   : { sel: '.jh-dd-relation',   sp: '.jh-sp-relation'   }
};

// Fill one <select> from [{v, l}, ...] array
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

// Fill only the 4 joint holder dropdowns inside one block
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

// ── Fires once on page open ─────────────────────────────────────────
(function loadJHDropdowns() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')  // ✅ same Java file
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function(data) {
            if (data._error) console.warn('Joint holder dropdown warning:', data._error);
            _jhDropdownCache = data;                                    // cache for clones
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

    // Reset all field values
    newCard.querySelectorAll('input, select, textarea').forEach(function(el) {
        if (el.type === 'radio')    { el.checked = (el.value === 'no'); return; }
        if (el.type === 'checkbox') { el.checked = false; return; }
        el.value = '';
    });

    // Hide Customer ID container if present
    var cidContainer = newCard.querySelector('.nomineeCustomerIDContainer');
    if (cidContainer) cidContainer.style.display = 'none';

    // Clear zip errors
    newCard.querySelectorAll('.zipError').forEach(function(el) { el.textContent = ''; });

    // Reset spinners to visible
    newCard.querySelectorAll('.dd-spinner').forEach(function(sp) { sp.classList.remove('done'); });

    // Mark dropdowns as loading
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

    // Fill instantly from cache — no extra network call
    if (_jhDropdownCache) {
        _fillJHBlock(newCard, _jhDropdownCache);
    } else {
        // Edge case: cache not ready yet — refetch same loader
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

// ── Customer lookup (Locker Information fieldset) ───────────────────
function openCustomerLookup(triggerEl) {
    // TODO: open modal and on select → document.getElementById('customerID').value = selectedId
}

// ── Nominee customer lookup ─────────────────────────────────────────
function openNomineeCustomerLookup(triggerEl) {
    var card  = triggerEl.closest('.nominee-block');
    var input = card.querySelector('.nomineeCustomerIDInput');
    // TODO: open modal and on select → input.value = selectedId
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
