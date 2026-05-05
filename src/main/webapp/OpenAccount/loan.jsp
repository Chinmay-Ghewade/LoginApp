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
	    
	    // Get product code from request
	    String productCode = request.getParameter("productCode");
	    if (productCode == null) {
	        productCode = "";
	    }
	    System.out.println("📌 loan.jsp - Product Code received: " + productCode);
	    
	    // Fetch product parameters to determine which fieldsets to show
	    boolean showNominee = false;
	    boolean showJointHolder = false;
	    boolean showGuarantor = false;
	    boolean showLandBuilding = false;
	    boolean showDeposit = false;
	    boolean showGold = false;
	    boolean showSharesHolder = false;
	    boolean showPlantMachinery = false;
	    boolean showVehicle = false;
	    boolean showMarketShares = false;
	    boolean showStockStatement = false;
	    boolean showFurnitureFixture = false;
	    boolean showStockPledge = false;
	    boolean showBookDebts = false;
	    boolean showSalary = false;
	    boolean showOffice = false;
	    boolean showLIC = false;          
	    boolean showFirePolicy = false;
	    boolean showPrinodv = false;
	    boolean showMotorInsurance = false;
	    boolean showNonMotorInsurance = false;
	    boolean showGovSecurity = false;
	    
	    if (!productCode.isEmpty()) {
	        PreparedStatement psProduct = null;
	        ResultSet rsProduct = null;
	        try (Connection connProduct = DBConnection.getConnection()) {
	        	String sql = "SELECT " +
	        		    "PPL.IS_NOMINEE_REQUIRED, " +
	        		    "PPL.IS_JOINT_HOLDER_REQUIRED, " +
	        		    "PPL.IS_GUARANTOR_REQUIRED, " +
	        		    "PPL.IS_LAND_N_BUILDING_DETAILS_REQ, " +
	        		    "PPL.IS_DEPOSIT_DETAILS_REQUIRED, " +
	        		    "PPL.IS_GOLD_DETAILS_REQUIRED, " +
	        		    "PPL.IS_SHARES_HOLDER_REQUIRED, " +
	        		    "PPL.IS_PLANT_N_MACHINORY_DET_REQ, " +
	        		    "PPL.IS_VEHICLE_DETAILS_REQUIRED, " +
	        		    "PPL.IS_MARKET_SHARES_DETAILS_REQ, " +
	        		    "PPL.IS_STOCK_STATEMENT_DETAILS_REQ, " +
	        		    "PPL.IS_FURNITURE_N_FIXTURE_DET_REQ, " +
	        		    "PPL.IS_STOCK_PLEDGE_DETAILS_REQ, " +
	        		    "PPL.IS_BOOK_DEBTS_DETAILS_REQUIRED, " +
	        		    "PPL.IS_SALARY_DETAILS_REQUIRED, " +
	        		    "PPL.IS_LIC_DETAILS_REQUIRED, " +        
	        		    "PPL.IS_FIRE_POLICY_DETAILS_REQ, " +
	        		    "PPL.IS_PRINOVD_REQUIRED, " +
	        		    "PPL.IS_MOTOR_INS_DET_REQUIRED, " +
	        		    "PPL.IS_NONMOTOR_INS_DET_REQUIRED, " +
	        		    "PPL.IS_GOV_CERTI_DET_REQUIRED, " +
	        		    "PPL.IS_OFFICE_DETAILS_REQUIRED " +
	        		    "FROM HEADOFFICE.PRODUCT P " +
	        		    "JOIN HEADOFFICE.PRODUCTPARAMETERLOAN PPL ON P.PRODUCT_CODE = PPL.PRODUCT_CODE " +
	        		    "WHERE P.PRODUCT_CODE = ?";
	            
	            psProduct = connProduct.prepareStatement(sql);
	            psProduct.setString(1, productCode);
	            rsProduct = psProduct.executeQuery();
	            
	            if (rsProduct.next()) {
	                showNominee = "Y".equalsIgnoreCase(rsProduct.getString("IS_NOMINEE_REQUIRED"));
	                showJointHolder = "Y".equalsIgnoreCase(rsProduct.getString("IS_JOINT_HOLDER_REQUIRED"));
	                showGuarantor = "Y".equalsIgnoreCase(rsProduct.getString("IS_GUARANTOR_REQUIRED"));
	                showLandBuilding = "Y".equalsIgnoreCase(rsProduct.getString("IS_LAND_N_BUILDING_DETAILS_REQ"));
	                showDeposit = "Y".equalsIgnoreCase(rsProduct.getString("IS_DEPOSIT_DETAILS_REQUIRED"));
	                showGold = "Y".equalsIgnoreCase(rsProduct.getString("IS_GOLD_DETAILS_REQUIRED"));
	                showSharesHolder = "Y".equalsIgnoreCase(rsProduct.getString("IS_SHARES_HOLDER_REQUIRED"));
	                showPlantMachinery = "Y".equalsIgnoreCase(rsProduct.getString("IS_PLANT_N_MACHINORY_DET_REQ"));
	                showVehicle = "Y".equalsIgnoreCase(rsProduct.getString("IS_VEHICLE_DETAILS_REQUIRED"));
	                showMarketShares = "Y".equalsIgnoreCase(rsProduct.getString("IS_MARKET_SHARES_DETAILS_REQ"));
	                showStockStatement = "Y".equalsIgnoreCase(rsProduct.getString("IS_STOCK_STATEMENT_DETAILS_REQ"));
	                showFurnitureFixture = "Y".equalsIgnoreCase(rsProduct.getString("IS_FURNITURE_N_FIXTURE_DET_REQ"));
	                showStockPledge = "Y".equalsIgnoreCase(rsProduct.getString("IS_STOCK_PLEDGE_DETAILS_REQ"));
	                showBookDebts = "Y".equalsIgnoreCase(rsProduct.getString("IS_BOOK_DEBTS_DETAILS_REQUIRED"));
	                showSalary = "Y".equalsIgnoreCase(rsProduct.getString("IS_SALARY_DETAILS_REQUIRED"));
	                showLIC = "Y".equalsIgnoreCase(rsProduct.getString("IS_LIC_DETAILS_REQUIRED"));                 
	                showFirePolicy = "Y".equalsIgnoreCase(rsProduct.getString("IS_FIRE_POLICY_DETAILS_REQ"));      
	                showOffice = "Y".equalsIgnoreCase(rsProduct.getString("IS_OFFICE_DETAILS_REQUIRED"));
	                showPrinodv = "Y".equalsIgnoreCase(rsProduct.getString("IS_PRINOVD_REQUIRED"));
	                showMotorInsurance = "Y".equalsIgnoreCase(rsProduct.getString("IS_MOTOR_INS_DET_REQUIRED"));
	                showNonMotorInsurance = "Y".equalsIgnoreCase(rsProduct.getString("IS_NONMOTOR_INS_DET_REQUIRED"));
	                showGovSecurity = "Y".equalsIgnoreCase(rsProduct.getString("IS_GOV_CERTI_DET_REQUIRED"));
	                
	                System.out.println("🔍 Product Parameters for " + productCode + ":");
	                System.out.println("   - Nominee: " + showNominee);
	                System.out.println("   - Joint Holder (Co-Borrower): " + showJointHolder);
	                System.out.println("   - Guarantor: " + showGuarantor);
	                System.out.println("   - Land & Building: " + showLandBuilding);
	                System.out.println("   - Deposit: " + showDeposit);
	                System.out.println("   - Gold: " + showGold);
	                System.out.println("   - Shares Holder: " + showSharesHolder);
	                System.out.println("   - Plant & Machinery: " + showPlantMachinery);
	                System.out.println("   - Vehicle: " + showVehicle);
	                System.out.println("   - Market Shares: " + showMarketShares);
	                System.out.println("   - Stock Statement: " + showStockStatement);
	                System.out.println("   - Furniture & Fixture: " + showFurnitureFixture);
	                System.out.println("   - Stock Pledge: " + showStockPledge);
	                System.out.println("   - Book Debts: " + showBookDebts);
	                System.out.println("   - Salary: " + showSalary);
	                System.out.println("   - LIC: " + showLIC);                    
	                System.out.println("   - Fire Policy: " + showFirePolicy);     
	                System.out.println("   - Office: " + showOffice);
	            }
	        } catch (Exception e) {
	            e.printStackTrace();
	            System.out.println("❌ Error fetching product parameters: " + e.getMessage());
	        } finally {
	            if (rsProduct != null) rsProduct.close();
	            if (psProduct != null) psProduct.close();
	        }
	    }
	%>
	
	<!DOCTYPE html>
	<html lang="en">
	<head>
	  <meta charset="UTF-8">
	  <title>Loan Account Application</title>
	  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
	  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
	  <link rel="stylesheet" type="text/css" href="css/savingAcc.css">
	  <link rel="stylesheet" href="css/application-tabs.css">
	</head>
	<body>
	<form action="LoanServlet" method="post">
	  <input type="hidden" name="productCode" value="<%= productCode %>">
	
	  <!-- Application Fieldset - Always Show -->
	  <fieldset>
	    <legend>Application</legend>
	    <div class="form-grid">
	      
	      <!-- ✅ ADD: Display Product Code for verification -->
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
	  		<label>Introduer A/c Code</label>
	  		<input type="text" name="introducerAccCode" maxlength="14" pattern="[0-9]{14}" inputmode="numeric"
	    	title="Introduer Account Code must be exactly 14 digits" required>
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
	        <select name="accountOperationCapacity" id="dd-accountOperationCapacity" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
	      </div>
	
	      <div>
	  <label>Min Balance</label>
	  <select name="minBalanceID" id="dd-minBalance" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
	</div>
	<div>
	  <label>Risk Category</label>
	  <input type="text" id="riskCategory" name="riskCategory" readonly>
	</div>
	      
	    </div>
	  </fieldset>
	
	
	  <!-- Loan Details Fieldset - Always Show -->
	<fieldset id="loanFieldset">
	  <legend>Loan Details</legend>
	  <div class="form-grid">
	  
	    <div>
	    	<label>Submission Date</label>
	    	<input type="date" name="submissionDate" id="submissionDate" value="<%= workingDateStr %>" required>
		</div>
	  
	    <div>
	      <label>Resolution No</label>
	      <input type="text" name="resolutionNo" required>
	    </div>
	
		<div>
	  		<label>Registration Date</label>
	  		<input type="date" name="registrationDate" id="registrationDate" required>
		</div>
	
	    <div>
	      <label>Register Amount</label>
	      <input type="number" step="0.01" name="registerAmount" required >
	    </div>
	
		<div>
	  		<label>Limit Amount</label>
	  		<input type="number" step="0.01" name="limitAmount" id="limitAmount" required>
		</div>
	
		<div>
		  <label>Drawing Power</label>
		  <input type="number" step="0.01" name="drawingPower" id="drawingPower" required>
		</div>
	
	    <div>
			<label for="sanctionDate">Sanction Date</label>
			<input type="date" id="sanctionDate" name="sanctionDate" required>  
		</div>
	
		<div>
		  <label>Sanction Amount</label>
		  <input type="number" step="0.01" name="sanctionAmount" id="sanctionAmount" required>
		</div>
	
	    <div>
			<label for="loanPeriod">Period of Loan (months)</label>
	  		<input type="number" id="loanPeriod" name="loanPeriod" min="1" required>
	    </div>
	
	    <div>
	      <label for="reviewDate">A/c Review Date</label>
	 	  <input type="date" id="reviewDate" name="reviewDate" readonly>
	    </div>
	
	
		<div>
	    		<label for="installmentTypeId">Installment Type Id</label>
	    	<div class="input-icon-box">
	        	<input type="text" id="installmentTypeId" name="installmentTypeId" 
	               onclick="openInstallmentLookup()" readonly required>
	        	<button type="button" class="inside-icon-btn" 
	                onclick="openInstallmentLookup()" title="Search Installment Type">🔍</button>
	    	</div>
		</div>
	
	
	    <div>
	      <label for="installmentType">Installment Type</label>
		  <input type="text" name="installmentType" id="installmentType" readonly>
	    </div>
	
	    <div>
	      <label>Repayment Freq.</label>
	      <select name="repaymentFreq" required>
	        <option value="">-- Select --</option>
	        <option value="M">Monthly</option>
	        <option value="Q">Quarterly</option>
	        <option value="H">Half-Yearly</option>
	        <option value="Y">Yearly</option>
	        <option value="O">On Maturity</option>
	      </select>
	    </div>
	
	    <div>
	      <label>Int. Calculation Method</label>
	      <select name="intCalcMethod" required>
	        <option value="">-- Select --</option>
	        <option value="S">Simple</option>
	        <option value="R">Reducing</option>
	        <option value="F">Flat</option>
	      </select>
	    </div>
	
	    <div>
	      <label>Interest Rate</label>
	      <input type="number" step="0.01" name="interestRate" required>
	    </div>
	
	    <div>
	      <label>Penal Int. Rate</label>
	      <input type="number" step="0.01" name="penalIntRate" value="0" required>
	    </div>
	
	    <div>
	      <label>Mor. Int. Rate</label>
	      <input type="number" step="0.01" name="morIntRate" value="0" required>
	    </div>
	
	    <div>
	      <label>Overdue Int. Rate</label>
	      <input type="number" step="0.01" name="overdueIntRate" value="0" required>
	    </div>
	
	    <div>
	      <label>Mor. Period Month</label>
	      <input type="number" name="morPeriodMonth" value="0" required>
	    </div>
	
	    <div>
	  		<label>Inst. Amount</label>
	  		<input type="number" step="0.01" name="instAmount" id="instAmount" value="0" readonly 
	         style="background-color: #f0f0f0; cursor: not-allowed;">
		</div>
	
	    <div>
	      <label>Consortium Loan</label>
	      <div>
	        <label><input type="radio" name="consortiumLoan" value="Y"> Yes</label>
	        <label><input type="radio" name="consortiumLoan" value="N" checked> No</label>
	      </div>
	    </div>
	
	<div>
	  <label>Area Code</label>
	  <div class="input-icon-box">
	    <input type="text" id="areaCode" name="areaCode" 
	           onclick="openAreaLookup()" readonly required>
	    <button type="button" class="inside-icon-btn" 
	            onclick="openAreaLookup()" title="Search Area">🔍</button>
	  </div>
	</div>
	
	<div>
	  <label>Area Name</label>
	  <input type="text" id="areaName" name="areaName" readonly>
	</div>
	    
	       <div>
	  <label>Social Section Id</label>
	  <select name="socialSectionId" required>
	    <option value="">-- Select --</option>
	
	    <%
	      PreparedStatement psSocial = null;
	      ResultSet rsSocial = null;
	      try (Connection connSocial = DBConnection.getConnection()) {
	        String sql = "SELECT SOCIALSECTION_ID, DESCRIPTION FROM GLOBALCONFIG.SOCIALSECTION ORDER BY SOCIALSECTION_ID";
	        psSocial = connSocial.prepareStatement(sql);
	        rsSocial = psSocial.executeQuery();
	
	        while (rsSocial.next()) {
	          String id = rsSocial.getString("SOCIALSECTION_ID");   // ID to store
	          String desc = rsSocial.getString("DESCRIPTION");      // Text to show
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Social Section</option>");
	      } finally {
	        if (rsSocial != null) rsSocial.close();
	        if (psSocial != null) psSocial.close();
	      }
	    %>
	
	  </select>
	</div>
	
	
	<div>
	  <label>Sub Area Code</label>
	  <div class="input-icon-box">
	    <input type="text" id="subAreaCode" name="subAreaCode" 
	           onclick="openSubAreaLookup()" readonly required>
	    <button type="button" class="inside-icon-btn" 
	            onclick="openSubAreaLookup()" title="Search Sub Area">🔍</button>
	  </div>
	</div>
	
	<div>
	  <label>Sub Area Name</label>
	  <input type="text" id="subAreaName" name="subAreaName" readonly>
	</div>
	    
	    <div>
	  <label>LBR Code</label>
	  <select name="lbrCode" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psMIS = null;
	      ResultSet rsMIS = null;
	
	      try (Connection conMIS = DBConnection.getConnection()) {
	        String sql = "SELECT MIS_ID, DESCRIPTION FROM HEADOFFICE.MIS ORDER BY DESCRIPTION";
	        psMIS = conMIS.prepareStatement(sql);
	        rsMIS = psMIS.executeQuery();
	
	        while (rsMIS.next()) {
	          String id = rsMIS.getString("MIS_ID");
	          String desc = rsMIS.getString("DESCRIPTION");
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading LBR Code</option>");
	      } finally {
	        if (rsMIS != null) rsMIS.close();
	        if (psMIS != null) psMIS.close();
	      }
	    %>
	  </select>
	</div>
	
	    
	    <div>
	  <label>Social Sector Id</label>
	  <div class="input-icon-box">
	    <input type="text" id="socialSectorId" name="socialSectorId" 
	           onclick="openSocialSectorLookup()" readonly required>
	    <button type="button" class="inside-icon-btn" 
	            onclick="openSocialSectorLookup()" title="Search Social Sector">🔍</button>
	  </div>
	</div>
	
	<div>
	  <label>Social Sector Description</label>
	  <input type="text" id="socialSectorDesc" name="socialSectorDesc" readonly>
	</div>
	
	    <div>
	  <label>Purpose Id</label>
	  <select name="purposeId" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psPurpose = null;
	      ResultSet rsPurpose = null;
	      try (Connection connPurpose = DBConnection.getConnection()) {
	
	        String sql = "SELECT PURPOSE_ID, DESCRIPTION FROM HEADOFFICE.PURPOSE ORDER BY DESCRIPTION";
	        psPurpose = connPurpose.prepareStatement(sql);
	        rsPurpose = psPurpose.executeQuery();
	
	        while (rsPurpose.next()) {
	          String id = rsPurpose.getString("PURPOSE_ID");        // value to store
	          String desc = rsPurpose.getString("DESCRIPTION");     // text to display
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Purpose</option>");
	      } finally {
	        if (rsPurpose != null) rsPurpose.close();
	        if (psPurpose != null) psPurpose.close();
	      }
	    %>
	  </select>
	</div>
	
	    
	    <div>
	  <label>Social SubSector Id</label>
	  <div class="input-icon-box">
	    <input type="text" id="socialSubSectorId" name="socialSubSectorId" 
	           onclick="openSocialSubSectorLookup()" readonly required>
	    <button type="button" class="inside-icon-btn" 
	            onclick="openSocialSubSectorLookup()" title="Search Social SubSector">🔍</button>
	  </div>
	</div>
	
	<div>
	  <label>Social SubSector Description</label>
	  <input type="text" id="socialSubSectorDesc" name="socialSubSectorDesc" readonly>
	</div>
	
	    <div>
	  <label>Classification Id</label>
	  <select name="classificationId" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psClass = null;
	      ResultSet rsClass = null;
	
	      try (Connection connClass = DBConnection.getConnection()) {
	
	        String sql = "SELECT CLASSIFICATION_ID, DESCRIPTION FROM HEADOFFICE.CLASSIFICATION ORDER BY DESCRIPTION";
	        psClass = connClass.prepareStatement(sql);
	        rsClass = psClass.executeQuery();
	
	        while (rsClass.next()) {
	          String id = rsClass.getString("CLASSIFICATION_ID");     // value to store
	          String desc = rsClass.getString("DESCRIPTION");         // visible text
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Classification</option>");
	      } finally {
	        if (rsClass != null) rsClass.close();
	        if (psClass != null) psClass.close();
	      }
	    %>
	  </select>
	</div>
	
	    <div>
	  <label>Mode Of San. Id</label>
	  <select name="modeOfSanId" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psMOS = null;
	      ResultSet rsMOS = null;
	
	      try (Connection conMOS = DBConnection.getConnection()) {
	        String sql = "SELECT MODEOFSANCTION_ID, DESCRIPTION FROM HEADOFFICE.MODEOFSANCTION ORDER BY DESCRIPTION";
	        psMOS = conMOS.prepareStatement(sql);
	        rsMOS = psMOS.executeQuery();
	
	        while (rsMOS.next()) {
	          String id = rsMOS.getString("MODEOFSANCTION_ID");
	          String desc = rsMOS.getString("DESCRIPTION");
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Mode of Sanction</option>");
	      } finally {
	        if (rsMOS != null) rsMOS.close();
	        if (psMOS != null) psMOS.close();
	      }
	    %>
	  </select>
	</div>
	
	
	    <div>
	  <label>Sanction Authority Id</label>
	  <select name="sanctionAuthorityId" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psSA = null;
	      ResultSet rsSA = null;
	
	      try (Connection conSA = DBConnection.getConnection()) {
	        String sql = "SELECT SANCTIONAUTHORITY_ID, DESCRIPTION FROM HEADOFFICE.SANCTIONAUTHORITY ORDER BY DESCRIPTION";
	        psSA = conSA.prepareStatement(sql);
	        rsSA = psSA.executeQuery();
	
	        while (rsSA.next()) {
	          String id = rsSA.getString("SANCTIONAUTHORITY_ID");
	          String desc = rsSA.getString("DESCRIPTION");
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Sanction Authority</option>");
	      } finally {
	        if (rsSA != null) rsSA.close();
	        if (psSA != null) psSA.close();
	      }
	    %>
	  </select>
	</div>
	
	
	    <div>
	  <label>Industry Id</label>
	  <select name="industryId" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psInd = null;
	      ResultSet rsInd = null;
	
	      try (Connection conInd = DBConnection.getConnection()) {
	        String sql = "SELECT INDUSTRY_ID, DESCRIPTION FROM HEADOFFICE.INDUSTRY ORDER BY DESCRIPTION";
	        psInd = conInd.prepareStatement(sql);
	        rsInd = psInd.executeQuery();
	
	        while (rsInd.next()) {
	          String id = rsInd.getString("INDUSTRY_ID");
	          String desc = rsInd.getString("DESCRIPTION");
	    %>
	          <option value="<%= id %>"><%= desc %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Industry</option>");
	      } finally {
	        if (rsInd != null) rsInd.close();
	        if (psInd != null) psInd.close();
	      }
	    %>
	  </select>
	</div>
	
	
	    <div>
	  <label>Is Director Related</label>
	  <div>
	    <label><input type="radio" name="isDirectorRelated" value="Y" onclick="toggleDirectorFields()"> Yes</label>
	    <label><input type="radio" name="isDirectorRelated" value="N" checked onclick="toggleDirectorFields()"> No</label>
	  </div>
	</div>
	
	<div>
	  <label>Director Id</label>
	  <input type="text" name="directorId" id="directorId" required>
	</div>
	
	<div>
	  <label>Director Name</label>
	  <input type="text" name="directorName" id="directorName" required>
	</div>
	
	  </div> <!-- end .form-grid -->
	</fieldset>
	
	
	  <!-- Nominee Fieldset - Conditional -->
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
	        <select name="nomineeSalutation[]" id="dd-nomineeSalutation" required class="dd-loading">
  		<option value="">Loading...</option>
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
	        <select name="nomineeCountry[]" id="dd-nomineeCountry" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
	      </div>
	
	      <div>
	        <label>State</label>
	        <select name="nomineeState[]" id="dd-nomineeState" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
	      </div>
	
	      <div>
	        <label>City</label>
	        <select name="nomineeCity[]" id="dd-nomineeCity" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
	      </div>
	
		<div>
	  		<label>Zip</label>
	  		<input type="text" name="nomineeZip[]" class="zip-input" maxlength="6" required>
	  		<small class="zipError"></small>
		</div>
	
	      <div>
	        <label>Relation with Guardian</label>
	        <select name="nomineeRelation[]" id="dd-nomineeRelation" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
	      </div>
	    </div>
	  </div>
	</fieldset>
	  <% } %>
	
	  <!-- Co-Borrower/Joint Holder Fieldset - Conditional -->
	  <% if (showJointHolder) { %>
	<fieldset id="coBorrowerFieldset">
	  <legend>
	    Co-Borrower
	    <button type="button" onclick="addCoBorrower()" 
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	
	  <div class="nominee-card coBorrower-block">
	    <button type="button" class="nominee-remove" onclick="removeCoBorrower(this)">✖</button>
	
	    <div class="nominee-title" 
	         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
	      Co-Borrower <span class="coBorrower-serial">1</span>
	    </div>
	    
	    <div class="inline-fields">
	      <div>
	        <label>Has Customer ID ?</label>
	        <div style="flex-direction: row;" class="radio-group">
	          <label><input type="radio" name="coBorrowerHasCustomerID_1" class="coBorrowerHasCustomerRadio" value="yes" onchange="toggleCoBorrowerCustomerID(this)"> Yes</label>
	          <label><input type="radio" name="coBorrowerHasCustomerID_1" class="coBorrowerHasCustomerRadio" value="no" onchange="toggleCoBorrowerCustomerID(this)" checked> No</label>
	        </div>
	      </div>
	
	      <div class="coBorrowerCustomerIDContainer" style="display:none; margin-top:10px;">
	        <label>Customer ID</label>
	        <div class="input-icon-box">
	          <input type="text" class="coBorrowerCustomerIDInput" name="coBorrowerCustomerID[]" onclick="openCoBorrowerCustomerLookup(this)" readonly>
	          <button type="button" class="inside-icon-btn" onclick="openCoBorrowerCustomerLookup(this)" title="Search Customer">🔍</button>
	        </div>
	      </div>
	    </div>
	
	    <br>
	
	    <div class="personal-grid">
	      <!-- ✅ FIXED: Changed from nomineeSalutation[] to coBorrowerSalutation[] -->
	      <div>
	        <label>Salutation Code</label>
	        <select name="coBorrowerSalutation[]" id="dd-coBorrowerSalutation" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
	      <!-- ✅ FIXED: Changed from nomineeName[] to coBorrowerName[] -->
	      <div>
	        <label>Co-Borrower Name</label>
	        <input type="text" name="coBorrowerName[]" required oninput="this.value = this.value
	        .replace(/[^A-Za-z ]/g, '')
	        .replace(/\s{2,}/g, ' ')
	        .replace(/^\s+/g, '')
	        .toLowerCase()
	        .replace(/\b\w/g, c => c.toUpperCase());">
		</div>
	
	      <div>
	        <label>Address 1</label>
	        <input type="text" name="coBorrowerAddress1[]" required>
	      </div>
	
	      <div>
	        <label>Address 2</label>
	        <input type="text" name="coBorrowerAddress2[]">
	      </div>
	
	      <div>
	        <label>Address 3</label>
	        <input type="text" name="coBorrowerAddress3[]">
	      </div>
	
	      <!-- ✅ FIXED: Changed from countryCode to coBorrowerCountry[] -->
	      <div>
	        <label>Country</label>
	        <select name="coBorrowerCountry[]" id="dd-coBorrowerCountry" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
	      <!-- ✅ FIXED: Changed from stateCode to coBorrowerState[] -->
	      <div>
	        <label>State</label>
	        <select name="coBorrowerState[]" id="dd-coBorrowerState" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
	      <!-- ✅ FIXED: Changed from cityCode to coBorrowerCity[] -->
	      <div>
	        <label>City</label>
	        <select name="coBorrowerCity[]" id="dd-coBorrowerCity" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
		<div>
	  		<label>Zip</label>
	  		<input type="text" name="coBorrowerZip[]" class="zip-input" maxlength="6" required>
	  		<small class="zipError"></small>
		</div>
	    </div>
	  </div>
	</fieldset>
	  <% } %>
	
	  <!-- Guarantor Fieldset - Conditional -->
	  <% if (showGuarantor) { %>
	  <fieldset id="guarantorFieldset">
	  <legend>
	    Guarantor
	    <button type="button" onclick="addGuarantor()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	
	  <div class="nominee-card guarantor-block">
	    <button type="button" class="nominee-remove" onclick="removeGuarantor(this)">✖</button>
	
	    <div class="nominee-title"
	         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
	      Guarantor <span class="guarantor-serial">1</span>
	    </div>
	    
	    <div class="inline-fields">
	      <div>
	        <label>Has Customer ID ?</label>
	        <div style="flex-direction: row;" class="radio-group">
	          <label><input type="radio" name="guarantorHasCustomerID_1" class="guarantorHasCustomerRadio" value="yes" onchange="toggleGuarantorCustomerID(this)"> Yes</label>
	          <label><input type="radio" name="guarantorHasCustomerID_1" class="guarantorHasCustomerRadio" value="no" onchange="toggleGuarantorCustomerID(this)" checked> No</label>
	        </div>
	      </div>
	
	      <div class="guarantorCustomerIDContainer" style="display:none; margin-top:10px;">
	        <label>Customer ID</label>
	        <div class="input-icon-box">
	          <input type="text" class="guarantorCustomerIDInput" name="guarantorCustomerID[]" onclick="openGuarantorCustomerLookup(this)" readonly>
	          <button type="button" class="inside-icon-btn" onclick="openGuarantorCustomerLookup(this)" title="Search Customer">🔍</button>
	        </div>
	      </div>
	    </div>
	
	    <br>
	
	    <div class="address-grid">
	      <!-- ✅ FIXED: Changed from guarantorsalutation[] to guarantorSalutation[] -->
	      <div>
	        <label>Salutation Code</label>
	        <select name="guarantorSalutation[]" id="dd-guarantorSalutation" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
	      <div>
	        <label>Guarantor Name</label>
	        <input type="text" name="guarantorName[]" required oninput="this.value = this.value
	        .replace(/[^A-Za-z ]/g, '')
	        .replace(/\s{2,}/g, ' ')
	        .replace(/^\s+/g, '')
	        .toLowerCase()
	        .replace(/\b\w/g, c => c.toUpperCase());">
		</div>
	
	      <div>
	        <label>Address 1</label>
	        <input type="text" name="guarantorAddress1[]" required>
	      </div>
	
	      <div>
	        <label>Address 2</label>
	        <input type="text" name="guarantorAddress2[]">
	      </div>
	
	      <div>
	        <label>Address 3</label>
	        <input type="text" name="guarantorAddress3[]">
	      </div>
	
	      <!-- ✅ FIXED: Changed from securityTypeCode[][] to guarantorCountry[] -->
	      <div>
	        <label>Country</label>
	        <select name="guarantorCountry[]" id="dd-guarantorCountry" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
	      <!-- ✅ FIXED: Changed from jointState[] to guarantorState[] -->
	      <div>
	        <label>State</label>
	        <select name="guarantorState[]" id="dd-guarantorState" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
	      <!-- ✅ FIXED: Changed from jointCity[] to guarantorCity[] -->
	      <div>
	        <label>City</label>
	        <select name="guarantorCity[]" id="dd-guarantorCity" required class="dd-loading">
  				<option value="">Loading...</option>
			</select>
	      </div>
	
		<div>
	  		<label>Zip</label>
	  		<input type="text" name="guarantorZip[]" class="zip-input" maxlength="6" required>
	  		<small class="zipError"></small>
		</div>
	
	      <div>
	        <label>Member No</label>
	        <input type="text" name="guarantorMemberNo[]" maxlength="2"
	      	oninput="this.value = this.value.replace(/[^0-9]/g, '');" required>
		</div>
	
	      <div>
	        <label>Employee Id</label>
	        <input type="number" name="guarantorEmployeeId[]" required>
	      </div>
	
	      <div>
	        <label>Birth Date</label>
	        <input type="date" name="guarantorBirthDate[]" required>
	      </div>
	
	      <div>
	        <label>Phone No</label>
	        <input type="text" name="guarantorPhoneNo[]" maxlength="10"
	   		oninput="this.value = this.value.replace(/[^0-9]/g, '');" required>
	      </div>
	
	      <div>
	        <label>Mobile No</label>
	        <input type="text" name="guarantorMobileNo[]" maxlength="10"
	   		oninput="this.value = this.value.replace(/[^0-9]/g, '');">
	      </div>
	    </div>
	  </div>
	</fieldset>
	  <% } %>
	
	  <!-- Land & Building Fieldset - Conditional -->
	  <% if (showLandBuilding) { %>
	<fieldset id="landBuildingFieldset">
		<legend>
	    	Land & Building
	    	<button type="button" onclick="addLandBuilding()"
	      		style="border:none;background:#373279;color:white;padding:2px 10px;
	        	border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      		➕
	    	</button>
	  	</legend>
	
		<div class="nominee-card lb-block">
	    	<button type="button" class="nominee-remove" onclick="removeLandBuilding(this)">✖</button>
	
	    	<div class="nominee-title"
	         	style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
	      		Land & Building <span class="lb-serial">1</span>
	    	</div>
	
		<div class="form-grid">
			<div>
	  			<label>Security Type Code</label>
	  			<select name="securityTypeCode[]" required>
	    		<option value="">-- Select --</option>
	    <%
	      PreparedStatement psSecType = null;
	      ResultSet rsSecType = null;
	      try (Connection connSecType = DBConnection.getConnection()) {
	        String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
	        psSecType = connSecType.prepareStatement(sql);
	        rsSecType = psSecType.executeQuery();
	        
	        while (rsSecType.next()) {
	          String securityType = rsSecType.getString("SECURITYTYPE_CODE");
	    %>
	          <option value="<%= securityType %>"><%= securityType %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Security Types</option>");
	        e.printStackTrace();
	      } finally {
	        if (rsSecType != null) rsSecType.close();
	        if (psSecType != null) psSecType.close();
	      }
	    %>
	  			</select>
			</div>
	
			<div>
	        	<label>Submi. Date</label>
	        	<input type="date" name="lbSubmiDate[]" required>
	      	</div>
	
	      	<div>
	        	<label>Amt. Valued</label>
	        	<input type="number" step="0.01" name="lbAmtValued[]" value="0" required>
	      	</div>
	
	      	<div>
	        	<label>Margin %</label>
	        	<input type="number" step="0.01" name="lbMargin[]" value="0" required>
	      	</div>
	
	      	<div>
	        	<label>Area</label>
	        	<input type="number" step="0.01" name="lbArea[]" value="0" required>
	      	</div>
	
	      	<div>
	        	<label>Unit Of Area</label>
	        	<input type="text" name="lbUnitOfArea[]" required>
	      	</div>
	
	      	<div>
	        	<label>Location</label>
	        	<input type="text" name="lbLocation[]" required>
	      	</div>
	
	      	<div>
	        	<label>Security Value</label>
	        	<input type="number" step="0.01" name="lbSecurityValue[]" value="0" required>
	      	</div> 
	
	      	<div>
	        	<label>Remark</label>
	        	<input type="text" name="lbRemark[]" required>
	      	</div>
	      
	      	<div>
	        	<label>Particular</label>
	        	<textarea name="lbParticular[]" rows="3" style="width: 95%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
	      	</div>
	    </div>
	  </div>
	</fieldset>
	
	  <% } %>
	
	  <!-- Deposit Details Fieldset - Conditional -->
	  <% if (showDeposit) { %>
	<fieldset id="depositDetailsFieldset">
	  <legend>
	    Deposit Details
	    <button type="button" onclick="addDepositDetails()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	
	  <div class="nominee-card deposit-block">
	    <button type="button" class="nominee-remove" onclick="removeDepositDetails(this)">✖</button>
	
	    <div class="nominee-title"
	         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
	      Deposit Details <span class="deposit-serial">1</span>
	    </div>
	
	    <div class="form-grid">
	
	      <div>
	  <label>Security Type Code</label>
	  <select name="securityTypeCode[]" required>
	    <option value="">-- Select --</option>
	    <%
	      PreparedStatement psSecType = null;
	      ResultSet rsSecType = null;
	      try (Connection connSecType = DBConnection.getConnection()) {
	        String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
	        psSecType = connSecType.prepareStatement(sql);
	        rsSecType = psSecType.executeQuery();
	        
	        while (rsSecType.next()) {
	          String securityType = rsSecType.getString("SECURITYTYPE_CODE");
	    %>
	          <option value="<%= securityType %>"><%= securityType %></option>
	    <%
	        }
	      } catch (Exception e) {
	        out.println("<option disabled>Error loading Security Types</option>");
	        e.printStackTrace();
	      } finally {
	        if (rsSecType != null) rsSecType.close();
	        if (psSecType != null) psSecType.close();
	      }
	    %>
	  </select>
	</div>
	
	      <div>
	        <label>Submission Date</label>
	        <input type="date" name="submissionDate[]" required>
	      </div>
	
	      <div>
	  		<label>Margin %</label>
	  		<input type="number" name="marginPercent[]" step="0.01" min="0" max="100" required>
	</div>
	
	      <div>
	  		<label>Deposit A/c Code</label>
	  		<input type="text" name="depositAccCode[]" inputmode="numeric" pattern="[0-9]{14}" maxlength="14" minlength="14" required
	         oninput="this.value = this.value.replace(/[^0-9]/g, '').slice(0,14);"
	         title="Enter exactly 14 digits" required>
	</div>
	
	      <div>
	        <label>Maturity Date</label>
	        <input type="date" name="maturityDate[]" required>
	      </div>
	
	      <div>
	        <label>Security Value</label>
	        <input type="number" step="0.01" name="securityValue[]" required>
	      </div>
	
	      <div>
	        <label>TD Value</label>
	        <input type="number" step="0.01" name="tdValue[]" value="0" readonly style="background-color: #f0f0f0;">
	      </div>
	
	      <div>
	  		<label>Particular</label>
	  		<input type="text" name="particular[]" maxlength="50" required>
		  </div>
	    </div>
	  </div>
	</fieldset>
	
	  <% } %>
	
	  <!-- Gold Details Fieldset - Conditional -->
	  <% if (showGold) { %>
	<fieldset id="goldSilverFieldset">
	  <legend>
	    Gold/Silver
	    <button type="button" onclick="addGoldSilver()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	
	  <div class="nominee-card goldsilver-block">
	    <button type="button" class="nominee-remove" onclick="removeGoldSilver(this)">✖</button>
	
	    <div class="nominee-title"
	         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
	      Gold/Silver <span class="goldsilver-serial">1</span>
	    </div>
	
	    <div class="form-grid">
	      <div>
	        <label>Security Type Code</label>
	        <select name="gsSecurityType[]" required>
	          <option value="">-- Select Security Type --</option>
	          <%
	            PreparedStatement psSecType = null;
	            ResultSet rsSecType = null;
	            try (Connection connSecType = DBConnection.getConnection()) {
	              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
	              psSecType = connSecType.prepareStatement(sql);
	              rsSecType = psSecType.executeQuery();
	              
	              while (rsSecType.next()) {
	                String securityType = rsSecType.getString("SECURITYTYPE_CODE");
	          %>
	                <option value="<%= securityType %>"><%= securityType %></option>
	          <%
	              }
	            } catch (Exception e) {
	              out.println("<option disabled>Error loading Security Types</option>");
	              e.printStackTrace();
	            } finally {
	              if (rsSecType != null) rsSecType.close();
	              if (psSecType != null) psSecType.close();
	            }
	          %>
	        </select>
	      </div>
	
	      <div>
	        <label>Submission Date</label>
	        <input type="date" name="gsSubmissionDate[]" required>
	      </div>
	
	      <!-- ✅ FIXED: Changed from number to text for GOLDBAGNO (VARCHAR2) -->
	      <div>
	        <label>Gold Bag No.</label>
	        <input type="text" name="gsGoldBagNo[]" maxlength="10" required>
	      </div>
	
	      <div>
	        <label>Total Wt.In Grm</label>
	        <input type="number" step="0.001" name="gsTotalWeight[]" 
	               title="Weight in total grams (up to 3 decimal places)" required>
	      </div>
	
	      <div>
	        <label>Margin %</label>
	        <input type="number" step="0.01" name="gsMargin[]" required>
	      </div>
	
	      <div>
	        <label>Rate/Grams</label>
	        <input type="number" step="0.01" name="gsRatePerGram[]" required>
	      </div>
	
	      <div>
	        <label>Total Value</label>
	        <input type="number" step="0.01" name="gsTotalValue[]"
	               onchange="calculateSecurityValue(this)" required>
	      </div>
	
	      <div>
	        <label>Security Value</label>
	        <input type="number" step="0.01" name="gsSecurityValue[]" readonly 
	               style="background-color: #f0f0f0;">
	      </div>
	
	      <div>
	        <label>Particular</label>
	        <input type="text" name="gsParticular[]" maxlength="100">
	      </div>
	
	      <div class="goldsilver-note-field">
	        <label>Note</label>
	        <textarea name="gsNote[]" rows="2" maxlength="300" style="width: 97%; padding: 8px; 
	                  border: 1px solid #ccc; border-radius: 4px; font-size: 13px;
	                  font-family: Arial, sans-serif;"></textarea>
	      </div>
	    </div>
	  </div>
	</fieldset>
	  <% } %>
	  
	  <!-- Shares Holder Fieldset - Conditional -->
<% if (showSharesHolder) { %>
<fieldset id="sharesHolderFieldset">
  <legend>
    Shares Holder Details
    <button type="button" onclick="addSharesHolder()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card shareholder-block">
    <button type="button" class="nominee-remove" onclick="removeSharesHolder(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Shares Holder <span class="shareholder-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
        <select name="sharesHolderSecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>Holder Name</label>
        <input type="text" name="sharesHolderName[]" required>
      </div>

      <div>
        <label>No. of Shares</label>
        <input type="number" name="sharesHolderNoShares[]" value="0" required>
      </div>

      <div>
        <label>Share Certificate No</label>
        <input type="text" name="sharesHolderCertNo[]" required>
      </div>

      <div>
        <label>Issue Date</label>
        <input type="date" name="sharesHolderIssueDate[]" required>
      </div>

      <div>
        <label>Face Value</label>
        <input type="number" step="0.01" name="sharesHolderFaceValue[]" value="0" required>
      </div>

      <div>
        <label>Margin%</label>
        <input type="number" step="0.01" name="sharesHolderMargin[]" value="0" required>
      </div>

      <div>
        <label>Security Value</label>
        <input type="number" step="0.01" name="sharesHolderSecurityValue[]" value="0" required>
      </div>

      <div>
        <label>Particular</label>
        <textarea name="sharesHolderParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>
	
<!-- Plant & Machinery Fieldset - Conditional -->
<% if (showPlantMachinery) { %>
<fieldset id="plantMachineryFieldset">
  <legend>
    Plant & Machinery Details
    <button type="button" onclick="addPlantMachinery()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card plant-block">
    <button type="button" class="nominee-remove" onclick="removePlantMachinery(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Plant & Machinery <span class="plant-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
        <select name="plantSecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>IsNewEquip(Y/N)</label>
        <select name="plantIsNewEquip[]" required>
          <option value="N" selected>N</option>
          <option value="Y">Y</option>
        </select>
      </div>

      <div>
        <label>Machine Type</label>
        <input type="text" name="plantMachineType[]" required>
      </div>

      <div>
        <label>Machine Name</label>
        <input type="text" name="plantMachineName[]" required>
      </div>

      <div>
        <label>Distinctive No.</label>
        <input type="text" name="plantDistinctiveNo[]" maxlength="20" required>
      </div>

      <div>
        <label>Submission Date</label>
        <input type="date" name="plantSubmissionDate[]" required>
      </div>

      <div>
        <label>Specification</label>
        <input type="text" name="plantSpecification[]" required>
      </div>

      <div>
        <label>Aquisition Date</label>
        <input type="date" name="plantAquisitionDate[]" required>
      </div>

      <div>
        <label>Supplier Name</label>
        <input type="text" name="plantSupplierName[]" required>
      </div>

      <div>
        <label>Purchase Price</label>
        <input type="number" step="0.01" name="plantPurchasePrice[]" value="0" required>
      </div>

      <div>
        <label>Margin%</label>
        <input type="number" step="0.01" name="plantMargin[]" value="0" required>
      </div>

      <div>
        <label>Security Value</label>
        <input type="number" step="0.01" name="plantSecurityValue[]" value="0" required>
      </div>

      <div>
        <label>Particular</label>
        <textarea name="plantParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>
	
	<!-- Vehicle Fieldset - Conditional -->
	<% if (showVehicle) { %>
	<fieldset id="vehicleFieldset">
	  <legend>
	    Vehicle Details
	    <button type="button" onclick="addVehicle()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	  
	  <!-- Add your fields here -->
	  
	</fieldset>
	<% } %>
	
<!-- Market Shares Fieldset - Conditional -->
<% if (showMarketShares) { %>
<fieldset id="marketSharesFieldset">
  <legend>
    Market Shares Details
    <button type="button" onclick="addMarketShares()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card marketshares-block">
    <button type="button" class="nominee-remove" onclick="removeMarketShares(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Market Shares <span class="marketshares-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
		<select name="marketSharesSecurityType[]" id="dd-marketSharesSecurityType" required class="dd-loading">
			<option value="">Loading...</option>
		</select>
      </div>

      <div>
        <label>Company Name</label>
        <input type="text" name="marketSharesCompanyName[]" required>
      </div>

      <div>
        <label>Margin%</label>
        <input type="number" step="0.01" name="marketSharesMargin[]" value="0" required>
      </div>

      <div>
        <label>Submission Date</label>
        <input type="date" name="marketSharesSubmissionDate[]" required>
      </div>

      <div>
        <label>Issue Date</label>
        <input type="date" name="marketSharesIssueDate[]" required>
      </div>

      <div>
        <label>Market Value</label>
        <input type="number" step="0.01" name="marketSharesMarketValue[]" value="0" required>
      </div>

      <div>
        <label>No.of Shares</label>
        <input type="number" name="marketSharesNoOfShares[]" value="0" required>
      </div>

      <div>
        <label>Security Value</label>
        <input type="number" step="0.01" name="marketSharesSecurityValue[]" value="0" required>
      </div>

      <div>
        <label>Particular</label>
        <textarea name="marketSharesParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>
	
<!-- Stock Statement Fieldset - Conditional -->
<% if (showStockStatement) { %>
<fieldset id="stockStatementFieldset">
  <legend>
    Stock Statement Details
    <button type="button" onclick="addStockStatement()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card stock-block">
    <button type="button" class="nominee-remove" onclick="removeStockStatement(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Stock Statement <span class="stock-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
        <select name="stockSecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>Submission Date</label>
        <input type="date" name="stockSubmissionDate[]" required>
      </div>

      <div>
        <label>Statement Date</label>
        <input type="date" name="stockStatementDate[]" required>
      </div>

      <div>
        <label>Raw Mat.Mar.%</label>
        <input type="number" step="0.01" name="stockRawMatMargin[]" value="0" required>
      </div>

      <div>
        <label>WorkInPro.Mar.%</label>
        <input type="number" step="0.01" name="stockWorkInProMargin[]" value="0" required>
      </div>

      <div>
        <label>Fini.Goods.Mar.%</label>
        <input type="number" step="0.01" name="stockFiniGoodsMargin[]" value="0" required>
      </div>

      <div>
        <label>Security Value</label>
        <input type="number" step="0.01" name="stockSecurityValue[]" value="0" required>
      </div>

      <div>
        <label>Particular</label>
        <textarea name="stockParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>
	
	<!-- Furniture & Fixture Fieldset - Conditional -->
	<% if (showFurnitureFixture) { %>
	<fieldset id="furnitureFixtureFieldset">
	  <legend>
	    Furniture & Fixture Details
	    <button type="button" onclick="addFurnitureFixture()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	  
	  <!-- Add your fields here -->
	  
	</fieldset>
	<% } %>
	
	<!-- Stock Pledge Fieldset - Conditional -->
	<% if (showStockPledge) { %>
	<fieldset id="stockPledgeFieldset">
	  <legend>
	    Stock Pledge Details
	    <button type="button" onclick="addStockPledge()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	  
	  <!-- Add your fields here -->
	  
	</fieldset>
	<% } %>
	
	<!-- Book Debts Fieldset - Conditional -->
	<% if (showBookDebts) { %>
	<fieldset id="bookDebtsFieldset">
	  <legend>
	    Book Debts Details
	    <button type="button" onclick="addBookDebts()"
	      style="border:none;background:#373279;color:white;padding:2px 10px;
	        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
	      ➕
	    </button>
	  </legend>
	  
	  <!-- Add your fields here -->
	  
	</fieldset>
	<% } %>
	
<!-- Salary Fieldset - Conditional -->
<% if (showSalary) { %>
<fieldset id="salaryFieldset">
  <legend>
    Salary Details
    <button type="button" onclick="addSalary()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card salary-block">
    <button type="button" class="nominee-remove" onclick="removeSalary(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Salary Details <span class="salary-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
        <select name="salarySecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>Country Code</label>
        <select name="salaryCountry[]" id="dd-salaryCountry" required class="dd-loading">
  			<option value="">Loading...</option>
		</select>
      </div>

      <div>
        <label>Employee Name</label>
        <input type="text" name="salaryEmployeeName[]" required>
      </div>

      <div>
        <label>State Code</label>
        <select name="salaryState[]" id="dd-salaryState" required class="dd-loading">
  			<option value="">Loading...</option>
		</select>
      </div>

      <div>
        <label>Address1</label>
        <input type="text" name="salaryAddress1[]" required>
      </div>

      <div>
        <label>City Code</label>
        <select name="salaryCity[]" id="dd-salaryCity" required class="dd-loading">
  			<option value="">Loading...</option>
		</select>
      </div>

      <div>
        <label>Address2</label>
        <input type="text" name="salaryAddress2[]">
      </div>

      <div>
        <label>Zip Number</label>
        <input type="text" name="salaryZip[]" maxlength="6" pattern="[0-9]{6}" required>
      </div>

      <div>
        <label>Address3</label>
        <input type="text" name="salaryAddress3[]">
      </div>

      <div>
        <label>Gross Salary</label>
        <input type="number" step="0.01" name="salaryGross[]" value="0" required>
      </div>

      <div>
        <label>Phone Number</label>
        <input type="text" name="salaryPhone[]" maxlength="10" pattern="[0-9]{10}" required>
      </div>

      <div>
        <label>Mobile Number</label>
        <input type="text" name="salaryMobile[]" maxlength="10" pattern="[0-9]{10}">
      </div>

      <div>
        <label>Net Salary</label>
        <input type="number" step="0.01" name="salaryNet[]" value="0" required>
      </div>

      <div>
        <label>Pan Number</label>
        <input type="text" name="salaryPan[]" maxlength="10" pattern="[A-Z]{5}[0-9]{4}[A-Z]{1}" required>
      </div>

      <div>
        <label>PF Account Number</label>
        <input type="text" name="salaryPFAccount[]" required>
      </div>

      <div>
        <label>IS Incomer Tax Payee</label>
        <div style="display: flex; gap: 15px;">
          <label><input type="radio" name="salaryIsTaxPayer_1" value="Yes"> Yes</label>
          <label><input type="radio" name="salaryIsTaxPayer_1" value="No" checked> No</label>
        </div>
      </div>

      <div>
        <label>Department</label>
        <input type="text" name="salaryDepartment[]" required>
      </div>

      <div>
        <label>Perticular</label>
        <textarea name="salaryParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>


<!-- Fire Policy Fieldset - Conditional -->
<% if (showFirePolicy) { %>
<fieldset id="firePolicyFieldset">
  <legend>
    Fire Policy Details
    <button type="button" onclick="addFirePolicy()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <!-- Add your fields here -->
  
</fieldset>
<% } %>



<!-- Office Fieldset - Conditional -->
<% if (showOffice) { %>
<fieldset id="officeFieldset">
  <legend>
    Office Details
    <button type="button" onclick="addOffice()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card office-block">
    <button type="button" class="nominee-remove" onclick="removeOffice(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Office Details <span class="office-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
        <select name="officeSecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>IsNewArticle(Y/N)</label>
        <select name="officeIsNewArticle[]" required>
          <option value="N" selected>N</option>
          <option value="Y">Y</option>
        </select>
      </div>

      <div>
        <label>Make serial</label>
        <input type="text" name="officeMakeSerial[]" maxlength="20" required>
      </div>

      <div>
        <label>Make Model</label>
        <input type="text" name="officeMakeModel[]" required>
      </div>

      <div>
        <label>Submission Date</label>
        <input type="date" name="officeSubmissionDate[]" required>
      </div>

      <div>
        <label>Date Of Acquisition</label>
        <input type="date" name="officeAcquisitionDate[]" required>
      </div>

      <div>
        <label>Warrenty Card Number</label>
        <input type="text" name="officeWarrentyCard[]" maxlength="20" required>
      </div>

      <div>
        <label>Purchase Price</label>
        <input type="number" step="0.01" name="officePurchasePrice[]" value="0" required>
      </div>

      <div>
        <label>Margin%</label>
        <input type="number" step="0.01" name="officeMargin[]" value="0" required>
      </div>

      <div>
        <label>Name Of Article</label>
        <input type="text" name="officeArticleName[]" required>
      </div>

      <div>
        <label>Warrenty In Months</label>
        <input type="number" name="officeWarrentyMonths[]" value="0" required>
      </div>

      <div>
        <label>Security Value</label>
        <input type="number" step="0.01" name="officeSecurityValue[]" value="0" required>
      </div>

      <div>
        <label>Supplier Name</label>
        <input type="text" name="officeSupplierName[]" required>
      </div>

      <div>
        <label>Perticular</label>
        <textarea name="officeParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>
	
	<!-- LIC Details Fieldset - Already exists but add fields -->
<% if (showLIC) { %>
<fieldset id="licFieldset">
  <legend>
    Insurance
    <button type="button" onclick="addInsurance()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card insurance-block">
    <button type="button" class="nominee-remove" onclick="removeInsurance(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Insurance <span class="insurance-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Security Type Code</label>
        <select name="insSecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>Insurance Name</label>
        <input type="text" name="insName[]" required>
      </div>

      <div>
        <label>Policy No</label>
        <input type="text" name="insPolicyNo[]" maxlength="20" required>
      </div>

      <div>
        <label>Policy Amount</label>
        <input type="number" step="0.01" name="insPolicyAmount[]" value="0" required>
      </div>

      <div>
        <label>Premium Period</label>
        <select name="insPremiumPeriod[]" required>
          <option value="">-- Select --</option>
          <option value="Monthly">Monthly</option>
          <option value="Quarterly">Quarterly</option>
          <option value="Half-Yearly">Half-Yearly</option>
          <option value="Yearly">Yearly</option>
        </select>
      </div>

      <div>
        <label>Premium Amount</label>
        <input type="number" step="0.01" name="insPremiumAmount[]" value="0" required>
      </div>

      <div>
        <label>Assured Amount</label>
        <input type="number" step="0.01" name="insAssuredAmount[]" value="0" required>
      </div>

      <div>
        <label>Security Value</label>
        <input type="number" step="0.01" name="insSecurityValue[]" value="0" required>
      </div>

      <div>
        <label>Particular</label>
        <textarea name="insParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>

<!-- Motor Insurance Fieldset -->
<% if (showMotorInsurance) { %>
<fieldset id="motorInsuranceFieldset">
  <legend>
    Motor Insurance
    <button type="button" onclick="addMotorInsurance()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card motor-block">
    <button type="button" class="nominee-remove" onclick="removeMotorInsurance(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Motor Insurance <span class="motor-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Type Of Vehicle</label>
        <select name="motorVehicleType[]" required>
          <option value="">-- Select --</option>
          <option value="NOT APPLICABLE">NOT APPLICABLE</option>
          <option value="TWO WHEELER">TWO WHEELER</option>
          <option value="FOUR WHEELER">FOUR WHEELER</option>
          <option value="COMMERCIAL">COMMERCIAL</option>
          <option value="HEAVY VEHICLE">HEAVY VEHICLE</option>
        </select>
      </div>

      <div>
        <label>RTO Location</label>
        <input type="text" name="motorRTOLocation[]" required>
      </div>

      <div>
        <label>Security Type Code</label>
        <select name="motorSecurityType[]" required>
          <option value="">-- Select --</option>
          <%
            PreparedStatement psSecType = null;
            ResultSet rsSecType = null;
            try (Connection connSecType = DBConnection.getConnection()) {
              String sql = "SELECT SECURITYTYPE_CODE FROM GLOBALCONFIG.SECURITYTYPE ORDER BY SECURITYTYPE_CODE";
              psSecType = connSecType.prepareStatement(sql);
              rsSecType = psSecType.executeQuery();
              while (rsSecType.next()) {
                String code = rsSecType.getString("SECURITYTYPE_CODE");
          %>
                <option value="<%= code %>"><%= code %></option>
          <%
              }
            } catch (Exception e) {
              out.println("<option disabled>Error loading Security Types</option>");
            } finally {
              if (rsSecType != null) rsSecType.close();
              if (psSecType != null) psSecType.close();
            }
          %>
        </select>
      </div>

      <div>
        <label>Is New Vehicle(Y/N)</label>
        <select name="motorIsNewVehicle[]">
          <option value="Y">Y</option>
          <option value="N" selected>N</option>
        </select>
      </div>

      <div>
        <label>Is Vehicle Insp(Y/N)</label>
        <select name="motorIsVehicleInsp[]">
          <option value="Y">Y</option>
          <option value="N" selected>N</option>
        </select>
      </div>

      <div>
        <label>Make Model</label>
        <input type="text" name="motorMakeModel[]" maxlength="50" required>
      </div>

      <div>
        <label>Model Year</label>
        <input type="text" name="motorModelYear[]" maxlength="4" pattern="[0-9]{4}" required>
      </div>

      <div>
        <label>CC</label>
        <input type="number" name="motorCC[]" value="0" required>
      </div>

      <div>
        <label>Submission Date</label>
        <input type="date" name="motorSubmissionDate[]" required>
      </div>

      <div>
        <label>Manufacture Date</label>
        <input type="date" name="motorManufactureDate[]" required>
      </div>

      <div>
        <label>Acquisition Date</label>
        <input type="date" name="motorAcquisitionDate[]" required>
      </div>

      <div>
        <label>Registration Date</label>
        <input type="date" name="motorRegistrationDate[]" required>
      </div>

      <div>
        <label>Registration Number</label>
        <input type="text" name="motorRegistrationNo[]" maxlength="20" required>
      </div>

      <div>
        <label>Chasis No.</label>
        <input type="text" name="motorChasisNo[]" maxlength="20" required>
      </div>

      <div>
        <label>Margin%</label>
        <input type="number" step="0.01" name="motorMargin[]" value="0" required>
      </div>

      <div>
        <label>Purchase Price</label>
        <input type="number" step="0.01" name="motorPurchasePrice[]" value="0" required>
      </div>

      <div>
        <label>Supplier Name</label>
        <input type="text" name="motorSupplierName[]" required>
      </div>

      <div>
        <label>Seating Capacity</label>
        <input type="number" name="motorSeatingCapacity[]" value="0" required>
      </div>

      <div>
        <label>Carrying Capacity</label>
        <input type="number" step="0.01" name="motorCarryingCapacity[]" value="0" required>
      </div>

      <div>
        <label>Insurance Deelesed Value</label>
        <input type="number" step="0.01" name="motorInsuranceValue[]" value="0" required>
      </div>

      <div>
        <label>Insurance Name</label>
        <input type="text" name="motorInsuranceName[]" required>
      </div>

      <div>
        <label>No Claim BOU%</label>
        <input type="number" step="0.01" name="motorNoClaimBOU[]" value="0" required>
      </div>

      <div>
        <label>Policy Number</label>
        <input type="text" name="motorPolicyNo[]" maxlength="20" required>
      </div>

      <div>
        <label>Premium Amount</label>
        <input type="number" step="0.01" name="motorPremiumAmount[]" value="0" required>
      </div>

      <div>
        <label>Total Insured Amount</label>
        <input type="number" step="0.01" name="motorTotalInsured[]" value="0" required>
      </div>

      <div>
        <label>Premium Frequency</label>
        <select name="motorPremiumFreq[]" required>
          <option value="">-- Select --</option>
          <option value="Monthly">Monthly</option>
          <option value="Quarterly">Quarterly</option>
          <option value="Half-Yearly">Half-Yearly</option>
          <option value="Yearly">Yearly</option>
        </select>
      </div>

      <div>
        <label>Policy Start Date</label>
        <input type="date" name="motorPolicyStartDate[]" required>
      </div>

      <div>
        <label>Policy End Date</label>
        <input type="date" name="motorPolicyEndDate[]" required>
      </div>

      <div>
        <label>Policy Type</label>
        <input type="text" name="motorPolicyType[]" required>
      </div>

      <div>
        <label>Particular</label>
        <textarea name="motorParticular[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>
    </div>
  </div>
</fieldset>
<% } %>

<!-- Non-Motor Insurance Fieldset -->
<% if (showNonMotorInsurance) { %>
<fieldset id="nonMotorInsuranceFieldset">
  <legend>
    Non-Motor Insurance
    <button type="button" onclick="addNonMotorInsurance()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card nonmotor-block">
    <button type="button" class="nominee-remove" onclick="removeNonMotorInsurance(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Non-Motor Insurance <span class="nonmotor-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Address Of Correspondance</label>
        <textarea name="nonmotorAddress[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>

      <div style="grid-column: span 2;">
        <label>Risk Location</label>
        <textarea name="nonmotorRiskLocation[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>

      <div>
        <label>Pin Code</label>
        <input type="text" name="nonmotorPinCode[]" maxlength="6" pattern="[0-9]{6}">
      </div>

      <div>
        <label>Landmark</label>
        <textarea name="nonmotorLandmark[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>

      <div>
        <label>City</label>
		<select name="nonmotorCity[]" 
		        id="dd-nonmotorCity" required class="dd-loading"><option value="">Loading...</option>
		</select>
      </div>

      <div>
        <label>Policy Start Date</label>
        <input type="date" name="nonmotorPolicyStartDate[]" required>
      </div>

      <div>
        <label>Policy End Date</label>
        <input type="date" name="nonmotorPolicyEndDate[]" required>
      </div>

      <div>
        <label>Village</label>
        <input type="text" name="nonmotorVillage[]" required>
      </div>

      <div>
        <label>Valuation of Property</label>
        <input type="number" step="0.01" name="nonmotorPropertyValuation[]" value="0" required>
      </div>

      <div>
        <label>Name of Insurance Company</label>
        <input type="text" name="nonmotorInsuranceCompany[]" required>
      </div>

      <div>
        <label>Existing Policy Start Date</label>
        <input type="date" name="nonmotorExistingPolicyStart[]" required>
      </div>

      <div>
        <label>Existing Policy End Date</label>
        <input type="date" name="nonmotorExistingPolicyEnd[]" required>
      </div>

      <div>
        <label>Type Of Mortagage</label>
        <input type="text" name="nonmotorMortgageType[]" required>
      </div>

      <div style="grid-column: span 2;">
        <label>Details of Mortagage</label>
        <textarea name="nonmotorMortgageDetails[]" rows="2" style="width: 97%; resize: vertical; font-size: 13px; padding: 4px 6px;"></textarea>
      </div>

      <div>
        <label>Premium Amount</label>
        <input type="number" step="0.01" name="nonmotorPremiumAmount[]" value="0" required>
      </div>

      <div>
        <label>Valuation Of Mortagage</label>
        <input type="number" step="0.01" name="nonmotorMortgageValuation[]" value="0" required>
      </div>
    </div>
  </div>
</fieldset>
<% } %>

<!-- Government Security Fieldset -->
<% if (showGovSecurity) { %>
<fieldset id="govSecurityFieldset">
  <legend>
    Government Security
    <button type="button" onclick="addGovSecurity()"
      style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
      ➕
    </button>
  </legend>
  
  <div class="nominee-card govsec-block">
    <button type="button" class="nominee-remove" onclick="removeGovSecurity(this)">✖</button>

    <div class="nominee-title"
         style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
      Government Security <span class="govsec-serial">1</span>
    </div>

    <div class="form-grid">
      <div>
        <label>Terms</label>
        <input type="text" name="govSecTerms[]" required>
      </div>

      <div>
        <label>Certificate No</label>
        <input type="text" name="govSecCertNo[]" maxlength="20" required>
      </div>

      <div>
        <label>Certificate Date</label>
        <input type="date" name="govSecCertDate[]" required>
      </div>

      <div>
        <label>Maturity Date</label>
        <input type="date" name="govSecMaturityDate[]" required>
      </div>

      <div>
        <label>Maturity Amount</label>
        <input type="number" step="0.01" name="govSecMaturityAmount[]" value="0" required>
      </div>

      <div>
        <label>Certificate Amount</label>
        <input type="number" step="0.01" name="govSecCertAmount[]" value="0" required>
      </div>

      <div>
        <label>Nominee</label>
        <input type="text" name="govSecNominee[]" required>
      </div>

      <div>
        <label>Transferable/Encashable</label>
        <input type="checkbox" name="govSecTransferable[]" value="Y" style="width: auto; height: 20px;">
      </div>
    </div>
  </div>
</fieldset>
<% } %>
	
	
	
	  <div class="form-buttons">
	    <button type="submit">Save</button>
	    <button type="reset">Reset</button>
	  </div>
	</form>
	
	<!-- Customer Lookup Modal -->
	<div id="customerLookupModal" class="customer-modal">
	  <div class="customer-modal-content">
	    <span class="customer-close" onclick="closeCustomerLookup()">&times;</span>
	    <div id="customerLookupContent">
	      <!-- Content will be loaded here -->
	    </div>
	  </div>
	</div>
	
	<!-- INSTALLMENT TYPE LOOKUP MODAL -->
	<div id="installmentLookupModal" class="customer-modal">
	    <div class="customer-modal-content">
	        <span class="customer-close" onclick="closeInstallmentLookup()">&times;</span>
	        <div id="installmentLookupContent"></div>
	    </div>
	</div>
	<!-- SOCIAL SECTOR LOOKUP MODAL -->
	<div id="socialSectorLookupModal" class="customer-modal">
	    <div class="customer-modal-content">
	        <span class="customer-close" onclick="closeSocialSectorLookup()">&times;</span>
	        <div id="socialSectorLookupContent"></div>
	    </div>
	</div>
	
	<!-- SOCIAL SUBSECTOR LOOKUP MODAL -->
	<div id="socialSubSectorLookupModal" class="customer-modal">
	    <div class="customer-modal-content">
	        <span class="customer-close" onclick="closeSocialSubSectorLookup()">&times;</span>
	        <div id="socialSubSectorLookupContent"></div>
	    </div>
	</div>
	<!-- AREA LOOKUP MODAL -->
	<div id="areaLookupModal" class="customer-modal">
	    <div class="customer-modal-content">
	        <span class="customer-close" onclick="closeAreaLookup()">&times;</span>
	        <div id="areaLookupContent"></div>
	    </div>
	</div>
	
	<!-- SUB AREA LOOKUP MODAL -->
	<div id="subAreaLookupModal" class="customer-modal">
	    <div class="customer-modal-content">
	        <span class="customer-close" onclick="closeSubAreaLookup()">&times;</span>
	        <div id="subAreaLookupContent"></div>
	    </div>
	</div>
	<script src="js/application.js"></script>
	<script src="js/savingAcc.js"></script>
	<script src="js/application-tabs.js"></script>
	<script src="js/formDropdownLoader.js"></script>

	<script>
	// Validation function
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
	        
	        // Clear URL parameters after showing toast
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
	        
	        // Clear URL parameters after showing toast
	        setTimeout(function() {
	            const cleanUrl = window.location.pathname + window.location.search.replace(/[?&](status|applicationNumber|message)=[^&]*/g, '').replace(/^&/, '?').replace(/\?$/, '');
	            window.history.replaceState({}, document.title, cleanUrl || window.location.pathname);
	        }, 100);
	    }
	});
	//==================== CUSTOMER LOOKUP FUNCTIONS ====================
	
	//Helper function to set select value with multiple matching strategies
	function setSelectValue(selectElement, value, fieldName) {
	  if (!selectElement) {
	      console.warn('⚠️ Select element not found for:', fieldName);
	      return false;
	  }
	  
	  if (!value || value.trim() === '') {
	      console.log('⚠️ Empty value for:', fieldName);
	      return false;
	  }
	  
	  const trimmedValue = value.trim().toUpperCase();
	  console.log(`🔧 Setting ${fieldName} to: "${trimmedValue}"`);
	  
	  let found = false;
	  
	  // Strategy 1: Try exact match on value (case-insensitive)
	  for (let i = 0; i < selectElement.options.length; i++) {
	      const optionValue = selectElement.options[i].value.trim().toUpperCase();
	      if (optionValue === trimmedValue) {
	          selectElement.selectedIndex = i;
	          found = true;
	          console.log(`✅ ${fieldName} set successfully (exact match) to: "${trimmedValue}"`);
	          return true;
	      }
	  }
	  
	  // Strategy 2: Try matching on text content
	  for (let i = 0; i < selectElement.options.length; i++) {
	      const optionText = selectElement.options[i].text.trim().toUpperCase();
	      if (optionText.includes(trimmedValue) || trimmedValue.includes(optionText)) {
	          selectElement.selectedIndex = i;
	          found = true;
	          console.log(`✅ ${fieldName} set successfully (text match) to: "${selectElement.options[i].value}"`);
	          return true;
	      }
	  }
	  
	  // Strategy 3: Try partial match on value
	  for (let i = 0; i < selectElement.options.length; i++) {
	      const optionValue = selectElement.options[i].value.trim().toUpperCase();
	      if (optionValue.includes(trimmedValue) || trimmedValue.includes(optionValue)) {
	          selectElement.selectedIndex = i;
	          found = true;
	          console.log(`✅ ${fieldName} set successfully (partial match) to: "${selectElement.options[i].value}"`);
	          return true;
	      }
	  }
	  
	  if (!found) {
	      console.warn(`⚠️ Value "${trimmedValue}" not found in ${fieldName} dropdown`);
	  }
	  
	  return found;
	}
	
	//Close modal when clicking outside
	window.onclick = function(event) {
	    const customerModal = document.getElementById('customerLookupModal');
	    const installmentModal = document.getElementById('installmentLookupModal');
	    const socialSectorModal = document.getElementById('socialSectorLookupModal');
	    const socialSubSectorModal = document.getElementById('socialSubSectorLookupModal');
	    const areaModal = document.getElementById('areaLookupModal');
	    const subAreaModal = document.getElementById('subAreaLookupModal');
	    
	    if (event.target === customerModal) closeCustomerLookup();
	    if (event.target === installmentModal) closeInstallmentLookup();
	    if (event.target === socialSectorModal) closeSocialSectorLookup();
	    if (event.target === socialSubSectorModal) closeSocialSubSectorLookup();
	    if (event.target === areaModal) closeAreaLookup();
	    if (event.target === subAreaModal) closeSubAreaLookup();
	}
	
	//Close modal on Escape key
	document.addEventListener('keydown', function(event) {
	    if (event.key === 'Escape') {
	        closeCustomerLookup();
	        closeInstallmentLookup();
	        closeSocialSectorLookup();
	        closeSocialSubSectorLookup();
	        closeAreaLookup();
	        closeSubAreaLookup();
	    }
	});

	
	//==================== LAND & BUILDING FUNCTIONS ====================
	
	function addLandBuilding() {
	  let fieldset = document.getElementById("landBuildingFieldset");
	  let original = fieldset.querySelector(".lb-block");
	  let clone = original.cloneNode(true);
	  
	  clone.querySelectorAll('select[id]').forEach(function(sel) {
	        sel.removeAttribute('id');
	    });
	  
	  // Clear all inputs in cloned block
	  clone.querySelectorAll("input, select, textarea").forEach(el => {
	      if (el.tagName === 'SELECT') {
	          el.selectedIndex = 0;
	      } else if (['lbAmtValued[]', 'lbMargin[]', 'lbArea[]', 'lbSecurityValue[]'].includes(el.name)) {
	          el.value = '0';
	      } else {
	          el.value = "";
	      }
	  });
	
	  clone.querySelector(".nominee-remove").onclick = function() {
	      removeLandBuilding(this);
	  };
	
	  fieldset.appendChild(clone);
	  updateLBSerials();
	}
	
	function removeLandBuilding(btn) {
	  let blocks = document.querySelectorAll(".lb-block");
	  if (blocks.length <= 1) {
		    showToast("⚠️ At least one Land & Building entry is required.", "warning");
		    return;
		}
	  btn.parentNode.remove();
	  updateLBSerials();
	}
	
	function updateLBSerials() {
	  let blocks = document.querySelectorAll(".lb-block");
	  blocks.forEach((block, index) => {
	      let serial = block.querySelector(".lb-serial");
	      if (serial) {
	          serial.textContent = (index + 1);
	      }
	  });
	}
	
	//==================== UTILITY FUNCTIONS ====================
	
	function showToast(message) {
	  if (typeof Toastify !== 'undefined') {
	      Toastify({
	          text: message,
	          duration: 5000,
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
	              marginTop: "20px"
	          }
	      }).showToast();
	  }
	}
	
	//For able and disable Director Related fields
	function toggleDirectorFields() {
	  const isRelated = document.querySelector('input[name="isDirectorRelated"]:checked').value;
	  
	  const idField = document.getElementById('directorId');
	  const nameField = document.getElementById('directorName');
	
	  if (isRelated === 'Y') {
	      idField.disabled = false;
	      nameField.disabled = false;
	  } else {
	      idField.disabled = true;
	      nameField.disabled = true;
	      idField.value = "0";
	      nameField.value = "";
	  }
	}
	
	//Call once on page load to apply initial state
	document.addEventListener('DOMContentLoaded', function() {
	  if (document.querySelector('input[name="isDirectorRelated"]')) {
	      toggleDirectorFields();
	  }
	});
	
	function calcReviewDate() {
	    const sanctionVal = document.getElementById('sanctionDate').value;
	    const months = parseInt(document.getElementById('loanPeriod').value, 10);
	
	    // Need both fields
	    if (!sanctionVal || isNaN(months) || months <= 0) {
	      document.getElementById('reviewDate').value = '';
	      return;
	    }
	
	    // Start from selected sanction date
	    const d = new Date(sanctionVal);   // sanctionVal is "YYYY-MM-DD"
	    d.setMonth(d.getMonth() + months); // add months
	
	    const yyyy = d.getFullYear();
	    const mm = String(d.getMonth() + 1).padStart(2, '0');
	    const dd = String(d.getDate()).padStart(2, '0');
	    const reviewStr = yyyy + '-' + mm + '-' + dd;
	
	    document.getElementById('reviewDate').value = reviewStr;
	  }
	
	  // Recalculate whenever sanction date or loan period changes
	  window.onload = function () {
	    document.getElementById('sanctionDate').addEventListener('change', calcReviewDate);
	    document.getElementById('loanPeriod').addEventListener('input', calcReviewDate);
	  };
	  
	  
	//✅ Monitor Application Customer ID changes
	  document.addEventListener('DOMContentLoaded', function() {
	      const customerIdField = document.getElementById('customerId');
	      if (customerIdField) {
	          // Store initial value
	          let previousValue = customerIdField.value;
	          
	          // Watch for changes (in case of manual clear/reset)
	          customerIdField.addEventListener('change', function() {
	              const newValue = this.value.trim();
	              if (previousValue && !newValue) {
	                  // Customer ID was cleared
	                  console.log('Application customer cleared');
	              }
	              previousValue = newValue;
	          });
	      }
	  });
	
	//==================== GOLD/SILVER SECURITY FUNCTIONS ====================
	
	  function addGoldSilver() {
	    let fieldset = document.getElementById("goldSilverFieldset");
	    let original = fieldset.querySelector(".goldsilver-block");
	    let clone = original.cloneNode(true);
	
	    clone.querySelectorAll('select[id]').forEach(function(sel) {
	        sel.removeAttribute('id');
	    });
	    
	    // Clear all input fields
	    clone.querySelectorAll("input, select, textarea").forEach(el => {
	      if (el.tagName === 'SELECT') {
	        el.selectedIndex = 0;
	      } else if (el.name === 'gsSerialNo[]') {
	        // Keep readonly, will be updated by updateGoldSilverSerials
	      } else if (el.name === 'gsTotalWeight[]' || el.name === 'gsMargin[]' || 
	                 el.name === 'gsRatePerGram[]' || el.name === 'gsTotalValue[]' || 
	                 el.name === 'gsSecurityValue[]' || el.name === 'gsGoldBagNo[]') {
	        el.value = '0';
	      } else {
	        el.value = "";
	      }
	    });
	
	    clone.querySelector(".nominee-remove").onclick = function() {
	      removeGoldSilver(this);
	    };
	
	    fieldset.appendChild(clone);
	    updateGoldSilverSerials();
	  }
	
	  function removeGoldSilver(btn) {
	    let blocks = document.querySelectorAll(".goldsilver-block");
	    if (blocks.length <= 1) {
	  	    showToast("⚠️ At least one gold/silver entry is required.", "warning");
	  	    return;
	  	}
	    btn.parentNode.remove();
	    updateGoldSilverSerials();
	  }
	
	  function updateGoldSilverSerials() {
	    let blocks = document.querySelectorAll(".goldsilver-block");
	    blocks.forEach((block, index) => {
	      let serial = block.querySelector(".goldsilver-serial");
	      if (serial) {
	        serial.textContent = (index + 1);
	      }
	      
	      // Update Sr No input
	      let srNoInput = block.querySelector('input[name="gsSerialNo[]"]');
	      if (srNoInput) {
	        srNoInput.value = (index + 1);
	      }
	    });
	  }
	
	  // Calculate Security Value based on Total Value and Margin
	  function calculateSecurityValue(totalValueInput) {
	    const block = totalValueInput.closest('.goldsilver-block');
	    const totalValue = parseFloat(totalValueInput.value) || 0;
	    const marginInput = block.querySelector('input[name="gsMargin[]"]');
	    const securityValueInput = block.querySelector('input[name="gsSecurityValue[]"]');
	    
	    const margin = parseFloat(marginInput.value) || 0;
	    
	    // Security Value = Total Value - (Total Value * Margin / 100)
	    const securityValue = totalValue - (totalValue * margin / 100);
	    
	    securityValueInput.value = securityValue.toFixed(2);
	  }
	
	  // Auto-calculate when margin changes
	  document.addEventListener('DOMContentLoaded', function() {
	    document.addEventListener('input', function(e) {
	      if (e.target.name === 'gsMargin[]') {
	        const block = e.target.closest('.goldsilver-block');
	        const totalValueInput = block.querySelector('input[name="gsTotalValue[]"]');
	        if (totalValueInput) {
	          calculateSecurityValue(totalValueInput);
	        }
	      }
	    });
	  });
	  
	  function addDepositDetails() {
		  let fieldset = document.getElementById("depositDetailsFieldset");
		  let original = fieldset.querySelector(".deposit-block");
		  let clone = original.cloneNode(true);
	
		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  // Clear all inputs in the cloned block
		  clone.querySelectorAll("input, select").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (el.name === 'depositSrNo[]') {
		      // Sr No will be updated by updateDepositSerials()
		      el.value = '';
		    } else if (el.name === 'marginPercent[]' || el.name === 'securityValue[]' || el.name === 'tdValue[]') {
		      el.value = '0';
		    } else {
		      el.value = '';
		    }
		  });
	
		  // Update remove button onclick
		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeDepositDetails(this);
		  };
	
		  fieldset.appendChild(clone);
		  updateDepositSerials();
		  
		  // Auto-calculate TD Value for new block
		  setupTDValueCalculation(clone);
		}
	
		function removeDepositDetails(btn) {
		  let blocks = document.querySelectorAll(".deposit-block");
		  if (blocks.length <= 1) {
			    showToast("⚠️ At least one deposit detail is required.", "warning");
			    return;
			}
		  btn.parentNode.remove();
		  updateDepositSerials();
		}
	
		function updateDepositSerials() {
		  let blocks = document.querySelectorAll(".deposit-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".deposit-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		    
		    // Update Sr No input
		    let srNoInput = block.querySelector('input[name="depositSrNo[]"]');
		    if (srNoInput) {
		      srNoInput.value = (index + 1);
		    }
		  });
		}
	
		// Auto-calculate TD Value based on Security Value and Margin %
		function calculateTDValue(block) {
		  const securityValue = parseFloat(block.querySelector('input[name="securityValue[]"]').value) || 0;
		  const marginPercent = parseFloat(block.querySelector('input[name="marginPercent[]"]').value) || 0;
		  const tdValueInput = block.querySelector('input[name="tdValue[]"]');
		  
		  // TD Value = Security Value × (Margin % / 100)
		  const tdValue = securityValue * (marginPercent / 100);
		  tdValueInput.value = tdValue.toFixed(2);
		}
	
		function setupTDValueCalculation(block) {
		  const securityValueInput = block.querySelector('input[name="securityValue[]"]');
		  const marginPercentInput = block.querySelector('input[name="marginPercent[]"]');
		  
		  securityValueInput.addEventListener('input', () => calculateTDValue(block));
		  marginPercentInput.addEventListener('input', () => calculateTDValue(block));
		}
	
		// Initialize TD Value calculation for the first deposit block on page load
		document.addEventListener('DOMContentLoaded', function() {
		  const firstDepositBlock = document.querySelector('.deposit-block');
		  if (firstDepositBlock) {
		    setupTDValueCalculation(firstDepositBlock);
		  }
		});
		
		//==================== INSURANCE FUNCTIONS ====================
		function addInsurance() {
		  let fieldset = document.getElementById("licFieldset");
		  let original = fieldset.querySelector(".insurance-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['insPolicyAmount[]', 'insPremiumAmount[]', 'insAssuredAmount[]', 'insSecurityValue[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeInsurance(this);
		  };

		  fieldset.appendChild(clone);
		  updateInsuranceSerials();
		}

		function removeInsurance(btn) {
		  let blocks = document.querySelectorAll(".insurance-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one insurance entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateInsuranceSerials();
		}

		function updateInsuranceSerials() {
		  let blocks = document.querySelectorAll(".insurance-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".insurance-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== MOTOR INSURANCE FUNCTIONS ====================
		function addMotorInsurance() {
		  let fieldset = document.getElementById("motorInsuranceFieldset");
		  let original = fieldset.querySelector(".motor-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['motorCC[]', 'motorMargin[]', 'motorPurchasePrice[]', 'motorSeatingCapacity[]', 
		                'motorCarryingCapacity[]', 'motorInsuranceValue[]', 'motorNoClaimBOU[]', 
		                'motorPremiumAmount[]', 'motorTotalInsured[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeMotorInsurance(this);
		  };

		  fieldset.appendChild(clone);
		  updateMotorSerials();
		}

		function removeMotorInsurance(btn) {
		  let blocks = document.querySelectorAll(".motor-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one motor insurance entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateMotorSerials();
		}

		function updateMotorSerials() {
		  let blocks = document.querySelectorAll(".motor-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".motor-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== NON-MOTOR INSURANCE FUNCTIONS ====================
		function addNonMotorInsurance() {
		  let fieldset = document.getElementById("nonMotorInsuranceFieldset");
		  let original = fieldset.querySelector(".nonmotor-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['nonmotorPropertyValuation[]', 'nonmotorPremiumAmount[]', 'nonmotorMortgageValuation[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeNonMotorInsurance(this);
		  };

		  fieldset.appendChild(clone);
		  updateNonMotorSerials();
		}

		function removeNonMotorInsurance(btn) {
		  let blocks = document.querySelectorAll(".nonmotor-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one non-motor insurance entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateNonMotorSerials();
		}

		function updateNonMotorSerials() {
		  let blocks = document.querySelectorAll(".nonmotor-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".nonmotor-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== GOVERNMENT SECURITY FUNCTIONS ====================
		function addGovSecurity() {
		  let fieldset = document.getElementById("govSecurityFieldset");
		  let original = fieldset.querySelector(".govsec-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.type === 'checkbox') {
		      el.checked = false;
		    } else if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['govSecMaturityAmount[]', 'govSecCertAmount[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeGovSecurity(this);
		  };

		  fieldset.appendChild(clone);
		  updateGovSecSerials();
		}

		function removeGovSecurity(btn) {
		  let blocks = document.querySelectorAll(".govsec-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one government security entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateGovSecSerials();
		}

		function updateGovSecSerials() {
		  let blocks = document.querySelectorAll(".govsec-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".govsec-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}
		
		
		//==================== OFFICE DETAILS FUNCTIONS ====================
		function addOffice() {
		  let fieldset = document.getElementById("officeFieldset");
		  let original = fieldset.querySelector(".office-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['officePurchasePrice[]', 'officeMargin[]', 'officeSecurityValue[]', 'officeWarrentyMonths[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeOffice(this);
		  };

		  fieldset.appendChild(clone);
		  updateOfficeSerials();
		}

		function removeOffice(btn) {
		  let blocks = document.querySelectorAll(".office-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one office detail is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateOfficeSerials();
		}

		function updateOfficeSerials() {
		  let blocks = document.querySelectorAll(".office-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".office-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== PLANT & MACHINERY FUNCTIONS ====================
		function addPlantMachinery() {
		  let fieldset = document.getElementById("plantMachineryFieldset");
		  let original = fieldset.querySelector(".plant-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['plantPurchasePrice[]', 'plantMargin[]', 'plantSecurityValue[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removePlantMachinery(this);
		  };

		  fieldset.appendChild(clone);
		  updatePlantSerials();
		}

		function removePlantMachinery(btn) {
		  let blocks = document.querySelectorAll(".plant-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one plant & machinery entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updatePlantSerials();
		}

		function updatePlantSerials() {
		  let blocks = document.querySelectorAll(".plant-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".plant-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== SALARY FUNCTIONS ====================
		function addSalary() {
		  let fieldset = document.getElementById("salaryFieldset");
		  let original = fieldset.querySelector(".salary-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  // Get the current count to create unique radio button names
		  let blockCount = document.querySelectorAll(".salary-block").length + 1;
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.type === 'radio') {
		      // Update radio button name to be unique for this block
		      el.name = 'salaryIsTaxPayer_' + blockCount;
		      el.checked = el.value === 'No';
		    } else if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['salaryGross[]', 'salaryNet[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeSalary(this);
		  };

		  fieldset.appendChild(clone);
		  updateSalarySerials();
		}

		function removeSalary(btn) {
		  let blocks = document.querySelectorAll(".salary-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one salary detail is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateSalarySerials();
		}

		function updateSalarySerials() {
		  let blocks = document.querySelectorAll(".salary-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".salary-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== SHARES HOLDER FUNCTIONS ====================
		function addSharesHolder() {
		  let fieldset = document.getElementById("sharesHolderFieldset");
		  let original = fieldset.querySelector(".shareholder-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['sharesHolderNoShares[]', 'sharesHolderFaceValue[]', 'sharesHolderMargin[]', 'sharesHolderSecurityValue[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeSharesHolder(this);
		  };

		  fieldset.appendChild(clone);
		  updateSharesHolderSerials();
		}

		function removeSharesHolder(btn) {
		  let blocks = document.querySelectorAll(".shareholder-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one shares holder entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateSharesHolderSerials();
		}

		function updateSharesHolderSerials() {
		  let blocks = document.querySelectorAll(".shareholder-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".shareholder-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}

		//==================== MARKET SHARES FUNCTIONS ====================
		function addMarketShares() {
		  let fieldset = document.getElementById("marketSharesFieldset");
		  let original = fieldset.querySelector(".marketshares-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['marketSharesMargin[]', 'marketSharesMarketValue[]', 'marketSharesNoOfShares[]', 'marketSharesSecurityValue[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeMarketShares(this);
		  };

		  fieldset.appendChild(clone);
		  updateMarketSharesSerials();
		}

		function removeMarketShares(btn) {
		  let blocks = document.querySelectorAll(".marketshares-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one market shares entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateMarketSharesSerials();
		}

		function updateMarketSharesSerials() {
		  let blocks = document.querySelectorAll(".marketshares-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".marketshares-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}
		
		//==================== STOCK STATEMENT FUNCTIONS ====================
		function addStockStatement() {
		  let fieldset = document.getElementById("stockStatementFieldset");
		  let original = fieldset.querySelector(".stock-block");
		  let clone = original.cloneNode(true);

		  clone.querySelectorAll('select[id]').forEach(function(sel) {
		        sel.removeAttribute('id');
		    });
		  
		  clone.querySelectorAll("input, select, textarea").forEach(el => {
		    if (el.tagName === 'SELECT') {
		      el.selectedIndex = 0;
		    } else if (['stockRawMatMargin[]', 'stockWorkInProMargin[]', 'stockFiniGoodsMargin[]', 'stockSecurityValue[]'].includes(el.name)) {
		      el.value = '0';
		    } else {
		      el.value = "";
		    }
		  });

		  clone.querySelector(".nominee-remove").onclick = function() {
		    removeStockStatement(this);
		  };

		  fieldset.appendChild(clone);
		  updateStockSerials();
		}

		function removeStockStatement(btn) {
		  let blocks = document.querySelectorAll(".stock-block");
		  if (blocks.length <= 1) {
		    showToast("⚠️ At least one stock statement entry is required.", "warning");
		    return;
		  }
		  btn.parentNode.remove();
		  updateStockSerials();
		}

		function updateStockSerials() {
		  let blocks = document.querySelectorAll(".stock-block");
		  blocks.forEach((block, index) => {
		    let serial = block.querySelector(".stock-serial");
		    if (serial) {
		      serial.textContent = (index + 1);
		    }
		  });
		}
	
	  
	console.log('Product Code: <%= productCode %>');
	console.log('Show Nominee: <%= showNominee %>');
	console.log('Show Joint Holder: <%= showJointHolder %>');
	console.log('Show Guarantor: <%= showGuarantor %>');
	console.log('Show Land & Building: <%= showLandBuilding %>');
	console.log('Show Deposit: <%= showDeposit %>');
	console.log('Show Gold: <%= showGold %>');
	console.log('Show Shares Holder: <%= showSharesHolder %>');
	console.log('Show Plant & Machinery: <%= showPlantMachinery %>');
	console.log('Show Vehicle: <%= showVehicle %>');
	console.log('Show Market Shares: <%= showMarketShares %>');
	console.log('Show Stock Statement: <%= showStockStatement %>');
	console.log('Show Furniture & Fixture: <%= showFurnitureFixture %>');
	console.log('Show Stock Pledge: <%= showStockPledge %>');
	console.log('Show Book Debts: <%= showBookDebts %>');
	console.log('Show Salary: <%= showSalary %>');
	console.log('Show LIC: <%= showLIC %>');                    
	console.log('Show Fire Policy: <%= showFirePolicy %>');     
	console.log('Show Office: <%= showOffice %>');
	console.log('Show Prinodv: <%= showPrinodv %>');
	console.log('Show Motor Insurance: <%= showMotorInsurance %>');
	console.log('Show Non-Motor Insurance: <%= showNonMotorInsurance %>');
	console.log('Show Gov Security: <%= showGovSecurity %>');
	</script>
<script>
  document.addEventListener('DOMContentLoaded', function () {
      var ctx = '<%= request.getContextPath() %>';
      loadAccountFormDropdowns(ctx);
  });
</script>
	</body>
	</html>