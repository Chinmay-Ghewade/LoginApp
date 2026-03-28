<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    // NOTE: No DB calls on page load — all dropdowns load via AJAX after render.
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Complete Bank Customer Form</title>
  <link rel="stylesheet" href="css/addCustomer.css">
  <link rel="stylesheet" href="css/tabs-navigation.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    /* ── Loading spinner shown inside dropdowns while AJAX runs ── */
    select.dd-loading {
      color: #999;
      background-color: #f9f9f9;
      font-style: italic;
    }
    /* Small pulse dot next to dropdowns that are still loading */
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
    /* Hide spinners once loaded */
    .dd-spinner.done { display: none; }
  </style>
</head>
<body>

<form action="AddCustomerServlet" method="post" onsubmit="return validateForm()">

  <!----------------------------------------------------------------------- Main customer details -------------------------------------------------------------------->
  <fieldset>
    <legend>Customer Information</legend>
    <div class="form-grid">

      <!-- Row 1 -->
      <div>
        <label>Is Individual</label>
        <div style="flex-direction: row;" class="radio-group">
          <label><input type="radio" name="isIndividual" value="yes" checked required> Yes</label>
          <label><input type="radio" name="isIndividual" value="no"> No</label>
        </div>
      </div>

      <div>
        <label>Gender</label>
        <select name="gender" id="gender" required>
          <option value="">-- Select Gender --</option>
          <option>Male</option>
          <option>Female</option>
          <option>Other</option>
        </select>
      </div>

      <div>
        <label>Salutation Code <span class="dd-spinner" id="sp-salutation"></span></label>
        <select name="salutationCode" id="salutationCode" required class="dd-loading">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>First Name</label>
        <input type="text" name="firstName" id="firstName" oninput="this.value = this.value
          .replace(/[^A-Za-z]/g, '')
          .replace(/^./, c => c.toUpperCase())
          .replace(/(.{1})(.*)/, (m,p1,p2) => p1 + p2.toLowerCase());
        updateCustomerName();" required>
      </div>

      <!-- Row 2 -->
      <div>
        <label>Surname Name</label>
        <input type="text" name="surname" id="surname" oninput="this.value = this.value
          .replace(/[^A-Za-z]/g, '')
          .replace(/^./, c => c.toUpperCase())
          .replace(/(.{1})(.*)/, (m,p1,p2) => p1 + p2.toLowerCase());
        updateCustomerName();" required>
      </div>

      <div>
        <label>Middle Name</label>
        <input type="text" name="middleName" id="middleName" oninput="this.value = this.value
          .replace(/[^A-Za-z]/g, '')
          .replace(/^./, c => c.toUpperCase())
          .replace(/(.{1})(.*)/, (m,p1,p2) => p1 + p2.toLowerCase());
        updateCustomerName();" required>
      </div>

      <div>
        <label>Customer Name</label>
        <input type="text" name="customerName" id="customerName"
               oninput="this.value = this.value.replace(/[^A-Za-z]/g, ' ')" required>
      </div>

      <div>
        <label>Birth Date</label>
        <input type="date" name="birthDate" id="birthDate" required>
      </div>

      <!-- Row 3 -->
      <div>
        <label>Registration Date</label>
        <input type="date" name="registrationDate" id='registrationDate'required>
      </div>

      <div>
        <label>Is Minor</label>
        <div style="flex-direction: row;" class="radio-group">
          <label><input type="radio" name="isMinor" id="isMinor1" value="yes" required onclick="toggleMinorFields()"> Yes</label>
          <label><input type="radio" name="isMinor" id="isMinor2" value="no" checked onclick="toggleMinorFields()"> No</label>
        </div>
      </div>

      <div>
        <label>Guardian Name</label>
        <input type="text" name="guardianName" id="guardianName" required
          oninput="this.value = this.value
            .replace(/[^A-Za-z ]/g, '')
            .replace(/\s{2,}/g, ' ')
            .replace(/^\s+/g, '')
            .toLowerCase()
            .replace(/\b\w/g, c => c.toUpperCase());" disabled>
      </div>

      <div>
        <label>Relation with Guardian <span class="dd-spinner" id="sp-relation"></span></label>
        <select name="relationGuardian" id="relationGuardian" disabled required class="dd-loading">
          <option value="">Loading...</option>
        </select>
      </div>

      <!-- Row 4 -->
      <div>
        <label>Religion Code <span class="dd-spinner" id="sp-religion"></span></label>
        <select name="religionyCode" required class="dd-loading" id="dd-religion">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Caste Code <span class="dd-spinner" id="sp-caste"></span></label>
        <select name="casteCode" required class="dd-loading" id="dd-caste">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Category Code <span class="dd-spinner" id="sp-category"></span></label>
        <select name="categoryCode" required class="dd-loading" id="dd-category">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Sub Category Code</label>
        <input type="text" name="subCategoryCode" required>
      </div>

      <!-- Row 5 -->
      <div>
        <label>Constitution Code <span class="dd-spinner" id="sp-constitution"></span></label>
        <select name="constitutionCode" id="constitutionCode" required class="dd-loading">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Occupation Code <span class="dd-spinner" id="sp-occupation"></span></label>
        <select name="occupationCode" required class="dd-loading" id="dd-occupation">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Vehicle Owned</label>
        <select name="vehicleOwned" required>
          <option>NOT APPLICABLE</option>
          <option>CAR</option>
          <option>BIKE</option>
          <option>BOTH</option>
        </select>
      </div>

      <div>
        <label>Member Type</label>
        <select name="memberType" required>
          <option>A</option>
          <option>B</option>
          <option>O</option>
        </select>
      </div>

      <!-- Row 6 -->
      <div>
        <label>Email ID</label>
        <input type="email" name="email">
      </div>

      <div>
        <label>GSTIN No</label>
        <input type="text" name="gstinNo" id="gstinNo" required>
      </div>

      <div>
        <label>Member Number</label>
        <input type="text" name="memberNumber" maxlength="2"
               oninput="this.value = this.value.replace(/[^0-9]/g, '');" required>
      </div>

      <div>
        <label>CKYC No</label>
        <input type="text" name="ckyNo" required>
      </div>

      <!-- Row 7 -->
      <div>
        <label>Risk Category</label>
        <select name="riskCategory" required>
          <option>LOW</option>
          <option>MEDIUM</option>
          <option>HIGH</option>
        </select>
      </div>

    </div>
  </fieldset>


  <!---------------------------------------------------------------------- Personal Info --------------------------------------------------------------------------->
  <fieldset>
    <legend>Personal Information</legend>
    <div class="personal-grid">

      <div>
        <label for="motherName">Mother Name</label>
        <input type="text" id="motherName" name="motherName" required oninput="this.value = this.value
          .replace(/[^A-Za-z ]/g, '')
          .replace(/\s{2,}/g, ' ')
          .replace(/^\s+/g, '')
          .toLowerCase()
          .replace(/\b\w/g, c => c.toUpperCase());">
      </div>

      <div>
        <label for="fatherName">Father Name</label>
        <input type="text" id="fatherName" name="fatherName" required oninput="this.value = this.value
          .replace(/[^A-Za-z ]/g, '')
          .replace(/\s{2,}/g, ' ')
          .replace(/^\s+/g, '')
          .toLowerCase()
          .replace(/\b\w/g, c => c.toUpperCase());">
      </div>

      <div>
        <label>Marital Status</label>
        <div class="radio-group">
          <label><input type="radio" name="maritalStatus" id="maritalStatus" value="Married" checked required onclick="toggleMarriedFields()"> Married</label>
          <label><input type="radio" name="maritalStatus" id="maritalStatus1" value="Single" onclick="toggleMarriedFields()"> Single</label>
          <label><input type="radio" name="maritalStatus" id="maritalStatus2" value="Other" onclick="toggleMarriedFields()"> Other</label>
        </div>
      </div>

      <div>
        <label for="children">No. of Children</label>
        <input type="number" id="children" name="children" value="" min="0"
               oninput="if(this.value.length > 2) this.value = this.value.slice(0,2);" disabled required>
      </div>

      <div>
        <label for="dependents">No. of Dependents</label>
        <input type="number" id="dependents" name="dependents" value="" min="0"
               oninput="if(this.value.length > 2) this.value = this.value.slice(0,2);" disabled required>
      </div>

    </div>
  </fieldset>


  <!-------------------------------------------------------------- Permanent/Address Info -------------------------------------------------------------------------->
  <fieldset>
    <legend>Permanent / Address Information</legend>
    <div class="address-grid">

      <div>
        <label>Nationality</label>
        <input type="text" name="nationality" value="INDIAN" readonly>
      </div>

      <div>
        <label>Residence Type <span class="dd-spinner" id="sp-residenceType"></span></label>
        <select name="residenceType" required class="dd-loading" id="dd-residenceType">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Residence Status</label>
        <select name="residenceStatus" required>
          <option>NOT APPLICABLE</option>
          <option>BANGLOW</option>
          <option>ROW HOUSE</option>
          <option>FLAT</option>
          <option>OTHER</option>
        </select>
      </div>

      <div>
        <label>Address 1</label>
        <input type="text" name="address1" required>
      </div>

      <div>
        <label>Address 2</label>
        <input type="text" name="address2" required>
      </div>

      <div>
        <label>Address 3</label>
        <input type="text" name="address3" required>
      </div>

      <div>
        <label>Country <span class="dd-spinner" id="sp-country"></span></label>
        <select name="country" required class="dd-loading" id="dd-country">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>State <span class="dd-spinner" id="sp-state"></span></label>
        <select name="state" required class="dd-loading" id="dd-state">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>City <span class="dd-spinner" id="sp-city"></span></label>
        <select name="city" required class="dd-loading" id="dd-city">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Zip</label>
        <input type="text" id="zip" name="zip" maxlength="6"
               oninput="validateZipLive(this)" required>
        <span id="zipError" style="color:red;"></span>
      </div>
      <script>
      const zipField = document.querySelector('input[name="zip"]');
      if (zipField) {
        zipField.maxLength = 6;
        zipField.addEventListener('input', function () {
          this.value = this.value.replace(/[^0-9]/g, '').slice(0, 6);
          if (this.value.length > 0) {
            const fd = this.value.charAt(0);
            if (fd !== '4' && fd !== '5') {
              showError(this, 'ZIP must start with 4 (MH/Goa) or 5 (Karnataka)');
            } else { clearError(this); }
          }
        });
        zipField.addEventListener('blur', function () {
          if (this.value === '') { clearError(this); return; }
          if (!/^(4\d{5}|5\d{5})$/.test(this.value)) {
            showError(this, 'Invalid ZIP. Allowed states: Maharashtra, Goa, Karnataka');
          } else { clearError(this); }
        });
      }
      </script>

      <div>
        <label>Mobile No</label>
        <input type="text" name="mobileNo">
      </div>

      <div>
        <label>Residence Phone</label>
        <input type="text" name="residencePhone" value="">
      </div>

      <div>
        <label>Office Phone</label>
        <input type="text" name="officePhone" value="">
      </div>

    </div>
  </fieldset>


  <!--------------------------------------------------------------------- KYC and Document Checklist -------------------------------------------------------------->
  <fieldset class="kyc-fieldset">
    <legend>KYC Document Details</legend>

    <div class="kyc-row">
      <!-- ID Proof -->
      <div class="kyc-section">
        <h4>Savings Account (ID Proof)</h4>
        <table>
          <tr><th>Select</th><th>Document</th><th>Expiry Date</th><th>Document Number</th></tr>
          <tr>
            <td><input type="checkbox" name="passport_check"></td>
            <td>Passport</td>
            <td><input id="date" type="date" name="passport_expiry"></td>
            <td><input type="text" name="passportNumber" id="passportNumber"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="pan_check"></td>
            <td>PAN Card</td>
            <td><input type="date" name="pan_expiry" disabled></td>
            <td><input type="text" name="pan" id="pan" style="text-transform:uppercase;"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="voterid_check"></td>
            <td>Election Card</td>
            <td><input type="date" name="voterid_expiry" disabled></td>
            <td><input type="text" name="voterid" id="voterid" style="text-transform:uppercase;"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="dl_check"></td>
            <td>Driving License</td>
            <td><input id="date" type="date" name="dl_expiry"></td>
            <td><input type="text" name="dl" id="dl" style="text-transform:uppercase;"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="aadhar_check"></td>
            <td>Aadhar Card</td>
            <td><input type="date" name="aadhar_expiry" disabled></td>
            <td><input type="text" name="aadhar"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="nrega_check"></td>
            <td>NREGA Job Card</td>
            <td><input type="date" name="nrega_expiry" disabled></td>
            <td><input type="text" name="nrega" id="nrega" style="text-transform:uppercase;"></td>
          </tr>
        </table>
      </div>

      <div class="kyc-divider"></div>

      <!-- Address Proof -->
      <div class="kyc-section">
        <h4>Savings Account (Address Proof)</h4>
        <table>
          <tr><th>Select</th><th>Document</th><th>Expiry Date</th><th>Document Number</th></tr>
          <tr>
            <td><input type="checkbox" name="telephone_check"></td>
            <td>Telephone Bill</td>
            <td><input  id="date" type="date" name="telephone_expiry"></td>
            <td><input type="text" name="telephone"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="bank_check"></td>
            <td>Bank Statement</td>
            <td><input id="date" type="date" name="bank_expiry"></td>
            <td><input type="text" name="bank_statement"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="govt_check"></td>
            <td>Govt. Documents</td>
            <td><input id="date" type="date" name="govt_expiry"></td>
            <td><input type="text" name="govt_doc"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="electricity_check"></td>
            <td>Electricity Bill</td>
            <td><input id="date" type="date" name="electricity_expiry"></td>
            <td><input type="text" name="electricity"></td>
          </tr>
          <tr>
            <td><input type="checkbox" name="ration_check"></td>
            <td>Ration Card</td>
            <td><input type="date" name="ration_expiry" disabled></td>
            <td><input type="text" name="ration" id="ration" style="text-transform:uppercase;"></td>
          </tr>
        </table>
      </div>
    </div>

    <hr>

    <div class="kyc-row">
      <!-- Proprietary Concern -->
      <div class="kyc-section">
        <h4>Accounts of Proprietary Concern</h4>
        <table>
          <tr><th>Select</th><th>Document</th><th>Expiry Date</th></tr>
          <tr><td><input type="checkbox" name="rent_check"></td><td>Registered Rent Agreement Copy</td><td><input id="date" type="date" name="rent_expiry"></td></tr>
          <tr><td><input type="checkbox" name="cert_check"></td><td>Certificate / License</td><td><input id="date" type="date" name="cert_expiry"></td></tr>
          <tr><td><input type="checkbox" name="tax_check"></td><td>Sales and Income Tax Returns</td><td><input id="date" type="date" name="tax_expiry"></td></tr>
          <tr><td><input type="checkbox" name="cst_check"></td><td>CST / VAT Certificate</td><td><input id="date" type="date" name="cst_expiry"></td></tr>
          <tr><td><input type="checkbox" name="reg_check"></td><td>License issued by Registering Authority</td><td><input id="date" type="date" name="reg_expiry"></td></tr>
        </table>
      </div>

      <div class="kyc-divider"></div>

      <!-- Business Concern -->
      <div class="kyc-section">
        <h4>Business Concern</h4>
        <table>
          <tr><th>Select</th><th>Document</th><th>Expiry Date</th></tr>
          <tr><td><input type="checkbox" name="inc_check"></td><td>Certificate of Incorporation</td><td><input id="date" type="date" name="inc_expiry"></td></tr>
          <tr><td><input type="checkbox" name="board_check"></td><td>Resolution of the Board of Directors</td><td><input id="date" type="date" name="board_expiry"></td></tr>
          <tr><td><input type="checkbox" name="poa_check"></td><td>Power of Attorney granted to its Managers</td><td><input id="date" type="date" name="poa_expiry"></td></tr>
        </table>
      </div>
    </div>
  </fieldset>


  <!-- Photo & Signature Upload -->
  <fieldset>
    <legend>Photo & Signature Upload</legend>
    <div class="upload-container">
      <div class="upload-card">
        <h3>Upload Photo</h3>
        <div class="upload-icon-container">
          <img src="images/photo-icon.png" alt="Photo" class="upload-icon" id="photoPreviewIcon">
        </div>
        <p class="upload-text">Upload a photo (Required)</p>
        <p class="upload-subtext">Drag and drop files here</p>
        <input type="file" id="photoInput" name="photo" accept="image/*" style="display: none;">
        <input type="hidden" id="photoData" name="photoData">
        <div class="upload-buttons">
          <button type="button" class="upload-btn" onclick="openPhotoCamera()">
            <img src="images/camera-icon.png" alt="Camera" width="20"> Camera
          </button>
          <button type="button" class="upload-btn" onclick="document.getElementById('photoInput').click()">
            <img src="images/browse-icon.png" alt="Browse" width="20"> Browse
          </button>
        </div>
      </div>

      <div class="upload-card">
        <h3>Upload Signature</h3>
        <div class="upload-icon-container">
          <img src="images/signature-icon.png" alt="Signature" class="upload-icon" id="signaturePreviewIcon">
        </div>
        <p class="upload-text">Upload a signature (Required)</p>
        <p class="upload-subtext">Drag and drop files here</p>
        <input type="file" id="signatureInput" name="signature" accept="image/*" style="display: none;">
        <input type="hidden" id="signatureData" name="signatureData">
        <div class="upload-buttons">
          <button type="button" class="upload-btn" onclick="openSignatureCamera()">
            <img src="images/camera-icon.png" alt="Camera" width="20"> Camera
          </button>
          <button type="button" class="upload-btn" onclick="document.getElementById('signatureInput').click()">
            <img src="images/browse-icon.png" alt="Browse" width="20"> Browse
          </button>
        </div>
      </div>
    </div>
  </fieldset>

  <!-- Submit & Reset Buttons -->
  <div class="form-buttons">
    <button type="submit">Save</button>
    <button type="reset" onclick="resetFormWithUploads()">Reset</button>
  </div>

</form>

<!-- Camera Modal for Photo -->
<div id="photoCameraModal" class="camera-modal">
  <div class="camera-modal-content">
    <span class="camera-close" onclick="closePhotoCamera()">&times;</span>
    <h3>Take Photo</h3>
    <video id="photoVideo" autoplay></video>
    <canvas id="photoCanvas" style="display: none;"></canvas>
    <div class="camera-controls">
      <button type="button" class="camera-btn" onclick="capturePhoto()">Capture</button>
      <button type="button" class="camera-btn camera-btn-cancel" onclick="closePhotoCamera()">Cancel</button>
    </div>
  </div>
</div>

<!-- Camera Modal for Signature -->
<div id="signatureCameraModal" class="camera-modal">
  <div class="camera-modal-content">
    <span class="camera-close" onclick="closeSignatureCamera()">&times;</span>
    <h3>Take Signature Photo</h3>
    <video id="signatureVideo" autoplay></video>
    <canvas id="signatureCanvas" style="display: none;"></canvas>
    <div class="camera-controls">
      <button type="button" class="camera-btn" onclick="captureSignature()">Capture</button>
      <button type="button" class="camera-btn camera-btn-cancel" onclick="closeSignatureCamera()">Cancel</button>
    </div>
  </div>
</div>

<script src="js/addCustomer.js"></script>
<script src="js/tabs-navigation.js"></script>

<!-- ═══════════════════════════════════════════════════
     AJAX DROPDOWN LOADER
     Fires immediately after page renders.
     One fetch → DropdownDataServlet → all 11 dropdowns.
     ═══════════════════════════════════════════════════ -->
<script>
(function loadAllDropdowns() {

    /* ── Map: servletKey → { selectId, spinnerId, hasCodeLabel } ── */
    const DD_MAP = {
        salutation:    { id: 'salutationCode',   sp: 'sp-salutation',   codeLabel: false },
        relation:      { id: 'relationGuardian', sp: 'sp-relation',     codeLabel: false },
        religion:      { id: 'dd-religion',      sp: 'sp-religion',     codeLabel: false },
        caste:         { id: 'dd-caste',         sp: 'sp-caste',        codeLabel: false },
        category:      { id: 'dd-category',      sp: 'sp-category',     codeLabel: false },
        constitution:  { id: 'constitutionCode', sp: 'sp-constitution', codeLabel: false },
        occupation:    { id: 'dd-occupation',    sp: 'sp-occupation',   codeLabel: false },
        residenceType: { id: 'dd-residenceType', sp: 'sp-residenceType',codeLabel: false },
        country:       { id: 'dd-country',       sp: 'sp-country',      codeLabel: true  },
        state:         { id: 'dd-state',         sp: 'sp-state',        codeLabel: true  },
        city:          { id: 'dd-city',          sp: 'sp-city',         codeLabel: false }
    };

    /* ── Fill one <select> from an array of {v, l} objects ── */
    function fillSelect(selectEl, items, codeLabel) {
        // Remove loading option
        selectEl.innerHTML = '';

        // Default blank option
        const blank = document.createElement('option');
        blank.value = '';
        blank.textContent = '-- Select --';
        selectEl.appendChild(blank);

        items.forEach(function(item) {
            const opt = document.createElement('option');
            opt.value = item.v;
            // If codeLabel (country/state): show "CODE — Name", else just the value
            opt.textContent = codeLabel ? item.v + ' — ' + item.l : item.l;
            selectEl.appendChild(opt);
        });

        // Remove loading style
        selectEl.classList.remove('dd-loading');
        selectEl.style.color = '';
        selectEl.style.fontStyle = '';
    }

    /* ── Fetch all dropdown data in one call ── */
    fetch('<%= request.getContextPath() %>/loaders/AddCustomerDataLoader')
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function(data) {
            if (data._error) {
                console.warn('Dropdown load warning:', data._error);
            }

            Object.keys(DD_MAP).forEach(function(key) {
                var cfg = DD_MAP[key];
                var selectEl = document.getElementById(cfg.id);
                var spinnerEl = document.getElementById(cfg.sp);

                if (!selectEl) return;

                var items = data[key];
                if (Array.isArray(items)) {
                    fillSelect(selectEl, items, cfg.codeLabel);
                } else {
                    // Fallback if this key missing from response
                    selectEl.innerHTML = '<option value="">-- Error loading --</option>';
                    selectEl.classList.remove('dd-loading');
                }

                // Hide spinner
                if (spinnerEl) spinnerEl.classList.add('done');
            });

            console.log('✅ All dropdowns loaded via AJAX');

            // Re-run the isIndividual toggle AFTER dropdowns are populated
            // so Constitution / Salutation lock/unlock logic applies correctly
            var checkedRadio = document.querySelector('input[name="isIndividual"]:checked');
            if (checkedRadio) {
                checkedRadio.dispatchEvent(new Event('change'));
            }
        })
        .catch(function(err) {
            console.error('❌ Dropdown AJAX error:', err);
            // On error, replace all "Loading..." with error message
            Object.keys(DD_MAP).forEach(function(key) {
                var cfg = DD_MAP[key];
                var selectEl = document.getElementById(cfg.id);
                if (selectEl) {
                    selectEl.innerHTML = '<option value="">-- Error: reload page --</option>';
                    selectEl.classList.remove('dd-loading');
                    selectEl.style.borderColor = '#f44336';
                }
                var spinnerEl = document.getElementById(cfg.sp);
                if (spinnerEl) { spinnerEl.style.background = '#f44336'; spinnerEl.classList.add('done'); }
            });
        });

})();
</script>

<script type="text/javascript">
document.addEventListener('DOMContentLoaded', function () {

    function toggleFieldsByIndividual(isIndividual) {
        var individualFields = ['birthDate','gender','salutationCode','motherName','fatherName',
            'maritalStatus','isMinor1','isMinor2','maritalStatus1','maritalStatus2','children','dependents'];
        var nonIndividualFields = ['gstinNo','constitutionCode','registrationDate'];

        if (isIndividual) {
            individualFields.forEach(function(id) {
                var el = document.getElementById(id);
                if (el) el.disabled = false;
            });
            nonIndividualFields.forEach(function(id) {
                var el = document.getElementById(id);
                if (el) el.disabled = true;
            });
        } else {
            individualFields.forEach(function(id) {
                var el = document.getElementById(id);
                if (el) el.disabled = true;
            });
            nonIndividualFields.forEach(function(id) {
                var el = document.getElementById(id);
                if (el) el.disabled = false;
            });
        }
    }

    var individualRadios = document.querySelectorAll('input[name="isIndividual"]');
    individualRadios.forEach(function(radio) {
        radio.addEventListener('change', function() {
            var isIndividual = this.value === 'yes';
            toggleFieldsByIndividual(isIndividual);
            lockUnlockSpecialFields(isIndividual);
        });
    });

    function lockUnlockSpecialFields(isIndividual) {
        var genderField       = document.getElementById('gender');
        var salutationField   = document.getElementById('salutationCode');
        var constitutionField = document.getElementById('constitutionCode');

        if (isIndividual) {
            if (genderField) {
                genderField.disabled = false;
                genderField.style.pointerEvents = '';
                genderField.style.backgroundColor = '';
                genderField.style.cursor = '';
            }
            if (salutationField) {
                salutationField.disabled = false;
                salutationField.style.pointerEvents = '';
                salutationField.style.backgroundColor = '';
                salutationField.style.cursor = '';
            }
            if (constitutionField) {
                for (var i = 0; i < constitutionField.options.length; i++) {
                    if (constitutionField.options[i].value.toUpperCase().includes('OTHER') ||
                        constitutionField.options[i].text.toUpperCase().includes('OTHER')) {
                        constitutionField.selectedIndex = i;
                        break;
                    }
                }
                constitutionField.disabled = false;
                constitutionField.style.pointerEvents = 'none';
                constitutionField.style.backgroundColor = '#f5f5f5';
                constitutionField.style.cursor = 'not-allowed';
            }
        } else {
            if (genderField) {
                genderField.value = 'Other';
                genderField.disabled = false;
                genderField.style.pointerEvents = 'none';
                genderField.style.backgroundColor = '#f5f5f5';
                genderField.style.cursor = 'not-allowed';
            }
            if (salutationField) {
                for (var i = 0; i < salutationField.options.length; i++) {
                    if (salutationField.options[i].value.toUpperCase().includes('OTHER') ||
                        salutationField.options[i].text.toUpperCase().includes('OTHER')) {
                        salutationField.selectedIndex = i;
                        break;
                    }
                }
                salutationField.disabled = false;
                salutationField.style.pointerEvents = 'none';
                salutationField.style.backgroundColor = '#f5f5f5';
                salutationField.style.cursor = 'not-allowed';
            }
            if (constitutionField) {
                constitutionField.disabled = false;
                constitutionField.style.pointerEvents = '';
                constitutionField.style.backgroundColor = '';
                constitutionField.style.cursor = '';
            }
        }
    }

    var checked = Array.from(individualRadios).find(function(r) { return r.checked; });
    var initialIsIndividual = checked ? checked.value === 'yes' : true;
    toggleFieldsByIndividual(initialIsIndividual);
    // Note: lockUnlockSpecialFields is called again after AJAX load completes
});

function resetFormWithUploads() {
    setTimeout(function() {
        var photoPreview = document.getElementById('photoPreviewIcon');
        if (photoPreview) {
            photoPreview.src = 'images/photo-icon.png';
            photoPreview.classList.remove('preview-image');
        }
        document.getElementById('photoData').value = '';
        document.getElementById('photoInput').value = '';
        var photoCard = photoPreview ? photoPreview.closest('.upload-card') : null;
        if (photoCard) { var pb = photoCard.querySelector('.upload-success-badge'); if (pb) pb.remove(); }

        var signaturePreview = document.getElementById('signaturePreviewIcon');
        if (signaturePreview) {
            signaturePreview.src = 'images/signature-icon.png';
            signaturePreview.classList.remove('preview-image');
        }
        document.getElementById('signatureData').value = '';
        document.getElementById('signatureInput').value = '';
        var sigCard = signaturePreview ? signaturePreview.closest('.upload-card') : null;
        if (sigCard) { var sb = sigCard.querySelector('.upload-success-badge'); if (sb) sb.remove(); }

        document.querySelectorAll('.error-message').forEach(function(err) { err.remove(); });
        document.querySelectorAll('input, select, textarea').forEach(function(f) {
            f.style.borderColor = '';
            f.style.backgroundColor = '';
        });
        if (typeof showInfoToast === 'function') {
            showInfoToast('🔄 Form has been reset including photo and signature');
        }
    }, 10);
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('addCustomer.jsp')
        );
    }
};
</script>

</body>
</html>
