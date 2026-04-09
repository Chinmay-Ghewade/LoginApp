//==================== AREA LOOKUP ====================

function openAreaLookup() {
    let url = "lookupForLoan.jsp?type=area";

    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById("areaLookupContent").innerHTML = html;
            document.getElementById("areaLookupModal").style.display = "flex";
            
            const scripts = document.getElementById("areaLookupContent").querySelectorAll('script');
            scripts.forEach(script => {
                const newScript = document.createElement('script');
                newScript.textContent = script.textContent;
                document.body.appendChild(newScript);
            });
        })
        .catch(error => {
            showToast('❌ Failed to load area lookup data. Please try again.');
            console.error('Lookup error:', error);
        });
}

function closeAreaLookup() {
    document.getElementById("areaLookupModal").style.display = "none";
}

window.setAreaData = function(code, name) {
    document.getElementById("areaCode").value = code;
    document.getElementById("areaName").value = name;
    
    // Clear sub area when area changes
    document.getElementById("subAreaCode").value = '';
    document.getElementById("subAreaName").value = '';
    
    closeAreaLookup();
    
};

//==================== SUB AREA LOOKUP ====================

function openSubAreaLookup() {
    const areaCode = document.getElementById("areaCode").value;
    
    if (!areaCode) {
        showToast('⚠️ Please select Area first!');
        return;
    }
    
    let url = "lookupForLoan.jsp?type=subArea&areaCode=" + encodeURIComponent(areaCode);

    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById("subAreaLookupContent").innerHTML = html;
            document.getElementById("subAreaLookupModal").style.display = "flex";
            
            const scripts = document.getElementById("subAreaLookupContent").querySelectorAll('script');
            scripts.forEach(script => {
                const newScript = document.createElement('script');
                newScript.textContent = script.textContent;
                document.body.appendChild(newScript);
            });
        })
        .catch(error => {
            showToast('❌ Failed to load sub area lookup data. Please try again.');
            console.error('Lookup error:', error);
        });
}

function closeSubAreaLookup() {
    document.getElementById("subAreaLookupModal").style.display = "none";
}

window.setSubAreaData = function(code, name) {
    document.getElementById("subAreaCode").value = code;
    document.getElementById("subAreaName").value = name;
    
    closeSubAreaLookup();
    
};

// ==================== LOAN FIELD AUTO-FILL FUNCTIONALITY ====================

/**
 * Get today's date in YYYY-MM-DD format
 * @returns {string} Today's date formatted for HTML date input
 */
function getTodayDate() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

/**
 * Handle limit amount changes and update related fields
 * When user enters limit amount:
 * - Sets sanction amount (readonly) to same value
 * - Sets drawing power (editable) to same value
 */
function handleLimitAmountChange() {
    const limitAmount = document.getElementById('limitAmount');
    const sanctionAmount = document.getElementById('sanctionAmount');
    const drawingPower = document.getElementById('drawingPower');
    
    if (limitAmount && sanctionAmount && drawingPower) {
        limitAmount.addEventListener('input', function() {
            const value = this.value || '0';
            // Set sanction amount (readonly)
            sanctionAmount.value = value;
            // Set drawing power (editable)
            drawingPower.value = value;
        });
    }
}

/**
 * Initialize loan fields on page load
 * - Sets submission date to today
 * - Sets registration date to today
 * - Makes sanction amount readonly with gray background
 * - Sets up limit amount change handler
 */
function initializeLoanFields() {
    // Set today's date for submission and registration dates
    const registrationDate = document.getElementById('registrationDate');
    
    const today = getTodayDate();
    
    if (registrationDate) {
        registrationDate.value = today;
    }
    
    // Make sanction amount readonly with visual indication
    const sanctionAmount = document.getElementById('sanctionAmount');
    if (sanctionAmount) {
        sanctionAmount.readOnly = true;
        sanctionAmount.style.backgroundColor = '#f0f0f0';
        sanctionAmount.style.cursor = 'not-allowed';
    }
    
    // Set up limit amount change handler
    handleLimitAmountChange();
}

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    initializeLoanFields();
});

//==================== INSTALLMENT TYPE LOOKUP ====================

function openInstallmentLookup() {
    let url = "lookupForLoan.jsp";

    // Load JSP content into modal using fetch()
    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById("installmentLookupContent").innerHTML = html;
            document.getElementById("installmentLookupModal").style.display = "flex";
            
            // ✅ Execute any scripts in the loaded content
            const scripts = document.getElementById("installmentLookupContent").querySelectorAll('script');
            scripts.forEach(script => {
                const newScript = document.createElement('script');
                newScript.textContent = script.textContent;
                document.body.appendChild(newScript);
            });
        })
        .catch(error => {
            showToast('❌ Failed to load lookup data. Please try again.');
            console.error('Lookup error:', error);
        });
}

function closeInstallmentLookup() {
    document.getElementById("installmentLookupModal").style.display = "none";
}

// ✅ Global function to set installment data (called from lookupForLoan.jsp)
window.setInstallmentData = function(id, desc) {
    document.getElementById("installmentTypeId").value = id;
    document.getElementById("installmentType").value = desc;
    
    closeInstallmentLookup();
    
};

//==================== SOCIAL SECTOR LOOKUP ====================

function openSocialSectorLookup() {
    let url = "lookupForLoan.jsp?type=socialSector";

    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById("socialSectorLookupContent").innerHTML = html;
            document.getElementById("socialSectorLookupModal").style.display = "flex";
            
            const scripts = document.getElementById("socialSectorLookupContent").querySelectorAll('script');
            scripts.forEach(script => {
                const newScript = document.createElement('script');
                newScript.textContent = script.textContent;
                document.body.appendChild(newScript);
            });
        })
        .catch(error => {
            showToast('❌ Failed to load social sector lookup data. Please try again.');
            console.error('Lookup error:', error);
        });
}

function closeSocialSectorLookup() {
    document.getElementById("socialSectorLookupModal").style.display = "none";
}

window.setSocialSectorData = function(id, desc) {
    document.getElementById("socialSectorId").value = id;
    document.getElementById("socialSectorDesc").value = desc;
    
    // Clear subsector when sector changes
    document.getElementById("socialSubSectorId").value = '';
    document.getElementById("socialSubSectorDesc").value = '';
    
    closeSocialSectorLookup();
    
};

//==================== SOCIAL SUBSECTOR LOOKUP ====================

function openSocialSubSectorLookup() {
    const sectorId = document.getElementById("socialSectorId").value;
    
    if (!sectorId) {
        showToast('⚠️ Please select Social Sector first!');
        return;
    }
    
    let url = "lookupForLoan.jsp?type=socialSubSector&sectorId=" + encodeURIComponent(sectorId);

    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById("socialSubSectorLookupContent").innerHTML = html;
            document.getElementById("socialSubSectorLookupModal").style.display = "flex";
            
            const scripts = document.getElementById("socialSubSectorLookupContent").querySelectorAll('script');
            scripts.forEach(script => {
                const newScript = document.createElement('script');
                newScript.textContent = script.textContent;
                document.body.appendChild(newScript);
            });
        })
        .catch(error => {
            showToast('❌ Failed to load social subsector lookup data. Please try again.');
            console.error('Lookup error:', error);
        });
}

function closeSocialSubSectorLookup() {
    document.getElementById("socialSubSectorLookupModal").style.display = "none";
}

window.setSocialSubSectorData = function(id, desc) {
    document.getElementById("socialSubSectorId").value = id;
    document.getElementById("socialSubSectorDesc").value = desc;
    
    closeSocialSubSectorLookup();
    
};

// ==================== END LOAN FIELD AUTO-FILL FUNCTIONALITY ====================



//==================== EMI CALCULATION FUNCTIONS ====================

  /**
   * Calculate EMI using the Oracle function via AJAX
   * Calls fn_get_emi_inst from the database
   */
  function calculateEMI() {
      const limitAmount = parseFloat(document.getElementById('limitAmount').value) || 0;
      const interestRate = parseFloat(document.querySelector('input[name="interestRate"]').value) || 0;
      const loanPeriod = parseInt(document.getElementById('loanPeriod').value) || 0;
      const installmentTypeId = document.getElementById('installmentTypeId').value;
      
      // Validation
      if (limitAmount <= 0) {
          return;
      }
      
      if (interestRate <= 0) {
          return;
      }
      
      if (loanPeriod <= 0) {
          return;
      }
      
      if (!installmentTypeId) {
          return;
      }
      
      // Show loading state
      const instAmountField = document.querySelector('input[name="instAmount"]');
      const originalValue = instAmountField.value;
      instAmountField.value = 'Calculating...';
      instAmountField.disabled = true;
      
      // Call backend to execute Oracle function
      fetch('calculateEMI.jsp', {
          method: 'POST',
          headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
              loanAmount: limitAmount,
              rate: interestRate,
              period: loanPeriod,
              instType: installmentTypeId
          })
      })
      .then(response => response.json())
      .then(data => {
          instAmountField.disabled = false;
          
          if (data.success) {
              instAmountField.value = data.emiAmount;
              // Removed toast notification - silent calculation
          } else {
              instAmountField.value = originalValue;
              showToast('⚠️ ' + data.message, 'warning');
          }
      })
      .catch(error => {
          console.error('Error calculating EMI:', error);
          instAmountField.disabled = false;
          instAmountField.value = originalValue;
          showToast('❌ Failed to calculate EMI', 'error');
      });
  }

  /**
   * Auto-calculate EMI when relevant fields change
   */
  function setupEMIAutoCalculation() {
      const limitAmount = document.getElementById('limitAmount');
      const interestRate = document.querySelector('input[name="interestRate"]');
      const loanPeriod = document.getElementById('loanPeriod');
      const installmentTypeId = document.getElementById('installmentTypeId');
      
      // Add event listeners for auto-calculation
      if (limitAmount) {
          limitAmount.addEventListener('blur', checkAndCalculateEMI);
          limitAmount.addEventListener('change', checkAndCalculateEMI);
      }
      
      if (interestRate) {
          interestRate.addEventListener('blur', checkAndCalculateEMI);
          interestRate.addEventListener('change', checkAndCalculateEMI);
      }
      
      if (loanPeriod) {
          loanPeriod.addEventListener('blur', checkAndCalculateEMI);
          loanPeriod.addEventListener('change', checkAndCalculateEMI);
      }
      
      if (installmentTypeId) {
          installmentTypeId.addEventListener('change', checkAndCalculateEMI);
      }
  }

  /**
   * Check if all required fields are filled before auto-calculating
   */
  function checkAndCalculateEMI() {
      const limitAmount = parseFloat(document.getElementById('limitAmount').value) || 0;
      const interestRate = parseFloat(document.querySelector('input[name="interestRate"]').value) || 0;
      const loanPeriod = parseInt(document.getElementById('loanPeriod').value) || 0;
      const installmentTypeId = document.getElementById('installmentTypeId').value;
      
      // Only auto-calculate if all fields have valid values
      if (limitAmount > 0 && interestRate > 0 && loanPeriod > 0 && installmentTypeId) {
          calculateEMI();
      }
  }

  // Initialize EMI auto-calculation when DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
      setupEMIAutoCalculation();
  });