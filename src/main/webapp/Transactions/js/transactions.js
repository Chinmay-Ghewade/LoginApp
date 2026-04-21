//========== CONFIGURATION ==========
const MIN_SEARCH_LENGTH = 3;
const SEARCH_DELAY = 300;
let searchTimeout;
let currentCategory = 'saving';
let previousAccountCode = '';

// ========== CHEQUE DATA STORE ==========
// Holds all cheque records fetched from server for the current account
let allChequeData = [];

// ========== TOAST UTILITY ==========
function showToast(message, type = 'error') {
    const styles = {
        success: { borderColor: '#4caf50', icon: '✅' },
        error: { borderColor: '#f44336', icon: '❌' },
        warning: { borderColor: '#ff9800', icon: '⚠️' },
        info: { borderColor: '#2196F3', icon: 'ℹ️' }
    };
    const style = styles[type] || styles.error;
    Toastify({
        text: style.icon + ' ' + message,
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
            borderLeft: "5px solid " + style.borderColor,
            marginTop: "20px"
        }
    }).showToast();
}

// ========== CLEAR IFRAME CONTENT ==========
function clearIframe() {
    const iframe = document.getElementById('resultFrame');
    if (iframe) {
        iframe.src = 'about:blank';
    }
}

// ========== ACCOUNT CODE INPUT - DIGITS ONLY ==========
const accountCodeInput = document.getElementById('accountCode');

accountCodeInput.addEventListener('input', function(e) {
    const currentValue = this.value.replace(/\D/g, '');
    this.value = currentValue;
    
    if (currentValue !== previousAccountCode) {
        document.getElementById('accountName').value = '';
        previousAccountCode = currentValue;
    }
    
    //  Clear loan fields when account code is cleared
    if (currentValue === '' || currentValue.length === 0) {
        const accountCategory = document.getElementById('accountCategory').value;
        if (accountCategory === 'loan' || accountCategory === 'cc') {
            clearLoanFields();
            resetLoanReceivedFields();
        }
        // Clear cheque fields when account is cleared
        clearChequeFields();
    }
    
    handleLiveSearch(currentValue);
});

accountCodeInput.addEventListener('keydown', function(e) {
    if ([8, 9, 27, 13, 46].indexOf(e.keyCode) !== -1 ||
        (e.keyCode === 65 && e.ctrlKey === true) ||
        (e.keyCode === 67 && e.ctrlKey === true) ||
        (e.keyCode === 86 && e.ctrlKey === true) ||
        (e.keyCode === 88 && e.ctrlKey === true) ||
        (e.keyCode >= 35 && e.keyCode <= 39)) {
        return;
    }
    if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
        e.preventDefault();
    }
});

// ========== HANDLE LIVE SEARCH ==========
function handleLiveSearch(value) {
    clearTimeout(searchTimeout);
    const searchResults = document.getElementById('searchResults');
    
    if (value.length === 0) {
        searchResults.classList.remove('active');
        return;
    }
    
    let searchNumber = value;
    if (value.length > 7) {
        searchNumber = value.slice(-7);
    }
    
    if (searchNumber.length < MIN_SEARCH_LENGTH) {
        searchResults.innerHTML = '<div class="search-info">Type at least ' + MIN_SEARCH_LENGTH + ' digits to search...</div>';
        searchResults.classList.add('active');
        return;
    }
    
    searchResults.innerHTML = '<div class="search-loading"><div class="loading-spinner"></div><div style="margin-top: 8px;">Searching...</div></div>';
    searchResults.classList.add('active');
    
    searchTimeout = setTimeout(function() {
        performSearch(searchNumber);
    }, SEARCH_DELAY);
}

// ========== PERFORM SEARCH ==========
function performSearch(searchNumber) {
    const searchResults = document.getElementById('searchResults');
    currentCategory = document.getElementById('accountCategory').value;
    
    fetch('SearchAccounts.jsp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'searchNumber=' + encodeURIComponent(searchNumber) + '&category=' + encodeURIComponent(currentCategory)
    })
    .then(function(response) {
        if (!response.ok) throw new Error('Network error');
        return response.json();
    })
    .then(function(data) {
        if (data.error) {
            searchResults.innerHTML = '<div class="no-results">' + data.error + '</div>';
            return;
        }
        if (data.accounts && data.accounts.length > 0) {
            displaySearchResults(data.accounts, searchNumber);
        } else {
            searchResults.innerHTML = '<div class="no-results">No accounts found matching "' + searchNumber + '"</div>';
        }
    })
    .catch(function(error) {
        console.error('Search error:', error);
        searchResults.innerHTML = '<div class="no-results">Error loading accounts. Please try again.</div>';
        showToast('Search failed. Please try again.', 'error');
    });
}

// ========== DISPLAY SEARCH RESULTS ==========
function displaySearchResults(accounts, searchNumber) {
    const searchResults = document.getElementById('searchResults');
    if (accounts.length === 0) {
        searchResults.innerHTML = '<div class="no-results">No accounts found</div>';
        return;
    }
    let html = '';
    accounts.forEach(function(account) {
        const highlightedCode = highlightMatch(account.code, searchNumber);
        const escapedName = account.name.replace(/'/g, "\\'");
        const productDesc = account.productDesc || '';
        
        html += '<div class="search-result-item" onclick="selectAccountFromSearch(\'' + 
                account.code + '\', \'' + escapedName + '\')">' +
                '<div class="result-code">' + highlightedCode + '</div>' +
                '<div class="result-name-row">' + account.name + '</div>';
        
        if (productDesc && productDesc.trim() !== '') {
            html += '<div class="result-product-desc">' + productDesc + '</div>';
        }
        
        html += '</div>';
    });
    searchResults.innerHTML = html;
}

// ========== HIGHLIGHT MATCHING TEXT ==========
function highlightMatch(text, search) {
    const last7Digits = text.slice(-7);
    const matchIndex = last7Digits.indexOf(search);
    
    if (matchIndex === -1) return text;
    
    const actualIndex = text.length - 7 + matchIndex;
    
    return text.substring(0, actualIndex) + 
           '<span class="highlight">' + 
           search + 
           '</span>' + 
           text.substring(actualIndex + search.length);
}

//Update selectAccountFromSearch to fetch loan data
function selectAccountFromSearch(code, name) {
    document.getElementById('accountCode').value = code;
    document.getElementById('accountName').value = name;
    previousAccountCode = code;
    document.getElementById('searchResults').classList.remove('active');
    
    setTimeout(function() { 
        submitTransactionForm(); 
        
        const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
        const accountCategory = document.getElementById('accountCategory').value;
        const operationType = document.querySelector("input[name='operationType']:checked").value;
        
        // ✅ Populate closing fields if in closing mode
        if (transactionType === 'closing') {
            setTimeout(() => {
                populateClosingFieldsFromIframe();
            }, 1500);
        }
        
        // ✅ Fetch loan data if category is loan
        if (accountCategory === 'loan' || accountCategory === 'cc') {
            setTimeout(() => {
                fetchLoanReceivableData(code);
            }, 1500);
        }

		// ✅ Fetch cheque data if operation is withdrawal OR transfer-debit
		const opType = document.getElementById('opType') ? document.getElementById('opType').value : '';
		if (operationType === 'withdrawal' || (operationType === 'transfer' && opType === 'Debit')) {
		    setTimeout(() => {
		        fetchChequeData(code);
		    }, 500);
		}
    }, 500);
}

// ========== FILTER TABLE FUNCTION FOR LOOKUP ==========
function filterTable() {
    const searchBox = document.getElementById('searchBox');
    if (!searchBox) return;
    const searchValue = searchBox.value.toLowerCase().trim();
    const table = document.getElementById('lookupTable');
    if (!table) return;
    const rows = table.getElementsByClassName('data-row');
    let noResultsRow = document.getElementById('noResultsRow');
    if (searchValue.length < 2) {
        for (let i = 0; i < rows.length; i++) {
            rows[i].style.display = '';
        }
        if (noResultsRow) noResultsRow.style.display = 'none';
        return;
    }
    let visibleCount = 0;
    for (let i = 0; i < rows.length; i++) {
        const cells = rows[i].getElementsByTagName('td');
        if (cells.length < 2) continue;
        const code = cells[0].textContent.toLowerCase();
        const name = cells[1].textContent.toLowerCase();
        if (code.includes(searchValue) || name.includes(searchValue)) {
            rows[i].style.display = '';
            visibleCount++;
        } else {
            rows[i].style.display = 'none';
        }
    }
    if (visibleCount === 0) {
        if (!noResultsRow) {
            noResultsRow = table.insertRow(-1);
            noResultsRow.id = 'noResultsRow';
            noResultsRow.innerHTML = '<td colspan="2" class="no-results">No accounts found</td>';
        }
        noResultsRow.style.display = '';
    } else {
        if (noResultsRow) noResultsRow.style.display = 'none';
    }
}

//========== UPDATE LABELS AND SHOW/HIDE TRANSFER CONTROLS ==========
function updateLabelsBasedOnOperation() {
    const operationType = document.querySelector("input[name='operationType']:checked").value;

    const accountCodeInput = document.getElementById("accountCode");
    const accountNameInput = document.getElementById("accountName");
    const accountCodeLabel = document.getElementById("accountCodeLabel");
    const accountNameLabel = document.getElementById("accountNameLabel");
    const transactionAmountLabel = document.getElementById("transactionamountLabel");

    const addButtonDiv = document.querySelector('.add-btn').parentElement;
    const creditAccountsContainer = document.getElementById('creditAccountsContainer');

    // Clear inputs
    accountCodeInput.value = '';
    accountNameInput.value = '';
    document.getElementById('transactionamount').value = '';
    document.getElementById('particular').value = '';
    previousAccountCode = '';
    clearIframe();
	
	//  Clear loan fields when operation changes
	    const accountCategory = document.getElementById('accountCategory').value;
	    if (accountCategory === 'loan' || accountCategory === 'cc') {
	        clearLoanFields();
	        resetLoanReceivedFields();
	    }

    // Clear transaction data
    creditAccountsData = [];
    refreshCreditAccountsTable();
    updateTotals();
	if (accountCategory === 'loan' || accountCategory === 'cc') {
	    const principleReceived = document.getElementById('principleReceived');
	    if (principleReceived) {
	        principleReceived.value = (parseFloat(this.value) || 0).toFixed(2);
	    }
	    calculateRemaining('principle');
	}

    // ✅ Show/hide cheque fields based on operation type
    toggleChequeFields();
    // Clear cheque fields when switching operation
    clearChequeFields();

    // ✅ Toggle transfer fields visibility
    toggleTransferFields();

    if (operationType === 'transfer') {
        // Update labels for transfer mode
        const opType = document.getElementById('opType').value;
        if (opType === 'Debit') {
            accountCodeLabel.textContent = 'Debit Account Code';
            accountNameLabel.textContent = 'Debit Account Name';
            transactionAmountLabel.textContent = 'Debit Amount';
        } else {
            accountCodeLabel.textContent = 'Credit Account Code';
            accountNameLabel.textContent = 'Credit Account Name';
            transactionAmountLabel.textContent = 'Credit Amount';
        }
        
        addButtonDiv.style.display = 'flex';
        creditAccountsContainer.style.display = 'block';
    } else {
        // Reset labels for deposit/withdrawal
        accountCodeLabel.textContent = 'Account Code';
        accountNameLabel.textContent = 'Account Name';
        transactionAmountLabel.textContent = 'Transaction Amount';
        
        addButtonDiv.style.display = 'none';
        creditAccountsContainer.style.display = 'none';
    }
	updateParticularField();

}

// ========================================
// ====  CHEQUE FIELD FUNCTIONS  ==========
// ========================================

/**
 * Show or hide the cheque fields row based on current operation type.
 * Cheque fields are shown ONLY when operation = withdrawal.
 */
function toggleChequeFields() {
    const operationType = document.querySelector('input[name="operationType"]:checked').value;
    const chequeFieldsRow = document.getElementById('chequeFieldsRow');
    const transactionType = document.querySelector('input[name="transactionTypeRadio"]:checked').value;
    
    // Show for regular withdrawal OR transfer with Debit OP Type (not closing)
    if ((operationType === 'withdrawal' && transactionType !== 'closing') ||
        (operationType === 'transfer' && document.getElementById('opType').value === 'Debit')) {
        chequeFieldsRow.classList.add('active');
    } else {
        chequeFieldsRow.classList.remove('active');
    }
}


/**
 * Fetch cheque data for the given account code from GetChequeData.jsp.
 * Populates Cheque Type and Cheque No dropdowns.
 */
function fetchChequeData(accountCode) {
    if (!accountCode || accountCode.trim() === '') {
        clearChequeFields();
        return;
    }

	const operationType = document.querySelector("input[name='operationType']:checked").value;
	const opType = document.getElementById('opType') ? document.getElementById('opType').value : '';

	if (operationType !== 'withdrawal' && !(operationType === 'transfer' && opType === 'Debit')) {
	    clearChequeFields();
	    return;
	}

    const chequeSeriesSelect = document.getElementById('chequeSeries');
    const chequeTypeSelect = document.getElementById('chequeType');
    const chequeNoSelect   = document.getElementById('chequeNo');
    chequeSeriesSelect.innerHTML = '<option value="">Loading...</option>';
    chequeTypeSelect.innerHTML = '<option value="">Loading...</option>';
    chequeNoSelect.innerHTML   = '<option value="">Loading...</option>';

    fetch('GetChequeData.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(response => response.json())
        .then(data => {
            if (!data.success) {
                showToast('Cheque data error: ' + (data.error || 'Unknown error'), 'warning');
                clearChequeFields();
                return;
            }

            allChequeData = data.cheques || [];

            if (allChequeData.length === 0) {
                chequeSeriesSelect.innerHTML = '<option value="">No cheques available</option>';
                chequeTypeSelect.innerHTML = '<option value="">No cheques available</option>';
                chequeNoSelect.innerHTML   = '<option value="">No cheques available/option>';
                return;
            }

            // ✅ Populate Cheque Series - All unique series from database
            const seriesList = data.seriesList || [];
            chequeSeriesSelect.innerHTML = '<option value="">Select Cheque Series</option>';
            seriesList.forEach(function(series) {
                const opt = document.createElement('option');
                opt.value = series;
                opt.textContent = series;
                chequeSeriesSelect.appendChild(opt);
            });

            // ✅ Populate Cheque Type - All unique types from database
            const typeList = data.typeList || [];
            chequeTypeSelect.innerHTML = '<option value="">Select Cheque Type</option>';
            typeList.forEach(function(typeCode) {
                const opt = document.createElement('option');
                opt.value = typeCode;
                opt.textContent = typeCode;
                chequeTypeSelect.appendChild(opt);
            });

            // ✅ Populate Cheque No - All cheque numbers from database
            chequeNoSelect.innerHTML = '<option value="">Select Cheque No</option>';
            allChequeData.forEach(function(cheque) {
                const opt = document.createElement('option');
                opt.value = cheque.chequeNumber;
                opt.textContent = cheque.chequeNumber;
                chequeNoSelect.appendChild(opt);
            });
        })
        .catch(error => {
            console.error('Error fetching cheque data:', error);
            showToast('Failed to load cheque data', 'warning');
            clearChequeFields();
        });
}

/**
 * Populate Cheque Type dropdown with CHEQUETYPE_CODE values
 * Filter by selected cheque series if provided
 */
function populateChequeTypeDropdown(selectedSeries) {
    const chequeTypeSelect = document.getElementById('chequeType');
    chequeTypeSelect.innerHTML = '<option value="">Select Cheque Type</option>';

    const filtered = selectedSeries
        ? allChequeData.filter(c => c.chequeSeries === selectedSeries)
        : allChequeData;

    // ✅ Get unique CHEQUETYPE_CODE values from filtered data
    const typeSet = new Set();
    filtered.forEach(cheque => {
        if (cheque.chequeTypeCode && cheque.chequeTypeCode.trim() !== '') {
            typeSet.add(cheque.chequeTypeCode.trim());
        }
    });

    if (typeSet.size === 0) {
        chequeTypeSelect.innerHTML = '<option value="">No cheque types available</option>';
        return;
    }

    
    typeSet.forEach(function(typeCode) {
        const opt = document.createElement('option');
        opt.value = typeCode;
        opt.textContent = typeCode;
        chequeTypeSelect.appendChild(opt);
    });
}

/**
 * Called when user changes Cheque Series dropdown
 */
function onChequeSeriesChange() {
    const selectedSeries = document.getElementById('chequeSeries').value;
    populateChequeTypeDropdown(selectedSeries);
    populateChequeNoDropdown(selectedSeries, '');
}

/**
 * Populate Cheque No dropdown, filtered by selected series AND selected type
 */
function populateChequeNoDropdown(selectedSeries, selectedType) {
    const chequeNoSelect = document.getElementById('chequeNo');
    chequeNoSelect.innerHTML = '<option value="">Select Cheque No</option>';

    let filtered = allChequeData;

    if (selectedSeries && selectedSeries.trim() !== '') {
        filtered = filtered.filter(c => c.chequeSeries === selectedSeries);
    }

    if (selectedType && selectedType.trim() !== '') {
        filtered = filtered.filter(c => c.chequeTypeCode === selectedType);
    }

    if (filtered.length === 0) {
        chequeNoSelect.innerHTML = '<option value="">No cheques available</option>';
        return;
    }

    filtered.forEach(function(cheque) {
        const opt = document.createElement('option');
        opt.value = cheque.chequeNumber;
        opt.textContent = cheque.chequeNumber;
        opt.setAttribute('data-series', cheque.chequeSeries);
        opt.setAttribute('data-type', cheque.chequeTypeCode);
        chequeNoSelect.appendChild(opt);
    });
}

/**
 * Called when user changes the Cheque Type dropdown
 */
function onChequeTypeChange() {
    const selectedSeries = document.getElementById('chequeSeries').value;
    const selectedType = document.getElementById('chequeType').value;
    populateChequeNoDropdown(selectedSeries, selectedType);
}

/**
 * Populate Cheque No dropdown, optionally filtered by selected Cheque Type (series).
 * If selectedSeries is empty/null, show all cheque numbers.
 */
function populateChequeNoDropdown(selectedSeries) {
    const chequeNoSelect = document.getElementById('chequeNo');
    chequeNoSelect.innerHTML = '<option value="">Select Cheque No</option>';

    const filtered = selectedSeries
        ? allChequeData.filter(c => c.chequeSeries === selectedSeries)
        : allChequeData;

    if (filtered.length === 0) {
        chequeNoSelect.innerHTML = '<option value="">No cheques for this type</option>';
        return;
    }

    filtered.forEach(function(cheque) {
        const opt = document.createElement('option');
        opt.value = cheque.chequeNumber;
        opt.textContent = cheque.chequeNumber;
        opt.setAttribute('data-series', cheque.chequeSeries);
        chequeNoSelect.appendChild(opt);
    });
}

/**
 * Called when user changes the Cheque Type dropdown.
 * Re-filters the Cheque No dropdown to only show cheques of that series.
 */
function onChequeTypeChange() {
    const selectedSeries = document.getElementById('chequeType').value;
    populateChequeNoDropdown(selectedSeries);
}

/**
 * Reset cheque dropdowns and date to empty state.
 */
function clearChequeFields() {
    allChequeData = [];
    const chequeSeriesSelect = document.getElementById('chequeSeries');
    const chequeTypeSelect = document.getElementById('chequeType');
    const chequeNoSelect   = document.getElementById('chequeNo');
    const chequeDateInput  = document.getElementById('chequeDate');

    if (chequeSeriesSelect) chequeSeriesSelect.innerHTML = '<option value="">Select Cheque Series</option>';
    if (chequeTypeSelect)   chequeTypeSelect.innerHTML = '<option value="">Select Cheque Type</option>';
    if (chequeNoSelect)     chequeNoSelect.innerHTML   = '<option value="">Select Cheque No</option>';
    if (chequeDateInput)    chequeDateInput.value = '';
}

// ========================================
// ====  END CHEQUE FIELD FUNCTIONS  ======
// ========================================

//========== TOGGLE LOAN FIELDS VISIBILITY ==========
function toggleLoanFields() {
    const accountCategory = document.getElementById('accountCategory').value;
    const loanFieldsSection = document.getElementById('loanFieldsSection');
	const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
	
	
	    if (transactionType === 'closing') {
	        loanFieldsSection.classList.remove('active');
	        clearLoanFields();
	        return;
	    }
		
    if (accountCategory === 'loan' || accountCategory === 'cc') {
        loanFieldsSection.classList.add('active');
        
        // Fetch columns if not already loaded
        if (loanRecoveryColumns.length === 0) {
            fetchLoanRecoveryColumns();
        }
    } else {
        loanFieldsSection.classList.remove('active');
        clearLoanFields();
    }
}

// ✅ NEW FUNCTION: Calculate and update Principle Received
function updatePrincipleReceived() {
    const transactionAmount = parseFloat(document.getElementById('transactionamount').value) || 0;
    const totalReceivable = parseFloat(document.getElementById('totalReceivable').value) || 0;
    const principleReceivedField = document.getElementById('principleReceived');
    
    if (!principleReceivedField) return;
    
    // If transaction amount > total receivable, show the difference
    // Otherwise show 0.00
    if (transactionAmount > totalReceivable) {
        const extraAmount = transactionAmount - totalReceivable;
        principleReceivedField.value = extraAmount.toFixed(2);
    } else {
        principleReceivedField.value = '0.00';
    }
}

//Calculate remaining amount (Receivable - Received)
function calculateRemaining(fieldName) {
	
	if (fieldName === 'total') {
	        const r = document.getElementById('totalReceivable');
	        const g = document.getElementById('totalReceived');
	        const m = document.getElementById('totalRemaining');

	        if (!r || !g || !m) return;

	        const receivable = parseFloat(r.value) || 0;
	        const received = parseFloat(g.value) || 0;

	        m.value = (receivable - received).toFixed(2);
			
			// ✅ UPDATE PRINCIPLE RECEIVED WHEN TOTAL CHANGES
			updatePrincipleReceived();
	        return;
	    }

    const receivableEl = document.getElementById(fieldName + 'Receivable');
    const receivedEl = document.getElementById(fieldName + 'Received');
    const remainingEl = document.getElementById(fieldName + 'Remaining');
    
    if (!receivableEl || !receivedEl || !remainingEl) return;
    
    const receivable = parseFloat(receivableEl.value.replace(/,/g, '')) || 0;
    const received = parseFloat(receivedEl.value.replace(/,/g, '')) || 0;
    const remaining = receivable - received;
    
    remainingEl.value = remaining.toFixed(2);
    
    // Color coding for remaining amount
    if (remaining < 0) {
        remainingEl.style.color = 'red';
        remainingEl.style.fontWeight = 'bold';
    } else if (remaining === 0) {
        remainingEl.style.color = 'green';
        remainingEl.style.fontWeight = 'bold';
    } else {
        remainingEl.style.color = '#666';
        remainingEl.style.fontWeight = 'normal';
    }
}

//========== TOGGLE TRANSFER FIELDS VISIBILITY ==========
function toggleTransferFields() {
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    const transferFieldsSection = document.getElementById('transferFieldsSection');
    
    if (operationType === 'transfer') {
        transferFieldsSection.classList.add('active');
    } else {
        transferFieldsSection.classList.remove('active');
    }
}
// ========== INITIALIZE ON PAGE LOAD ==========
document.addEventListener('DOMContentLoaded', function() {
	
	// Fetch loan recovery columns from database
    fetchLoanRecoveryColumns();
	
	// Fetch closing sequence columns from database
	    fetchClosingSequenceColumns();
		
    // Initialize transaction table
    refreshCreditAccountsTable();
    
    // Transaction type change handler - NEW
    const transactionTypeRadios = document.querySelectorAll("input[name='transactionTypeRadio']");
    transactionTypeRadios.forEach(function(radio) {
        radio.addEventListener('change', function() {
            handleTransactionTypeChange();
        });
    });
    
    // Initial call to set proper visibility
    handleTransactionTypeChange();
    
    // Operation type change handler
    const operationRadios = document.querySelectorAll("input[name='operationType']");
    operationRadios.forEach(function(radio) {
		radio.addEventListener('change', function() {
		    updateLabelsBasedOnOperation();
		    calculateNewBalanceInIframe();
		    toggleChequeFields();
		    
		    // If switching to withdrawal OR transfer-debit and account is already selected, fetch cheque data
		    const currentAccountCode = document.getElementById('accountCode').value.trim();
		    if ((this.value === 'withdrawal' || (this.value === 'transfer' && document.getElementById('opType').value === 'Debit')) && currentAccountCode) {
		        fetchChequeData(currentAccountCode);
		    } else {
		        clearChequeFields();
		    }
		});

    });
    
    // Handle OP Type dropdown change
    const opTypeSelect = document.getElementById('opType');
    if (opTypeSelect) {
		opTypeSelect.addEventListener('change', function() {
		    const opType = this.value;
		    const accountCodeLabel = document.getElementById('accountCodeLabel');
		    const accountNameLabel = document.getElementById('accountNameLabel');
		    const transactionAmountLabel = document.getElementById('transactionamountLabel');
		    
		    if (opType === 'Debit') {
		        accountCodeLabel.textContent = 'Debit Account Code';
		        accountNameLabel.textContent = 'Debit Account Name';
		        transactionAmountLabel.textContent = 'Debit Amount';
		    } else if (opType === 'Credit') {
		        accountCodeLabel.textContent = 'Credit Account Code';
		        accountNameLabel.textContent = 'Credit Account Name';
		        transactionAmountLabel.textContent = 'Credit Amount';
		    }
		    
		    // Clear inputs when OP Type changes
		    document.getElementById('accountCode').value = '';
		    document.getElementById('accountName').value = '';
		    document.getElementById('transactionamount').value = '';
		    document.getElementById('particular').value = '';
		    previousAccountCode = '';
		    clearIframe();
		    updateParticularField();
		    
		    // Toggle cheque fields when switching Debit/Credit
		    toggleChequeFields();
			const currentAccountCode = document.getElementById('accountCode').value.trim();
			if (this.value === 'Debit' && currentAccountCode) {
			    fetchChequeData(currentAccountCode);
			} else if (this.value === 'Credit') {
			    clearChequeFields();
			}
		});
    }
    
	// Category change handler
	const categoryDropdown = document.getElementById('accountCategory');
	if (categoryDropdown) {
	    categoryDropdown.addEventListener('change', function() {
	        
	        const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
	        if (transactionType === 'closing') {
	            fetchClosingSequenceColumns();
	        }
	        
	        // Toggle loan fields visibility
	        toggleLoanFields();
	    });
	}


	
    // Initialize previous values
    previousAccountCode = document.getElementById('accountCode').value;
    
    // Transaction amount input handler for totals
    const transactionAmountInput = document.getElementById('transactionamount');
    if (transactionAmountInput) {
        transactionAmountInput.addEventListener('input', updateTotals);
    }
    
    // Initial calls to set visibility
    updateLabelsBasedOnOperation();
    toggleLoanFields();
    toggleTransferFields();
    toggleChequeFields(); // ✅ Initialize cheque fields visibility
	updateParticularField(); 
});

// ================= FINAL & ONLY TRANSACTION AMOUNT HANDLER =================
const transactionAmountInput = document.getElementById('transactionamount');
if (transactionAmountInput) {
    transactionAmountInput.removeAttribute('oninput');

    transactionAmountInput.addEventListener('input', function () {
        const accountCategory = document.getElementById('accountCategory').value;
        const txnAmount = parseFloat(this.value) || 0;

        // ✅ LOAN / CC PRINCIPAL HANDLING (LAST)
		if (accountCategory === 'loan' || accountCategory === 'cc') {
		    resetLoanReceivedFields();

		    const totalReceived = document.getElementById('totalReceived');
		    if (totalReceived) {
		        totalReceived.value = txnAmount.toFixed(2);
		    }

		    calculateRemaining('total');
			// ✅ UPDATE PRINCIPLE RECEIVED
			updatePrincipleReceived();
		}

        // ✅ EXISTING FLOW
        calculateNewBalanceInIframe();
        updateTotals();
    });
}


// ========== LOOKUP MODAL FUNCTIONS ==========
function openLookup(type) {
	let accountCategory = document.getElementById('accountCategory').value;
    let url = "LookupForTransactions.jsp?type=account";
    url += "&accountCategory=" + accountCategory;
    
    fetch(url)
        .then(function(response) { return response.text(); })
        .then(function(html) {
            document.getElementById("lookupContent").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
            window.currentLookupType = type;
            setTimeout(function() {
                const searchBox = document.getElementById('searchBox');
                if (searchBox) searchBox.focus();
            }, 100);
        })
        .catch(function(error) {
            showToast('Failed to load lookup data.', 'error');
            console.error('Lookup error:', error);
        });
}

function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
    window.currentLookupType = null;
}

function sendBack(code, desc, type) {
    setValueFromLookup(code, desc, type);
}

function setValueFromLookup(code, desc, type) {
    document.getElementById("accountCode").value = code;
    document.getElementById("accountName").value = desc;
    previousAccountCode = code;
    window.currentLookupType = null;
    closeLookup();
    
    setTimeout(function() { 
        submitTransactionForm(); 
        
        const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
        const accountCategory = document.getElementById('accountCategory').value;
        const operationType = document.querySelector("input[name='operationType']:checked").value;
        
        // ✅ Populate closing fields if in closing mode
        if (transactionType === 'closing') {
            setTimeout(() => {
                populateClosingFieldsFromIframe();
            }, 1500);
        }
        
        // ✅ Fetch loan data if category is loan
        if (accountCategory === 'loan' || accountCategory === 'cc') {
            setTimeout(() => {
                fetchLoanReceivableData(code);
            }, 1500);
        }

		// ✅ Fetch cheque data if operation is withdrawal OR transfer-debit
		const opType = document.getElementById('opType') ? document.getElementById('opType').value : '';
		if (operationType === 'withdrawal' || (operationType === 'transfer' && opType === 'Debit')) {
		    setTimeout(() => {
		        fetchChequeData(code);
		    }, 500);
		}
    }, 500);
}

//Update the submitTransactionForm function
function submitTransactionForm() {
    let transTypeRadio = document.querySelector("input[name='transactionTypeRadio']:checked").value;
    let operationType = document.querySelector("input[name='operationType']:checked").value;
    let accountCategory = document.getElementById('accountCategory').value;
    let accountCode = document.querySelector("input[name='accountCode']").value.trim();
    let accountName = document.querySelector("input[name='accountName']").value.trim();
    
    console.log("Submitting:", transTypeRadio, operationType, accountCategory, accountCode, accountName);
    
    const pageMap = {
        "deposit": "transactionForm.jsp",
        "withdrawal": "transactionForm.jsp",
        "transfer": "transferForm.jsp"
    };
    
    if (pageMap[operationType]) {
        let form = document.getElementById("transactionForm");
        form.action = pageMap[operationType];
        form.submit();
        
        
        
        if (accountCategory === 'loan' && accountCode) {
            setTimeout(() => {
                fetchLoanReceivableData(accountCode);
            }, 1000); // Wait for iframe to load
        }
    } else {
        showToast('No page found for Operation Type: ' + operationType, 'error');
    }
}

// ========== CLOSE DROPDOWN AND MODAL ==========
document.addEventListener('click', function(e) {
    if (!e.target.closest('.input-box') && !e.target.closest('.search-dropdown')) {
        document.getElementById('searchResults').classList.remove('active');
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeLookup();
        document.getElementById('searchResults').classList.remove('active');
    }
});

function handleSaveTransaction() {
    const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    
    // Use working date from session (defined in JSP)
    const sessionWorkingDate = typeof workingDate !== 'undefined' ? workingDate : 
        new Date().toLocaleDateString('en-GB').replace(/\//g, '/');

		// ✅ CHECK LEDGER BALANCE - ONLY FOR WITHDRAWAL AND TRANSFER DEBIT
		const iframe = document.getElementById('resultFrame');
		try {
		    const iframeWindow = iframe.contentWindow;
		    const iframeDoc = iframeWindow.document;
		    
		    if (operationType === 'transfer') {
		        // For transfer, check ONLY debit accounts (NOT credit)
		        for (let i = 0; i < creditAccountsData.length; i++) {
		            const txn = creditAccountsData[i];
		            
		            // Only validate for Debit transactions
		            if (txn.opType === 'Debit') {
		                const ledgerField = iframeDoc.getElementById('ledgerBalance');
		                
		                if (ledgerField) {
		                    const ledgerBalance = parseFloat(ledgerField.value) || 0;
		                    if (txn.amount > ledgerBalance) {
		                        showValidationError('Debit Amount cannot exceed Ledger Balance (₹' + 
		                                           ledgerBalance.toFixed(2) + ')');
		                        return;
		                    }
		                }
		            }
		            // Credit transactions - NO validation needed
		        }
		    } else if (operationType === 'withdrawal') {
		        // For withdrawal, check single account
		        const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
		        if (ledgerBalanceField) {
		            const ledgerBalance = parseFloat(ledgerBalanceField.value) || 0;
		            const txnAmount = parseFloat(document.getElementById('transactionamount').value) || 0;
		            
		            if (txnAmount > ledgerBalance) {
		                showValidationError('Withdrawal Amount cannot exceed Ledger Balance (₹' + 
		                                   ledgerBalance.toFixed(2) + ')');
		                return;
		            }
		        }
		    }
		    // For deposit - NO validation needed
		} catch (e) {
		    console.error('Error checking balance:', e);
		}
    
    // ✅ HANDLE TRANSFER MODE - Validate from creditAccountsData list
    if (operationType === 'transfer') {
        // Validation for transfer mode
        if (creditAccountsData.length === 0) {
            showToast('Please add at least one transaction to the list', 'error');
            return;
        }
        
        // Check if transactions are tallied
        const totalDebit = parseFloat(document.getElementById('totalDebit').value) || 0;
        const totalCredit = parseFloat(document.getElementById('totalCredit').value) || 0;
        
        if (totalDebit !== totalCredit || totalDebit === 0) {
            showToast('Transactions must be tallied (Debit = Credit) before saving', 'error');
            return;
        }
        
        // ✅ Validate each account from creditAccountsData array
        validateTransactionsSequentially(0, sessionWorkingDate);
        
    } else {
        // VALIDATION FOR NON-TRANSFER (DEPOSIT/WITHDRAWAL)
        const accountCode = document.getElementById('accountCode').value.trim();
        const transactionAmount = document.getElementById('transactionamount').value.trim();
        
        if (!accountCode) {
            showToast('Please enter or select an account code', 'error');
            return;
        }
        
        if (!transactionAmount || parseFloat(transactionAmount) <= 0) {
            showToast('Please enter a valid transaction amount', 'error');
            return;
        }
        
        // Validate single transaction
        validateSingleTransaction(accountCode, sessionWorkingDate, operationType, transactionAmount);
    }
}

// ✅ VALIDATE TRANSACTIONS FROM creditAccountsData ARRAY
function validateTransactionsSequentially(index, sessionWorkingDate) {
    if (index >= creditAccountsData.length) {
        // All validations passed
        
        proceedWithSave();
        return;
    }
    
    // ✅ Get transaction data from creditAccountsData array
    const transaction = creditAccountsData[index];
    const accountCode = transaction.code;
    const accountName = transaction.name;
    const amount = transaction.amount;
    const opType = transaction.opType;
    
    // Determine transaction indicator based on opType
    const transactionIndicator = opType === 'Credit' ? 'TRCR' : 'TRDR';
    
    
    
    const params = new URLSearchParams({
        accountCode: accountCode,
        workingDate: sessionWorkingDate,
        transactionIndicator: transactionIndicator,
        transactionAmount: amount
    });
    
    fetch('ValidateTransaction.jsp?' + params.toString())
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showValidationError('Validation failed for ' + opType + ' account ' + accountCode + ':\n' + data.error);
                return; // Stop validation
            } else if (data.success) {
               
                // Continue to next account after a short delay
                setTimeout(() => {
                    validateTransactionsSequentially(index + 1, sessionWorkingDate);
                }, 500);
            } else {
                // Validation failed
    			showValidationError('Validation failed for ' + opType + ' account ' + accountCode + ':\n' + data.message);
                return; // Stop validation
            }
        })
        .catch(error => {
            console.error('Validation error for account ' + accountCode + ':', error);
            showValidationError('Network error validating account ' + accountCode);
            return; // Stop validation
        });
}

// VALIDATE SINGLE TRANSACTION (for non-transfer)
function validateSingleTransaction(accountCode, sessionWorkingDate, operationType, transactionAmount) {
    
    // ✅ VALIDATE AGAINST LEDGER BALANCE BEFORE SERVER VALIDATION
    const iframe = document.getElementById('resultFrame');
    try {
        const iframeWindow = iframe.contentWindow;
        const iframeDoc = iframeWindow.document;
        const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
        
        if (ledgerBalanceField && operationType === 'withdrawal') {
            const ledgerBalance = parseFloat(ledgerBalanceField.value) || 0;
            const txnAmountValue = parseFloat(transactionAmount) || 0;
            
            if (txnAmountValue > ledgerBalance) {
                showValidationError('Withdrawal Amount cannot exceed available Ledger Balance (₹' + 
                                  ledgerBalance.toFixed(2) + ')');
                return;
            }
        }
    } catch (e) {
        console.error('Error checking balance:', e);
    }
    
    // Determine transaction indicator
    let transactionIndicator = '';
    
    if (operationType === 'deposit') {
        transactionIndicator = 'CSCR';
    } else if (operationType === 'withdrawal') {
        transactionIndicator = 'CSDR';
    } else {
        showToast('Invalid operation type', 'error');
        return;
    }
    
    const params = new URLSearchParams({
        accountCode: accountCode,
        workingDate: sessionWorkingDate,
        transactionIndicator: transactionIndicator,
        transactionAmount: transactionAmount
    });
    
    fetch('ValidateTransaction.jsp?' + params.toString())
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showValidationError('Error: ' + data.error);
            } else if (data.success) {
                //showToast(data.message, 'success');
                proceedWithSave();
            } else {
                showValidationError(data.message);
            }
        })
        .catch(error => {
            console.error('Validation error:', error);
            showValidationError('Failed to validate transaction. Please try again.');
        });
}

function showValidationError(message) {
    document.getElementById('validationErrorMessage').textContent = message;
    document.getElementById('validationErrorModal').style.display = 'flex';
}

function closeValidationErrorModal() {
    document.getElementById('validationErrorModal').style.display = 'none';
}

function proceedWithSave() {
    const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    const accountCategory = document.getElementById('accountCategory').value;
    
    // Use working date from session (defined in JSP)
    const sessionWorkingDate = typeof workingDate !== 'undefined' ? workingDate : 
        new Date().toLocaleDateString('en-GB').replace(/\//g, '/');
    
    if (operationType === 'transfer') {
        // Save all transactions from creditAccountsData array
        saveTransactionsSequentially(0, sessionWorkingDate);
    } else {
        // Save single transaction (deposit/withdrawal)
        const accountCode = document.getElementById('accountCode').value.trim();
        const transactionAmount = document.getElementById('transactionamount').value.trim();
        const particular = document.getElementById('particular').value.trim();
        
        // Determine transaction indicator
        let transactionIndicator = '';
        if (operationType === 'deposit') {
            transactionIndicator = 'CSCR';
        } else if (operationType === 'withdrawal') {
            transactionIndicator = 'CSDR';
        }
        
        saveSingleTransaction(accountCode, transactionAmount, transactionIndicator, particular, operationType, sessionWorkingDate);
    }
}

function getNewAccountBalanceFromIframe() {
    const iframe = document.getElementById('resultFrame');
    const operationType = document.querySelector("input[name='operationType']:checked").value;

    try {
        const iframeWindow = iframe.contentWindow;
        const iframeDoc = iframeWindow.document;

        if (operationType === 'transfer') {
            // For transfer, return both balances as an object
            const debitNew = iframeDoc.getElementById('newLedgerBalance');
            const creditNew = iframeDoc.getElementById('creditNewLedgerBalance');

            return {
                debit: (debitNew && debitNew.value.trim() !== '') ? debitNew.value.trim() : '0.00',
                credit: (creditNew && creditNew.value.trim() !== '') ? creditNew.value.trim() : '0.00'
            };
        }

        // Deposit / Withdrawal
        const newLedgerBalanceField = iframeDoc.getElementById('newLedgerBalance');
        const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');

        if (newLedgerBalanceField && newLedgerBalanceField.value.trim() !== '') {
            return newLedgerBalanceField.value.trim();
        } else if (ledgerBalanceField && ledgerBalanceField.value.trim() !== '') {
            return ledgerBalanceField.value.trim();
        } else {
            return '0.00';
        }
    } catch (e) {
        console.error('Error reading balance from iframe:', e);
        return null;
    }
}

// Save single transaction (deposit/withdrawal) - MODIFIED WITH AUTHORIZATION MODAL
function saveSingleTransaction(accountCode, transactionAmount, transactionIndicator, particular, operationType, sessionWorkingDate) {
    // ✅ Get new account balance from iframe
    const newAccountBalance = getNewAccountBalanceFromIframe();
	const accountCategory = document.getElementById('accountCategory').value;
	if (accountCategory === 'loan' || accountCategory === 'cc') {
	        saveLoanRecoveryTransactions(accountCode, sessionWorkingDate);
	        return;
	    }
		
    if (newAccountBalance === null) {
        showToast('❌ Could not read account balance from iframe. Please wait for the page to load.', 'error');
        return;
    }
    
    // Create form data for POST request
    const formData = new URLSearchParams();
    formData.append('accountCode', accountCode);
    formData.append('transactionAmount', transactionAmount);
    formData.append('transactionIndicator', transactionIndicator);
    formData.append('particular', particular || '');
    formData.append('operationType', operationType);
    formData.append('newAccountBalance', newAccountBalance); // ✅ ADD THIS

	// Append cheque fields for withdrawal only (deposit → no cheque params → servlet inserts NULL)
	    if (operationType === 'withdrawal') {
	        formData.append('chequeType',   document.getElementById('chequeType').value   || '');
	        formData.append('chequeSeries', document.getElementById('chequeSeries').value || '');
	        formData.append('chequeNumber', document.getElementById('chequeNo').value      || '');
	        formData.append('chequeDate',   document.getElementById('chequeDate').value    || '');
	    }

    
    // Call servlet
    fetch('SaveTransactionServlet', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.toString()
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            showToast('❌ Error: ' + data.error, 'error');
        } else if (data.success) {
            // ✅ SHOW AUTHORIZATION MODAL INSTEAD OF TOAST
            showAuthorizationModal(accountCode, data.scrollNumber, operationType);
            
            // Clear form fields
            document.getElementById('accountCode').value = '';
            document.getElementById('accountName').value = '';
            document.getElementById('transactionamount').value = '';
            document.getElementById('particular').value = '';
            previousAccountCode = '';
            clearIframe();

            // ✅ Clear cheque fields after successful save
            clearChequeFields();
            
            // Clear loan fields if applicable
            if (accountCategory === 'loan' || accountCategory === 'cc') {
                clearLoanFields();
                resetLoanReceivedFields();
            }
        } else {
            showToast('❌ ' + data.message, 'error');
        }
    })
    .catch(error => {
        console.error('Save error:', error);
        showToast('❌ Failed to save transaction', 'error');
    });
}

// Save transactions from creditAccountsData array sequentially - MODIFIED WITH AUTHORIZATION MODAL
function saveTransactionsSequentially(index, sessionWorkingDate) {
    // Initialize scroll number tracking on first call
    if (index === 0) {
        window.currentTransferScrollNumber = null;
        window.transferBatchInProgress = true;
        console.log('=== Starting new transfer batch ===');
    }
    
    if (index >= creditAccountsData.length) {
        // All transactions saved successfully
        const firstTransaction = creditAccountsData[0];
        showAuthorizationModal(firstTransaction.code, window.currentTransferScrollNumber, 'transfer');
        
        // Clear the transaction list and reset the form
        creditAccountsData = [];
        refreshCreditAccountsTable();
        updateTotals();
        
        // Clear form fields
        document.getElementById('accountCode').value = '';
        document.getElementById('accountName').value = '';
        document.getElementById('transactionamount').value = '';
        document.getElementById('particular').value = '';
        previousAccountCode = '';
        clearIframe();
        
        // Reset the global scroll number
        window.currentTransferScrollNumber = null;
        window.transferBatchInProgress = false;
        console.log('=== Transfer batch completed ===');
        
        return;
    }
    
	const transaction = creditAccountsData[index];
	const accountCode = transaction.code;
	const amount = transaction.amount;
	const particular = transaction.particular;
	const opType = transaction.opType;

	console.log('Processing transaction ' + (index + 1) + '/' + creditAccountsData.length + 
	            ': ' + opType + ' for account ' + accountCode);

	// Determine transaction indicator based on opType
	const transactionIndicator = opType === 'Credit' ? 'TRCR' : 'TRDR';

	// For transfer, get the opposite account code as forAccountCode
	const oppositeTransaction = creditAccountsData.find(t => 
	    t.opType !== opType && t.id !== transaction.id
	);
	const forAccountCode = oppositeTransaction ? oppositeTransaction.code : '';

	// ✅ CRITICAL FIX: Use the balance that was stored when adding to the list
	const newAccountBalance = transaction.newAccountBalance || '0.00';

	console.log('Using stored balance for ' + opType + ' account ' + accountCode + ': ' + newAccountBalance);
    
    // Create form data for POST request
    const formData = new URLSearchParams();
    formData.append('accountCode', accountCode);
    formData.append('transactionAmount', amount);
    formData.append('transactionIndicator', transactionIndicator);
    formData.append('particular', particular || '');
    formData.append('operationType', 'transfer');
    formData.append('forAccountCode', forAccountCode);
    formData.append('newAccountBalance', newAccountBalance); // ✅ correct per-opType balance
    
	// Append cheque fields for Debit transactions (Credit rows → params absent → servlet inserts NULL)
	    if (opType === 'Debit' && transaction.chequeData) {
	        formData.append('chequeType',   transaction.chequeData.chequeType   || '');
	        formData.append('chequeSeries', transaction.chequeData.chequeSeries || '');
	        formData.append('chequeNumber', transaction.chequeData.chequeNumber || '');
	        formData.append('chequeDate',   transaction.chequeData.chequeDate   || '');
	    }

	    // Handle scroll number parameters correctly
	    if (index === 0) {
        // First transaction - servlet will generate new scroll number
        console.log('→ First transaction - servlet will generate new scroll number');
        // DO NOT send scrollNumber or subscrollNumber parameters
    } else if (window.currentTransferScrollNumber !== null) {
        // Subsequent transactions - reuse the scroll number from first transaction
        formData.append('scrollNumber', window.currentTransferScrollNumber.toString());
        formData.append('subscrollNumber', (index + 1).toString());
        console.log('→ Transaction #' + (index + 1) + ' - Reusing scroll number: ' + 
                    window.currentTransferScrollNumber + ', subscroll: ' + (index + 1));
    } else {
        // This should not happen
        console.error('ERROR: Scroll number not available for transaction ' + (index + 1));
        showToast('❌ Error: Previous transaction not completed', 'error');
        window.transferBatchInProgress = false;
        return;
    }
    
    // Call servlet
    fetch('SaveTransactionServlet', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.toString()
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            console.error('❌ Save failed:', data.error);
            showToast('❌ Failed to save ' + opType + ' transaction for account ' + 
                     accountCode + ': ' + data.error, 'error');
            window.currentTransferScrollNumber = null;
            window.transferBatchInProgress = false;
            return;
        } else if (data.success) {
            // Store scroll number from FIRST transaction response
            if (index === 0 && data.scrollNumber) {
                window.currentTransferScrollNumber = data.scrollNumber;
                console.log('✓ Stored scroll number from first transaction: ' + 
                           window.currentTransferScrollNumber);
            }
            
            // Verify scroll number consistency
            if (index > 0 && data.scrollNumber !== window.currentTransferScrollNumber) {
                console.warn('WARNING: Scroll number mismatch! Expected ' + 
                           window.currentTransferScrollNumber + ', got ' + data.scrollNumber);
            }
            
            console.log('✓ Transaction saved: Scroll ' + data.scrollNumber + 
                       ', Subscroll ' + data.subscrollNumber);
            
            // Continue to next transaction
            setTimeout(() => {
                saveTransactionsSequentially(index + 1, sessionWorkingDate);
            }, 800);
        } else {
            console.error('❌ Save failed:', data.message);
            showToast('❌ Failed to save transaction: ' + data.message, 'error');
            window.currentTransferScrollNumber = null;
            window.transferBatchInProgress = false;
            return;
        }
    })
    .catch(error => {
        console.error('❌ Network error for account ' + accountCode + ':', error);
        showToast('❌ Network error saving account ' + accountCode, 'error');
        window.currentTransferScrollNumber = null;
        window.transferBatchInProgress = false;
        return;
    });
}

function calculateNewBalanceInIframe() {
    const transactionAmount = parseFloat(document.getElementById('transactionamount').value) || 0;
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    const accountCategory = document.getElementById('accountCategory').value;
    const opType = document.getElementById('opType') ? document.getElementById('opType').value : '';

    const iframe = document.getElementById('resultFrame');

    try {
        const iframeWindow = iframe.contentWindow;
        const iframeDoc = iframeWindow.document;

        // ===== TRANSFER MODE =====
        if (operationType === 'transfer') {
            const shouldUseSequential = (accountCategory === 'loan' || accountCategory === 'cc') 
                                        && opType === 'Credit';

            if (shouldUseSequential) {
                calculateSequentialLoanDeduction();
                return;
            }

            if (opType === 'Debit') {
                // Debit: subtract from debit account ledger balance
                const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
                const newLedgerBalanceField = iframeDoc.getElementById('newLedgerBalance');

                if (ledgerBalanceField && newLedgerBalanceField) {
                    const ledgerBalance = parseFloat(ledgerBalanceField.value) || 0;
                    const newBalance = transactionAmount > 0 
                        ? (ledgerBalance - transactionAmount) 
                        : ledgerBalance;
                    newLedgerBalanceField.value = newBalance.toFixed(2);
                }

            } else if (opType === 'Credit') {
                // Credit: add to credit account ledger balance
                const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
                const newLedgerBalanceField = iframeDoc.getElementById('newLedgerBalance');

                if (ledgerBalanceField && newLedgerBalanceField) {
                    const ledgerBalance = parseFloat(ledgerBalanceField.value) || 0;
                    const newBalance = transactionAmount > 0 
                        ? (ledgerBalance + transactionAmount) 
                        : ledgerBalance;
                    newLedgerBalanceField.value = newBalance.toFixed(2);
                }
            }
            return;
        }

        // ===== DEPOSIT / WITHDRAWAL MODE =====
        const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
        const newLedgerBalanceField = iframeDoc.getElementById('newLedgerBalance');

        if (ledgerBalanceField && newLedgerBalanceField) {
            const ledgerBalance = parseFloat(ledgerBalanceField.value) || 0;
            let newLedgerBalance = ledgerBalance;

            if (transactionAmount > 0) {
                const shouldUseSequential = (accountCategory === 'loan' || accountCategory === 'cc') 
                                            && operationType === 'deposit';

                if (shouldUseSequential) {
                    calculateSequentialLoanDeduction();
                    return;
                }

                if (operationType === 'deposit') {
                    newLedgerBalance = ledgerBalance + transactionAmount;
                } else if (operationType === 'withdrawal') {
                    newLedgerBalance = ledgerBalance - transactionAmount;
                }
            }

            newLedgerBalanceField.value = newLedgerBalance.toFixed(2);
        }

    } catch (e) {
        console.error('Error calculating balance:', e);
    }
}

	// ========== DYNAMIC TRANSACTION TABLE ==========
	let creditAccountsData = [];
	
	function addTransactionRow() {
	    const accountCode = document.getElementById('accountCode').value.trim();
	    const accountName = document.getElementById('accountName').value.trim();
	    const transactionAmount = document.getElementById('transactionamount').value.trim();
	    const particular = document.getElementById('particular').value.trim();
	    const opType = document.getElementById('opType').value;
	    const accountCategory = document.getElementById('accountCategory').value;

	    // Validate inputs
	    if (!accountCode) {
	        showToast('Please enter or select an account code', 'error');
	        return;
	    }

	    if (!accountName) {
	        showToast('Please select an account', 'error');
	        return;
	    }

	    if (!transactionAmount || parseFloat(transactionAmount) <= 0) {
	        showToast('Please enter a valid transaction amount', 'error');
	        return;
	    }

	    const finalAmount = parseFloat(transactionAmount).toFixed(2);

	    // ✅ NEW FIX: Calculate balance from CURRENT iframe state
	    let newAccountBalance = '0.00';
	    const iframe = document.getElementById('resultFrame');

	    try {
	        const iframeWindow = iframe.contentWindow;
	        const iframeDoc = iframeWindow.document;
	        
	        // Get the ledger balance from the iframe (current account being displayed)
	        let currentLedgerBalance = 0;
	        
			if (opType === 'Debit') {
			    // For Debit, check if debit section exists
			    const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
			    if (ledgerBalanceField && ledgerBalanceField.value.trim() !== '') {
			        currentLedgerBalance = parseFloat(ledgerBalanceField.value) || 0;
			        
			        // ✅ VALIDATE AGAINST LEDGER BALANCE FOR DEBIT ONLY
			        if (finalAmount > currentLedgerBalance) {
			            showValidationError('Debit Amount cannot exceed Ledger Balance (₹' + 
			                               currentLedgerBalance.toFixed(2) + ')');
			            return;
			        }
			        
			        // Debit: subtract amount
			        newAccountBalance = (currentLedgerBalance - parseFloat(finalAmount)).toFixed(2);
			    }
			} else if (opType === 'Credit') {
			    // For Credit, NO ledger balance check needed
			    const creditLedgerBalanceField = iframeDoc.getElementById('creditLedgerBalance');
			    const regularLedgerBalanceField = iframeDoc.getElementById('ledgerBalance');
			    
			    if (creditLedgerBalanceField && creditLedgerBalanceField.value.trim() !== '') {
			        // Credit section exists (transferForm.jsp loaded with credit account)
			        currentLedgerBalance = parseFloat(creditLedgerBalanceField.value) || 0;
			    } else if (regularLedgerBalanceField && regularLedgerBalanceField.value.trim() !== '') {
			        // Regular section exists (transactionForm.jsp loaded with credit account)
			        currentLedgerBalance = parseFloat(regularLedgerBalanceField.value) || 0;
			    }
			    
			    // Credit: add amount (NO validation needed)
			    newAccountBalance = (currentLedgerBalance + parseFloat(finalAmount)).toFixed(2);
			}
	        
	        console.log('Captured ' + opType + ' balance: ' + newAccountBalance + ' (Ledger: ' + currentLedgerBalance + ', Amount: ' + finalAmount + ')');
	        
	    } catch (e) {
	        console.error('Error reading balance from iframe:', e);
	        showToast('Could not read account balance. Please try again.', 'error');
	        return;
	    }

	    // ✅ FIXED: Collect loan field values if it's a loan account
	    let loanFieldsData = {};
	    if (accountCategory === 'loan' || accountCategory === 'cc') {
	        loanRecoveryColumns.forEach(function(col) {
	            if (!col || !col.columnName) return;
	            const fieldName = col.columnName.toLowerCase().trim();
	            if (!fieldName) return;
	            
	            const receivableEl = document.getElementById(fieldName + 'Receivable');
	            const receivedEl = document.getElementById(fieldName + 'Received');
	            const remainingEl = document.getElementById(fieldName + 'Remaining');
	            
	            loanFieldsData[fieldName] = {
	                receivable: receivableEl ? receivableEl.value : '',
	                received: receivedEl ? receivedEl.value : '',
	                remaining: remainingEl ? remainingEl.value : ''
	            };
	        });
	        
	        const totalReceivableEl = document.getElementById('totalReceivable');
	        const totalReceivedEl = document.getElementById('totalReceived');
	        const totalRemainingEl = document.getElementById('totalRemaining');

	        loanFieldsData['total'] = {
	            receivable: totalReceivableEl ? totalReceivableEl.value : '',
	            received: totalReceivedEl ? totalReceivedEl.value : '',
	            remaining: totalRemainingEl ? totalRemainingEl.value : ''
	        };
	        
	        const principleReceivedEl = document.getElementById('principleReceived');
	        loanFieldsData['principle'] = {
	            received: principleReceivedEl ? principleReceivedEl.value : ''
	        };
	    }

	    // Capture cheque fields for Debit transfer rows
	    let chequeData = { chequeType: '', chequeSeries: '', chequeNumber: '', chequeDate: '' };
	    if (opType === 'Debit') {
	        chequeData = {
	            chequeType:   document.getElementById('chequeType').value   || '',
	            chequeSeries: document.getElementById('chequeSeries').value || '',
	            chequeNumber: document.getElementById('chequeNo').value      || '',
	            chequeDate:   document.getElementById('chequeDate').value    || ''
	        };
	    }

	    creditAccountsData.push({
	        id: Date.now(),
	        code: accountCode,
	        name: accountName,
	        amount: finalAmount,
	        particular: particular,
	        opType: opType,
	        loanFields: loanFieldsData,
	        newAccountBalance: newAccountBalance,
	        chequeData: chequeData   // ✅ Store cheque data per-row
	    });

	    // Clear input fields
	    document.getElementById('accountCode').value = '';
	    document.getElementById('accountName').value = '';
	    document.getElementById('transactionamount').value = '';
	    document.getElementById('particular').value = '';
	    previousAccountCode = '';
	    clearIframe();

	    // Clear loan fields
	    if (accountCategory === 'loan' || accountCategory === 'cc') {
	        clearLoanFields();
	        resetLoanReceivedFields();
	    }

	    // Refresh table + totals
	    refreshCreditAccountsTable();
	    updateTotals();
	}

function refreshCreditAccountsTable() {
    const container = document.getElementById('creditAccountsContainer');
    
    if (creditAccountsData.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #999; padding: 20px;">No transactions added yet</p>';
        return;
    }
    
	    let tableHTML = '<table style="width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 13px;">' +
		    '<thead>' +
		    '<tr style="background-color: #373279; color: white;">' +
		    '<th style="padding: 6px 8px; text-align: left; border: 1px solid #ddd;">OP Type</th>' +
		    '<th style="padding: 6px 8px; text-align: left; border: 1px solid #ddd;">Account Code</th>' +
		    '<th style="padding: 6px 8px; text-align: left; border: 1px solid #ddd;">Account Name</th>' +
		    '<th style="padding: 6px 8px; text-align: right; border: 1px solid #ddd;">Amount</th>' +
		    '<th style="padding: 6px 8px; text-align: left; border: 1px solid #ddd;">Particular</th>' +
		    '<th style="padding: 6px 8px; text-align: center; border: 1px solid #ddd; width: 60px;">Action</th>' +
		    '</tr>' +
		    '</thead>' +
		    '<tbody>';
		
		creditAccountsData.forEach(function(account) {
		const rowBgColor = account.opType === 'Debit' ? '#FF4D0F' : '#3AD330';
		
		tableHTML += '<tr style="background-color:' + rowBgColor + '; color:white; line-height:1.2;">' +
		     '<td style="padding:4px 6px; border:1px solid #ddd; font-weight:bold;">' + account.opType + '</td>' +
		     '<td style="padding:4px 6px; border:1px solid #ddd; cursor:pointer; text-decoration:underline;" ' +
		     'onclick="loadAccountInTransferForm(\'' + account.code + '\', \'' + account.name.replace(/'/g, "\\'") + '\', \'' + account.opType + '\')">' +
		     account.code + '</td>' +
		     '<td style="padding:4px 6px; border:1px solid #ddd;">' + account.name + '</td>' +
		     '<td style="padding:4px 6px; border:1px solid #ddd; text-align:right; font-weight:bold;">₹ ' + account.amount + '</td>' +
		     '<td style="padding:4px 6px; border:1px solid #ddd;">' + (account.particular || '-') + '</td>' +
		     '<td style="padding:4px 6px; border:1px solid #ddd; text-align:center;">' +
		     '<button type="button" onclick="removeCreditAccount(' + account.id + ')" ' +
		     ' class="remove-btn" style="padding:2px 6px; font-size:14px;">×</button>' +
		     '</td>' +
		     '</tr>';
		});
	
	tableHTML += '</tbody></table>';

    
    container.innerHTML = tableHTML;
	}
	
	function removeCreditAccount(accountId) {
	    // Find the account being removed
	    const removedAccount = creditAccountsData.find(acc => acc.id === accountId);
	    
	    // Remove from array
	    creditAccountsData = creditAccountsData.filter(acc => acc.id !== accountId);
	    refreshCreditAccountsTable();
	    updateTotals();
	    
	    // ✅ Check if removed account's data is currently displayed
	    if (removedAccount) {
	        const currentAccountCode = document.getElementById('accountCode').value;
	        const iframe = document.getElementById('resultFrame');
	        const iframeSrc = iframe.src || '';
	        const accountCategory = document.getElementById('accountCategory').value;
	        
	        // ✅ Clear transaction form AND loan fields if removed account matches current account
	        if (currentAccountCode === removedAccount.code) {
	            // Clear main transaction form fields
	            document.getElementById('accountCode').value = '';
	            document.getElementById('accountName').value = '';
	            document.getElementById('transactionamount').value = '';
	            document.getElementById('particular').value = '';
	            previousAccountCode = '';
	            
	            // Clear loan fields if it's a loan/cc account
	            if (accountCategory === 'loan' || accountCategory === 'cc') {
	                clearLoanFields();
	                resetLoanReceivedFields();
	            }
	            
	            // Clear iframe
	            clearIframe();
	        }
	        // ✅ Also clear iframe if the removed account code is in the iframe URL (but not current form)
	        else if (iframeSrc.includes(encodeURIComponent(removedAccount.code))) {
	            clearIframe();
	        }
	    }
	}


function updateTotals() {
    let totalDebit = 0;
    let totalCredit = 0;

    creditAccountsData.forEach(function (row) {
        const amount = parseFloat(row.amount) || 0;

        if (row.opType === 'Debit') {
            totalDebit += amount;
        } else if (row.opType === 'Credit') {
            totalCredit += amount;
        }
    });

    document.getElementById('totalDebit').value = totalDebit.toFixed(2);
    document.getElementById('totalCredit').value = totalCredit.toFixed(2);

    // Optional: highlight when balanced
    const talliedMessage = document.getElementById('talliedMessage');
    if (totalDebit === totalCredit && totalDebit > 0) {
        document.getElementById('totalDebit').style.borderColor = 'green';
        document.getElementById('totalCredit').style.borderColor = 'green';
        
        // Show "Transaction tallied" message
        if (talliedMessage) {
            talliedMessage.style.display = 'block';
        }
    } else {
        document.getElementById('totalDebit').style.borderColor = '#C8B7F6';
        document.getElementById('totalCredit').style.borderColor = '#C8B7F6';
        
        // Hide message
        if (talliedMessage) {
            talliedMessage.style.display = 'none';
        }
    }
}

function loadAccountInTransferForm(accountCode, accountName, opType) {
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    const accountCategory = document.getElementById('accountCategory').value;

    if (operationType !== 'transfer') {
        showToast('This feature only works in transfer mode', 'warning');
        return;
    }

    // ✅ Get txnAmount for this account from creditAccountsData
    const transaction = creditAccountsData.find(acc => acc.code === accountCode);
    const txnAmount = transaction ? parseFloat(transaction.amount) || 0 : 0;

    // Build URL with parameters
    let url = 'transferForm.jsp?';
    url += 'operationType=' + encodeURIComponent(operationType);
    url += '&accountCategory=' + encodeURIComponent(accountCategory);
    url += '&txnAmount=' + txnAmount; // ✅ Pass amount to iframe

    if (opType === 'Debit') {
        url += '&accountCode=' + encodeURIComponent(accountCode);
        url += '&accountName=' + encodeURIComponent(accountName);
        url += '&creditAccountCode=';
        url += '&creditAccountName=';
    } else {
        url += '&accountCode=';
        url += '&accountName=';
        url += '&creditAccountCode=' + encodeURIComponent(accountCode);
        url += '&creditAccountName=' + encodeURIComponent(accountName);
    }

    // Load in iframe
    const iframe = document.getElementById('resultFrame');
    iframe.src = url;

    // Handle loan/cc account restore
    if (accountCategory === 'loan' || accountCategory === 'cc') {
        iframe.onload = function() {
            if (transaction) {
                document.getElementById('transactionamount').value = transaction.amount;

                setTimeout(() => {
                    fetchLoanReceivableData(accountCode);

                    setTimeout(() => {
                        if (transaction.loanFields) {
                            for (const fieldName in transaction.loanFields) {
                                const fieldData = transaction.loanFields[fieldName];
                                const receivableEl = document.getElementById(fieldName + 'Receivable');
                                const receivedEl   = document.getElementById(fieldName + 'Received');
                                const remainingEl  = document.getElementById(fieldName + 'Remaining');
                                if (receivableEl) receivableEl.value = fieldData.receivable || '';
                                if (receivedEl)   receivedEl.value   = fieldData.received   || '';
                                if (remainingEl)  remainingEl.value  = fieldData.remaining  || '';
                            }
                        }
                    }, 500);
                }, 1000);
            }
            iframe.onload = null;
        };
    }
}
	const opTypeSelect = document.getElementById('opType');

	function updateOpTypeBackground() {
	    opTypeSelect.classList.remove('debit-bg', 'credit-bg');

	    if (opTypeSelect.value === 'Debit') {
	        opTypeSelect.classList.add('debit-bg');
	    } else {
	        opTypeSelect.classList.add('credit-bg');
	    }
	}

	opTypeSelect.addEventListener('change', updateOpTypeBackground);
	updateOpTypeBackground();
	
	// ========== DYNAMIC LOAN FIELDS ==========
	let loanRecoveryColumns = [];
	let closingSequenceColumns = [];

	// Fetch loan recovery columns from database
	function fetchLoanRecoveryColumns() {
	    fetch('GetLoanRecoveryColumns.jsp')
	        .then(response => response.json())
	        .then(data => {
	            if (data.success && data.columns && data.columns.length > 0) {
	                loanRecoveryColumns = data.columns;
	                buildLoanFieldsTable();
	            } else {
	                showToast('Failed to load loan recovery columns', 'error');
	                console.error('Error:', data.error || 'No columns found');
	            }
	        })
	        .catch(error => {
	            console.error('Error fetching loan recovery columns:', error);
	            showToast('Failed to load loan recovery columns', 'error');
	        });
	}

	// Build the dynamic loan fields table
function buildLoanFieldsTable() {
    const loader = document.getElementById('loanFieldsLoader');
    const tableContainer = document.getElementById('loanFieldsTableContainer');
    const headerRow = document.getElementById('loanTableHeader');
    const tableBody = document.getElementById('loanTableBody');
    
    if (!loanRecoveryColumns || loanRecoveryColumns.length === 0) {
        loader.innerHTML = '<p style="color: #f44336;">No loan recovery columns configured</p>';
        return;
    }
    
    // Hide loader and show table
    loader.style.display = 'none';
    tableContainer.style.display = 'block';
    
    // Build table headers - ADD PRINCIPLE COLUMN
    let headerHTML = '<tr><th>Type</th>';
    loanRecoveryColumns.forEach(col => {
        // Safety check for undefined/null values
        if (!col || !col.description) {
            console.warn('Skipping invalid column:', col);
            return;
        }
        
        // Truncate long descriptions for display
        const displayName = col.description.length > 10 
            ? col.description.substring(0, 20) 
            : col.description;
        headerHTML += '<th title="' + escapeHtml(col.description) + '">' + escapeHtml(displayName) + '</th>';
    });
	headerHTML += '<th>Principle</th>'; // ✅ NEW: Principle column header
	headerHTML += '<th>Total</th>';
    headerHTML += '</tr>';
    headerRow.innerHTML = headerHTML;
    
	/* ================= ROWS ================= */
	let receivableRow = '<tr class="receivable-row"><td>Receivable</td>';
	let receivedRow   = '<tr class="received-row"><td>Received</td>';
	let remainingRow  = '<tr class="remaining-row"><td>Remaining</td>';
    
    loanRecoveryColumns.forEach(col => {
        // Safety check for undefined/null values
        if (!col || !col.columnName) {
            console.warn('Skipping invalid column:', col);
            return;
        }
        
        const fieldName = col.columnName.toLowerCase().trim();
		if (fieldName === 'principal') return;
        // Skip if fieldName is empty
        if (!fieldName) {
            console.warn('Empty fieldName for column:', col);
            return;
        }
        
        // Receivable row (readonly)
        receivableRow += '<td><input type="text" name="' + fieldName + 'Receivable" ' +
                        'id="' + fieldName + 'Receivable" placeholder="0.00" readonly></td>';
        
        // Received row (editable with oninput)
        receivedRow += '<td><input type="text" name="' + fieldName + 'Received" ' +
                      'id="' + fieldName + 'Received" placeholder="0.00" ' +
                      'oninput="calculateRemaining(\'' + fieldName + '\')"></td>';
        
        // Remaining row (readonly)
        remainingRow += '<td><input type="text" id="' + fieldName + 'Remaining" ' +
                       'placeholder="0.00" readonly></td>';
    });
    
	
	receivableRow += '<td><input type="text" id="principleReceivable" placeholder="0.00" readonly style="background-color: #e6ffe6;"></td>';
	receivedRow   += '<td><input type="text" id="principleReceived" placeholder="0.00" readonly style="background-color: #e6ffe6; font-weight: bold; color: #2e7d32;"></td>';
	remainingRow  += '<td><input type="text" id="principleRemaining" placeholder="0.00" readonly style="background-color: #e6ffe6;"></td>';
	
	
	receivableRow += '<td><input type="text" id="totalReceivable" placeholder="0.00" readonly></td>';
	receivedRow   += '<td><input type="text" id="totalReceived" placeholder="0.00"></td>';
	remainingRow  += '<td><input type="text" id="totalRemaining"  placeholder="0.00" readonly></td>';
		
    receivableRow += '</tr>';
    receivedRow += '</tr>';
    remainingRow += '</tr>';
    
    tableBody.innerHTML = receivableRow + receivedRow + remainingRow;
}

function buildClosingFieldsTable() {
    const loader = document.getElementById('closingFieldsLoader');
    const tableContainer = document.getElementById('closingFieldsTableContainer');
    const headerRow = document.getElementById('closingTableHeader');
    const tableBody = document.getElementById('closingTableBody');
    
    if (!closingSequenceColumns || closingSequenceColumns.length === 0) {
        loader.innerHTML = '<p style="color: #f44336;">No closing sequence columns configured</p>';
        return;
    }
    
    // Hide loader and show table
    loader.style.display = 'none';
    tableContainer.style.display = 'block';
    
    // Build table headers
    let headerHTML = '<tr><th>Type</th>';
    closingSequenceColumns.forEach(col => {
        if (!col || !col.description) {
            console.warn('Skipping invalid column:', col);
            return;
        }
        
        const displayName = col.description.length > 10 
            ? col.description.substring(0, 20) 
            : col.description;
        headerHTML += '<th title="' + escapeHtml(col.description) + '">' + escapeHtml(displayName) + '</th>';
    });
    headerHTML += '</tr>';
    headerRow.innerHTML = headerHTML;
    
    // Build table rows (Receivable, Received, Remaining)
    let receivableRow = '<tr class="receivable-row"><td>Receivable</td>';
    let receivedRow   = '<tr class="received-row"><td>Received</td>';
    let remainingRow  = '<tr class="remaining-row"><td>Remaining</td>';
    
    closingSequenceColumns.forEach(col => {
        if (!col || !col.columnName) {
            console.warn('Skipping invalid column:', col);
            return;
        }
        
        const fieldName = col.columnName.toLowerCase().trim();
        
        if (!fieldName) {
            console.warn('Empty fieldName for column:', col);
            return;
        }
        
        // Receivable row (readonly)
        receivableRow += '<td><input type="text" name="' + fieldName + 'Receivable" ' +
                        'id="closing_' + fieldName + 'Receivable" placeholder="0.00" readonly></td>';
        
        // Received row (editable)
        receivedRow += '<td><input type="text" name="' + fieldName + 'Received" ' +
                      'id="closing_' + fieldName + 'Received" placeholder="0.00" ' +
                      'oninput="calculateClosingRemaining(\'' + fieldName + '\')"></td>';
        
        // Remaining row (readonly)
        remainingRow += '<td><input type="text" id="closing_' + fieldName + 'Remaining" ' +
                       'placeholder="0.00" readonly></td>';
    });
    
    receivableRow += '</tr>';
    receivedRow += '</tr>';
    remainingRow += '</tr>';
    
    tableBody.innerHTML = receivableRow + receivedRow + remainingRow;
}

// Helper function to escape HTML (add this if not already present)
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}



function fetchLoanReceivableData(accountCode) {
    if (!accountCode || accountCode.trim() === '') {
        return;
    }
    
    fetch('GetLoanReceivableData.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showToast('Error loading loan data: ' + data.error, 'error');
                console.error('Error:', data.error);
                return;
            }
            
            if (data.success && data.receivableData) {
                populateLoanReceivableFields(data.receivableData);
            }
        })
        .catch(error => {
            console.error('Error fetching loan receivable data:', error);
            showToast('Failed to fetch loan receivable data', 'error');
        });
}

function fetchClosingSequenceColumns() {
    
    const accountCategory = document.getElementById('accountCategory').value;
    
    // ✅ MODIFY FETCH URL 
    fetch('GetClosingSequenceColumns.jsp?accountType=' + encodeURIComponent(accountCategory))
        .then(response => response.json())
        .then(data => {
            if (data.success && data.columns && data.columns.length > 0) {
                closingSequenceColumns = data.columns;
                buildClosingFieldsTable();
            } else {
                showToast('Failed to load closing sequence columns', 'error');
                console.error('Error:', data.error || 'No columns found');
            }
        })
        .catch(error => {
            console.error('Error fetching closing sequence columns:', error);
            showToast('Failed to load closing sequence columns', 'error');
        });
}

function populateLoanReceivableFields(receivableData) {
    let totalReceivable = 0;

    for (const fieldName in receivableData) {
        if (fieldName === 'principal') continue;

        const receivableField = document.getElementById(fieldName + 'Receivable');
        const value = parseFloat(receivableData[fieldName]) || 0;

        if (receivableField) {
            receivableField.value = value.toFixed(2);
            totalReceivable += value;
        }

        calculateRemaining(fieldName);
    }

	const totalReceivableField = document.getElementById('totalReceivable');
	if (totalReceivableField) {
	    totalReceivableField.value = totalReceivable.toFixed(2);
	}

	calculateRemaining('total');
	
	// ✅ UPDATE PRINCIPLE RECEIVED AFTER POPULATING
	updatePrincipleReceived();
}


//Updated clearLoanFields to work with dynamic fields
function clearLoanFields() {
    if (!loanRecoveryColumns || loanRecoveryColumns.length === 0) {
        return;
    }
    
    loanRecoveryColumns.forEach(col => {
        // Safety check
        if (!col || !col.columnName) {
            return;
        }
        
        const fieldName = col.columnName.toLowerCase().trim();
        
        // Skip if fieldName is empty
        if (!fieldName) {
            return;
        }
        
        ['Receivable', 'Received', 'Remaining'].forEach(suffix => {
            const el = document.getElementById(fieldName + suffix);
            if (el) {
                el.value = '';
                el.style.color = '';
                el.style.fontWeight = '';
            }
        });
    });
	
	//  Clear total fields
	    const totalReceivable = document.getElementById('totalReceivable');
	    const totalReceived = document.getElementById('totalReceived');
	    const totalRemaining = document.getElementById('totalRemaining');
	    
	    if (totalReceivable) totalReceivable.value = '';
	    if (totalReceived) totalReceived.value = '';
	    if (totalRemaining) totalRemaining.value = '';
	    
	    // Clear principle received field
	    const principleReceivedField = document.getElementById('principleReceived');
	    if (principleReceivedField) {
	        principleReceivedField.value = '';
	    }
	}



function calculateSequentialLoanDeduction() {
    const transactionAmountInput = document.getElementById('transactionamount');
    const transactionAmount = parseFloat(transactionAmountInput.value) || 0;
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    const accountCategory = document.getElementById('accountCategory').value;
    
    // Only proceed if it's a deposit or (transfer with credit OP Type)
    const opType = document.getElementById('opType') ? document.getElementById('opType').value : '';
    const shouldProcess = (operationType === 'deposit') || 
                         (operationType === 'transfer' && opType === 'Credit');
    
    if (!shouldProcess || (accountCategory !== 'loan' && accountCategory !== 'cc')) {
        return;
    }
    
    // ✅ ALWAYS CLEAR ALL RECEIVED FIELDS FIRST (even if amount is 0)
    if (loanRecoveryColumns && loanRecoveryColumns.length > 0) {
        loanRecoveryColumns.forEach(col => {
            if (!col || !col.columnName) return;
            const fieldName = col.columnName.toLowerCase().trim();
            if (!fieldName) return;
            
            const receivedEl = document.getElementById(fieldName + 'Received');
            if (receivedEl) {
                receivedEl.value = '';
                receivedEl.style.backgroundColor = '';
                receivedEl.style.fontWeight = '';
            }
            
            // ✅ Also recalculate remaining to show full receivable
            calculateRemaining(fieldName);
        });
    }
    
    // ✅ If transaction amount is 0 or empty, stop here (don't recalculate)
    if (transactionAmount <= 0) {
        return;
    }
    
    let remainingAmount = transactionAmount;
    
    // Process each loan column sequentially
    if (loanRecoveryColumns && loanRecoveryColumns.length > 0) {
        for (let i = 0; i < loanRecoveryColumns.length; i++) {
            const col = loanRecoveryColumns[i];
            if (!col || !col.columnName) continue;
            
            const fieldName = col.columnName.toLowerCase().trim();
            if (!fieldName) continue;
            
            const receivableEl = document.getElementById(fieldName + 'Receivable');
            const receivedEl = document.getElementById(fieldName + 'Received');
            const remainingEl = document.getElementById(fieldName + 'Remaining');
            
            if (!receivableEl || !receivedEl || !remainingEl) continue;
            
            // Get receivable and current received values
            const receivable = parseFloat(receivableEl.value.replace(/,/g, '')) || 0;
            const currentReceived = parseFloat(receivedEl.value.replace(/,/g, '')) || 0;
            const outstanding = receivable - currentReceived;
            
            if (outstanding > 0 && remainingAmount > 0) {
                // Calculate how much to deduct from this field
                const deductionAmount = Math.min(outstanding, remainingAmount);
                const newReceived = currentReceived + deductionAmount;
                
                // Update the received field
                receivedEl.value = newReceived.toFixed(2);
                
                // Recalculate remaining
                calculateRemaining(fieldName);
                
                // Reduce remaining amount
                remainingAmount -= deductionAmount;
                
                // Highlight the updated field
                receivedEl.style.backgroundColor = '#e6f7ff';
                receivedEl.style.fontWeight = 'bold';
                
                setTimeout(() => {
                    receivedEl.style.backgroundColor = '';
                }, 2000);
            }
            
            // If no remaining amount, stop processing
            if (remainingAmount <= 0) {
                break;
            }
        }
    }
    
	let lastToastMessage = '';
	let lastToastTime = 0;
	// If there's still remaining amount, deduct from ledger balance
	    if (remainingAmount > 0) {
	        const iframe = document.getElementById('resultFrame');
	        
	        try {
	            const iframeWindow = iframe.contentWindow;
	            const iframeDoc = iframeWindow.document;
	            
	            const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
	            const newLedgerBalanceField = iframeDoc.getElementById('newLedgerBalance');
	            
	            if (ledgerBalanceField && newLedgerBalanceField) {
	                const ledgerBalance = parseFloat(ledgerBalanceField.value) || 0;
	                const newLedgerBalance = ledgerBalance + remainingAmount;
	                
	                newLedgerBalanceField.value = newLedgerBalance.toFixed(2);
	                
	                // Highlight ledger balance update
	                newLedgerBalanceField.style.backgroundColor = '#e6f7ff';
	                newLedgerBalanceField.style.fontWeight = 'bold';
	                
	                setTimeout(() => {
	                    newLedgerBalanceField.style.backgroundColor = '';
	                }, 2000);
	                
	                // ✅ PREVENT DUPLICATE TOASTS
	                const message = '₹' + remainingAmount.toFixed(2) + ' applied to Ledger Balance after loan recovery deductions';
	                const now = Date.now();
	                
	                // Only show toast if message is different or enough time has passed (500ms)
	                if (lastToastMessage !== message || (now - lastToastTime) > 500) {
	                    showToast(message, 'info');
	                    lastToastMessage = message;
	                    lastToastTime = now;
	                }
	                
	                remainingAmount = 0;
	            }
	        } catch (e) {
	            console.error('Error updating ledger balance:', e);
	        }
	    }
    // If there's STILL remaining amount (shouldn't happen normally), alert user
    if (remainingAmount > 0) {
        showToast('WARNING: ₹' + remainingAmount.toFixed(2) + ' remaining after all deductions!', 'warning');
    }
}


function resetLoanReceivedFields() {
    if (!loanRecoveryColumns || loanRecoveryColumns.length === 0) return;
    
    loanRecoveryColumns.forEach(col => {
        if (!col || !col.columnName) return;
        
        const fieldName = col.columnName.toLowerCase().trim();
        if (!fieldName) return;
        
        const receivedEl = document.getElementById(fieldName + 'Received');
        if (receivedEl) {
            receivedEl.value = '';
            receivedEl.style.backgroundColor = '';
            receivedEl.style.fontWeight = '';
        }
        
        calculateRemaining(fieldName);
    });
	
	// ✅ Clear principle received field when resetting
	const principleReceivedField = document.getElementById('principleReceived');
	if (principleReceivedField) {
	    principleReceivedField.value = '0.00';
	}
}

// Call this when transaction amount is cleared or changed significantly
function handleTransactionAmountChange() {
    const transactionAmount = parseFloat(document.getElementById('transactionamount').value) || 0;
    
    if (transactionAmount === 0) {
        // Reset all loan received fields if amount is cleared
        resetLoanReceivedFields();
    }
    
    calculateNewBalanceInIframe();
    updateTotals();
}

// Handle transaction amount changes (only on blur/enter)
function handleTransactionAmountFinalized() {
    calculateNewBalanceInIframe();
    updateTotals();
}

 function updateParticularField() {
    const operationType = document.querySelector("input[name='operationType']:checked").value;
    const particularField = document.getElementById('particular');
    
    if (!particularField) return;
    
    // Only auto-fill if the field is empty
    if (particularField.value.trim() !== '') return;
    
    if (operationType === 'deposit') {
        particularField.value = 'By Cash';
    } else if (operationType === 'withdrawal') {
        particularField.value = 'To Cash';
    } else if (operationType === 'transfer') {
        const opType = document.getElementById('opType').value;
        if (opType === 'Debit') {
            particularField.value = 'To Transfer';
        } else	if (opType === 'Credit') {
			 particularField.value = 'By Transfer';
		}
    }
}

// ========== HANDLE TRANSACTION TYPE CHANGE (REGULAR/CLOSING) ==========
function handleTransactionTypeChange() {
    const transactionType = document.querySelector("input[name='transactionTypeRadio']:checked").value;
    
    // Get elements to hide/show
    const operationTypeSection = document.querySelector('.radio-group-inline:has(input[name="operationType"])');
    const transferFieldsSection = document.getElementById('transferFieldsSection');
    const loanFieldsSection = document.getElementById('loanFieldsSection');
    const creditAccountsContainer = document.getElementById('creditAccountsContainer');
    const addButtonParent = document.querySelector('.add-btn') ? document.querySelector('.add-btn').parentElement : null;
    const transactionAmountDiv = document.querySelector('#transactionamount') ? document.querySelector('#transactionamount').closest('div') : null;
    
    if (transactionType === 'closing') {
        // ========== CLOSING MODE ==========
        
        // Hide elements for closing transaction
        if (transferFieldsSection) transferFieldsSection.classList.remove('active');
        if (loanFieldsSection) loanFieldsSection.classList.remove('active');
        if (creditAccountsContainer) creditAccountsContainer.style.display = 'none';
        if (addButtonParent) addButtonParent.style.display = 'none';

        // ✅ Hide cheque fields in closing mode
        const chequeFieldsRow = document.getElementById('chequeFieldsRow');
        if (chequeFieldsRow) chequeFieldsRow.classList.remove('active');
        clearChequeFields();

		// Show closing fields section
		    const closingFieldsSection = document.getElementById('closingFieldsSection');
		    if (closingFieldsSection) {
		        closingFieldsSection.classList.add('active');
		        
		        // Fetch columns if not already loaded
		        if (closingSequenceColumns.length === 0) {
		            fetchClosingSequenceColumns();
		        }
		    }
        
        // Clear iframe
        clearIframe();
        
        // Clear inputs
        document.getElementById('accountCode').value = '';
        document.getElementById('accountName').value = '';
        if (document.getElementById('transactionamount')) {
            document.getElementById('transactionamount').value = '';
        }
        document.getElementById('particular').value = '';
        previousAccountCode = '';
        
        // Clear transaction data
        creditAccountsData = [];
        refreshCreditAccountsTable();
        
        // Clear loan fields if they were active
        clearLoanFields();
        resetLoanReceivedFields();
        
        // Clear closing fields
        clearClosingFields();
        
    } else {
        // ========== REGULAR MODE ==========
        
        // Show operation type section
        if (operationTypeSection) operationTypeSection.style.display = 'flex';
        
        // Show add button and transaction amount
        if (addButtonParent) addButtonParent.style.display = 'flex';
        if (transactionAmountDiv) transactionAmountDiv.style.display = 'block';
        
        // Show credit accounts container
        if (creditAccountsContainer) creditAccountsContainer.style.display = 'block';
        
		const closingFieldsSection = document.getElementById('closingFieldsSection');
		   if (closingFieldsSection) closingFieldsSection.classList.remove('active');
        
        // Clear inputs when switching back to regular
        document.getElementById('accountCode').value = '';
        document.getElementById('accountName').value = '';
        if (document.getElementById('transactionamount')) {
            document.getElementById('transactionamount').value = '';
        }
        document.getElementById('particular').value = '';
        previousAccountCode = '';
        
        // Clear iframe
        clearIframe();
        
        // Clear transaction data
        creditAccountsData = [];
        refreshCreditAccountsTable();
        updateTotals();
        
        // Clear loan fields
        clearLoanFields();
        resetLoanReceivedFields();

        // ✅ Clear cheque fields when switching to regular mode
        clearChequeFields();
        
        // ✅ IMPORTANT: Re-evaluate visibility based on current selections
        const currentOperationType = document.querySelector("input[name='operationType']:checked").value;
        const accountCategory = document.getElementById('accountCategory').value;
        
        // Show/hide transfer fields based on operation type
        if (currentOperationType === 'transfer') {
            if (transferFieldsSection) transferFieldsSection.classList.add('active');
        } else {
            if (transferFieldsSection) transferFieldsSection.classList.remove('active');
        }
        
        // Show/hide loan fields based on account category
        if (accountCategory === 'loan' || accountCategory === 'cc') {
            if (loanFieldsSection) loanFieldsSection.classList.add('active');
        } else {
            if (loanFieldsSection) loanFieldsSection.classList.remove('active');
        }

        // ✅ Re-evaluate cheque fields visibility
        toggleChequeFields();
        
        // Update labels and other UI elements
        updateLabelsBasedOnOperation();
        updateParticularField();
    }
}



// Clear closing fields
function clearClosingFields() {
    const closingFields = [
        'closingLedgerBalance',
        'closingAvailableBalance',
        'closingTransactionAmount',
        'closingInterest',
        'closingBalance',
        'againstEffectInt',
        'todInterest',
        'serviceCharges',
        'otherCharges',
        'serviceTax'
    ];
    
    closingFields.forEach(fieldId => {
        const field = document.getElementById(fieldId);
        if (field) {
            field.value = '';
        }
    });
}

// Populate closing fields from iframe
function populateClosingFieldsFromIframe() {
    const accountCode = document.getElementById('accountCode').value;
    
    if (!accountCode) {
        showToast('Please select an account first', 'error');
        return;
    }
    
    const iframe = document.getElementById('resultFrame');
    
    try {
        const iframeWindow = iframe.contentWindow;
        const iframeDoc = iframeWindow.document;
        
        const ledgerBalanceField = iframeDoc.getElementById('ledgerBalance');
        const availableBalanceField = iframeDoc.getElementById('availableBalance');
        
        if (ledgerBalanceField && availableBalanceField) {
            const ledgerBalance = ledgerBalanceField.value || '0.00';
            const availableBalance = availableBalanceField.value || '0.00';
            
            document.getElementById('closingLedgerBalance').value = ledgerBalance;
            document.getElementById('closingAvailableBalance').value = availableBalance;
            
            
            showToast('Account details loaded successfully', 'success');
        } else {
            showToast('Could not fetch account details from iframe', 'error');
        }
    } catch (e) {
        console.error('Error reading iframe:', e);
        showToast('Error reading account details. Please wait for the page to load completely.', 'error');
    }
}

// Save loan recovery transactions - MODIFIED WITH AUTHORIZATION MODAL
function saveLoanRecoveryTransactions(accountCode, sessionWorkingDate) {
    const formData = new URLSearchParams();
    formData.append('accountCode', accountCode);
    formData.append('accountCategory', 'loan');
    formData.append('operationType', 'deposit');
    

    loanRecoveryColumns.forEach(function(col) {
        if (!col || !col.columnName) return;
        const fieldName = col.columnName.toLowerCase().trim();
        if (!fieldName) return;
        
        const receivedEl = document.getElementById(fieldName + 'Received');
        if (receivedEl && receivedEl.value) {
            formData.append(fieldName + 'Received', receivedEl.value);
        }
    });
    

    const principleReceivedEl = document.getElementById('principleReceived');
    if (principleReceivedEl && principleReceivedEl.value && parseFloat(principleReceivedEl.value) > 0) {
        formData.append('principleReceived', principleReceivedEl.value);
        console.log('Adding principle amount to save:', principleReceivedEl.value);
    }
    
    // Call servlet
    fetch('SaveTransactionServlet', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.toString()
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            showToast('❌ Error: ' + data.error, 'error');
        } else if (data.success) {
            // ✅ SHOW AUTHORIZATION MODAL INSTEAD OF TOAST
            showAuthorizationModal(accountCode, data.scrollNumber, 'loan');
            
            // Clear form
            document.getElementById('accountCode').value = '';
            document.getElementById('accountName').value = '';
            document.getElementById('transactionamount').value = '';
            previousAccountCode = '';
            clearIframe();
            clearLoanFields();
            resetLoanReceivedFields();
        }
    })
    .catch(error => {
        console.error('Save error:', error);
        showToast('❌ Failed to save transactions', 'error');
    });
}

// ========== AUTHORIZATION MODAL FUNCTIONS ==========
function showAuthorizationModal(accountCode, scrollNumber, transactionType) {
    const modal = document.getElementById('authorizationModal');
    const messageDisplay = document.getElementById('authMessage');
    const scrollDisplay = document.getElementById('authScrollNumber');
    
    // Build the success message based on transaction type
    let message = 'Transaction saved successfully!';
    
    if (transactionType === 'transfer') {
        message = 'All transfer transactions saved successfully!';
    } else if (transactionType === 'loan') {
        message = 'Loan recovery transactions saved successfully!';
    }
    
    // Display the message and scroll number
    messageDisplay.textContent = message;
    scrollDisplay.textContent = 'Scroll Number: ' + scrollNumber;
    
    modal.style.display = 'flex';
}

function closeAuthorizationModal() {
    const modal = document.getElementById('authorizationModal');
    modal.style.display = 'none';
}

// ========== VOUCHER MODAL FUNCTIONS ==========

// Store scroll number for voucher popup
let voucherScrollNumber = null;

function showVoucherPopup() {
    // Get scroll number from modal
    const scrollText = document.getElementById('authScrollNumber').textContent;
    voucherScrollNumber = scrollText.replace('Scroll Number: ', '').trim();
    
    const sessionWorkingDate = typeof workingDate !== 'undefined' ? workingDate : 
        new Date().toLocaleDateString('en-GB').replace(/\//g, '/');
    
    // Fetch voucher data
    fetchVoucherData(voucherScrollNumber, sessionWorkingDate);
    
    // Show voucher modal
    document.getElementById('voucherModal').style.display = 'flex';
}

function closeVoucherModal() {
    document.getElementById('voucherModal').style.display = 'none';
}

function fetchVoucherData(scrollNumber, workingDate) {
    const tableContainer = document.getElementById('voucherTableContainer');
    tableContainer.innerHTML = '<p style="text-align: center; color: #8066E8;">Loading voucher data...</p>';
    
    const params = new URLSearchParams({
        scrollNumber: scrollNumber,
        workingDate: workingDate
    });
    
    fetch('GetDailyScrollData.jsp?' + params.toString())
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                tableContainer.innerHTML = '<p style="color: #e74c3c; text-align: center;">Error: ' + data.error + '</p>';
                return;
            }
            
            if (data.rows && data.rows.length > 0) {
                displayVoucherTable(data.rows);
            } else {
                tableContainer.innerHTML = '<p style="color: #7f8c8d; text-align: center;">No voucher records found</p>';
            }
        })
        .catch(error => {
            console.error('Error fetching voucher data:', error);
            tableContainer.innerHTML = '<p style="color: #e74c3c; text-align: center;">Failed to load voucher data</p>';
        });
}

function displayVoucherTable(rows) {
    let html = '<table style="width: 100%; border-collapse: collapse; border: 1px solid #ddd;">';
    
    // Table header
    html += '<thead style="background-color: #373279; color: white; font-size: 12px;">';
    html += '<tr>';
    html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 5%;">SR NO</th>';
    html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 10%;">SCROLL NO</th>';
    html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 8%;">SUB SR</th>';
    html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 12%;">ACCOUNT CODE</th>';
    html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 12%;">FOR ACCOUNT CODE</th>';
    html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 10%;">TRANSACTION INDICATOR</th>';
    html += '<th style="padding: 12px; text-align: right; border: 1px solid #ddd; width: 10%;">AMOUNT</th>';
    html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd; width: 20%;">PARTICULAR</th>';
    html += '</tr>';
    html += '</thead>';
    
    // Table body
    html += '<tbody>';
    
    rows.forEach(function(row, index) {
        const bgColor = index % 2 === 0 ? '#f9f9f9' : '#ffffff';
        const amount = parseFloat(row.amount) || 0;
        
        html += '<tr style="background-color: ' + bgColor + '; font-size: 14px;">';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + row.srNo + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + row.scrollNumber + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + row.subscrollNumber + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center; font-weight: bold;">' + row.accountCode + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center; font-weight: bold;">' + (row.forAccountCode || '-') + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + (row.transactionIndicator || '-') + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: right; font-weight: bold;">₹ ' + amount.toFixed(2) + '</td>';
        html += '<td style="padding: 10px; border: 1px solid #ddd;">' + (row.particular || '-') + '</td>';
        html += '</tr>';
    });
    
    html += '</tbody>';
    html += '</table>';
    
    document.getElementById('voucherTableContainer').innerHTML = html;
}