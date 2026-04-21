<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String branchCode = (String) sess.getAttribute("branchCode");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Transaction Type Selection</title>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
    <link rel="stylesheet" href="css/transactions.css">
    <style>
        /* ===== CHEQUE FIELDS STYLES ===== */
        .cheque-fields-row {
            display: none; /* hidden by default */
            align-items: flex-end;
            gap: 20px;
            margin-top: 10px;
            flex-wrap: wrap;
            animation: fadeIn 0.3s ease;
        }

        .cheque-fields-row.active {
            display: flex;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-6px); }
            to   { opacity: 1; transform: translateY(0); }
        }



        .cheque-fields-row select,
        .cheque-fields-row input[type="date"] {
            padding: 8px 10px;
            border: 2px solid #C8B7F6;
            border-radius: 8px;
            color: #3D316F;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            outline: none;
            transition: all 0.3s ease;
            min-width: 140px;
        }


        .cheque-fields-row .cheque-badge {
            background: #f9a825;
            color: white;
            font-size: 11px;
            font-weight: bold;
            padding: 2px 8px;
            border-radius: 10px;
            letter-spacing: 0.5px;
        }

        .cheque-section-title {
            width: 100%;
            font-size: 13px;
            font-weight: bold;
            color: #7B5800;
            margin-bottom: 2px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Loading state for cheque dropdowns */
        .cheque-loading {
            font-size: 12px;
            color: #999;
            font-style: italic;
            padding: 8px 10px;
        }
    </style>
<script>
    // Store working date from session
    const workingDate = '<%= sess.getAttribute("workingDate") != null ? 
        new java.text.SimpleDateFormat("dd/MM/yyyy").format((java.util.Date)sess.getAttribute("workingDate")) : 
        new java.text.SimpleDateFormat("dd/MM/yyyy").format(new java.util.Date()) %>';
</script>
   
</head>
<body>
<div class="container">
    <form id="transactionForm" method="post" target="resultFrame">
        <div class="card">

            <fieldset>
                <legend>Transaction Details</legend>

                <!-- All Radio Button Groups in One Line -->
                <div style="display:flex; align-items:center; justify-content:flex-start; gap:30px;">
				<div class="radio-row">
                    <!-- Transaction Type -->
                    <div class="radio-group-inline">
                        <div class="label">Transaction Type:</div>
                        <div class="radio-buttons">
                            <label class="radio-label">
                                <input type="radio" name="transactionTypeRadio" value="regular" checked>
                                <span>Regular</span>
                            </label>
                            <label class="radio-label">
                                <input type="radio" name="transactionTypeRadio" value="closing">
                                <span>Closing</span>
                            </label>
                        </div>
                    </div>

                    <!-- Operation Type -->
                    <div class="radio-group-inline">
                        <div class="label">Operation Type:</div>
                        <div class="radio-buttons">
                            <label class="radio-label">
                                <input type="radio" name="operationType" value="deposit" checked>
                                <span>Deposit</span>
                            </label>
                            <label class="radio-label">
                                <input type="radio" name="operationType" value="withdrawal">
                                <span>Withdrawal</span>
                            </label>
                            <label class="radio-label">
                                <input type="radio" name="operationType" value="transfer">
                                <span>Transfer</span>
                            </label>
                        </div>
                    </div>

                </div>
							
			<!-- TRANSFER SPECIFIC FIELDS (Hidden by default) -->
			<div id="transferFieldsSection" class="transfer-fields-section">
			    <div class="transfer-field-group">
			        <!-- OP Type Dropdown -->
			        <div class="op-type-inline">
			            <label for="opType">OP Type:</label>
			            <select id="opType" name="opType">
			                <option value="Debit" selected>DEBIT</option>
			                <option value="Credit">CREDIT</option>
			            </select>
			        </div>
			        
			        <!-- Totals -->
			        <div class="totals-row">
			            <span class="total-label">Total Debit:</span>
			            <input type="text" id="totalDebit" readonly>
			        </div>
			        
			        <div class="totals-row">
			            <span class="total-label">Total Credit:</span>
			            <input type="text" id="totalCredit" readonly>
			        </div>
			        
			        <!-- Tallied Message -->
			        <div id="talliedMessage" style="display: none; color: green; font-weight: bold; font-size: 15px;">
			            ✓ Transaction tallied
			        </div>
			    </div>
			</div>

                </div>

                <!-- Account Code and Name Row -->
				<div class="row">	
				<!-- Account Category Dropdown -->
				<div class="dropdown-inline">
				<div>
				    <div class="label">Account Type</div>
				    <select name="accountCategory" id="accountCategory" style="min-width: 100px;">
				        <option value="saving" selected>Saving</option>
				        <option value="loan">Loan</option>
				        <option value="deposit">Deposit</option>
				        <option value="pigmy">Pigmy</option>
				        <option value="current">Current</option>
				        <option value="cc">CC</option>
				        <option value="other">Other</option>
				    </select>
				</div>	</div>	
				    <!-- Account Code -->
				    <div>
				        <div class="label" id="accountCodeLabel">Account Code</div>
				        <div class="input-box">
				            <input type="text" name="accountCode" id="accountCode" placeholder="Enter account code" maxlength="14" autocomplete="off">
				            <button type="button" class="icon-btn" id="accountLookupBtn" onclick="openLookup('account')">…</button>
				        </div>
				        <div class="search-hint">Type last 7 digits to search</div>
				        
				        <!-- LIVE SEARCH DROPDOWN -->
				        <div class="search-dropdown">
				            <div class="search-results" id="searchResults"></div>
				        </div>
				    </div>
				
				    <div>
				        <div class="label" id="accountNameLabel">Account Name</div>
				        <input type="text" name="accountName" id="accountName" placeholder="Account Name" style="width: 220px;" readonly>
				    </div>
				    <div>
					    <div class="label" id="transactionamountLabel">Transaction Amount</div>
					    <input type="text" name="transactionamount" id="transactionamount" placeholder="Enter Transaction Amount" oninput="calculateNewBalanceInIframe()">
					</div>
					<div>
					    <div class="label">Particular</div>
					    <textarea name="particular" id="particular" placeholder="Enter particular details" style="width: 250px; height: 40px; padding: 10px; border: 2px solid #C8B7F6; border-radius: 8px; background-color: #F4EDFF; resize: vertical;" required></textarea>
					</div>
					
					<div class="save-button-container">
					    <button type="button" class="add-btn" onclick="addTransactionRow()">+</button>
					</div>
				    <div class="save-button-container">
					    <button type="button" class="save-btn" onclick="handleSaveTransaction()">Save</button>
				</div>

				</div>

                <!-- ========================================== -->
                <!-- CHEQUE FIELDS ROW (Shown only on Withdrawal) -->
                <!-- ========================================== -->
				<div class="cheque-fields-row" id="chequeFieldsRow">
				
								    <!-- Cheque Type (CHEQUETYPE_CODE) -->
				    <div>
				        <div class="label">Cheque Type</div>
				        <select id="chequeType" name="chequeType">
				            <option value="">Select Cheque Type</option>
				        </select>
				    </div>
				    
				    <!-- Cheque Series -->
				    <div>
				        <div class="label">Cheque Series</div>
				        <select id="chequeSeries" name="chequeSeries">
				            <option value="">Select Cheque Series</option>
				        </select>
				    </div>
				
				
				    <!-- Cheque No (CHEQUE_NUMBER) -->
				    <div>
				        <div class="label">Cheque No</div>
				        <select id="chequeNo" name="chequeNo">
				            <option value="">Select Cheque No</option>
				        </select>
				    </div>
				
				    <!-- Cheque Date -->
				    <div>
				        <div class="label">Cheque Date</div>
				        <input type="date" id="chequeDate" name="chequeDate">
				    </div>
				</div>
				
				
				
				
				<!-- LOAN SPECIFIC FIELDS (Hidden by default) -->
				<div id="loanFieldsSection" class="loan-fields-section">    
				    <div id="loanFieldsLoader" style="text-align: center; padding: 20px;">
				        <div class="loading-spinner"></div>
				        <div style="margin-top: 10px; color: #8066E8;">Loading loan fields...</div>
				    </div>
				    <div id="loanFieldsTableContainer" style="display: none;">
				        <table class="compact-loan-table" id="loanFieldsTable">
				            <thead id="loanTableHeader">
				                <!-- Headers will be dynamically generated -->
				            </thead>
				            <tbody id="loanTableBody">
				                <!-- Rows will be dynamically generated -->
				            </tbody>
				        </table>
				    </div>
				    
				</div>
				
				<!-- CLOSING SPECIFIC FIELDS (Hidden by default) -->
				<div id="closingFieldsSection" class="loan-fields-section">    
				    <div id="closingFieldsLoader" style="text-align: center; padding: 20px;">
				        <div class="loading-spinner"></div>
				        <div style="margin-top: 10px; color: #8066E8;">Loading closing fields...</div>
				    </div>
				    <div id="closingFieldsTableContainer" style="display: none;">
				        <table class="compact-loan-table" id="closingFieldsTable">
				            <thead id="closingTableHeader">
				                <!-- Headers will be dynamically generated -->
				            </thead>
				            <tbody id="closingTableBody">
				                <!-- Rows will be dynamically generated -->
				            </tbody>
				        </table>
				    </div>
				</div>
				
				<div id="creditAccountsContainer"></div>
				
				
				
            </fieldset>

        </div>
    </form>

    <!-- IFRAME for loading dynamic pages -->
    <iframe id="resultFrame" name="resultFrame"
            style="width:100%; height:800px; border:1px solid #ccc; margin-top:20px;">
    </iframe>

</div>
<!-- Success Modal -->
<div id="authorizationModal" style="
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    justify-content: center;
    align-items: center;
    z-index: 10000;
">
    <div style="
        background: white;
        width: 500px;
        padding: 40px;
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        text-align: center;
    ">
        <div style="
            color: #2ecc71;
            font-size: 48px;
            margin-bottom: 20px;
        ">✓</div>
        
        <div id="authMessage" style="
            font-size: 20px;
            font-weight: bold;
            color: #333;
            margin-bottom: 15px;
        ">
            Transaction saved successfully!
        </div>
        
        <div id="authScrollNumber" style="
            font-size: 25px;
            color: #666;
            margin-bottom: 30px;
            font-weight: bold;
        ">
            Scroll Number: 12345
        </div>
        
        <!-- ADD THESE TWO BUTTONS -->
        <div style="display: flex; gap: 10px; justify-content: center;">
            <button onclick="showVoucherPopup()" style="
                background: #3498db;
                color: white;
                border: none;
                padding: 12px 50px;
                border-radius: 6px;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
                transition: background 0.3s;
            " onmouseover="this.style.background='#2980b9'" 
               onmouseout="this.style.background='#3498db'">
                Voucher
            </button>
            
            <button onclick="closeAuthorizationModal()" style="
                background: #2ecc71;
                color: white;
                border: none;
                padding: 12px 50px;
                border-radius: 6px;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
                transition: background 0.3s;
            " onmouseover="this.style.background='#27ae60'" 
               onmouseout="this.style.background='#2ecc71'">
                OK
            </button>
        </div>
    </div>
</div>



<!-- Validation Error Modal -->
<div id="validationErrorModal" style="
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.5);
    justify-content: center;
    align-items: center;
    z-index: 10001;
">
    <div style="
        background: white;
        width: 480px;
        padding: 40px;
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        text-align: center;
    ">
        <div style="color: #e53935; font-size: 48px; margin-bottom: 20px;">✕</div>
        <div id="validationErrorMessage" style="
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 30px;
            line-height: 1.5;
        "></div>
        <button onclick="closeValidationErrorModal()" style="
            background: #e53935;
            color: white;
            border: none;
            padding: 12px 50px;
            border-radius: 6px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.3s;
        " onmouseover="this.style.background='#c62828'"
           onmouseout="this.style.background='#e53935'">
            OK
        </button>
    </div>
</div>

<!-- SINGLE LOOKUP MODAL -->
<div id="lookupModal" style="
    display:none; 
    position:fixed; 
    top:0; left:0; width:100%; height:100%;
    background:rgba(0,0,0,0.5); 
    justify-content:center; 
    align-items:center;
    z-index:9999;
">
    <div style="background:white; width:80%; max-height:80%; overflow:auto; padding:20px; border-radius:6px;">
        <button onclick="closeLookup()" style="float:right; cursor:pointer; background:#f44336; color:white; border:none; padding:8px 12px; border-radius:4px; font-size:16px;">✖</button>
        <div id="lookupContent"></div>
    </div>
</div>

<!-- Voucher Modal -->
<div id="voucherModal" style="
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    justify-content: center;
    align-items: center;
    z-index: 10001;
    overflow: auto;
">
    <div style="
        background: white;
        width: 90%;
        max-width: 1200px;
        padding: 30px;
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        margin: 20px auto;
    ">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <h2 style="margin: 0; color: #333; font-size: 20px;">Transaction Voucher</h2>
            <button onclick="closeVoucherModal()" style="
                background: #e74c3c;
                color: white;
                border: none;
                padding: 8px 15px;
                border-radius: 4px;
                cursor: pointer;
                font-size: 14px;
                font-weight: bold;
            ">Close</button>
        </div>
        
        <div id="voucherTableContainer" style="overflow-x: auto;">
            <!-- Table will be loaded here -->
        </div>
    </div>
</div>

    <script src="js/transactions.js"></script>
</body>
</html>
