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

    /* ── LAYOUT FIXES ONLY — no color/font changes ── */

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

    /* Each nominee block is visually separated like its own sub-fieldset */
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

    /* Equal 3-column grid — overrides addCustomer.css for nominee fields only */
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

    /* ALL inputs AND selects same width — overrides addCustomer.css */
    .nominee-block .personal-grid input,
    .nominee-block .personal-grid select {
      width: 100% !important;
      box-sizing: border-box !important;
      min-width: 0 !important;
      max-width: 100% !important;
      display: block !important;
    }

    /* zipError must not affect cell height / grid alignment */
    .nominee-block .personal-grid .zip-input + small.zipError {
      position: absolute !important;
      font-size: 11px !important;
      color: red !important;
      margin-top: 2px !important;
    }
    .nominee-block .personal-grid div:has(.zip-input) {
      position: relative !important;
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
  <!-- FIELDSET 2: NOMINEE -->
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

      <!-- Header: title left, remove button right -->
      <div class="nominee-header">
        <div class="nominee-title"
             style="font-weight:bold; font-size:15px; color:#373279;">
          Nominee <span class="nominee-serial">1</span>
        </div>
        <button type="button" class="nominee-remove" onclick="removeNominee(this)">✖</button>
      </div>

      <!-- Customer ID row: radio + CID field side by side -->
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
          <label>Salutation Code</label>
          <select name="nomineeSalutation[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psSalutation = null;
              ResultSet rsSalutation = null;
              try (Connection connSal = DBConnection.getConnection()) {
                psSalutation = connSal.prepareStatement(
                  "SELECT SALUTATION_CODE FROM GLOBALCONFIG.SALUTATION ORDER BY SALUTATION_CODE");
                rsSalutation = psSalutation.executeQuery();
                while (rsSalutation.next()) {
                  String sal = rsSalutation.getString("SALUTATION_CODE");
            %>
                  <option value="<%= sal %>"><%= sal %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading Salutation Code</option>");
              } finally {
                if (rsSalutation != null) rsSalutation.close();
                if (psSalutation != null) psSalutation.close();
              }
            %>
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
          <label>City</label>
          <select name="nomineeCity[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psCity = null;
              ResultSet rsCity = null;
              try (Connection connCt = DBConnection.getConnection()) {
                psCity = connCt.prepareStatement(
                  "SELECT CITY_CODE, NAME FROM GLOBALCONFIG.CITY ORDER BY UPPER(NAME)");
                rsCity = psCity.executeQuery();
                while (rsCity.next()) {
                  String cyc = rsCity.getString("CITY_CODE");
                  String cyn = rsCity.getString("NAME");
            %>
                  <option value="<%= cyc %>"><%= cyn %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading cities</option>");
              } finally {
                if (rsCity != null) rsCity.close();
                if (psCity != null) psCity.close();
              }
            %>
          </select>
        </div>
        
        <div>
          <label>State</label>
          <select name="nomineeState[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psState = null;
              ResultSet rsState = null;
              try (Connection connSt = DBConnection.getConnection()) {
                psState = connSt.prepareStatement(
                  "SELECT STATE_CODE, NAME FROM GLOBALCONFIG.STATE ORDER BY NAME");
                rsState = psState.executeQuery();
                while (rsState.next()) {
                  String sc = rsState.getString("STATE_CODE");
                  String sn = rsState.getString("NAME");
            %>
                  <option value="<%= sc %>"><%= sn %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading states</option>");
              } finally {
                if (rsState != null) rsState.close();
                if (psState != null) psState.close();
              }
            %>
          </select>
        </div>
        
         <div>
          <label>Country</label>
          <select name="nomineeCountry[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psCountry = null;
              ResultSet rsCountry = null;
              try (Connection connC = DBConnection.getConnection()) {
                psCountry = connC.prepareStatement(
                  "SELECT COUNTRY_CODE, NAME FROM GLOBALCONFIG.COUNTRY ORDER BY NAME");
                rsCountry = psCountry.executeQuery();
                while (rsCountry.next()) {
                  String cc = rsCountry.getString("COUNTRY_CODE");
                  String cn = rsCountry.getString("NAME");
            %>
                  <option value="<%= cc %>"><%= cn %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading countries</option>");
              } finally {
                if (rsCountry != null) rsCountry.close();
                if (psCountry != null) psCountry.close();
              }
            %>
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
          <label>Relation with Nominee</label>
          <select name="nomineeRelation[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psRelation = null;
              ResultSet rsRelation = null;
              try (Connection connRel = DBConnection.getConnection()) {
                psRelation = connRel.prepareStatement(
                  "SELECT RELATION_ID, DESCRIPTION FROM GLOBALCONFIG.RELATION ORDER BY RELATION_ID");
                rsRelation = psRelation.executeQuery();
                while (rsRelation.next()) {
                  String rid  = rsRelation.getString("RELATION_ID");
                  String rdesc = rsRelation.getString("DESCRIPTION");
            %>
                  <option value="<%= rid %>"><%= rdesc %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading relation</option>");
              } finally {
                if (rsRelation != null) rsRelation.close();
                if (psRelation != null) psRelation.close();
              }
            %>
          </select>
        </div>

        <!-- Declaration: last cell in the grid, aligned bottom-right -->
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

// ── Nominee serial renumbering ──────────────────────────────────────
function renumberNominees() {
  document.querySelectorAll('.nominee-block').forEach(function(card, idx) {
    var serial = card.querySelector('.nominee-serial');
    if (serial) serial.textContent = idx + 1;

    var radios = card.querySelectorAll('.nomineeHasCustomerRadio');
    radios.forEach(function(r) {
      r.name = 'nomineeHasCustomerID_' + (idx + 1);
    });
  });
}

// ── Add nominee card (clones the first card) ────────────────────────
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

  var blocks = fieldset.querySelectorAll('.nominee-block');
  blocks[blocks.length - 1].insertAdjacentElement('afterend', newCard);

  renumberNominees();
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

// ── Toggle Customer ID container visibility ─────────────────────────
function toggleNomineeCustomerID(radio) {
  var card      = radio.closest('.nominee-block');
  var container = card.querySelector('.nomineeCustomerIDContainer');
  if (!container) return;
  container.style.display = (radio.value === 'yes') ? 'flex' : 'none';

  var input = container.querySelector('.nomineeCustomerIDInput');
  if (input && radio.value !== 'yes') input.value = '';
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
  if (valid && Math.round(totalShare) !== 100) {
    alert('Total Percentage Share across all nominees must equal 100. Current total: ' + totalShare.toFixed(2));
    valid = false;
  }

  if (valid) {
    document.querySelectorAll('.zip-input').forEach(function(inp) {
      if (inp.closest('.nominee-block') && (inp.value.length !== 6 || !/^\d{6}$/.test(inp.value))) {
        inp.nextElementSibling.textContent = 'Must be exactly 6 digits';
        valid = false;
      } else if (inp.nextElementSibling) {
        inp.nextElementSibling.textContent = '';
      }
    });
  }

  if (valid) {
    var unchecked = false;
    document.querySelectorAll('.nomineeDeclaration').forEach(function(cb) {
      if (!cb.checked) unchecked = true;
    });
    if (unchecked) {
      alert('Please accept the declaration for all nominees.');
      valid = false;
    }
  }

  return valid;
}

window.onload = function() {
  if (window.parent && window.parent.updateParentBreadcrumb) {
    window.parent.updateParentBreadcrumb(
      window.buildBreadcrumbPath ? window.buildBreadcrumbPath('Lockers/lockerNominee.jsp') : 'Locker Nominee'
    );
  }
};
</script>

</body>
</html>
