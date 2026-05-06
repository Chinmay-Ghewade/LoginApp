//==================== CUSTOMER LOOKUP FUNCTIONS ====================

// ✅ MODIFY: Update setCustomerData to handle validation
window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
    // Check if this is for nominee lookup
    if (window.currentNomineeInput) {
        // Check if already used in other nominee blocks
        if (isCustomerUsedInSameFieldset(customerId, 'nominee', window.currentNomineeBlock)) {
            showToast('This customer is already added as another nominee!', 'error');
            return;
        }
        
        window.currentNomineeInput.value = customerId;
        fetchCustomerDetails(customerId, 'nominee', window.currentNomineeBlock);
        window.currentNomineeInput = null;
        window.currentNomineeBlock = null;
        closeCustomerLookup();
        return;
    }

    // Check if this is for joint holder lookup
    if (window.currentJointInput) {
        // Check if already used in other joint holder blocks
        if (isCustomerUsedInSameFieldset(customerId, 'joint', window.currentJointBlock)) {
            showToast('This customer is already added as another joint holder!', 'error');
            return;
        }
        
        window.currentJointInput.value = customerId;
        fetchCustomerDetails(customerId, 'joint', window.currentJointBlock);
        window.currentJointInput = null;
        window.currentJointBlock = null;
        closeCustomerLookup();
        return;
    }

    // Check if this is for Co-Borrower lookup
    if (window.currentCoBorrowerInput) {
        // Check if already used in other co-borrower blocks
        if (isCustomerUsedInSameFieldset(customerId, 'coborrower', window.currentCoBorrowerBlock)) {
            showToast('This customer is already added as another co-borrower!', 'error');
            return;
        }
        
        window.currentCoBorrowerInput.value = customerId;
        fetchCustomerDetails(customerId, 'coborrower', window.currentCoBorrowerBlock);
        window.currentCoBorrowerInput = null;
        window.currentCoBorrowerBlock = null;
        closeCustomerLookup();
        return;
    }

    // Check if this is for Guarantor lookup
    if (window.currentGuarantorInput) {
        // Check if already used in other guarantor blocks
        if (isCustomerUsedInSameFieldset(customerId, 'guarantor', window.currentGuarantorBlock)) {
            showToast('This customer is already added as another guarantor!', 'error');
            return;
        }
        
        window.currentGuarantorInput.value = customerId;
        fetchCustomerDetails(customerId, 'guarantor', window.currentGuarantorBlock);
        window.currentGuarantorInput = null;
        window.currentGuarantorBlock = null;
        closeCustomerLookup();
        return;
    }

    // ✅ This is for Application fieldset (main customer)
    // Clear old customer from other fieldsets if needed
    const oldCustomerId = document.getElementById('customerId').value.trim();
    if (oldCustomerId && oldCustomerId !== customerId) {
        const clearedCount = clearCustomerFromOtherFieldsets(oldCustomerId);
        if (clearedCount > 0) {
            showToast('Previous customer cleared from ' + clearedCount + ' other fieldset(s)', 'warning');
        }
    }
    
    // Set new customer in Application fieldset
    document.getElementById('customerId').value = customerId;
    document.getElementById('customerName').value = customerName;
    document.getElementById('categoryCode').value = categoryCode || '';
    document.getElementById('riskCategory').value = riskCategory || '';

    closeCustomerLookup();
};

//Fetch customer details from database
function fetchCustomerDetails(customerId, type, block) {
    console.log('🔍 Fetching customer details for:', customerId, 'Type:', type);

    fetch('getCustomerDetails.jsp?customerId=' + encodeURIComponent(customerId))
        .then(response => response.json())
        .then(data => {
            console.log('📦 Received data:', data);

            if (data.success) {
                if (type === 'nominee') {
                    populateNomineeFields(block, data.customer);
                } else if (type === 'joint') {
                    populateJointFields(block, data.customer);
                } else if (type === 'coborrower') {
                    populateCoBorrowerFields(block, data.customer);
                } else if (type === 'guarantor') {
                    populateGuarantorFields(block, data.customer);
                }
            } else {
                showToast('❌ Error: ' + (data.message || 'Failed to load customer data'), 'error');
            }
        })
        .catch(error => {
            console.error('❌ Error fetching customer details:', error);
            showToast('Failed to load customer data', 'error');
        });
}

// Helper function to set select value with multiple matching strategies
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
    console.log('🔧 Setting ' + fieldName + ' to: "' + trimmedValue + '"');

    let found = false;

    // Strategy 1: Try exact match on value (case-insensitive)
    for (let i = 0; i < selectElement.options.length; i++) {
        const optionValue = selectElement.options[i].value.trim().toUpperCase();
        if (optionValue === trimmedValue) {
            selectElement.selectedIndex = i;
            found = true;
            console.log('✅ ' + fieldName + ' set successfully (exact match) to: "' + trimmedValue + '"');
            return true;
        }
    }

    // Strategy 2: Try matching on text content
    for (let i = 0; i < selectElement.options.length; i++) {
        const optionText = selectElement.options[i].text.trim().toUpperCase();
        if (optionText.includes(trimmedValue) || trimmedValue.includes(optionText)) {
            selectElement.selectedIndex = i;
            found = true;
            console.log('✅ ' + fieldName + ' set successfully (text match) to: "' + selectElement.options[i].value + '"');
            return true;
        }
    }

    // Strategy 3: Try partial match on value
    for (let i = 0; i < selectElement.options.length; i++) {
        const optionValue = selectElement.options[i].value.trim().toUpperCase();
        if (optionValue.includes(trimmedValue) || trimmedValue.includes(optionValue)) {
            selectElement.selectedIndex = i;
            found = true;
            console.log('✅ ' + fieldName + ' set successfully (partial match) to: "' + selectElement.options[i].value + '"');
            return true;
        }
    }

    if (!found) {
        console.warn('⚠️ Value "' + trimmedValue + '" not found in ' + fieldName + ' dropdown');
        console.log('First 10 available options:');
        for (let i = 0; i < Math.min(10, selectElement.options.length); i++) {
            console.log('  [' + i + '] value="' + selectElement.options[i].value + '" text="' + selectElement.options[i].text + '"');
        }
    }

    return found;
}

// ........................COMMON FUNCTIONS............................

//Customer Lookup Functions with exclusion support
function openCustomerLookup(excludeCustomerId) {
    var excludeIds = [];

    // collect all currently used customer IDs
    var allUsed = getAllUsedCustomerIds();
    excludeIds = excludeIds.concat(allUsed);

    if (excludeCustomerId && excludeCustomerId.trim()) {
        excludeIds.push(excludeCustomerId.trim());
    }

    // Remove duplicates
    excludeIds = excludeIds.filter(function(v, i, a){ return a.indexOf(v) === i; });

    // Ask newApplication.jsp to open its modal
    window.parent.postMessage({
        type       : 'OPEN_CUSTOMER_LOOKUP',
        callbackId : 'mainCustomer',
        excludeIds : excludeIds
    }, '*');
}

function closeCustomerLookup() {
    document.getElementById('customerLookupModal').style.display = 'none';
}

window.onclick = function(event) {
    const modal = document.getElementById('customerLookupModal');
    if (event.target === modal) {
        closeCustomerLookup();
    }
};

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeCustomerLookup();
    }
});

// === HARD LOCK for SELECT fields (cannot open, cannot click, value still submits) ===
function lockSelect(field) {
    field.dataset.locked = "true"; // mark as locked

    field.addEventListener("mousedown", stopEvent, true);
    field.addEventListener("click", stopEvent, true);
    field.addEventListener("focus", stopEvent, true);
    field.addEventListener("keydown", stopEvent, true);

    field.style.backgroundColor = "#f0f0f0";
    field.style.cursor = "not-allowed";
}

function unlockSelect(field) {
    field.dataset.locked = "false";

    field.removeEventListener("mousedown", stopEvent, true);
    field.removeEventListener("click", stopEvent, true);
    field.removeEventListener("focus", stopEvent, true);
    field.removeEventListener("keydown", stopEvent, true);

    field.style.backgroundColor = "";
    field.style.cursor = "";
}

// Blocks dropdown from opening
function stopEvent(e) {
    if (e.target.dataset.locked === "true") {
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
    }
}
// === LOCK fetched fields ===
function makeFieldsReadOnly(block) {

    const fieldsToLock = [
        'select[name="nomineeSalutation[]"]',
        'input[name="nomineeName[]"]',
        'input[name="nomineeAddress1[]"]',
        'input[name="nomineeAddress2[]"]',
        'input[name="nomineeAddress3[]"]',
        'select[name="nomineeCountry[]"]',
        'select[name="nomineeState[]"]',
        'select[name="nomineeCity[]"]',
        'input[name="nomineeZip[]"]',

        'select[name="jointSalutation[]"]',
        'input[name="jointName[]"]',
        'input[name="jointAddress1[]"]',
        'input[name="jointAddress2[]"]',
        'input[name="jointAddress3[]"]',
        'select[name="jointCountry[]"]',
        'select[name="jointState[]"]',
        'select[name="jointCity[]"]',
        'input[name="jointZip[]"]',

        'select[name="coBorrowerSalutation[]"]',
        'input[name="coBorrowerName[]"]',
        'input[name="coBorrowerAddress1[]"]',
        'input[name="coBorrowerAddress2[]"]',
        'input[name="coBorrowerAddress3[]"]',
        'select[name="coBorrowerCountry[]"]',
        'select[name="coBorrowerState[]"]',
        'select[name="coBorrowerCity[]"]',
        'input[name="coBorrowerZip[]"]',

        'select[name="guarantorSalutation[]"]',
        'input[name="guarantorName[]"]',
        'input[name="guarantorAddress1[]"]',
        'input[name="guarantorAddress2[]"]',
        'input[name="guarantorAddress3[]"]',
        'select[name="guarantorCountry[]"]',
        'select[name="guarantorState[]"]',
        'select[name="guarantorCity[]"]',
        'input[name="guarantorZip[]"]',
        'input[name="guarantorMemberNo[]"]',
        'input[name="guarantorBirthDate[]"]',
        'input[name="guarantorPhoneNo[]"]',
        'input[name="guarantorMobileNo[]"]'
    ];

    fieldsToLock.forEach(selector => {
        const field = block.querySelector(selector);

        if (field) {
            if (field.tagName === "SELECT") {
                lockSelect(field); // ❗ Replace disabled=true
            } else {
                field.readOnly = true;
            }

            field.style.backgroundColor = "#f0f0f0";
            field.style.cursor = "not-allowed";
        }
    });
}
// === UNLOCK fetched fields ===
function makeFieldsEditable(block) {

    const fieldsToUnlock = [
        'select[name="nomineeSalutation[]"]',
        'input[name="nomineeName[]"]',
        'input[name="nomineeAddress1[]"]',
        'input[name="nomineeAddress2[]"]',
        'input[name="nomineeAddress3[]"]',
        'select[name="nomineeCountry[]"]',
        'select[name="nomineeState[]"]',
        'select[name="nomineeCity[]"]',
        'input[name="nomineeZip[]"]',

        'select[name="jointSalutation[]"]',
        'input[name="jointName[]"]',
        'input[name="jointAddress1[]"]',
        'input[name="jointAddress2[]"]',
        'input[name="jointAddress3[]"]',
        'select[name="jointCountry[]"]',
        'select[name="jointState[]"]',
        'select[name="jointCity[]"]',
        'input[name="jointZip[]"]',

        'select[name="coBorrowerSalutation[]"]',
        'input[name="coBorrowerName[]"]',
        'input[name="coBorrowerAddress1[]"]',
        'input[name="coBorrowerAddress2[]"]',
        'input[name="coBorrowerAddress3[]"]',
        'select[name="coBorrowerCountry[]"]',
        'select[name="coBorrowerState[]"]',
        'select[name="coBorrowerCity[]"]',
        'input[name="coBorrowerZip[]"]',

        'select[name="guarantorSalutation[]"]',
        'input[name="guarantorName[]"]',
        'input[name="guarantorAddress1[]"]',
        'input[name="guarantorAddress2[]"]',
        'input[name="guarantorAddress3[]"]',
        'select[name="guarantorCountry[]"]',
        'select[name="guarantorState[]"]',
        'select[name="guarantorCity[]"]',
        'input[name="guarantorZip[]"]',
        'input[name="guarantorMemberNo[]"]',
        'input[name="guarantorBirthDate[]"]',
        'input[name="guarantorPhoneNo[]"]',
        'input[name="guarantorMobileNo[]"]'
    ];

    fieldsToUnlock.forEach(selector => {
        const field = block.querySelector(selector);

        if (field) {
            if (field.tagName === "SELECT") {
                unlockSelect(field); // ❗ Restore select
            } else {
                field.readOnly = false;
            }

            field.style.backgroundColor = "";
            field.style.cursor = "";
        }
    });
}

//==================== NOMINEE FUNCTIONS ====================

function toggleNomineeCustomerID(radio) {
    const nomineeBlock = radio.closest('.nominee-block');
    const container = nomineeBlock.querySelector('.nomineeCustomerIDContainer');
    const input = nomineeBlock.querySelector('.nomineeCustomerIDInput');

    if (radio.value === 'yes') {
        container.style.display = 'flex'; // Changed from 'block' to 'flex'
        input.required = true;
    } else {
        container.style.display = 'none';
        input.required = false;
        input.value = '';
        clearNomineeFields(nomineeBlock);
        makeFieldsEditable(nomineeBlock);
    }
}

function clearNomineeFields(block) {
    block.querySelector('select[name="nomineeSalutation[]"]').value = '';
    block.querySelector('input[name="nomineeName[]"]').value = '';
    block.querySelector('input[name="nomineeAddress1[]"]').value = '';
    block.querySelector('input[name="nomineeAddress2[]"]').value = '';
    block.querySelector('input[name="nomineeAddress3[]"]').value = '';
    block.querySelector('select[name="nomineeCountry[]"]').value = '';
    block.querySelector('select[name="nomineeState[]"]').value = '';
    block.querySelector('select[name="nomineeCity[]"]').value = '';
    block.querySelector('input[name="nomineeZip[]"]').value = '0';
}

function openNomineeCustomerLookup(button) {
    var nomineeBlock = button.closest('.nominee-block');
    window.currentNomineeInput = nomineeBlock.querySelector('.nomineeCustomerIDInput');
    window.currentNomineeBlock = nomineeBlock;
    var mainId = document.getElementById('customerId') ?
                 document.getElementById('customerId').value : '';
    window.parent.postMessage({
        type: 'OPEN_CUSTOMER_LOOKUP',
        callbackId: 'nominee',
        excludeIds: mainId ? [mainId] : []
    }, '*');
}

function addNominee() {
    let fieldset = document.getElementById("nomineeFieldset");
    let original = fieldset.querySelector(".nominee-block");
    let clone = original.cloneNode(true);

    clone.querySelectorAll("input, select").forEach(el => {
        if (el.type === 'radio') {
            if (el.value === 'no') el.checked = true;
            else el.checked = false;
        } else if (el.tagName === 'SELECT') {
            el.selectedIndex = 0;
        } else if (el.name === 'nomineeZip[]') {
            el.value = '0';
        } else {
            el.value = "";
        }
    });

    const customerIDContainer = clone.querySelector('.nomineeCustomerIDContainer');
    if (customerIDContainer) {
        customerIDContainer.style.display = 'none';
    }

	// ✅ Reset all fields to editable state in the new clone
	    makeFieldsEditable(clone);

    const nomineeBlocks = fieldset.querySelectorAll(".nominee-block");
    const newIndex = nomineeBlocks.length + 1;
    const radios = clone.querySelectorAll('.nomineeHasCustomerRadio');
    radios.forEach(radio => {
        radio.name = 'nomineeHasCustomerID_' + newIndex;
    });

    clone.querySelector(".nominee-remove").onclick = function() {
        removeNominee(this);
    };

    fieldset.appendChild(clone);
    updateNomineeSerials();
}

function removeNominee(btn) {
    let blocks = document.querySelectorAll(".nominee-block");
    if (blocks.length <= 1) {
        showToast("At least one nominee is required.", "warning");
        return;
    }
    btn.parentNode.remove();
    updateNomineeSerials();
}

function updateNomineeSerials() {
    let blocks = document.querySelectorAll(".nominee-block");
    blocks.forEach((block, index) => {
        let serial = block.querySelector(".nominee-serial");
        if (serial) {
            serial.textContent = (index + 1);
        }
    });
}

//Populate Nominee fields with customer data
function populateNomineeFields(block, customer) {
    console.log('📝 Populating Nominee fields:', customer);

    const salutationSelect = block.querySelector('select[name="nomineeSalutation[]"]');
    if (salutationSelect && customer.salutationCode) {
        setSelectValue(salutationSelect, customer.salutationCode, 'Nominee Salutation');
    }

    const nameInput = block.querySelector('input[name="nomineeName[]"]');
    if (nameInput && customer.customerName) {
        nameInput.value = customer.customerName;
    }

    const address1Input = block.querySelector('input[name="nomineeAddress1[]"]');
    if (address1Input && customer.address1) {
        address1Input.value = customer.address1;
    }

    const address2Input = block.querySelector('input[name="nomineeAddress2[]"]');
    if (address2Input && customer.address2) {
        address2Input.value = customer.address2;
    }

    const address3Input = block.querySelector('input[name="nomineeAddress3[]"]');
    if (address3Input && customer.address3) {
        address3Input.value = customer.address3;
    }

    const countrySelect = block.querySelector('select[name="nomineeCountry[]"]');
    if (countrySelect && customer.country) {
        setSelectValue(countrySelect, customer.country, 'Nominee Country');
    }

    const stateSelect = block.querySelector('select[name="nomineeState[]"]');
    if (stateSelect && customer.state) {
        setSelectValue(stateSelect, customer.state, 'Nominee State');
    }

    const citySelect = block.querySelector('select[name="nomineeCity[]"]');
    if (citySelect && customer.city) {
        setSelectValue(citySelect, customer.city, 'Nominee City');
    }

    const zipInput = block.querySelector('input[name="nomineeZip[]"]');
    if (zipInput && customer.zip) {
        zipInput.value = customer.zip;
    }
	// ✅ Make all fields read-only after populating
	    makeFieldsReadOnly(block);
}

//==================== JOINT HOLDER FUNCTIONS ====================

function toggleJointCustomerID(radio) {
    const jointBlock = radio.closest('.joint-block');
    const container = jointBlock.querySelector('.jointCustomerIDContainer');
    const input = jointBlock.querySelector('.jointCustomerIDInput');

    if (radio.value === 'yes') {
        container.style.display = 'flex'; // Changed from 'block' to 'flex'
        input.required = true;
    } else {
        container.style.display = 'none';
        input.required = false;
        input.value = '';
        clearJointFields(jointBlock);
        makeFieldsEditable(jointBlock);
    }
}

function clearJointFields(block) {
    block.querySelector('select[name="jointSalutation[]"]').value = '';
    block.querySelector('input[name="jointName[]"]').value = '';
    block.querySelector('input[name="jointAddress1[]"]').value = '';
    block.querySelector('input[name="jointAddress2[]"]').value = '';
    block.querySelector('input[name="jointAddress3[]"]').value = '';
    block.querySelector('select[name="jointCountry[]"]').value = '';
    block.querySelector('select[name="jointState[]"]').value = '';
    block.querySelector('select[name="jointCity[]"]').value = '';
    block.querySelector('input[name="jointZip[]"]').value = '0';
}

function openJointCustomerLookup(button) {
    var jointBlock = button.closest('.joint-block');
    window.currentJointInput = jointBlock.querySelector('.jointCustomerIDInput');
    window.currentJointBlock = jointBlock;
    var mainId = document.getElementById('customerId') ?
                 document.getElementById('customerId').value : '';
    window.parent.postMessage({
        type: 'OPEN_CUSTOMER_LOOKUP',
        callbackId: 'joint',
        excludeIds: mainId ? [mainId] : []
    }, '*');
}

function addJointHolder() {
    let fieldset = document.getElementById("jointFieldset");
    let original = fieldset.querySelector(".joint-block");
    let clone = original.cloneNode(true);

    clone.querySelectorAll("input, select").forEach(el => {
        if (el.type === 'radio') {
            if (el.value === 'no') el.checked = true;
            else el.checked = false;
        } else if (el.tagName === 'SELECT') {
            el.selectedIndex = 0;
        } else if (el.name === 'jointZip[]') {
            el.value = '0';
        } else {
            el.value = "";
        }
    });

    const customerIDContainer = clone.querySelector('.jointCustomerIDContainer');
    if (customerIDContainer) {
        customerIDContainer.style.display = 'none';
    }

	// ✅ Reset all fields to editable state in the new clone
	    makeFieldsEditable(clone);

    const jointBlocks = fieldset.querySelectorAll(".joint-block");
    const newIndex = jointBlocks.length + 1;
    const radios = clone.querySelectorAll('.jointHasCustomerRadio');
    radios.forEach(radio => {
        radio.name = 'jointHasCustomerID_' + newIndex;
    });

    clone.querySelector(".nominee-remove").onclick = function() {
        removeJointHolder(this);
    };

    fieldset.appendChild(clone);
    updateJointSerials();
}

function removeJointHolder(btn) {
    let blocks = document.querySelectorAll(".joint-block");
    if (blocks.length <= 1) {
        showToast("At least one joint holder is required.", "warning");
        return;
    }
    btn.parentNode.remove();
    updateJointSerials();
}

function updateJointSerials() {
    let blocks = document.querySelectorAll(".joint-block");
    blocks.forEach((block, index) => {
        let serial = block.querySelector(".joint-serial");
        if (serial) {
            serial.textContent = (index + 1);
        }
    });
}

//Populate Joint Holder fields with customer data
function populateJointFields(block, customer) {
    console.log('📝 Populating Joint Holder fields:', customer);

    const salutationSelect = block.querySelector('select[name="jointSalutation[]"]');
    if (salutationSelect && customer.salutationCode) {
        setSelectValue(salutationSelect, customer.salutationCode, 'Joint Salutation');
    }

    const nameInput = block.querySelector('input[name="jointName[]"]');
    if (nameInput && customer.customerName) {
        nameInput.value = customer.customerName;
    }

    const address1Input = block.querySelector('input[name="jointAddress1[]"]');
    if (address1Input && customer.address1) {
        address1Input.value = customer.address1;
    }

    const address2Input = block.querySelector('input[name="jointAddress2[]"]');
    if (address2Input && customer.address2) {
        address2Input.value = customer.address2;
    }

    const address3Input = block.querySelector('input[name="jointAddress3[]"]');
    if (address3Input && customer.address3) {
        address3Input.value = customer.address3;
    }

    const countrySelect = block.querySelector('select[name="jointCountry[]"]');
    if (countrySelect && customer.country) {
        setSelectValue(countrySelect, customer.country, 'Joint Country');
    }

    const stateSelect = block.querySelector('select[name="jointState[]"]');
    if (stateSelect && customer.state) {
        setSelectValue(stateSelect, customer.state, 'Joint State');
    }

    const citySelect = block.querySelector('select[name="jointCity[]"]');
    if (citySelect && customer.city) {
        setSelectValue(citySelect, customer.city, 'Joint City');
    }

    const zipInput = block.querySelector('input[name="jointZip[]"]');
    if (zipInput && customer.zip) {
        zipInput.value = customer.zip;
    }
	// ✅ Make all fields read-only after populating
	    makeFieldsReadOnly(block);
}

//==================== CO-BORROWER FUNCTIONS ====================

function toggleCoBorrowerCustomerID(radio) {
    const coBorrowerBlock = radio.closest('.coBorrower-block');
    const container = coBorrowerBlock.querySelector('.coBorrowerCustomerIDContainer');
    const input = coBorrowerBlock.querySelector('.coBorrowerCustomerIDInput');

    if (radio.value === 'yes') {
        container.style.display = 'flex'; // Changed from 'block' to 'flex'
        input.required = true;
    } else {
        container.style.display = 'none';
        input.required = false;
        input.value = '';
        clearCoBorrowerFields(coBorrowerBlock);
        makeFieldsEditable(coBorrowerBlock);
    }
}

function clearCoBorrowerFields(block) {
    block.querySelector('select[name="coBorrowerSalutation[]"]').value = '';
    block.querySelector('input[name="coBorrowerName[]"]').value = '';
    block.querySelector('input[name="coBorrowerAddress1[]"]').value = '';
    block.querySelector('input[name="coBorrowerAddress2[]"]').value = '';
    block.querySelector('input[name="coBorrowerAddress3[]"]').value = '';
    block.querySelector('select[name="coBorrowerCountry[]"]').value = '';
    block.querySelector('select[name="coBorrowerState[]"]').value = '';
    block.querySelector('select[name="coBorrowerCity[]"]').value = '';
    block.querySelector('input[name="coBorrowerZip[]"]').value = '0';
}

function openCoBorrowerCustomerLookup(button) {
    var coBorrowerBlock = button.closest('.coBorrower-block');
    window.currentCoBorrowerInput = coBorrowerBlock.querySelector('.coBorrowerCustomerIDInput');
    window.currentCoBorrowerBlock = coBorrowerBlock;
    var mainId = document.getElementById('customerId') ?
                 document.getElementById('customerId').value : '';
    window.parent.postMessage({
        type: 'OPEN_CUSTOMER_LOOKUP',
        callbackId: 'coborrower',
        excludeIds: mainId ? [mainId] : []
    }, '*');
}

function addCoBorrower() {
    let fieldset = document.getElementById("coBorrowerFieldset");
    let original = fieldset.querySelector(".coBorrower-block");
    let clone = original.cloneNode(true);

    clone.querySelectorAll("input, select").forEach(el => {
        if (el.type === 'radio') {
            if (el.value === 'no') el.checked = true;
            else el.checked = false;
        } else if (el.tagName === 'SELECT') {
            el.selectedIndex = 0;
        } else if (el.name === 'coBorrowerZip[]') {
            el.value = '0';
        } else {
            el.value = "";
        }
    });

    const customerIDContainer = clone.querySelector('.coBorrowerCustomerIDContainer');
    if (customerIDContainer) {
        customerIDContainer.style.display = 'none';
    }

	// ✅ Reset all fields to editable state in the new clone
	    makeFieldsEditable(clone);

    const coBorrowerBlocks = fieldset.querySelectorAll(".coBorrower-block");
    const newIndex = coBorrowerBlocks.length + 1;
    const radios = clone.querySelectorAll('.coBorrowerHasCustomerRadio');
    radios.forEach(radio => {
        radio.name = 'coBorrowerHasCustomerID_' + newIndex;
    });

    clone.querySelector(".nominee-remove").onclick = function() {
        removeCoBorrower(this);
    };

    fieldset.appendChild(clone);
    updateCoBorrowerSerials();
}

function removeCoBorrower(btn) {
    let blocks = document.querySelectorAll(".coBorrower-block");
    if (blocks.length <= 1) {
        showToast("⚠️ At least one co-borrower is required.", "warning");
        return;
    }
    btn.parentNode.remove();
    updateCoBorrowerSerials();
}

function updateCoBorrowerSerials() {
    let blocks = document.querySelectorAll(".coBorrower-block");
    blocks.forEach((block, index) => {
        let serial = block.querySelector(".coBorrower-serial");
        if (serial) {
            serial.textContent = (index + 1);
        }
    });
}

// Populate Co-Borrower fields with customer data
function populateCoBorrowerFields(block, customer) {
    console.log('📝 Populating Co-Borrower fields:', customer);

    // Salutation Code
    const salutationSelect = block.querySelector('select[name="coBorrowerSalutation[]"]');
    if (salutationSelect && customer.salutationCode) {
        setSelectValue(salutationSelect, customer.salutationCode, 'Co-Borrower Salutation');
    }

    // Co-Borrower Name
    const nameInput = block.querySelector('input[name="coBorrowerName[]"]');
    if (nameInput && customer.customerName) {
        nameInput.value = customer.customerName;
    }

    // Address fields
    const address1Input = block.querySelector('input[name="coBorrowerAddress1[]"]');
    if (address1Input && customer.address1) {
        address1Input.value = customer.address1;
    }

    const address2Input = block.querySelector('input[name="coBorrowerAddress2[]"]');
    if (address2Input && customer.address2) {
        address2Input.value = customer.address2;
    }

    const address3Input = block.querySelector('input[name="coBorrowerAddress3[]"]');
    if (address3Input && customer.address3) {
        address3Input.value = customer.address3;
    }

    // Country
    const countrySelect = block.querySelector('select[name="coBorrowerCountry[]"]');
    if (countrySelect && customer.country) {
        setSelectValue(countrySelect, customer.country, 'Co-Borrower Country');
    }

    // State
    const stateSelect = block.querySelector('select[name="coBorrowerState[]"]');
    if (stateSelect && customer.state) {
        setSelectValue(stateSelect, customer.state, 'Co-Borrower State');
    }

    // City
    const citySelect = block.querySelector('select[name="coBorrowerCity[]"]');
    if (citySelect && customer.city) {
        setSelectValue(citySelect, customer.city, 'Co-Borrower City');
    }

    // Zip
    const zipInput = block.querySelector('input[name="coBorrowerZip[]"]');
    if (zipInput && customer.zip) {
        zipInput.value = customer.zip;
    }
	// ✅ Make all fields read-only after populating
	    makeFieldsReadOnly(block);
}

//==================== GUARANTOR FUNCTIONS ====================

function toggleGuarantorCustomerID(radio) {
    const guarantorBlock = radio.closest('.guarantor-block');
    const container = guarantorBlock.querySelector('.guarantorCustomerIDContainer');
    const input = guarantorBlock.querySelector('.guarantorCustomerIDInput');

    if (radio.value === 'yes') {
        container.style.display = 'flex'; // Changed from 'block' to 'flex'
        input.required = true;
    } else {
        container.style.display = 'none';
        input.required = false;
        input.value = '';
        clearGuarantorFields(guarantorBlock);
        makeFieldsEditable(guarantorBlock);
    }
}

function clearGuarantorFields(block) {
    block.querySelector('select[name="guarantorSalutation[]"]').value = '';
    block.querySelector('input[name="guarantorName[]"]').value = '';
    block.querySelector('input[name="guarantorAddress1[]"]').value = '';
    block.querySelector('input[name="guarantorAddress2[]"]').value = '';
    block.querySelector('input[name="guarantorAddress3[]"]').value = '';
    block.querySelector('select[name="guarantorCountry[]"]').value = '';
    block.querySelector('select[name="guarantorState[]"]').value = '';
    block.querySelector('select[name="guarantorCity[]"]').value = '';
    block.querySelector('input[name="guarantorZip[]"]').value = '';

    block.querySelector('input[name="guarantorMemberNo[]"]').value = '';
    block.querySelector('input[name="guarantorPhoneNo[]"]').value = '';
    block.querySelector('input[name="guarantorMobileNo[]"]').value = '';
    block.querySelector('input[name="guarantorBirthDate[]"]').value = '';
}

function openGuarantorCustomerLookup(button) {
    var guarantorBlock = button.closest('.guarantor-block');
    window.currentGuarantorInput = guarantorBlock.querySelector('.guarantorCustomerIDInput');
    window.currentGuarantorBlock = guarantorBlock;
    var mainId = document.getElementById('customerId') ?
                 document.getElementById('customerId').value : '';
    window.parent.postMessage({
        type: 'OPEN_CUSTOMER_LOOKUP',
        callbackId: 'guarantor',
        excludeIds: mainId ? [mainId] : []
    }, '*');
}

function addGuarantor() {
    let fieldset = document.getElementById("guarantorFieldset");
    let original = fieldset.querySelector(".guarantor-block");
    let clone = original.cloneNode(true);

    clone.querySelectorAll("input, select").forEach(el => {
        if (el.type === 'radio') {
            if (el.value === 'no') el.checked = true;
            else el.checked = false;
        } else if (el.tagName === 'SELECT') {
            el.selectedIndex = 0;
        } else if (el.name === 'guarantorZip[]') {
            el.value = '0';
        } else {
            el.value = "";
        }
    });

    const customerIDContainer = clone.querySelector('.guarantorCustomerIDContainer');
    if (customerIDContainer) {
        customerIDContainer.style.display = 'none';
    }

	// ✅ Reset all fields to editable state in the new clone
	    makeFieldsEditable(clone);

    const guarantorBlocks = fieldset.querySelectorAll(".guarantor-block");
    const newIndex = guarantorBlocks.length + 1;
    const radios = clone.querySelectorAll('.guarantorHasCustomerRadio');
    radios.forEach(radio => {
        radio.name = 'guarantorHasCustomerID_' + newIndex;
    });

    clone.querySelector(".nominee-remove").onclick = function() {
        removeGuarantor(this);
    };

    fieldset.appendChild(clone);
    updateGuarantorSerials();
}

function removeGuarantor(btn) {
    let blocks = document.querySelectorAll(".guarantor-block");
    if (blocks.length <= 1) {
        showToast("⚠️ At least one guarantor is required.", "warning");
        return;
    }
    btn.parentNode.remove();
    updateGuarantorSerials();
}

function updateGuarantorSerials() {
    let blocks = document.querySelectorAll(".guarantor-block");
    blocks.forEach((block, index) => {
        let serial = block.querySelector(".guarantor-serial");
        if (serial) {
            serial.textContent = (index + 1);
        }
    });
}

//Populate Guarantor fields with customer data
function populateGuarantorFields(block, customer) {
    console.log('📝 Populating Guarantor fields:', customer);

    const salutationSelect = block.querySelector('select[name="guarantorSalutation[]"]');
    if (salutationSelect && customer.salutationCode) {
        setSelectValue(salutationSelect, customer.salutationCode, 'Guarantor Salutation');
    }

    const nameInput = block.querySelector('input[name="guarantorName[]"]');
    if (nameInput && customer.customerName) {
        nameInput.value = customer.customerName;
    }

    const address1Input = block.querySelector('input[name="guarantorAddress1[]"]');
    if (address1Input && customer.address1) {
        address1Input.value = customer.address1;
    }

    const address2Input = block.querySelector('input[name="guarantorAddress2[]"]');
    if (address2Input && customer.address2) {
        address2Input.value = customer.address2;
    }

    const address3Input = block.querySelector('input[name="guarantorAddress3[]"]');
    if (address3Input && customer.address3) {
        address3Input.value = customer.address3;
    }

    const countrySelect = block.querySelector('select[name="guarantorCountry[]"]');
    if (countrySelect && customer.country) {
        setSelectValue(countrySelect, customer.country, 'Guarantor Country');
    }

    const stateSelect = block.querySelector('select[name="guarantorState[]"]');
    if (stateSelect && customer.state) {
        setSelectValue(stateSelect, customer.state, 'Guarantor State');
    }

    const citySelect = block.querySelector('select[name="guarantorCity[]"]');
    if (citySelect && customer.city) {
        setSelectValue(citySelect, customer.city, 'Guarantor City');
    }

    const zipInput = block.querySelector('input[name="guarantorZip[]"]');
    if (zipInput && customer.zip) {
        zipInput.value = customer.zip;
    }

    const memberNoInput = block.querySelector('input[name="guarantorMemberNo[]"]');
    if (memberNoInput && customer.memberNumber) {
        memberNoInput.value = customer.memberNumber;
    }

    const birthDateInput = block.querySelector('input[name="guarantorBirthDate[]"]');
    if (birthDateInput && customer.birthDate) {
        birthDateInput.value = customer.birthDate;
    }

    const phoneNoInput = block.querySelector('input[name="guarantorPhoneNo[]"]');
    if (phoneNoInput && customer.residencePhone) {
        phoneNoInput.value = customer.residencePhone;
    }

    const mobileNoInput = block.querySelector('input[name="guarantorMobileNo[]"]');
    if (mobileNoInput && customer.mobileNo) {
        mobileNoInput.value = customer.mobileNo;
    }
	// ✅ Make all fields read-only after populating
	    makeFieldsReadOnly(block);
}

//==================== UTILITY FUNCTIONS ====================

// Enhanced toast utility function with different types
function showToast(message, type) {
    if (typeof type === 'undefined') {
        type = 'success';
    }

    if (typeof Toastify === 'undefined') {
        console.warn('Toastify library not loaded');
        return;
    }

    const styles = {
        success: {
            borderColor: '#4caf50',
            icon: '✅'
        },
        error: {
            borderColor: '#f44336',
            icon: '❌'
        },
        warning: {
            borderColor: '#ff9800',
            icon: '⚠️'
        },
        info: {
            borderColor: '#2196F3',
            icon: 'ℹ️'
        }
    };

    const style = styles[type] || styles.info;

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
            borderLeft: '5px solid ' + style.borderColor,
            marginTop: "20px",
            whiteSpace: "pre-line"
        },
        stopOnFocus: true
    }).showToast();
	}
	
	// ✅ NEW: Helper function to collect all used customer IDs
	function getAllUsedCustomerIds() {
	    var usedIds = [];
	    var seenIds = {};
	    
	    // Collect from all nominee blocks
	    var nomineeBlocks = document.querySelectorAll('.nominee-block');
	    for (var i = 0; i < nomineeBlocks.length; i++) {
	        var input = nomineeBlocks[i].querySelector('.nomineeCustomerIDInput');
	        if (input && input.value && input.value.trim()) {
	            var custId = input.value.trim();
	            if (!seenIds[custId]) {
	                usedIds.push(custId);
	                seenIds[custId] = true;
	            }
	        }
	    }
	    
	    // Collect from all joint holder blocks
	    var jointBlocks = document.querySelectorAll('.joint-block');
	    for (var j = 0; j < jointBlocks.length; j++) {
	        var input2 = jointBlocks[j].querySelector('.jointCustomerIDInput');
	        if (input2 && input2.value && input2.value.trim()) {
	            var custId2 = input2.value.trim();
	            if (!seenIds[custId2]) {
	                usedIds.push(custId2);
	                seenIds[custId2] = true;
	            }
	        }
	    }
	    
	    // Collect from all co-borrower blocks
	    var coBorrowerBlocks = document.querySelectorAll('.coBorrower-block');
	    for (var k = 0; k < coBorrowerBlocks.length; k++) {
	        var input3 = coBorrowerBlocks[k].querySelector('.coBorrowerCustomerIDInput');
	        if (input3 && input3.value && input3.value.trim()) {
	            var custId3 = input3.value.trim();
	            if (!seenIds[custId3]) {
	                usedIds.push(custId3);
	                seenIds[custId3] = true;
	            }
	        }
	    }
	    
	    // Collect from all guarantor blocks
	    var guarantorBlocks = document.querySelectorAll('.guarantor-block');
	    for (var m = 0; m < guarantorBlocks.length; m++) {
	        var input4 = guarantorBlocks[m].querySelector('.guarantorCustomerIDInput');
	        if (input4 && input4.value && input4.value.trim()) {
	            var custId4 = input4.value.trim();
	            if (!seenIds[custId4]) {
	                usedIds.push(custId4);
	                seenIds[custId4] = true;
	            }
	        }
	    }
	    
	    return usedIds;
	}

	// ✅ NEW: Check if customer ID is already used in same fieldset type
	function isCustomerUsedInSameFieldset(customerId, fieldsetType, currentBlock) {
	    var selector = '';
	    var inputClass = '';
	    
	    if (fieldsetType === 'nominee') {
	        selector = '.nominee-block';
	        inputClass = '.nomineeCustomerIDInput';
	    }
	    
	    if (fieldsetType === 'joint') {
	        selector = '.joint-block';
	        inputClass = '.jointCustomerIDInput';
	    }
	    
	    if (fieldsetType === 'coborrower') {
	        selector = '.coBorrower-block';
	        inputClass = '.coBorrowerCustomerIDInput';
	    }
	    
	    if (fieldsetType === 'guarantor') {
	        selector = '.guarantor-block';
	        inputClass = '.guarantorCustomerIDInput';
	    }
	    
	    if (!selector) {
	        return false;
	    }
	    
	    var blocks = document.querySelectorAll(selector);
	    for (var i = 0; i < blocks.length; i++) {
	        var block = blocks[i];
	        if (block === currentBlock) {
	            continue;
	        }
	        
	        var input = block.querySelector(inputClass);
	        if (input && input.value.trim() === customerId) {
	            return true;
	        }
	    }
	    
	    return false;
	}

	// ✅ NEW: Clear customer data from all fieldsets where it's used (except Application)
	function clearCustomerFromOtherFieldsets(customerId) {
	    let clearedCount = 0;
	    
	    // Clear from nominee blocks
	    document.querySelectorAll('.nominee-block').forEach(block => {
	        const input = block.querySelector('.nomineeCustomerIDInput');
	        if (input && input.value.trim() === customerId) {
	            input.value = '';
	            clearNomineeFields(block);
	            makeFieldsEditable(block);
	            // Switch radio to "No"
	            const noRadio = block.querySelector('input[type="radio"][value="no"]');
	            if (noRadio) {
	                noRadio.checked = true;
	                toggleNomineeCustomerID(noRadio);
	            }
	            clearedCount++;
	        }
	    });
	    
	    // Clear from joint holder blocks
	    document.querySelectorAll('.joint-block').forEach(block => {
	        const input = block.querySelector('.jointCustomerIDInput');
	        if (input && input.value.trim() === customerId) {
	            input.value = '';
	            clearJointFields(block);
	            makeFieldsEditable(block);
	            const noRadio = block.querySelector('input[type="radio"][value="no"]');
	            if (noRadio) {
	                noRadio.checked = true;
	                toggleJointCustomerID(noRadio);
	            }
	            clearedCount++;
	        }
	    });
	    
	    // Clear from co-borrower blocks
	    document.querySelectorAll('.coBorrower-block').forEach(block => {
	        const input = block.querySelector('.coBorrowerCustomerIDInput');
	        if (input && input.value.trim() === customerId) {
	            input.value = '';
	            clearCoBorrowerFields(block);
	            makeFieldsEditable(block);
	            const noRadio = block.querySelector('input[type="radio"][value="no"]');
	            if (noRadio) {
	                noRadio.checked = true;
	                toggleCoBorrowerCustomerID(noRadio);
	            }
	            clearedCount++;
	        }
	    });
	    
	    // Clear from guarantor blocks
	    document.querySelectorAll('.guarantor-block').forEach(block => {
	        const input = block.querySelector('.guarantorCustomerIDInput');
	        if (input && input.value.trim() === customerId) {
	            input.value = '';
	            clearGuarantorFields(block);
	            makeFieldsEditable(block);
	            const noRadio = block.querySelector('input[type="radio"][value="no"]');
	            if (noRadio) {
	                noRadio.checked = true;
	                toggleGuarantorCustomerID(noRadio);
	            }
	            clearedCount++;
	        }
	    });
	    return clearedCount;
	}
	
	document.addEventListener("DOMContentLoaded", function () {

	    const zipInputs = document.querySelectorAll(".zip-input");

	    zipInputs.forEach(function (input) {
	        input.addEventListener("input", function () {
	            validateZip(input);
	        });
	    });

	});

	//==================== ZIP VALIDATION ====================
	document.addEventListener("DOMContentLoaded", function () {

	    /* 🔴 ADD CSS USING JS */
	    const style = document.createElement("style");
	    style.innerHTML = `
	        .zipError {
	            color: red;
	            font-size: 12px;
	        }
	        .zip-input.error {
	            border: 1px solid red;
	        }
	    `;
	    document.head.appendChild(style);

	    /* 🔁 ATTACH VALIDATION TO ALL ZIP INPUTS */
	    document.querySelectorAll(".zip-input").forEach(input => {
	        input.addEventListener("input", function () {
	            validateZip(this);
	        });
	    });

	});

	function validateZip(input) {
	    let zip = input.value;
	    const error = input.nextElementSibling;

	    // Allow only digits
	    zip = zip.replace(/\D/g, '');
	    input.value = zip;

	    // Reset error
	    error.textContent = "";
	    input.classList.remove("error");

	    if (zip.length === 0) return;

	    // First digit validation (4 = MH/Goa, 5 = Karnataka)
	    const firstDigit = zip.charAt(0);

	    if (firstDigit !== '4' && firstDigit !== '5') {
	        error.textContent = "PIN must start with 4 or 5";
	        input.classList.add("error");
	        input.value = "";
	        return;
	    }

	    // Length validation
	    if (zip.length < 6) {
	        error.textContent = "PIN must be 6 digits";
	        input.classList.add("error");
	        return;
	    }
	}
	
	// Receive customer data back from newApplication.jsp modal
	window.addEventListener('message', function(e) {
	    if (e.data && e.data.type === 'CUSTOMER_SELECTED') {
	        var d = e.data;

	        if (window.currentNomineeInput) {
	            if (isCustomerUsedInSameFieldset(d.custId, 'nominee', window.currentNomineeBlock)) {
	                showToast('This customer is already added as another nominee!', 'error');
	                return;
	            }
	            window.currentNomineeInput.value = d.custId;
	            fetchCustomerDetails(d.custId, 'nominee', window.currentNomineeBlock);
	            window.currentNomineeInput = null;
	            window.currentNomineeBlock = null;
	            return;
	        }

	        if (window.currentJointInput) {
	            if (isCustomerUsedInSameFieldset(d.custId, 'joint', window.currentJointBlock)) {
	                showToast('This customer is already added as another joint holder!', 'error');
	                return;
	            }
	            window.currentJointInput.value = d.custId;
	            fetchCustomerDetails(d.custId, 'joint', window.currentJointBlock);
	            window.currentJointInput = null;
	            window.currentJointBlock = null;
	            return;
	        }

	        if (window.currentCoBorrowerInput) {
	            if (isCustomerUsedInSameFieldset(d.custId, 'coborrower', window.currentCoBorrowerBlock)) {
	                showToast('This customer is already added as another co-borrower!', 'error');
	                return;
	            }
	            window.currentCoBorrowerInput.value = d.custId;
	            fetchCustomerDetails(d.custId, 'coborrower', window.currentCoBorrowerBlock);
	            window.currentCoBorrowerInput = null;
	            window.currentCoBorrowerBlock = null;
	            return;
	        }

	        if (window.currentGuarantorInput) {
	            if (isCustomerUsedInSameFieldset(d.custId, 'guarantor', window.currentGuarantorBlock)) {
	                showToast('This customer is already added as another guarantor!', 'error');
	                return;
	            }
	            window.currentGuarantorInput.value = d.custId;
	            fetchCustomerDetails(d.custId, 'guarantor', window.currentGuarantorBlock);
	            window.currentGuarantorInput = null;
	            window.currentGuarantorBlock = null;
	            return;
	        }

	        // Main application customer
	        var oldId = document.getElementById('customerId') ?
	                    document.getElementById('customerId').value.trim() : '';
	        if (oldId && oldId !== d.custId) {
	            var cleared = clearCustomerFromOtherFieldsets(oldId);
	            if (cleared > 0) {
	                showToast('Previous customer cleared from ' + cleared + ' fieldset(s)', 'warning');
	            }
	        }

	        document.getElementById('customerId').value  = d.custId;
	        document.getElementById('customerName').value = d.custName;
	        if (document.getElementById('categoryCode')) {
	            document.getElementById('categoryCode').value = d.catCode || '';
	        }
	        if (document.getElementById('riskCategory')) {
	            document.getElementById('riskCategory').value = d.riskCat || '';
	        }
	    }
	});