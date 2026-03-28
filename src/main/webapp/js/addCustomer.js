function toggleMinorFields() {
  const isMinorRadio = document.querySelector('input[name="isMinor"]:checked');
  if (!isMinorRadio) return;
  
  const isMinor = isMinorRadio.value;
  const guardianName = document.getElementById('guardianName');
  const relationGuardian = document.getElementById('relationGuardian');

  if (isMinor === 'yes') {
    guardianName.disabled = false;
    relationGuardian.disabled = false;
  } else {
    guardianName.disabled = true;
    relationGuardian.disabled = true;
    guardianName.value = '';
    relationGuardian.value = 'NOT SPECIFIED';
  }
}

function toggleMarriedFields() {
  const maritalStatus = document.querySelector('input[name="maritalStatus"]:checked').value;
  const noOFChildren = document.getElementById('children');
  const noOfDependents = document.getElementById('dependents');

  if (maritalStatus === 'Single') {
    noOFChildren.disabled = true;
    noOfDependents.disabled = true;
  } else {
    noOFChildren.disabled = false;
    noOfDependents.disabled = false;
    noOFChildren.value = '';
    noOfDependents.value = 'NOT SPECIFIED';
  }
}

// Auto-detect minor status based on birth date
function checkMinorStatus() {
    const birthDateInput = document.getElementById('birthDate');
    const isMinorYes = document.getElementById('isMinor1');
    const isMinorNo = document.getElementById('isMinor2');
    
    if (!birthDateInput || !birthDateInput.value) {
        if (isMinorYes) {
            isMinorYes.disabled = false;
            isMinorYes.style.cursor = 'pointer';
        }
        if (isMinorNo) {
            isMinorNo.disabled = false;
            isMinorNo.style.cursor = 'pointer';
        }
        return;
    }
    
    const birthDate = new Date(birthDateInput.value);
    const today = new Date();
    
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
        age--;
    }
    
    if (age < 18) {
        isMinorYes.checked = true;
        isMinorNo.checked = false;
    } else {
        isMinorYes.checked = false;
        isMinorNo.checked = true;
    }
    
    isMinorYes.disabled = true;
    isMinorNo.disabled = true;
    isMinorYes.style.cursor = 'not-allowed';
    isMinorNo.style.cursor = 'not-allowed';
    
    const radioGroup = isMinorYes.closest('.radio-group');
    if (radioGroup) {
        radioGroup.style.opacity = '0.7';
        radioGroup.title = 'Is Minor is auto-calculated from Birth Date';
    }
    
    toggleMinorFields();
    console.log(`Age calculated: ${age} years - Minor: ${age < 18 ? 'Yes' : 'No'} [READONLY]`);
}

document.addEventListener("DOMContentLoaded", function() {
  // Toggle KYC document fields based on checkboxes
  document.querySelectorAll(".kyc-section table tr").forEach(row => {
    const checkbox = row.querySelector('input[type="checkbox"]');
    const inputs = row.querySelectorAll('input[id="date"], input[type="text"]');

    if (checkbox) {
      inputs.forEach(input => input.disabled = true);
      checkbox.addEventListener("change", () => {
        if (checkbox.checked) {
          // Enable inputs when checkbox is checked
          inputs.forEach(input => input.disabled = false);
        } else {
          // Disable AND CLEAR inputs when checkbox is unchecked
          inputs.forEach(input => {
            input.disabled = true;
            clearKYCFieldCache(input);
          });
        }
      });
    }
  });

  // Birth date change listener
  const birthDateField = document.getElementById('birthDate');
  if (birthDateField) {
      birthDateField.addEventListener('change', checkMinorStatus);

      birthDateField.addEventListener('input', function() {
          if (!this.value) {
              const isMinorYes = document.getElementById('isMinor1');
              const isMinorNo = document.getElementById('isMinor2');
              const radioGroup = isMinorYes?.closest('.radio-group');

              if (isMinorYes) {
                  isMinorYes.disabled = false;
                  isMinorYes.style.cursor = 'pointer';
              }
              if (isMinorNo) {
                  isMinorNo.disabled = false;
                  isMinorNo.style.cursor = 'pointer';
              }
              if (radioGroup) {
                  radioGroup.style.opacity = '1';
                  radioGroup.title = '';
              }
          }
      });
  }
});

// ========== KYC CACHE CLEAR FUNCTION ==========
function clearKYCFieldCache(inputField) {
    inputField.value = '';
    inputField.style.borderColor = '';
    inputField.style.backgroundColor = '';
    
    const errorDiv = inputField.parentNode.querySelector('.error-message');
    if (errorDiv) {
        errorDiv.remove();
    }
    
    console.log(`✅ Cleared: ${inputField.name}`);
}

// Validation patterns
const validationPatterns = {
    gstin: /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/,
    pan: /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/,
    aadhar: /^[0-9]{12}$/,
    mobile: /^[6-9][0-9]{9}$/,
    phone: /^[0-9]{10,11}$/,
    zip: /^[0-9]{6}$/,
    voterId: /^[A-Z]{3}[0-9]{7}$/,
    drivingLicense: /^[A-Z]{2}[0-9]{13}$/,
    passport: /^[A-Z]{1}[0-9]{7}$/,
    nrega: /^[A-Z]{2}-[0-9]{2}-[0-9]{3}-[0-9]{3}-[0-9]{6}$/
};

// Real-time input formatting and validation
function setupFieldValidations() {
    // GSTIN validation
    const gstinField = document.querySelector('input[name="gstinNo"]');
    if (gstinField) {
        gstinField.maxLength = 15;
        gstinField.addEventListener('input', function(e) {
            this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        });
        gstinField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.gstin.test(this.value)) {
                showError(this, 'Invalid GSTIN format (e.g., 22AAAAA0000A1Z5)');
            } else {
                clearError(this);
            }
        });
    }

    // Mobile Number validation
    const mobileField = document.querySelector('input[name="mobileNo"]');
    if (mobileField) {
        mobileField.maxLength = 10;
        mobileField.addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 10);
        });
        mobileField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.mobile.test(this.value)) {
                showError(this, 'Mobile number must be 10 digits starting with 6-9');
            } else {
                clearError(this);
            }
        });
    }

    // Residence Phone validation
    const residencePhoneField = document.querySelector('input[name="residencePhone"]');
    if (residencePhoneField) {
        residencePhoneField.maxLength = 11;
        residencePhoneField.addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 11);
        });
        residencePhoneField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.phone.test(this.value)) {
                showError(this, 'Phone number must be 10-11 digits');
            } else {
                clearError(this);
            }
        });
    }

    // Office Phone validation
    const officePhoneField = document.querySelector('input[name="officePhone"]');
    if (officePhoneField) {
        officePhoneField.maxLength = 11;
        officePhoneField.addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 11);
        });
        officePhoneField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.phone.test(this.value)) {
                showError(this, 'Phone number must be 10-11 digits');
            } else {
                clearError(this);
            }
        });
    }

    // Passport Number validation
    const passportField = document.getElementById('passportNumber');
    if (passportField) {
        passportField.maxLength = 8;
        passportField.addEventListener('input', function(e) {
            this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        });
        passportField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.passport.test(this.value)) {
                showError(this, 'Passport format: 1 letter + 7 digits (e.g., A1234567)');
            } else {
                clearError(this);
            }
        });
    }

    // PAN Card validation
    const panField = document.getElementById('pan');
    if (panField) {
        panField.maxLength = 10;
        panField.addEventListener('input', function(e) {
            this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        });
        panField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.pan.test(this.value)) {
                showError(this, 'PAN format: ABCDE1234F (5 letters, 4 digits, 1 letter)');
            } else {
                clearError(this);
            }
        });
    }

    // Voter ID validation
    const voterIdField = document.getElementById('voterid');
    if (voterIdField) {
        voterIdField.maxLength = 10;
        voterIdField.addEventListener('input', function(e) {
            this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        });
        voterIdField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.voterId.test(this.value)) {
                showError(this, 'Voter ID format: ABC1234567 (3 letters + 7 digits)');
            } else {
                clearError(this);
            }
        });
    }

    // Driving License validation
    const dlField = document.getElementById('dl');
    if (dlField) {
        dlField.maxLength = 15;
        dlField.addEventListener('input', function(e) {
            this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        });
        dlField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.drivingLicense.test(this.value)) {
                showError(this, 'DL format: AB1234567890123 (2 letters + 13 digits)');
            } else {
                clearError(this);
            }
        });
    }

    // Aadhar Card validation
    const aadharField = document.querySelector('input[name="aadhar"]');
    if (aadharField) {
        aadharField.maxLength = 12;
        aadharField.addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 12);
        });
        aadharField.addEventListener('blur', function() {
            if (this.value && !validationPatterns.aadhar.test(this.value)) {
                showError(this, 'Aadhar must be exactly 12 digits');
            } else {
                clearError(this);
            }
        });
    }

    // NREGA Job Card validation
    const nregaField = document.getElementById('nrega');
    if (nregaField) {
        nregaField.maxLength = 22;
        nregaField.addEventListener('input', function(e) {
            let value = this.value.toUpperCase().replace(/[^A-Z0-9-]/g, '');
            if (value.length > 2 && value[2] !== '-') {
                value = value.slice(0, 2) + '-' + value.slice(2);
            }
            if (value.length > 5 && value[5] !== '-') {
                value = value.slice(0, 5) + '-' + value.slice(5);
            }
            if (value.length > 9 && value[9] !== '-') {
                value = value.slice(0, 9) + '-' + value.slice(9);
            }
            if (value.length > 13 && value[13] !== '-') {
                value = value.slice(0, 13) + '-' + value.slice(13);
            }
            this.value = value;
        });
    }

    // Document number validations (alphanumeric)
    const docFields = ['telephone', 'bank_statement', 'govt_doc', 'electricity'];
    docFields.forEach(fieldName => {
        const field = document.querySelector(`input[name="${fieldName}"]`);
        if (field) {
            field.maxLength = 20;
            field.addEventListener('input', function(e) {
                this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
            });
        }
    });

    // Ration Card validation
    const rationField = document.getElementById('ration');
    if (rationField) {
        rationField.maxLength = 15;
        rationField.addEventListener('input', function(e) {
            this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        });
    }
}

// Show error message
function showError(field, message) {
    clearError(field);
    field.style.borderColor = '#ff0000';
    field.style.backgroundColor = '#ffe6e6';
    
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.style.color = '#ff0000';
    errorDiv.style.fontSize = '11px';
    errorDiv.style.marginTop = '3px';
    errorDiv.textContent = message;
    
    field.parentNode.appendChild(errorDiv);
}

// Clear error message
function clearError(field) {
    field.style.borderColor = '';
    field.style.backgroundColor = '';
    
    const errorDiv = field.parentNode.querySelector('.error-message');
    if (errorDiv) {
        errorDiv.remove();
    }
}

// Form validation before submit
function validateForm() {
    let isValid = true;

    // GSTIN validation
    const gstinField = document.querySelector('input[name="gstinNo"]');
    if (gstinField && gstinField.value && !validationPatterns.gstin.test(gstinField.value)) {
        showError(gstinField, 'Invalid GSTIN format (e.g., 22AAAAA0000A1Z5)');
        isValid = false;
    } else {
        clearError(gstinField);
    }

    // Mobile validation
    const mobileField = document.querySelector('input[name="mobileNo"]');
if (mobileField && mobileField.value && !validationPatterns.mobile.test(mobileField.value)) {
        showError(mobileField, 'Mobile must be 10 digits starting with 6-9');
        isValid = false;
    } else {
        clearError(mobileField);
    }

    // ZIP validation
    const zipField = document.querySelector('input[name="zip"]');
    if (zipField && zipField.value && !validationPatterns.zip.test(zipField.value)) {
        showError(zipField, 'Invalid ZIP (6 digits, starts with 4 or 5)');
        isValid = false;
    } else {
        clearError(zipField);
    }

    // PAN validation
    const panField = document.getElementById('pan');
    if (panField && panField.value && !validationPatterns.pan.test(panField.value)) {
        showError(panField, 'PAN format: ABCDE1234F');
        isValid = false;
    } else {
        clearError(panField);
    }

    // Aadhar validation
    const aadharField = document.querySelector('input[name="aadhar"]');
    if (aadharField && aadharField.value && !validationPatterns.aadhar.test(aadharField.value)) {
        showError(aadharField, 'Aadhar must be 12 digits');
        isValid = false;
    } else {
        clearError(aadharField);
    }

    // Passport validation
    const passportField = document.getElementById('passportNumber');
    if (passportField && passportField.value && !validationPatterns.passport.test(passportField.value)) {
        showError(passportField, 'Passport: 1 letter + 7 digits');
        isValid = false;
    } else {
        clearError(passportField);
    }

    // Voter ID validation
    const voterIdField = document.getElementById('voterid');
    if (voterIdField && voterIdField.value && !validationPatterns.voterId.test(voterIdField.value)) {
        showError(voterIdField, 'Voter ID: ABC1234567');
        isValid = false;
    } else {
        clearError(voterIdField);
    }

    // Driving License validation
    const dlField = document.getElementById('dl');
    if (dlField && dlField.value && !validationPatterns.drivingLicense.test(dlField.value)) {
        showError(dlField, 'DL: AB1234567890123');
        isValid = false;
    } else {
        clearError(dlField);
    }


    return isValid;
}

// Initialize validations when page loads
document.addEventListener('DOMContentLoaded', function() {
    setupFieldValidations();
});

// Update customer name from input fields
function updateCustomerName() {
    const first = document.getElementById("firstName").value.trim();
    const middle = document.getElementById("middleName").value.trim();
    const surname = document.getElementById("surname").value.trim();
    const fullName = [first, middle, surname].filter(Boolean).join(" ");
    document.getElementById("customerName").value = fullName;
}

// Reset form including uploads
function resetFormWithUploads() {
  setTimeout(() => {
    const photoPreview = document.getElementById('photoPreviewIcon');
    if (photoPreview) {
      photoPreview.src = 'images/photo-icon.png';
      photoPreview.classList.remove('preview-image');
    }
    document.getElementById('photoData').value = '';
    document.getElementById('photoInput').value = '';
    
    const photoCard = photoPreview?.closest('.upload-card');
    if (photoCard) {
      const photoBadge = photoCard.querySelector('.upload-success-badge');
      if (photoBadge) photoBadge.remove();
    }
    
    const signaturePreview = document.getElementById('signaturePreviewIcon');
    if (signaturePreview) {
      signaturePreview.src = 'images/signature-icon.png';
      signaturePreview.classList.remove('preview-image');
    }
    document.getElementById('signatureData').value = '';
    document.getElementById('signatureInput').value = '';
    
    const signatureCard = signaturePreview?.closest('.upload-card');
    if (signatureCard) {
      const signatureBadge = signatureCard.querySelector('.upload-success-badge');
      if (signatureBadge) signatureBadge.remove();
    }
    
    document.querySelectorAll('.error-message').forEach(err => err.remove());
    document.querySelectorAll('input, select, textarea').forEach(field => {
      field.style.borderColor = '';
      field.style.backgroundColor = '';
    });
    
    showToast('🔄 Form has been reset including photo and signature', 'info');
  }, 10);
}

// ========== IMAGE UPLOAD CONFIGURATION ==========
const IMAGE_CONFIG = {
    photo: {
        maxSize: 5 * 1024 * 1024,
        targetSize: 500 * 1024,
        width: 413,
        height: 531,
        aspectRatio: 3.5 / 4.5,
        quality: 0.85,
        name: 'Photo'
    },
    signature: {
        maxSize: 5 * 1024 * 1024,
        targetSize: 500 * 1024,
        width: 600,
        height: 200,
        aspectRatio: 3,
        quality: 0.85,
        name: 'Signature'
    }
};

const ALLOWED_TYPES = ['image/jpeg', 'image/jpg'];
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg'];

// Validate file type
function validateFileType(file, configType, fieldElement) {
    const fileType = file.type.toLowerCase();
    const fileName = file.name.toLowerCase();
    
    const hasValidType = ALLOWED_TYPES.includes(fileType);
    const hasValidExtension = ALLOWED_EXTENSIONS.some(ext => fileName.endsWith(ext));
    
    if (!hasValidType && !hasValidExtension) {
        showError(fieldElement, 'Only JPG/JPEG files allowed');
        return false;
    }
    clearError(fieldElement);
    return true;
}

// Validate file size
function validateFileSize(file, config, fieldElement) {
    if (file.size > config.maxSize) {
        const maxSizeMB = (config.maxSize / (1024 * 1024)).toFixed(1);
        const fileSizeMB = (file.size / (1024 * 1024)).toFixed(1);
        showError(fieldElement, `File size (${fileSizeMB}MB) exceeds ${maxSizeMB}MB`);
        return false;
    }
    clearError(fieldElement);
    return true;
}

// Compress and resize image
function compressImage(imageData, config) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        
        img.onload = function() {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            
            canvas.width = config.width;
            canvas.height = config.height;
            
            ctx.fillStyle = '#FFFFFF';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            
            let sourceWidth = img.width;
            let sourceHeight = img.height;
            let sourceX = 0;
            let sourceY = 0;
            
            const sourceAspect = sourceWidth / sourceHeight;
            const targetAspect = config.width / config.height;
            
            if (sourceAspect > targetAspect) {
                sourceWidth = sourceHeight * targetAspect;
                sourceX = (img.width - sourceWidth) / 2;
            } else {
                sourceHeight = sourceWidth / targetAspect;
                sourceY = (img.height - sourceHeight) / 2;
            }
            
            ctx.drawImage(
                img,
                sourceX, sourceY, sourceWidth, sourceHeight,
                0, 0, canvas.width, canvas.height
            );
            
            compressToTargetSize(canvas, config.quality, config.targetSize)
                .then(resolve)
                .catch(reject);
        };
        
        img.onerror = function() {
            reject(new Error('Failed to load image'));
        };
        
        img.src = imageData;
    });
}

// Compress to target size
function compressToTargetSize(canvas, initialQuality, targetSize) {
    return new Promise((resolve) => {
        let quality = initialQuality;
        let attempts = 0;
        const maxAttempts = 10;
        
        function tryCompress() {
            const compressed = canvas.toDataURL('image/jpeg', quality);
            const sizeInBytes = Math.round((compressed.length * 3) / 4);
            
            if (sizeInBytes <= targetSize || attempts >= maxAttempts || quality <= 0.1) {
                console.log(`✅ Compressed to ${(sizeInBytes / 1024).toFixed(1)}KB at quality ${(quality * 100).toFixed(0)}%`);
                resolve(compressed);
                return;
            }
            
            quality -= 0.1;
            attempts++;
            tryCompress();
        }
        
        tryCompress();
    });
}

// Process image file
function processImageFile(file, config, previewElementId, dataFieldId) {
    return new Promise((resolve, reject) => {
        const fieldElement = document.getElementById(dataFieldId).previousElementSibling || 
                           document.querySelector(`[name="${config.name.toLowerCase()}"]`);
        
        if (!validateFileType(file, config.name, fieldElement)) {
            reject(new Error('Invalid file type'));
            return;
        }
        
        if (!validateFileSize(file, config, fieldElement)) {
            reject(new Error('File too large'));
            return;
        }
        
        const reader = new FileReader();
        
        reader.onload = function(e) {
            compressImage(e.target.result, config)
                .then(compressedImage => {
                    const preview = document.getElementById(previewElementId);
                    preview.src = compressedImage;
                    preview.classList.add('preview-image');
                    
                    document.getElementById(dataFieldId).value = compressedImage;
                    markFieldAsComplete(previewElementId);
                    clearError(fieldElement);
                    
                    resolve(compressedImage);
                })
                .catch(error => {
                    showError(fieldElement, `Failed to process: ${error.message}`);
                    reject(error);
                });
        };
        
        reader.onerror = function() {
            showError(fieldElement, 'Failed to read file');
            reject(new Error('File read error'));
        };
        
        reader.readAsDataURL(file);
    });
}

// ========== PHOTO UPLOAD HANDLERS ==========
let photoStream = null;

document.getElementById('photoInput').addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        processImageFile(file, IMAGE_CONFIG.photo, 'photoPreviewIcon', 'photoData')
            .catch(() => { 
                this.value = ''; 
                showError(this, 'Photo upload failed');
            });
    }
});

function handlePhotoFile(file) {
    processImageFile(file, IMAGE_CONFIG.photo, 'photoPreviewIcon', 'photoData')
        .catch(() => {});
}

function openPhotoCamera() {
    const modal = document.getElementById('photoCameraModal');
    const video = document.getElementById('photoVideo');
    
    modal.style.display = 'block';
    
    navigator.mediaDevices.getUserMedia({ 
        video: { 
            width: { ideal: 1280 },
            height: { ideal: 720 },
            facingMode: 'user'
        } 
    })
    .then(function(stream) {
        photoStream = stream;
        video.srcObject = stream;
    })
    .catch(function(err) {
        showToast('❌ Error accessing camera: ' + err.message, 'error');
        closePhotoCamera();
    });
}

function closePhotoCamera() {
    const modal = document.getElementById('photoCameraModal');
    const video = document.getElementById('photoVideo');
    
    if (photoStream) {
        photoStream.getTracks().forEach(track => track.stop());
        photoStream = null;
    }
    
    video.srcObject = null;
    modal.style.display = 'none';
}

function capturePhoto() {
    const video = document.getElementById('photoVideo');
    const canvas = document.getElementById('photoCanvas');
    const ctx = canvas.getContext('2d');
    
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    
    const imageData = canvas.toDataURL('image/jpeg', 0.95);
    
   
    
    compressImage(imageData, IMAGE_CONFIG.photo)
        .then(compressedImage => {
            const preview = document.getElementById('photoPreviewIcon');
            preview.src = compressedImage;
            preview.classList.add('preview-image');
            document.getElementById('photoData').value = compressedImage;
            
            closePhotoCamera();
            markFieldAsComplete('photoPreviewIcon');
            
            const finalSize = Math.round((compressedImage.length * 3) / 4);
        })
        .catch(error => {
            showToast('❌ Failed to process photo: ' + error.message, 'error');
        });
}

// ========== SIGNATURE UPLOAD HANDLERS ==========
let signatureStream = null;

document.getElementById('signatureInput').addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        processImageFile(file, IMAGE_CONFIG.signature, 'signaturePreviewIcon', 'signatureData')
            .catch(() => { this.value = ''; });
    }
});

function handleSignatureFile(file) {
    processImageFile(file, IMAGE_CONFIG.signature, 'signaturePreviewIcon', 'signatureData')
        .catch(() => {});
}

function openSignatureCamera() {
    const modal = document.getElementById('signatureCameraModal');
    const video = document.getElementById('signatureVideo');
    
    modal.style.display = 'block';
    
    navigator.mediaDevices.getUserMedia({ 
        video: { 
            width: { ideal: 1280 },
            height: { ideal: 720 },
            facingMode: 'environment'
        } 
    })
    .then(function(stream) {
        signatureStream = stream;
        video.srcObject = stream;
    })
    .catch(function(err) {
        showToast('❌ Error accessing camera: ' + err.message, 'error');
        closeSignatureCamera();
    });
}

function closeSignatureCamera() {
    const modal = document.getElementById('signatureCameraModal');
    const video = document.getElementById('signatureVideo');
    
    if (signatureStream) {
        signatureStream.getTracks().forEach(track => track.stop());
        signatureStream = null;
    }
    
    video.srcObject = null;
    modal.style.display = 'none';
}

function captureSignature() {
    const video = document.getElementById('signatureVideo');
    const canvas = document.getElementById('signatureCanvas');
    const ctx = canvas.getContext('2d');
    
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    
    const imageData = canvas.toDataURL('image/jpeg', 0.95);
    
    
    
    compressImage(imageData, IMAGE_CONFIG.signature)
        .then(compressedImage => {
            const preview = document.getElementById('signaturePreviewIcon');
            preview.src = compressedImage;
            preview.classList.add('preview-image');
            document.getElementById('signatureData').value = compressedImage;
            
            closeSignatureCamera();
            markFieldAsComplete('signaturePreviewIcon');
            
            const finalSize = Math.round((compressedImage.length * 3) / 4);
            
        })
        .catch(error => {
            showToast('❌ Failed to process signature: ' + error.message, 'error');
        });
}

// ========== DRAG AND DROP ==========
const photoCard = document.querySelector('.upload-card:first-child');
if (photoCard) {
    photoCard.addEventListener('dragover', function(e) {
        e.preventDefault();
        this.classList.add('dragover');
    });

    photoCard.addEventListener('dragleave', function() {
        this.classList.remove('dragover');
    });

    photoCard.addEventListener('drop', function(e) {
        e.preventDefault();
        this.classList.remove('dragover');
        
        const file = e.dataTransfer.files[0];
        if (file) {
            handlePhotoFile(file);
        }
    });
}

const signatureCard = document.querySelector('.upload-card:last-child');
if (signatureCard) {
    signatureCard.addEventListener('dragover', function(e) {
        e.preventDefault();
        this.classList.add('dragover');
    });

    signatureCard.addEventListener('dragleave', function() {
        this.classList.remove('dragover');
    });

    signatureCard.addEventListener('drop', function(e) {
        e.preventDefault();
        this.classList.remove('dragover');
        
        const file = e.dataTransfer.files[0];
        if (file) {
            handleSignatureFile(file);
        }
    });
}

// Close camera modals when clicking outside
window.addEventListener('click', function(event) {
    if (event.target.id === 'photoCameraModal') {
        closePhotoCamera();
    }
    if (event.target.id === 'signatureCameraModal') {
        closeSignatureCamera();
    }
});

// Unified toast notification function
function showToast(message, type = 'info') {
    if (typeof Toastify === 'undefined') return;
    
    const colors = {
        success: '#4caf50',
        error: '#f44336',
        info: '#2196F3'
    };
    
    Toastify({
        text: message,
        duration: type === 'error' ? 5000 : 4000,
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
            borderLeft: `5px solid ${colors[type]}`,
            marginTop: "20px",
            whiteSpace: "pre-line"
        }
    }).showToast();
}

// Add visual indicator for successful upload
function markFieldAsComplete(fieldId) {
    const container = document.getElementById(fieldId).closest('.upload-card');
    if (container) {
        let badge = container.querySelector('.upload-success-badge');
        if (!badge) {
            badge = document.createElement('span');
            badge.className = 'upload-success-badge';
            badge.innerHTML = '✓';
            badge.style.cssText = `
                position: absolute;
                top: 10px;
                right: 10px;
                background: #4caf50;
                color: white;
                width: 30px;
                height: 30px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 18px;
                font-weight: bold;
                z-index: 10;
            `;
            container.style.position = 'relative';
            container.appendChild(badge);
        }
    }
}

// Check URL parameters for success/error messages
window.addEventListener('DOMContentLoaded', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const status = urlParams.get('status');
    const customerId = urlParams.get('customerId');
    const message = urlParams.get('message');
    
    if (status === 'success') {
        showCustomerSuccessModal(customerId);
        setTimeout(function() {
            window.history.replaceState({}, document.title, "addCustomer.jsp");
        }, 100);
    } else if (status === 'error') {
        showToast("❌ Error: " + (message || "Failed to add customer"), 'error');
        setTimeout(function() {
            window.history.replaceState({}, document.title, "addCustomer.jsp");
        }, 100);
    }
    
    console.log('✅ Image upload handlers initialized');
});

// Show success modal for customer
function showCustomerSuccessModal(customerId) {
    const modal = document.createElement('div');
    modal.id = 'customerSuccessModal';
    modal.style.cssText = `
        display: flex;
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        justify-content: center;
        align-items: center;
        z-index: 10000;
    `;
    
    modal.innerHTML = `
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
            
            <div style="
                font-size: 20px;
                font-weight: bold;
                color: #333;
                margin-bottom: 15px;
            ">
                Customer added successfully!
            </div>
            
            <div style="
                font-size: 25px;
                color: #666;
                margin-bottom: 30px;
                font-weight: bold;
            ">
                Customer ID: ${customerId}
            </div>
            
            <button onclick="closeCustomerModal()" style="
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
    `;
    
    document.body.appendChild(modal);
}

function closeCustomerModal() {
    const modal = document.getElementById('customerSuccessModal');
    if (modal) {
        modal.remove();
    }
    // Optionally reset the form
    document.querySelector('form').reset();
}