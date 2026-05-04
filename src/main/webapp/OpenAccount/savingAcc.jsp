<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
    // Fetch working date for this branch
    String workingDateStr = "";
    try (Connection connWorkDate = DBConnection.getConnection()) {
        String bankCode = "0100";
        CallableStatement cstmtWorkDate = connWorkDate.prepareCall("{? = call SYSTEM.FN_GET_WORKINGDATE(?, ?)}");
        cstmtWorkDate.registerOutParameter(1, Types.DATE);
        cstmtWorkDate.setString(2, bankCode);
        cstmtWorkDate.setString(3, branchCode);
        cstmtWorkDate.execute();
        
        Date workingDate = cstmtWorkDate.getDate(1);
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        workingDateStr = sdf.format(workingDate);
        
        cstmtWorkDate.close();
    } catch (Exception e) {
        e.printStackTrace();
        workingDateStr = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    }
    
    // ✅ GET PRODUCT CODE FROM REQUEST
    String productCode = request.getParameter("productCode");
    if (productCode == null) {
        productCode = "";
    }
    
    // ✅ FETCH PRODUCT FLAGS FROM DATABASE
    boolean showNominee = false;
    boolean showJointHolder = false;
    
    if (!productCode.isEmpty()) {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "SELECT IS_NOMINEE_REQUIRED, IS_JOINT_HOLDER_REQUIRED " +
                        "FROM HEADOFFICE.PRODUCT " +
                        "WHERE PRODUCT_CODE = ?";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, productCode);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                String nomineeFlag = rs.getString("IS_NOMINEE_REQUIRED");
                String jointFlag = rs.getString("IS_JOINT_HOLDER_REQUIRED");
                
                showNominee = "Y".equalsIgnoreCase(nomineeFlag);
                showJointHolder = "Y".equalsIgnoreCase(jointFlag);
                
                System.out.println("📌 Product Code: " + productCode);
                System.out.println("   Nominee Required: " + nomineeFlag + " (Show: " + showNominee + ")");
                System.out.println("   Joint Holder Required: " + jointFlag + " (Show: " + showJointHolder + ")");
            }
            
            rs.close();
            ps.close();
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("❌ Error fetching product flags: " + e.getMessage());
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Saving Account Application</title>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <link rel="stylesheet" href="css/savingAcc.css">
  <link rel="stylesheet" href="css/application-tabs.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
</head>
<body>

<form action="SaveApplicationServlet" method="post" onsubmit="return validateForm()">
  <input type="hidden" id="hiddenProductCode" name="productCode" value="<%= productCode %>">

  <!-- ========================================== -->
  <!-- APPLICATION FIELDSET (ALWAYS SHOWN) -->
  <!-- ========================================== -->
  <fieldset>
    <legend>Application</legend>
    <div class="form-grid">
      
      <div>
        <label>Product Code</label>
        <input type="text" value="<%= productCode %>" readonly style="background-color: #f0f0f0;">
      </div>
      
      <div>
        <label>Customer ID</label>
        <div class="input-icon-box">
          <input type="text" id="customerId" name="customerId" onclick="openCustomerLookup()" readonly required>
          <button type="button" class="inside-icon-btn" onclick="openCustomerLookup()" title="Search Customer">🔍</button>
        </div>
      </div>

      <div>
        <label>Customer Name</label>
        <input type="text" id="customerName" name="customerName" readonly>
      </div>
     
      <div>
        <label>Category Code</label>
        <input type="text" id="categoryCode" name="categoryCode" readonly>
      </div>

      <div>
        <label>Introducer A/c Code</label>
        <input type="text" name="introducerAccCode" maxlength="14" pattern="[0-9]{14}" inputmode="numeric"
               title="Introducer Account Code must be exactly 14 digits">
      </div>

      <div>
        <label>Introducer A/c Name</label>
        <input type="text" name="introducerAccName" required oninput="this.value = this.value
               .replace(/[^A-Za-z ]/g, '')
               .replace(/\s{2,}/g, ' ')
               .replace(/^\s+/g, '')
               .toLowerCase()
               .replace(/\b\w/g, c => c.toUpperCase());">
      </div>

      <div>
        <label>Date Of Application</label>
        <input type="date" name="dateOfApplication" value="<%= workingDateStr %>" readonly 
               style="background-color: #f0f0f0; cursor: not-allowed;" required>
      </div>

      <div>
        <label>Account Operation Capacity</label>
        <select name="accountOperationCapacity" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psAccOpCap = null;
            ResultSet rsAccOpCap = null;
            try (Connection connAccOp = DBConnection.getConnection()) {
              String sql = "SELECT ACCOUNTOPERATIONCAPACITY_ID, DESCRIPTION FROM GLOBALCONFIG.ACCOUNTOPERATIONCAPACITY ORDER BY ACCOUNTOPERATIONCAPACITY_ID";
              psAccOpCap = connAccOp.prepareStatement(sql);
              rsAccOpCap = psAccOpCap.executeQuery();
              while (rsAccOpCap.next()) {
                String capacityId = rsAccOpCap.getString("ACCOUNTOPERATIONCAPACITY_ID");
                String description = rsAccOpCap.getString("DESCRIPTION");
          %>
                <option value="<%= capacityId %>"><%= description %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading capacities</option>");
            } finally {
              if (rsAccOpCap != null) rsAccOpCap.close();
              if (psAccOpCap != null) psAccOpCap.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>Min Balance</label>
        <select name="minBalanceID" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psMinBal = null;
            ResultSet rsMinBal = null;
            try (Connection connMinBal = DBConnection.getConnection()) {
              String sql = "SELECT MINBALANCE_ID, MINBALANCE FROM HEADOFFICE.ACCOUNTMINBALANCE ORDER BY MINBALANCE_ID";
              psMinBal = connMinBal.prepareStatement(sql);
              rsMinBal = psMinBal.executeQuery();

              while (rsMinBal.next()) {
                String id = rsMinBal.getString("MINBALANCE_ID");
                String value = rsMinBal.getString("MINBALANCE");
          %>
                <option value="<%= id %>"><%= value %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Min Balance</option>");
            } finally {
              if (rsMinBal != null) rsMinBal.close();
              if (psMinBal != null) psMinBal.close();
            }
          %>
        </select>
      </div>
      
      <div>
        <label>Risk Category</label>
        <input type="text" id="riskCategory" name="riskCategory" readonly>
      </div>
    </div>
  </fieldset>

  <!-- ========================================== -->
  <!-- NOMINEE FIELDSET (CONDITIONAL) -->
  <!-- ========================================== -->
  <% if (showNominee) { %>
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
      <button type="button" class="nominee-remove" onclick="removeNominee(this)">✖</button>

      <div class="nominee-title" 
           style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
        Nominee <span class="nominee-serial">1</span>
      </div>
      
      <div class="inline-fields">
        <div>
          <label>Has Customer ID ?</label>
          <div style="flex-direction: row;" class="radio-group">
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="yes" onchange="toggleNomineeCustomerID(this)"> Yes</label>
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="no" onchange="toggleNomineeCustomerID(this)" checked> No</label>
          </div>
        </div>

        <div class="nomineeCustomerIDContainer" style="display:none; margin-top:10px;">
          <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="nomineeCustomerIDInput" name="nomineeCustomerID[]" onclick="openNomineeCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openNomineeCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <br>

      <div class="personal-grid">
        <div>
          <label>Salutation Code</label>
          <select name="nomineeSalutation[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psnomineeSalutation = null;
              ResultSet rsnomineeSalutation = null;
              try (Connection conn1 = DBConnection.getConnection()) {
                String sql1 = "SELECT SALUTATION_CODE FROM GLOBALCONFIG.SALUTATION ORDER BY SALUTATION_CODE";
                psnomineeSalutation = conn1.prepareStatement(sql1);
                rsnomineeSalutation = psnomineeSalutation.executeQuery();
                while (rsnomineeSalutation.next()) {
                  String nomineeSalutation = rsnomineeSalutation.getString("SALUTATION_CODE");
            %>
                  <option value="<%= nomineeSalutation %>"><%= nomineeSalutation %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading Salutation Code</option>");
                e.printStackTrace();
              } finally {
                if (rsnomineeSalutation != null) rsnomineeSalutation.close();
                if (psnomineeSalutation != null) psnomineeSalutation.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>Nominee Name</label>
          <input type="text" name="nomineeName[]" required oninput="this.value = this.value
                 .replace(/[^A-Za-z ]/g, '')
                 .replace(/\s{2,}/g, ' ')
                 .replace(/^\s+/g, '')
                 .toLowerCase()
                 .replace(/\b\w/g, c => c.toUpperCase());">
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
          <label>Country</label>
          <select name="nomineeCountry[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psCountryNominee = null;
              ResultSet rsCountryNominee = null;
              try (Connection connCountryN = DBConnection.getConnection()) {
                String sql = "SELECT COUNTRY_CODE, NAME FROM GLOBALCONFIG.COUNTRY ORDER BY NAME";
                psCountryNominee = connCountryN.prepareStatement(sql);
                rsCountryNominee = psCountryNominee.executeQuery();
                while (rsCountryNominee.next()) {
                  String countryCode = rsCountryNominee.getString("COUNTRY_CODE");
                  String countryName = rsCountryNominee.getString("NAME");
            %>
                  <option value="<%= countryCode %>"><%= countryName %></option>
            <% 
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading countries</option>");
              } finally {
                if (rsCountryNominee != null) rsCountryNominee.close();
                if (psCountryNominee != null) psCountryNominee.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>State</label>
          <select name="nomineeState[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psStateNominee = null;
              ResultSet rsStateNominee = null;
              try (Connection connStateN = DBConnection.getConnection()) {
                String sql = "SELECT STATE_CODE, NAME FROM GLOBALCONFIG.STATE ORDER BY NAME";
                psStateNominee = connStateN.prepareStatement(sql);
                rsStateNominee = psStateNominee.executeQuery();
                while (rsStateNominee.next()) {
                  String stateCode = rsStateNominee.getString("STATE_CODE");
                  String stateName = rsStateNominee.getString("NAME");
            %>
                  <option value="<%= stateCode %>"><%= stateName %></option>
            <% 
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading states</option>");
                e.printStackTrace();
              } finally {
                if (rsStateNominee != null) rsStateNominee.close();
                if (psStateNominee != null) psStateNominee.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>City</label>
          <select name="nomineeCity[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psCityNominee = null;
              ResultSet rsCityNominee = null;
              try (Connection connCityN = DBConnection.getConnection()) {
                String sql = "SELECT CITY_CODE, NAME FROM GLOBALCONFIG.CITY ORDER BY UPPER(NAME)";
                psCityNominee = connCityN.prepareStatement(sql);
                rsCityNominee = psCityNominee.executeQuery();
                while (rsCityNominee.next()) {
                  String cityCode = rsCityNominee.getString("CITY_CODE");
                  String cityName = rsCityNominee.getString("NAME");
            %>
                  <option value="<%= cityCode %>"><%= cityName %></option>
            <% 
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading cities</option>");
                e.printStackTrace();
              } finally {
                if (rsCityNominee != null) rsCityNominee.close();
                if (psCityNominee != null) psCityNominee.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>Zip</label>
          <input type="text" name="nomineeZip[]" class="zip-input" maxlength="6" required>
          <small class="zipError"></small>
        </div>

        <div>
          <label>Relation with Guardian</label>
          <select name="nomineeRelation[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psRelation = null;
              ResultSet rsRelation = null;
              try (Connection conn9 = DBConnection.getConnection()) {
                String sql = "SELECT RELATION_ID, DESCRIPTION FROM GLOBALCONFIG.RELATION ORDER BY RELATION_ID";
                psRelation = conn9.prepareStatement(sql);
                rsRelation = psRelation.executeQuery();
                while (rsRelation.next()) {
                  String relationId = rsRelation.getString("RELATION_ID");
                  String description = rsRelation.getString("DESCRIPTION");
            %>
                  <option value="<%= relationId %>"><%= description %></option>
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
      </div>
    </div>
  </fieldset>
  <% } else { %>
  <!-- Hidden input to indicate no nominee required -->
  <input type="hidden" name="nomineeNotRequired" value="true">
  <% } %>

  <!-- ========================================== -->
  <!-- JOINT HOLDER FIELDSET (CONDITIONAL) -->
  <!-- ========================================== -->
  <% if (showJointHolder) { %>
  <fieldset id="jointFieldset">
    <legend>
      Joint Holder
      <button type="button" onclick="addJointHolder()"
        style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
        ➕
      </button>
    </legend>

    <div class="nominee-card joint-block">
      <button type="button" class="nominee-remove" onclick="removeJointHolder(this)">✖</button>

      <div class="nominee-title"
           style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
        Joint Holder <span class="joint-serial">1</span>
      </div>
      
      <div class="inline-fields">
        <div>
          <label>Has Customer ID ?</label>
          <div style="flex-direction: row;" class="radio-group">
            <label><input type="radio" name="jointHasCustomerID_1" class="jointHasCustomerRadio" value="yes" onchange="toggleJointCustomerID(this)"> Yes</label>
            <label><input type="radio" name="jointHasCustomerID_1" class="jointHasCustomerRadio" value="no" onchange="toggleJointCustomerID(this)" checked> No</label>
          </div>
        </div>

        <div class="jointCustomerIDContainer" style="display:none; margin-top:10px;">
          <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="jointCustomerIDInput" name="jointCustomerID[]" onclick="openJointCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openJointCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <br>

      <div class="address-grid">
        <div>
          <label>Salutation Code</label>
          <select name="jointSalutation[]" required>
            <option value="">-- Select --</option>
            <%
              PreparedStatement psSalutation2 = null;
              ResultSet rsSalutation2 = null;
              try (Connection conn2 = DBConnection.getConnection()) {
                String sql2 = "SELECT SALUTATION_CODE FROM GLOBALCONFIG.SALUTATION ORDER BY SALUTATION_CODE";
                psSalutation2 = conn2.prepareStatement(sql2);
                rsSalutation2 = psSalutation2.executeQuery();
                while (rsSalutation2.next()) {
                  String salutationCode2 = rsSalutation2.getString("SALUTATION_CODE");
            %>
                  <option value="<%= salutationCode2 %>"><%= salutationCode2 %></option>
            <%
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading Salutation Code</option>");
                e.printStackTrace();
              } finally {
                if (rsSalutation2 != null) rsSalutation2.close();
                if (psSalutation2 != null) psSalutation2.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>Joint Holder Name</label>
          <input type="text" name="jointName[]" required oninput="this.value = this.value
                 .replace(/[^A-Za-z ]/g, '')
                 .replace(/\s{2,}/g, ' ')
                 .replace(/^\s+/g, '')
                 .toLowerCase()
                 .replace(/\b\w/g, c => c.toUpperCase());">
        </div>

        <div>
          <label>Address 1</label>
          <input type="text" name="jointAddress1[]" required>
        </div>

        <div>
          <label>Address 2</label>
          <input type="text" name="jointAddress2[]">
        </div>

        <div>
          <label>Address 3</label>
          <input type="text" name="jointAddress3[]">
        </div>

        <div>
          <label>Country</label>
          <select name="jointCountry[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psCountryJoint = null;
              ResultSet rsCountryJoint = null;
              try (Connection connCountryJ = DBConnection.getConnection()) {
                String sql = "SELECT COUNTRY_CODE, NAME FROM GLOBALCONFIG.COUNTRY ORDER BY NAME";
                psCountryJoint = connCountryJ.prepareStatement(sql);
                rsCountryJoint = psCountryJoint.executeQuery();
                while (rsCountryJoint.next()) {
                  String countryCode = rsCountryJoint.getString("COUNTRY_CODE");
                  String countryName = rsCountryJoint.getString("NAME");
            %>
                  <option value="<%= countryCode %>"><%= countryName %></option>
            <% 
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading countries</option>");
              } finally {
                if (rsCountryJoint != null) rsCountryJoint.close();
                if (psCountryJoint != null) psCountryJoint.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>State</label>
          <select name="jointState[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psStateJoint = null;
              ResultSet rsStateJoint = null;
              try (Connection connStateJ = DBConnection.getConnection()) {
                String sql = "SELECT STATE_CODE, NAME FROM GLOBALCONFIG.STATE ORDER BY NAME";
                psStateJoint = connStateJ.prepareStatement(sql);
                rsStateJoint = psStateJoint.executeQuery();
                while (rsStateJoint.next()) {
                  String stateCode = rsStateJoint.getString("STATE_CODE");
                  String stateName = rsStateJoint.getString("NAME");
            %>
                  <option value="<%= stateCode %>"><%= stateName %></option>
            <% 
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading states</option>");
                e.printStackTrace();
              } finally {
                if (rsStateJoint != null) rsStateJoint.close();
                if (psStateJoint != null) psStateJoint.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>City</label>
          <select name="jointCity[]" required>
            <option value="">-- Select --</option>
            <% 
              PreparedStatement psCityJoint = null;
              ResultSet rsCityJoint = null;
              try (Connection connCityJ = DBConnection.getConnection()) {
                String sql = "SELECT CITY_CODE, NAME FROM GLOBALCONFIG.CITY ORDER BY UPPER(NAME)";
                psCityJoint = connCityJ.prepareStatement(sql);
                rsCityJoint = psCityJoint.executeQuery();
                while (rsCityJoint.next()) {
                  String cityCode = rsCityJoint.getString("CITY_CODE");
                  String cityName = rsCityJoint.getString("NAME");
            %>
                  <option value="<%= cityCode %>"><%= cityName %></option>
            <% 
                }
              } catch (Exception e) {
                out.println("<option disabled>Error loading cities</option>");
                e.printStackTrace();
              } finally {
                if (rsCityJoint != null) rsCityJoint.close();
                if (psCityJoint != null) psCityJoint.close();
              }
            %>
          </select>
        </div>

        <div>
          <label>Zip</label>
          <input type="text" name="jointZip[]" class="zip-input" maxlength="6" required>
          <small class="zipError"></small>
        </div>
      </div>
    </div>
  </fieldset>
  <% } else { %>
  <!-- Hidden input to indicate no joint holder required -->
  <input type="hidden" name="jointHolderNotRequired" value="true">
  <% } %>

  <!-- ========================================== -->
  <!-- FORM BUTTONS -->
  <!-- ========================================== -->
  <div class="form-buttons">
    <button type="submit">Save</button>
    <button type="reset">Reset</button>
  </div>
</form>

<!-- Customer Lookup Modal (same as original) -->
<div id="customerLookupModal" class="customer-modal">
  <div class="customer-modal-content">
    <span class="customer-close" onclick="closeCustomerLookup()">&times;</span>
    <div id="customerLookupContent"></div>
  </div>
</div>

<script src="js/savingAcc.js"></script>
<script src="js/application-tabs.js"></script>
<script>
function validateForm() {
    const customerId = document.getElementById('customerId').value.trim();
    
    if (!customerId) {
        showToast('❌ Please select a customer before submitting');
        return false;
    }
    
    return true;
}

// Check URL parameters for success/error messages
window.addEventListener('DOMContentLoaded', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const status = urlParams.get('status');
    const applicationNumber = urlParams.get('applicationNumber');
    const message = urlParams.get('message');
    
    if (status === 'success' && applicationNumber) {
        Toastify({
            text: "✅ Application saved successfully!\nApplication Number: " + applicationNumber,
            duration: 6000,
            close: true,
            gravity: "top",
            position: "center",
            style: {
                background: "#fff",
                color: "#333",
                borderRadius: "8px",
                fontSize: "14px",
                padding: "16px 24px",
                boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
                borderLeft: "5px solid #4caf50",
                marginTop: "20px",
                whiteSpace: "pre-line"
            },
            stopOnFocus: true
        }).showToast();
        
        setTimeout(function() {
            const cleanUrl = window.location.pathname + window.location.search.replace(/[?&](status|applicationNumber|message)=[^&]*/g, '').replace(/^&/, '?').replace(/\?$/, '');
            window.history.replaceState({}, document.title, cleanUrl || window.location.pathname);
        }, 100);
        
    } else if (status === 'error') {
        Toastify({
            text: "❌ Error: " + (message || "Failed to save application"),
            duration: 6000,
            close: true,
            gravity: "top",
            position: "center",
            style: {
                background: "#fff",
                color: "#333",
                borderRadius: "8px",
                fontSize: "14px",
                padding: "16px 24px",
                boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
                borderLeft: "5px solid #f44336",
                marginTop: "20px"
            },
            stopOnFocus: true
        }).showToast();
        
        setTimeout(function() {
            const cleanUrl = window.location.pathname + window.location.search.replace(/[?&](status|applicationNumber|message)=[^&]*/g, '').replace(/^&/, '?').replace(/\?$/, '');
            window.history.replaceState({}, document.title, cleanUrl || window.location.pathname);
        }, 100);
    }
});
</script>
</body>
</html>